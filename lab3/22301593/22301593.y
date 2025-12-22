%{
#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

int lines = 1;
int error_count = 0;
ofstream outlog, outerr;

symbol_table *sym_table; 
vector<pair<string, string>> current_params; 
bool entering_function_scope = false; 
string current_type; 
string current_func_name;

void yyerror(char *s) {
    outlog << "At line " << lines << " " << s << endl << endl;
    outerr << "At line " << lines << " " << s << endl << endl;
}
%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog << "At line no: " << lines << " start : program " << endl << endl;
        outlog << "Symbol Table" << endl << endl;
        sym_table->print_all_scopes(outlog);
    }
    ;

program : program unit
    {
        outlog << "At line no: " << lines << " program : program unit " << endl << endl;
        outlog << $1->get_name() << "\n" << $2->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + "\n" + $2->get_name(), "program");
    }
    | unit
    {
        outlog << "At line no: " << lines << " program : unit " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = $1;
    }
    ;

unit : var_declaration
    {
        outlog << "At line no: " << lines << " unit : var_declaration " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = $1;
    }
    | func_definition
    {
        outlog << "At line no: " << lines << " unit : func_definition " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = $1;
    }
    ;

func_name : ID 
    { 
        $$ = $1;
        current_func_name = $1->get_name(); 
        outlog << "DEBUG: Set current_func_name to " << current_func_name << " at line " << lines << endl; 
    }
;

func_definition : type_specifier func_name LPAREN parameter_list RPAREN 
    {
        symbol_info *func = new symbol_info($2->get_name(), "ID");
        func->set_symbol_category("function");
        func->set_return_type($1->get_name());
        func->set_param_types(vector<string>(current_params.size()));
        for (size_t i = 0; i < current_params.size(); i++) {
            func->get_param_types()[i] = current_params[i].first + " " + current_params[i].second;
        }
        if (sym_table->lookup(func) != nullptr) {
            outerr << "At line no: " << lines << " Multiple declaration of function " << $2->get_name() << endl << endl;
            error_count++;
        } else {
            sym_table->insert(func);
        }
        entering_function_scope = true;
    } 
compound_statement
    {
        outlog << "At line no: " << lines << " func_definition : type_specifier func_name LPAREN parameter_list RPAREN compound_statement " << endl << endl;
        outlog << $1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n" + $7->get_name() << endl << endl;
        current_params.clear();
        entering_function_scope = false;
        current_func_name = "";
        outlog << "DEBUG: Cleared current_func_name at line " << lines << endl;
        $$ = new symbol_info($1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n" + $7->get_name(), "func_def");
    }
| type_specifier func_name LPAREN RPAREN 
    {
        symbol_info *func = new symbol_info($2->get_name(), "ID");
        func->set_symbol_category("function");
        func->set_return_type($1->get_name());
        if (sym_table->lookup(func) != nullptr) {
            outerr << "At line no: " << lines << " Multiple declaration of function " << $2->get_name() << endl << endl;
            error_count++;
        } else {
            sym_table->insert(func);
        }
        entering_function_scope = true;
    } 
compound_statement
    {
        outlog << "At line no: " << lines << " func_definition : type_specifier func_name LPAREN RPAREN compound_statement " << endl << endl;
        outlog << $1->get_name() + " " + $2->get_name() + "()\n" + $6->get_name() << endl << endl;
        entering_function_scope = false;
        current_func_name = "";
        outlog << "DEBUG: Cleared current_func_name at line " << lines << endl;
        $$ = new symbol_info($1->get_name() + " " + $2->get_name() + "()\n" + $6->get_name(), "func_def");
    }
;

parameter_list : parameter_list COMMA type_specifier ID
    {
        outlog << "DEBUG: Checking parameter " << $4->get_name() << " for function " << current_func_name << " at line " << lines << endl;
        for (auto param : current_params) {
            if (param.second == $4->get_name()) {
                outerr << "At line no: " << lines << " Multiple declaration of variable " << $4->get_name() << " in parameter of " << current_func_name << endl << endl;
                
                error_count++;
                break;
            }
        }
        current_params.push_back({$3->get_name(), $4->get_name()});
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
        outlog << $1->get_name() + "," + $3->get_name() + " " + $4->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + "," + $3->get_name() + " " + $4->get_name(), "param_list");
    }
    | type_specifier ID
    {
        outlog << "DEBUG: First parameter " << $2->get_name() << " for function " << current_func_name << " at line " << lines << endl;
        current_params.clear();
        current_params.push_back({$1->get_name(), $2->get_name()});
        outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
        outlog << $1->get_name() + " " + $2->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + " " + $2->get_name(), "param_list");
    }
    ;

