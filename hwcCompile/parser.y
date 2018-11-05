/*
 *  The parser for Hardware C source code
 */


/* Prologue C-statements */
%{
	#include <math.h>
	#include <stdio.h>
	#include <ctype.h>
	#include <string.h>
	#include <assert.h>

	int yylex(void);
	void yyerror(char const *);


/* I don't have any need of this, but without it, Bison won't give me
 * access to yytoknum[].  (sigh).  -Russ
 * lol  -Jackson
 */
#define YYPRINT(fp, yychar, yylval)   do {} while(0)
%}

/* the block above is code which is *ONLY* dropped into the parser's .c
 * file.  This block is code that needs to be in *BOTH* the .c and .h
 * files.
 *
 * https://www.gnu.org/software/bison/manual/html_node/_0025code-Summary.html#g_t_0025code-Summary
 *
 * (Thanks to Stack Overflow for helping me find this page.)
 */
%code requires {
	#include "parsercommon.h"
	#include "pt/all.h"
}



/* these are the tokens which are not implicitly declared with "keyword"
 * down in the grammar below.
 */
%token<str> NUM
%token<str> IDENT

/* this generates the yytname[] table, used by tokenLookup() below */
%token-table

/* this generates the yyloc global variable (line and column information),
 * which lex fills because we have also set the %bison-locations option
 * inside our lexer.
 */
%locations



/* this declares the various types which can be stored in yylval. */
%union {
	char *str;

	PT_file      *file;
	PT_file_decl *file_decl;

	PT_part_decl *part_decl;
	PT_plugtype_decl  *plugtype_decl;

	PT_stmt *stmt;
	PT_decl *decl;

	PT_array_decl *array_decl;

	PT_type *type;

	PT_expr *expr;
}

%type<file>      file
%type<file_decl> file_decls
%type<file_decl> file_decl

%type<part_decl> part_decl
%type<stmt> opt_stmts
%type<stmt> stmts
%type<stmt> stmt

%type<plugtype_decl>  plugtype_decl

%type<stmt> opt_plugtype_stmts
%type<stmt> plugtype_stmts

%type<stmt> declStmt
%type<decl> decl_fields

%type<array_decl> opt_array_decls
%type<array_decl> array_decls

%type<type> type

%type<expr> expr
%type<expr> expr2
%type<expr> expr3
%type<expr> expr4
%type<expr> expr5
%type<expr> expr6
%type<expr> expr7


/* this solves the if-else chaining problem.  Canonical example is the
 * shift-reduce conflict that happens in this example code:
 *      if (a)
 *        if (a)
 *          stmt
 *        else
 *          stmt
 */
%right "if" "else"
/* Probably not the best fix. Discuss with Russ. */
%left  '+' '-' '*' '/' '%' '&' "&&" '|' "||" '^'

/* Grammar Rules */
%%



/* it feels terribly wrong to me to modify a global variable inside the
 * reduction code.  However, I can't find any way to access the 'file'
 * that we've created here, except in this way.  If bison provides a
 * "correct" global variable, which represents the root of the parse
 * tree, I haven't found it.
 *
 * I believe that I could fix this, more "correctly," by changing the
 * options to tell Bison to generate a reentrant parser (because then
 * yylval would be a pointer, not a global).  Maybe I'll make that
 * change later.
 *
 * UPDATE: It appears that the 'reentrant' parser only affects the
 *         parser/lexer calling convention; it doesn't affect yyparse().
 *         However, there are options which allow you to add your own,
 *         custom parameters to yyparse():
 *
 *         https://www.gnu.org/software/bison/manual/html_node/Pure-Calling.html#Pure-Calling
 *
 *       - Russ 3 Oct 2018
 */

file:
		%empty           { $$ = malloc(sizeof(PT_file));
		                   $$->decls = NULL;
		                   bisonParseRoot = $$; }

	|	file_decls       { $$ = malloc(sizeof(PT_file));
		                   $$->decls = $1;
		                   bisonParseRoot = $$; }
;

file_decls:
		           file_decl   { $$ = $1; $$->prev = NULL; }
	|	file_decls file_decl   { $$ = $2; $$->prev = $1;   }
