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

The C-- grammar is defined using non-terminal symbols. Each non-terminal represents a syntactic category in the language.

#### **Program Structure Non-Terminals**

##### `PROGRAM`
**Purpose:** The root of the entire parse tree - represents a complete C-- program.

**Grammar Rule:**
```c
PROGRAM:
    FDEFS  // A program is a collection of function definitions
```

**Example:** Any valid C-- file.

---

##### `FDEFS` (Function Definitions)
**Purpose:** A list of function definitions and/or declarations. Can be empty.

**Grammar Rules:**
```c
FDEFS:
    FDEFS FUNC_DEF_API BLK      // Add a function definition (signature + body)
    | FDEFS FUNC_DEC_API         // Add a function declaration (signature only)
    | /* empty */                // Or no functions at all
```

**Examples:**
```c
int foo();           // ← FUNC_DEC_API (declaration)
void bar() { }       // ← FUNC_DEF_API + BLK (definition)
```

**Note:** Recursive structure to handle multiple functions.

---

##### `FUNC_DEC_API` (Function Declaration API)
**Purpose:** Function declaration (prototype) - signature with semicolon, no body.

**Grammar Rules:**
```c
FUNC_DEC_API:
    TYPE ID LPAREN RPAREN SEMICOLON                    // int foo();
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN SEMICOLON     // int foo(x:int);
```

**Examples:**
```c
int calculate();
float add(a:int, b:int);
```

---

##### `FUNC_DEF_API` (Function Definition API)
**Purpose:** Function definition signature - without the body (body comes as BLK separately).

**Grammar Rules:**
```c
FUNC_DEF_API:
    TYPE ID LPAREN RPAREN                    // int main()
    | TYPE ID LPAREN FUNC_ARGLIST RPAREN     // int add(x:int, y:int)
```

**Example:**
```c
void main()  // ← This is FUNC_DEF_API
{            // ← This is BLK (follows separately)
    x:int;
}
```

**Note:** No semicolon because body follows immediately.

---

##### `FUNC_ARGLIST` (Function Argument List)
**Purpose:** The parameters inside function declaration/definition parentheses.

**Grammar Rules:**
```c
FUNC_ARGLIST:
    FUNC_ARGLIST COMMA DCL    // Multiple parameters: x:int, y:float
    | DCL                     // Single parameter: x:int
```

**Example:**
```c
void foo(x:int, y:float, z:int)
         ↑_________________________↑
              FUNC_ARGLIST
```

---

##### `BLK` (Block)
**Purpose:** A code block enclosed in braces containing statements.

**Grammar Rule:**
```c
BLK:
    LBRACE STLIST RBRACE    // { statements }
```

**Example:**
```c
{
    x:int;
    x = 5;
    write(x);
}
```

---

##### `DCL` (Declaration)
**Purpose:** Variable declaration(s) with type annotation.

**Grammar Rules:**
```c
DCL:
    ID COLON TYPE          // Single: x:int
    | ID COMMA DCL         // Multiple: x, y, z:int
```

**Examples:**
```c
x:int;              // Single declaration
x, y, z:float;      // Multiple declarations (recursive pattern)
```

---

##### `TYPE`
**Purpose:** Data type keyword (int, float, void).

**Grammar Rules:**
```c
TYPE:
    INT     // int
    | FLOAT // float
    | VOID  // void
```

**Examples:**
```c
int x;      // TYPE = int
float y;    // TYPE = float
void foo(); // TYPE = void
```

---

#### **Statement Non-Terminals**

##### `STLIST` (Statement List)
**Purpose:** A sequence of zero or more statements.

**Grammar Rules:**
```c
STLIST:
    STLIST STMT     // One or more statements
    | /* empty */   // Or no statements
```

**Example:**
```c
x:int;       // ← STMT
x = 5;       // ← STMT
write(x);    // ← STMT
```

**Structure:** Builds nested STLIST nodes, each containing one STMT.

---

##### `STMT` (Statement)
**Purpose:** Any single statement - the "workhorse" of the language.

**Grammar Rules:**
```c
STMT:
    DCL SEMICOLON       // Declaration: x:int;
    | ASSN              // Assignment: x = 5;
    | EXP SEMICOLON     // Expression: foo();
    | CNTRL             // Control: if/while
    | READ_STMT         // Input: read(x);
    | WRITE_STMT        // Output: write(x);
    | RETURN_STMT       // Return: return x;
    | BLK               // Block: { ... }
```

