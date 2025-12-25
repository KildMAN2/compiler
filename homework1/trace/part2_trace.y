/* 
 * TRACING VERSION - part2_trace.y
 * This version prints detailed information about each grammar rule reduction
 * Student IDs: 322449539, 323885350
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include "../part2_helpers.h"

/* External from lexer */
extern int yylex(void);
extern char* yytext;
extern int line_number;
extern FILE* yyin;
extern FILE *trace_file;

/* Global parse tree root */
ParserNode *parseTree = NULL;
int reduction_counter = 0;

/* Trace helper functions */
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

void print_tree_indented(FILE *f, ParserNode *node, int indent, const char *prefix) {
    if (node == NULL) return;
    
    for (int i = 0; i < indent; i++) fprintf(f, "  ");
    fprintf(f, "%s", prefix);
    
    if (node->type != NULL && node->value != NULL) {
        fprintf(f, "[%s: %s]\n", node->type, node->value);
    } else if (node->type != NULL) {
        fprintf(f, "[%s]\n", node->type);
    } else if (node->value != NULL) {
        fprintf(f, "[%s]\n", node->value);
    } else {
        fprintf(f, "[NULL]\n");
    }
    
    if (node->child != NULL) {
        print_tree_indented(f, node->child, indent + 1, "↓ child: ");
    }
    
    if (node->sibling != NULL) {
        print_tree_indented(f, node->sibling, indent, "→ sibling: ");
    }
}

void trace_tree_state(ParserNode *result) {
    fprintf(trace_file, "  Tree after this reduction:\n");
    if (result == NULL) {
        fprintf(trace_file, "    (NULL)\n");
    } else {
        print_tree_indented(trace_file, result, 2, "");
    }
}

/* Error handling function */
void yyerror(const char *s);
%}

/* Union to hold semantic values */
%union {
    ParserNode *node;
}

/* Token declarations with semantic values */
%token <node> INT FLOAT VOID WRITE READ WHILE DO IF THEN ELSE RETURN
%token <node> ID INTEGERNUM REALNUM STR
%token <node> RELOP ADDOP MULOP ASSIGN AND OR NOT
%token <node> LPAREN RPAREN LBRACE RBRACE COMMA SEMICOLON COLON

/* Non-terminal types */
%type <node> PROGRAM FDEFS FUNC_DEC_API FUNC_DEF_API FUNC_ARGLIST BLK DCL TYPE
%type <node> STLIST STMT RETURN_STMT WRITE_STMT READ_STMT ASSN LVAL CNTRL
%type <node> BEXP EXP NUM CALL CALL_ARGS POS_ARGLIST NAMED_ARGLIST NAMED_ARG

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

/* Grammar rules with semantic actions */

PROGRAM:
    FDEFS
    { 
        trace_reduction("PROGRAM", "PROGRAM -> FDEFS", "Root of parse tree");
        $$ = makeNode("PROGRAM", NULL, $1);
        trace_tree_state($$);
        parseTree = $$;
    }
    ;

FDEFS:
    FDEFS FUNC_DEF_API BLK
    {
        trace_reduction("FDEFS", "FDEFS -> FDEFS FUNC_DEF_API BLK", "Function definition with body");
        ParserNode *fdefs_inner = makeNode("FDEFS", NULL, $1);
        $$ = fdefs_inner;
        $1->sibling = $2;
        $2->sibling = $3;
        trace_tree_state($$);
    }
    | FDEFS FUNC_DEC_API
    {
        trace_reduction("FDEFS", "FDEFS -> FDEFS FUNC_DEC_API", "Function declaration only");
        ParserNode *fdefs_inner = makeNode("FDEFS", NULL, $1);
        $$ = fdefs_inner;
        $1->sibling = $2;
        trace_tree_state($$);
    }
    | /* empty */
    {
        trace_reduction("FDEFS", "FDEFS -> epsilon", "No more function definitions");
        ParserNode *epsilon = makeNode("EPSILON", NULL, NULL);
        $$ = makeNode("FDEFS", NULL, epsilon);
        trace_tree_state($$);
    }
    ;

FUNC_DEC_API:
    TYPE ID LPAREN RPAREN SEMICOLON
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        ParserNode *funcDecApi = makeNode("FUNC_DEC_API", NULL, type);
        $$ = funcDecApi;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN SEMICOLON
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        ParserNode *arglist = makeNode("FUNC_ARGLIST", NULL, $4);
        ParserNode *funcDecApi = makeNode("FUNC_DEC_API", NULL, type);
        $$ = funcDecApi;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = arglist;
        arglist->sibling = $5;
        $5->sibling = $6;
    }
    ;

FUNC_DEF_API:
    TYPE ID LPAREN RPAREN
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        ParserNode *funcDefApi = makeNode("FUNC_DEF_API", NULL, type);
        $$ = funcDefApi;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        ParserNode *arglist = makeNode("FUNC_ARGLIST", NULL, $4);
        ParserNode *funcDefApi = makeNode("FUNC_DEF_API", NULL, type);
        $$ = funcDefApi;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = arglist;
        arglist->sibling = $5;
    }
    ;

FUNC_ARGLIST:
    FUNC_ARGLIST COMMA DCL
    {
        $$ = $1;
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
        $2->sibling = $3;
    }
    | DCL
    {
        $$ = $1;
    }
    ;

