%{ 
	#include <ctype.h> 
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	
	/* defines */
	#define TRUE "True"
	#define FALSE "False"
	#define plus_expr 	0
	#define minus_expr 	1
	#define	mul_expr	2
	#define	div_expr	3
	#define	unary_minus	4

	extern FILE *yyin;

	typedef struct t_expr {
		char* code;
		char* next;
		char* addr;
	} t_expr;

	typedef struct t_assign {
		char* code;
	} t_assign;

	typedef struct t_bool {
		char* _true;
		char* _false;
		char* code;
	} t_bool;

	
	/* functions declaration */
	int yylex();
	int yyparse();
	void yyerror(char const *s);
	char* temp();
	char* label();
	char* expr_codegen(unsigned short op, t_expr* e, t_expr* e1, t_expr* e2);
	char* assign_codegen(char* varname, t_assign* a, t_expr* e);
	char* bool_codegen(t_bool* b, t_expr* e1, char* rel, t_expr* e2);
	void free_expr(t_expr* expr);
	void free_assign(t_assign* assign);
	t_expr* make_expr();
	void build_program(char* next_line);
	void vars_declaration();
	void concat(char** s1, char* s2);

	

	/* global variables */
	static unsigned int i = 0;
	static unsigned int labelcount = 0;
	int vars[26];
	char vars_decl[26] = "abcdefghijklmnopqrstuvwxyz";
	FILE* dest_file;
	t_bool* bool_ref = NULL;	
	char* program_body = NULL;

	void main(int argc, char ** argv) {
		char* dest_filename = "generated.c";
		if (argc == 1) {
			yyin = stdin;
		}
		else if (argc > 1 && argc <= 3) {
			yyin = fopen(argv[1], "r");
			if (yyin == NULL) {
				printf("Could not open %s\n", argv[1]);
				return;			
			}
			if (argc == 3) {
				dest_filename = argv[2];			
			}
					
		} else if (argc > 3) {
			printf("Usage:\n");
			printf("\t%s <input_file>\n", argv[0]);
			printf("\t%s <input_file> <dest_file.c>\n", argv[0]);
			return; 		
		} 
		dest_file = fopen(dest_filename, "w");
		fprintf(dest_file, "#include<stdio.h>\n\nint main() {\n");
		yyparse();
		vars_declaration();
		fprintf(dest_file, "%s", program_body);
		fprintf(dest_file, "\treturn 1;\n}\n");			
	}
%}

%error-verbose

%union{
	int number;
	char* string;
	struct t_expr* expr;
	struct t_assign* assign;
	struct t_bool* bool;
}

%token <number> INTEGER
%token <string> VAR
%token <string> LT LE GT GE EQ NE 
%token IF THEN ELSE EXIT
%token <number> BOOL
%type <bool> bool_expr
%type <assign> var_assign
%type <expr> expr if_then_else
%type <string> relop;


%left '+' '-'
%left '*' '/'
%left '(' ')'

%%


lines:	 lines line			
	|line								
;

line:	 expr '\n' 			{ 
						char format[50];
						sprintf(format, "\tprintf(\"%%d\\n\", %s);\n", $1->addr);
						concat(&$1->code, format);
						build_program($1->code);												 
						free_expr($1); 
					}
	|if_then_else '\n'		{ build_program($1->code); free_expr($1); }
	|bool_expr '\n'			{ build_program($1->code); free($1->code); free($1);}
	|var_assign '\n'	 	{ build_program($1->code); free_assign($1); }
	|EXIT '\n'			{ return 1; }						
;