;

file_decl:
		part_decl        { $$ = malloc(sizeof(PT_file_decl));
		                   $$->partDecl     = $1;
		                   $$->plugtypeDecl = NULL; }

	|	plugtype_decl    { $$ = malloc(sizeof(PT_file_decl));
		                   $$->partDecl     = NULL;
		                   $$->plugtypeDecl = $1; }
;



part_decl:
		"part" IDENT '{' opt_stmts '}'
		                 { $$ = malloc(sizeof(PT_part_decl));
		                   $$->name  = $2;
		                   $$->stmts = $4; }
;

opt_stmts:
		%empty  { $$ = NULL; }
	|	stmts   { $$ = $1; }
;

stmts:
		      stmt   { $$ = $1; $$->prev = NULL; }
	|	stmts stmt   { $$ = $2; $$->prev = $1;   }
;

stmt:
		'{' opt_stmts '}'          { /* we need to nest this block as a
		                              * single statement because (a) it's
		                              * currently a list, not one stmt; and
		                              * (b) because it creates a name scope.
		                              */
		                             $$ = malloc(sizeof(PT_stmt));
		                             $$->mode  = STMT_BLOCK;
		                             $$->stmts = $2; }
	|	"subpart" declStmt
		                           { $$ = $2;
		                             $$->isPublic  = 0;
		                             $$->isSubpart = 1; }
	|	"public"  declStmt
		                           { $$ = $2;
		                             $$->isPublic  = 1;
		                             $$->isSubpart = 0; }
	|	"private" declStmt
		                           { $$ = $2;
		                             $$->isPublic  = 0;
		                             $$->isSubpart = 0; }
	|	expr '=' expr ';'
		                           { $$ = malloc(sizeof(PT_stmt));
		                             $$->mode  = STMT_CONN;
		                             $$->lHand = $1;
		                             $$->rHand = $3; }
	|	"for" '(' IDENT ';' expr ".." expr ')' stmt
		                           { $$ = malloc(sizeof(PT_stmt));
		                             $$->mode     = STMT_FOR;
		                             $$->forVar   = $3;
		                             $$->forBegin = $5;
		                             $$->forEnd   = $7; 
		                             $$->forStmts = $9; }

		/* THIS IS A WEIRD HACK TO MAKE BISON WORK.
		 *
		 * Bison says that "the rule gets its precedence from the last
		 * terminal symbol" - so, by default, this has the precedence
		 * of the ')' token.  We explicitly must set the precedence
		 * here.
		 *
		 * However, that is not required in the "else" case, since it
		 * gets its precedence from "else".
		 */
	|	%prec "if"
		"if" '(' expr ')' stmt
		                       { $$ = malloc(sizeof(PT_stmt));
		                         $$->mode    = STMT_IF;
		                         $$->ifExpr  = $3;
		                         $$->ifStmts = $5;
		                         $$->ifElse  = NULL; }
	|	"if" '(' expr ')' stmt "else" stmt
		                       { $$ = malloc(sizeof(PT_stmt));
		                         $$->mode    = STMT_IF;
		                         $$->ifExpr  = $3;
		                         $$->ifStmts = $5;
		                         $$->ifElse  = $7; }

	|	"assert" '(' expr ')' ';'
		                       { $$ = malloc(sizeof(PT_stmt));
		                         $$->mode      = STMT_ASRT;
		                         $$->assertion = $3; }

	|	"unittest" opt_unittest_varlist       '{' opt_stmts '}' { printf("TODO: implement unittest statements\n"); }
	|	"unittest" opt_unittest_varlist IDENT '{' opt_stmts '}' { printf("TODO: implement unittest statements\n"); }
;

opt_unittest_varlist:
		%empty
	|	'(' unittest_varlist ')'
;

unittest_varlist:
		                     IDENT
	|	unittest_varlist ',' IDENT
;



plugtype_decl:
		"plugtype" IDENT '{' opt_plugtype_stmts '}'
		                  { $$ = malloc(sizeof(PT_plugtype_decl));
		                    $$->name  = $2;
		                    $$->stmts = $4; }
;

opt_plugtype_stmts:
		%empty          { $$ = NULL; }
	|	plugtype_stmts  { $$ = $1;   }
