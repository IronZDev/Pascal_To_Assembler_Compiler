#include "global.hpp"

#define STRMAX 999
char lexemes[STRMAX];
int lastchar = -1;
vector<entry> symtable;
unsigned last_offset = 0;

int lookup (string s) 
{
  for (auto p = symtable.end(); p != symtable.begin(); p--)
    if (p->name == s) 
	{
		return distance(symtable.begin(), p);
	}
  return -1;
}

int insert_id (string s) 
{
  struct entry e;
  e.name = s;
  e.type = VARIABLE;
  e.offset = last_offset;
  last_offset+=4;
  symtable.push_back(e);
  return symtable.size() - 1;
}

int insert_num (string s)
{
  struct entry e;
  e.name = s;
  e.type = NUMBER;
  e.value = stoi(s);
  symtable.push_back(e);
  return symtable.size() - 1;
}

void print_entry(int index) 
{
  if (symtable[index].type == VARIABLE) {
    cout << symtable[index].offset;
  } else if (symtable[index].type == NUMBER) {
    cout << "#" << symtable[index].value;
  }
}


