#ifndef SCOPE_TABLE_CPP
#define SCOPE_TABLE_CPP

#include <bits/stdc++.h>
using namespace std;
#include "2105074_symbolinfo.h"

class ScopeTable
{
    int id;
    int num_buckets;
    Symbolinfo **table;
    ScopeTable *parentScope;
    int collision_count;
    string newid;

public:
    unsigned int (*hashFunc)(string);

    ScopeTable(int n, ScopeTable *parent = nullptr, int scope_id = 0, bool print = true, unsigned int (*hf)(string) = nullptr)
    {
        parentScope = parent;
        hashFunc = hf;
        collision_count = 0;
        if (parent != nullptr){
            id = parent->getId() + 1;
            newid = parent->getNewId() + "."+to_string(1);
        }
        else{
            id = 1;
            newid = to_string(id);
        }
        if (scope_id != 0)
            id = scope_id;
        num_buckets = n;
        table = new Symbolinfo *[num_buckets];
        for (int i = 0; i < num_buckets; i++)
            table[i] = nullptr;
        if (print)
        {
            cout << "\tScopeTable# " << id << " created" << endl;
        }
    }

    ~ScopeTable()
    {
        for (int i = 0; i < num_buckets; i++)
        {
            if (table[i] != nullptr)
            {
                delete table[i];
            }
        }

        delete[] table;
        if (parentScope != nullptr)
        {
            delete parentScope; // Disconnect from parent scope
        }
    }

    int getId() { return id; }
    int getNumBuckets() { return num_buckets; }
    ScopeTable *getParentScope() { return parentScope; }
    string getNewId() { return newid; }

    void setParentScope(ScopeTable *parent) { parentScope = parent; }

    unsigned int hashFunction(string str)
    {
        // if (hashFunc == nullptr)
        //     cout << "hashFunc is null" << endl;
        if (hashFunc)
            return hashFunc(str) % num_buckets;

        // Default to SDBM
        unsigned int hash = 0;
        unsigned int len = str.length();
        for (unsigned int i = 0; i < len; i++)
        {
            hash = ((str[i]) + (hash << 6) + (hash << 16) - hash) % num_buckets;
        }
        return hash;
    }

    Symbolinfo *lookUp(string key, bool print = false)
    {
        unsigned int index = hashFunction(key);

        Symbolinfo *temp = table[index];

        int count = 1;
        while (temp != nullptr)
        {
            if (temp->getName() == key)
            {
                if (print)
                    cout << "'" << key << "'" << "found in ScopeTable #" << id << " at position " << index + 1 << ", " << count << endl;
                return temp;
            }
            temp = temp->getNext();
            count++;
        }
        return nullptr;
    }    bool insert(string name, string type, bool print = true, bool arraytype = false)
    {
        if (lookUp(name) == nullptr)
        {
            unsigned int index = hashFunction(name);
            Symbolinfo *newSymbol = new Symbolinfo(name, type, nullptr, false, arraytype);

            int count = 0;
            if (table[index] == nullptr) // checking if the chain is empty
            {
                table[index] = newSymbol;
            }
            else
            {
                count = 1;
                collision_count++;
                Symbolinfo *temp = table[index];
                while (temp->getNext() != nullptr)
                {
                    temp = temp->getNext();

                    count++;
                }
                temp->setNext(newSymbol);
            }
            if (print)
            {
                cout << "Inserted in ScopeTable# " << id << " at position " << index + 1 << ", " << count + 1 << endl;
            }
            return true;
        }
        else
        {

            // cout << "Already exists in the current scope" << endl;
            return false;
        }
    }

    bool insertParameter(string name, string type, bool print = true, bool arraytype = false)
    {
        if (lookUp(name) == nullptr)
        {
            unsigned int index = hashFunction(name);
            Symbolinfo *newSymbol = new Symbolinfo(name, type, nullptr, false, arraytype);
            newSymbol->setIsParameter(true); // Mark as parameter

            int count = 0;
            if (table[index] == nullptr) // checking if the chain is empty
            {
                table[index] = newSymbol;
            }
            else
            {
                count = 1;
                collision_count++;
                Symbolinfo *temp = table[index];
                while (temp->getNext() != nullptr)
                {
                    temp = temp->getNext();
                    count++;
                }
                temp->setNext(newSymbol);
            }
            if (print)
            {
                cout << "Inserted parameter in ScopeTable# " << id << " at position " << index + 1 << ", " << count + 1 << endl;
            }
            return true;
        }
        else
        {
            return false;
        }
    }

