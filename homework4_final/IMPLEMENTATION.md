# C-- Compiler Implementation Summary

## Current Status

The complete compiler has been implemented from scratch in `homework4_final/` with the following components:

### Core Files Created

1. **rx-cc.cpp** - Main compiler driver
   - Opens input file
   - Initializes code generation buffer
   - Calls parser
   - Writes output .rsk file

2. **part3.lex** - Lexical analyzer (Flex)
   - Tokenizes C-- keywords, identifiers, numbers, operators
   - Handles string literals with escape sequences
   - Reports lexical errors with line numbers

3. **part3.y** - Parser and code generator (Bison)
   - Complete grammar for C-- language
   - Symbol table for variables
   - Function table for function declarations/definitions
   - Type checking and semantic analysis
   - Riski code generation with backpatching for control flow

4. **part3_helpers.cpp/hpp** - Helper classes
   - Buffer class for code generation
   - Symbol and Function classes
   - Type definitions
   - Global data structures

5. **makefile** - Build configuration
   - Builds compiler using flex, bison, and g++
   - Includes test targets

6. **README.md** - Documentation

## Implementation Features

### Lexical Analysis
- Keywords: void, int, float, return, if, then, else, while, do, read, write
- Identifiers: [a-zA-Z][a-zA-Z0-9_]*
- Numbers: integers and floating point
- Operators: arithmetic, relational, assignment
- String literals with escape sequences (\n, \t, \r, \0, \", \\)
- Single-line comments (//)

### Syntax Analysis
- Function declarations and definitions
- Variable declarations with type annotations
- Statements: assignments, if-then-else, while loops, return
- Expressions: arithmetic and relational operations
- Function calls with arguments
- I/O: read() and write()

### Semantic Analysis
- Type checking for all operations
- Symbol table with scope management
- Function signature matching
- Undeclared variable/function detection
- Type mismatch detection

### Code Generation
- Riski assembly output (.rsk files)
- Register allocation
- Stack frame management
- Backpatching for control flow
- Function call protocol
- Header section with function information

## Riski Instruction Set Used

### Data Movement
- COPYI, COPYF - Copy immediate values
- LOADI, LOADF - Load from memory
- STORI, STORF - Store to memory

### Arithmetic
- ADD2I, ADD2F - Addition
- SUBTI, SUBTF - Subtraction (also SUB2I)
- MULTI, MULTF - Multiplication
- DIVDI, DIVDF - Division

### Comparison
- SEQUI, SEQLF - Set if equal
- SNEQI, SNEQF - Set if not equal
- SLTTI, SLTTF - Set if less than
- SGRTI, SGRTF - Set if greater than
- SLETI, SLETF - Set if less than or equal
- SGETI, SGETF - Set if greater than or equal

### Control Flow
- UJUMP - Unconditional jump
- BREQZ - Branch if equal to zero
- JLINK - Jump and link (function call)
- RETRN - Return from function

### I/O
- READI, READF - Read integer/float
- PRNTI, PRNTF - Print integer/float
- PRNTC - Print character

## Register Convention

- **I0**: Return value register
- **I1**: Frame pointer (FP)
- **I2**: Stack pointer (SP)
- **I3-I30**: General purpose registers
- **F0-F15**: Floating point registers

## Stack Frame Layout

```
Higher addresses
+-------------------+
| Caller's FP       |  <- FP+0 (saved)
+-------------------+
| Arg N             |
| ...               |
| Arg 1             |
+-------------------+
| Local variable 1  |  <- FP+offset
| Local variable 2  |
| ...               |
+-------------------+
Lower addresses
```

## Header Format

The generated .rsk file starts with:
```
<header>
<unimplemented>
<implemented> func1,paramCount1 func2,paramCount2 ...
</header>
```

## Testing

Test with the provided examples:

```bash
make                                 # Build compiler
./rx-cc examples/example1.cmm        # Generate example1.rsk
./rx-vm examples/example1.e < examples/example1.in  # Run
```

## Known Limitations

The current implementation handles basic features but may need refinement for:
1. Complex register saving/restoring during nested function calls
2. Optimized register allocation
3. Float operations (currently focused on integer operations)
4. Complete header generation with all function signatures

## Next Steps

1. Test the compiler with all provided examples
2. Fix any issues found during testing
3. Optimize register usage
4. Add proper register saving/restoring for function calls
5. Ensure proper header generation

## Build Instructions

```bash
cd homework4_final
make clean
make
```

This generates the `rx-cc` compiler executable.

## Usage

```bash
./rx-cc <source_file.cmm>
```

Output is written to `<source_file>.rsk`

To link and run:
```bash
./rx-linker <file>.rsk         # Creates <file>.e
./rx-vm <file>.e              # Execute
```
