# C-- Parser Implementation Documentation
**Project Part 2 - Compilation Methods Course**  
**Student IDs:** 322449539, 323885350

---

## Overview

This project implements a syntax parser for the C-- programming language using Flex (lexical analyzer) and Bison (parser generator). The parser reads C-- source code, performs syntax analysis, builds a parse tree, and outputs the tree structure.

---

## Project Structure

### Files Included

1. **part2.y** - Bison grammar file containing:
   - Grammar rules for C-- language
   - Semantic actions for parse tree construction
   - Operator precedence declarations
   - Error handling

2. **part2.lex** - Flex lexer specification:
   - Token patterns (keywords, identifiers, operators, etc.)
   - Integration with Bison parser
   - Lexical error handling

3. **part2_helpers.c/h** - Helper functions:
   - `makeNode()` - Creates parse tree nodes
   - `concatList()` - Concatenates sibling nodes
   - `dumpParseTree()` - Prints parse tree
   - `main()` - Entry point that calls yyparse()

4. **makefile** - Build automation:
   - Compiles lexer and parser
   - Links all components
   - Produces `part2` executable

---

## Implementation Details

### 1. Parse Tree Structure

Each node in the parse tree is represented by:

```c
typedef struct node {
    char *type;          // Token type or non-terminal name
    char *value;         // Lexeme value (NULL for non-terminals)
    struct node *sibling; // Next sibling (for lists)
    struct node *child;   // First child
} ParserNode;
```

**Tree Organization:**
- **child**: Points to the first child of a node
- **sibling**: Links siblings in left-to-right order
- Non-terminals wrap their production elements as children
- Terminals contain their lexeme value

### 2. Grammar Rules

The C-- grammar includes:

- **Function definitions and declarations**
  - `FUNC_DEF_API` - Function with body
  - `FUNC_DEC_API` - Function signature only

- **Statements**
  - Declarations (`DCL`)
  - Assignments (`ASSN`)
  - Control flow (`if-then-else`, `while-do`)
  - I/O operations (`read`, `write`)
  - Return statements

- **Expressions**
  - Arithmetic operations (`+`, `-`, `*`, `/`)
  - Boolean expressions (`&&`, `||`, `!`)
  - Relational operators (`==`, `<>`, `<`, `>`, `<=`, `>=`)
  - Type casting `(type)expr`
  - Function calls with positional and named arguments

### 3. Operator Precedence

Operators are resolved using Bison precedence declarations (lowest to highest):

```
%right ASSIGN        // Assignment (right-associative)
%left OR             // Logical OR
%left AND            // Logical AND
%left RELOP          // Relational operators
%left ADDOP          // Addition, subtraction
%left MULOP          // Multiplication, division
%right NOT           // Logical NOT
%right CAST          // Type casting
%left LPAREN RPAREN  // Parentheses
```

This follows standard C/C++ operator precedence conventions.

### 4. Semantic Actions

Each grammar rule has semantic actions that:
- Create nodes for non-terminals
- Link children and siblings properly
- Wrap non-terminals according to C-- specifications
- Handle epsilon (empty) productions

**Example:**
```c
STLIST:
    STLIST STMT
    {
        ParserNode *stlist_inner = makeNode("STLIST", NULL, $1);
        $$ = makeNode("STLIST", NULL, stlist_inner);
        stlist_inner->sibling = $2;
    }
    | /* empty */
    {
        $$ = makeNode("EPSILON", NULL, NULL);
    }
```

### 5. Error Handling

**Lexical Errors:**
- Detected by Flex when invalid characters are encountered
- Format: `Lexical error: '<lexeme>' in line number <line_number>`
- Exit code: 1

**Syntax Errors:**
- Detected by Bison when grammar rules are violated
- Handled by `yyerror()` function
- Format: `Syntax error: '<lexeme>' in line number <line_number>`
- Exit code: 2

**Error Implementation:**
```c
void yyerror(const char *s) {
    fprintf(stderr, "Syntax error: '%s' in line number %d\n", 
            yytext, line_number);
    exit(2);
}
```

