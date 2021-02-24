#include "global.hpp"

#define STRMAX 999
char lexemes[STRMAX];
int lastchar = -1;
vector<entry> symtable;
unsigned last_offset = 0;

int lookup (string s) 
{
  // First look in local scope, then check in global scope
  if (scopeStack.size() != 0) {
    for (auto p = symtable.begin(); p != symtable.end(); p++)
      if (p->name == s && scopeStack.top() == p->scope) 
      {
        return distance(symtable.begin(), p);
      }
  }
  for (auto p = symtable.begin(); p != symtable.end(); p++)
    if (p->name == s && p->scope == GLOBAL) 
    {
      return distance(symtable.begin(), p);
    }
  return -1;
}

int insert_id (string s, dataType dtype) 
{
  //cout<<"Add to symtable: "<<s<<endl;
  //cout<<scopeStack.size()<<endl;
  // cout<<"Current offset: "<<last_offset<<endl;
  // cout<<"Data type:"<<dtype<<endl;
  struct entry e;
  e.name = s;
  e.type = VARIABLE;
  e.dtype = dtype;
  if (isParamsDeclaration) {
    e.scope = scopeStack.top();
    e.type = PARAM;
  } else if (scopeStack.size() > 0) {
    e.scope = scopeStack.top();
    if (dtype == INT)
    {
      symtable[scopeStack.top()].value.params.offset_down -= 4;
      e.offset = symtable[scopeStack.top()].value.params.offset_down;

    } else if (dtype == FLOAT)
    {
      symtable[scopeStack.top()].value.params.offset_down -= 8;
      e.offset = symtable[scopeStack.top()].value.params.offset_down;
    }
  } else {
    //cout << "GLOBAL" << endl;
    e.scope = GLOBAL;
    e.offset = last_offset;
    if (dtype == INT)
    {
      e.offset = last_offset;
      last_offset += 4;
    } else if (dtype == FLOAT)
    {
      e.offset = last_offset;
      last_offset += 8;
    }
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

void print_entry(int index, bool preceedHash) 
{
  if (symtable[index].type == VARIABLE) {
    if (preceedHash) {
      cout << "#";
    }
    if (scopeStack.size() > 0 && symtable[index].scope != GLOBAL) {
      //cout << symtable[index].offset << endl;
      //cout << symtable[index].scope << endl;
      cout << "BP" + to_string(symtable[index].offset);
    } else {
      cout << symtable[index].offset;
    }
  } else if (symtable[index].type == NUMBER) {
    if (symtable[index].dtype == INT) {
      cout << "#" << symtable[index].value.int_val;
    } else if (symtable[index].dtype == FLOAT) {
      cout << "#" << symtable[index].value.float_val;
    }
  } else if (symtable[index].type == FUN) {
    if (preceedHash) {
      cout << "#";
    }
    if (scopeStack.size() != 0 && (scopeStack.top() == symtable[index].scope || scopeStack.top() == index)) {
      print_entry(symtable[index].value.params.output);
    } else if (scopeStack.size() != 0) {
      cout << "BP" + to_string(symtable[index].offset);
    } else {
      cout << symtable[index].offset;
    }
  } else if (symtable[index].type == PARAM) {
    if (preceedHash) {
      cout << "BP+" << symtable[index].offset;
    } else {
      cout << "*BP+" << symtable[index].offset;    }
  }
}


