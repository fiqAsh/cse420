%{
#include "symbol_table.h"
#include <bits/stdc++.h>
using namespace std;

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);

int lines = 1;
ofstream outlog;

symbol_table *sym_table;

string current_var_type = "";
vector<string> param_types;
vector<string> param_names;

void yyerror(const char *s) {
    outlog << "Error at line " << lines << ": " << s << endl << endl;
}
%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog << "At line no: " << lines << " start : program " << endl << endl;
        outlog << $1->get_name() << endl << endl;

        outlog << "Final Symbol Table:" << endl << endl;
        sym_table->print_all_scopes(outlog);

        $$ = new symbol_info($1->get_name(), "start");
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
        $$ = new symbol_info($1->get_name(), "program");
    }
    ;

unit : var_declaration
     {
        outlog << "At line no: " << lines << " unit : var_declaration " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "unit");
     }
     | func_definition
     {
        outlog << "At line no: " << lines << " unit : func_definition " << endl << endl;
        outlog << $1->get_name() << endl << endl;
        $$ = new symbol_info($1->get_name(), "unit");
     }
     ;

/* ==================== FUNCTION DEFINITION WITH FULL LOGGING ==================== */

func_definition : type_specifier ID LPAREN parameter_list RPAREN
    {
        // Collect function info
        string func_name = $2->get_name();
        string ret_type = $1->get_name();

        outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;

        // Insert function symbol (in current scope — should be global or outer)
        symbol_info* func_sym = new symbol_info(func_name, "ID", "FUNCTION", ret_type, -1, param_types, param_names);
        if (sym_table->lookup_current_scope(func_name) != nullptr) {
            outlog << "Error at line " << lines << ": Multiple declaration of function " << func_name << endl << endl;
            delete func_sym;
        } else {
            sym_table->insert(func_sym);
        }

        // Enter function body scope
        sym_table->enter_scope();

        // Insert parameters
        for (size_t i = 0; i < param_names.size(); i++) {
            if (param_names[i].empty()) continue;
            symbol_info* param = new symbol_info(param_names[i], "ID", "VARIABLE", param_types[i]);
            if (!sym_table->insert(param)) {
                outlog << "Error at line " << lines << ": Redefinition of parameter " << param_names[i] << endl << endl;
                delete param;
            }
        }

        param_types.clear();
        param_names.clear();
    }
    compound_statement
    {
        string code = $1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n" + $7->get_name();
        outlog << code << endl << endl;

        sym_table->exit_scope();
        $$ = new symbol_info(code, "func_def");
    }
    | type_specifier ID LPAREN RPAREN
    {
        string func_name = $2->get_name();
        string ret_type = $1->get_name();

        outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;

        symbol_info* func_sym = new symbol_info(func_name, "ID", "FUNCTION", ret_type);
        if (sym_table->lookup_current_scope(func_name)) {
            outlog << "Error at line " << lines << ": Multiple declaration of function " << func_name << endl << endl;
            delete func_sym;
        } else {
            sym_table->insert(func_sym);
        }

        sym_table->enter_scope();
        param_types.clear();
        param_names.clear();
    }
    compound_statement
    {
        string code = $1->get_name() + " " + $2->get_name() + "()\n" + $6->get_name();
        outlog << code << endl << endl;

        sym_table->exit_scope();
        $$ = new symbol_info(code, "func_def");
    }
    ;

/* ==================== PARAMETER LIST — FULL OUTLOG PRESERVED ==================== */

parameter_list : parameter_list COMMA type_specifier ID
    {
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
        outlog << $1->get_name() << "," << $3->get_name() << " " << $4->get_name() << endl << endl;

        param_types.push_back($3->get_name());
        param_names.push_back($4->get_name());

        $$ = new symbol_info($1->get_name() + "," + $3->get_name() + " " + $4->get_name(), "param_list");
    }
    | parameter_list COMMA type_specifier
    {
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier " << endl << endl;
        outlog << $1->get_name() << "," << $3->get_name() << endl << endl;

        param_types.push_back($3->get_name());
        param_names.push_back("");

        $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "param_list");
    }
    | type_specifier ID
    {
        outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
        outlog << $1->get_name() << " " << $2->get_name() << endl << endl;

        param_types.push_back($1->get_name());
        param_names.push_back($2->get_name());

        $$ = new symbol_info($1->get_name() + " " + $2->get_name(), "param_list");
    }
    | type_specifier
    {
        outlog << "At line no: " << lines << " parameter_list : type_specifier " << endl << endl;
        outlog << $1->get_name() << endl << endl;

        param_types.push_back($1->get_name());
        param_names.push_back("");

        $$ = new symbol_info($1->get_name(), "param_list");
    }
    ;

/* ==================== REST OF THE RULES (with your original outlog style) ==================== */

compound_statement : LCURL
    {
        sym_table->enter_scope();
    }
    statements RCURL
    {
        outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
        outlog << "{\n" << $3->get_name() << "\n}" << endl << endl;
        $$ = new symbol_info("{\n" + $3->get_name() + "\n}", "comp_stmnt");

        sym_table->print_current_scope(outlog);
        sym_table->exit_scope();
    }
    | LCURL RCURL
    {
        sym_table->enter_scope();
        outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
        outlog << "{\n}" << endl << endl;
        $$ = new symbol_info("{\n}", "comp_stmnt");

        sym_table->print_current_scope(outlog);
        sym_table->exit_scope();
    }
    ;

/* You can keep the rest exactly as you had — var_declaration, statements, expressions, etc. */
/* Just add symbol table insertions where needed (like in var_declaration, variable use, etc.) */

var_declaration : type_specifier declaration_list SEMICOLON
    {
        current_var_type = $1->get_name();
        outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
        outlog << current_var_type << " " << $2->get_name() << ";" << endl << endl;

        // Parse declaration_list and insert variables/arrays
        string decl = $2->get_name();
        stringstream ss(decl);
        string token;
        while (getline(ss, token, ',')) {
            string name;
            int size = -1;
            size_t pos = token.find('[');
            if (pos != string::npos) {
                name = token.substr(0, pos);
                string sz = token.substr(pos+1, token.find(']')-pos-1);
                size = sz.empty() ? 0 : stoi(sz);
            } else {
                name = token;
            }
            name.erase(0, name.find_first_not_of(" \t"));
            name.erase(name.find_last_not_of(" \t")+1);

            if (sym_table->lookup_current_scope(name)) {
                outlog << "Error at line " << lines << ": Multiple declaration of " << name << endl << endl;
            } else {
                symbol_info* sym = (size == -1) ?
                    new symbol_info(name, "ID", "VARIABLE", current_var_type) :
                    new symbol_info(name, "ID", "ARRAY", current_var_type, size);
                sym_table->insert(sym);
            }
        }

        $$ = new symbol_info(current_var_type + " " + $2->get_name() + ";", "var_dec");
    }
    ;

/* Keep all your other rules (declaration_list, statements, etc.) with full outlog as you like */

%%

int main(int argc, char *argv[])
{
    if(argc != 2) {
        cout << "Please provide input file" << endl;
        return 0;
    }

    yyin = fopen(argv[1], "r");
    outlog.open("log.txt", ios::trunc);

    if(!yyin) {
        cout << "File not found" << endl;
        return 0;
    }

    sym_table = new symbol_table(13);

    yyparse();

    outlog << "Total lines: " << lines << endl;
    outlog.close();
    fclose(yyin);

    delete sym_table;
    return 0;
}