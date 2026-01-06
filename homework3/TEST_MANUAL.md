# Part 3 Testing Guide

## Quick Test Commands

### 1. Compile the compiler
```bash
make clean
make
```

### 2. Test a valid program
```bash
./rx-cc examples/example1.cmm
cat example1.rsk
```
Should create `example1.rsk` file.

### 3. CRITICAL: Test errors go to STDOUT (not stderr)
```bash
# Create an error test
echo 'void main() { x = @; }' > test_error.cmm

# Test with separate streams
./rx-cc test_error.cmm > stdout.txt 2> stderr.txt

# Check results
cat stderr.txt  # Should be EMPTY
cat stdout.txt  # Should contain the error message
```

### 4. Test with linker and VM
```bash
./rx-cc examples/example1.cmm
./rx-linker example1.rsk
./rx-vm example1.e
```

### 5. Run comprehensive tests
```bash
# Run error output validation
bash test_error_output.sh

# Run all examples
bash test_all.sh

# Run comprehensive feature tests
bash run_comprehensive_tests.sh
```

## What Was Fixed (Following Part 2 Guidelines)

### Before Fixes:
- ❌ Syntax errors went to `stderr`
- ❌ Semantic errors went to `stderr`
- ❌ Lexical errors went to `stderr`

### After Fixes:
- ✅ All errors go to `stdout`
- ✅ Proper error format with line numbers
- ✅ Single `\n` at end of each error
- ✅ Compatible with diff testing

## Key Test Points

1. **Error Output Location**: Must be `stdout`, NOT `stderr`
2. **Error Format**: Should include line numbers
3. **No Output File on Error**: `.rsk` file should not be created on error
4. **Exit Codes**: Non-zero on error

## Critical Tests from Part 2 Guidelines

### 1. Missing/Redundant Newlines ✅
All error messages end with exactly ONE `\n`

### 2. Error Format ✅
```
Syntax error: '<token>' in line <n>
Semantic error in line <n>: <message>
Lexical error: unrecognized character '<char>' in line <n>
```

### 3. Using Given Helpers ✅
Uses Buffer class and helper functions from `part3_helpers.hpp`

### 4. Testing with Diff ✅
Errors to stdout allow proper diff testing

## Example Test Session

```bash
# Quick validation
make clean && make

# Test error output location (MOST IMPORTANT!)
bash test_error_output.sh

# If all critical tests pass, run full suite
bash test_all.sh

# Test linking
./rx-cc examples/example1.cmm
./rx-linker example1.rsk
./rx-vm example1.e
```

## Common Issues to Avoid

1. ❌ Don't use `fprintf(stderr, ...)` for errors
2. ✅ Use `printf(...)` for all error messages
3. ❌ Don't create `.rsk` file on compilation error
4. ✅ Exit with appropriate error code
5. ✅ Always include line numbers in error messages
6. ✅ Use dos2unix on scripts when testing in Linux/VirtualBox

## Notes

- Remember: `dos2unix *.sh` before running scripts in VirtualBox
- The linker is provided and checks for duplicate function definitions
- The VM executes the linked `.e` file
- Test both single-file and multi-file compilation
