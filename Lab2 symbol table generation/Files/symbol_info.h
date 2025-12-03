#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    string ID_type; // variable/array/function
    string var_type; // int/float/void/...
    int arr_size; // size of array if symbol is an array
    vector<string> param_type;
    vector<string> param_name;


    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    // Write necessary attributes to store the parameters of a function
    // Write necessary attributes to store the array size if the symbol is an array

public:
    symbol_info(string name, string type, string ID_type, string var_type, int arr_size, vector<string> param_type, vector<string> param_name)
    {
        this->ID_type = ID_type;
        this->var_type = var_type;
        this->arr_size = arr_size;
        this->param_type = param_type;
        this->param_name = param_name;
    
        this->name = name;
        this->type = type;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes

    //get methods
    string get_ID_type()
    {
        return ID_type;
    }
    string get_var_type()
    {
        return var_type;
    }
    int get_arr_size()
    {
        return arr_size;
    }
    vector<string> get_param_type()
    {
        return param_type;
    }
    vector<string> get_param_name()
    {
        return param_name;
    }


    //set methods
    void set_ID_type(string ID_type)
    {
        this->ID_type = ID_type;
    }
    void set_var_type(string var_type)
    {
        this->var_type = var_type;
    }
    void set_arr_size(int arr_size)
    {
        this->arr_size = arr_size;
    }
    void set_param_type(vector<string> param_type)
    {
        this->param_type = param_type;
    }
    void set_param_name(vector<string> param_name)
    {
        this->param_name = param_name;
    }


    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};