scope_marker : /* empty */
    {
        sym_table->enter_scope();
        outlog << "New ScopeTable with ID " << sym_table->get_current_scope_id() << " created" << endl << endl;
        if (entering_function_scope) {
            for (auto param : current_params) { 
                if (!param.second.empty()) {
                    symbol_info *param_symbol = new symbol_info(param.second, "ID");
                    param_symbol->set_symbol_category("variable");
                    param_symbol->set_data_type(param.first);
                    sym_table->insert(param_symbol);
                }
            }
        }
    }
    ;

compound_statement : LCURL scope_marker statements RCURL
    {
        outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
        outlog << "{\n" + $3->get_name() + "\n}" << endl << endl;
        $$ = new symbol_info("{\n" + $3->get_name() + "\n}", "comp_stmnt");
        sym_table->print_all_scopes(outlog);
        outlog << "Scopetable with ID " << sym_table->get_current_scope_id() << " removed" << endl << endl;
        sym_table->exit_scope();
    }
    | LCURL scope_marker RCURL
    {
        outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
        outlog << "{\n}" << endl << endl;
        $$ = new symbol_info("{\n}", "comp_stmnt");
        sym_table->print_all_scopes(outlog);
        outlog << "Scopetable with ID " << sym_table->get_current_scope_id() << " removed" << endl << endl;
        sym_table->exit_scope();
    }
    ;

var_declaration : type_specifier declaration_list SEMICOLON
    {
        outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
        outlog << $1->get_name() + " " + $2->get_name() + ";" << endl << endl;
        $$ = new symbol_info($1->get_name() + " " + $2->get_name() + ";", "var_dec");
        if ($1->get_name() == "void") {
            outerr << "At line no: " << lines << " variable type can not be void " << endl << endl;
            error_count++;
        }
    }
    ;

type_specifier : INT
    {
        current_type = "int";
        outlog << "At line no: " << lines << " type_specifier : INT " << endl << endl;
        outlog << "int" << endl << endl;
        $$ = new symbol_info("int", "type");
    }
    | FLOAT
    {
        current_type = "float";
        outlog << "At line no: " << lines << " type_specifier : FLOAT " << endl << endl;
        outlog << "float" << endl << endl;
        $$ = new symbol_info("float", "type");
    }
    | VOID
    {
        current_type = "void";
        outlog << "At line no: " << lines << " type_specifier : VOID " << endl << endl;
        outlog << "void" << endl << endl;
        $$ = new symbol_info("void", "type");
    }
    ;

