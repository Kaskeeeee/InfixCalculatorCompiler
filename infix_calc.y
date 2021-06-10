%{ 
	#include <ctype.h> 
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#define TRUE "True"
	#define FALSE "False"

	extern FILE *yyin;
	
	int yylex();
	int yyparse();
	void yyerror(char const *s);
	int vars[26];
	char vars_decl[26] = "abcdefghijklmnopqrstuvwyz";

	void main(int argc, char ** argv){
		yyparse();
	}

%}

%error-verbose

%union{
	int number;
	char* string;
}

%token <number> INTEGER BOOL
%token <string> VAR
%token LT LE GT GE EQ NE 
%token IF THEN ELSE EXIT
%type  <number> bool_expr if_then_else expr

%left '+' '-'
%left '*' '/'
%left '(' ')' 
	

%%

lines:	 lines line
	|line
;

line:	 expr '\n' 			{ printf("= %d\n", $1); }
	|if_then_else '\n'		{ printf("%d\n", $1); }
	|bool_expr '\n'			{ printf("%s\n", $1 ? TRUE : FALSE); }
	|var_assign '\n'
	|EXIT				{ return 1; }	 							
;

if_then_else: IF bool_expr THEN expr 
			ELSE expr	{ $$ = $2 ? $4 : $6; }
;
		

bool_expr:  expr LT expr		{ $$ = $1 <  $3; }
	   |expr LE expr		{ $$ = $1 <= $3; }
	   |expr GT expr		{ $$ = $1 >  $3; }
	   |expr GE expr		{ $$ = $1 >= $3; }
	   |expr EQ expr		{ $$ = $1 == $3; }
           |expr NE expr 		{ $$ = $1 != $3; }
	   |'('bool_expr')'		{ $$ = $2; }
	   |BOOL			{ $$ = $1; }
;

var_assign: VAR '=' expr 		{ vars[$1[0] - 'a'] = $3; 
						vars_decl[$1[0] - 'a'] = '*';}
;

expr:	 expr '+' expr			{ $$ = $1 + $3; 	}
	|expr '-' expr			{ $$ = $1 - $3;		}
	|expr '*' expr			{ $$ = $1 * $3;		}
	|expr '/' expr			{ $$ = $1 / $3; 	}
	|'(' expr ')'			{ $$ = $2;		}
	|'-'expr			{ $$ = -$2;		}
	|INTEGER			{ $$ = $1;		}
	|VAR				{ 
						if (vars_decl[$1[0] - 'a'] != '*') {
							fprintf(stderr, "%s'%s'\n", "Error: use of non-declared variable ", $1);
							exit(1);
						}					
						$$ = vars[$1[0] - 'a'];
					}
;


/*expr:	 factor '+' expr		{ $$ = $1 + $3; 	}
	|factor '-' expr		{ $$ = $1 - $3; 	}
	|factor				{ $$ = $1;		}
;

factor:  factor '*' term		{ $$ = $1 * $3; 	}	
	|factor '/' term		{ $$ = $1 / $3; 	}
	|term				{ $$ = $1;		}
	
;

term:	 '(' expr ')'			{ $$ = $2;		}
	|INTEGER			{ $$ = $1;		}
	|VAR				{ $$ = vars[$1]; 	}
;*/

%%

void yyerror (char const *s) {
   fprintf(stderr, "%s\n", s);
}

