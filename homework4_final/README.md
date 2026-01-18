# C-- Compiler - Part 3
## EE046266 Compilation Methods - Winter 2025-2026

This is a complete implementation of a compiler for the C-- language that generates Riski machine code.

## Features

- **Lexical Analysis**: Tokenizes C-- source code
- **Syntax Analysis**: Parses the token stream using a context-free grammar
- **Semantic Analysis**: Type checking, scope management, and symbol table
- **Code Generation**: Generates Riski assembly code (.rsk files)
- **Function Support**: Function declarations, definitions, and calls
- **Control Flow**: if-then-else, while loops
- **Expressions**: Arithmetic and relational operators
- **I/O**: read() and write() functions

## Building the Compiler

To build the compiler, run:
```bash
make
```

This will create the `rx-cc` executable.

## Usage

To compile a C-- source file:
```bash
./rx-cc <input_file.cmm>
```

For example:
```bash
./rx-cc examples/example1.cmm
```

This will generate `example1.rsk` containing the Riski machine code.

## Linking Multiple Modules

If you have multiple source files, compile each one:
```bash
./rx-cc myprog.cmm
./rx-cc extra_funcs.cmm
```

Then link them using the provided linker:
```bash
./rx-linker myprog.rsk extra_funcs.rsk
```

This creates `myprog.e` which can be executed.

## Running the Executable

Use the Riski virtual machine:
```bash
./rx-vm myprog.e
```

## Implementation Details

### File Structure

- `part3.lex`: Flex lexer specification
- `part3.y`: Bison parser specification with code generation
- `part3_helpers.hpp/cpp`: Helper classes and functions
- `rx-cc.cpp`: Main compiler driver
- `makefile`: Build configuration

### Code Generation Strategy

1. **Symbol Table**: Tracks variables with their types, scopes, and memory offsets
2. **Function Table**: Tracks functions with their signatures and implementations
3. **Register Allocation**: Simple register allocation strategy
4. **Backpatching**: Used for control flow (if-then-else, while loops)
5. **Stack Frame**: Standard calling convention with frame pointers

### Register Usage

- `I0`: Return value register
- `I1`: Frame pointer (FP)
- `I2`: Stack pointer (SP)
- `I3-I30`: General purpose registers

### Memory Layout

- Stack grows upward (increasing addresses)
- Local variables and parameters stored on stack
- Each variable/parameter uses 4 bytes

## Testing

Run the test examples:
```bash
make test
```

Or manually test:
```bash
./rx-cc examples/example1.cmm
./rx-vm examples/example1.e < examples/example1.in
```

## Error Handling

The compiler provides error messages for:
- **Lexical errors**: Invalid tokens
- **Syntax errors**: Grammar violations
- **Semantic errors**: Type mismatches, undeclared variables, etc.

All errors include line numbers for easy debugging.

## Examples

See the `examples/` directory for sample C-- programs:
- `example1.cmm`: Simple integer counting
- `example2.cmm`: Recursive function (power)
- `example3-*.cmm`: Multi-module program
- More examples demonstrating various language features

## Notes

- This implementation follows the project specifications in `project-part3_th_v0.pdf`
- The Riski instruction set is documented in the project PDF
- Function declarations must appear before their use
- The `main` function is the entry point

## Clean Up

To remove generated files:
```bash
make clean
```
