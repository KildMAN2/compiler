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
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input_file.cmm>" << endl;
        return 1;
    }

    string inputFile = argv[1];
    yyin = fopen(inputFile.c_str(), "r");
    
    if (!yyin) {
        cerr << "Error: Cannot open file " << inputFile << endl;
        return 1;
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
        cerr << "Error: Cannot create output file " << outputFile << endl;
        return 1;
    }

    outFile << getGeneratedCode();
    outFile.close();

    return 0;
}