    bool Delete(string name, bool print = true)
    {
        if (lookUp(name) != nullptr)
        {
            unsigned int index = hashFunction(name);
            Symbolinfo *temp = table[index];
            Symbolinfo *prev = nullptr;

            int count = 1;
            while (temp != nullptr && temp->getName() != name)
            {
                prev = temp;
                temp = temp->getNext();
                count++;
            }
            if (prev == nullptr) // Deleting the first node in the chain
            {
                table[index] = temp->getNext();
            }
            else
            {
                prev->setNext(temp->getNext());
            }
            temp->setNext(nullptr); // Disconnect the node from the chain

            if (print)
            {
                cout << "\t";
                cout << "Deleted '" << name << "' from ScopeTable #" << id << " at position " << index + 1 << ", " << count << endl;
            }
            delete temp; // Free the memory of the deleted node
            return true;
        }
        else
        {
            if (print)
            {
                cout << "Not found in the current ScopeTable " << endl;
            }
            return false;
        }
    }
/*
    void print(int indentLevel = 2)
    {
        // Print indentation
        for (int i = 0; i < indentLevel; i++)
        {
            cout << "\t";
        }

        // Print the scope header
        cout << "ScopeTable# " << this->id << endl;

        // Print each bucket
        for (int i = 0; i < num_buckets; i++)
        {
            for (int j = 0; j < indentLevel; j++)
            {
                cout << "\t";
            }

            cout << i + 1 << "-->";

            Symbolinfo *temp = table[i];
            while (temp != nullptr)
            {
                cout << " <" << temp->getName() << "," << temp->getType() << ">";
                temp = temp->getNext();
            }
            cout << " " << endl; // ensure clean line even if empty
        }
    }
        */
void print(std::ostream &out, int indentLevel = 2)
    {
        for (int i = 0; i < indentLevel; i++)
        {
            //out << "\t";
        }

        out << "ScopeTable# " << this->newid << std::endl;

        for (int i = 0; i < num_buckets; i++)
        {
            // for (int j = 0; j < indentLevel; j++)
            // {
            //     out << "\t";
            // }

            //out << i + 1 << "-->";

            Symbolinfo *temp = table[i];
            if (temp == nullptr)
            {
                continue; // Skip empty buckets
                //out << " <empty>";
            }            out << i  << "-->";            while (temp != nullptr)
            {
               // out << " <" << temp->getName() << "," << temp->getType() << ">";
               if (temp->getType() == "FUNCTION") {
                   out << " < " << temp->getName() << " : " << temp->getReturnType() << " >";
               } else {
                   out << " < " << temp->getName() << " : " << temp->getType() << " >";
               }
                temp = temp->getNext();
            }
            out << " " << std::endl;
        }
    }


    int getCollisionCount()
    {
        return collision_count;
    }    // Special method for handling function declarations/definitions
    bool insertFunction(string name, string returnType, bool isDefined, vector<pair<string, string>> parameters, bool print = true)
    {
        Symbolinfo* existingSymbol = lookUp(name);
        
        if (existingSymbol == nullptr)
        {
            // Function doesn't exist, insert it
            unsigned int index = hashFunction(name);
            Symbolinfo *newSymbol = new Symbolinfo(name, "FUNCTION", nullptr, isDefined, false, returnType, parameters);

            int count = 0;
            if (table[index] == nullptr)
            {
                table[index] = newSymbol;
            }
            else
            {
                count = 1;
                collision_count++;
                Symbolinfo *temp = table[index];
                while (temp->getNext() != nullptr)
                {
                    temp = temp->getNext();
                    count++;
                }
                temp->setNext(newSymbol);
            }
            if (print)
            {
                cout << "Inserted in ScopeTable# " << id << " at position " << index + 1 << ", " << count + 1 << endl;
            }
            return true;
        }        else
        {
            // Function already exists, check if it's valid
            bool existingIsDefined = existingSymbol->getIsDefined();
            string existingReturnType = existingSymbol->getReturnType();
            vector<pair<string, string>> existingParameters = existingSymbol->getParameters();
            
            // Check return type consistency
            if (existingReturnType != returnType)
            {
                // Return type mismatch - error
                return false;
            }
            
            // Check parameter count and types consistency
            if (existingParameters.size() != parameters.size())
            {
                // Parameter count mismatch - error
                return false;
            }
            
            // Check parameter types
            for (size_t i = 0; i < parameters.size(); i++)
            {
                if (existingParameters[i].second != parameters[i].second)
                {
                    // Parameter type mismatch - error
                    return false;
                }
            }
            
            if (!existingIsDefined && isDefined)
            {
                // Previously declared, now being defined - this is valid
                existingSymbol->setIsDefined(true);
                return true;
            }
            else if (existingIsDefined && isDefined)
            {
                // Already defined, trying to define again - error
                return false;
            }
            else if (!existingIsDefined && !isDefined)
            {
                // Already declared, trying to declare again - this is OK for functions
                return true;
            }
            else // (existingIsDefined && !isDefined)
            {
                // Already defined, trying to declare - this is OK for functions
                return true;
            }
        }
    }
};

#endif // SCOPE_TABLE_CPP
