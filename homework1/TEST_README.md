# C-- Parser Test Scripts

This directory contains automated test scripts to verify the parser implementation.

## Test Scripts

### For Linux/Mac: `test_parser.sh`

**Make executable:**
```bash
chmod +x test_parser.sh
```

**Run tests:**
```bash
./test_parser.sh
```

### For Windows: `test_parser.bat`

**Run tests:**
```cmd
test_parser.bat
```

## What the Scripts Do

1. **Check Prerequisites**
   - Verifies `part2` executable exists
   - Verifies `examples/` directory exists

2. **Test Valid Programs**
   - Runs parser on `example1.cmm`, `example2.cmm`, `example3.cmm`
   - Compares output with expected `.tree` files
   - Reports PASS/FAIL for each test

3. **Test Error Cases**
   - Runs parser on `*err*.cmm` files
   - Verifies parser exits with error code 1 (lexical) or 2 (syntax)
   - Reports PASS if error is correctly detected

4. **Summary Report**
   - Total tests run
   - Number passed
   - Number failed
   - Exit code 0 if all pass, 1 if any fail

## Output Examples

**Successful test:**
```
Testing example1 ... PASS
Testing example2 ... PASS
Testing example3 ... PASS
Testing example-err ... PASS (error detected with exit code 2)

==========================================
           Test Results
==========================================
Total tests:  4
Passed:       4
Failed:       0

All tests passed! ✓
```

**Failed test:**
```
Testing example1 ... FAIL (output differs from expected)
  Expected: examples/example1.tree
  Got:      examples/example1.out
  Run 'diff examples/example1.tree examples/example1.out' to see differences
```

## Debugging Failed Tests

When a test fails, the script keeps the output file (`.out`) so you can compare:

**Linux/Mac:**
```bash
diff examples/example1.tree examples/example1.out
```

**Windows:**
```cmd
fc examples\example1.tree examples\example1.out
```

## Adding New Tests

1. Add your `.cmm` file to `examples/` directory
2. Run parser manually to generate expected output:
   ```bash
   ./part2 < examples/mytest.cmm > examples/mytest.tree
   ```
3. Verify the output is correct
4. Run test script - it will automatically detect new `.cmm` files

## Notes

- Valid programs should have `.cmm` extension and corresponding `.tree` expected output
- Error cases should have `err` in the filename (e.g., `example-err.cmm`)
- The script automatically cleans up `.out` files for passed tests
- Failed test outputs are kept for debugging
