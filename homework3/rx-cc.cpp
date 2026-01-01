/*
    EE046266: Compilation Methods - Winter 2025-2026
    Part 3: Code Generation - Main Compiler Program
*/

#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include "part3_helpers.hpp"

using namespace std;

// External functions from parser
extern int yyparse();
extern FILE* yyin;

// Global variable definitions
Buffer* buffer = new Buffer();
map<string, Symbol> symbolTable;
map<string, Function> functionTable;

// Additional globals used in parser
int currentDepth = 0;
int currentOffset = 0;
int tempCounter = 0;
map<int, Type> registerTypes;
string currentFunction = "";
Type currentFunctionReturnType = void_t;
bool inFunctionBody = false;

int main(int argc, char* argv[]) {
    // Check command line arguments
    if (argc != 3) {
        cerr << "Usage: " << argv[0] << " <input.cmm> <output.rsk>" << endl;
        return 1;
    }
    
    string inputFile = argv[1];
    string outputFile = argv[2];
    
    // Open input file
    yyin = fopen(inputFile.c_str(), "r");
    if (!yyin) {
        cerr << "Error: Cannot open input file: " << inputFile << endl;
        return 1;
    }
    
    // Parse the input
    int parseResult = yyparse();
    fclose(yyin);
    
    if (parseResult != 0) {
        cerr << "Parsing failed" << endl;
        return parseResult;
    }
    
    // Write output to file
    ofstream outFile(outputFile.c_str());
    if (!outFile) {
        cerr << "Error: Cannot open output file: " << outputFile << endl;
        return 1;
    }
    
    // Print the generated code
    outFile << buffer->printBuffer();
    outFile.close();
    
    cout << "Compilation successful. Output written to: " << outputFile << endl;
    
    // Clean up
    delete buffer;
    
    return 0;
}
