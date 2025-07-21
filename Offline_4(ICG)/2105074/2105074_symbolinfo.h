#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H

#include <iostream>
#include <string>
#include <vector>
using namespace std;

class Symbolinfo
{
    string name;
    string type;
    Symbolinfo *next;
    bool isDefined; // For functions: true if defined, false if only declared
    bool arraytype;
    int arraySize;
    bool isGlobal; 
    int offset;
    bool isParameter; // True if this symbol is a function parameter
    string returnType; // For functions: the return type of the function
    vector<pair<string, string>> parameters; // For functions: parameter list (name, type)
    
public:      Symbolinfo(string name,string type,Symbolinfo *next=NULL, bool isDefined=false, bool arraytype=false, string returnType="", vector<pair<string, string>> parameters = vector<pair<string, string>>())
    {
        this->name=name;
        this->type=type;
        this->next=next;
        this->isDefined=isDefined;
        this->arraytype=arraytype;
        this->returnType=returnType;
        this->parameters=parameters;
        this->arraySize = 0;
        this->isGlobal = false;
        this->offset = 0;
        this->isParameter = false;
    }

    //  getter and setter
    string getName()
    {
        return name;
    }
    string getType()
    {
        return type;
    }
    Symbolinfo *getNext()
    {
        return next;
    }

    void setName(string name)
    {
        this->name=name;
    }
    void setType(string type)
    {
        this->type=type;
    }    void setNext(Symbolinfo *next)
    {
        this->next=next;
    }
    
    bool getIsDefined()
    {
        return isDefined;
    }
      void setIsDefined(bool isDefined)
    {
        this->isDefined=isDefined;
    }
    
    bool getArrayType()
    {
        return arraytype;
    }
    
    void setArrayType(bool arraytype)
    {
        this->arraytype=arraytype;
    }
    
    string getReturnType()
    {
        return returnType;
    }
    
    void setReturnType(string returnType)
    {
        this->returnType=returnType;
    }
    
    vector<pair<string, string>> getParameters()
    {
        return parameters;
    }
    
    void setParameters(vector<pair<string, string>> parameters)
    {
        this->parameters=parameters;
    }

    void show()
    {
        cout<<"Name:"<<name<<" "<<" Type:"<<type<<endl;
    }
    int getArraySize()
    {
        return arraySize;
    }
    void setArraySize(int size)
    {
        this->arraySize = size;
    }
    bool getIsGlobal()
    {
        return isGlobal;
    }
    void setIsGlobal(bool isGlobal)
    {
        this->isGlobal = isGlobal;
    }
    int getOffset()
    {
        return offset;
    }
    void setOffset(int offset)
    {
        this->offset = offset;
    }
    bool getIsParameter()
    {
        return isParameter;
    }
    void setIsParameter(bool isParameter)
    {
        this->isParameter = isParameter;
    }

    ~Symbolinfo()
    {
        if(next != NULL) delete next; 
    }
    
};

#endif

