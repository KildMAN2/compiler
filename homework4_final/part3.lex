%{
/*
    EE046266: Compilation Methods - Winter 2025-2026
    Lexer for C-- Language
*/

#include "part3_helpers.hpp"
#include "part3.tab.hpp"

extern int yylineno;

%}

%option yylineno
%option noyywrap

%%

"void"          { return VOID; }
"int"           { return INT; }
"float"         { return FLOAT; }
"return"        { return RETURN; }
"if"            { return IF; }
"then"          { return THEN; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"do"            { return DO; }
"read"          { return READ; }
"write"         { return WRITE; }

[a-zA-Z][a-zA-Z0-9_]*  { 
    yylval.name = string(yytext);
    return ID; 
}

0|[1-9][0-9]*   { 
    yylval.name = string(yytext);
    return NUM; 
}

[0-9]+\.[0-9]+  { 
    yylval.name = string(yytext);
    return REALNUM; 
}

"=="            { return EQEQ; }
"<>"            { return NOTEQ; }
"<="            { return LTEQ; }
">="            { return GTEQ; }
"="             { return ASSIGN; }
"<"             { return LT; }
">"             { return GT; }
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULT; }
"/"             { return DIV; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
":"             { return COLON; }
";"             { return SEMICOLON; }
","             { return COMMA; }

\"([^\\\"\n]|\\[ntr0\"\\])*\"  {
    yylval.name = string(yytext);
    return STRING;
}

[ \t\r\n]+      { /* ignore whitespace */ }

"#"[^\n]*       { /* ignore single-line comments (part1-style) */ }

"//"[^\n]*      {
    // part1-style requirement: comments start with '#', so '//' is not allowed.
    cerr << "Lexical error: '//' in line number " << yylineno << endl;
    exit(LEXICAL_ERROR);
}

.               { 
    cerr << "Lexical error: '" << yytext << "' in line number " << yylineno << endl;
    exit(LEXICAL_ERROR);
}

%%
