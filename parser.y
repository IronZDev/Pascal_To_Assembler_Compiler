%{
#include "global.hpp"
int yylex();
bool isVarDeclaration = false;
bool isParamsDeclaration = false;
stack<long> scopeStack;
stack<long> readStack;
vector<pendingEntry> pendingEntries;
unsigned long temp_counter = 0;
unsigned long label_counter = 0;
unsigned long fun_proc_counter = 0;

long getFunProcLabel() {
	fun_proc_counter++;
	return fun_proc_counter;
}

long getLabel() {
	label_counter++;
	return label_counter;
};

long genTemp(dataType dtype) {
	long temp;
	if (dtype == INT) {
		temp = insert_id("$temp"+to_string(temp_counter), INT);
	} else {
		temp = insert_id("$temp"+to_string(temp_counter), FLOAT);
	}
	temp_counter++;
	return temp;
}

int genOp(string op,int var1, int var2) {
	int ret;
	// If both int leave int, if one is real all to real
	if (symtable[var1].dtype == INT || symtable[var1].dtype == REF_INT)
	{
		if(symtable[var2].dtype == INT || symtable[var2].dtype == REF_INT)
		{
			ret = genTemp(INT);
			cout << "\t" << op <<".i "; print_entry(var1); cout << ","; print_entry(var2); cout << ","; print_entry(ret); cout << endl;
		}
		else 
		{
			ret = genTemp(FLOAT);
			int temp = genTemp(FLOAT);
			cout << "\tinttoreal.i "; print_entry(var1); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << op <<".r "; print_entry(temp); cout << ","; print_entry(var2); cout << ","; print_entry(ret); cout << endl;
		}
	}
	if (symtable[var1].dtype == FLOAT || symtable[var1].dtype == REF_FLOAT)
	{
		ret = genTemp(FLOAT);
		if(symtable[var2].dtype == FLOAT || symtable[var2].dtype == REF_FLOAT)
		{
			cout << "\t" << op <<".r "; print_entry(var1); cout << ","; print_entry(var2); cout << ","; print_entry(ret); cout << endl;
		}
		else
		{
			int temp = genTemp(FLOAT);
			cout << "\tinttoreal.i "; print_entry(var2); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << op <<".r "; print_entry(var1); cout << ","; print_entry(temp); cout << ","; print_entry(ret); cout << endl;
		}
	}
	return ret;
}

int genRelOp(relOps relOp, int var1, int var2) {
	long ret_label = getLabel();
	long ret_bool = genTemp(INT);
	string relOpName;
	switch (relOp) {
		case EQUAL:
			relOpName = "je";
			break;
		case NOT_EQUAL:
			relOpName = "jne";
			break;
		case SMALLER:
			relOpName = "jl";
			break;
		case SMALLER_EQUAL:
			relOpName = "jle";
			break;
		case GREATER_EQUAL:
			relOpName = "jge";
			break;
		case GREATER:
			relOpName = "jg";
			break;
	}
	if (symtable[var1].dtype == INT || symtable[var1].dtype == REF_INT)
	{
		temp_counter++;
		if(symtable[var2].dtype == INT || symtable[var2].dtype == REF_INT)
		{
			cout << "\t" << relOpName <<".i "; print_entry(var1); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		} else {
			int temp = genTemp(FLOAT);
			temp_counter++;
			cout << "\tinttoreal.i "; print_entry(var1); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << relOpName <<".r "; print_entry(temp); cout << ","; print_entry(var2); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		}
	}
	if (symtable[var1].dtype == FLOAT || symtable[var1].dtype == REF_FLOAT)
	{
		temp_counter++;
		if(symtable[var2].dtype == FLOAT || symtable[var2].dtype == REF_FLOAT)
		{
			cout << "\t" << relOpName <<".r "; print_entry(var1); cout << ","; print_entry(var2); cout << ", #lab"+to_string(ret_label) << endl;
		}
		else
		{
			int temp = genTemp(FLOAT);
			temp_counter++;
			cout << "\tinttoreal.i "; print_entry(var2); cout << ","; print_entry(temp); cout << endl;
			cout << "\t" << relOpName <<".r "; print_entry(var1); cout << ","; print_entry(temp); cout << ", #lab"+to_string(ret_label) << endl;
		}
	}
	long end_if_label = getLabel();
	cout << "\tmov.i #0,"; print_entry(ret_bool); cout << endl;
	cout << "\tjump.i #lab"+to_string(end_if_label) << endl;
	cout << "lab" + to_string(ret_label) + ":" << endl;
	cout << "\tmov.i #1,"; print_entry(ret_bool); cout << endl;
	cout << "lab" + to_string(end_if_label) +  ":" << endl;
	return ret_bool;
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
%token WRITE
%token READ

%%
program: PROGRAM ID {cout << "\tjump.i #start" << endl;} '(' identifier_list ')' ';' declarations subprogram_declarations {cout << "start:" << endl;} compound_statement '.' {cout<<"\texit"<<endl;}
	;

identifier_list: ID | identifier_list ',' ID
	;

declarations: declarations VAR {isVarDeclaration=true;} identifier_list ':' type {
		isVarDeclaration = false;
		for (auto it = pendingEntries.begin(); it != pendingEntries.end(); ++it) {
			insert_id (it->name, dataType($6));
		}
		pendingEntries.clear();
	} ';'
	|
	;

/*
type: standard_type {$$ = $1;}
	;
*/

type: standard_type {$$ = $1;}
	| ARRAY '[' NUM ARRAY_DELIM NUM ']' OF standard_type
	;

standard_type: INTEGER
	| REAL
	;

subprogram_declarations: subprogram_declarations subprogram_declaration ';'
	|
	;
	
subprogram_declaration: subprogram_head declarations compound_statement {
		string scope_content = redirectStream.str();
		cout.rdbuf(oldbuf);
		redirectStream.str(string()); // Clear buffer
		cout << "\tenter.i #"+to_string(abs(symtable[scopeStack.top()].value.params.offset_down)) << endl;
		cout << scope_content;
		scopeStack.pop();
	}
	;
	
subprogram_head: FUNCTION ID {
		cout << symtable[$2].name << ":" << endl;
		scopeStack.push($2);
		symtable[$2].type = FUN;
		symtable[$2].value.params.offset_up = 12;
		symtable[$2].value.params.offset_down = 0;
		isParamsDeclaration = true;
		oldbuf = cout.rdbuf(redirectStream.rdbuf());
	} arguments ':' standard_type ';' {
		long currentScope = scopeStack.top();
		for (auto it = pendingEntries.rbegin(); it != pendingEntries.rend(); ++it) {
			int index = insert_id (it->name, it->dtype);
			symtable[currentScope].value.params.inputs.push_back(index);
		}
		pendingEntries.clear();
		entry e;
		e.name = symtable[$2].name;
		e.offset = 8;
		e.type = PARAM;
		e.dtype = dataType($6);
		symtable.push_back(e);
		if (dataType($6) == REF_INT) {
			symtable[$2].dtype = INT;
		} else {
			symtable[$2].dtype = FLOAT;
		}
		symtable[$2].value.params.output = symtable.size() - 1;
		isParamsDeclaration = false;
	}
	| PROCEDURE ID {
		cout << symtable[$2].name << ":" << endl;
		scopeStack.push($2);
		symtable[$2].type = UNDEF;
		symtable[$2].value.params.offset_up = 8;
		symtable[$2].value.params.offset_down = 0;
		isParamsDeclaration = true;
		oldbuf = cout.rdbuf(redirectStream.rdbuf());
	} arguments ';' {
		long currentScope = scopeStack.top();
		for (auto it = pendingEntries.rbegin(); it != pendingEntries.rend(); ++it) {
			int index = insert_id (it->name, it->dtype);
			symtable[currentScope].value.params.inputs.push_back(index);
		}
		pendingEntries.clear();
		isParamsDeclaration = false;
	}
	;

arguments: '(' parameter_list ')'
	|
	;

parameter_list: identifier_list ':' type {
		// Add parameter from last to first to maintain correct order on stack
		for (auto it = pendingEntries.rbegin(); it != pendingEntries.rend(); ++it) {
			//int index = insert_id (*it, dataType($3));
			//symtable[currentScope].value.params.inputs.push_back(index);
			it->dtype = dataType($3);
		}
		//pendingEntries.clear();
	}
	| parameter_list ';' identifier_list ':' type {
		for (auto it = pendingEntries.rbegin(); it != pendingEntries.rend(); ++it) {
			//int index = insert_id (*it, dataType($5));
			//symtable[currentScope].value.params.inputs.push_back(index);
			it->dtype = dataType($5);
		}
		//pendingEntries.clear();
	}
	;

compound_statement: BEGIN_TOK optional_statements END {
		if (scopeStack.size() > 0) {
			cout<<"\tleave"<<endl;
			cout<<"\treturn"<<endl;
		}
	}
	;

optional_statements: statement_list
	|
	;

statement_list: statement
	| statement_list ';' statement
	;

statement: variable ASSIGNOP expression {
		if (symtable[$1].dtype == FLOAT || symtable[$1].dtype == REF_FLOAT) {
			if (symtable[$3].dtype == INT || symtable[$3].dtype == REF_INT) {
				cout << "\tinttoreal.i "; print_entry($3); cout << ","; print_entry($1); cout << endl;
			} else {
				cout << "\tmov.r "; print_entry($3); cout << ","; print_entry($1); cout << endl;
			}
		} else {
			if (symtable[$3].dtype == FLOAT || symtable[$3].dtype == REF_FLOAT) {
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
	expression {
		long if_false = getLabel();
		$$ = if_false;
		if (symtable[$3].dtype == FLOAT || symtable[$3].dtype == REF_FLOAT) {
			cout << "\tje.r #0,"; print_entry($3); cout << ", #lab"+to_string(if_false) << endl;
		} else {
			cout << "\tje.i #0,"; print_entry($3); cout << ", #lab"+to_string(if_false) << endl;
		}
	}
	THEN 
	statement {
		cout << "\tjump.i #lab" + to_string($2) << endl;
	}  ELSE {
		cout << "lab"+to_string($4)+":" << endl;
	} statement {
		cout << "lab"+to_string($2)+":" << endl;
	}
	| WHILE {
		long again_id = getLabel();
		$$ = again_id;
		cout << "lab" << again_id << ":" << endl;
	}
	expression {
		long exit_loop = getLabel();
		$$ = exit_loop;
		cout << "\tje.i #0,"; print_entry($3); cout << ",#lab"+to_string(exit_loop) << endl;
	} DO statement {
		cout << "\tjump.i #lab" + to_string($2) << endl;
		cout << "lab"+to_string($4)+":" << endl;
	}
	;

variable: ID {
		// Make a function call only if we are calling it from outside of it, otherwise return just a pointer to the return value
		if (symtable[$1].type == FUN && (scopeStack.size() == 0
		|| (scopeStack.size() != 0 && scopeStack.top() != symtable[$1].scope))) {
			int sp_counter = 0;
				sp_counter += 4;
				long output = genTemp(symtable[$1].dtype);
				symtable[$1].offset = symtable[output].offset; // Set the offset to the one of the temp value holding the result
				cout << "\tpush.i "; print_entry(output, true); cout << endl;
			// Remove temp symbol from the name of the function
			string name = symtable[$1].name;
			name.erase(remove(name.begin(), name.end(), '$'), name.end());
			cout << "\tcall.i #" + name << endl;
			cout << "\tincsp.i #" + to_string(sp_counter) << endl;
		}
		$$ = $1;
	}	
	| ID '[' expression ']'
	;

procedure_statement: ID {
		// Make a function call only if we are calling it from outside of it, otherwise return just a pointer to the return value
		if ((symtable[$1].type == FUN || symtable[$1].type == UNDEF) 
		&& (scopeStack.size() == 0
		|| (scopeStack.size() != 0 && scopeStack.top() != symtable[$1].scope))) {
			int sp_counter = 0;
			if (symtable[$1].type == FUN) {
				sp_counter += 4;
				long output = genTemp(symtable[$1].dtype);
				symtable[$1].offset = symtable[output].offset; // Set the offset to the one of the temp value holding the result
				cout << "\tpush.i "; print_entry(output, true); cout << endl;
			}
			// Remove temp symbol from the name of the function
			string name = symtable[$1].name;
			name.erase(remove(name.begin(), name.end(), '$'), name.end());
			cout << "\tcall.i #" + name << endl;
			if (symtable[$1].type == FUN) {
				cout << "\tincsp.i #" + to_string(sp_counter) << endl;
			}
		}
		$$ = $1;
	}
	| WRITE {readStack.push($1);} '(' expression_list ')' {
		readStack.pop();
		for (auto it = symtable[$1].value.params.pendingExpressions.begin(); it != symtable[$1].value.params.pendingExpressions.end(); ++it) {
			if (symtable[*it].dtype == FLOAT) {
				cout << "\twrite.r "; print_entry(*it); cout << endl;
			} else {
				cout << "\twrite.i "; print_entry(*it); cout << endl;
			}
		}
		symtable[$1].value.params.pendingExpressions.clear();
	}
	| READ {readStack.push($1);} '(' expression_list ')' {
		readStack.pop();
		for (auto it = symtable[$1].value.params.pendingExpressions.begin(); it != symtable[$1].value.params.pendingExpressions.end(); ++it) {
			if (symtable[*it].dtype == FLOAT) {
				cout << "\tread.r "; print_entry(*it); cout << endl;
			} else {
				cout << "\tread.i "; print_entry(*it); cout << endl;
			}
		}
		symtable[$1].value.params.pendingExpressions.clear();
	}
	| ID {
			// Handle recurency
			readStack.push($1);
			if (scopeStack.size() != 0 && scopeStack.top() == symtable[$1].scope) {
				symtable[$1].scope = -1;
			}
		} '(' expression_list ')' {
		readStack.pop();
		int sp_counter = 0;
		if (symtable[$1].value.params.pendingExpressions.size() != symtable[$1].value.params.inputs.size()) {
			yyerror("Wrong number of input arguments!");
		}
		auto input_ref = symtable[$1].value.params.inputs.rbegin();
		for (auto it = symtable[$1].value.params.pendingExpressions.begin(); it != symtable[$1].value.params.pendingExpressions.end(); ++it) {
			sp_counter += 4;
			if (symtable[*input_ref].dtype == REF_FLOAT) {
				if (symtable[*it].dtype == REF_FLOAT || symtable[*it].dtype == FLOAT) {
					cout << "\tpush.i "; print_entry(*it, true); cout << endl;
				} else {
					long converted_val = genTemp(FLOAT);
					cout << "\tinttoreal.i "; print_entry(*it); cout << ","; print_entry(converted_val); cout << endl;
					cout << "\tpush.i "; print_entry(converted_val, true); cout << endl;
				}
			} else {
				if (symtable[*it].dtype == REF_INT || symtable[*it].dtype == INT) {
					cout << "\tpush.i "; print_entry(*it, true); cout << endl;
				} else {
					long converted_val = genTemp(INT);
					cout << "\trealtoint.r "; print_entry(*it); cout << ","; print_entry(converted_val); cout << endl;
					cout << "\tpush.i "; print_entry(converted_val, true); cout << endl;
				}
			}
			input_ref++;
			//cout << "\tpush.i "; print_entry(*it, true); cout << endl;
		}
		if (symtable[$1].type == FUN) {
			sp_counter += 4;
			long output = genTemp(symtable[$1].dtype);
			symtable[$1].offset = symtable[output].offset; // Set the offset to the one of the temp value holding the result
			cout << "\tpush.i "; print_entry(output, true); cout << endl;
		}
		// Remove temp symbol from the name of the function
		string name = symtable[$1].name;
		name.erase(remove(name.begin(), name.end(), '$'), name.end());
		cout << "\tcall.i #" + name << endl;
		cout << "\tincsp.i #" + to_string(sp_counter) << endl;
		symtable[$1].value.params.pendingExpressions.clear();
		$$ = $1;
	}
	;

expression_list: expression {
		if(symtable[$1].type == NUMBER) {
			long temp = genTemp(symtable[$1].dtype);
			if (symtable[$1].dtype == FLOAT) {
				cout << "\tmov.r "; print_entry($1); cout << ","; print_entry(temp); cout<<endl;
			} else {
				cout << "\tmov.i "; print_entry($1); cout << ","; print_entry(temp); cout<<endl;
			}
			symtable[readStack.top()].value.params.pendingExpressions.push_back(temp);
		} else {
			symtable[readStack.top()].value.params.pendingExpressions.push_back($1);
		}
	}
	| expression_list ',' expression {
		if(symtable[$3].type == NUMBER) {
			long temp = genTemp(symtable[$3].dtype);
			if (symtable[$3].dtype == FLOAT) {
				cout << "\tmov.r "; print_entry($3); cout << ","; print_entry(temp); cout<<endl;
			} else {
				cout << "\tmov.i "; print_entry($3); cout << ","; print_entry(temp); cout<<endl;
			}
			symtable[readStack.top()].value.params.pendingExpressions.push_back(temp);
		} else {
			symtable[readStack.top()].value.params.pendingExpressions.push_back($3);
		}
	}
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
			$$=genOp("add", $1, $3);
		} else {
			$$=genOp("sub", $1, $3);
		}
	}
	| simple_expression OR term {
		$$=genOp("or", $1, $3);
	}
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
				res = genOp("mod", $1, $3);
				// if (symtable[res].dtype == FLOAT) {
				// 	int int_div = genTemp(INT);
				// 	cout << "\trealtoint.r "; print_entry(res); cout << ","; print_entry(int_div); cout<<endl;
				// 	res = int_div;
				// }
				// $$ = genOp("sub", $1, res);
				$$ = res;
				break;
			case 'a':
				$$ = genOp("and", $1, $3);
				break;
		}
	}
	;

factor: variable { $$=$1; }
	| ID {
			// Handle recurency
			readStack.push($1);
			if (scopeStack.size() != 0 && scopeStack.top() == symtable[$1].scope) {
				symtable[$1].scope = -1;
			}
		} '(' expression_list ')' {
		readStack.pop();
		int sp_counter = 0;
		if (symtable[$1].value.params.pendingExpressions.size() != symtable[$1].value.params.inputs.size()) {
			yyerror("Wrong number of input arguments!");
		}
		// Convert to proper type
		auto input_ref = symtable[$1].value.params.inputs.rbegin();
		for (auto it = symtable[$1].value.params.pendingExpressions.begin(); it != symtable[$1].value.params.pendingExpressions.end(); ++it) {
			sp_counter += 4;
			//cout << "Orig" + symtable[*it].name << endl;
			//cout << "Ref" + symtable[*input_ref].name << endl;
			if (symtable[*input_ref].dtype == REF_FLOAT) {
				if (symtable[*it].dtype == REF_FLOAT || symtable[*it].dtype == FLOAT) {
					cout << "\tpush.i "; print_entry(*it, true); cout << endl;
				} else {
					long converted_val = genTemp(FLOAT);
					cout << "\tinttoreal.i "; print_entry(*it); cout << ","; print_entry(converted_val); cout << endl;
					cout << "\tpush.i "; print_entry(converted_val, true); cout << endl;
				}
			} else {
				if (symtable[*it].dtype == REF_INT || symtable[*it].dtype == INT) {
					cout << "\tpush.i "; print_entry(*it, true); cout << endl;
				} else {
					long converted_val = genTemp(INT);
					cout << "\trealtoint.r "; print_entry(*it); cout << ","; print_entry(converted_val); cout << endl;
					cout << "\tpush.i "; print_entry(converted_val, true); cout << endl;
				}
			}
			input_ref++;
			//cout << "\tpush.i "; print_entry(*it, true); cout << endl;
		}
		if (symtable[$1].type == FUN) {
			sp_counter += 4;
			long output = genTemp(symtable[$1].dtype);
			symtable[$1].offset = symtable[output].offset; // Set the offset to the one of the temp value holding the result
			cout << "\tpush.i "; print_entry(output, true); cout << endl;
		}
		// Remove temp symbol from the name of the function
		string name = symtable[$1].name;
		name.erase(remove(name.begin(), name.end(), '$'), name.end());
		cout << "\tcall.i #" + name << endl;
		cout << "\tincsp.i #" + to_string(sp_counter) << endl;
		symtable[$1].value.params.pendingExpressions.clear();
		$$ = $1;
	}
	| NUM { $$ = $1; }
	| '(' expression ')' { $$ = $2; }
	| NOT factor {
		long negated_temp = genTemp(INT);
		if (symtable[$2].dtype == FLOAT || symtable[$2].dtype == REF_FLOAT) {
			long converted_to_int = genTemp(INT);
			cout << "\trealtoint.r "; print_entry($2); cout << ","; print_entry(converted_to_int); cout << endl;
		}
		cout << "\tnot.i "; print_entry($2); cout << ","; print_entry(negated_temp); cout << endl;
		$$ = negated_temp;
	}
	;
%%

void parse() {yyparse();}
