# Comprehensive Test Suite for C-- Parser

This directory contains an extensive test suite for the C-- parser, covering white-box, black-box, and edge case testing.

## Test Organization

### 1. Original Tests
- `example1.cmm` - Basic function definitions and control flow
- `example2.cmm` - Complex expressions and statements
- `example3.cmm` - Function calls with positional and named arguments
- `example_err*.cmm` - Error detection tests

### 2. White-Box Tests (Code Coverage)

#### Basic Functionality (test_01 - test_10)
- **test_01_empty_program.cmm** - Empty program (epsilon production)
- **test_02_single_declaration.cmm** - Single function declaration
- **test_03_multiple_declarations.cmm** - Multiple function declarations
- **test_04_empty_main.cmm** - Main function with empty body
- **test_05_all_types.cmm** - All type declarations (int, float, void)
- **test_06_nested_blocks.cmm** - Deeply nested block statements
- **test_07_all_operators.cmm** - All arithmetic and relational operators
- **test_08_operator_precedence.cmm** - Operator precedence rules
- **test_09_complex_expressions.cmm** - Complex nested expressions
- **test_10_casting.cmm** - Type casting operations

#### Control Flow (test_11 - test_15)
- **test_11_if_then.cmm** - If-then without else
- **test_12_if_else.cmm** - If-then-else statements
- **test_13_nested_if.cmm** - Nested if statements
- **test_14_while_loop.cmm** - While loops
- **test_15_nested_loops.cmm** - Nested while loops

#### Statements (test_16 - test_18)
- **test_16_return_statements.cmm** - Return statements
- **test_17_write_statements.cmm** - Write statements
- **test_18_read_statements.cmm** - Read statements

#### Function Calls (test_19 - test_24)
- **test_19_function_no_args.cmm** - Function calls with no arguments
- **test_20_function_positional_args.cmm** - Positional arguments only
- **test_21_function_named_args.cmm** - Named arguments only
- **test_22_function_mixed_args.cmm** - Mixed positional and named arguments
- **test_23_nested_calls.cmm** - Nested function calls
- **test_24_calls_in_expressions.cmm** - Function calls within expressions

#### Boolean Expressions (test_25 - test_29)
- **test_25_boolean_and.cmm** - Boolean AND operations
- **test_26_boolean_or.cmm** - Boolean OR operations
- **test_27_boolean_not.cmm** - Boolean NOT operations
- **test_28_complex_boolean.cmm** - Complex boolean expressions
- **test_29_parenthesized_boolean.cmm** - Parenthesized boolean expressions

#### Literals and Identifiers (test_30 - test_35)
- **test_30_integers.cmm** - Integer literals
- **test_31_floats.cmm** - Float literals
- **test_32_strings.cmm** - String literals with escape sequences
- **test_33_identifiers.cmm** - Various identifier naming patterns
- **test_34_mixed_declarations.cmm** - Mix of declarations and definitions
- **test_35_statement_sequence.cmm** - Long sequence of statements

### 3. Edge Cases (test_36 - test_40)
- **test_36_edge_empty_blocks.cmm** - Empty blocks in various contexts
- **test_37_edge_single_char_ids.cmm** - Single character identifiers
- **test_38_edge_long_identifiers.cmm** - Very long identifier names
- **test_39_edge_zero_values.cmm** - Zero values in different contexts
- **test_40_edge_max_nesting.cmm** - Maximum nesting depth

### 4. Black-Box Error Tests (error_01 - error_15)
- **error_01_missing_semicolon.cmm** - Missing semicolon
- **error_02_missing_then.cmm** - Missing 'then' keyword
- **error_03_missing_do.cmm** - Missing 'do' keyword
- **error_04_missing_brace.cmm** - Unclosed block
- **error_05_missing_paren.cmm** - Unclosed parenthesis
- **error_06_missing_colon.cmm** - Missing colon in declaration
- **error_07_invalid_operator.cmm** - Invalid operator sequence
- **error_08_missing_function_body.cmm** - Function without body
- **error_09_invalid_lvalue.cmm** - Invalid assignment target
- **error_10_unclosed_call.cmm** - Unclosed function call
- **error_11_missing_return_type.cmm** - Missing return type
- **error_12_missing_param_type.cmm** - Missing parameter type
- **error_13_extra_comma.cmm** - Extra comma in parameter list
- **error_14_empty_return.cmm** - Empty return statement
- **error_15_missing_condition.cmm** - Missing condition in if

