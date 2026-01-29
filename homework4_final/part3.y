%{
/*
    EE046266: Compilation Methods - Winter 2025-2026
    Parser and Code Generator for C-- Language - Based on project specification
*/

#include "part3_helpers.hpp"

#include <iomanip>
#include <sstream>

extern int yylex();
extern int yylineno;
extern char* yytext;
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
void popScope(int newDepth);
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
%right CAST

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

        popScope(currentDepth);
        
        currentOffset = 0;
    }
    ;

param_list:
    param_group_list {
        $$.paramTypes = $1.paramTypes;
        $$.paramIds = $1.paramIds;

        // Disallow duplicate parameter names
        for (size_t i = 0; i < $$.paramIds.size(); i++) {
            for (size_t j = i + 1; j < $$.paramIds.size(); j++) {
                if ($$.paramIds[i] == $$.paramIds[j]) {
                    semanticError("Duplicate parameter name");
                }
            }
        }
    }
    | /* empty */ {
        $$.paramTypes.clear();
        $$.paramIds.clear();
    }
    ;

// Function parameters can be grouped: a,b:int
param_group_list:
    param_group {
        $$ = $1;
    }
    | param_group_list COMMA param_group {
        $$ = $1;
        for (size_t i = 0; i < $3.paramTypes.size(); i++) {
            $$.paramTypes.push_back($3.paramTypes[i]);
            $$.paramIds.push_back($3.paramIds[i]);
        }
    }
    ;

param_group:
    id_list COLON type_specifier {
        $$.paramTypes.clear();
        $$.paramIds.clear();
        for (size_t i = 0; i < $1.paramIds.size(); i++) {
            $$.paramIds.push_back($1.paramIds[i]);
            $$.paramTypes.push_back($3.type);
        }
    }
    ;

id_list:
    ID {
        $$.paramIds.clear();
        $$.paramIds.push_back($1.name);
    }
    | id_list COMMA ID {
        $$ = $1;
        $$.paramIds.push_back($3.name);
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

        popScope(currentDepth);
    }
    ;

