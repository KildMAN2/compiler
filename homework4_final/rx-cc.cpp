/*
    EE046266: Compilation Methods - Winter 2025-2026
    C-- Compiler Main Driver
*/

#include "part3_helpers.hpp"
#include <fstream>

extern int yyparse();
extern FILE* yyin;
extern string getGeneratedCode();

int main(int argc, char** argv) {
    if (argc != 2) {
        cerr << "Operational error: wrong number of arguments" << endl;
        return OPERATIONAL_ERROR;
    }

    string inputFile = argv[1];

    // Input file must be a single .cmm file
    const string suffix = ".cmm";
    if (inputFile.size() < suffix.size() || inputFile.substr(inputFile.size() - suffix.size()) != suffix) {
        cerr << "Operational error: input file must have .cmm extension" << endl;
        return OPERATIONAL_ERROR;
    }

    yyin = fopen(inputFile.c_str(), "r");
    
    if (!yyin) {
        cerr << "Operational error: cannot open file" << endl;
        return OPERATIONAL_ERROR;
    }

    // Parse the input (buffer initialized in parser)
    int result = yyparse();
    
    fclose(yyin);

    if (result != 0) {
        return result;
    }

    // Generate output filename
    string outputFile = inputFile;
    size_t dotPos = outputFile.find_last_of(".");
    if (dotPos != string::npos) {
        outputFile = outputFile.substr(0, dotPos);
    }
    outputFile += ".rsk";

    // Write the output
    ofstream outFile(outputFile.c_str());
    if (!outFile) {
        cerr << "Operational error: cannot create output file" << endl;
        return OPERATIONAL_ERROR;
    }

    outFile << getGeneratedCode();
    outFile.close();

    return 0;
}
