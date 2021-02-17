#include "global.hpp"

void
yyerror (string m) 
{
  fprintf (stderr, "line%d:%s\n", lineno, m.c_str());
  exit (1);
}

