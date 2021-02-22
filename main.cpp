#include "global.hpp"
int main (int argc, char* argv[]) 
{
  yyin=fopen(argv[1], "r");
  consolebuf = cout.rdbuf();
  cout.rdbuf(out.rdbuf());
  init ();
  parse ();
  fclose(yyin);
  out.close();
  exit (0);
}


