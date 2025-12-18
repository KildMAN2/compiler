/* 
 * Compilation Course - Project Part 2
 * Parser for C-- Language
 * Student IDs: 322449539, 323885350
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include "part2_helpers.h"

/* External from lexer */
extern int yylex(void);
extern char* yytext;
extern int line_number;
extern FILE* yyin;

/* Global parse tree root */
ParserNode *parseTree = NULL;

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
        $$ = makeNode("PROGRAM", NULL, $1);
        parseTree = $$;
    }
    ;

FDEFS:
    FDEFS FUNC_DEF_API BLK
    {
        ParserNode *fdefs_inner = makeNode("FDEFS", NULL, $1);
        $$ = fdefs_inner;
        $1->sibling = $2;
        $2->sibling = $3;
    }
    | FDEFS FUNC_DEC_API
    {
        ParserNode *fdefs_inner = makeNode("FDEFS", NULL, $1);
        $$ = fdefs_inner;
        $1->sibling = $2;
    }
    | /* empty */
    {
        $$ = makeNode("EPSILON", NULL, NULL);
    }
    ;

FUNC_DEC_API:
    TYPE ID LPAREN RPAREN SEMICOLON
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        $$ = type;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
        $4->sibling = $5;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN SEMICOLON
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        ParserNode *arglist = makeNode("FUNC_ARGLIST", NULL, $4);
        $$ = type;
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
        $$ = type;
        type->sibling = $2;
        $2->sibling = $3;
        $3->sibling = $4;
    }
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN
    {
        ParserNode *type = makeNode("TYPE", NULL, $1);
        ParserNode *arglist = makeNode("FUNC_ARGLIST", NULL, $4);
        $$ = type;
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
        $$ = makeNode("EPSILON", NULL, NULL);
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
        ParserNode *exp1 = makeNode("EXP", NULL, $1);
        ParserNode *exp2 = makeNode("EXP", NULL, $3);
        $$ = makeNode("EXP", NULL, exp1);
        exp1->sibling = $2;
        $2->sibling = exp2;
    }
    | EXP MULOP EXP
    {
        ParserNode *exp1 = makeNode("EXP", NULL, $1);
        ParserNode *exp2 = makeNode("EXP", NULL, $3);
        $$ = makeNode("EXP", NULL, exp1);
        exp1->sibling = $2;
        $2->sibling = exp2;
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
        $$ = NULL;
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
        $$ = $1;
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
        $$ = $1;
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
