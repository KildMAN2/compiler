/*
 * Compilation Course - Project Part 3
 * Main compiler program for rx-cc
 * EE046266 Winter 2025-2026
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "part3_helpers.hpp"

// External from parser
extern int yyparse(void);
extern FILE* yyin;
extern int line_number;

// Global variables - defined here
Buffer* buffer = NULL;
map<string, Symbol> symbolTable;
map<string, Function> functionTable;

// Function to extract filename without extension
string getBaseName(const string& filename) {
    size_t lastDot = filename.find_last_of('.');
    if (lastDot == string::npos) {
        return filename;
    }
    return filename.substr(0, lastDot);
}

// Function to check file extension
bool hasExtension(const string& filename, const string& ext) {
    if (filename.length() < ext.length()) {
        return false;
    }
    return filename.substr(filename.length() - ext.length()) == ext;
}

// Generate linker header
void generateLinkerHeader(ofstream& outFile, const string& moduleName) {
    // .extern directive for external functions
    outFile << ".extern ";
    bool first = true;
    for (auto& pair : functionTable) {
        if (!pair.second.isDefined) {
            if (!first) outFile << " ";
            outFile << pair.first;
            first = false;
        }
    }
    outFile << endl;
    
    // .global directive for defined functions
    outFile << ".global ";
    first = true;
    for (auto& pair : functionTable) {
        if (pair.second.isDefined) {
            if (!first) outFile << " ";
            outFile << pair.first;
            first = false;
        }
    }
    outFile << endl << endl;
}

int main(int argc, char** argv) {
    // Check command line arguments
    if (argc != 2) {
        fprintf(stderr, "Usage: rx-cc <input_file.cmm>\n");
        return OPERATIONAL_ERROR;
    }
    
    string inputFile = argv[1];
    
    // Check file extension
    if (!hasExtension(inputFile, ".cmm")) {
        fprintf(stderr, "Error: Input file must have .cmm extension\n");
        return OPERATIONAL_ERROR;
    }
    
    // Open input file
    FILE* inFile = fopen(inputFile.c_str(), "r");
    if (!inFile) {
        fprintf(stderr, "Error: Cannot open input file: %s\n", inputFile.c_str());
        return OPERATIONAL_ERROR;
    }
    
    // Set input for lexer
    yyin = inFile;
    
    // Initialize buffer for code generation
    buffer = new Buffer();
    
    // Parse input file
    int parseResult = yyparse();
    
    fclose(inFile);
    
    if (parseResult != 0) {
        // Parsing failed
        delete buffer;
        return SYNTAX_ERROR;
    }
    
    // Generate output file
    string baseName = getBaseName(inputFile);
    string outputFile = baseName + ".rsk";
    
    ofstream outFile(outputFile.c_str());
    if (!outFile.is_open()) {
        fprintf(stderr, "Error: Cannot create output file: %s\n", outputFile.c_str());
        delete buffer;
        return OPERATIONAL_ERROR;
    }
    
    // Write linker header
    generateLinkerHeader(outFile, baseName);
    
    // Write generated code
    outFile << buffer->printBuffer();
    
    outFile.close();
    delete buffer;
    
    printf("Compilation successful: %s -> %s\n", inputFile.c_str(), outputFile.c_str());
    
    return 0;
}
