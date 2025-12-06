#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "scope_table.h"
#include <fstream>
using namespace std;

class symbol_table
{
private:
    scope_table* current_scope;
    int bucket_count;
    int current_scope_id;  // Starts from 1

public:
    // Constructor: creates global scope (ID = 1)
    symbol_table(int bucket_count)
    {
        this->bucket_count = bucket_count;
        this->current_scope_id = 1;
        this->current_scope = new scope_table(bucket_count, current_scope_id, nullptr);
    }

    // Destructor: delete all scopes
    ~symbol_table()
    {
        scope_table* temp;
        while (current_scope != nullptr)
        {
            temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    // === ENTER & EXIT SCOPE NOW TAKE outlog AS PARAMETER ===
    void enter_scope(ofstream& outlog)
    {
        current_scope_id++;
        scope_table* new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = new_scope;

        outlog << "New ScopeTable with ID " << current_scope_id << " created" << endl << endl;
    }

    bool exit_scope(ofstream& outlog)
    {
        if (current_scope->get_parent_scope() == nullptr)
            return false;  // cannot exit global scope

        outlog << "Scopetable with ID " << current_scope->get_unique_id() << " removed" << endl << endl;

        scope_table* temp = current_scope;
        current_scope = current_scope->get_parent_scope();
        delete temp;
        return true;
    }

    // Insert into current scope
    bool insert(symbol_info* symbol)
    {
        return current_scope->insert_in_scope(symbol);
    }

    bool insert(string name, string type)
    {
        symbol_info* sym = new symbol_info(name, type);
        return insert(sym);
    }

    // Lookup in all scopes (current → global)
    symbol_info* lookup(string name)
    {
        scope_table* temp_scope = current_scope;
        while (temp_scope != nullptr)
        {
            symbol_info* found = temp_scope->lookup_in_scope(name);
            if (found != nullptr) return found;
            temp_scope = temp_scope->get_parent_scope();
        }
        return nullptr;
    }

    symbol_info* lookup(symbol_info* symbol)
    {
        return lookup(symbol->getname());
    }

    symbol_info* lookup_current_scope(string name)
    {
        return current_scope->lookup_in_scope(name);
    }

    // Print functions
    void print_current_scope(ofstream& outlog)
    {
        current_scope->print_scope_table(outlog);
    }

    void print_all_scopes(ofstream& outlog)
    {
        outlog << "################################" << endl;

        scope_table* temp = current_scope;
        while (temp != nullptr)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }

        outlog << "################################" << endl;
    }

    // Optional helpers
    int get_current_scope_id()
    {
        return current_scope->get_unique_id();
    }

    scope_table* get_current_scope()
    {
        return current_scope;
    }
};

#endif