;

plugtype_stmts:
		               declStmt { $$ = $1;
		                          $$->isPublic  = 1;
		                          $$->isSubpart = 0; }
	|	plugtype_stmts declStmt { $$ = $2;
		                          $$->prev = $1;
		                          $$->isPublic  = 1;
		                          $$->isSubpart = 0; }
;

/* Added support for "bit a, b[1], c[4], d;" with idea from: */
/* https://stackoverflow.com/a/33066472 */
/* HOWEVER, THIS SOLUTION BREAKS THE ASSUMPTION THAT WHEN A pt_decl IS DISCLARED IN A PART AS A STATEMENT, THE prev FIELD IN pt_decl IS NULL */
/* IS THAT AN ASSUMPTION WE WANT TO MAINTAIN? */
/* Maybe not, since we could trust the Semantic phase to make sense of it */

declStmt:
		decl_fields ';'
		      { $$ = malloc(sizeof(PT_stmt));
		        $$->prev      = NULL;   /* user may override this */
		        $$->mode      = STMT_DECL;
		           /* NOTE: the user *MUST* set public and subPart */
		        $$->stmtDecl  = $1; }
;

decl_fields:
		type IDENT opt_array_decls
		                 { $$ = malloc(sizeof(PT_decl));
		                   $$->type = $1;
		                   $$->name = $2;
		                   $$->arraySuffix = $3; }
	|	decl_fields ',' IDENT opt_array_decls
		                 { $$ = malloc(sizeof(PT_decl));
		                   $$->prev = $1;
		                   $$->type = $1->type;
		                   $$->name = $3;
		                   $$->arraySuffix = $4; }
;


opt_array_decls:
		%empty            { $$ = NULL; }
	|	array_decls       { $$ = $1;   }
;

array_decls:
		            '[' expr ']'
		                  { $$ = malloc(sizeof(PT_array_decl));
		                    $$->size = $2;
		                    $$->prev = NULL; }

	|	array_decls '[' expr ']'
		                  { $$ = malloc(sizeof(PT_array_decl));
		                    $$->size = $3;
		                    $$->prev = $1; }

;



type:
		"bit"              { $$ = malloc(sizeof(PT_type));
		                     $$->mode = TYPE_BIT; }
	|	IDENT              { $$ = malloc(sizeof(PT_type));
		                     $$->mode  = TYPE_IDENT;
		                     $$->ident = $1; }
	/* I've tried to be clever here and use 'expr2' to exclude 'expr == expr' within brackets. This may have to change eventually. */
	|	type '[' expr2 ']'   { $$ = malloc(sizeof(PT_type));
		                       $$->mode = TYPE_ARRAY;
		                       $$->base = $1;
		                       $$->len  = $3; }
;


/* Note to self(Jackson): It is better to call this "expr" instead of "expr1" */
/* This is because nonterminals trying to use "expr" shouldn't care about if "expr" is one of several. */
/* ie, it's good implementation hiding. */
expr:
		expr2
	|	expr2 "==" expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_EQUALS;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 "!=" expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_NEQUAL;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '<' expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_LESS;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '>' expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_GREATER;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 "<=" expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_LESSEQ;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 ">=" expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_GREATEREQ;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }

/* Should insert an expr3 to allow for chaining of && and || and so on */
/* Is there any way to compress these down? There's a lot of redundant code */
expr2:
		expr3
	|	expr2 '&'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_BITAND;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 "&&" expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_AND;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '|'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_BITOR;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 "||" expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_OR;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '^'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_XOR;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '+'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_PLUS;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '-'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_MINUS;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '*'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_TIMES;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '/'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_DIVIDE;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
	|	expr2 '%'  expr2   { $$ = malloc(sizeof(PT_expr));
		                     $$->mode   = EXPR_TWOOP;
		                     $$->opMode = OP_MODULO;
		                     $$->lHand  = $1;
		                     $$->rHand  = $3; }
;

