%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
%}

DIGIT [0-9]

%%
exit			{ return EXIT; }
[a-z]			{ yylval.string = strdup(yytext); return VAR; }
{DIGIT}+		{ yylval.number = atoi(yytext); return INTEGER; }
"<"			{ yylval.string = "<"; return LT; }
"<="			{ yylval.string = "<="; return LE; }
">"			{ yylval.string = ">"; return GT; }
">="			{ yylval.string = ">="; return GE; }
"=="			{ yylval.string = "=="; return EQ; }
"!="			{ yylval.string = "!="; return NE; }
False			{ yylval.number = 0; return BOOL; }
True			{ yylval.number = 1; return BOOL; }
if			{ return IF; }
then			{ return THEN; }
else			{ return ELSE; }
[\t\r ]			;
\n			{ return yytext[0]; }
.			{ return yytext[0]; }
%%
