%option noyywrap
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

#define yylval cool_yylval
#define yylex  cool_yylex

#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin;

#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST];
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

%}

%x SINGLE_LINE_COMMENT MULTI_LINE_COMMENT

DARROW                      =>
LESS_EQUAL                  <=
ASSIGNMENT                  <-

%%

\n                          { curr_lineno++; }
[ \t]+                      {}

 /*
  *  Nested comments
  */

"--"                        { BEGIN SINGLE_LINE_COMMENT; }
"(\*"                       { BEGIN MULTI_LINE_COMMENT; }

<SINGLE_LINE_COMMENT>\n     { BEGIN 0; curr_lineno++; }
<MULTI_LINE_COMMENT>\n      { curr_lineno++; }
<MULTI_LINE_COMMENT>"\*)"   { BEGIN 0; }

<SINGLE_LINE_COMMENT>.      {}
<MULTI_LINE_COMMENT>.       {}

 /*
  * The multiple-character operators.
  */

{DARROW}                    { return (DARROW); }
{LESS_EQUAL}                { return (LESS_EQUAL); }
{ASSIGNMENT}                { retunr (ASSIGNMENT); }

 /*
  * The single-character operators.
  */

"{"                         { return '{'; }
"}"                         { return '}'; }
"("                         { return '('; }
")"                         { return ')'; }
"~"                         { return '~'; }
","                         { return ','; }
";"                         { return ';'; }
":"                         { return ':'; }
"+"                         { return '+'; }
"-"                         { return '-'; }
"*"                         { return '*'; }
"/"                         { return '/'; }
"%"                         { return '%'; }
"."                         { return '.'; }
"<"                         { return '<'; }
"="                         { return '='; }
"@"                         { return '@'; }

 /*
  * Keywords
  */

(?i:CLASS)                  { return (CLASS); }
(?i:ELSE)                   { return (ELSE); }
(?i:FI)                     { return (FI); }
(?i:IF)                     { return (IF); }
(?i:IN)                     { return (IN); }
(?i:INHERITS)               { return (INHERITS); }
(?i:LET)                    { return (LET); }
(?i:LOOP)                   { return (LOOP); }
(?i:POOL)                   { return (POOL); }
(?i:THEN)                   { return (THEN); }
(?i:WHILE)                  { return (WHILE); }
(?i:CASE)                   { return (CASE); }
(?i:ESAC)                   { return (ESAC); }
(?i:OF)                     { return (OF); }
(?i:NEW)                    { return (NEW); }
(?i:LE)                     { return (LE); }
(?i:NOT)                    { return (NOT); }
(?i:ISVOID)                 { return (ISVOID); }

t[rR][uU][eE] { 
  cool_yylval.boolean = 1;
  return (BOOL_CONST);
}
f[aA][lL][sS][eE] { 
  cool_yylval.boolean = 0;
  return (BOOL_CONST);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
