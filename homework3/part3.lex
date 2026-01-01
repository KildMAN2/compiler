/*
 * Compilation Course - Project Part 3
 * Lexical Analyzer for C-- Language (Code Generation Version)
 * EE046266 Winter 2025-2026
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "part3_helpers.hpp"
#include "part3.tab.hpp"

int line_number = 1;
%}

%option noyywrap

/* Macro definitions for regular expressions */
id          [a-zA-Z][a-zA-Z0-9_]*
integernum  [0-9]+
realnum     [0-9]+\.[0-9]+
str         \"([^\n\r\"\\]|\\[nt\"])*\"

%%

    /* Reserved words */
"int"       { yylval.node.name = "int"; yylval.node.type = int_; return INT; }
"float"     { yylval.node.name = "float"; yylval.node.type = float_; return FLOAT; }
"void"      { yylval.node.name = "void"; yylval.node.type = void_t; return VOID; }
"write"     { yylval.node.name = "write"; return WRITE; }
"read"      { yylval.node.name = "read"; return READ; }
"while"     { yylval.node.name = "while"; return WHILE; }
"do"        { yylval.node.name = "do"; return DO; }
"if"        { yylval.node.name = "if"; return IF; }
"then"      { yylval.node.name = "then"; return THEN; }
"else"      { yylval.node.name = "else"; return ELSE; }
"return"    { yylval.node.name = "return"; return RETURN; }

    /* Symbols */
"("         { yylval.node.name = "("; return LPAREN; }
")"         { yylval.node.name = ")"; return RPAREN; }
"{"         { yylval.node.name = "{"; return LBRACE; }
"}"         { yylval.node.name = "}"; return RBRACE; }
","         { yylval.node.name = ","; return COMMA; }
";"         { yylval.node.name = ";"; return SEMICOLON; }
":"         { yylval.node.name = ":"; return COLON; }

    /* Complex tokens */
{id}        { yylval.node.name = yytext; return ID; }
{integernum} { yylval.node.name = yytext; yylval.node.type = int_; return INTEGERNUM; }
{realnum}   { yylval.node.name = yytext; yylval.node.type = float_; return REALNUM; }
{str}       { 
              /* Extract string content without quotes and process escapes */
              int len = strlen(yytext);
              string str_val = string(yytext + 1, len - 2);
              yylval.node.name = str_val;
              return STR;
            }

    /* Relational operators */
"=="        { yylval.node.name = "=="; return RELOP; }
"<>"        { yylval.node.name = "<>"; return RELOP; }
"<="        { yylval.node.name = "<="; return RELOP; }
">="        { yylval.node.name = ">="; return RELOP; }
"<"         { yylval.node.name = "<"; return RELOP; }
">"         { yylval.node.name = ">"; return RELOP; }

    /* Arithmetic operators */
"+"         { yylval.node.name = "+"; return ADDOP; }
"-"         { yylval.node.name = "-"; return ADDOP; }
"*"         { yylval.node.name = "*"; return MULOP; }
"/"         { yylval.node.name = "/"; return MULOP; }

    /* Logical operators */
"and"       { yylval.node.name = "and"; return AND; }
"or"        { yylval.node.name = "or"; return OR; }
"not"       { yylval.node.name = "not"; return NOT; }

    /* Assignment operator */
"="         { yylval.node.name = "="; return ASSIGN; }

    /* Whitespace (except newlines) */
[ \t\r]+    { /* ignore whitespace */ }

    /* Newlines */
\n          { line_number++; }

    /* Comments */
"//".*      { /* ignore single-line comments */ }

    /* Unrecognized characters */
.           { 
              fprintf(stderr, "Lexical error: unrecognized character '%s' in line %d\n", yytext, line_number);
              exit(LEXICAL_ERROR);
            }

%%
