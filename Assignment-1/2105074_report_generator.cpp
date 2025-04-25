#include <bits/stdc++.h>
using namespace std;
#include "2105074_symbolinfo.h"
#include "2105074_scopeTable.h"
#include "2105074_symbolTable.h"

// Hash function: sdbm
unsigned int sdbm(string str)
{
    unsigned long hash = 0;
    for (char c : str)
        hash = c + (hash << 6) + (hash << 16) - hash;
    return hash;
}

// Hash function: djb2
unsigned int djb2(string str)
{

    unsigned long hash = 5381;
    for (char c : str)
        hash = ((hash << 5) + hash) + c; // hash * 33 + c
    // return hash;
    return hash;
}

// Hash function: fnv1a
unsigned int fnv1a(string str)
{
    const unsigned int fnv_prime = 16777619u;
    unsigned int hash = 2166136261u;
    for (char c : str)
    {
        hash ^= c;
        hash *= fnv_prime;
    }
    return hash;
}

int tokenizeLine(char tokens[][100], const string &line)
{
    int count = 0;
    int i = 0;
    int len = line.length();

    while (i < len)
    {
        while (i < len && isspace(line[i]))
            i++;

        if (i >= len)
            break;

        int j = 0;
        while (i < len && !isspace(line[i]) && j < 99)
        {
            tokens[count][j++] = line[i++];
        }
        tokens[count][j] = '\0';
        count++;
    }

    return count;
}

int main(int argc, char *argv[])
{
    string hashFuncName = "sdbm";
    if (argc > 1)
        hashFuncName = argv[1];

    // Select hash function (default sdbm)
    unsigned int (*hashFunc)(string) = sdbm;
    if (hashFuncName == "djb2")
        hashFunc = djb2;
    else if (hashFuncName == "fnv1a")
        hashFunc = fnv1a;

    freopen("input.txt", "r", stdin);
    freopen("report_output.txt", "w", stdout);

    int bucketCount;
    cin >> bucketCount;
    cin.ignore();

    // Create three symbol tables for each hash function
    symbolTable table_sdbm(bucketCount, false);
    symbolTable table_djb2(bucketCount, false, djb2);
    symbolTable table_fnv1a(bucketCount, false, fnv1a);

    // table_sdbm.getCurrentScopeTable()->hashFunc = sdbm;
    // table_djb2.getCurrentScopeTable()->hashFunc = djb2;
    // table_fnv1a.getCurrentScopeTable()->hashFunc = fnv1a;

    string line, command, name, type;
    int commandNo = 1;

    cout << "hashFuncName: " << hashFuncName << endl;

    while (cin >> command)
    {
        string inputLine;
        char tokens[100][100];
        getline(cin, inputLine);
        // cout << "Cmd " << commandNo++ << ": " << command << "  ";
        // cout << inputLine << endl;
        int tokenCount = tokenizeLine(tokens, inputLine);

        if (command == "I")
        {
            if (strcmp(tokens[1], "FUNCTION") == 0)
            {
                name = tokens[0];
                type = string(tokens[1]) + "," + tokens[2] + "<==(";
                for (int i = 3; i < tokenCount; i++)
                {
                    type += tokens[i];
                    if (i != tokenCount - 1)
                        type += ",";
                }
                type += ")";
            }
            else if (strcmp(tokens[1], "STRUCT") == 0 || strcmp(tokens[1], "UNION") == 0)
            {
                name = tokens[0];
                type = string(tokens[1]) + ",{";
                for (int i = 2; i < tokenCount; i += 2)
                {
                    type += "(" + string(tokens[i]) + "," + string(tokens[i + 1]) + ")";
                    if (i + 2 < tokenCount)
                        type += ",";
                }
                type += "}";
            }
            else
            {
                if (tokenCount < 2)
                    continue;
                name = tokens[0];
                type = (tokenCount > 1) ? tokens[1] : "";
            }

            table_sdbm.insert(name, type, false);
            table_djb2.insert(name, type, false);
            table_fnv1a.insert(name, type, false);
        }
        else if (command == "L")
        {
            if (tokenCount != 1)
                continue;
            name = tokens[0];
            table_sdbm.lookUp(name, false);
            table_djb2.lookUp(name, false);
            table_fnv1a.lookUp(name, false);
        }
        else if (command == "D")
        {
            if (tokenCount != 1)
                continue;
            name = tokens[0];
            table_sdbm.Remove(name, false);
            table_djb2.Remove(name, false);
            table_fnv1a.Remove(name, false);
        }
        else if (command == "P")
        {
            if (tokenCount != 1)
                continue;
            if (tokens[0][0] == 'A')
            {
                // Optional: Add if needed
            }
            else if (tokens[0][0] == 'C')
            {
                // Optional: Add if needed
            }
        }
        else if (command == "S")
        {
            if (tokenCount != 0)
                continue;
            table_sdbm.enterScope(false);
            table_djb2.enterScope(false);
            table_fnv1a.enterScope(false);
        }
        else if (command == "E")
        {
            if (tokenCount != 0)
                continue;
            table_sdbm.exitScope(false);
            table_djb2.exitScope(false);
            table_fnv1a.exitScope(false);
        }
        else if (command == "Q")
        {
            if (tokenCount != 0)
                continue;
            table_sdbm.quitallscope(false);
            table_djb2.quitallscope(false);
            table_fnv1a.quitallscope(false);

            cout << "SDBM Hash Function: " << endl;
            cout << "Total number of collisions: " << table_sdbm.getCollisionCount() << endl;
            cout << "Collision ration: " << (float)table_sdbm.getCollisionCount() / (table_sdbm.getCurrentScopeTable()->getNumBuckets() * table_sdbm.getScopeCount()) << endl;

            cout << "DJB2 Hash Function: " << endl;
            cout << "Total number of collisions: " << table_djb2.getCollisionCount() << endl;
            cout << "Collision ration: " << (float)table_djb2.getCollisionCount() / (table_djb2.getCurrentScopeTable()->getNumBuckets() * table_djb2.getScopeCount()) << endl;

            cout << "FNV1A Hash Function: " << endl;
            cout << "Total number of collisions: " << table_fnv1a.getCollisionCount() << endl;
            cout << "Collision ration: " << (float)table_fnv1a.getCollisionCount() / (table_fnv1a.getCurrentScopeTable()->getNumBuckets() * table_fnv1a.getScopeCount()) << endl;

            return 0;
        }
    }

    return 0;
}
