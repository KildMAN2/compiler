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
/*
 * String literal:
 * - Must be closed on the same line
 * - Allows escape sequences syntactically as \\.
 * - We validate allowed escapes in the action (only \n, \t, \" are allowed).
 */
str         \"([^\n\r\"\\]|\\.)*\"
unterminated_str  \"([^\n\r\"\\]|\\.)*

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
                            /* Validate escape sequences and strip surrounding quotes */
                            const char* raw = yytext;
                            int len = (int)strlen(raw);
                            string inner = string(raw + 1, len - 2);

                            for (size_t i = 0; i < inner.size(); i++) {
                                if (inner[i] == '\\') {
                                    if (i + 1 >= inner.size()) {
                                        printf("Lexical error: '%s' in line number %d\n", raw, line_number);
                                        exit(LEXICAL_ERROR);
                                    }
                                    char esc = inner[i + 1];
                                    if (!(esc == 'n' || esc == 't' || esc == '\"')) {
                                        printf("Lexical error: '%s' in line number %d\n", raw, line_number);
                                        exit(LEXICAL_ERROR);
                                    }
                                    i++; /* skip escaped char */
                                }
                            }

                            yylval.name = inner;
                            return STR;
                        }

{unterminated_str} {
                            /* Unterminated string (reached end of line/EOF without closing quote) */
                            printf("Lexical error: '%s' in line number %d\n", yytext, line_number);
                            exit(LEXICAL_ERROR);
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
                            printf("Lexical error: '%s' in line number %d\n", yytext, line_number);
                            exit(LEXICAL_ERROR);
            }

%%