BLK:
    LBRACE STLIST RBRACE
    {
        $$ = makeNode("BLK", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

DCL:
    ID COLON TYPE
    {
        ParserNode *type = makeNode("TYPE", NULL, $3);
        $$ = makeNode("DCL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = type;
    }
    | ID COMMA DCL
    {
        $$ = makeNode("DCL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

TYPE:
    INT     { $$ = $1; }
    | FLOAT { $$ = $1; }
    | VOID  { $$ = $1; }
    ;

STLIST:
    STLIST STMT
    {
        ParserNode *stlist_inner = makeNode("STLIST", NULL, $1);
        $$ = stlist_inner;
        $1->sibling = $2;
    }
    | /* empty */
    {
        ParserNode *epsilon = makeNode("EPSILON", NULL, NULL);
        $$ = makeNode("STLIST", NULL, epsilon);
    }
    ;

STMT:
    DCL SEMICOLON
    {
        $$ = makeNode("STMT", NULL, $1);
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
    }
    | ASSN          
    { 
        $$ = makeNode("STMT", NULL, $1); 
    }
    | EXP SEMICOLON 
    {
        $$ = makeNode("STMT", NULL, $1);
        ParserNode *last = $1;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $2;
    }
    | CNTRL         
    { 
        $$ = makeNode("STMT", NULL, $1); 
    }
    | READ_STMT     
    { 
        $$ = makeNode("STMT", NULL, $1); 
    }
    | WRITE_STMT    
    { 
        $$ = makeNode("STMT", NULL, $1); 
    }
    | RETURN_STMT        
    { 
        $$ = makeNode("STMT", NULL, $1); 
    }
    | BLK           
    { 
        $$ = makeNode("STMT", NULL, $1); 
    }
    ;

RETURN_STMT:
    RETURN EXP SEMICOLON
    {
        $$ = makeNode("RETURN", NULL, $1);
        $1->sibling = $2;
        ParserNode *last = $2;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $3;
    }
    | RETURN SEMICOLON
    {
        $$ = makeNode("RETURN", NULL, $1);
        $1->sibling = $2;
    }
    ;

WRITE_STMT:
    WRITE LPAREN EXP RPAREN SEMICOLON
    {
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
        $$ = makeNode("LVAL", NULL, $1); 
    }
    ;

CNTRL:
    IF BEXP THEN STMT ELSE STMT
    {
        $$ = makeNode("CNTRL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
        $5->sibling = $6;
    }
    | IF BEXP THEN STMT
    {
        $$ = makeNode("CNTRL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    | WHILE BEXP DO STMT
    {
        $$ = makeNode("CNTRL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    ;

BEXP:
    BEXP OR BEXP
    {
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | BEXP AND BEXP
    {
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | NOT BEXP
    {
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
    }
    | EXP RELOP EXP
    {
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | LPAREN BEXP RPAREN
    {
        $$ = makeNode("BEXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

EXP:
    EXP ADDOP EXP
    {
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | EXP MULOP EXP
    {
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | LPAREN EXP RPAREN
    {
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | LPAREN TYPE RPAREN EXP %prec CAST
    {
        ParserNode *type = makeNode("TYPE", NULL, $2);
        $$ = makeNode("EXP", NULL, $1);
        $1->sibling = type;
        type->sibling = $3;
        $3->sibling = $4;
    }
    | ID    
    { 
        $$ = makeNode("EXP", NULL, $1); 
    }
    | NUM   
    { 
        $$ = makeNode("EXP", NULL, $1); 
    }
    | CALL  
    { 
        $$ = makeNode("EXP", NULL, $1); 
    }
    ;

NUM:
    INTEGERNUM  
    { 
        $$ = makeNode("NUM", NULL, $1); 
    }
    | REALNUM   
    { 
        $$ = makeNode("NUM", NULL, $1); 
    }
    ;

CALL:
    ID LPAREN CALL_ARGS RPAREN
    {
        $$ = makeNode("CALL", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
        ParserNode *last = $3;
        while (last->sibling != NULL) last = last->sibling;
        last->sibling = $4;
    }
    ;

CALL_ARGS:
    /* empty */
    {
        ParserNode *epsilon = makeNode("EPSILON", NULL, NULL);
        $$ = makeNode("CALL_ARGS", NULL, epsilon);
    }
    | POS_ARGLIST
    {
        $$ = makeNode("CALL_ARGS", NULL, $1);
    }
    | NAMED_ARGLIST
    {
        $$ = makeNode("CALL_ARGS", NULL, $1);
    }
    | POS_ARGLIST COMMA NAMED_ARGLIST
    {
        $$ = makeNode("CALL_ARGS", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

POS_ARGLIST:
    EXP
    {
        $$ = makeNode("POS_ARGLIST", NULL, $1);
    }
    | POS_ARGLIST COMMA EXP
    {
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
        $$ = makeNode("NAMED_ARGLIST", NULL, $1);
    }
    | NAMED_ARGLIST COMMA NAMED_ARG
    {
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
        $$ = makeNode("NAMED_ARG", NULL, $1);
        $1->sibling = $2;
        $2->sibling = $3;
    }
    ;

%%

/* Error handling function */
void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: '%s' in line number %d\n", yytext, line_number);
    exit(2);
}
