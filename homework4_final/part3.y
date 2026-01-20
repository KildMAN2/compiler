%{
/*
    EE046266: Compilation Methods - Winter 2025-2026
    Parser and Code Generator for C-- Language - Based on project specification
*/

#include "part3_helpers.hpp"

extern int yylex();
extern int yylineno;
void yyerror(const char* s);

// Initialize buffer in parser (to avoid static linkage issues)
void initParser() {
    if (!buffer) {
        buffer = new Buffer();
    }
}

// Global variables (using declarations from part3_helpers.hpp)
int currentDepth = 0;
int currentOffset = 0;
int regCounter = 3;
string currentFunction = "";
Type currentReturnType = void_t;
vector<string> implementedFuncs;

// Helper functions
void declareVariable(const string& id, Type type);
void declareFunction(const string& id, Type returnType, const vector<Type>& paramTypes, const vector<string>& paramIds);
void defineFunction(const string& id, int startLine);
Symbol* lookup(const string& id);
Function* lookupFunction(const string& id);
int allocateRegister();
void emitCode(const string& code);
void semanticError(const string& msg);
void generateHeader();

%}

%token VOID INT FLOAT RETURN IF THEN ELSE WHILE DO READ WRITE
%token ID NUM REALNUM STRING
%token EQEQ NOTEQ LTEQ GTEQ LT GT ASSIGN
%token PLUS MINUS MULT DIV
%token LPAREN RPAREN LBRACE RBRACE COLON SEMICOLON COMMA

%right ASSIGN
%left EQEQ NOTEQ
%left LT GT LTEQ GTEQ
%left PLUS MINUS
%left MULT DIV

%%

program: 
    { initParser(); }
    function_declarations {
        generateHeader();
    }
    ;

function_declarations:
    function_declarations function_declaration
    | function_declarations function_definition
    | /* empty */
    ;

function_declaration:
    type_specifier ID LPAREN param_list RPAREN SEMICOLON {
        string funcName = $2.name;
        Type retType = $1.type;
        vector<Type> paramTypes = $4.paramTypes;
        vector<string> paramIds = $4.paramIds;
        
        if (functionTable.find(funcName) != functionTable.end()) {
            Function& func = functionTable[funcName];
            if (func.returnType != retType || func.paramTypes.size() != paramTypes.size()) {
                semanticError("Function redeclared with different signature");
            }
            for (size_t i = 0; i < paramTypes.size(); i++) {
                if (func.paramTypes[i] != paramTypes[i]) {
                    semanticError("Function redeclared with different signature");
                }
            }
        } else {
            declareFunction(funcName, retType, paramTypes, paramIds);
        }
    }
    ;

function_definition:
    type_specifier ID LPAREN param_list RPAREN {
        string funcName = $2.name;
        Type retType = $1.type;
        vector<Type> paramTypes = $4.paramTypes;
        vector<string> paramIds = $4.paramIds;
        
        currentFunction = funcName;
        currentReturnType = retType;
        currentDepth++;
        currentOffset = 0;
        
        if (functionTable.find(funcName) != functionTable.end()) {
            Function& func = functionTable[funcName];
            if (func.isDefined) {
                semanticError("Function redefined");
            }
            if (func.returnType != retType || func.paramTypes.size() != paramTypes.size()) {
                semanticError("Function definition doesn't match declaration");
            }
            for (size_t i = 0; i < paramTypes.size(); i++) {
                if (func.paramTypes[i] != paramTypes[i]) {
                    semanticError("Function definition doesn't match declaration");
                }
            }
        } else {
            declareFunction(funcName, retType, paramTypes, paramIds);
        }
        
        int startLine = buffer->nextQuad();
        defineFunction(funcName, startLine);
        
        // Parameters at negative offsets from FP
        int paramOffset = -4 - (paramIds.size() * 4);
        for (size_t i = 0; i < paramIds.size(); i++) {
            Symbol& sym = symbolTable[paramIds[i]];
            sym.type[currentDepth] = paramTypes[i];
            sym.offset[currentDepth] = paramOffset + ((paramIds.size() - i - 1) * 4);
            sym.depth = currentDepth;
        }
        
        implementedFuncs.push_back(funcName + "," + intToString(startLine));
    }
    LBRACE statement_list RBRACE {
        emitCode("RETRN");
        
        currentDepth--;
        currentFunction = "";
        
        for (auto it = symbolTable.begin(); it != symbolTable.end(); ) {
            if (it->second.depth > currentDepth) {
                it = symbolTable.erase(it);
            } else {
                ++it;
            }
        }
        
        currentOffset = 0;
    }
    ;

