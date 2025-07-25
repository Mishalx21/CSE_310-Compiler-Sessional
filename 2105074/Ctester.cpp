#include <iostream>
#include <fstream>
#include <string>
#include "antlr4-runtime.h"
#include "C2105074Lexer.h"
#include "C2105074Parser.h"

using namespace antlr4;
using namespace std;

ofstream parserLogFile; // global output stream
ofstream errorFile; // global error stream
ofstream lexLogFile; // global lexer log stream
ofstream machineFilePart1; // global machine code output stream
ofstream machineFilePart2; // global machine code output stream for second part


int syntaxErrorCount;

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    // ---- Input File ----
    ifstream inputFile(argv[1]);
    if (!inputFile.is_open()) {
        cerr << "Error opening input file: " << argv[1] << endl;
        return 1;
    }

    string outputDirectory = "output/";
    string parserLogFileName = outputDirectory + "parserLog.txt";
    string errorFileName = outputDirectory + "errorLog.txt";
    string lexLogFileName = outputDirectory + "lexerLog.txt";
    string machineCodeFileName = outputDirectory + "machineCode.txt";
    string machineCodeFilePartName2 = outputDirectory + "machineCodePart2.txt";
  

    // create output directory if it doesn't exist
    system(("mkdir -p " + outputDirectory).c_str());

    // ---- Output Files ----
    parserLogFile.open(parserLogFileName);
    if (!parserLogFile.is_open()) {
        cerr << "Error opening parser log file: " << parserLogFileName << endl;
        return 1;
    }

    errorFile.open(errorFileName);
    if (!errorFile.is_open()) {
        cerr << "Error opening error log file: " << errorFileName << endl;
        return 1;
    }

    lexLogFile.open(lexLogFileName);
    if (!lexLogFile.is_open()) {
        cerr << "Error opening lexer log file: " << lexLogFileName << endl;
        return 1;
    }
    machineFilePart1.open(machineCodeFileName);
    if (!machineFilePart1.is_open()) {
        cerr << "Error opening machine code file: " << machineCodeFileName << endl;
        return 1;
    }
    machineFilePart2.open(machineCodeFilePartName2);
    if (!machineFilePart2.is_open()) {
        cerr << "Error opening machine code file: " << machineCodeFilePartName2 << endl;
        return 1;
    }
    
   
   
    // ---- Parsing Flow ----
    ANTLRInputStream input(inputFile);
    C2105074Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    C2105074Parser parser(&tokens);

    // this is necessary to avoid the default error listener and use our custom error handling
    parser.removeErrorListeners();

    // start parsing at the 'start' rule
    parser.start();

    // clean up
    inputFile.close();
    parserLogFile.close();
    errorFile.close();
    lexLogFile.close();
    machineFilePart1.close();
    machineFilePart2.close();

    
    // Concatenate the two machine code files
    string finalMachineCodeFile = outputDirectory + "finalMachineCode.asm";
    ofstream finalFile(finalMachineCodeFile);
   /* 
    if (finalFile.is_open()) {
        // First, copy machineCodePart2.txt (data section)
       
        ifstream part2(machineCodeFilePartName2);
        if (part2.is_open()) {
            finalFile << part2.rdbuf();
            part2.close();
        }
        
        // Add .CODE section
       // finalFile << "\n.CODE\n";
        
        // Then, copy machineCode.txt (code section)
        ifstream part1(machineCodeFileName);
        if (part1.is_open()) {
            finalFile << part1.rdbuf();
            part1.close();
        }
        
        // Add print.txt content before END main
        ifstream printInputFile(printFileName);
        if (printInputFile.is_open()) {
            cout<< "Adding print utility functions to final machine code file." << endl;
            finalFile << "\n";
            finalFile << "; Print utility functions\n";
            finalFile << printInputFile.rdbuf();
            printInputFile.close();
        }
        else {
            cerr << "Error opening print file: " << printFileName << endl;
        }
        
        // Add END directive
        //finalFile << "\nEND main\n";
        
        finalFile.close();
       // cout << "Machine code files concatenated into: " << finalMachineCodeFile << endl;
    }
    */
    cout << "Parsing completed. Check the output files for details." << endl;
    return 0;
}
