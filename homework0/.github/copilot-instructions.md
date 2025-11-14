# Copilot Instructions - Lexical Analyzer Project

## Project Overview
This is a compiler course homework implementing a lexical analyzer (lexer/scanner) using Flex (Fast Lexical Analyzer). The lexer tokenizes a simple C-like programming language and outputs formatted tokens.

## Build and Run Workflow
```bash
# Build the lexer (generates lex.yy.c and compiles to homework0 executable)
make homework0

# Run on input (redirect or pipe input)
./homework0 < input.txt

# Clean build artifacts
make clean
```

## Language Being Tokenized
The lexer recognizes:
- **Reserved words**: int, float, void, write, read, while, do, if, then, else, return
- **Operators**: Relational (==, <>, <=, >=, <, >), arithmetic (+, -, *, /), logical (&&, ||, !), assignment (=)
- **Tokens**: Identifiers (`[a-zA-Z][a-zA-Z0-9_]*`), integers, real numbers, strings
- **Comments**: Lines starting with `#` are ignored
- **Symbols**: Parentheses, braces, punctuation preserved literally

## Token Output Format
- Reserved words: `<keyword>` (e.g., `<int>`, `<while>`)
- Identifiers: `<id,name>` (e.g., `<id,counter>`)
- Numbers: `<integernum,value>` or `<realnum,value>`
- Strings: `<str,content>` (quotes stripped)
- Operators: `<type,symbol>` (e.g., `<relop,==>`, `<addop,+>`)
- Symbols: Output literally (e.g., `(`, `;`)
- Whitespace: Preserved in output

## Key Patterns
- **Line tracking**: `line_number` variable increments on newlines for error reporting
- **Error handling**: Unrecognized characters print error with line number and exit(1)
- **String processing**: Manually strips surrounding quotes in output
- **Flex directives**: `%option noyywrap` (single file mode), macro definitions section before rules

## When Modifying
- Add new tokens in appropriate section (reserved words, symbols, or macros)
- Follow existing output format conventions
- Test error handling with invalid input
- Verify whitespace preservation for readability
- Windows compatibility: handles both `\n` and `\r\n` line endings
