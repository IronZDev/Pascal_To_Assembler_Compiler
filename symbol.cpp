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

int insert_id (string s, dataType dtype) 
{
  // cout<<"Add to symtable: "<<s<<endl;
  // cout<<"Current offset: "<<last_offset<<endl;
  // cout<<"Data type:"<<dtype<<endl;
  struct entry e;
  e.name = s;
  e.type = VARIABLE;
  e.dtype = dtype;
  e.offset = last_offset;
  if (dtype == INT)
  {
    last_offset+=4;
  } else if (dtype == FLOAT)
  {
    last_offset+=8;
  }
  symtable.push_back(e);
  return symtable.size() - 1;
}

int insert_num (string s)
{
  struct entry e;
  e.name = s;
  e.type = NUMBER;
  if (s.find('.') != string::npos) {
    e.dtype = FLOAT;
    e.value.float_val = stof(s);
  } else {
    e.dtype = INT;
    e.value.int_val = stoi(s);
  }
  symtable.push_back(e);
  return symtable.size() - 1;
}

void print_entry(int index) 
{
  if (symtable[index].type == VARIABLE) {
    cout << symtable[index].offset;
  } else if (symtable[index].type == NUMBER) {
    if (symtable[index].dtype == INT) {
      cout << "#" << symtable[index].value.int_val;
    } else {
      cout << "#" << symtable[index].value.float_val;
    }
  }
}


