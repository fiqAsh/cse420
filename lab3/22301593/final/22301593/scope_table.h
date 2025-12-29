#include "symbol_info.h"

class scope_table {
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope;
    vector<list<symbol_info *>> table;

    int hash_function(string name) {
        int sum = 0;
        for (char c : name) sum += (int)c;
        return sum % bucket_count;
    }

public:
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope) {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }

    scope_table *get_parent_scope() { return parent_scope; }
    int get_unique_id() { return unique_id; }

    symbol_info *lookup_in_scope(symbol_info* symbol) {
        int index = hash_function(symbol->get_name());
        for (auto it = table[index].begin(); it != table[index].end(); ++it) {
            if ((*it)->get_name() == symbol->get_name()) {
                return *it;
            }
        }
        return nullptr;
    }

    bool insert_in_scope(symbol_info* symbol) {
        int index = hash_function(symbol->get_name());
        if (lookup_in_scope(symbol) != nullptr) {
            return false; 
        }
        table[index].push_back(symbol);
        return true;
    }

    bool delete_from_scope(symbol_info* symbol) {
        int index = hash_function(symbol->get_name());
        for (auto it = table[index].begin(); it != table[index].end(); ++it) {
            if ((*it)->get_name() == symbol->get_name()) {
                table[index].erase(it);
                return true;
            }
        }
        return false;
    }

    void print_scope_table(ofstream& outlog) {
        outlog << "ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; i++) {
            if (!table[i].empty()) {
                outlog << i << " --> " << endl; 
                for (auto symbol : table[i]) {
                    symbol->print(outlog); 
                }
            }
        }
        outlog << endl;
    }

    ~scope_table() {
        for (int i = 0; i < bucket_count; i++) {
            for (auto symbol : table[i]) {
                delete symbol;
            }
            table[i].clear();
        }
    }
};