#ifndef SYMBOLINFO_H
#define SYMBOLINFO_H

#include <iostream>
#include <string>
using namespace std;

class Symbolinfo
{
    string name;
    string type;
    Symbolinfo *next;
    
public:
    
    Symbolinfo(string name,string type,Symbolinfo *next=NULL)
    {
        this->name=name;
        this->type=type;
        this->next=next;

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
    }
    void setNext(Symbolinfo *next)
    {
        this->next=next;
    }

    void show()
    {
        cout<<"Name:"<<name<<" "<<" Type:"<<type<<endl;
    }

    ~Symbolinfo()
    {
        if(next != NULL) delete next; 
    }
    
};

#endif

