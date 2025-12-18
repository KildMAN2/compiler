/* 
 * TRACING VERSION - part2_trace.y
 * This version prints detailed information about each grammar rule reduction
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include "../part2_helpers.h"

extern int yylex(void);
extern char* yytext;
extern int line_number;
extern FILE* yyin;
extern FILE *trace_file;

ParserNode *parseTree = NULL;
int reduction_counter = 0;

void trace_reduction(const char *rule_name, const char *pattern, const char *description) {
    if (trace_file == NULL) {
        trace_file = fopen("trace_output.txt", "a");
    }
    reduction_counter++;
    fprintf(trace_file, "\n[PARSER REDUCTION #%d]\n", reduction_counter);
    fprintf(trace_file, "  Rule: %s\n", rule_name);
    fprintf(trace_file, "  Pattern: %s\n", pattern);
    fprintf(trace_file, "  Description: %s\n", description);
}

void trace_node_creation(const char *node_type, const char *node_value) {
    fprintf(trace_file, "  Action: Creating node (type='%s', value='%s')\n", 
            node_type, node_value ? node_value : "NULL");
}

void trace_sibling_link(const char *from, const char *to) {
    fprintf(trace_file, "  Action: Linking sibling %s -> %s\n", from, to);
}

void yyerror(const char *s);
%}

%union {
    ParserNode *node;
}

%token <node> INT FLOAT VOID WRITE READ WHILE DO IF THEN ELSE RETURN
%token <node> ID INTEGERNUM REALNUM STR
%token <node> RELOP ADDOP MULOP ASSIGN AND OR NOT
%token <node> LPAREN RPAREN LBRACE RBRACE COMMA SEMICOLON COLON

%type <node> PROGRAM FDEFS FUNC_DEC_API FUNC_DEF_API FUNC_ARGLIST BLK DCL TYPE
%type <node> STLIST STMT RETURN_STMT WRITE_STMT READ_STMT ASSN LVAL CNTRL
%type <node> BEXP EXP NUM CALL CALL_ARGS POS_ARGLIST NAMED_ARGLIST NAMED_ARG

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

PROGRAM:
    FDEFS
    { 
        trace_reduction("PROGRAM", "FDEFS", "A complete C-- program");
        trace_node_creation("PROGRAM", NULL);
        $$ = makeNode("PROGRAM", NULL, $1);
        parseTree = $$;
        fprintf(trace_file, "  Result: Parse tree root created and stored in 'parseTree'\n");
    }
    ;

FDEFS:
    FDEFS FUNC_DEF_API BLK
    {
        trace_reduction("FDEFS", "FDEFS FUNC_DEF_API BLK", "Adding a function definition");
        ParserNode *fdefs_inner = makeNode("FDEFS", NULL, $1);
        ParserNode *funcDefApi = makeNode("FUNC_DEF_API", NULL, $2);
        $$ = makeNode("FDEFS", NULL, fdefs_inner);
        trace_node_creation("FDEFS (outer)", NULL);
        trace_sibling_link("FDEFS(inner)", "FUNC_DEF_API");
        trace_sibling_link("FUNC_DEF_API", "BLK");
        fdefs_inner->sibling = funcDefApi;
        funcDefApi->sibling = $3;
    }
    | FDEFS FUNC_DEC_API
    {
        trace_reduction("FDEFS", "FDEFS FUNC_DEC_API", "Adding a function declaration");
        ParserNode *fdefs_inner = makeNode("FDEFS", NULL, $1);
        ParserNode *funcDecApi = makeNode("FUNC_DEC_API", NULL, $2);
        $$ = makeNode("FDEFS", NULL, fdefs_inner);
        fdefs_inner->sibling = funcDecApi;
    }
    | /* empty */
    {
        trace_reduction("FDEFS", "epsilon", "Empty function list (base case)");
        trace_node_creation("EPSILON", NULL);
        $$ = makeNode("EPSILON", NULL, NULL);
    }
    ;