**Examples:**
```c
x:int;              // Declaration statement
x = 42;             // Assignment statement
foo();              // Expression statement
if (x > 0) then ... // Control statement
```

---

##### `RETURN_STMT`
**Purpose:** Return statement to exit a function (with or without a value).

**Grammar Rules:**
```c
RETURN_STMT:
    RETURN EXP SEMICOLON    // return x + 5;
    | RETURN SEMICOLON      // return;
```

**Examples:**
```c
return 42;      // With value
return x + y;   // With expression
return;         // Without value (void functions)
```

---

##### `WRITE_STMT`
**Purpose:** Output statement to print to console.

**Grammar Rules:**
```c
WRITE_STMT:
    WRITE LPAREN EXP RPAREN SEMICOLON     // write(x + 5);
    | WRITE LPAREN STR RPAREN SEMICOLON   // write("Hello");
```

**Examples:**
```c
write(42);
write(x + y);
write("Hello, World!");
```

**Note:** Can print either expressions or string literals.

---

##### `READ_STMT`
**Purpose:** Input statement to read from console into a variable.

**Grammar Rule:**
```c
READ_STMT:
    READ LPAREN LVAL RPAREN SEMICOLON    // read(x);
```

**Examples:**
```c
read(x);      // Read value into variable x
read(result); // Read value into variable result
```

**Note:** Can only read into an LVAL (left-value = variable).

---

##### `ASSN` (Assignment)
**Purpose:** Assignment statement - store a value in a variable.

**Grammar Rule:**
```c
ASSN:
    LVAL ASSIGN EXP SEMICOLON    // x = expression;
```

**Examples:**
```c
x = 42;
y = x + 5;
result = foo(10);
```

---

##### `LVAL` (Left-Value)
**Purpose:** Something that can appear on the left side of an assignment.

**Grammar Rule:**
```c
LVAL:
    ID    // Just an identifier (variable name)
```

**Examples:**
```c
x = 5;      // x is the LVAL
result = 10; // result is the LVAL
```

**Note:** Separate from ID for future expansion (arrays, pointers, etc.)

---

##### `CNTRL` (Control Flow)
**Purpose:** Control flow statements (if/while).

**Grammar Rules:**
```c
CNTRL:
    IF BEXP THEN STMT ELSE STMT    // if-then-else
    | IF BEXP THEN STMT             // if-then
    | WHILE BEXP DO STMT            // while loop
```

**Examples:**
```c
if (x > 0) then write(x) else write(0);

while (x > 0) do x = x - 1;
```

**Note:** C-- requires `then` and `do` keywords (unlike C).

---

#### **Expression Non-Terminals**

##### `BEXP` (Boolean Expression)
**Purpose:** An expression that evaluates to true or false (used in conditions).

**Grammar Rules:**
```c
BEXP:
    BEXP OR BEXP              // a || b
    | BEXP AND BEXP           // a && b
    | NOT BEXP                // !a
    | EXP RELOP EXP           // a < b, a == b, a != b
    | LPAREN BEXP RPAREN      // (a && b)
```

**Examples:**
```c
x > 0                    // Comparison
x > 0 && y < 10         // AND
!(x == 0)               // NOT
(x > 0) || (y > 0)      // OR with parentheses
```

**Used in:** `if` conditions, `while` conditions.

---

##### `EXP` (Expression)
**Purpose:** An expression that computes a value (number, variable, calculation, function call).

**Grammar Rules:**
```c
EXP:
    EXP ADDOP EXP                    // a + b, a - b
    | EXP MULOP EXP                  // a * b, a / b
    | LPAREN EXP RPAREN              // (a + b)
    | LPAREN TYPE RPAREN EXP         // (int)x  [type cast]
    | ID                             // variable
    | NUM                            // number
    | CALL                           // function call
```

**Examples:**
```c
42                // Number
x                 // Variable
x + 5             // Addition
x * (y + 2)       // Complex expression
foo(10)           // Function call
(float)x          // Type cast
```

---

##### `NUM` (Number)
**Purpose:** A numeric literal (integer or real number).

**Grammar Rules:**
```c
NUM:
    INTEGERNUM    // 42, 123, 0
    | REALNUM     // 3.14, 0.5, 10.0
```

**Examples:**
```c
42      // Integer
3.14    // Real number
0       // Zero
```

---

