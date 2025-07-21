#ifndef SYMBOLTABLE_CPP
#define SYMBOLTABLE_CPP

#include <bits/stdc++.h>
using namespace std;
#include "2105074_symbolinfo.h"
#include "2105074_scopeTable.h"
class symbolTable
{
    ScopeTable *currentScopeTable;
    int num_buckets;
    int scopeCount = 0; // To keep track of the number of symbols in the symbol table
    int collisionCount = 0;

public:
    unsigned int (*hashFunc)(string); // Hash function pointer
    symbolTable(int n, bool print = true, unsigned int (*hf)(string) = nullptr)
    {
        hashFunc = hf;
        // cout << endl;

        currentScopeTable = new ScopeTable(n, NULL, ++scopeCount, print, hf);
        num_buckets = n;
    }
    ~symbolTable()
    {
        delete currentScopeTable; // Destructor will handle the deletion of all scopes
    }

    void enterScope(bool print = true)
    {
        // cout << endl;
        ScopeTable *newScope = new ScopeTable(num_buckets, currentScopeTable, ++scopeCount, print, hashFunc);
        currentScopeTable = newScope;
        // cout << endl;
        // cout << "\tNew ScopeTable" << currentScopeTable->getId() << " created" << endl;
    }
    ScopeTable *getCurrentScopeTable()
    {
        return currentScopeTable;
    }
    void quitallscope(bool print = true)

    {
        // use exitScope() to delete all the scopes
        while (currentScopeTable->getParentScope() != nullptr)
        {

            collisionCount += currentScopeTable->getCollisionCount();
            ScopeTable *temp = currentScopeTable;
            currentScopeTable = currentScopeTable->getParentScope();
            temp->setParentScope(nullptr);
            if (print)
            {
                cout << "\tScopeTable# " << temp->getId() << " removed" << endl;
            }
            delete temp;
        }
        if (print)
        {
            cout << "\tScopeTable# " << currentScopeTable->getId() << " removed" << endl;
        }
        collisionCount += currentScopeTable->getCollisionCount();
    }

    void exitScope(bool print = true)
    {

        if (currentScopeTable->getParentScope() != nullptr)
        {
            collisionCount += currentScopeTable->getCollisionCount();
            ScopeTable *temp = currentScopeTable;
            currentScopeTable = currentScopeTable->getParentScope();
            temp->setParentScope(nullptr);
            if (print)
            {
                cout << "\tScopeTable# " << temp->getId() << " removed" << endl;
            }
            delete temp;
        }
        else
        {
            if (print)
            {
                cout << "\tNo more scopes to exit" << endl;
            }
        }
    }    bool insert(string name, string type, bool print = true, bool arraytype = false)
    {
        if (currentScopeTable->insert(name, type, print, arraytype))
        {

            return true;
        }
        else
        {
            if (print)
            {

                cout << "'" << name << "'" << "already exists in the current ScopeTable" << endl;
            }
            return false;
        }
    }    
    
    bool insertParameter(string name, string type, bool print = true, bool arraytype = false)
    {
        if (currentScopeTable->insertParameter(name, type, print, arraytype))
        {
            return true;
        }
        else
        {
            if (print)
            {
                cout << "'" << name << "'" << " parameter already exists in the current ScopeTable" << endl;
            }
            return false;
        }
    }    // Special method for handling function declarations/definitions
    bool insertFunction(string name, string returnType, bool isDefined, vector<pair<string, string>> parameters, bool print = true)
    {
        if (currentScopeTable->insertFunction(name, returnType, isDefined, parameters, print))
        {
            return true;
        }
        else
        {
            if (print)
            {
                cout << "'" << name << "'" << " function declaration/definition conflict in the current ScopeTable" << endl;
            }
            return false;
        }
    }

    bool Remove(string name, bool print = true)
    {
        if (currentScopeTable->Delete(name, print))
        {
            // cout << "Removed from current ScopeTable" << endl;
            return true;
        }
        else
        {

            return false;
        }
    }

    Symbolinfo *lookUp(string name, bool print = false)
    {
        ScopeTable *temp = currentScopeTable;
        while (temp != nullptr)
        {
            Symbolinfo *symbol = temp->lookUp(name, print);
            if (symbol != nullptr)
                return symbol;
            temp = temp->getParentScope();
        }
        if (print)
        {
            cout << "'" << name << "'" << " not found in any of the ScopeTables" << endl;
        }
        return nullptr;
    }
/*
    void printCurrentScopeTable()
    {
        currentScopeTable->print();
    }
    void printAllScopeTables()
    {
        ScopeTable *temp = currentScopeTable;
        int indent = 2;
        while (temp != nullptr)
        {
            temp->print(indent++);
            temp = temp->getParentScope();
        }
    }
*/
    void printCurrentScopeTable(std::ostream &out)
    {
        currentScopeTable->print(out);
    }
    void printAllScopeTables(std::ostream &out)
    {
        ScopeTable *temp = currentScopeTable;
        int indent = 2;
        while (temp != nullptr)
        {
            temp->print(out, indent++);
            temp = temp->getParentScope();
        }
    }

    int getCollisionCount()
    {
        return collisionCount;
    }

    int getScopeCount()
    {
        return scopeCount;
    }
    int getSymbolTableNum()
    {
        return currentScopeTable->getId();
    }
};

#endif // SYMBOLTABLE_CPP