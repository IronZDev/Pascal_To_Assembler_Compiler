#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <iostream>
#include <vector>
#include <stack>
#include <sstream>
#include <algorithm>
#include <fstream>

using namespace std;

#define BSIZE 128
//#define NUM 256
//#define DIV 257
//#define MOD 258
//#define ID  259
//#define DONE 260
#define GLOBAL -1

static stringstream redirectStream;
static streambuf* oldbuf;
static streambuf* consolebuf;
static ofstream out("out.asm");
extern FILE* yyin;

extern int tokenval;
extern int lineno;
extern unsigned last_offset;
enum dataType{FLOAT, INT, REF_INT, REF_FLOAT, NONE};
enum entryType{VARIABLE, PARAM, NUMBER, FUN, UNDEF};
enum relOps{EQUAL, NOT_EQUAL, SMALLER, SMALLER_EQUAL, GREATER_EQUAL, GREATER};
struct parameters {
  long offset_up;
  long offset_down;
  int output;
  vector<int> inputs;
  vector<int> pendingExpressions;
};
struct val {
  int int_val;
  float float_val;
  parameters params;
};
struct entry {
  string name;
  long offset;
  entryType type;
  dataType dtype;
  val value;
  int scope;
};
struct pendingEntry {
  string name;
  dataType dtype;
};
extern bool isVarDeclaration;
extern bool isParamsDeclaration;
extern stack<long> scopeStack;
extern stack<long> readStack;
extern vector<long> pendingEntries;
extern vector<entry> symtable;
int insert_id (string s, dataType dtype);
int insert_num (string s);
void print_entry(int index, bool preceedHash = false);
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
