/*
    EE046266: Compilation Methods - Winter 2025-2026
    Part 3: Code Generation - Main Compiler Program
*/

#include <iostream>
#include <fstream>
#include <sstream>
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
    
    // Get the buffer output first to calculate line numbers
    string bufferOutput = buffer->printBuffer();

    // Split buffer output into individual lines for validation/mapping
    vector<string> bufferLines;
    {
        istringstream bufferLinesStream(bufferOutput);
        string bufLine;
        while (getline(bufferLinesStream, bufLine)) {
            // buffer->printBuffer() always ends lines with '\n', so getline strips it.
            // Keep empty lines if they ever appear.
            bufferLines.push_back(bufLine);
        }
    }
    
    // Calculate line numbers for each function label in the buffer
    map<string, int> functionLineNumbers;
    istringstream bufferStream(bufferOutput);
    string line;
    int lineNum = 5; // Header takes lines 1-4: <header>, <unimplemented>..., <implemented>..., </header>
    while (getline(bufferStream, line)) {
        // Check if this line is a LABEL directive
        if (line.find("LABEL ") == 0) {
            string funcName = line.substr(6); // Extract function name after "LABEL "
            // Remove any trailing whitespace
            funcName.erase(funcName.find_last_not_of(" \t\n\r") + 1);
            functionLineNumbers[funcName] = lineNum;
        }
        lineNum++;
    }
    
    // Generate header for linker
    outFile << "<header>" << endl;
    
    // Call sites to be resolved by the linker.
    // The linker patches the JLINK placeholder at the given line number to the final target.
    outFile << "<unimplemented> ";  // Space after tag is required
    bool firstUnimp = true;
    for (auto& func : functionTable) {
        // Output each call location: funcName,line1 funcName,line2 ...
        for (int callLine : func.second.callingLines) {
            int adjustedCallLine = callLine;

            // Validate the recorded line points to a JLINK instruction in the buffer.
            // callingLines are 1-based indices into the emitted buffer.
            const int idx = adjustedCallLine - 1;
            auto startsWithJlink = [&](int i) -> bool {
                if (i < 0 || i >= (int)bufferLines.size()) return false;
                return bufferLines[i].rfind("JLINK", 0) == 0;
            };

            if (!startsWithJlink(idx) && startsWithJlink(idx + 1)) {
                // Defensive fix for off-by-one recording: move to the actual JLINK line.
                adjustedCallLine++;
            }

            if (!firstUnimp) outFile << " ";
            // Adjust line number to account for header (4 lines)
            outFile << func.first << "," << (adjustedCallLine + 4);
            firstUnimp = false;
        }
    }
    outFile << endl;
    
    // Implemented functions (defined in this file) with their actual line number in output
    outFile << "<implemented> ";  // Space after tag is required
    bool firstImp = true;
    for (auto& func : functionTable) {
        if (func.second.isDefined) {
            if (!firstImp) outFile << " ";
            outFile << func.first << "," << functionLineNumbers[func.first];
            firstImp = false;
        }
    }
    outFile << endl;
    
    outFile << "</header>" << endl;
    
    // Print the generated code
    outFile << bufferOutput;
    outFile.close();
    
    cout << "Compilation successful. Output written to: " << outputFile << endl;
    
    // Clean up
    delete buffer;
    
    return 0;
}
