# Manual Testing Guide for Part 2

## Quick Test Commands

### 1. Compile the parser
```bash
make clean
make
```

### 2. Test a valid program
```bash
./part2 < examples/example1.cmm
```
Should output the parse tree (lots of nested nodes).

### 3. Test syntax error goes to STDOUT (not stderr)
```bash
./part2 < examples/example-err.cmm 2>&1 | tee test_result.txt
```
Should show: `Syntax error: '21' in line number 3`

**Critical test - redirect stderr separately:**
```bash
./part2 < examples/example-err.cmm > stdout.txt 2> stderr.txt
cat stdout.txt  # Should contain the error message
cat stderr.txt  # Should be EMPTY
```

### 4. Test lexical error goes to STDOUT
```bash
echo 'void main() { x = @; }' | ./part2
```
Should show: `Lexical error: '@' in line number 1`

### 5. Compare with expected output
```bash
./part2 < examples/example1.cmm > my_output.txt
diff examples/example1.tree my_output.txt
```
No output means perfect match!

### 6. Run comprehensive tests
```bash
bash test_comprehensive.sh
```

## What the Fixes Changed

### Before Fixes:
- ❌ Errors went to `stderr` → tests failed redirect checks
- ❌ Tree sibling links broken → wrong tree structure
- ❌ Expression trees incomplete → nested expressions failed

### After Fixes:
- ✅ All errors go to `stdout` 
- ✅ Proper sibling traversal in all rules
- ✅ Correct tree structure for complex expressions

## Key Test Points

1. **Error Output Location**: Must be `stdout`, not `stderr`
2. **Error Format**: `Syntax error: '<token>' in line number <n>`
3. **Tree Structure**: All siblings properly linked
4. **Expression Nesting**: Binary ops (ADDOP, MULOP, RELOP, AND, OR) properly chained

## Example Test Session

```bash
# Quick sanity check
make && ./part2 < examples/example1.cmm | head -20

# Verify error to stdout
./part2 < examples/example-err.cmm > out.txt 2> err.txt
# err.txt should be empty!
cat err.txt
# out.txt should have: Syntax error: '21' in line number 3
cat out.txt

# Run all tests
bash test_comprehensive.sh
```
