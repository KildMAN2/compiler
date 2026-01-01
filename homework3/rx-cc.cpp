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
bool currentFunctionHasReturn = false;

int main(int argc, char* argv[]) {
    // Check command line arguments - now only needs input file
    if (argc != 2) {
        cerr << "Usage: " << argv[0] << " <input.cmm>" << endl;
        return 1;
    }
    
    string inputFile = argv[1];
    
    // Verify input file has .cmm extension
    if (inputFile.size() < 4 || inputFile.substr(inputFile.size() - 4) != ".cmm") {
        cerr << "Error: Input file must have .cmm extension" << endl;
        return 1;
    }
    
    // Generate output file name by replacing .cmm with .rsk
    string outputFile = inputFile.substr(0, inputFile.size() - 4) + ".rsk";
    
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
    
    // Generate header for linker
    outFile << "<header>" << endl;
    
    // Unimplemented functions (declared but not defined - external)
    outFile << "<unimplemented>";
    bool firstUnimp = true;
    for (auto& func : functionTable) {
        if (!func.second.isDefined) {
            if (!firstUnimp) outFile << " ";
            outFile << func.first;
            firstUnimp = false;
        }
    }
    outFile << endl;
    
    // Implemented functions (defined in this file) with their start line
    outFile << "<implemented>";
    bool firstImp = true;
    for (auto& func : functionTable) {
        if (func.second.isDefined) {
            if (!firstImp) outFile << " ";
            outFile << func.first << "," << (func.second.startLineImplementation + 1); // +1 because lines after header
            firstImp = false;
        }
    }
    outFile << endl;
    
    outFile << "</header>" << endl;
    
    // Print the generated code
    outFile << buffer->printBuffer();
    outFile.close();
    
    cout << "Compilation successful. Output written to: " << outputFile << endl;
    
    // Clean up
    delete buffer;
    
    return 0;
}