declaration_stmt:
    id_list COLON type_specifier SEMICOLON {
        for (size_t i = 0; i < $1.paramIds.size(); i++) {
            declareVariable($1.paramIds[i], $3.type);
        }
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
        if ($3.type == float_) {
            int baseF = allocateRegister();
            ss << "CITOF F" << baseF << " I" << targetReg;
            emitCode(ss.str());

            ss.str("");
            ss << "STORF F" << $3.RegNum << " F" << baseF << " 0";
        } else {
            ss << "STORI I" << $3.RegNum << " I" << targetReg << " 0";
        }
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
            int baseF = allocateRegister();
            ss << "CITOF F" << baseF << " I1";
            emitCode(ss.str());

            ss.str("");
            ss << "STORF F" << $2.RegNum << " F" << baseF << " -4";
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
        if (sym->type[sym->depth] == float_) {
            int baseF = allocateRegister();
            ss << "CITOF F" << baseF << " I" << addrReg;
            emitCode(ss.str());

            ss.str("");
            ss << "STORF F" << reg << " F" << baseF << " 0";
        } else {
            ss << "STORI I" << reg << " I" << addrReg << " 0";
        }
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
            ss << "SEQEF F" << $$.RegNum << " F" << $1.RegNum << " F" << $3.RegNum;
        }
        emitCode(ss.str());

        // Float comparisons yield a float (0.0/1.0); convert to int (0/1) for branches and expression value.
        if ($1.type == float_) {
            ss.str("");
            ss << "CFTOI I" << $$.RegNum << " F" << $$.RegNum;
            emitCode(ss.str());
        }
        
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

        if ($1.type == float_) {
            ss.str("");
            ss << "CFTOI I" << $$.RegNum << " F" << $$.RegNum;
            emitCode(ss.str());
        }
        
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
            // Avoid SLTTI (not supported by some rx-vm builds): a < b  <=>  b > a
            ss << "SGRTI I" << $$.RegNum << " I" << $3.RegNum << " I" << $1.RegNum;
        } else {
            // a < b  <=>  b > a
            ss << "SGRTF F" << $$.RegNum << " F" << $3.RegNum << " F" << $1.RegNum;
        }
        emitCode(ss.str());

        if ($1.type == float_) {
            ss.str("");
            ss << "CFTOI I" << $$.RegNum << " F" << $$.RegNum;
            emitCode(ss.str());
        }
        
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

        if ($1.type == float_) {
            ss.str("");
            ss << "CFTOI I" << $$.RegNum << " F" << $$.RegNum;
            emitCode(ss.str());
        }
        
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
        
        // Implement a <= b as !(a > b).
        // This avoids relying on SLETI/SLETF semantics across different rx-vm builds.
        int tmp = allocateRegister();
        stringstream ss;
        if ($1.type == int_) {
            ss << "SGRTI I" << tmp << " I" << $1.RegNum << " I" << $3.RegNum;
            emitCode(ss.str());
        } else {
            ss << "SGRTF F" << tmp << " F" << $1.RegNum << " F" << $3.RegNum;
            emitCode(ss.str());

            ss.str("");
            ss << "CFTOI I" << tmp << " F" << tmp;
            emitCode(ss.str());
        }

        ss.str("");
        ss << "COPYI I" << $$.RegNum << " 1";
        emitCode(ss.str());

        ss.str("");
        ss << "SUBTI I" << $$.RegNum << " I" << $$.RegNum << " I" << tmp;
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
        
        // Implement a >= b as !(a < b) == !(b > a).
        int tmp = allocateRegister();
        stringstream ss;
        if ($1.type == int_) {
            ss << "SGRTI I" << tmp << " I" << $3.RegNum << " I" << $1.RegNum;
            emitCode(ss.str());
        } else {
            ss << "SGRTF F" << tmp << " F" << $3.RegNum << " F" << $1.RegNum;
            emitCode(ss.str());

            ss.str("");
            ss << "CFTOI I" << tmp << " F" << tmp;
            emitCode(ss.str());
        }

        ss.str("");
        ss << "COPYI I" << $$.RegNum << " 1";
        emitCode(ss.str());

        ss.str("");
        ss << "SUBTI I" << $$.RegNum << " I" << $$.RegNum << " I" << tmp;
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
    | LPAREN type_specifier RPAREN expression %prec CAST {
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
        if ($$.type == float_) {
            int addrReg = allocateRegister();
            ss << "ADD2I I" << addrReg << " I1 " << sym->offset[sym->depth];
            emitCode(ss.str());

            int baseF = allocateRegister();
            ss.str("");
            ss << "CITOF F" << baseF << " I" << addrReg;
            emitCode(ss.str());

            ss.str("");
            ss << "LOADF F" << $$.RegNum << " F" << baseF << " 0";
        } else {
            ss << "LOADI I" << $$.RegNum << " I1 " << sym->offset[sym->depth];
        }
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
        
        // Emit float constants in a stable form (some toolchains are picky)
        double v = 0.0;
        try {
            v = stod($1.name);
        } catch (...) {
            semanticError("Invalid float literal");
        }

        ostringstream lit;
        lit << fixed << setprecision(6) << v;

        stringstream ss;
        ss << "COPYF F" << $$.RegNum << " " << lit.str();
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

        // Map actual args -> formal params (supports named arguments: label:expr)
        size_t formalCount = func->paramTypes.size();
        vector<int> passedRegs(formalCount, -1);
        vector<Type> passedTypes(formalCount, void_t);
        vector<int> provided(formalCount, 0);

        size_t nextPositional = 0;
        for (size_t i = 0; i < $3.paramTypes.size(); i++) {
            const string& label = (i < $3.paramLabels.size()) ? $3.paramLabels[i] : string("");
            if (label.empty()) {
                if (nextPositional >= formalCount) {
                    semanticError("Too many positional arguments");
                }
                if (provided[nextPositional]) {
                    semanticError("Parameter passed twice");
                }
                passedRegs[nextPositional] = $3.paramRegs[i];
                passedTypes[nextPositional] = $3.paramTypes[i];
                provided[nextPositional] = 1;
                nextPositional++;
            } else {
                int foundIdx = -1;
                for (size_t j = 0; j < func->paramIds.size(); j++) {
                    if (func->paramIds[j] == label) {
                        foundIdx = (int)j;
                        break;
                    }
                }
                if (foundIdx < 0) {
                    semanticError("Unknown named parameter");
                }
                if (provided[foundIdx]) {
                    semanticError("Parameter passed twice");
                }
                passedRegs[foundIdx] = $3.paramRegs[i];
                passedTypes[foundIdx] = $3.paramTypes[i];
                provided[foundIdx] = 1;
            }
        }

        for (size_t j = 0; j < formalCount; j++) {
            if (!provided[j]) {
                semanticError("Missing argument for parameter");
            }
            if (passedTypes[j] != func->paramTypes[j]) {
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

        // Store parameters into their fixed slots (by formal index)
        for (size_t i = 0; i < formalCount; i++) {
            int offset = -8 - ((int)i * 4);
            stringstream ss;
            if (func->paramTypes[i] == float_) {
                ss << "STORF F" << passedRegs[i] << " F1 " << offset;
            } else {
                ss << "STORI I" << passedRegs[i] << " I1 " << offset;
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
        
        // Get return value (from current FP frame) FIRST before any register restoration
        // Store it in a safe location (on stack above saved regs) temporarily
        $$.type = func->returnType;
        emitCode("CITOF F1 I1");
        
        // Save the old SP (base of saved regs) in I3
        emitCode("COPYI I3 I1");
        {
            stringstream ss;
            ss << "SUBTI I3 I3 " << frameSizeBytes;
            emitCode(ss.str());
        }
        
        // Read return value and save it ABOVE the current frame (won't be clobbered)
        {
            stringstream ss;
            if (func->returnType == float_) {
                ss << "LOADF F" << savedFloatCount << " F1 -4";
            } else {
                ss << "LOADI I" << savedIntCount << " I1 -4";
            }
            emitCode(ss.str());
        }

        // Restore SP to saved base
        emitCode("COPYI I2 I3");

        // Restore integer registers (skip I2 and I3)
        for (int r = 0; r < savedIntCount; r++) {
            if (r == 2 || r == 3) {
                continue;
            }
            stringstream ss;
            ss << "LOADI I" << r << " I2 " << (r * 4);
            emitCode(ss.str());
        }
        // Restore float registers (skip F2)
        emitCode("CITOF F2 I2");
        for (int r = 0; r < savedFloatCount; r++) {
            if (r == 2) {
                continue;
            }
            stringstream ss;
            ss << "LOADF F" << r << " F2 " << (64 + (r * 4));
            emitCode(ss.str());
        }
        // Restore base registers last (I3, I2, F2)
        emitCode("LOADI I3 I2 12");
        emitCode("LOADI I2 I2 8");
        emitCode("CITOF F2 I2");
        emitCode("LOADF F2 F2 72");
        
        // Now allocate a register for the return value and copy from safe register
        do {
            $$.RegNum = allocateRegister();
        } while ($$.RegNum < 16);
        {
            stringstream ss;
            if (func->returnType == float_) {
                ss << "COPYF F" << $$.RegNum << " F" << savedFloatCount;
            } else {
                ss << "COPYI I" << $$.RegNum << " I" << savedIntCount;
            }
            emitCode(ss.str());
        }
        $$.quad = buffer->nextQuad() - 1;
    }
    ;

argument_list:
    /* empty */ {
        $$.paramTypes.clear();
        $$.paramRegs.clear();
        $$.paramLabels.clear();
    }
    | positional_arg_list named_arg_list_tail_opt {
        $$ = $1;
        // append named tail (if any)
        for (size_t i = 0; i < $2.paramTypes.size(); i++) {
            $$.paramTypes.push_back($2.paramTypes[i]);
            $$.paramRegs.push_back($2.paramRegs[i]);
            $$.paramLabels.push_back($2.paramLabels[i]);
        }
    }
    | named_arg_list {
        $$ = $1;
    }
    ;

// Positional arguments only (expressions).
positional_arg_list:
    expression {
        $$.paramTypes.clear();
        $$.paramRegs.clear();
        $$.paramLabels.clear();
        $$.paramTypes.push_back($1.type);
        $$.paramRegs.push_back($1.RegNum);
        $$.paramLabels.push_back("");
    }
    | positional_arg_list COMMA expression {
        $$ = $1;
        $$.paramTypes.push_back($3.type);
        $$.paramRegs.push_back($3.RegNum);
        $$.paramLabels.push_back("");
    }
    ;

// If there are named args after some positionals, they must start after a comma.
named_arg_list_tail_opt:
    /* empty */ {
        $$.paramTypes.clear();
        $$.paramRegs.clear();
        $$.paramLabels.clear();
    }
    | COMMA named_arg_list {
        $$ = $2;
    }
    ;

// Named arguments list: label:expression
named_arg_list:
    named_arg {
        $$ = $1;
    }
    | named_arg_list COMMA named_arg {
        $$ = $1;
        $$.paramTypes.push_back($3.paramTypes[0]);
        $$.paramRegs.push_back($3.paramRegs[0]);
        $$.paramLabels.push_back($3.paramLabels[0]);
    }
    ;

named_arg:
    ID COLON expression {
        $$.paramTypes.clear();
        $$.paramRegs.clear();
        $$.paramLabels.clear();
        $$.paramTypes.push_back($3.type);
        $$.paramRegs.push_back($3.RegNum);
        $$.paramLabels.push_back($1.name);
    }
    ;

%%

void yyerror(const char* s) {
    (void)s;
    string lexeme = (yytext && yytext[0] != '\0') ? string(yytext) : string("EOF");
    cerr << "Syntax error: '" << lexeme << "' in line number " << yylineno << endl;
    exit(SYNTAX_ERROR);
}

void semanticError(const string& msg) {
    cerr << "Semantic error: " << msg << " in line number " << yylineno << endl;
    exit(SEMANTIC_ERROR);
}

// Remove symbols declared in scopes deeper than newDepth.
// If an identifier was shadowed, restore its previous (outer) declaration.
void popScope(int newDepth) {
    for (auto it = symbolTable.begin(); it != symbolTable.end(); ) {
        Symbol& sym = it->second;

        if (sym.depth <= newDepth) {
            ++it;
            continue;
        }

        while (sym.depth > newDepth) {
            sym.type.erase(sym.depth);
            sym.offset.erase(sym.depth);

            if (sym.type.empty()) {
                break;
            }

            sym.depth = sym.type.rbegin()->first;
        }

        if (sym.type.empty()) {
            it = symbolTable.erase(it);
        } else {
            ++it;
        }
    }
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
