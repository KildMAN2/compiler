%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h> /* for strlen used in string token processing */
extern FILE *yyin; /* allow feeding lexer from files */
int line_number = 1;
%}

%option noyywrap


/* Macro definitions for regular expressions */
id          [a-zA-Z][a-zA-Z0-9_]*
integernum  [0-9]+
realnum     [0-9]+\.[0-9]+
str    \"([^\"\\\n]|\\[nt\"\\])*\"

%%

    /* Reserved words */
"int"       { printf("<%s>", yytext); }
"float"     { printf("<%s>", yytext); }
"void"      { printf("<%s>", yytext); }
"write"     { printf("<%s>", yytext); }
"read"      { printf("<%s>", yytext); }
"while"     { printf("<%s>", yytext); }
"do"        { printf("<%s>", yytext); }
"if"        { printf("<%s>", yytext); }
"then"      { printf("<%s>", yytext); }
"else"      { printf("<%s>", yytext); }
"return"    { printf("<%s>", yytext); }

    /* Symbols */
"("         { printf("%s", yytext); }
")"         { printf("%s", yytext); }
"{"         { printf("%s", yytext); }
"}"         { printf("%s", yytext); }
","         { printf("%s", yytext); }
";"         { printf("%s", yytext); }
":"         { printf("%s", yytext); }

    /* Complex tokens */
{id}        { printf("<id,%s>", yytext); }
{integernum} { printf("<integernum,%s>", yytext); }
{realnum}   { printf("<realnum,%s>", yytext); }
{str}       { 
              int len = strlen(yytext);
              printf("<str,");
              for (int i = 1; i < len - 1; i++) {
                  printf("%c", yytext[i]);
              }
              printf(">");
            }

    /* Relational operators */
"=="        { printf("<relop,==>"); }
"<>"        { printf("<relop,<>>"); }
"<="        { printf("<relop,<=>"); }
">="        { printf("<relop,>=>"); }
"<"         { printf("<relop,<>"); }
">"         { printf("<relop,>>"); }

    /* Arithmetic operators */
"+"         { printf("<addop,+>"); }
"-"         { printf("<addop,->"); }
"*"         { printf("<mulop,*>"); }
"/"         { printf("<mulop,/>"); }

    /* Assignment operator */
"="         { printf("<assign,=>"); }

    /* Logical operators */
"&&"        { printf("<and,&&>"); }
"||"        { printf("<or,||>"); }
"!"         { printf("<not,!>"); }

    /* Comments - ignore everything from # to end of line (not including CR/LF) */
#[^\r\n]*    { /* Ignore comments anywhere on the line; # inside strings is matched by {str} */ }

    /* Whitespace - pass through unchanged */
[ \t]       { printf("%s", yytext); }
\n          { printf("%s", yytext); line_number++; }
\r\n        { printf("%s", yytext); line_number++; }

    /* Error handling */
.           { 
              printf("\nLexical error: '%s' in line number %d\n", yytext, line_number);
              exit(1);
            }

%%

int main(int argc, char **argv) {
    if (argc == 1) {
        /* No files passed: read from stdin */
        yylex();
        return 0;
    }

    /* One or more files passed: process each sequentially */
    for (int i = 1; i < argc; ++i) {
        FILE *f = fopen(argv[i], "r");
        if (!f) {
            fprintf(stderr, "Error: cannot open %s\n", argv[i]);
            return 1;
        }
        yyin = f;
        line_number = 1; /* reset line counter per file */
        yylex();
        fclose(f);
    }
    return 0;
}