FUNC_DEC_API:
    TYPE ID LPAREN RPAREN SEMICOLON
    {
        trace_reduction("FUNC_DEC_API", "TYPE ID ( ) ;", "Function declaration without parameters");
        ParserNode *type = makeNode("TYPE", NULL, $1);
        $$ = type;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
        trace_node_creation("TYPE", NULL);
        trace_sibling_link("TYPE", "ID");
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN SEMICOLON
    {
        trace_reduction("FUNC_DEC_API", "TYPE ID ( FUNC_ARGLIST ) ;", "Function declaration with parameters");
        ParserNode *type = makeNode("TYPE", NULL, $1);
        $$ = type;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
        $5->sibling = $6;
    }
    ;

FUNC_DEF_API:
    TYPE ID LPAREN RPAREN
    {
        trace_reduction("FUNC_DEF_API", "TYPE ID ( )", "Function definition without parameters");
        ParserNode *type = makeNode("TYPE", NULL, $1);
        $$ = type;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN
    {
        trace_reduction("FUNC_DEF_API", "TYPE ID ( FUNC_ARGLIST )", "Function definition with parameters");
        ParserNode *type = makeNode("TYPE", NULL, $1);
        $$ = type;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
    }
    ;

FUNC_ARGLIST:
    FUNC_ARGLIST COMMA DCL
    {
        trace_reduction("FUNC_ARGLIST", "FUNC_ARGLIST , DCL", "Adding argument to list");
        ParserNode *arglist = makeNode("FUNC_ARGLIST", NULL, $1);
        $$ = arglist;
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | DCL
    {
        trace_reduction("FUNC_ARGLIST", "DCL", "First argument in list");
        $$ = $1;
    }
    ;

BLK:
    LBRACE STLIST RBRACE
    {
        trace_reduction("BLK", "{ STLIST }", "Code block");
        trace_node_creation("BLK", NULL);
        $$ = makeNode("BLK", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

DCL:
    ID COLON TYPE
    {
        trace_reduction("DCL", "ID : TYPE", "Single variable declaration");
        ParserNode *type = makeNode("TYPE", NULL, $3);
        $$ = makeNode("DCL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = type;
        trace_node_creation("DCL", NULL);
    }
    | ID COMMA DCL
    {
        trace_reduction("DCL", "ID , DCL", "Multiple variable declaration");
        $$ = makeNode("DCL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

TYPE:
    INT     { 
        trace_reduction("TYPE", "int", "Integer type");
        $$ = $1; 
    }
    | FLOAT { 
        trace_reduction("TYPE", "float", "Float type");
        $$ = $1; 
    }
    | VOID  { 
        trace_reduction("TYPE", "void", "Void type");
        $$ = $1; 
    }
    ;

STLIST:
    STLIST STMT
    {
        trace_reduction("STLIST", "STLIST STMT", "Adding statement to list");
        ParserNode *stlist_inner = makeNode("STLIST", NULL, $1);
        $$ = makeNode("STLIST", NULL, stlist_inner);
        stlist_inner->sibling = $2;
    }
    | /* empty */
    {
        trace_reduction("STLIST", "epsilon", "Empty statement list");
        $$ = makeNode("EPSILON", NULL, NULL);
    }
    ;

STMT:
    DCL SEMICOLON
    {
        trace_reduction("STMT", "DCL ;", "Declaration statement");
        $$ = makeNode("STMT", NULL, $1);
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
    }
    | ASSN          
    { 
        trace_reduction("STMT", "ASSN", "Assignment statement");
        $$ = makeNode("STMT", NULL, $1); 
    }
    | EXP SEMICOLON 
    {
        trace_reduction("STMT", "EXP ;", "Expression statement");
        $$ = makeNode("STMT", NULL, $1);
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
    }
    | CNTRL         
    { 
        trace_reduction("STMT", "CNTRL", "Control flow statement");
        $$ = makeNode("STMT", NULL, $1); 
    }
    | READ_STMT     
    { 
        trace_reduction("STMT", "READ_STMT", "Read statement");
        $$ = makeNode("STMT", NULL, $1); 
    }
    | WRITE_STMT    
    { 
        trace_reduction("STMT", "WRITE_STMT", "Write statement");
        $$ = makeNode("STMT", NULL, $1); 
    }
    | RETURN_STMT        
    { 
        trace_reduction("STMT", "RETURN_STMT", "Return statement");
        $$ = makeNode("STMT", NULL, $1); 
    }
    | BLK           
    { 
        trace_reduction("STMT", "BLK", "Block statement");
        $$ = makeNode("STMT", NULL, $1); 
    }
    ;

RETURN_STMT:
    RETURN EXP SEMICOLON
    {
        trace_reduction("RETURN_STMT", "return EXP ;", "Return with value");
        $$ = makeNode("RETURN", NULL, $1);
        $1->sibling = $2;
        ParserNode *last = $2;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $3;
    }
    | RETURN SEMICOLON
    {
        trace_reduction("RETURN_STMT", "return ;", "Return without value");
        $$ = makeNode("RETURN", NULL, $1);
        $1->sibling = $2;
    }
    ;

WRITE_STMT:
    WRITE LPAREN EXP RPAREN SEMICOLON
    {
        trace_reduction("WRITE_STMT", "write ( EXP ) ;", "Write expression");
        $$ = makeNode("WRITE", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        ParserNode *last = $3;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $4;
        $4->sibling = $5;
    }
    | WRITE LPAREN STR RPAREN SEMICOLON
    {
        trace_reduction("WRITE_STMT", "write ( STR ) ;", "Write string");
        $$ = makeNode("WRITE", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
    }
    ;

READ_STMT:
    READ LPAREN LVAL RPAREN SEMICOLON
    {
        trace_reduction("READ_STMT", "read ( LVAL ) ;", "Read into variable");
        $$ = makeNode("READ", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        ParserNode *last = $3;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $4;
        $4->sibling = $5;
    }
    ;

ASSN:
    LVAL ASSIGN EXP SEMICOLON
    {
        trace_reduction("ASSN", "LVAL = EXP ;", "Assignment");
        trace_node_creation("ASSN", NULL);
        $$ = makeNode("ASSN", NULL, $1);
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
        $2->sibling = $3;
        last = $3;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $4;
    }
    ;

LVAL:
    ID 
    { 
        trace_reduction("LVAL", "ID", "Left-value (variable)");
        $$ = makeNode("LVAL", NULL, $1); 
    }
    ;

CNTRL:
    IF BEXP THEN STMT ELSE STMT
    {
        trace_reduction("CNTRL", "if BEXP then STMT else STMT", "If-then-else");
        $$ = makeNode("CNTRL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
        $5->sibling = $6;
    }
    | IF BEXP THEN STMT
    {
        trace_reduction("CNTRL", "if BEXP then STMT", "If-then");
        $$ = makeNode("CNTRL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    | WHILE BEXP DO STMT
    {
        trace_reduction("CNTRL", "while BEXP do STMT", "While loop");
        $$ = makeNode("CNTRL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    ;

BEXP:
    BEXP OR BEXP
    {
        trace_reduction("BEXP", "BEXP || BEXP", "Logical OR");
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | BEXP AND BEXP
    {
        trace_reduction("BEXP", "BEXP && BEXP", "Logical AND");
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | NOT BEXP
    {
        trace_reduction("BEXP", "! BEXP", "Logical NOT");
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
    }
    | EXP RELOP EXP
    {
        trace_reduction("BEXP", "EXP relop EXP", "Relational comparison");
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | LPAREN BEXP RPAREN
    {
        trace_reduction("BEXP", "( BEXP )", "Parenthesized boolean expression");
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

EXP:
    EXP ADDOP EXP
    {
        trace_reduction("EXP", "EXP + EXP", "Addition/Subtraction");
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | EXP MULOP EXP
    {
        trace_reduction("EXP", "EXP * EXP", "Multiplication/Division");
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | LPAREN EXP RPAREN
    {
        trace_reduction("EXP", "( EXP )", "Parenthesized expression");
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | LPAREN TYPE RPAREN EXP %prec CAST
    {
        trace_reduction("EXP", "( TYPE ) EXP", "Type cast");
        ParserNode *type = makeNode("TYPE", NULL, $2);
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = type;
        type->sibling = $3;
        $3->sibling = $4;
    }
    | ID    
    { 
        trace_reduction("EXP", "ID", "Identifier expression");
        $$ = $1; 
    }
    | NUM   
    { 
        trace_reduction("EXP", "NUM", "Number expression");
        $$ = $1; 
    }
    | CALL  
    { 
        trace_reduction("EXP", "CALL", "Function call expression");
        $$ = $1; 
    }
    ;

NUM:
    INTEGERNUM  
    { 
        trace_reduction("NUM", "INTEGERNUM", "Integer number");
        $$ = makeNode("NUM", NULL, $1); 
    }
    | REALNUM   
    { 
        trace_reduction("NUM", "REALNUM", "Real number");
        $$ = makeNode("NUM", NULL, $1); 
    }
    ;

CALL:
    ID LPAREN CALL_ARGS RPAREN
    {
        trace_reduction("CALL", "ID ( CALL_ARGS )", "Function call");
        $$ = makeNode("CALL", NULL, $1);
        $1->sibling = $2;
        if ($3 != NULL) {
            $2->sibling = $3;
            ParserNode *last = $3;
            while (last->sibling != NULL) last = last->sibling;
            last->sibling = $4;
        } else {
            $2->sibling = $4;
        }
    }
    ;

CALL_ARGS:
    /* empty */
    {
        trace_reduction("CALL_ARGS", "epsilon", "No arguments");
        $$ = NULL;
    }
    | POS_ARGLIST
    {
        trace_reduction("CALL_ARGS", "POS_ARGLIST", "Positional arguments");
        $$ = $1;
    }
    | NAMED_ARGLIST
    {
        trace_reduction("CALL_ARGS", "NAMED_ARGLIST", "Named arguments");
        $$ = $1;
    }
    | POS_ARGLIST COMMA NAMED_ARGLIST
    {
        trace_reduction("CALL_ARGS", "POS_ARGLIST , NAMED_ARGLIST", "Mixed arguments");
        $$ = $1;
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
        $2->sibling = $3;
    }
    ;

POS_ARGLIST:
    EXP
    {
        trace_reduction("POS_ARGLIST", "EXP", "Single positional argument");
        $$ = $1;
    }
    | POS_ARGLIST COMMA EXP
    {
        trace_reduction("POS_ARGLIST", "POS_ARGLIST , EXP", "Adding positional argument");
        $$ = $1;
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
        $2->sibling = $3;
    }
    ;

NAMED_ARGLIST:
    NAMED_ARG
    {
        trace_reduction("NAMED_ARGLIST", "NAMED_ARG", "Single named argument");
        $$ = $1;
    }
    | NAMED_ARGLIST COMMA NAMED_ARG
    {
        trace_reduction("NAMED_ARGLIST", "NAMED_ARGLIST , NAMED_ARG", "Adding named argument");
        $$ = $1;
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
        $2->sibling = $3;
    }
    ;

NAMED_ARG:
    ID COLON EXP
    {
        trace_reduction("NAMED_ARG", "ID : EXP", "Named argument");
        $$ = makeNode("NAMED_ARG", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: '%s' in line number %d\n", yytext, line_number);
    if (trace_file) {
        fprintf(trace_file, "\n[PARSER ERROR] Syntax error at line %d\n", line_number);
        fprintf(trace_file, "  Unexpected token: '%s'\n", yytext);
        fclose(trace_file);
    }
    exit(2);
}