param_list:
    param_list_non_empty {
        $$.paramTypes = $1.paramTypes;
        $$.paramIds = $1.paramIds;
    }
    | /* empty */ {
        $$.paramTypes.clear();
        $$.paramIds.clear();
    }
    ;

param_list_non_empty:
    param {
        $$.paramTypes.push_back($1.type);
        $$.paramIds.push_back($1.name);
    }
    | param_list_non_empty COMMA param {
        $$.paramTypes = $1.paramTypes;
        $$.paramIds = $1.paramIds;
        $$.paramTypes.push_back($3.type);
        $$.paramIds.push_back($3.name);
    }
    ;

param:
    ID COLON type_specifier {
        $$.name = $1.name;
        $$.type = $3.type;
    }
    ;

type_specifier:
    VOID { $$.type = void_t; }
    | INT { $$.type = int_; }
    | FLOAT { $$.type = float_; }
    ;

statement_list:
    statement_list statement
    | /* empty */
    ;

statement:
    declaration_stmt
    | assignment_stmt
    | if_stmt
    | while_stmt
    | return_stmt
    | read_stmt
    | write_stmt
    | block_stmt
    ;

block_stmt:
    LBRACE {
        currentDepth++;
    }
    statement_list RBRACE {
        currentDepth--;
        
        for (auto it = symbolTable.begin(); it != symbolTable.end(); ) {
            if (it->second.depth > currentDepth) {
                it = symbolTable.erase(it);
            } else {
                ++it;
            }
        }
    }
    ;

declaration_stmt:
    ID COLON type_specifier SEMICOLON {
        declareVariable($1.name, $3.type);
    }
    ;

assignment_stmt:
    ID ASSIGN expression SEMICOLON {
        Symbol* sym = lookup($1.name);
        
        if (!sym) {
            semanticError("Undeclared variable");
        }
        
        if (sym->type[sym->depth] != $3.type) {
            semanticError("Type mismatch");
        }
        
        int targetReg = allocateRegister();
        stringstream ss;
        ss << "ADD2I I" << targetReg << " I1 " << sym->offset[sym->depth];
        emitCode(ss.str());
        
        ss.str("");
        ss << "STORI I" << $3.RegNum << " I" << targetReg << " 0";
        emitCode(ss.str());
    }
    ;

if_stmt:
    IF expression THEN statement {
        // Expression falls through when true, jumps when false
        buffer->backpatch($2.falseList, buffer->nextQuad());
    }
    | IF expression THEN statement ELSE {
        // Jump over else block at end of then block
        int jumpQuad = buffer->nextQuad();
        emitCode("UJUMP ");
        
        // False condition jumps to else block
        buffer->backpatch($2.falseList, buffer->nextQuad());
        $5.nextList.push_back(jumpQuad);
    }
    statement {
        // Backpatch the jump at end of then block to after else
        buffer->backpatch($5.nextList, buffer->nextQuad());
    }
    ;

while_stmt:
    WHILE {
        $1.quad = buffer->nextQuad();
    }
    expression DO statement {
        // Jump back to condition
        stringstream ss;
        ss << "UJUMP " << $1.quad;
        emitCode(ss.str());
        
        // Backpatch false jumps to after loop
        buffer->backpatch($3.falseList, buffer->nextQuad());
    }
    ;

