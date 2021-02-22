#include "global.hpp"

void
yyerror (string m) 
{
  cout.rdbuf(consolebuf);
  fprintf (stderr, "line%d:%s\n", lineno, m.c_str());
  out.close();
  fclose(yyin);
  exit (1);
}

