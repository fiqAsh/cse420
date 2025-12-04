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
    int current_scope_id;  // To generate unique IDs: 1, 2, 3, ...

public:
    // Constructor: creates global scope (ID = 1)
    symbol_table(int bucket_count)
    {
        this->bucket_count = bucket_count;
        this->current_scope_id = 1;
        this->current_scope = new scope_table(bucket_count, current_scope_id, nullptr);
        // Global scope has no parent
    }

    // Destructor: delete all scopes from bottom up
    ~symbol_table()
    {
        scope_table* temp;
        while (current_scope != nullptr)
        {
            temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;  // This will call scope_table destructor → frees all symbols
        }
    }

    // Create a new scope (child of current)
    void enter_scope()
    {
        current_scope_id++;
        scope_table* new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = new_scope;
    }

    // Remove current scope and go back to parent
    // Returns false if trying to exit global scope
    bool exit_scope()
    {
        if (current_scope->get_parent_scope() == nullptr)
        {
            // Cannot exit global scope
            return false;
        }

        scope_table* temp = current_scope;
        current_scope = current_scope->get_parent_scope();
        delete temp;  // Automatically deletes all symbols in this scope
        return true;
    }

    // Insert symbol into CURRENT scope only
    bool insert(symbol_info* symbol)
    {
        return current_scope->insert_in_scope(symbol);
    }

    // Overloaded: insert by name and type (convenient for parser)
    bool insert(string name, string type)
    {
        symbol_info* sym = new symbol_info(name, type, "", "", -1, {}, {});
        return insert(sym);
    }

    // Lookup symbol in current scope and all parent scopes
    symbol_info* lookup(string name)
    {
        scope_table* temp = current_scope;
        while (temp != nullptr)
        {
            symbol_info* found = temp->lookup_in_scope(name);
            if (found != nullptr)
                return found;
            temp = temp->get_parent_scope();
        }
        return nullptr; // Not found anywhere
    }

    // Overloaded: lookup using symbol_info object (by name)
    symbol_info* lookup(symbol_info* symbol)
    {
        return lookup(symbol->getname());
    }

    // Lookup only in current scope (useful for redeclaration check)
    symbol_info* lookup_current_scope(string name)
    {
        return current_scope->lookup_in_scope(name);
    }

    // Print only current scope
    void print_current_scope(ofstream& outlog)
    {
        current_scope->print_scope_table(outlog);
    }

    // Print ALL scopes from current → global
    void print_all_scopes(ofstream& outlog)
    {
        outlog << "################################" << endl << endl;

        scope_table* temp = current_scope;
        while (temp != nullptr)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }

        outlog << "################################" << endl << endl;
    }

    // Optional: get current scope ID (for debugging)
    int get_current_scope_id()
    {
        return current_scope->get_unique_id();
    }

    // Optional: get current scope pointer
    scope_table* get_current_scope()
    {
        return current_scope;
    }
};

#endif