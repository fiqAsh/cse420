#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include "symbol_info.h"
#include <vector>
#include <list>
#include <string>
#include <sstream>
#include <fstream>
using namespace std;

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope;
    vector<list<symbol_info*>> table;

    // Hash function: sum of ASCII values of characters in name, then mod bucket_count
    int hash_function(string name)
    {
        unsigned int hash = 0;
        for (char c : name)
            hash = hash * 31 + c;  // Good distribution
        return hash % bucket_count;
    }

public:
    // Default constructor (not usually used)
    scope_table() : bucket_count(0), unique_id(0), parent_scope(nullptr) {}

    // Parameterized constructor
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope = nullptr)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);  // Create bucket_count empty lists
    }

    scope_table* get_parent_scope()
    {
        return parent_scope;
    }

    int get_unique_id()
    {
        return unique_id;
    }

    // Lookup a symbol in CURRENT scope only
    symbol_info* lookup_in_scope(string name)
    {
        int index = hash_function(name);
        for (auto it = table[index].begin(); it != table[index].end(); ++it)
        {
            if ((*it)->getname() == name)
            {
                return *it;
            }
        }
        return nullptr; // Not found
    }

    // Insert symbol (only if not already present in this scope)
    bool insert_in_scope(symbol_info* symbol)
    {
        string name = symbol->getname();
        int index = hash_function(name);

        // Check if already exists in this bucket
        for (auto it = table[index].begin(); it != table[index].end(); ++it)
        {
            if ((*it)->getname() == name)
            {
                return false; // Already exists → insertion failed
            }
        }

        // Insert at the beginning (or end, doesn't matter)
        table[index].push_front(symbol);
        return true; // Successfully inserted
    }

    // Overloaded version: take name and type directly (sometimes useful)
    bool insert_in_scope(string name, string type)
    {
        symbol_info* temp = new symbol_info(name, type);
        return insert_in_scope(temp);
    }

    // Delete a symbol by name from current scope
    bool delete_from_scope(string name)
    {
        int index = hash_function(name);
        auto& bucket = table[index];

        for (auto it = bucket.begin(); it != bucket.end(); ++it)
        {
            if ((*it)->getname() == name)
            {
                delete *it;        // Free the symbol_info object
                bucket.erase(it);  // Remove from list
                return true;
            }
        }
        return false; // Not found
    }

    // Print current scope table to logfile
    void print_scope_table(ofstream& outlog)
    {
        outlog << "ScopeTable # " << unique_id << endl;

        for (int i = 0; i < bucket_count; i++)
        {
            if (table[i].empty()) continue;

            outlog << i << " --> ";
            for (auto symbol : table[i])
            {
                outlog << "< " << symbol->getname() << " : " << symbol->get_type() << " > ";

                if (symbol->get_ID_type() == "FUNCTION")
                {
                    outlog << endl << "Function Definition" << endl;
                    outlog << "Return Type: " << symbol->get_var_type() << endl;
                    outlog << "Number of Parameters: " << symbol->get_param_type().size() << endl;
                    outlog << "Parameter Details: ";
                    for (size_t j = 0; j < symbol->get_param_name().size(); j++)
                    {
                        if (!symbol->get_param_name()[j].empty())
                            outlog << symbol->get_param_type()[j] << " " << symbol->get_param_name()[j];
                        else
                            outlog << symbol->get_param_type()[j];

                        if (j < symbol->get_param_name().size()-1) outlog << ", ";
                    }
                    outlog << endl;
                }
                else if (symbol->get_ID_type() == "ARRAY")
                {
                    outlog << endl << "Array" << endl;
                    outlog << "Type: " << symbol->get_var_type() << endl;
                    outlog << "Size: " << symbol->get_arr_size() << endl;
                }
                else // VARIABLE
                {
                    outlog << endl << "Variable" << endl;
                    outlog << "Type: " << symbol->get_var_type() << endl;
                }
            }
            outlog << endl;
        }
        outlog << endl;
    }

    // Destructor: delete all symbol_info objects in this scope
    ~scope_table()
    {
        for (int i = 0; i < bucket_count; i++)
        {
            for (auto symbol : table[i])
            {
                delete symbol;
            }
            table[i].clear();
        }
        table.clear();
    }
};

#endif