return_stmt:
    RETURN expression SEMICOLON {
        if (currentReturnType == void_t) {
            semanticError("Cannot return value from void function");
        }
        if ($2.type != currentReturnType) {
            semanticError("Return type mismatch");
        }
        
        stringstream ss;
        if ($2.type == float_) {
            ss << "STORF F" << $2.RegNum << " I1 -4";
        } else {
            ss << "STORI I" << $2.RegNum << " I1 -4";
        }
        emitCode(ss.str());
        emitCode("RETRN");
    }
    | RETURN SEMICOLON {
        if (currentReturnType != void_t) {
            semanticError("Must return value from non-void function");
        }
        emitCode("RETRN");
    }
    ;

read_stmt:
    READ LPAREN ID RPAREN SEMICOLON {
        Symbol* sym = lookup($3.name);
        
        if (!sym) {
            semanticError("Undeclared variable");
        }
        
        int reg = allocateRegister();
        stringstream ss;
        
        if (sym->type[sym->depth] == int_) {
            ss << "READI I" << reg;
            emitCode(ss.str());
        } else {
            ss << "READF F" << reg;
            emitCode(ss.str());
        }
        
        int addrReg = allocateRegister();
        ss.str("");
        ss << "ADD2I I" << addrReg << " I1 " << sym->offset[sym->depth];
        emitCode(ss.str());
        
        ss.str("");
        ss << "STORI I" << reg << " I" << addrReg << " 0";
        emitCode(ss.str());
    }
    ;

write_stmt:
    WRITE LPAREN expression RPAREN SEMICOLON {
        stringstream ss;
        if ($3.type == int_) {
            ss << "PRNTI I" << $3.RegNum;
        } else {
            ss << "PRNTF F" << $3.RegNum;
        }
        emitCode(ss.str());
    }
    | WRITE LPAREN STRING RPAREN SEMICOLON {
        string str = $3.name;
        str = str.substr(1, str.length() - 2);
        
        for (size_t i = 0; i < str.length(); i++) {
            if (str[i] == '\\' && i + 1 < str.length()) {
                int charCode;
                switch (str[i + 1]) {
                    case 'n': charCode = 10; break;
                    case 't': charCode = 9; break;
                    case 'r': charCode = 13; break;
                    case '0': charCode = 0; break;
                    case '"': charCode = 34; break;
                    case '\\': charCode = 92; break;
                    default: charCode = str[i + 1]; break;
                }
                
                stringstream ss;
                ss << "PRNTC " << charCode;
                emitCode(ss.str());
                i++;
            } else {
                stringstream ss;
                ss << "PRNTC " << (int)str[i];
                emitCode(ss.str());
            }
        }
    }
    ;

