#include <bits/stdc++.h>
using namespace std;

class symbol_info {
private:
    string name;
    string type;
    string symbol_category;
    string data_type;
    int array_size;
    string return_type;
    vector<string> param_types;

public:
    symbol_info(string name, string type) {
        this->name = name;
        this->type = type;
        this->symbol_category = "";
        this->data_type = "";
        this->array_size = -1;
        this->return_type = "";
    }

    // Getters
    string get_name() { return name; }
    string get_type() { return type; }
    string get_symbol_category() { return symbol_category; }
    string get_data_type() { return data_type; }
    int get_array_size() { return array_size; }
    string get_return_type() { return return_type; }
    vector<string>& get_param_types() { return param_types; }

    // Setters
    void set_name(string name) { this->name = name; }
    void set_type(string type) { this->type = type; }
    void set_symbol_category(string category) { this->symbol_category = category; }
    void set_data_type(string data_type) { this->data_type = data_type; }
    void set_array_size(int size) { this->array_size = size; }
    void set_return_type(string return_type) { this->return_type = return_type; }
    void set_param_types(vector<string> param_types) { this->param_types = param_types; }

    void print(ofstream& outlog) {
        outlog << "< " << name << " : " << type << " >" << endl;
        if (symbol_category == "variable") {
            outlog << "Variable" << endl;
            outlog << "Type: " << data_type << endl;
        } else if (symbol_category == "array") {
            outlog << "Array" << endl;
            outlog << "Type: " << data_type << endl;
            outlog << "Size: " << array_size << endl;
        } else if (symbol_category == "function") {
            outlog << "Function Definition" << endl;
            outlog << "Return Type: " << return_type << endl;
            outlog << "Number of Parameters: " << param_types.size() << endl;
            outlog << "Parameter Details: ";
            if (param_types.empty()) {
                outlog << endl;
            } else {
                for (size_t i = 0; i < param_types.size(); i++) {
                    outlog << param_types[i];
                    if (i < param_types.size() - 1) outlog << ", ";
                }
                outlog << endl;
            }
        }
        outlog << endl;
    }

    ~symbol_info() {}
};