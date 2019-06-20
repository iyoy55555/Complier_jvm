/*	Definition section */
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
extern int scope_state;
extern int yylineno;
extern int yylex();
extern char type_temp[10];
char para_buf[256];
int end_scope=0;
int yyerror(char*);
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex
extern char se_error_buff[30];
extern char sy_error_buff[30];
/*check if it's time to print table or error*/
extern int CanDump;
extern int PrintSemeticError;
extern int PrintSytax;
int sy_error=0;
FILE *OutputFile;
int num_of_label=0;

struct symbol{
	int index;
	char *name; 
	char entry_type[15];
	char data_type[7];
	int scope_level;
	char *formal_parameters;
	struct symbol * next;
    struct symbol * next_index;
    int function_declaration;/*check function declare and def*/
    int function_imp;
};
/* Symbol table function - you can add new function if needed. */
struct symbol * lookup_symbol(const char *);
int create_symbol(char *,int,char *,char *,int);
void insert_symbol(int,struct symbol *);
void dump_symbol(int);
void dump_withoutprint(int);
void semantic_error(char *);

struct symbol * table[30][30];
struct symbol * index_stack[30];

%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
    char c_val;
}

/* Token without return */
%token PRINT 
%token IF ELSE FOR WHILE
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token DEC_ASSIGN RETURN
%token <string> ID

/* Token with return, which need to sepcify type */
%token <string> I_CONST
%token <string> F_CONST
%token <string> S_CONST
%token <string> INT
%token <string> FLOAT
%token <string> BOOL
%token <string> VOID
%token <string> STRING

/* Nonterminal with return, which need to sepcify type */
%type <string> type
%type <string> initializer
%type <c_val> primary_expression 
%type <c_val> postfix_expression
%type <c_val>  unary_expression
%type <c_val>  multiplicative_expression
%type <c_val> additive_expression
%type <c_val> assignment_expression
%type <c_val> assignment_operator
%type <c_val> shift_expression
%type <c_val> relational_expression
%type <c_val> equality_expression
%type <i_val> if_part
%type <i_val> if_else_part
%type <i_val> while_part
%type <c_val> function_name
/* Yacc will start at this nonterminal */
%start program


/* Grammar section */
%%

program
    : program stat
    | 
;

stat
    : declaration 
    | function_declaration
    | print_func
;

print_func
	: PRINT '(' print_element ')' {
    }
;