expression:
    expression PLUS expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = $1.type;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($$.type == int_) {
            ss << "ADD2I I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "ADD2F F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        $$.quad = buffer->nextQuad() - 1;
    }
    | expression MINUS expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = $1.type;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($$.type == int_) {
            ss << "SUBTI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SUBTF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        $$.quad = buffer->nextQuad() - 1;
    }
    | expression MULT expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = $1.type;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($$.type == int_) {
            ss << "MULTI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "MULTF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        $$.quad = buffer->nextQuad() - 1;
    }
    | expression DIV expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = $1.type;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($$.type == int_) {
            ss << "DIVDI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "DIVDF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        $$.quad = buffer->nextQuad() - 1;
    }
    | expression EQEQ expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($1.type == int_) {
            ss << "SEQUI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SEQLF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        
        $$.falseList.push_back(buffer->nextQuad());
        ss.str("");
        ss << "BREQZ I" << $$.RegNum << " ";
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad();
    }
    | expression NOTEQ expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($1.type == int_) {
            ss << "SNEQI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SNEQF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        
        // Emit BREQZ - if result is 0 (false), jump to false target
        $$.falseList.push_back(buffer->nextQuad());
        ss.str("");
        ss << "BREQZ I" << $$.RegNum << " ";
        emitCode(ss.str());
        
        // No UJUMP needed - execution falls through when true
        $$.quad = buffer->nextQuad();
    }
    | expression LT expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($1.type == int_) {
            ss << "SLTTI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SLTTF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        
        $$.falseList.push_back(buffer->nextQuad());
        ss.str("");
        ss << "BREQZ I" << $$.RegNum << " ";
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad();
    }
    | expression GT expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($1.type == int_) {
            ss << "SGRTI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SGRTF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        
        $$.falseList.push_back(buffer->nextQuad());
        ss.str("");
        ss << "BREQZ I" << $$.RegNum << " ";
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad();
    }
    | expression LTEQ expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($1.type == int_) {
            ss << "SLETI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SLETF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        
        $$.falseList.push_back(buffer->nextQuad());
        ss.str("");
        ss << "BREQZ I" << $$.RegNum << " ";
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad();
    }
    | expression GTEQ expression {
        if ($1.type != $3.type) {
            semanticError("Type mismatch");
        }
        
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($1.type == int_) {
            ss << "SGETI I" << $$.RegNum << " I" << $1.RegNum << " I" << $3.RegNum;
        } else {
            ss << "SGETF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());
        
        $$.falseList.push_back(buffer->nextQuad());
        ss.str("");
        ss << "BREQZ I" << $$.RegNum << " ";
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad();
    }
    | LPAREN expression RPAREN {
        $$ = $2;
    }
    | LPAREN type_specifier RPAREN expression {
        $$.type = $2.type;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        if ($4.type == int_ && $2.type == float_) {
            // int to float
            ss << "CITOF F" << $$.RegNum << " I" << $4.RegNum;
            emitCode(ss.str());
        } else if ($4.type == float_ && $2.type == int_) {
            // float to int
            ss << "CFTOI I" << $$.RegNum << " F" << $4.RegNum;
            emitCode(ss.str());
        } else {
            // Same type, just copy
            if ($2.type == int_) {
                ss << "COPYI I" << $$.RegNum << " I" << $4.RegNum;
            } else {
                ss << "COPYF F" << $$.RegNum << " F" << $4.RegNum;
            }
            emitCode(ss.str());
        }
        
        $$.quad = buffer->nextQuad() - 1;
    }
    | ID {
        Symbol* sym = lookup($1.name);
        
        if (!sym) {
            semanticError("Undeclared variable");
        }
        
        $$.type = sym->type[sym->depth];
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        ss << "LOADI I" << $$.RegNum << " I1 " << sym->offset[sym->depth];
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad() - 1;
    }
    | NUM {
        $$.type = int_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        ss << "COPYI I" << $$.RegNum << " " << $1.name;
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad() - 1;
    }
    | REALNUM {
        $$.type = float_;
        $$.RegNum = allocateRegister();
        
        stringstream ss;
        ss << "COPYF F" << $$.RegNum << " " << $1.name;
        emitCode(ss.str());
        
        $$.quad = buffer->nextQuad() - 1;
    }
    | ID LPAREN argument_list RPAREN {
        Function* func = lookupFunction($1.name);
        
        if (!func) {
            semanticError("Undeclared function");
        }
        
        if ($3.paramTypes.size() != func->paramTypes.size()) {
            semanticError("Wrong number of arguments");
        }
        
        for (size_t i = 0; i < $3.paramTypes.size(); i++) {
            if ($3.paramTypes[i] != func->paramTypes[i]) {
                semanticError("Argument type mismatch");
            }
        }
        
        // Calling convention (matches provided reference outputs):
        // - Save I0..I15 and F0..F15 below current SP
        // - Allocate a call frame of: saved-regs + (return slot + params)
        // - Set FP=SP
        // - Params live at [FP-8], [FP-12], ... and return at [FP-4]
        const int savedIntCount = 16;   // I0..I15
        const int savedFloatCount = 16; // F0..F15
        const int savedBytes = (savedIntCount + savedFloatCount) * 4; // 128
        int extraBytes = (int)(($3.paramRegs.size() + 1) * 4); // return slot + params
        int frameSizeBytes = savedBytes + extraBytes;

        // Save integer registers at [SP + 0..60]
        for (int r = 0; r < savedIntCount; r++) {
            stringstream ss;
            ss << "STORI I" << r << " I2 " << (r * 4);
            emitCode(ss.str());
        }
        // Save float registers at [SP + 64..124]
        emitCode("CITOF F2 I2");
        for (int r = 0; r < savedFloatCount; r++) {
            stringstream ss;
            ss << "STORF F" << r << " F2 " << (64 + (r * 4));
            emitCode(ss.str());
        }

        // Allocate frame and set FP
        {
            stringstream ss;
            ss << "ADD2I I2 I2 " << frameSizeBytes;
            emitCode(ss.str());
        }
        emitCode("COPYI I1 I2");
        emitCode("CITOF F1 I1");

        // Store parameters into their fixed slots
        for (size_t i = 0; i < $3.paramRegs.size(); i++) {
            int offset = -8 - ((int)i * 4);
            stringstream ss;
            if ($3.paramTypes[i] == float_) {
                ss << "STORF F" << $3.paramRegs[i] << " F1 " << offset;
            } else {
                ss << "STORI I" << $3.paramRegs[i] << " I1 " << offset;
            }
            emitCode(ss.str());
        }
        
        // Call
        if (func->isDefined) {
            stringstream ss;
            ss << "JLINK " << func->startLineImplementation;
            emitCode(ss.str());
        } else {
            int callLine = buffer->nextQuad();
            func->callingLines.push_back(callLine);
            emitCode("JLINK ");
        }
        
        // Get return value (from current FP frame) into a reg >= 16
        // so it won't be overwritten by restoring I0..I15 / F0..F15.
        $$.type = func->returnType;
        do {
            $$.RegNum = allocateRegister();
        } while ($$.RegNum < 16);
        emitCode("CITOF F1 I1");
        {
            stringstream ss;
            if (func->returnType == float_) {
                ss << "LOADF F" << $$.RegNum << " F1 -4";
            } else {
                ss << "LOADI I" << $$.RegNum << " I1 -4";
            }
            emitCode(ss.str());
        }

        // Restore SP to old SP (base of saved regs)
        emitCode("COPYI I2 I1");
        {
            stringstream ss;
            ss << "SUBTI I2 I2 " << frameSizeBytes;
            emitCode(ss.str());
        }

        // Restore integer registers (restore I2 last since it's our base)
        for (int r = 0; r < savedIntCount; r++) {
            if (r == 2) {
                continue;
            }
            stringstream ss;
            ss << "LOADI I" << r << " I2 " << (r * 4);
            emitCode(ss.str());
        }
        // Restore float registers (restore F2 last since it's our base)
        emitCode("CITOF F2 I2");
        for (int r = 0; r < savedFloatCount; r++) {
            if (r == 2) {
                continue;
            }
            stringstream ss;
            ss << "LOADF F" << r << " F2 " << (64 + (r * 4));
            emitCode(ss.str());
        }
        // Restore base registers last
        emitCode("LOADI I2 I2 8");
        emitCode("LOADF F2 F2 72");
        
        $$.quad = buffer->nextQuad() - 1;
    }
    ;

argument_list:
    argument_list_non_empty {
        $$ = $1;
    }
    | /* empty */ {
        $$.paramTypes.clear();
        $$.paramRegs.clear();
    }
    ;

argument_list_non_empty:
    expression {
        $$.paramTypes.push_back($1.type);
        $$.paramRegs.push_back($1.RegNum);
    }
    | argument_list_non_empty COMMA expression {
        $$ = $1;
        $$.paramTypes.push_back($3.type);
        $$.paramRegs.push_back($3.RegNum);
    }
    ;

%%

void yyerror(const char* s) {
    cerr << "Syntax error: '" << s << "' in line number " << yylineno << endl;
    exit(SYNTAX_ERROR);
}

void semanticError(const string& msg) {
    cerr << "Semantic error: " << msg << " in line number " << yylineno << endl;
    exit(SEMANTIC_ERROR);
}

void declareVariable(const string& id, Type type) {
    Symbol& sym = symbolTable[id];
    
    if (sym.type.find(currentDepth) != sym.type.end()) {
        semanticError("Variable already declared");
    }
    
    sym.type[currentDepth] = type;
    sym.offset[currentDepth] = currentOffset;
    sym.depth = currentDepth;
    
    currentOffset += 4;
    
    stringstream ss;
    ss << "ADD2I I2 I2 4";
    emitCode(ss.str());
}

void declareFunction(const string& id, Type returnType, const vector<Type>& paramTypes, const vector<string>& paramIds) {
    Function& func = functionTable[id];
    func.isDefined = false;
    func.returnType = returnType;
    func.paramTypes = paramTypes;
    func.paramIds = paramIds;
    func.startLineImplementation = -1;
}

void defineFunction(const string& id, int startLine) {
    Function& func = functionTable[id];
    func.isDefined = true;
    func.startLineImplementation = startLine;
    
    for (size_t i = 0; i < func.callingLines.size(); i++) {
        vector<int> patchList(1, func.callingLines[i]);
        buffer->backpatch(patchList, startLine);
    }
}

Symbol* lookup(const string& id) {
    if (symbolTable.find(id) == symbolTable.end()) {
        return NULL;
    }
    return &symbolTable[id];
}

Function* lookupFunction(const string& id) {
    if (functionTable.find(id) == functionTable.end()) {
        return NULL;
    }
    return &functionTable[id];
}

int allocateRegister() {
    int reg = regCounter++;
    if (regCounter > 30) {
        regCounter = 3;
    }
    return reg;
}

void emitCode(const string& code) {
    buffer->emit(code);
}

void generateHeader() {
    // Build unimplemented functions line (external calls)
    string unimplementedLine = "<unimplemented>";
    for (map<string, Function>::iterator it = functionTable.begin(); it != functionTable.end(); ++it) {
        if (!it->second.isDefined) {
            // The linker only *fixes* existing jump targets; it doesn't insert them.
            // For calls to functions that remain unimplemented in this module, ensure
            // the JLINK instruction already has a numeric placeholder target.
            // We use 0 as an intentionally-invalid label that the linker will replace.
            for (size_t i = 0; i < it->second.callingLines.size(); i++) {
                vector<int> patchList(1, it->second.callingLines[i]);
                buffer->backpatch(patchList, 0);
            }

            // If there are no recorded call sites, still list the function name.
            // (Some reference outputs include externals declared but not called.)
            if (it->second.callingLines.empty()) {
                unimplementedLine += " " + it->first;
            } else {
                // List all call sites for this external function
                for (size_t i = 0; i < it->second.callingLines.size(); i++) {
                    unimplementedLine += " " + it->first + "," + intToString(it->second.callingLines[i]);
                }
            }
        }
    }
    
    // Build implemented functions line (sorted by name for stable output)
    vector<pair<string, int> > impl;
    impl.reserve(implementedFuncs.size());
    for (size_t i = 0; i < implementedFuncs.size(); i++) {
        size_t commaPos = implementedFuncs[i].find(',');
        if (commaPos == string::npos) {
            continue;
        }
        string name = implementedFuncs[i].substr(0, commaPos);
        int line = atoi(implementedFuncs[i].substr(commaPos + 1).c_str());
        impl.push_back(make_pair(name, line));
    }
    sort(impl.begin(), impl.end());
    string implementedLine = "<implemented>";
    for (size_t i = 0; i < impl.size(); i++) {
        implementedLine += " " + impl[i].first + "," + intToString(impl[i].second);
    }
    
    buffer->frontEmit("</header>");
    buffer->frontEmit(implementedLine);
    buffer->frontEmit(unimplementedLine);
    buffer->frontEmit("<header>");
}

string getGeneratedCode() {
    if (buffer) {
        return buffer->printBuffer();
    }
    return "";
}
