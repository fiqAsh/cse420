#include "scope_table.h"
#include <fstream>
extern ofstream outlog;

class symbol_table {
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count) {
        this->bucket_count = bucket_count;
        this->current_scope_id = 1;
        this->current_scope = new scope_table(bucket_count, current_scope_id, nullptr);
    }

    ~symbol_table() {
        while (current_scope != nullptr) {
            scope_table *temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    void enter_scope() {
        current_scope_id++;
        scope_table *new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = new_scope;
    }

    void exit_scope() {
        if (current_scope != nullptr) {
            scope_table *temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    bool insert(symbol_info* symbol) {
        return current_scope->insert_in_scope(symbol);
    }

    symbol_info* lookup(symbol_info* symbol) {
        scope_table *temp = current_scope;
        while (temp != nullptr) {
            symbol_info *found = temp->lookup_in_scope(symbol);
            if (found != nullptr) {
                return found;
            }
            temp = temp->get_parent_scope();
        }
        return nullptr;
    }

    int get_current_scope_id() const {
        return current_scope_id;
    }

    void print_current_scope() {
        current_scope->print_scope_table(outlog);
    }

    void print_all_scopes(ofstream& outlog) {
        outlog << "################################" << endl << endl;
        scope_table *temp = current_scope;
        while (temp != nullptr) {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog << "################################" << endl << endl;
    }
};