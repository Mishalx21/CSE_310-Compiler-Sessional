#include <iostream>
#include <string>
#include <sstream>
#include <fstream>

#include "SymbolTable.hpp"

using namespace std;

void runTest(string inputFileName, string outputFileName, int hashFunctionChoice, int &totalInsertions, int &totalCollisions, double &collisionRatio, int &totalScopeTables, int &bucketCount);
string filterSpaces(string str);

int main(int argc, char const *argv[])
{
    string inputFileName = "input.txt";
    string outputFileName = "report.txt";

    ifstream inputFile;
    if(argc > 1)
    {
        inputFileName = argv[1];
    }
    else
    {
        cout << "No input file provided. Reading from input.txt" << endl;
    }

    ofstream outputFile;
    outputFile.open(outputFileName);
    if(!outputFile.is_open())
    {
        cout << "Error opening output file" << endl;
        return 1;
    }

    int totalTests = 3;

    int totalInsertions = 0;
    int totalScopeTables = 0;
    int *collisions = new int[totalTests]();
    double *collisionRatios = new double[totalTests]();
    int bucketCount = 0;

    for (int t = 0; t < totalTests; t++)
    {
        runTest(inputFileName, outputFileName, t + 1, totalInsertions, collisions[t], collisionRatios[t], totalScopeTables, bucketCount);    
    }

    outputFile << "SymbolTable Collision Report" << endl;
    outputFile << "Total number of insertions: " << totalInsertions << endl;
    outputFile << "Total number of scope tables: " << totalScopeTables << endl;
    outputFile << "Total number of buckets: " << bucketCount << endl;
    // outputFile << "------------------------------------------------------------------" << endl;
    outputFile << endl;

    int totalSpace = 35;
    for (int t = 0; t < totalTests; t++)
    {
        string hashFunctionName = getHashFunctionName(t + 1);
        outputFile << hashFunctionName;
        for(int i = 0; i < (totalSpace - hashFunctionName.length()); i++) outputFile << " ";
        outputFile << " -> Total collisions: " << collisions[t] << endl;
        for(int i = 0; i < totalSpace; i++) outputFile << " ";
        outputFile << " -> Collision ratio:  " << collisionRatios[t] << endl;
        outputFile << endl;
        // outputFile << "------------------------------------------------------------------" << endl;
    }

    outputFile << endl;
    outputFile << "Hash function source: " << endl;
    for (int i = 0; i < totalTests; i++)
    {
        outputFile << getHashFunctionName(i + 1) << " : " << getHashFunctionSource(i + 1) << endl;
    }
    

    delete[] collisions;
    delete[] collisionRatios;
    
    return 0;
}

void runTest(string inputFileName, string outputFileName, int hashFunctionChoice, int &totalInsertions, int &totalCollisions, double &totalCollisionRatio, int &totalScopeTables, int &bucketCount)
{
    ifstream inputFile(inputFileName);
    if(!inputFile.is_open())
    {
        cout << "Error opening input file" << endl;
    }

    string line;

    getline(inputFile, line);

    stringstream stringStream(line);
    stringStream >> bucketCount; 
    if(bucketCount <= 0)
    {
        cout << "Invalid number of buckets" << endl;
    }

    SymbolTable symbolTable(bucketCount, hashFunctionChoice);
    
    int cmdCount = 0;

    while (getline(inputFile, line))
    {
        line = filterSpaces(line);
        // if(line == "") continue; // ignore empty lines
        string choice, symbolName, symbolType, extra;
        stringstream stringStream(line);
        stringStream >> choice;
        
        cmdCount++;

        // cout << "Cmd " << cmdCount << ": " << line << endl;
    
        if(choice == "I") // Insert
        {
            int extraCount = 0;

            if(!(stringStream >> symbolName)) // I must be followed by symbol name
            {
                // cout << "\tNumber of parameters mismatch for the command I" << endl;
                continue;
            }
            if(!(stringStream >> symbolType)) // I may or may not be followed by symbol type
            {
                symbolType = "";
            }
            
            if(symbolType == "FUNCTION")
            {
                while(stringStream >> extra)
                {
                    symbolType += " " + extra;
                    extraCount++;
                }
            }
            else if(symbolType == "STRUCT" || symbolType == "UNION")
            {
                while(stringStream >> extra)
                {
                    symbolType += " " + extra;
                    extraCount++;
                }

                if(extraCount % 2 != 0)
                {
                    // cout << "\tNumber of parameters mismatch for the command I (STRUCT/UNION should be followed by type and name pairs)" << endl;
                    continue;
                }
            }
            else 
            {
                if(stringStream >> extra)
                {
                    // cout << "\tNumber of parameters mismatch for the command I" << endl;
                    continue;
                }
            }
            
            symbolTable.insert(symbolName, symbolType);
        }
        else if(choice == "L") // Lookup
        {
            if(!(stringStream >> symbolName))
            {
                // cout << "\tNumber of parameters mismatch for the command L" << endl;
                continue;
            }

            if(stringStream >> extra)
            {
                // cout << "\tNumber of parameters mismatch for the command L" << endl;
                continue;
            }

            symbolTable.lookUp(symbolName);
        }
        else if(choice == "D") // Delete
        {
            if(!(stringStream >> symbolName))
            {
                // cout << "\tNumber of parameters mismatch for the command D" << endl;
                continue;
            }

            if(stringStream >> extra)
            {
                // cout << "\tNumber of parameters mismatch for the command D" << endl;
                continue;
            }

            symbolTable.erase(symbolName);
        }
        else if(choice == "P") // Print
        {
            string printType;
            if(!(stringStream >> printType))
            {
                // cout << "\tNumber of parameters mismatch for the command P" << endl;
                continue;
            }

            if(stringStream >> extra)
            {
                // cout << "\tNumber of parameters mismatch for the command P" << endl;
                continue;
            }

            if(printType == "A")
            {
                symbolTable.printAllScopeTables();
            }
            else if(printType == "C")
            {
                symbolTable.printCurrentScopeTable();
            }
            else
            {
                // cout << "\tInvalid parameter for the command P" << endl;
                continue;
            }
        }
        else if(choice == "S") // Enter new scope table
        {
            if(stringStream >> extra)
            {
                // cout << "\tNumber of parameters mismatch for the command S" << endl;
                continue;
            }

            symbolTable.enterScope();
        }
        else if(choice == "E") // Exit current scope table
        {
            if(stringStream >> extra)
            {
                // cout << "\tNumber of parameters mismatch for the command E" << endl;
                continue;
            }

            symbolTable.exitScope();
        }
        else if(choice == "Q") // Quit the program
        {
            if(stringStream >> extra)
            {
                // cout << "\tNumber of parameters mismatch for the command Q" << endl;
                continue;
            }

            break;
        }
        else 
        {
            // cout << "\tInvalid command" << endl;
            continue;
        }
    }

    inputFile.close();

    totalInsertions = symbolTable.getTotalInsertions();
    totalCollisions = symbolTable.getTotalCollisions();
    totalCollisionRatio = symbolTable.getCollisionRatio();
    totalScopeTables = symbolTable.getTotalScopeTables();
}


string filterSpaces(string str)
{
    stringstream ss(str);
    string filteredStr;
    string word;

    while (ss >> word)
    {
        filteredStr += word + " ";
    }

    if (!filteredStr.empty())
    {
        filteredStr.pop_back(); // Remove the trailing space
    }

    return filteredStr;
}
