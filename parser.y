%{
#include "global.hpp"
int yylex();
%}

%token PROGRAM
%token ID
%token NUM
%token INTEGER
%token REAL
%token VAR
%token FUNCTION
%token PROCEDURE
%token BEGIN_TOK
%token END
%token ASSIGNOP
%token IF
%token THEN
%token ELSE
%token WHILE
%token DO
%token RELOP
%token SIGN
%token OR
%token MULOP
%token NOT
%token OF
%token ARRAY_DELIM
%token ARRAY

%%
program: PROGRAM ID '(' identifier_list ')' ';' declarations subprogram_declarations compound_statement '.'
	;

identifier_list: ID | identifier_list ',' ID
	;

declarations: declarations VAR identifier_list ':' type ';' 
	|
	;

/*
type: standard_type
	;
*/

type: standard_type 
	| ARRAY '[' NUM ARRAY_DELIM NUM ']' OF standard_type
	;

standard_type: INTEGER
	| REAL
	;

subprogram_declarations: subprogram_declarations subprogram_declaration ';'
	|
	;
	
subprogram_declaration: subprogram_head declarations compound_statement
	;
	
subprogram_head: FUNCTION ID arguments ':' standard_type ';'
	| PROCEDURE ID arguments ';'
	;

arguments: '(' parameter_list ')'
	|
	;

parameter_list: identifier_list ':' type
	| parameter_list ';' identifier_list ':' type
	;

compound_statement: BEGIN_TOK optional_statements END
	;

optional_statements: statement_list
	|
	;

statement_list: statement
	| statement_list ';' statement
	;

statement: variable ASSIGNOP expression
	| procedure_statement
	| compound_statement
	| IF expression THEN statement ELSE statement
	| WHILE expression DO statement
	;

variable: ID	
	| ID '[' expression ']'
	;

procedure_statement: ID
	| ID '(' expression_list ')' {cout<<"write.i "<<$3<<endl;}
	;

expression_list: expression
	| expression_list ',' expression
	;

expression: simple_expression
	| simple_expression RELOP simple_expression
	;

simple_expression: term
	| SIGN term
	| simple_expression SIGN term
	| simple_expression OR term
	;

term: factor
	| term MULOP factor
	;

factor: variable 
	| ID '(' expression_list ')' 
	| NUM 
	| '(' expression ')' 
	| NOT factor
	;
%%

void parse() {yyparse();}