---

## Data Structures

### Node Creation Strategy

1. **Terminals** - Created directly from lexer with type and value
2. **Non-terminals** - Wrap their production elements as children
3. **Lists** - Built recursively with proper sibling linking
4. **Empty productions** - Represented by EPSILON nodes

### Memory Management

- All nodes allocated dynamically using `malloc()`
- `strdup()` used for string duplication
- No explicit deallocation (program terminates after tree dump)

---

## Build and Usage

### Building the Parser

```bash
make
```

This generates the `part2` executable.

### Running the Parser

**From stdin:**
```bash
./part2 < input.cmm
```

**From file with redirection:**
```bash
./part2 < example1.cmm > example1.tree
```

### Expected Output

**Successful parse:**
- Prints the parse tree in nested parenthesis format
- Each node shows: `(<type,value>)` or `(<type>)`
- Indentation shows tree depth

**Parse error:**
- Prints error message to stderr
- Exits with appropriate code (1 for lexical, 2 for syntax)

---

## Design Decisions

### 1. Parse Tree Representation

We chose the sibling-child representation because:
- Efficient for variable-length child lists
- Natural for recursive grammar structures
- Easy to traverse and print
- Memory-efficient for deep trees

### 2. Token Value Handling

- Keywords and symbols: type only, no value
- Identifiers: type="id", value=identifier name
- Numbers: type="integernum"/"realnum", value=number
- Strings: type="str", value=string content (without quotes)
- Operators: type includes operator category, value is the operator

### 3. Grammar Ambiguity Resolution

Used Bison precedence declarations instead of grammar rewriting because:
- Maintains grammar readability
- Directly encodes C-- semantics
- Avoids introduction of extra non-terminals
- More maintainable

### 4. EPSILON Nodes

Empty productions create explicit EPSILON nodes to:
- Make parse tree structure complete
- Show where optional elements are absent
- Aid in debugging and understanding parse flow

---

## Assumptions

1. **Input Encoding**: UTF-8 or ASCII text files
2. **Line Endings**: Support both `\n` and `\r\n`
3. **Comments**: Hash `#` to end of line (not inside strings)
4. **String Escapes**: Only `\n`, `\t`, `\"` are valid
5. **Identifiers**: Start with letter, contain letters/digits/underscores
6. **Numbers**: Integers or reals (with mandatory decimal point and digits after)

---

## Testing

### Test Coverage

The implementation was tested with:
- Simple programs (basic declarations, assignments)
- Complex control flow (nested if-while statements)
- Function definitions and declarations
- Function calls with mixed argument styles
- Type casting expressions
- Error cases (lexical and syntax errors)

### Test Files Location

Examples provided in `examples/` directory:
- `example1.cmm` - Complete valid program
- `example2.cmm` - I/O and control flow
- `example3.cmm` - Function calls
- `example-err.cmm` - Syntax error
- `example_err1.cmm` - Additional error case
- `example_err2.cmm` - Additional error case

---

## Limitations and Future Work

### Current Limitations

1. No semantic analysis (type checking, scope resolution)
2. No optimization of parse tree
3. Limited error recovery (stops at first error)
4. No support for include files or modules

### Potential Extensions

1. **Semantic Analyzer** - Add type checking and symbol tables
2. **Intermediate Code Generation** - Convert parse tree to IR
3. **Error Recovery** - Continue parsing after errors
4. **Better Error Messages** - Show context and suggestions
5. **Source Location Tracking** - Track column numbers, not just lines

---

## References

- Bison Manual: https://www.gnu.org/software/bison/manual/
- Flex Manual: https://github.com/westes/flex
- C++ Operator Precedence: http://en.cppreference.com/w/cpp/language/operator_precedence
- Course materials: Project Part 2 specification

---

## Compilation Environment

**Target Platform:** Linux Virtual Machine (provided by course)  
**Compiler:** GCC
**Tools:** Flex 2.6+, Bison 3.0+  
**Build System:** GNU Make

---

*End of Documentation*
