%option noyywrap
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

%x SINGLE_LINE_COMMENT MULTI_LINE_COMMENT

/*
 * Define names for regular expressions here.
 */


DARROW          =>

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
  *  The multiple-character operators.
  */
{DARROW}                    { return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
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