/* 
 * Compilation Course - Project Part 3
 * Parser and Code Generator for C-- Language
 * EE046266 Winter 2025-2026
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <map>
#include <vector>
#include <string>
#include <algorithm>
#include "part3_helpers.hpp"

/* External from lexer */
extern int yylex(void);
extern char* yytext;
extern int line_number;
extern FILE* yyin;

/* Error handling function */
void yyerror(const char *s);

/* Semantic error reporting */
void semanticError(const string& msg);

/* Helper functions for semantic analysis */
void checkTypesMatch(Type t1, Type t2, const string& operation);
void declareVariable(const string& id, Type type);
void clearFunctionScope();
void declareFunction(const string& id, Type returnType, vector<Type>& paramTypes, vector<string>& paramIds, vector<string>& paramLabels);
void defineFunction(const string& id);
Type getVariableType(const string& id);
bool isVariableDeclared(const string& id);
bool isFunctionDeclared(const string& id);
Type castType(Type from, Type to);
void checkFunctionCall(const string& funcName, vector<Type>& argTypes, vector<string>& argLabels, vector<int>& argRegs);

/* Code generation helpers */
int newTemp(Type type);
string getRegName(int regNum);
void emitArithmetic(int result, int op1, int op2, const string& operation, Type type);
void emitRelational(int result, int op1, int op2, const string& operation, Type type);

/* Global variables - declared as extern, defined in rx-cc.cpp */
extern int currentDepth;
extern int currentOffset;
extern int tempCounter;
extern int labelCounter;
extern map<int, Type> registerTypes;
extern string currentFunction;
extern Type currentFunctionReturnType;
extern bool inFunctionBody;
extern bool currentFunctionHasReturn;

/* Define YYSTYPE directly as yystype */
#define YYSTYPE yystype

%}

/* Token declarations */
%token INT FLOAT VOID WRITE READ WHILE DO IF THEN ELSE RETURN
%token ID INTEGERNUM REALNUM STR
%token RELOP ADDOP MULOP ASSIGN AND OR NOT
%token LPAREN RPAREN LBRACE RBRACE COMMA SEMICOLON COLON

/* Operator precedence and associativity (lowest to highest) */
%right ASSIGN
%left OR
%left AND
%left RELOP
%left ADDOP
%left MULOP
%right NOT
%right CAST
%left LPAREN RPAREN

%%

/* Grammar rules with semantic actions and code generation */

PROGRAM:
    FDEFS
    { 
        // Check that if main exists, it must be defined (not just declared)
        // main() is optional to allow library modules without main
        if (isFunctionDeclared("main") && !functionTable["main"].isDefined) {
            semanticError("main function must be defined");
        }
        
        $$ = $1;
    }
    ;

FDEFS:
    FDEFS FUNC_DEF_API BLK
    {
        // Check if non-void function has return statement
        if ($2.type != void_t && !currentFunctionHasReturn) {
            semanticError("Non-void function must have a return statement");
        }
        
        // Complete function definition
        defineFunction($2.name);
        buffer->emit("RETRN");  // Add return at end if not present
        
        inFunctionBody = false;
        currentFunction = "";
        currentDepth = 0;
        currentOffset = 0;
        
        $$ = $1;
    }
    | FDEFS FUNC_DEC_API
    {
        // Function declaration only
        $$ = $1;
    }
    | /* empty */
    {
        $$.name = "";
    }
    ;