if_then_else: IF			{
						bool_ref = (t_bool*) malloc(sizeof(t_bool));
						bool_ref->_true = label();
						bool_ref->_false = label();
					}

	bool_expr THEN expr ELSE expr	{		
						$$ = make_expr();
						$$->next = label();
						char format[20];
						char label_format[20];
						$$->code = strdup("\0");
						concat(&$$->code, bool_ref->code);
						sprintf(label_format, "%s:\n", bool_ref->_true);
						concat(&$$->code, label_format);
						concat(&$$->code, $5->code);
						sprintf(format, "\tprintf(\"%%d\\n\", %s);\n", $5->addr);
						concat(&$$->code, format);
						sprintf(format, "\tgoto %s;\n", $$->next);
						concat(&$$->code, format); 
						sprintf(label_format, "%s:\n", bool_ref->_false);
						concat(&$$->code, label_format);
						concat(&$$->code, $7->code);
						sprintf(format, "\tprintf(\"%%d\\n\", %s);\n", $7->addr); 
						concat(&$$->code, format);
						sprintf(label_format, "%s:\n", $$->next);
						concat(&$$->code, label_format);
						free(bool_ref->_true);
						free(bool_ref->_false);
						free(bool_ref->code);
						free(bool_ref);
						bool_ref = NULL; 
					}
;
			

bool_expr:  expr relop expr		{
						if (bool_ref) {
							$$ = bool_ref;
						} else {
							$$ = (t_bool*) malloc(sizeof(t_bool));
						}
						$$->code = bool_codegen(bool_ref, $1, $2, $3);
						free_expr($1); free_expr($3);	
					}
	   
	   |'('bool_expr')'		{
						$$ = $2;
					}	   				
	   |BOOL			{
						if (bool_ref) {
							$$ = bool_ref;
							char format[20] = "\tgoto %s;\n";
							sprintf(format, format, $1 ? bool_ref->_true : bool_ref->_false);
							$$->code = strdup(format);
						} else {
							$$ = (t_bool*) malloc(sizeof(t_bool));
							$$->code = strdup($1 ? "\tprintf(\"True\\n\");\n" : "\tprintf(\"False\\n\");\n");
						}
					}	
;

relop:   LT
	|LE
	|GT
	|GE
	|EQ
	|NE
;

var_assign: VAR '=' expr 		{
						$$ = (t_assign*) malloc(sizeof(t_assign));
						$$->code = assign_codegen($1, $$, $3);
						free_expr($3);
						vars_decl[$1[0] - 'a'] = '*';
					}
;

expr:	 expr '+' expr			{
						$$ = make_expr(); 
						$$->addr = temp();
						$$->code = expr_codegen(plus_expr, $$, $1, $3);
						free_expr($1); free_expr($3);
					}
	|expr '-' expr			{
						$$ = make_expr(); 
						$$->addr = temp();
						$$->code = expr_codegen(minus_expr, $$, $1, $3);
						free_expr($1); free_expr($3);
					}
	|expr '*' expr			{ 
						$$ = make_expr(); 
						$$->addr = temp();
						$$->code = expr_codegen(mul_expr, $$, $1, $3);
						free_expr($1); free_expr($3);
						
					}
	|expr '/' expr			{ 
						$$ = make_expr(); 
						$$->addr = temp();
						$$->code = expr_codegen(div_expr, $$, $1, $3);
						free_expr($1); free_expr($3);
					}
	|'(' expr ')'			{
						$$ = make_expr();
						$$->addr = strdup($2->addr);
						$$->code = strdup($2->code);
						free_expr($2);
					}
	|'-'expr			{
						$$ = make_expr();
						$$->addr = temp();
						$$->code = expr_codegen(unary_minus, $$, $2, NULL);
						free_expr($2);
					}
	|INTEGER			{ 
						$$ = make_expr(); 
						$$->addr = (char*) malloc(sizeof(char) * 11);
						sprintf($$->addr, "%d", $1);
						$$->code = (char*) malloc(sizeof(char));
						$$->code[0] = '\0';
						
					}
	|VAR				{
						if (vars_decl[$1[0] - 'a'] != '*') {
							fprintf(stderr, "%s'%s'\n", "Error: use of non-declared variable ", $1);
							exit(1);
						}
						$$ = make_expr();
						$$->addr = strdup($1);
						$$->code = (char*) malloc(sizeof(char));
						$$->code[0] = '\0';						
					}