##### `CALL` (Function Call)
**Purpose:** A function call expression.

**Grammar Rule:**
```c
CALL:
    ID LPAREN CALL_ARGS RPAREN    // functionName(arguments)
```

**Examples:**
```c
foo()                    // No arguments
add(5, 10)              // Positional arguments
create(x:10, y:20)      // Named arguments
mix(5, 10, z:30)        // Mixed arguments
```

---

##### `CALL_ARGS` (Call Arguments)
**Purpose:** The arguments passed to a function call. Can be empty, positional, named, or mixed.

**Grammar Rules:**
```c
CALL_ARGS:
    /* empty */                           // foo()
    | POS_ARGLIST                         // foo(1, 2)
    | NAMED_ARGLIST                       // foo(x:1, y:2)
    | POS_ARGLIST COMMA NAMED_ARGLIST     // foo(1, 2, x:3)
```

**Examples:**
```c
foo()              // No arguments
foo(1, 2, 3)       // Positional only
foo(x:1, y:2)      // Named only
foo(1, 2, x:3, y:4) // Mixed (positional first!)
```

**Rule:** Positional arguments must come before named arguments.

---

##### `POS_ARGLIST` (Positional Argument List)
**Purpose:** List of arguments passed by position (like in C).

**Grammar Rules:**
```c
POS_ARGLIST:
    EXP                       // Single argument
    | POS_ARGLIST COMMA EXP   // Multiple arguments
```

**Examples:**
```c
foo(42)              // One argument
foo(1, 2, 3)         // Three arguments
foo(x+5, y*2, 10)    // Expressions as arguments
```

---

##### `NAMED_ARGLIST` (Named Argument List)
**Purpose:** List of arguments passed by name (like Python's keyword arguments).

**Grammar Rules:**
```c
NAMED_ARGLIST:
    NAMED_ARG                        // Single named argument
    | NAMED_ARGLIST COMMA NAMED_ARG  // Multiple named arguments
```

**Examples:**
```c
foo(x:10)                // One named argument
foo(x:10, y:20)          // Two named arguments
foo(a:5, b:10, c:15)     // Three named arguments
```

---

##### `NAMED_ARG` (Named Argument)
**Purpose:** A single argument with a name (parameter name : value).

**Grammar Rule:**
```c
NAMED_ARG:
    ID COLON EXP    // name:value
```

**Examples:**
```c
x:10              // Simple value
width:100         // Parameter name with value
result:foo(5)     // Expression as value
```

---

#### **Non-Terminal Summary Table**

| **Symbol** | **Category** | **Purpose** | **Example** |
|-----------|-------------|-----------|-----------|
| `PROGRAM` | Structure | Root of entire program | whole file |
| `FDEFS` | Structure | List of functions | all functions |
| `FUNC_DEC_API` | Function | Function declaration | `int foo();` |
| `FUNC_DEF_API` | Function | Function signature | `int foo()` (before `{`) |
| `FUNC_ARGLIST` | Function | Parameter list | `x:int, y:float` |
| `BLK` | Structure | Code block | `{ statements }` |
| `DCL` | Declaration | Variable declaration | `x:int;` |
| `TYPE` | Type | Data type | `int`, `float`, `void` |
| `STLIST` | Structure | List of statements | multiple statements |
| `STMT` | Statement | Any statement | declaration, assignment, etc. |
| `RETURN_STMT` | Statement | Return from function | `return x;` |
| `WRITE_STMT` | I/O | Output statement | `write(42);` |
| `READ_STMT` | I/O | Input statement | `read(x);` |
| `ASSN` | Statement | Assignment | `x = 5;` |
| `LVAL` | Expression | Left-value (variable) | `x` in `x = 5` |
| `CNTRL` | Statement | Control flow | `if`, `while` |
| `BEXP` | Expression | Boolean expression | `x > 0 && y < 10` |
| `EXP` | Expression | Value expression | `x + 5`, `foo()` |
| `NUM` | Expression | Numeric literal | `42`, `3.14` |
| `CALL` | Expression | Function call | `foo(1, 2)` |
| `CALL_ARGS` | Function | Call arguments | `1, 2, x:3` |
| `POS_ARGLIST` | Function | Positional args | `1, 2, 3` |
| `NAMED_ARGLIST` | Function | Named args | `x:1, y:2` |
| `NAMED_ARG` | Function | Single named arg | `x:10` |

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
