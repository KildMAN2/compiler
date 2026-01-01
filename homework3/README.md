# C-- Compiler - Part 3
## EE046266 Compilation Methods - Winter 2025-2026

This is a compiler for the C-- language that generates Riski machine code.

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

## Language Features

### Named Parameters
Functions can be called with named parameters (Python-style):
```c
func(a:10, b:20)        // Named parameters
func(10, b:20)          // Mixed: positional then named
func(10, 20)            // All positional
```

Rules:
- Positional parameters must come before named parameters
- Each parameter must be provided exactly once
- Named parameters must match function declaration

### Type System
- Types: `int`, `float`, `void`
- Explicit type casting required: `(float)x`
- No implicit conversions between types
- `void` only for function return types

### Operators
- Arithmetic: `+`, `-`, `*`, `/`
- Relational: `==`, `<>`, `<`, `<=`, `>`, `>=`
- Logical: `and`, `or`, `not`

### Control Structures
- `if-then-else` (else is optional)
- `while-do` loops
- `return` statements

### I/O
- `read(variable)` - read from input
- `write(expression)` - write to output
- `write("string")` - write string literal

## File Structure

- `part3.lex` - Lexical analyzer
- `part3.y` - Parser and code generator
- `part3_helpers.hpp` - Helper classes and functions
- `part3_helpers.cpp` - Helper implementations
- `rx-cc.cpp` - Main compiler program
- `makefile` - Build configuration

## Riski Machine Code

The compiler generates code for the Riski virtual machine with:
- Register-based operations
- Function calls with stack-based parameter passing
- Integer and floating-point arithmetic
- Conditional and unconditional jumps

## Error Handling

The compiler reports:
- Lexical errors (unrecognized characters)
- Syntax errors (grammar violations)
- Semantic errors (type mismatches, undeclared variables, etc.)
- Operational errors (file I/O issues)

## Clean Up

To remove generated files:
```bash
make clean
```

## Testing

Run the test:
```bash
make test
```

## Examples

See the `examples/` directory for sample C-- programs.
