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
        // Skip leading/trailing/multiple spaces
        while (i < len && isspace(line[i]))
            i++;

        if (i >= len)
            break;

        // Extract one token
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
    freopen("output.txt", "w", stdout);

    int bucketCount;
    cin >> bucketCount;
    cin.ignore(); // clear newline after the number

    symbolTable symbolTable(bucketCount);

    // ScopeTable current =
    string line;
    int commandNo = 1;
    string command;
   
    string name, type, value, scopeId;

    ///////////////////////////////////

    while (cin >> command)
    {
        cout << "Cmd " << commandNo++ << ": " << command;

        char tokens[100][100];
        string inputLine;
        getline(cin, inputLine);
        cout << inputLine << endl;
        int tokenCount = tokenizeLine(tokens, inputLine);

        if (command == "I")
        {
            cout << "\t";
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
                {
                    cout << "Number of parameters mismatch for the command I" << endl;
                    continue;
                }
                name = tokens[0];
                type = (tokenCount > 1) ? tokens[1] : "";
            }

            symbolTable.insert(name, type);
        }
        else if (command == "L")
        {
            cout << "\t";
            if (tokenCount != 1)
            {
                cout << "Number of parameters mismatch for the command L" << endl;
            }
            else
            {
                name = tokens[0];
                symbolTable.lookUp(name);
            }
        }
        else if (command == "D")
        {
            cout << "\t";
            if (tokenCount != 1)
            {
                cout << "Number of parameters mismatch for the command D" << endl;
            }
            else
            {
                name = tokens[0];
                symbolTable.Remove(name);
            }
        }
        else if (command == "P")
        {
            if (tokenCount != 1)
            {
                cout << "Number of parameters mismatch for the command P" << endl;
            }
            else if (tokens[0][0] == 'A')
            {
                symbolTable.printAllScopeTables();
            }
            else if (tokens[0][0] == 'C')
            {
                symbolTable.printCurrentScopeTable();
            }
            else
            {
                cout << "Invalid command for P" << endl;
            }
        }
        else if (command == "S")
        {
            if (tokenCount != 0)
            {
                cout << "Number of parameters mismatch for the command S" << endl;
            }
            else
            {
                symbolTable.enterScope();
            }
        }
        else if (command == "E")
        {
            // cout << endl;
            if (tokenCount != 0)
            {
                cout << "Number of parameters mismatch for the command E" << endl;
            }
            else
            {
                symbolTable.exitScope();
            }
        }
        else if (command == "Q")
        {

            if (tokenCount != 0)
            {
                cout << "Number of parameters mismatch for the command Q" << endl;
            }
            else
            {
                symbolTable.quitallscope();
                return 0;
            }
        }
        else
        {
            cout << "Unrecognized command: " << command << endl;
        }
    }

}