declaration_list : declaration_list COMMA ID
    {
        symbol_info *var = new symbol_info($3->get_name(), "ID");
        var->set_symbol_category("variable");
        var->set_data_type(current_type);
        if (!sym_table->insert(var)) {
            outerr << "At line no: " << lines << " Multiple declaration of variable " << $3->get_name() << endl << endl;
            error_count++;
        }
        
        outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
        outlog << $1->get_name() + "," + $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "decl_list");
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        symbol_info *arr = new symbol_info($3->get_name(), "ID");
        arr->set_symbol_category("array");
        arr->set_data_type(current_type);
        arr->set_array_size(stoi($5->get_name()));
        if (!sym_table->insert(arr)) {
            outerr << "At line no: " << lines << " Multiple declaration of variable " << $3->get_name() << endl << endl;
            error_count++;
        }
        
        outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        outlog << $1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]" << endl << endl;
        $$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "decl_list");
    }
    | ID
    {
        symbol_info *var = new symbol_info($1->get_name(), "ID");
        var->set_symbol_category("variable");
        var->set_data_type(current_type);
        if (!sym_table->insert(var)) {
            outerr << "At line no: " << lines << " Multiple declaration of variable " << $1->get_name() << endl << endl;
            error_count++;
        }
        outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "decl_list");
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        symbol_info *arr = new symbol_info($1->get_name(), "ID");
        arr->set_symbol_category("array");
        arr->set_data_type(current_type);
        arr->set_array_size(stoi($3->get_name()));
        if (!sym_table->insert(arr)) {
            outerr << "At line no: " << lines << " Multiple declaration of variable " << $1->get_name() << endl << endl;
            error_count++;
        }
        
        outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        outlog << $1->get_name() + "[" + $3->get_name() + "]" << endl << endl;
        $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "decl_list");
    }
    ;

statements : statement
    {
        outlog << "At line no: " << lines << " statements : statement " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "stmnts");
    }
    | statements statement
    {
        outlog << "At line no: " << lines << " statements : statements statement " << endl << endl;
        outlog << $1->get_name() << "\n" << $2->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + "\n" + $2->get_name(), "stmnts");
    }
    ;

statement : var_declaration
    {
        outlog << "At line no: " << lines << " statement : var_declaration " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "stmnt");
    }
    | func_definition
    {
        outlog << "At line no: " << lines << " statement : func_definition " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "stmnt");
    }
    | expression_statement
    {
        outlog << "At line no: " << lines << " statement : expression_statement " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "stmnt");
    }
    | compound_statement
    {
        outlog << "At line no: " << lines << " statement : compound_statement " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "stmnt");
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement " << endl << endl;
        outlog << "for(" + $3->get_name() + $4->get_name() + $5->get_name() + ")\n" + $7->get_name() << endl << endl;
        $$ = new symbol_info("for(" + $3->get_name() + $4->get_name() + $5->get_name() + ")\n" + $7->get_name(), "stmnt");
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    {
        outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement " << endl << endl;
        outlog << "if(" + $3->get_name() + ")\n" + $5->get_name() << endl << endl;
        $$ = new symbol_info("if(" + $3->get_name() + ")\n" + $5->get_name(), "stmnt");
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement " << endl << endl;
        outlog << "if(" + $3->get_name() + ")\n" + $5->get_name() + "\nelse\n" + $7->get_name() << endl << endl;
        $$ = new symbol_info("if(" + $3->get_name() + ")\n" + $5->get_name() + "\nelse\n" + $7->get_name(), "stmnt");
    }
    | WHILE LPAREN expression RPAREN statement
    {
        outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement " << endl << endl;
        outlog << "while(" + $3->get_name() + ")\n" + $5->get_name() << endl << endl;
        $$ = new symbol_info("while(" + $3->get_name() + ")\n" + $5->get_name(), "stmnt");
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        symbol_info* var = sym_table->lookup($3);
        if (var == nullptr) {
            outerr << "At line no: " << lines << " Undeclared variable " << $3->get_name() << endl << endl;
            error_count++;
        }
        
        outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON " << endl << endl;
        outlog << "printf(" + $3->get_name() + ");" << endl << endl;
        $$ = new symbol_info("printf(" + $3->get_name() + ");", "stmnt");
    }
    | RETURN expression SEMICOLON
    {
        outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON " << endl << endl;
        outlog << "return " + $2->get_name() + ";" << endl << endl;
        $$ = new symbol_info("return " + $2->get_name() + ";", "stmnt");
    }
    ;

