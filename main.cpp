#include "global.hpp"
extern FILE* yyin;
int main (int argc, char* argv[]) 
{
  yyin=fopen(argv[1], "r");
  init ();
  parse ();
  fclose(yyin);
  exit (0);
}