;


%%

void yyerror (char const *s) {
   fprintf(stderr, "%s\n", s);
}

t_expr* make_expr() {
	t_expr* p = (t_expr*)malloc(sizeof(t_expr));
	p->code = NULL;
	p->addr = NULL;
	p->next = NULL;
	return p;
}

char* temp() {
	char temp[15];
	sprintf(temp, "t%d", i++);
	return strdup(temp);
}

char* label() {
	char label[15];
	sprintf(label, "l%d", labelcount++);
	return strdup(label);
}

char* expr_codegen(unsigned short op, t_expr* e, t_expr* e1, t_expr* e2) {
	char format[50];
	char op_symbol;	
	if (op == unary_minus) {
		sprintf(format, "\t%s = -%s;\n", e->addr, e1->addr);
	} else {
		sprintf(format, "\t%s = %s %c %s;\n", e->addr, e1->addr, "+-*/"[op], e2->addr);
	}
	
	char* code = (char*) malloc(sizeof(char));
	code[0] = '\0';
	concat(&code, e1->code);
	if (e2 != NULL) concat(&code, e2->code);
	concat(&code, format);
	return code;
}

char* assign_codegen(char* varname, t_assign* a, t_expr* e) {
	char format[50];
	sprintf(format, "\t%s = %s;\n", varname, e->addr);
	char* code = (char*) malloc(sizeof(char));
	code[0] = '\0';
	concat(&code, e->code);
	concat(&code, format);
	return code;
}

char* bool_codegen(t_bool* b, t_expr* e1, char* rel, t_expr* e2) {
	char format[100];	
	if (b) {
		sprintf(format, "\tif (%s %s %s)\n\t\tgoto %s;\n\telse\n\t\tgoto %s;\n",\
				e1->addr, rel, e2->addr, b->_true, b->_false);
		char* code = (char*) malloc(sizeof(char));
		code[0] = '\0';
		concat(&code, e1->code);
		concat(&code, e2->code);
		concat(&code, format);
		return code;
	}
							
	sprintf(format, "\tprintf(\"%%s\\n\", %s %s %s ? \"True\" : \"False\");\n", e1->addr, rel, e2->addr);							
	return strdup(format);
}

void free_expr(t_expr* expr) { 
	if (expr->code) free(expr->code);
	if (expr->next) free(expr->next);
	if (expr->addr) free(expr->addr);
	free(expr);
}

void free_assign(t_assign* assign) {
	free(assign->code);
	free(assign);
}

void build_program(char* next_line) {
	unsigned int next_line_len = strlen(next_line);
	if (program_body == NULL) {
		program_body = strdup(next_line);
		return;
	}
	unsigned int pb_len = strlen(program_body);
	program_body = realloc(program_body, sizeof(char) * (pb_len + next_line_len + 1));
	strcat(program_body, next_line);
}

void vars_declaration() {
	fprintf(dest_file, "%s", "\tint ");
	int index;
	for (index = 0; index < 26; index++) {
		if (vars_decl[index] == '*')		
			fprintf(dest_file, "%c, ", 'a'+index); 
	}
	for (index = 0; index < i - 1; index++) {
		fprintf(dest_file, "%c%d, ", 't', index);
	}
	fprintf(dest_file, "%c%d;\n", 't', index);
}

void concat(char** s1, char* s2) {
	int total_string_size = sizeof(char) * (strlen(*s1) + strlen(s2) + 1);		
	if (sizeof(*s1) < total_string_size) {
		int double_space = sizeof(*s1) * 2;
		int size = double_space >= total_string_size ? double_space : total_string_size; 		
		*s1 = realloc(*s1, size);
	}
	strcat(*s1, s2);
}