expression_statement : SEMICOLON
    {
        outlog << "At line no: " << lines << " expression_statement : SEMICOLON " << endl << endl;
        outlog << ";" << endl << endl;
        $$ = new symbol_info(";", "expr_stmt");
    }
    | expression SEMICOLON
    {
        outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON " << endl << endl;
        outlog << $1->get_name() + ";" << endl << endl;
        $$ = new symbol_info($1->get_name() + ";", "expr_stmt");
    }
    ;

variable : ID
    {
        symbol_info* var = sym_table->lookup($1);
        if (var == nullptr) {
            outerr << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
            error_count++;
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type("undeclared");
        } else if (var->get_symbol_category() == "function") {
            outerr << "At line no: " << lines << " Function used as variable: " << $1->get_name() << endl << endl;
            error_count++;
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type("function");
        } else if (var->get_symbol_category() == "array") {
            outerr << "At line no: " << lines << " variable is of array type : " << $1->get_name() << endl << endl;
            error_count++;
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type("array");
        } else {
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type(var->get_data_type());
        }
        
        outlog << "At line no: " << lines << " variable : ID " << endl << endl;
        outlog << $1->get_name() << endl << endl;
    }
    | ID LTHIRD expression RTHIRD
    {
        symbol_info* var = sym_table->lookup($1);
        if (var == nullptr) {
            outerr << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
            error_count++;
            $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
            $$->set_data_type("undeclared");
        } else if (var->get_symbol_category() != "array") {
            outerr << "At line no: " << lines << " variable is not of array type : " << $1->get_name() << endl << endl;
            error_count++;
            $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
            $$->set_data_type(var->get_data_type());
        } else if ($3->get_data_type() != "int") {
            outerr << "At line no: " << lines << " array index is not of integer type : " << $1->get_name() << endl << endl;
            error_count++;
            $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
            $$->set_data_type(var->get_data_type());
        } else {
            $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
            $$->set_data_type(var->get_data_type());
        }
       
        outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
        outlog << $1->get_name() + "[" + $3->get_name() + "]" << endl << endl;
    }
    ;

expression : logic_expression
    {
        outlog << "At line no: " << lines << " expression : logic_expression " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "expr");
        $$->set_data_type($1->get_data_type());
    }
    | variable ASSIGNOP logic_expression
    {
        outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression " << endl << endl;
        outlog << $1->get_name() + "=" + $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + "=" + $3->get_name(), "expr");
        if ($1->get_symbol_category() == "array") {
            outerr << "At line no: " << lines << " variable is of array type : " << $1->get_name() << endl << endl;
            error_count++;
        } else if ($3->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl << endl;
            error_count++;
        } else if ($1->get_data_type() == "int" && $3->get_data_type() == "float") {
            outerr << "At line no: " << lines << " Warning: Assignment of float value into variable of integer type " << endl << endl;
            error_count++;
        } 
        
        $$->set_data_type($1->get_data_type());
    }
    ;

logic_expression : rel_expression
    {
        outlog << "At line no: " << lines << " logic_expression : rel_expression " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "lgc_expr");
        $$->set_data_type($1->get_data_type());
    }
    | rel_expression LOGICOP rel_expression
    {
        outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
        outlog << $1->get_name() + $2->get_name() + $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "lgc_expr");
        if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl << endl;
            error_count++;
        }
        $$->set_data_type("int");
    }
    ;

rel_expression : simple_expression
    {
        outlog << "At line no: " << lines << " rel_expression : simple_expression " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "rel_expr");
        $$->set_data_type($1->get_data_type());
    }
    | simple_expression RELOP simple_expression
    {
        outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
        outlog << $1->get_name() + $2->get_name() + $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "rel_expr");
        if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl << endl;
            error_count++;
        }
        $$->set_data_type("int");
    }
    ;

