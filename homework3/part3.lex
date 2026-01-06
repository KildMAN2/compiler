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
"int"       { yylval.name = "int"; yylval.type = int_; return INT; }
"float"     { yylval.name = "float"; yylval.type = float_; return FLOAT; }
"void"      { yylval.name = "void"; yylval.type = void_t; return VOID; }
"write"     { yylval.name = "write"; return WRITE; }
"read"      { yylval.name = "read"; return READ; }
"while"     { yylval.name = "while"; return WHILE; }
"do"        { yylval.name = "do"; return DO; }
"if"        { yylval.name = "if"; return IF; }
"then"      { yylval.name = "then"; return THEN; }
"else"      { yylval.name = "else"; return ELSE; }
"return"    { yylval.name = "return"; return RETURN; }
"and"       { yylval.name = "and"; return AND; }
"or"        { yylval.name = "or"; return OR; }
"not"       { yylval.name = "not"; return NOT; }

    /* Symbols */
"("         { yylval.name = "("; return LPAREN; }
")"         { yylval.name = ")"; return RPAREN; }
"{"         { yylval.name = "{"; return LBRACE; }
"}"         { yylval.name = "}"; return RBRACE; }
","         { yylval.name = ","; return COMMA; }
";"         { yylval.name = ";"; return SEMICOLON; }
":"         { yylval.name = ":"; return COLON; }

    /* Complex tokens */
{id}        { yylval.name = yytext; return ID; }
{integernum} { yylval.name = yytext; yylval.type = int_; return INTEGERNUM; }
{realnum}   { yylval.name = yytext; yylval.type = float_; return REALNUM; }
{str}       { 
              /* Extract string content without quotes and process escapes */
              int len = strlen(yytext);
              string str_val = string(yytext + 1, len - 2);
              yylval.name = str_val;
              return STR;
            }

    /* Relational operators */
"=="        { yylval.name = "=="; return RELOP; }
"<>"        { yylval.name = "<>"; return RELOP; }
"<="        { yylval.name = "<="; return RELOP; }
">="        { yylval.name = ">="; return RELOP; }
"<"         { yylval.name = "<"; return RELOP; }
">"         { yylval.name = ">"; return RELOP; }

    /* Arithmetic operators */
"+"         { yylval.name = "+"; return ADDOP; }
"-"         { yylval.name = "-"; return ADDOP; }
"*"         { yylval.name = "*"; return MULOP; }
"/"         { yylval.name = "/"; return MULOP; }

    /* Assignment operator */
"="         { yylval.name = "="; return ASSIGN; }

    /* Whitespace (except newlines) */
[ \t\r]+    { /* ignore whitespace */ }

    /* Newlines */
\n          { line_number++; }

    /* Comments */
"//".*      { /* ignore single-line comments */ }

    /* Unrecognized characters */
.           { 
              printf("Lexical error: unrecognized character '%s' in line %d\n", yytext, line_number);
              exit(LEXICAL_ERROR);
            }

%%
