#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <iostream>
#include <vector>

using namespace std;

#define BSIZE 128
//#define NUM 256
//#define DIV 257
//#define MOD 258
//#define ID  259
//#define DONE 260
extern int tokenval;
extern int lineno;
enum dataType{FLOAT, INT, NONE};
enum entryType{VARIABLE, NUMBER, UNDEF};
enum relOps{EQUAL, NOT_EQUAL, SMALLER, SMALLER_EQUAL, GREATER_EQUAL, GREATER};
union val {
  int int_val;
  float float_val;
};
struct entry {
  string name;
  unsigned offset;
  entryType type;
  dataType dtype;
  val value;
};
extern bool isVarDeclaration;
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