print_element
	: initializer{
        fprintf(OutputFile,"getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        if($1[0]>47 && $1[0]<58){
            fprintf(OutputFile,"ldc %s\n",$1);
            char * dot = strchr($1,'.');
            if (dot ==NULL){
                fprintf(OutputFile,"invokevirtual java/io/PrintStream/println(I)V\n");
            }
            if(dot != NULL)
                fprintf(OutputFile,"invokevirtual java/io/PrintStream/println(F)V\n");
        }
        else {
            fprintf(OutputFile,"ldc \"%s\"\n",$1);
            fprintf(OutputFile,"invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }
    }
	| ID {
        const struct symbol * s = lookup_symbol($1);
        if(s == NULL){
            strcat(se_error_buff,"Undeclared variable ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else{
            char t;
            /*get the variable*/
            if(scope_state>0)
                fprintf(OutputFile,"\t");

            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'S';
            if(s->scope_level == 0){
                fprintf(OutputFile,"getstatic compiler_hw3/%s %c\n",s->name,t);
            }else {
                if(t == 'S')
                    fprintf(OutputFile,"aload %d\n",s->index);
                else if(t == 'F')
                    fprintf(OutputFile,"fload %d\n",s->index);
                else
                    fprintf(OutputFile,"iload %d\n",s->index);
            }
            /*print*/
            if(scope_state>0)fprintf(OutputFile,"\t");
            fprintf(OutputFile,"getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            if(scope_state>0)fprintf(OutputFile,"\t");
            fprintf(OutputFile,"swap\n");
            if(scope_state>0)fprintf(OutputFile,"\t");
            if(t == 'S')
                fprintf(OutputFile,"invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
            else    
                fprintf(OutputFile,"invokevirtual java/io/PrintStream/println(%c)V\n",t);
        }
    }
;


declaration
    : type ID '=' initializer ';' {
        struct symbol * s =lookup_symbol($2);
        if(s!=NULL && s->scope_level == scope_state){
            strcat(se_error_buff,"Redeclared variable ");
            strcat(se_error_buff,$2);
            PrintSemeticError=1;
        }
        else{
            int index = create_symbol($2,scope_state,"variable",$1,0);
            struct symbol * s =lookup_symbol($2);
            char t;
            if(strcmp(s->data_type,"int")==0){
                t = 'I';
            }
            if(strcmp(s->data_type,"float")==0){
                t = 'F';
            }
            if(strcmp(s->data_type,"bool")==0){
                t = 'Z'; 
            }
            if(strcmp(s->data_type,"string")==0){
                t = 'S';
            }
            if(scope_state==0){

                if(t == 'Z'){
                    fprintf(OutputFile,"%s %s %c %c ",".field public static",$2,t,'=');
                    if(strcmp($4,"true")==0)
                        fprintf(OutputFile,"0\n");
                    else if(strcmp($4,"false")==0)
                        fprintf(OutputFile,"1\n");   
                }
                else if(t == 'S')
                    fprintf(OutputFile,"%s %s %s %c \"%s\"\n",".field public static",$2,"(Ljava/lang/String;)",'=',$4); 
                else
                    fprintf(OutputFile,"%s %s %c %c %s\n",".field public static",$2,t,'=',$4);   
            }
            else {

                if(t == 'Z'){
                    if(strcmp($4,"true")==0)
                        fprintf(OutputFile,"\t%s 1\n","ldc");
                    else if(strcmp($4,"false")==0)
                        fprintf(OutputFile,"\t%s 0\n","ldc");   
                }
                else if(t=='S')fprintf(OutputFile,"\t%s \"%s\"\n","ldc",$4);
                else fprintf(OutputFile,"\t%s %s\n","ldc",$4);

                char * dot = strchr($4,'.');
                if (dot ==NULL && t == 'F')
                    fprintf(OutputFile,"i2f\n");
                if(dot != NULL && t=='I')
                    fprintf(OutputFile,"f2i\n");
                if(t == 'S')
                    fprintf(OutputFile,"\tastore %d\n",index);
                else if(t == 'F')
                    fprintf(OutputFile,"\t%s %d\n","fstore", index);
                else
                    fprintf(OutputFile,"\t%s %d\n", "istore",index);

            }

        }
        }
    | type ID '=' additive_expression ';' {
        struct symbol * s =lookup_symbol($2);
        if(s!=NULL && s->scope_level == scope_state){
            strcat(se_error_buff,"Redeclared variable ");
            strcat(se_error_buff,$2);
            PrintSemeticError=1;
        }
        else{
            int index = create_symbol($2,scope_state,"variable",$1,0);
            char t;
                if(strcmp($1,"int")==0){
                    t = 'I';
                }
                if(strcmp($1,"float")==0){
                    t = 'F';
                }
                if(t == 'F' && $4 =='I')
                    fprintf(OutputFile,"\ti2f\n");
                if(t == 'I' && $4 == 'F')
                    fprintf(OutputFile,"\tf2i\n");
                if(t == 'F')
                    fprintf(OutputFile,"\t%s %d\n","fstore", index);
                else
                    fprintf(OutputFile,"\t%s %d\n", "istore",index);

        }
        }
    | type ID ';' {
        struct symbol * s =lookup_symbol($2);
        if(s!=NULL && s->scope_level == scope_state){
            strcat(se_error_buff,"Redeclared variable ");
            strcat(se_error_buff,$2);
            PrintSemeticError=1;
        }
        else{
            int index = create_symbol($2,scope_state,"variable",$1,0);
            char t;
                if(strcmp($1,"int")==0){
                    t = 'I';
                }
                if(strcmp($1,"float")==0){
                    t = 'F';
                }
                if(strcmp($1,"bool")==0){
                    t = 'Z'; 
                }
            if(scope_state==0){
                if(t == 'F')
                    fprintf(OutputFile,"%s %s %c\n",".field public static",$2,t); 
                else 
                    fprintf(OutputFile,".field public static %s\n",$2);  
            }
            else {
                fprintf(OutputFile,"\t%s %d\n","ldc",0);
                if(t == 'F')
                    fprintf(OutputFile,"\t%s %d\n","fstore", index);
                else
                    fprintf(OutputFile,"\t%s %d\n", "istore",index);

            }

        }    
        } 
;

statement
	: compound_stat
	| expression_statement
	| print_func
	| selection_statement
	| iteration_statement
	| jump_statement
;

expression_statement
	: ';'
	| expression ';'
;

if_part
    : IF '(' equality_expression ')'{
        if ($3 == '<')
            fprintf(OutputFile,"ifge Label_%d\n",num_of_label);
        if($3 == '>')
            fprintf(OutputFile,"ifle Label_%d\n",num_of_label);
        if($3 == 'L')
            fprintf(OutputFile,"ifgt Label_%d\n",num_of_label);
        if($3 == 'G')
            fprintf(OutputFile,"iflt Label_%d\n",num_of_label);
        if($3 == '=')
            fprintf(OutputFile,"ifne Label_%d\n",num_of_label);
        if($3 == '!')
            fprintf(OutputFile,"ifeq Label_%d\n",num_of_label);
        $$ = num_of_label;
        num_of_label++;
    }
;

if_else_part
    :if_part statement ELSE{
        fprintf(OutputFile,"goto Label_%d\n",num_of_label);
        fprintf(OutputFile,"Label_%d :\n",$1);
        $$ = num_of_label;
        num_of_label++;
    }
;
selection_statement
	: if_else_part statement {
        fprintf(OutputFile,"Label_%d :\n",$1);
    }
	| if_part statement{
        fprintf(OutputFile,"Label_%d :\n",$1);
    }
;

while_label
    : WHILE{         
        fprintf(OutputFile,"Label_%d :\n",num_of_label);
        num_of_label++;
    }
;

while_part
    : while_label '(' equality_expression ')' {
        if ($3 == '<')
            fprintf(OutputFile,"ifge Label_%d\n",num_of_label);
        if($3 == '>')
            fprintf(OutputFile,"ifle Label_%d\n",num_of_label);
        if($3 == 'L')
            fprintf(OutputFile,"ifgt Label_%d\n",num_of_label);
        if($3 == 'G')
            fprintf(OutputFile,"iflt Label_%d\n",num_of_label);
        if($3 == '=')
            fprintf(OutputFile,"ifne Label_%d\n",num_of_label);
        if($3 == '!')
            fprintf(OutputFile,"ifeq Label_%d\n",num_of_label);
        $$ = num_of_label;
        num_of_label++;
    }
;

iteration_statement
	: while_part statement{
        fprintf(OutputFile,"goto Label_%d\n",$1-1);
        fprintf(OutputFile,"Label_%d :\n",$1);
    }

compound_stat
	: '{' '}' {CanDump=1; scope_state--;}
	| '{' block_item_list '}' {CanDump=1;   scope_state--;}
;

jump_statement
	: RETURN ';'
	| RETURN additive_expression
;

block_item_list
	: block_item
	| block_item_list block_item
;

block_item
	: declaration
	| statement
;

primary_expression
	: ID {
        struct symbol * s =lookup_symbol($1);
        if(s == NULL){
            strcat(se_error_buff,"Undeclared variable ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else{
            char t;
            /*get the variable*/
            if(scope_state>0)
                fprintf(OutputFile,"\t");

            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'L';
            if(s->scope_level == 0){
                fprintf(OutputFile,"getstatic compiler_hw3/%s %c\n",s->name,t);
            }else {
                if(t == 'F')
                    fprintf(OutputFile,"fload %d\n",s->index);
                else
                    fprintf(OutputFile,"iload %d\n",s->index);
            }
            $$ = t;
        }
    }
	| initializer {
        fprintf(OutputFile,"ldc %s\n",$1);           
        char * dot = strchr($1,'.');
        if (dot ==NULL){
            $$ ='I';
        }
        if(dot != NULL)
            $$ ='F';
    }
    | '(' expression ')'
;

expression 
	: assignment_expression
	| expression ',' assignment_expression
;
/*******VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV  expression priority high             */
unary_expression
	: postfix_expression {$$ = $1;}
	| INC_OP unary_expression
	| DEC_OP unary_expression
    | '-' unary_expression                                                              /*負數未處理*/
;

multiplicative_expression
	: unary_expression {$$ = $1;}
	| multiplicative_expression '*' unary_expression{
        if($3 == 'F' && $1 =='I'){
            fprintf(OutputFile,"swap\n");
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if($3 == 'I' && $1 =='F'){
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if( $3 == 'F' && $1 == 'F')
            $$ = 'F';
        else if($3 == 'I' && $1 =='I')
            $$ = 'I';

        if($$ == 'F')
            fprintf(OutputFile,"fmul\n");
        else
            fprintf(OutputFile,"imul\n");
    }
	| multiplicative_expression '/' unary_expression{
        if($3 == 'F' && $1 =='I'){
            fprintf(OutputFile,"swap\n");
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if($3 == 'I' && $1 =='F'){
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if( $3 == 'F' && $1 == 'F')
            $$ = 'F';
        else if($3 == 'I' && $1 =='I')
            $$ = 'I';

        if($$ == 'F')
            fprintf(OutputFile,"fdiv\n");
        else
            fprintf(OutputFile,"idiv\n");
    }
	| multiplicative_expression '%' unary_expression{
        if($3 == 'F' && $1 =='I'){
            fprintf(OutputFile,"swap\n");
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if($3 == 'I' && $1 =='F'){
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if( $3 == 'F' && $1 == 'F')
            $$ = 'F';
        else if($3 == 'I' && $1 =='I')
            $$ = 'I';

        if($$ == 'F'){
            strcat(se_error_buff,"Arithmetic error ");
            PrintSemeticError=1;
        }
        else
            fprintf(OutputFile,"irem\n");
    }
;

additive_expression
	: multiplicative_expression {$$ = $1;}
	| additive_expression '+' multiplicative_expression {
        if($3 == 'F' && $1 =='I'){
            fprintf(OutputFile,"swap\n");
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if($3 == 'I' && $1 =='F'){
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if( $3 == 'F' && $1 == 'F')
            $$ = 'F';
        else if($3 == 'I' && $1 =='I')
            $$ = 'I';

        if($$ == 'F')
            fprintf(OutputFile,"fadd\n");
        else
            fprintf(OutputFile,"iadd\n");
    }
	| additive_expression '-' multiplicative_expression{
        if($3 == 'F' && $1 =='I'){
            fprintf(OutputFile,"swap\n");
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if($3 == 'I' && $1 =='F'){
            fprintf(OutputFile,"i2f\n");
            $$ = 'F';
        }
        else if( $3 == 'F' && $1 == 'F')
            $$ = 'F';
        else if($3 == 'I' && $1 =='I')
            $$ = 'I';

        if($$ == 'F')
            fprintf(OutputFile,"fsub\n");
        else
            fprintf(OutputFile,"isub\n");
    }
;

shift_expression
	: additive_expression {$$ = $1;}
/*	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
*/
;

relational_expression
	: shift_expression {$$ = $1;}
	| relational_expression '<' shift_expression{
        if($3 == 'F')
            fprintf(OutputFile,"fsub\nf2i\n");
        else fprintf(OutputFile,"isub\n");
        $$ = '<';
    }
	| relational_expression '>' shift_expression{
        if($3 == 'F')
            fprintf(OutputFile,"fsub\nf2i\n");
        else fprintf(OutputFile,"isub\n");
        $$ = '>';
    }
	| relational_expression LE_OP shift_expression{
        if($3 == 'F')
            fprintf(OutputFile,"fsub\nf2i\n");
        else fprintf(OutputFile,"isub\n");
        $$ = 'L';
    }
	| relational_expression GE_OP shift_expression{
        if($3 == 'F')
            fprintf(OutputFile,"fsub\nf2i\n");
        else fprintf(OutputFile,"isub\n");
        $$ = 'G';
    }
;


equality_expression
	: relational_expression {$$ =$1;}
	| equality_expression EQ_OP relational_expression{
        if($3 == 'F'){
            fprintf(OutputFile,"fsub\nf2i\n");
        }
        else fprintf(OutputFile,"isub\n");
        $$ = '=';
    }
	| equality_expression NE_OP relational_expression{
        if($3 == 'F')
            fprintf(OutputFile,"fsub\nf2i\n");
        else fprintf(OutputFile,"isub\n");
        $$ = '!';
    }
;


and_expression
	: equality_expression
	| and_expression '&' equality_expression
;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
;

logic_and_expression
	: inclusive_or_expression
	| logic_and_expression AND_OP inclusive_or_expression
;

logic_or_expression
	: logic_and_expression
	| logic_or_expression OR_OP logic_and_expression
;

condition_expression
	: logic_or_expression
;

assignment_expression
	: additive_expression {$$ = $1;}
	| ID assignment_operator assignment_expression {
        struct symbol * s =lookup_symbol($1);
        if(s == NULL){
            strcat(se_error_buff,"Undeclared variable ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else {
            char t;
            /*get the variable*/
            if(scope_state>0)
                fprintf(OutputFile,"\t");

            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'L';
            if(s->scope_level == 0){
                fprintf(OutputFile,"putstatic compiler_hw3/%s %c\n",s->name,t);
            }else {
                if(t == 'F'){
                    if($3 == 'I')
                        fprintf(OutputFile, "i2f\n");
                    if($2 != '=')
                        fprintf(OutputFile,"fload %d\nswap\n",s->index);
                    if($2 == '+')
                        fprintf(OutputFile,"fadd\n");
                    if($2 == '-')
                        fprintf(OutputFile,"fsub\n");
                    if($2 == '*')
                        fprintf(OutputFile,"fmul\n");
                    if($2 == '/')
                        fprintf(OutputFile,"fdiv\n");
                    if($2 == '%'){
                        strcat(se_error_buff,"Arithmetic error");
                        PrintSemeticError=1;
                    }                                         /*mod float error*/                                             
                    fprintf(OutputFile,"fstore %d\n",s->index);
                }
                else{
                    if($3 == 'F')
                        fprintf(OutputFile, "f2i\n");

                    if($2 != '=')
                        fprintf(OutputFile,"iload %d\nswap\n",s->index);
                    if($2 == '+')
                        fprintf(OutputFile,"iadd\n");
                    if($2 == '-')
                        fprintf(OutputFile,"isub\n");
                    if($2 == '*')
                        fprintf(OutputFile,"imul\n");
                    if($2 == '/')
                        fprintf(OutputFile,"idiv\n"); 
                    if($2 == '%')
                        fprintf(OutputFile,"irem\n");     
                    fprintf(OutputFile,"istore %d\n",s->index);
                }
            }
        }
    }
;
/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  expression priority low*/
assignment_operator
	: '=' {$$ = '=';}
	| MUL_ASSIGN {$$ = '*';}
	| DIV_ASSIGN {$$ = '/';}
	| MOD_ASSIGN {$$ = '%';}
	| ADD_ASSIGN {$$ = '+';}
	| DEC_ASSIGN {$$ = '-';}
;

argument_expression_list
	: additive_expression
	| argument_expression_list ',' additive_expression
;

postfix_expression
	: primary_expression {$$ = $1;}
	| ID INC_OP {
        struct symbol * s =lookup_symbol($1);
        if(s == NULL){
            strcat(se_error_buff,"Undeclared variable ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else{
            char t;
            /*get the variable*/
            if(scope_state>0)
                fprintf(OutputFile,"\t");

            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'L';
            if(s->scope_level == 0){
                fprintf(OutputFile,"getstatic compiler_hw3/%s %c\n",s->name,t);
            }else {
                if(t == 'F'){
                    fprintf(OutputFile,"fload %d\n",s->index);
                    fprintf(OutputFile, "ldc 1.0\n");
                    fprintf(OutputFile, "fadd\n");
                    fprintf(OutputFile,"fstore %d\n",s->index);
                }
                else{
                    fprintf(OutputFile,"iload %d\n",s->index);
                    fprintf(OutputFile, "ldc 1\n");
                    fprintf(OutputFile, "iadd\n");
                    fprintf(OutputFile,"istore %d\n",s->index);
                }
            }
            $$ = t;
        }
    }
	| ID DEC_OP{
        struct symbol * s =lookup_symbol($1);
        if(s == NULL){
            strcat(se_error_buff,"Undeclared variable ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else{
            char t;
            /*get the variable*/
            if(scope_state>0)
                fprintf(OutputFile,"\t");

            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'L';
            if(s->scope_level == 0){
                fprintf(OutputFile,"getstatic compiler_hw3/%s %c\n",s->name,t);
            }else {
                if(t == 'F'){
                    fprintf(OutputFile, "ldc 1.0\n");
                    fprintf(OutputFile,"fload %d\n",s->index);
                    fprintf(OutputFile, "fsub\n");
                    fprintf(OutputFile,"fstore %d\n",s->index);
                }
                else{
                    fprintf(OutputFile, "ldc 1\n");
                    fprintf(OutputFile,"iload %d\n",s->index);
                    fprintf(OutputFile, "isub\n");
                    fprintf(OutputFile,"istore %d\n",s->index);
                }
            }
            $$ = t;
        }
    }
	| ID '(' argument_expression_list ')' {
        struct symbol * s =lookup_symbol($1);  
        if(s == NULL){
            strcat(se_error_buff,"Undeclared function ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else{
            char t;
            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'S';
            fprintf(OutputFile,"invokestatic compiler_hw3/%s(",s->name);
            char * p =NULL;
            char * copy = malloc(strlen(s->formal_parameters)+1);
            strcpy(copy,s->formal_parameters);
            p = strtok(copy,",");
            while(p!=NULL){
                if(strcmp(p,"int")==0)
                    fprintf(OutputFile,"I");
                if(strcmp(p,"float")==0)
                    fprintf(OutputFile,"F");
                p = strtok(NULL,",");
            }
            free(copy);
            fprintf(OutputFile,")%c\n",t);
            $$ = t;
        }
    }
    | ID '(' ')' { 
        struct symbol * s =lookup_symbol($1);       
        if(s == NULL){
            strcat(se_error_buff,"Undeclared function ");
            strcat(se_error_buff,$1);
            PrintSemeticError=1;
        }else {
            char t;
            if(strcmp(s->data_type,"int") == 0)
                    t = 'I';
            if(strcmp(s->data_type,"float") == 0)
                t = 'F';
            if(strcmp(s->data_type,"bool") == 0)
                t = 'Z';
            if(strcmp(s->data_type,"string") == 0)
                t = 'S';
            else 
                t ='V';
            fprintf(OutputFile,"invokestatic compiler_hw3/%s()%c\n",s->name,t);
            $$ = t;
        }
        }
;


function_declaration
	: function_name compound_stat  {
        char t = $1;
        if (t == 'I')
            fprintf(OutputFile,"\t%s\n%s","ireturn",".end method\n");
        else if (t == 'F')
            fprintf(OutputFile,"\t%s\n%s","freturn",".end method\n");
        else
            fprintf(OutputFile,"\t%s\n%s","return",".end method\n");
        }/*insert function*/
    | function_name ';' {}
;

function_name
    : type ID parameter {
        struct symbol * s =lookup_symbol($2);  
        if(s!=NULL){
            strcat(se_error_buff,"Redeclared function ");
            strcat(se_error_buff,$2);
            PrintSemeticError=1;
        }

        if(strcmp($2,"main")==0){
            fprintf(OutputFile,"%s",".method static public main([Ljava/lang/String;)V\n.limit stack 50\n.limit locals 50\n");
        }else {
            fprintf(OutputFile, ".method static public %s(",$2);
            char * p =NULL;
            char * copy = malloc(strlen(para_buf)+1);
            strcpy(copy,para_buf);
            p = strtok(copy,",");
            while(p!=NULL){
                if(strcmp(p,"int")==0)
                    fprintf(OutputFile,"I");
                if(strcmp(p,"float")==0)
                    fprintf(OutputFile,"F");
                p = strtok(NULL,",");
            }
            free(copy);
            char t;
            if(strcmp($1,"int")==0)
                t = 'I';
            if(strcmp($1,"float")==0)
                t = 'F';
            if(strcmp($1,"void")==0)
                t = 'V';
            fprintf(OutputFile,")%c\n",t);
            fprintf(OutputFile,".limit stack 50\n");
            fprintf(OutputFile,".limit locals 50\n");
            $$ = t;            
        }

        create_symbol($2,scope_state-1,"function",$1,1);
    }
;

parameter
	: '(' ')'
	| '(' identifier_list ')' {}
;

identifier_list
	: identifier_list ',' type ID {
        if(strlen(para_buf)!=0)
            strcat(para_buf,",");
        strcat(para_buf,$3);
        create_symbol($4,scope_state+1,"parameter",$3,0);}
	| type ID {
        if(strlen(para_buf)!=0)
            strcat(para_buf,",");
        strcat(para_buf,$1);
        create_symbol($2,scope_state+1,"parameter",$1,0);}
;
parameter 
    : parameter ',' declaration
    | declaration 
;

type
    : INT { $$ =$1;}
    | FLOAT {$$ =$1;}
    | BOOL  {$$ =$1;}
    | STRING {$$ =$1;}
    | VOID {$$ =$1;}
;

initializer
	: I_CONST {$$ = $1;}
	| F_CONST {$$ = $1;}
	| S_CONST {$$ = $1;}
;
%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;
    OutputFile =fopen("compiler_hw3.j","w");
    fprintf(OutputFile,"%s",".class public compiler_hw3\n.super java/lang/Object\n");
    yyparse();
    dump_symbol(scope_state);
	//if(!sy_error)printf("\nTotal lines: %d \n",yylineno);

    return 0;
}

int yyerror(char *s)
{
    yylineno++;
    printf("%d: %s\n",yylineno,buf);
    strcat(buf,"\n");
    if(PrintSemeticError)
        semantic_error(se_error_buff);
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
    sy_error=1;
}

int create_symbol(char* name, int scope,char* kind, char* type,int function_check) {
	struct symbol* s = malloc(sizeof(struct symbol));
	
    /*insert data*/
    s->name=malloc(strlen(name)+1);
	strcpy(s->name, name);
	s->scope_level = scope;
	int hash_num = s->name[0]%30;
    strcpy(s->entry_type,kind);
    strcpy(s->data_type,type);
    if(strcmp("function",kind)==0){
        s->formal_parameters = malloc(strlen(para_buf));
        strcpy(s->formal_parameters,para_buf);
        memset(para_buf,0,strlen(para_buf));
        if(function_check==1)
            s->function_imp=1;
        else
            s->function_declaration=1; 
    }else {
        s->formal_parameters=malloc(1);
        s->formal_parameters="";
    }    
	insert_symbol(hash_num,s);


    /*insert to index stack*/
    int index=1;
    if(index_stack[scope]==NULL){
        index_stack[scope]=s;
        s->next_index=NULL;
        s->index=0;
    }
    else {
        struct symbol * temp=index_stack[scope];
        while(temp->next_index != NULL){
            temp=temp->next_index;
            index++;
        }
        temp->next_index=s;
        s->next_index=NULL;
        s->index = index;
    }
    return s->index;
}
void insert_symbol(int hash_num, struct symbol * s) {
	int scope=s->scope_level;
	if(table[scope][hash_num]==NULL){
		table[scope][hash_num]=s;
        s->next=NULL;
	}
	else{
		struct symbol * p = table[scope][hash_num];
		while(p->next!=NULL){
			p=p->next;
		}
		p->next=s;
        s->next=NULL;
	}
}
struct symbol * lookup_symbol(const char * name) {
    int hash_num = name[0]%30;
    struct symbol * s = table[scope_state][hash_num];
    int scope_level = scope_state;
    for (;scope_level>=0;scope_level--){
        s = table[scope_level][hash_num];
        while(s!=NULL){
            if(strcmp(name , s->name)==0){
                return s;
            }
            s=s->next;
        }
    }
    return NULL;/*undeclared*/
}
void dump_symbol(int scope) {
    if(index_stack[scope]==NULL)return;

	//printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
    //       "Index", "Name", "Kind", "Type", "Scope", "Attribute");
	int index=0;
	struct symbol * s;
    s=index_stack[scope];
    while(s!=NULL){
    //    printf("%-10d%-10s%-12s%-10s%-10d%s\n",
    //        index,s->name,s->entry_type,s->data_type,s->scope_level,s->formal_parameters);
        index_stack[scope]=s->next_index;
        index++;
        free(s);
        s=index_stack[scope];
    }
    //printf("\n");
    for(int i=0;i<30;++i){
        table[scope][i]=NULL;
    }
}

void dump_withoutprint(int scope){
    if(index_stack[scope]==NULL)return;
	struct symbol * s;
    s=index_stack[scope];
    while(s!=NULL){
        index_stack[scope]=s->next_index;
        free(s);
        s=index_stack[scope];
    }
    for(int i=0;i<30;++i){
        table[scope][i]=NULL;
    }
}

void semantic_error(char * error_type){
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s", yylineno, buf);
    printf("| %s",error_type);
    printf("\n|-----------------------------------------------|\n\n");
}