/* I presume !!!!!!!!!expr is something the semantic phase handles */
expr3:
		expr4
	|	'!' expr3          { $$ = malloc(sizeof(PT_expr));
		                     $$->mode    = EXPR_NOT;
		                     $$->notExpr = $2; }
	|	'~' expr3          { $$ = malloc(sizeof(PT_expr));
		                     $$->mode    = EXPR_BITNOT;
		                     $$->notExpr = $2; }
;

expr4:
		expr5
	/* I've tried to be clever here and use 'expr2' to exclude 'expr == expr' within brackets. This may have to change eventually. */
	|	expr4 '[' expr2 ']'   { $$ = malloc(sizeof(PT_expr));
		                        $$->mode      = EXPR_ARR;
		                        $$->arrayExpr = $1;
		                        $$->indexExpr = $3; }
;

expr5:
		expr6
	|	expr5 '.' expr6       /* Do we allow expr.expr.expr.expr endlessly, or only expr.expr? I think it's the later, but I made it the former just in case */
		                      /* Do we allow expr5.expr4[expr3]? This code doesn't allow for that, and shift/reduce conflicts are created when I try. */
		                      /*    Fixing the above shift/reduce conflict idea: Swap expr4 and expr5's components. */
                            { $$ = malloc(sizeof(PT_expr));
		                        $$->mode    = EXPR_DOT;
		                        $$->dotExpr = $1;
		                        $$->field   = $3; }
;

expr6:
		expr7
	|	'(' expr ')'         { $$ = malloc(sizeof(PT_expr));
		                       $$->mode  = EXPR_PAREN;
		                       $$->paren = $2; }
;

expr7:
		IDENT   { $$ = malloc(sizeof(PT_expr));
		          $$->mode  = EXPR_IDENT;
		          $$->name  = $1; }
	|	NUM     { $$ = malloc(sizeof(PT_expr));
		          $$->mode  = EXPR_NUM;
		          $$->num   = $1; }
	|	"true"  { $$ = malloc(sizeof(PT_expr));
		          $$->mode  = EXPR_BOOL;
		          $$->value = 1;  }
	|	"false" { $$ = malloc(sizeof(PT_expr));
		          $$->mode  = EXPR_BOOL;
		          $$->value = 0;  }
;



%%

void yyerror(char const *s)
{
	printf("%s at line %d col %d\n", s, yylloc.first_line, yylloc.first_column);
}



/* this looks up a possible-IDENT in a table of strings generated by Bison; if
 * we find it, then we return the correct ID for that keyword.  But if we don't
 * find it, then strdup() the string to a new string, save it into yylval, and
 * then report an IDENT.
 *
 * Note that if assertFound==1, then we won't support the IDENT case at the
 * end.
 */
int tokenLookup(char *str, int assertFound)
{
	int i;
	int len = strlen(str);

	/* YYNTOKENS is the number of defined tokens in the table.  The table
	 * of strings is the array yytname[].
	 *
	 * Since we're always looking for double-quoted strings, the string
	 * at each entry that we care about will be
	 *       "keyword"
	 * or
	 *       "<="
	 *
	 * So, we'll perform several checks in a row:
	 *    - Is the first character of the string a double-quote?
	 *    - Is the string immediately after that, continuing for the
	 *      length of our target string, an exact match?
	 *    - After that, do we have another double-quote?
	 *    - After that, do we have a null terminator?
	 *
	 * If all of these checks pass, then the string in yytname[i] matches
	 * what we're lexing, so we look up the token ID in yytoknum[i] and
	 * return that.
	 *
	 * If we fail these checks for *ALL* of the tokens in the table, then
	 * this is an actual identifier (if allowed).
	 */
	for(i=0; i<YYNTOKENS; i++)
	{
		if(yytname[i] != NULL                   &&
		   yytname[i][0] == '"'                 &&
		   strncmp(yytname[i]+1, str, len) == 0 &&
		   yytname[i][len+1] == '"'             &&
		   yytname[i][len+2] == '\0')
		{
			return yytoknum[i];
		}
	}


	/* if we get here, then we failed the search.  Was that expected to
	 * be possible?
	 */
	if (assertFound)
	{
		assert(0);   // TODO
	}

	/* otherwise, save the string in the yylval, and we can return */
	yylval.str = strdup(str);
	return IDENT;
}