simple_expression : term
    {
        outlog << "At line no: " << lines << " simple_expression : term " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "simp_expr");
        $$->set_data_type($1->get_data_type());
    }
    | simple_expression ADDOP term
    {
        outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term " << endl << endl;
        outlog << $1->get_name() + $2->get_name() + $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "simp_expr");
        if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl << endl;
            error_count++;
        } else if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
            $$->set_data_type("float");
        } else {
            $$->set_data_type("int");
        }
    }
    ;

term : unary_expression
    {
        outlog << "At line no: " << lines << " term : unary_expression " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "term");
        $$->set_data_type($1->get_data_type());
    }
    | term MULOP unary_expression
    {
        outlog << "At line no: " << lines << " term : term MULOP unary_expression " << endl << endl;
        outlog << $1->get_name() + $2->get_name() + $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
        if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl << endl;
            error_count++;
        } else if ($2->get_name() == "%") {
            if ($1->get_data_type() != "int" || $3->get_data_type() != "int") {
                outerr << "At line no: " << lines << " Modulus operator on non integer type " << endl << endl;
                error_count++;
            }
            if ($3->get_name() == "0" && $3->get_data_type() == "int") {
                outerr << "At line no: " << lines << " Modulus by 0 " << endl << endl;
                error_count++;
            }
            $$->set_data_type("int");
        } else {
            if ($1->get_data_type() == "float" || $3->get_data_type() == "float")
                $$->set_data_type("float");
            else
                $$->set_data_type("int");
        }
    }
    ;

unary_expression : ADDOP unary_expression
    {
        outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression " << endl << endl;
        outlog << $1->get_name() + $2->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + $2->get_name(), "un_expr");
        if ($2->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl << endl;
            error_count++;
        }
        $$->set_data_type($2->get_data_type());
    }
    | NOT unary_expression
    {
        outlog << "At line no: " << lines << " unary_expression : NOT unary_expression " << endl << endl;
        outlog << "!" + $2->get_name() << endl << endl;
        $$ = new symbol_info("!" + $2->get_name(), "un_expr");
        if ($2->get_data_type() == "void") {
            outerr << "At line no: " << lines << " operation on void type " << endl;
            error_count++;
        }
        $$->set_data_type("int");
    }
    | factor
    {
        outlog << "At line no: " << lines << " unary_expression : factor " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "un_expr");
        $$->set_data_type($1->get_data_type());
    }
    ;

