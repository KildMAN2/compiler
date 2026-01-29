# Bug Tests for Compiler Issues

This directory contains test cases for known bugs in the compiler.

## Test Categories

### 1. Void Parameter Tests
**Issue**: No validation that function parameters cannot be void type  
**Tests**:
- `test_void_param.cmm` - Single void parameter
- `test_void_param2.cmm` - Multiple parameters with one void
- `test_void_param3.cmm` - Grouped parameters with void type

**Expected Behavior**: Should produce semantic error  
**Current Behavior**: Allows void parameters without error

### 2. Recursive Function Return Value Tests
**Issue**: Problems with return values in recursive functions  
**Tests**:
- `test_recursive_return.cmm` - Factorial with int return
- `test_recursive_return2.cmm` - Power function with float return
- `test_recursive_fibonacci.cmm` - Fibonacci with multiple recursive calls

**Expected Behavior**: Recursive functions should correctly return and propagate values  
**Current Behavior**: May have issues with return value handling in recursive contexts

### 3. Type Mismatch Error Classification Tests
**Issue**: Type mismatches reported as syntax errors instead of semantic errors  
**Tests**:
- `test_type_mismatch_semantic.cmm` - Type mismatch in arithmetic expression
- `test_type_mismatch_semantic2.cmm` - Type mismatch in comparison

**Expected Behavior**: Should report "Semantic error: Type mismatch"  
**Current Behavior**: May report "Syntax error" instead

### 4. Float Equality Assembly Bug Tests
**Issue**: Float equality comparison uses SEQLF instead of SEQEF instruction  
**Tests**:
- `test_float_equality_seqlf.cmm` - Basic float equality check
- `test_float_equality_complex.cmm` - Multiple float equality comparisons

**Expected Behavior**: Should generate SEQEF instruction for float equality  
**Current Behavior**: Generates SEQLF instruction (note: this didn't affect grading)

## Running the Tests

### For Semantic Error Tests (void params, type mismatch):
```bash
cd homework4_final/bug_tests
../rx-cc test_void_param.cmm 2>&1 | head -n 1
../rx-cc test_type_mismatch_semantic.cmm 2>&1 | head -n 1
```

### For Runtime Tests (recursive functions, float equality):
```bash
cd homework4_final/bug_tests
../rx-cc test_recursive_return.cmm -o test_recursive_return.rsk
../rx-vm test_recursive_return.rsk < test_recursive_return.in > output.txt
diff output.txt test_recursive_return.e
```

### Check Assembly Output (SEQLF bug):
```bash
../rx-cc test_float_equality_seqlf.cmm -o test.rsk
cat test.rsk | grep -i "SEQ"
# Look for SEQLF (bug) vs SEQEF (correct)
```

## Notes

- Void parameter tests should fail compilation with semantic errors
- Recursive return tests should produce correct output if working
- Type mismatch tests should show "Semantic error" not "Syntax error"
- Float equality tests work but generate incorrect assembly mnemonic
