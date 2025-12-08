#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    string ID_type;        // "VARIABLE", "ARRAY", "FUNCTION"
    string var_type;       // "int", "float", "void", etc.
    int arr_size;          // size if array, -1 otherwise
    vector<string> param_type;
    vector<string> param_name;

public:
    // Default constructor
    symbol_info() : arr_size(-1) {}

    // Constructor for simple variables (most common)
    symbol_info(string name, string type)
        : name(name), type(type), ID_type("VARIABLE"), var_type("int"), arr_size(-1)
    {}

    // Full constructor (for functions, arrays, etc.)
    symbol_info(string name, string type, string ID_type, string var_type,
                int arr_size = -1,
                const vector<string>& param_type = {},
                const vector<string>& param_name = {})
        : name(name), type(type), ID_type(ID_type), var_type(var_type),
          arr_size(arr_size), param_type(param_type), param_name(param_name)
    {}

    // Getters
    string getname() const        { return name; }
    string get_type() const        { return type; }
    string get_ID_type() const     { return ID_type; }
    string get_var_type() const    { return var_type; }
    int get_arr_size() const       { return arr_size; }
    vector<string> get_param_type() const { return param_type; }
    vector<string> get_param_name() const { return param_name; }

    // Setters
    void set_name(string n)        { name = n; }
    void set_type(string t)        { type = t; }
    void set_ID_type(string id)    { ID_type = id; }
    void set_var_type(string vt)   { var_type = vt; }
    void set_arr_size(int sz)      { arr_size = sz; }
    void set_param_type(const vector<string>& pt) { param_type = pt; }
    void set_param_name(const vector<string>& pn) { param_name = pn; }

    // Destructor (nothing to delete — vectors manage themselves)
    ~symbol_info() = default;
};

#endif // SYMBOL_INFO_H