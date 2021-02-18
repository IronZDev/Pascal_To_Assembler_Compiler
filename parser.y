%{
#include "global.hpp"
int yylex();
bool isVarDeclaration = false;
vector<string> pendingEntries;
unsigned long temp_counter = 0;
unsigned long label_counter = 0;

long getLabel() {
	label_counter++;
	return label_counter;
};

int genTemp(dataType dtype) {
	int temp;
	if (dtype == INT) {
		temp = insert_id("temp"+to_string(temp_counter), INT);
	} else {
		temp = insert_id("temp"+to_string(temp_counter), FLOAT);
	}
	temp_counter++;
	return temp;
}

int genOp(string op,int var1, int var2) {
	int ret;
	if (symtable[var1].dtype == INT)
	{
		ret = genTemp(INT);
		temp_counter++;
		if(symtable[var2].dtype == INT)
		{
			cout << "\t" << op <<".i "; print_entry(var1); cout << ","; print_entry(var2); cout << ","; print_entry(ret); cout << endl;
		}
		else 
		{
			int temp = genTemp(INT);
			temp_counter++;
			cout << "\trealtoint.r "; print_entry(var2); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << op <<".i "; print_entry(var1); cout << ","; print_entry(temp); cout << ","; print_entry(ret); cout << endl;
		}
	}
	if (symtable[var1].dtype == FLOAT)
	{
		ret = genTemp(FLOAT);
		temp_counter++;
		if(symtable[var2].dtype == FLOAT)
		{
			cout << "\t" << op <<".r "; print_entry(var1); cout << ","; print_entry(var2); cout << ","; print_entry(ret); cout << endl;
		}
		else
		{
			int temp = genTemp(FLOAT);
			temp_counter++;
			cout << "\tinttoreal.i "; print_entry(var2); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << op <<".r "; print_entry(var1); cout << ","; print_entry(temp); cout << ","; print_entry(ret); cout << endl;
		}
	}
	return ret;
}

int genRelOp(relOps relOp, int var1, int var2) {
	int ret_label = getLabel();
	string relOpName;
	switch (relOp) {
		case EQUAL:
			relOpName = "jne";
			break;
		case NOT_EQUAL:
			relOpName = "je";
			break;
		case SMALLER:
			relOpName = "jge";
			break;
		case SMALLER_EQUAL:
			relOpName = "jg";
			break;
		case GREATER_EQUAL:
			relOpName = "jl";
			break;
		case GREATER:
			relOpName = "jle";
			break;
	}
	if (symtable[var1].dtype == INT)
	{
		temp_counter++;
		if(symtable[var2].dtype == INT)
		{
			cout << "\t" << relOpName <<".i "; print_entry(var1); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		} else {
			int temp = genTemp(FLOAT);
			temp_counter++;
			cout << "\tinttoreal.i "; print_entry(var1); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << relOpName <<".r "; print_entry(temp); cout << ","; print_entry(var2); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		}
	}
	if (symtable[var1].dtype == FLOAT)
	{
		temp_counter++;
		if(symtable[var2].dtype == FLOAT)
		{
			cout << "\t" << relOpName <<".r "; print_entry(var1); cout << ","; print_entry(var2); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		}
		else
		{
			int temp = genTemp(FLOAT);
			temp_counter++;
			cout << "\tinttoreal.i "; print_entry(var2); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << relOpName <<".r "; print_entry(var1); cout << ","; print_entry(temp); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		}
	}
	return ret_label;
}
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

declarations: declarations VAR {isVarDeclaration=true;} identifier_list ':' type {
		isVarDeclaration = false;
		for (auto it = pendingEntries.begin(); it != pendingEntries.end(); ++it) {
			insert_id (*it, dataType($6));
		}
		pendingEntries.clear();
	} ';'
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

compound_statement: BEGIN_TOK optional_statements END {cout<<"\texit"<<endl;}
	;

optional_statements: statement_list
	|
	;

statement_list: statement
	| statement_list ';' statement
	;

statement: variable ASSIGNOP expression {
		if (symtable[$1].dtype == FLOAT) {
			if (symtable[$3].dtype != FLOAT) {
				cout << "\tinttoreal.i "; print_entry($3); cout << ","; print_entry($1); cout << endl;
			} else {
				cout << "\tmov.r "; print_entry($3); cout << ","; print_entry($1); cout << endl;
			}
		} else {
			if (symtable[$3].dtype != INT) {
				cout << "\trealtoint.r "; print_entry($3); cout << ","; print_entry($1); cout << endl;
			} else {
				cout << "\tmov.i "; print_entry($3); cout << ","; print_entry($1); cout << endl;
			}
		}
	}
	| procedure_statement
	| compound_statement
	| IF {
		long end_if = getLabel();
		$$ = end_if;
	}
	expression 
	THEN 
	statement {
		cout << "\tjump.i #lab"+to_string($2) << endl;
	}  ELSE {
		cout << "lab"+to_string($3)+":" << endl;
	} statement {
		cout << "lab"+to_string($2)+":" << endl;
	}
	| WHILE {
		long again_id = getLabel();
		$$ = again_id;
		cout << "lab" << again_id << ":" << endl;
	}
	expression DO statement {
		cout << "\tjump #lab" << $2 << endl;
		cout << "lab" << $3 <<": " << endl;
	}
	;

variable: ID {$$=$1;}	
	| ID '[' expression ']'
	;

procedure_statement: ID
	| ID {cout<<"write.i ";} '(' expression_list ')' {print_entry($4); cout<<endl;}
	;

expression_list: expression
	| expression_list ',' expression
	;

expression: simple_expression {$$=$1;}
	| simple_expression RELOP simple_expression {
		$$ = genRelOp(relOps($2), $1, $3);
	}
	;

simple_expression: term {$$ = $1;}
	| SIGN term {
		if ($1 == '+') {
			$$ = $2;
		} else {
			$$ = genOp("sub", insert_num("0"), $2);
		}
	}
	| simple_expression SIGN term {
		if ($2 == '+') {
			$$=genOp("add",$1, $3);
		} else {
			$$=genOp("sub",$1, $3);
		}
	}
	| simple_expression OR term
	;

term: factor { $$ = $1; }
	| term MULOP factor {
		int res;
		switch ($2) {
			case '*':
				$$ = genOp("mul", $1, $3);
				break;
			case '/':
				$$ = genOp("div", $1, $3);
				break;
			case 'd':
				res = genOp("div", $1, $3);
				if (symtable[res].dtype == FLOAT) {
					int temp = genTemp(INT);
					cout << "\trealtoint.r "; print_entry(res); cout << ","; print_entry(temp); cout<<endl;
					$$ = temp;
				} else {
					$$ = res;
				}
				break;
			case 'm':
				res = genOp("div", $1, $3);
				if (symtable[res].dtype == FLOAT) {
					int int_div = genTemp(INT);
					cout << "\trealtoint.r "; print_entry(res); cout << ","; print_entry(int_div); cout<<endl;
					res = int_div;
				}
				$$ = genOp("sub", $1, res);
				break;
			case 'a':
				break;
		}
	}
	;

factor: variable { $$=$1; }
	| ID '(' expression_list ')' 
	| NUM { $$ = $1; }
	| '(' expression ')' { $$ = $2; }
	| NOT factor
	;
%%

void parse() {yyparse();}