FUNC_DEC_API:
    TYPE ID LPAREN RPAREN SEMICOLON
    {
        vector<Type> paramTypes;
        vector<string> paramIds;
        vector<string> paramLabels;
        declareFunction($2.name, $1.type, paramTypes, paramIds, paramLabels);
        
        $$.name = $2.name;
        $$.type = $1.type;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN SEMICOLON
    {
        declareFunction($2.name, $1.type, $4.paramTypes, $4.paramIds, $4.paramLabels);
        
        $$.name = $2.name;
        $$.type = $1.type;
    }
    ;

FUNC_DEF_API:
    TYPE ID LPAREN RPAREN
    {
        vector<Type> paramTypes;
        vector<string> paramIds;
        vector<string> paramLabels;
        
        if (!isFunctionDeclared($2.name)) {
            declareFunction($2.name, $1.type, paramTypes, paramIds, paramLabels);
        }
        
        // Start function implementation
        clearFunctionScope();  // Clear previous function's variables
        currentFunction = $2.name;
        currentFunctionReturnType = $1.type;
        inFunctionBody = true;
        currentFunctionHasReturn = false;  // Reset return flag
        currentDepth = 1;
        currentOffset = 0;
        
        Function& func = functionTable[$2.name];
        func.startLineImplementation = buffer->nextQuad();
        buffer->emit("LABEL " + $2.name);
        
        $$.name = $2.name;
        $$.type = $1.type;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN
    {
        if (!isFunctionDeclared($2.name)) {
            declareFunction($2.name, $1.type, $4.paramTypes, $4.paramIds, $4.paramLabels);
        }
        
        // Start function implementation
        clearFunctionScope();  // Clear previous function's variables
        currentFunction = $2.name;
        currentFunctionReturnType = $1.type;
        inFunctionBody = true;
        currentFunctionHasReturn = false;  // Reset return flag
        currentDepth = 1;
        currentOffset = 0;
        
        Function& func = functionTable[$2.name];
        func.startLineImplementation = buffer->nextQuad();
        buffer->emit("LABEL " + $2.name);
        
        // Load parameters into registers/memory
        for (int i = 0; i < $4.paramIds.size(); i++) {
            declareVariable($4.paramIds[i], $4.paramTypes[i]);
        }
        
        $$.name = $2.name;
        $$.type = $1.type;
        $$.paramTypes = $4.paramTypes;
        $$.paramIds = $4.paramIds;
        $$.paramLabels = $4.paramLabels;
    }
    ;

FUNC_ARGLIST:
    FUNC_ARGLIST COMMA DCL
    {
        $$ = $1;
        $$.paramTypes.push_back($3.type);
        $$.paramIds.push_back($3.name);
        
        // Create label for named parameter: "label:name"
        string label = $3.name + ":" + $3.name;
        $$.paramLabels.push_back(label);
    }
    | DCL
    {
        $$.paramTypes.push_back($1.type);
        $$.paramIds.push_back($1.name);
        
        string label = $1.name + ":" + $1.name;
        $$.paramLabels.push_back(label);
    }
    ;

BLK:
    LBRACE STLIST RBRACE
    {
        $$ = $2;
    }
    ;

DCL:
    ID COLON TYPE
    {
        $$.name = $1.name;
        $$.type = $3.type;
        
        if ($3.type == void_t) {
            semanticError("Cannot declare variable of type void: " + $1.name);
        }
        
        if (inFunctionBody) {
            declareVariable($1.name, $3.type);
        }
    }
    | ID COMMA DCL
    {
        $$.name = $1.name;
        $$.type = $3.type;
        
        if ($3.type == void_t) {
            semanticError("Cannot declare variable of type void: " + $1.name);
        }
        
        if (inFunctionBody) {
            declareVariable($1.name, $3.type);
        }
    }
    ;

TYPE:
    INT     { $$.type = int_; $$.name = "int"; }
    | FLOAT { $$.type = float_; $$.name = "float"; }
    | VOID  { $$.type = void_t; $$.name = "void"; }
    ;

STLIST:
    STLIST M STMT
    {
        // Backpatch nextList of previous statement
        buffer->backpatch($1.nextList, $2.quad);
        $$.nextList = $3.nextList;
    }
    | /* empty */
    {
        $$.nextList = vector<int>();
    }
    ;

M:
    /* empty - marker for backpatching */
    {
        $$.quad = buffer->nextQuad();
    }
    ;

STMT:
    DCL SEMICOLON
    {
        $$.nextList = vector<int>();
    }
    | ASSN          
    { 
        $$ = $1;
    }
    | EXP SEMICOLON 
    {
        // Expression as statement must be void type (or cast to void)
        if ($1.type != void_t) {
            semanticError("Expression in statement context must be of type void");
        }
        $$.nextList = vector<int>();
    }
    | CNTRL         
    { 
        $$ = $1;
    }
    | READ_STMT     
    { 
        $$ = $1;
    }
    | WRITE_STMT    
    { 
        $$ = $1;
    }
    | RETURN_STMT        
    { 
        $$ = $1;
    }
    | BLK           
    { 
        $$ = $1;
    }
    ;

RETURN_STMT:
    RETURN EXP SEMICOLON
    {
        // Check return type matches function
        if (currentFunctionReturnType == void_t) {
            semanticError("Cannot return value from void function");
        }
        checkTypesMatch($2.type, currentFunctionReturnType, "return");
        
        currentFunctionHasReturn = true;  // Mark that we've seen a return
        
        // Store return value in I1 (by convention)
        string srcReg = "I" + intToString($2.RegNum);
        if ($2.type == int_) {
            buffer->emit("COPYI I1 " + srcReg);
        } else {
            buffer->emit("COPYF I1 " + srcReg);
        }
        buffer->emit("RETRN");
        
        $$.nextList = vector<int>();
    }
    | RETURN SEMICOLON
    {
        if (currentFunctionReturnType != void_t) {
            semanticError("Must return value from non-void function");
        }
        
        currentFunctionHasReturn = true;  // Mark that we've seen a return
        
        buffer->emit("RETRN");
        $$.nextList = vector<int>();
    }
    ;

WRITE_STMT:
    WRITE LPAREN EXP RPAREN SEMICOLON
    {
        // Generate write instruction
        string regName = "I" + intToString($3.RegNum);
        if ($3.type == int_) {
            buffer->emit("PRNTI " + regName);
        } else if ($3.type == float_) {
            buffer->emit("PRNTF " + regName);
        } else {
            semanticError("Cannot write expression of type void");
        }
        
        $$.nextList = vector<int>();
    }
    | WRITE LPAREN STR RPAREN SEMICOLON
    {
        // Write string literal - emit PRNTC for each character with escape sequence processing
        string str = $3.name;
        for (size_t i = 0; i < str.length(); i++) {
            int asciiValue;
            if (str[i] == '\\' && i + 1 < str.length()) {
                // Process escape sequences
                i++;  // Move to next character
                switch (str[i]) {
                    case 'n':  asciiValue = 10; break;  // newline
                    case 't':  asciiValue = 9;  break;  // tab
                    case '"':  asciiValue = 34; break;  // quote
                    default:
                        semanticError("Invalid escape sequence");
                        asciiValue = str[i];
                }
            } else {
                asciiValue = (int)str[i];
            }
            buffer->emit("PRNTC " + intToString(asciiValue));
        }
        $$.nextList = vector<int>();
    }
    ;

READ_STMT:
    READ LPAREN LVAL RPAREN SEMICOLON
    {
        Type varType = getVariableType($3.name);
        
        int tempReg = newTemp(varType);
        string regName = "I" + intToString(tempReg);
        
        if (varType == int_) {
            buffer->emit("READI " + regName);
        } else if (varType == float_) {
            buffer->emit("READF " + regName);
        } else {
            semanticError("Cannot read into void variable");
        }
        
        // Store to variable
        Symbol& sym = symbolTable[$3.name];
        string instruction = (varType == int_) ? "STORI" : "STORF";
        buffer->emit(instruction + " " + regName + " I0 " + intToString(sym.offset[currentDepth]));
        
        $$.nextList = vector<int>();
    }
    ;

ASSN:
    LVAL ASSIGN EXP SEMICOLON
    {
        Type varType = getVariableType($1.name);
        checkTypesMatch($3.type, varType, "assignment");
        
        // Generate store instruction
        Symbol& sym = symbolTable[$1.name];
        string regName = "I" + intToString($3.RegNum);
        string instruction = (varType == int_) ? "STORI" : "STORF";
        buffer->emit(instruction + " " + regName + " I0 " + intToString(sym.offset[currentDepth]));
        
        $$.nextList = vector<int>();
    }
    ;

LVAL:
    ID 
    { 
        if (!isVariableDeclared($1.name)) {
            semanticError("Undeclared variable: " + $1.name);
        }
        $$.name = $1.name;
        $$.type = getVariableType($1.name);
    }
    ;

CNTRL:
    IF BEXP THEN M STMT ELSE M STMT
    {
        // Backpatch true list to M1 (then part)
        buffer->backpatch($2.trueList, $4.quad);
        // Backpatch false list to M2 (else part)
        buffer->backpatch($2.falseList, $7.quad);
        
        // Merge nextLists
        $$.nextList = merge($5.nextList, $8.nextList);
    }
    | IF BEXP THEN M STMT
    {
        // Backpatch true list to M (then part)
        buffer->backpatch($2.trueList, $4.quad);
        // Merge false list and STMT nextList
        $$.nextList = merge($2.falseList, $5.nextList);
    }
    | WHILE M BEXP DO M STMT
    {
        // Backpatch true list to M2 (body)
        buffer->backpatch($3.trueList, $5.quad);
        // Backpatch STMT nextList back to M1 (loop start)
        buffer->backpatch($6.nextList, $2.quad);
        // Jump back to loop start
        buffer->emit("UJUMP " + intToString($2.quad));
        // False list becomes nextList
        $$.nextList = $3.falseList;
    }
    ;

BEXP:
    BEXP OR M BEXP
    {
        // Backpatch B1.falseList to M
        buffer->backpatch($1.falseList, $3.quad);
        // Merge true lists
        $$.trueList = merge($1.trueList, $4.trueList);
        $$.falseList = $4.falseList;
    }
    | BEXP AND M BEXP
    {
        // Backpatch B1.trueList to M
        buffer->backpatch($1.trueList, $3.quad);
        // Merge false lists
        $$.falseList = merge($1.falseList, $4.falseList);
        $$.trueList = $4.trueList;
    }
    | NOT BEXP
    {
        // Swap true and false lists
        $$.trueList = $2.falseList;
        $$.falseList = $2.trueList;
    }
    | EXP RELOP EXP
    {
        checkTypesMatch($1.type, $3.type, "relational operation");
        
        // Generate comparison + branch
        string reg1 = "I" + intToString($1.RegNum);
        string reg2 = "I" + intToString($3.RegNum);
        string op = $2.name;
        
        // Create temp register for comparison result
        int tempReg = newTemp(int_);
        string regTemp = "I" + intToString(tempReg);
        
        // Generate comparison instruction based on operator
        if (op == "==") {
            if ($1.type == int_) buffer->emit("SEQUI " + regTemp + " " + reg1 + " " + reg2);
            else buffer->emit("SEQUF " + regTemp + " " + reg1 + " " + reg2);
        }
        else if (op == "<>") {
            if ($1.type == int_) buffer->emit("SNEQI " + regTemp + " " + reg1 + " " + reg2);
            else buffer->emit("SNEQF " + regTemp + " " + reg1 + " " + reg2);
        }
        else if (op == "<") {
            // For a < b, use SGRT with swapped operands: b > a
            if ($1.type == int_) buffer->emit("SGRTI " + regTemp + " " + reg2 + " " + reg1);
            else buffer->emit("SGRTF " + regTemp + " " + reg2 + " " + reg1);
        }
        else if (op == "<=") {
            if ($1.type == int_) buffer->emit("SLETI " + regTemp + " " + reg1 + " " + reg2);
            else buffer->emit("SLETF " + regTemp + " " + reg1 + " " + reg2);
        }
        else if (op == ">") {
            if ($1.type == int_) buffer->emit("SGRTI " + regTemp + " " + reg1 + " " + reg2);
            else buffer->emit("SGRTF " + regTemp + " " + reg1 + " " + reg2);
        }
        else if (op == ">=") {
            // For a >= b, use SLET with swapped operands: b <= a
            if ($1.type == int_) buffer->emit("SLETI " + regTemp + " " + reg2 + " " + reg1);
            else buffer->emit("SLETF " + regTemp + " " + reg2 + " " + reg1);
        }
        
        // Branch if not equal to zero (comparison was true)
        $$.trueList.push_back(buffer->nextQuad());
        buffer->emit("BNEQZ " + regTemp + " ");
        
        // Unconditional jump for false case
        $$.falseList.push_back(buffer->nextQuad());
        buffer->emit("UJUMP ");
    }
    | LPAREN BEXP RPAREN
    {
        $$ = $2;
    }
    ;

EXP:
    EXP ADDOP EXP
    {
        checkTypesMatch($1.type, $3.type, "arithmetic operation");
        
        int resultReg = newTemp($1.type);
        string reg1 = "I" + intToString($1.RegNum);
        string reg2 = "I" + intToString($3.RegNum);
        string result = "I" + intToString(resultReg);
        
        if ($2.name == "+") {
            if ($1.type == int_) {
                buffer->emit("ADD2I " + result + " " + reg1 + " " + reg2);
            } else {
                buffer->emit("ADD2F " + result + " " + reg1 + " " + reg2);
            }
        } else if ($2.name == "-") {
            if ($1.type == int_) {
                buffer->emit("SUBTI " + result + " " + reg1 + " " + reg2);
            } else {
                buffer->emit("SUBTF " + result + " " + reg1 + " " + reg2);
            }
        }
        
        $$.RegNum = resultReg;
        $$.type = $1.type;
    }
    | EXP MULOP EXP
    {
        checkTypesMatch($1.type, $3.type, "arithmetic operation");
        
        int resultReg = newTemp($1.type);
        string reg1 = "I" + intToString($1.RegNum);
        string reg2 = "I" + intToString($3.RegNum);
        string result = "I" + intToString(resultReg);
        
        if ($2.name == "*") {
            if ($1.type == int_) {
                buffer->emit("MULTI " + result + " " + reg1 + " " + reg2);
            } else {
                buffer->emit("MULTF " + result + " " + reg1 + " " + reg2);
            }
        } else if ($2.name == "/") {
            if ($1.type == int_) {
                buffer->emit("DIVDI " + result + " " + reg1 + " " + reg2);
            } else {
                buffer->emit("DIVDF " + result + " " + reg1 + " " + reg2);
            }
        }
        
        $$.RegNum = resultReg;
        $$.type = $1.type;
    }
    | LPAREN EXP RPAREN
    {
        $$ = $2;
    }
    | LPAREN TYPE RPAREN EXP %prec CAST
    {
        // Type cast
        Type targetType = $2.type;
        Type sourceType = $4.type;
        
        if (targetType == void_t) {
            // Cast to void - just change type
            $$ = $4;
            $$.type = void_t;
        } else if (sourceType == targetType) {
            // Same type, no conversion needed
            $$ = $4;
        } else if (sourceType == int_ && targetType == float_) {
            // Int to float conversion
            int resultReg = newTemp(float_);
            string source = "I" + intToString($4.RegNum);
            string result = "I" + intToString(resultReg);
            buffer->emit("CITOF " + result + " " + source);
            
            $$.RegNum = resultReg;
            $$.type = float_;
        } else if (sourceType == float_ && targetType == int_) {
            // Float to int conversion
            int resultReg = newTemp(int_);
            string source = "I" + intToString($4.RegNum);
            string result = "I" + intToString(resultReg);
            buffer->emit("CFTOI " + result + " " + source);
            
            $$.RegNum = resultReg;
            $$.type = int_;
        } else if (sourceType == void_t) {
            semanticError("Cannot cast from void type");
        } else {
            semanticError("Invalid type cast");
        }
    }
    | ID    
    { 
        if (!isVariableDeclared($1.name)) {
            semanticError("Undeclared variable: " + $1.name);
        }
        
        Type varType = getVariableType($1.name);
        int tempReg = newTemp(varType);
        
        Symbol& sym = symbolTable[$1.name];
        string regName = "I" + intToString(tempReg);
        string instruction = (varType == int_) ? "LOADI" : "LOADF";
        buffer->emit(instruction + " " + regName + " I0 " + intToString(sym.offset[currentDepth]));
        
        $$.RegNum = tempReg;
        $$.type = varType;
        $$.name = $1.name;
    }
    | NUM   
    { 
        $$ = $1;
    }
    | CALL  
    { 
        $$ = $1;
    }
    ;

NUM:
    INTEGERNUM  
    { 
        int tempReg = newTemp(int_);
        string regName = "I" + intToString(tempReg);
        // Load immediate value using COPYI
        buffer->emit("COPYI " + regName + " " + $1.name);
        
        $$.RegNum = tempReg;
        $$.type = int_;
        $$.name = $1.name;
    }
    | REALNUM   
    { 
        int tempReg = newTemp(float_);
        string regName = "I" + intToString(tempReg);
        // Load immediate value using COPYF
        buffer->emit("COPYF " + regName + " " + $1.name);
        
        $$.RegNum = tempReg;
        $$.type = float_;
        $$.name = $1.name;
    }
    ;

CALL:
    ID LPAREN CALL_ARGS RPAREN
    {
        if (!isFunctionDeclared($1.name)) {
            semanticError("Undeclared function: " + $1.name);
        }
        
        checkFunctionCall($1.name, $3.paramTypes, $3.paramLabels, $3.paramRegs);
        
        // Copy arguments to parameter registers (I2, I3, I4, ...)
        for (size_t i = 0; i < $3.paramRegs.size(); i++) {
            string srcReg = "I" + intToString($3.paramRegs[i]);
            string destReg = "I" + intToString(i + 2);  // Parameters start at I2
            
            if ($3.paramTypes[i] == int_) {
                buffer->emit("COPYI " + destReg + " " + srcReg);
            } else {
                buffer->emit("COPYF " + destReg + " " + srcReg);
            }
        }
        
        // Call function using JLINK (stores return address in I0)
        Function& func = functionTable[$1.name];
        int jlinkLine = buffer->nextQuad(); // Track the line where JLINK is emitted
        // All calls are emitted as an unresolved JLINK placeholder.
        // The linker resolves the target using the header's <implemented> table and
        // the <unimplemented> (call sites) list.
        buffer->emit("JLINK -1");
        // Record this call location for linker
        functionTable[$1.name].callingLines.push_back(jlinkLine);
        
        // Get return value from I1
        Type returnType = func.returnType;
        if (returnType != void_t) {
            int resultReg = newTemp(returnType);
            string regName = "I" + intToString(resultReg);
            if (returnType == int_) {
                buffer->emit("COPYI " + regName + " I1");
            } else {
                buffer->emit("COPYF " + regName + " I1");
            }
            $$.RegNum = resultReg;
        } else {
            $$.RegNum = -1;  // No return value for void functions
        }
        
        $$.type = returnType;
        $$.name = $1.name;
    }
    ;

CALL_ARGS:
    /* empty */
    {
        $$.paramTypes = vector<Type>();
        $$.paramLabels = vector<string>();
        $$.paramRegs = vector<int>();
    }
    | POS_ARGLIST
    {
        $$ = $1;
    }
    | NAMED_ARGLIST
    {
        $$ = $1;
    }
    | POS_ARGLIST COMMA NAMED_ARGLIST
    {
        // Merge positional and named arguments
        $$.paramTypes = $1.paramTypes;
        $$.paramTypes.insert($$.paramTypes.end(), $3.paramTypes.begin(), $3.paramTypes.end());
        
        $$.paramLabels = $1.paramLabels;
        $$.paramLabels.insert($$.paramLabels.end(), $3.paramLabels.begin(), $3.paramLabels.end());
        
        $$.paramRegs = $1.paramRegs;
        $$.paramRegs.insert($$.paramRegs.end(), $3.paramRegs.begin(), $3.paramRegs.end());
    }
    ;

POS_ARGLIST:
    EXP
    {
        $$.paramTypes.push_back($1.type);
        $$.paramLabels.push_back("");  // Empty label for positional
        $$.paramRegs.push_back($1.RegNum);
    }
    | POS_ARGLIST COMMA EXP
    {
        $$ = $1;
        $$.paramTypes.push_back($3.type);
        $$.paramLabels.push_back("");
        $$.paramRegs.push_back($3.RegNum);
    }
    ;

NAMED_ARGLIST:
    NAMED_ARG
    {
        $$.paramTypes.push_back($1.type);
        $$.paramLabels.push_back($1.name);  // name is "label:value"
        $$.paramRegs.push_back($1.RegNum);
    }
    | NAMED_ARGLIST COMMA NAMED_ARG
    {
        $$ = $1;
        $$.paramTypes.push_back($3.type);
        $$.paramLabels.push_back($3.name);
        $$.paramRegs.push_back($3.RegNum);
    }
    ;

NAMED_ARG:
    ID COLON EXP
    {
        // Store label name
        $$.name = $1.name;
        $$.type = $3.type;
        $$.RegNum = $3.RegNum;
    }
    ;

%%

/* Error handling function */
void yyerror(const char *s) {
    printf("Syntax error: '%s' in line %d\n", yytext, line_number);
    exit(SYNTAX_ERROR);
}

void semanticError(const string& msg) {
    printf("Semantic error in line %d: %s\n", line_number, msg.c_str());
    exit(SEMANTIC_ERROR);
}

/* Helper function implementations */

void checkTypesMatch(Type t1, Type t2, const string& operation) {
    if (t1 != t2) {
        semanticError("Type mismatch in " + operation);
    }
}

void clearFunctionScope() {
    // Remove all function-local variables (depth >= 1) from symbol table
    for (auto it = symbolTable.begin(); it != symbolTable.end(); ) {
        Symbol& sym = it->second;
        
        // Remove all function-scope entries (depth > 0)
        for (auto depthIt = sym.type.begin(); depthIt != sym.type.end(); ) {
            if (depthIt->first > 0) {
                sym.offset.erase(depthIt->first);
                depthIt = sym.type.erase(depthIt);
            } else {
                ++depthIt;
            }
        }
        
        // If symbol has no entries left, remove it entirely
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
        semanticError("Variable already declared in this scope: " + id);
    }
    
    sym.type[currentDepth] = type;
    sym.offset[currentDepth] = currentOffset++;
    sym.depth = currentDepth;
}

void declareFunction(const string& id, Type returnType, vector<Type>& paramTypes, 
                     vector<string>& paramIds, vector<string>& paramLabels) {
    if (functionTable.find(id) != functionTable.end()) {
        Function& func = functionTable[id];
        
        // Check if already declared with different signature
        if (func.paramTypes != paramTypes || func.returnType != returnType) {
            semanticError("Function " + id + " redeclared with different signature");
        }
        return;
    }
    
    Function func;
    func.isDefined = false;
    func.returnType = returnType;
    func.paramTypes = paramTypes;
    func.paramIds = paramIds;
    func.paramLabels = paramLabels;
    func.startLineImplementation = -1;
    
    functionTable[id] = func;
}

void defineFunction(const string& id) {
    if (!isFunctionDeclared(id)) {
        semanticError("Function not declared before definition: " + id);
    }
    
    Function& func = functionTable[id];
    if (func.isDefined) {
        semanticError("Function already defined: " + id);
    }
    
    func.isDefined = true;
}

Type getVariableType(const string& id) {
    if (!isVariableDeclared(id)) {
        semanticError("Undeclared variable: " + id);
    }
    
    Symbol& sym = symbolTable[id];
    return sym.type[sym.depth];
}

bool isVariableDeclared(const string& id) {
    if (symbolTable.find(id) == symbolTable.end()) {
        return false;
    }
    
    Symbol& sym = symbolTable[id];
    return sym.type.find(currentDepth) != sym.type.end();
}

bool isFunctionDeclared(const string& id) {
    return functionTable.find(id) != functionTable.end();
}

int newTemp(Type type) {
    int regNum = tempCounter++;
    registerTypes[regNum] = type;
    return regNum;
}

void checkFunctionCall(const string& funcName, vector<Type>& argTypes, 
                       vector<string>& argLabels, vector<int>& argRegs) {
    Function& func = functionTable[funcName];
    
    // Track which parameters have been assigned
    vector<bool> paramAssigned(func.paramTypes.size(), false);
    int positionalCount = 0;
    
    // Count positional arguments
    for (int i = 0; i < argLabels.size(); i++) {
        if (argLabels[i].empty()) {
            positionalCount++;
        } else {
            break;  // Named arguments follow positional
        }
    }
    
    // Check positional arguments
    if (positionalCount > func.paramTypes.size()) {
        semanticError("Too many positional arguments in call to " + funcName);
    }
    
    for (int i = 0; i < positionalCount; i++) {
        checkTypesMatch(argTypes[i], func.paramTypes[i], "function call");
        paramAssigned[i] = true;
    }
    
    // Check named arguments
    for (int i = positionalCount; i < argLabels.size(); i++) {
        string label = argLabels[i];
        
        // Find parameter with this name
        int paramIndex = -1;
        for (int j = 0; j < func.paramIds.size(); j++) {
            if (func.paramIds[j] == label) {
                paramIndex = j;
                break;
            }
        }
        
        if (paramIndex == -1) {
            semanticError("Unknown parameter name '" + label + "' in call to " + funcName);
        }
        
        if (paramAssigned[paramIndex]) {
            semanticError("Parameter '" + label + "' assigned multiple times in call to " + funcName);
        }
        
        checkTypesMatch(argTypes[i], func.paramTypes[paramIndex], "function call");
        paramAssigned[paramIndex] = true;
    }
    
    // Check all parameters are assigned
    for (int i = 0; i < paramAssigned.size(); i++) {
        if (!paramAssigned[i]) {
            semanticError("Parameter '" + func.paramIds[i] + "' not provided in call to " + funcName);
        }
    }
}
