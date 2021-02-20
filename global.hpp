#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <iostream>
#include <vector>
#include <stack>

using namespace std;

#define BSIZE 128
//#define NUM 256
//#define DIV 257
//#define MOD 258
//#define ID  259
//#define DONE 260
#define GLOBAL -1
extern int tokenval;
extern int lineno;
enum dataType{FLOAT, INT, REF_INT, REF_FLOAT, NONE};
enum entryType{VARIABLE, PARAM, NUMBER, FUN, UNDEF};
enum relOps{EQUAL, NOT_EQUAL, SMALLER, SMALLER_EQUAL, GREATER_EQUAL, GREATER};
struct parameters {
  long offset_up;
  long offset_down;
  int output;
  vector<int> inputs;
};
struct val {
  int int_val;
  float float_val;
  parameters params;
  long ref_offset;
};
struct entry {
  string name;
  long offset;
  entryType type;
  dataType dtype;
  val value;
  int scope;
};
extern bool isVarDeclaration;
extern bool isParamsDeclaration;
extern stack<long> scopeStack;
extern vector<string> pendingEntries;
extern vector<entry> symtable;
int insert_id (string s, dataType dtype);
int insert_num (string s);
void print_entry(int index);
void yyerror (string m) ;
int lookup (string s) ;
void init () ;
void parse () ;
int lexan () ;
void expr () ;
void term () ;
void factor () ;
void match (int t) ;
void emit (int t, int tval) ;