factor : variable
    {
        outlog << "At line no: " << lines << " factor : variable " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "fctr");
        $$->set_data_type($1->get_data_type());
    }
    | ID LPAREN argument_list RPAREN
    {
        outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
        outlog << $1->get_name() + "(" + $3->get_name() + ")" << endl << endl;
        $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
        symbol_info* func = sym_table->lookup($1);
        
        if (func == nullptr) {
            outerr << "At line no: " << lines << " Undeclared function: " << $1->get_name() << endl << endl;
            error_count++;
            $$->set_data_type("undeclared");
        } else if (func->get_symbol_category() != "function") {
            outerr << "At line no: " << lines << " Not a function: " << $1->get_name() << endl << endl;
            error_count++;
            $$->set_data_type("not_function");
        } else {
            vector<string> params = func->get_param_types();
            vector<string> arg_types;
            string arg_type_str = $3->get_data_type();
            size_t pos = 0;
            string token;
            while ((pos = arg_type_str.find(",")) != string::npos) {
                token = arg_type_str.substr(0, pos);
                arg_types.push_back(token);
                arg_type_str.erase(0, pos + 1);
            }
            if (!arg_type_str.empty()) {
                arg_types.push_back(arg_type_str);
            }
            vector<string> arg_names;
            string arg_list = $3->get_name();
            pos = 0;
            while ((pos = arg_list.find(",")) != string::npos) {
                token = arg_list.substr(0, pos);
                arg_names.push_back(token);
                arg_list.erase(0, pos + 1);
            }
            if (!arg_list.empty()) {
                arg_names.push_back(arg_list);
            }
            bool suppressArgMismatch = false;
            if (params.size() != arg_types.size())
                suppressArgMismatch = true;
            if (func->get_return_type() == "void")
                suppressArgMismatch = true;
            for (auto &t : arg_types)
                if (t == "array" || t == "undeclared")
                    suppressArgMismatch = true;
            if (params.size() != arg_types.size()) {
                outerr << "At line no: " << lines << " Inconsistencies in number of arguments in function call: " << $1->get_name() << endl << endl;
                error_count++;
            } else {
                for (size_t i = 0; i < params.size(); i++) {
                    bool is_array = false;
                    if (i < arg_names.size()) {
                        symbol_info *arg = sym_table->lookup(new symbol_info(arg_names[i], "ID"));
                        is_array = arg && arg->get_symbol_category() == "array";
                    }
                    string param_type = params[i].substr(0, params[i].find(" "));
                    if (!suppressArgMismatch && !is_array && param_type != arg_types[i]) {
                        outerr << "At line no: " << lines << " argument " << i+1 << " type mismatch in function call: " << $1->get_name() << endl << endl;
                        error_count++;
                    }
                }
            }
            $$->set_data_type(func->get_return_type());
        }
    }
    | LPAREN expression RPAREN
    {
        outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
        outlog << "(" + $2->get_name() + ")" << endl << endl;
        $$ = new symbol_info("(" + $2->get_name() + ")", "fctr");
        $$->set_data_type($2->get_data_type());
    }
    | CONST_INT
    {
        outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "fctr");
        $$->set_data_type("int");
    }
    | CONST_FLOAT
    {
        outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "fctr");
        $$->set_data_type("float");
    }
    | variable INCOP
    {
        outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
        outlog << $1->get_name() + "++" << endl << endl;
        $$ = new symbol_info($1->get_name() + "++", "fctr");
        $$->set_data_type($1->get_data_type());
    }
    | variable DECOP
    {
        outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
        outlog << $1->get_name() + "--" << endl << endl;
        $$ = new symbol_info($1->get_name() + "--", "fctr");
        $$->set_data_type($1->get_data_type());
    }
    ;

argument_list : arguments
    {
        outlog << "At line no: " << lines << " argument_list : arguments " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = $1;
    }
    | 
    {
        outlog << "At line no: " << lines << " argument_list : /* empty */ " << endl << endl;
        outlog << "" << endl << endl;
        $$ = new symbol_info("", "arg_list");
        $$->set_data_type("");
    }
    ;

arguments : arguments COMMA logic_expression
    {
        outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression " << endl << endl;
        outlog << $1->get_name() << "," << $3->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "arg");
        string new_type = $1->get_data_type();
        if (!new_type.empty()) new_type += ",";
        new_type += $3->get_data_type();
        $$->set_data_type(new_type);
    }
    | logic_expression
    {
        outlog << "At line no: " << lines << " arguments : logic_expression " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "arg");
        $$->set_data_type($1->get_data_type());
    }
    ;

%%

int main(int argc, char *argv[])
{
    if (argc != 2) {
        cout << "Please input file name" << endl;
        return 0;
    }

    yyin = fopen(argv[1], "r");

    outlog.open("22301593_log.txt", ios::trunc);
    outerr.open("22301593_error.txt", ios::trunc);

    if (yyin == NULL) {
        cout << "Couldn't open file" << endl;
        return 0;
    }

    sym_table = new symbol_table(10);
    outlog << "New ScopeTable with ID 1 created" << endl << endl;

    yyparse();

    outlog << endl << "Total lines: " << lines << endl;
    outlog << "Total errors: " << error_count << endl;
    outerr << "Total errors: " << error_count << endl;

    outlog.close();
    outerr.close();
    fclose(yyin);
    delete sym_table;

    return 0;
}
