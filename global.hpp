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
enum dataType{FLOAT, INT};
enum entryType{VARIABLE, NUMBER, UNDEF};
struct entry {
  string name;
  unsigned offset;
  entryType type;
  dataType dtype;
  int value;
};
extern vector<entry> symtable;
int insert (string s, int tok);
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