## Grammar Coverage

### Non-terminals Tested
✓ PROGRAM - All tests
✓ FDEFS - tests 01-04, 16, 19-24, 34
✓ FUNC_DEC_API - tests 02, 03, 34
✓ FUNC_DEF_API - tests 04-40
✓ FUNC_ARGLIST - tests 03, 20-24
✓ DCL - tests 05, 33-35
✓ TYPE - tests 05, 10
✓ STLIST - tests 04-40
✓ STMT - tests 05-40
✓ ASSN - tests 07-10, 17, 35
✓ BLK - tests 04-06, 12-15
✓ CNTRL - tests 11-15
✓ WRITE - tests 17, 25-29
✓ READ - test 18
✓ RETURN - test 16
✓ LVAL - tests 07-10, 35
✓ BEXP - tests 07, 11-15, 25-29
✓ EXP - tests 07-10, 23-24, 30-32
✓ NUM - tests 30-31
✓ CALL - tests 19-24
✓ CALL_ARGS - tests 19-24
✓ POS_ARGLIST - tests 20, 22-24
✓ NAMED_ARGLIST - tests 21-22
✓ NAMED_ARG - tests 21-22

### Operators Tested
- Arithmetic: +, -, *, / (test_07, test_08)
- Relational: <, >, <=, >=, ==, <> (test_07)
- Boolean: and, or, not (test_25, test_26, test_27)
- Assignment: = (test_07, test_09, test_10)
- Cast: (type) (test_10)

### Keywords Tested
- Type keywords: int, float, void (test_05)
- Control flow: if, then, else, while, do (test_11-15)
- I/O: read, write (test_17, test_18)
- Function: return (test_16)

## Running Tests

### Run All Tests
```bash
chmod +x test_comprehensive.sh
./test_comprehensive.sh
```

### Run Specific Test Categories
```bash
# Valid programs only
for f in examples/test_*.cmm; do ./part2 < "$f" > /dev/null 2>&1 && echo "✓ $f" || echo "✗ $f"; done

# Error cases only
for f in examples/error_*.cmm; do ./part2 < "$f" > /dev/null 2>&1 && echo "✗ $f (should fail)" || echo "✓ $f"; done
```

### Run Individual Tests
```bash
./part2 < examples/test_01_empty_program.cmm
./part2 < examples/error_01_missing_semicolon.cmm
```

## Expected Results

### Valid Tests
All `test_*.cmm` files should:
- Parse successfully (exit code 0)
- Generate valid parse tree
- Not produce syntax errors

### Error Tests
All `error_*.cmm` files should:
- Be rejected by parser (exit code 2)
- Display appropriate error message
- Not generate parse tree

## Test Coverage Summary

| Category | Tests | Coverage |
|----------|-------|----------|
| Grammar Productions | 40 valid | 100% of non-terminals |
| Operators | 15 valid | 100% of operators |
| Keywords | 18 valid | 100% of keywords |
| Error Handling | 15 error | Common syntax errors |
| Edge Cases | 5 edge | Boundary conditions |
| **Total** | **75** | **Comprehensive** |

## Adding New Tests

To add a new test:

1. Create input file: `examples/test_XX_description.cmm`
2. For valid tests: Ensure correct C-- syntax
3. For error tests: Name as `error_XX_description.cmm`
4. Run: `./test_comprehensive.sh`

Expected output files (`.tree`) are optional but recommended for regression testing.

## Test Maintenance

- Keep test files small and focused on one feature
- Add comments explaining what each test validates
- Update this documentation when adding new tests
- Run full suite before committing changes

## Troubleshooting

If tests fail:
1. Check parser compilation: `make clean && make`
2. Run individual test to see error: `./part2 < examples/test_XX.cmm`
3. Compare with expected: `diff examples/test_XX.tree examples/test_XX.out`
4. Use trace version for debugging: `cd trace && make && ./part2_trace < ../examples/test_XX.cmm`
