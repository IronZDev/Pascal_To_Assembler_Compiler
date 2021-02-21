%option noyywrap
%{
    #include "global.hpp"
    #include "parser.hpp"
    char lexbuf[BSIZE];
    int lineno = 1;
%}

/* regular definitions */
delim				[ \t]+
newline				[\n]
digit				[0-9]
letter				[A-Za-z]
id					{letter}({letter}|{digit})*
digits				{digit}+
optional_fraction	.{digits}
optional_exponent	E(\+|-){digits}
num                 {digits}{optional_fraction}?{optional_exponent}?
relop				=|<>|<|<=|>=|>
sign				\+|-
mulop				\*|\/|div|mod|and
assignop			:=
array_delim         \.\.

%%
{delim}		{}
{newline}	{lineno++;}
program		{return PROGRAM;}
function	{return FUNCTION;}
procedure	{return PROCEDURE;}
array       {return ARRAY;}
integer     {
        if (isParamsDeclaration) {
            yylval = REF_INT;
        } else {
            yylval = INT;
        }
        return INTEGER;
    }
real        {
        if (isParamsDeclaration) {
            yylval = REF_FLOAT;
        } else {
            yylval = FLOAT;
        } return REAL;
    }
var         {return VAR;}
begin       {return BEGIN_TOK;}
end         {return END;}
{assignop}  {return ASSIGNOP;}
if          {return IF;}
then        {return THEN;}
else        {return ELSE;}
while       {return WHILE;}
do          {return DO;}
{relop}     {
                string op = (string)yytext;
                if (op == "=") {
                    yylval = EQUAL;
                } else if (op == "<>") {
                    yylval = NOT_EQUAL;
                } else if (op == "<") {
                    yylval = SMALLER;
                } else if (op == "<=") {
                    yylval = SMALLER_EQUAL;
                } else if (op == ">=") {
                    yylval = GREATER_EQUAL;
                } else {
                    yylval = GREATER;
                }
                return RELOP;
            }
{sign}      {yylval = (int)yytext[0]; return SIGN;}
or          {return OR;}
{mulop}     {yylval = (int)yytext[0]; return MULOP;}
not         {return NOT;}
of          {return OF;}
{array_delim} {return ARRAY_DELIM;}
write       {
                yylval = insert_id("$write", NONE);
                return WRITE;
            }
read        {
                yylval = insert_id("$read", NONE);
                return READ;
            }
{id}        {
                int index = lookup(yytext);
                if(index == -1)
                {   
                    if (isVarDeclaration || isParamsDeclaration) {
                        pendingEntries.push_back(yytext);
                    } else {
                        index = insert_id(yytext, NONE);
                    }
                }
                yylval = index;
                return ID;
            }
{num}       {
                yylval = insert_num(yytext);
                return NUM;
            }
.           {return *yytext;}

%%

int lexan() {return yylex();}
/*
%%
{delim}		{}
{newline}	{lineno++;}
{number}	{yylval = atoi(yytext); return(NUM);}
{word}		{int p = lookup(yytext); if(p == 0) p = insert(yytext, ID); yylval = p; return(symtable[p].token);}
{symbol}	{yylval = NONE; return(yytext[0]);}

%%
*/