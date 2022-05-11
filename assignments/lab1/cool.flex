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
char *string_buf_end;
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int comment_nesting_counter = 0;

%}

%x SINGLE_LINE_COMMENT MULTI_LINE_COMMENT STRING

DARROW                      =>
LE                          <=
ASSIGN                      <-

%%

\n                          { curr_lineno++; }
[ \t]+                      {}

 /*
  *  Nested comments
  */

"--"                        { BEGIN SINGLE_LINE_COMMENT; }
"(*"                        {
                              BEGIN MULTI_LINE_COMMENT;
                              comment_nesting_counter++;
                            }


<SINGLE_LINE_COMMENT>\n     { BEGIN 0; curr_lineno++; }
<MULTI_LINE_COMMENT>"*)"    {
                              comment_nesting_counter--;                              
                              if(comment_nesting_counter == 0) {
                                BEGIN (INITIAL);
                              }                              
                            }
<MULTI_LINE_COMMENT>"(*"    { comment_nesting_counter++; }
<MULTI_LINE_COMMENT><<EOF>> {
	                            strcpy(cool_yylval.error_msg, "EOF in comment");
                              BEGIN 0;
                              return (ERROR);
                            }

"*)" {
  strcpy(cool_yylval.error_msg, "Unmatched *)");
  return (ERROR);
}

<SINGLE_LINE_COMMENT>.      {}
<MULTI_LINE_COMMENT>.       {}

 /*
  * The multiple-character operators.
  */

{DARROW}                    { return (DARROW); }
{LE}                        { return (LE); }
{ASSIGN}                    { return (ASSIGN); }

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

\"  { 
  BEGIN(STRING);
  string_buf_ptr = string_buf;
  string_buf_end = string_buf + MAX_STR_CONST;
}

<STRING>(([^\"\n\\]*)(\\(.|\n))?)*[\\]?[\"\n]?  {
  while(*yytext) {
    if(*yytext == '\\') {
      switch(*(++yytext)) {
      case 'b':
        *string_buf_ptr++ = 8;
        break;
      case 't':
        *string_buf_ptr++ = 9;
        break;
      case 'n':
        *string_buf_ptr++ = 10;
        break;
      case 'f':
        *string_buf_ptr++ = 12;
        break;
      case '\n':
        *string_buf_ptr++ = '\n';
        curr_lineno++;
        break;
      case 0:
        BEGIN(INITIAL);
        cool_yylval.error_msg = string_buf;
        return ERROR;
      default:
        *string_buf_ptr++ = *yytext;
      }
      yytext++;
	  }
    else {
      if(*yytext == '"') {
        BEGIN(INITIAL);
        *string_buf_ptr = 0;
        cool_yylval.symbol = stringtable.add_string(string_buf);
        return STR_CONST;
      }
      if(*yytext == '\n') {
       BEGIN(INITIAL);
        curr_lineno++;
        sprintf(string_buf, "Unterminated string constant");
        cool_yylval.error_msg = string_buf;
        return ERROR;
      }
      *string_buf_ptr++ = *yytext++;
    }
    if(string_buf_ptr == string_buf_end) {
      BEGIN(INITIAL);
      sprintf(string_buf, "String constant too long");
      cool_yylval.error_msg = string_buf;
      return ERROR;
    }
  }
  BEGIN(INITIAL);
  sprintf(string_buf, "String contains null character.");
  cool_yylval.error_msg = string_buf;
  return ERROR;
}

[[:space:]]+

[0-9]+  {
  cool_yylval.symbol = inttable.add_string(yytext);
  return (INT_CONST);
}

[A-Z][A-Za-z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}

[a-z][A-Za-z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (OBJECTID);
}

.	{
	strcpy(cool_yylval.error_msg, yytext); 
	return (ERROR); 
}

%%
