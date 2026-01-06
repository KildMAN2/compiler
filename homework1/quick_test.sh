#!/bin/bash
# Quick test script to verify parser fixes

echo "==================================="
echo "Testing Part 2 Parser"
echo "==================================="

# Compile first
echo ""
echo "1. Compiling..."
make clean > /dev/null 2>&1
make > /dev/null 2>&1

if [ ! -f "./part2" ]; then
    echo "❌ Compilation failed!"
    exit 1
fi
echo "✓ Compilation successful"

# Test 1: Valid program
echo ""
echo "2. Testing valid program (example1.cmm)..."
./part2 < examples/example1.cmm > test_output.txt 2>&1
if diff -q test_output.txt examples/example1.tree > /dev/null 2>&1; then
    echo "✓ Valid program test PASSED"
else
    echo "❌ Valid program test FAILED"
    echo "Expected vs Got:"
    diff examples/example1.tree test_output.txt | head -20
fi

# Test 2: Syntax error - check stdout
echo ""
echo "3. Testing syntax error goes to STDOUT..."
./part2 < examples/example-err.cmm > test_error.txt 2> test_stderr.txt
if [ -s test_stderr.txt ]; then
    echo "❌ Error went to STDERR (should be STDOUT)!"
    cat test_stderr.txt
else
    if diff -q test_error.txt examples/example-err.tree > /dev/null 2>&1; then
        echo "✓ Syntax error to STDOUT test PASSED"
    else
        echo "❌ Error message format incorrect"
        echo "Expected:"
        cat examples/example-err.tree
        echo "Got:"
        cat test_error.txt
    fi
fi

# Test 3: Lexical error - check stdout
echo ""
echo "4. Testing lexical error goes to STDOUT..."
echo 'void main() { x = @; }' > test_lex_error.cmm
./part2 < test_lex_error.cmm > test_lex_out.txt 2> test_lex_err.txt
if [ -s test_lex_err.txt ]; then
    echo "❌ Lexical error went to STDERR (should be STDOUT)!"
    cat test_lex_err.txt
else
    if grep -q "Lexical error" test_lex_out.txt; then
        echo "✓ Lexical error to STDOUT test PASSED"
    else
        echo "❌ Lexical error not detected properly"
    fi
fi

# Test 4: Expression tree building
echo ""
echo "5. Testing expression tree building..."
cat > test_expr.cmm << 'EOF'
void main() {
    a : int;
    a = 1 + 2 * 3;
}
EOF

./part2 < test_expr.cmm > test_expr_out.txt 2>&1
if grep -q "EXP" test_expr_out.txt && grep -q "addop" test_expr_out.txt && grep -q "mulop" test_expr_out.txt; then
    echo "✓ Expression tree building test PASSED"
else
    echo "❌ Expression tree building test FAILED"
fi

# Cleanup
rm -f test_output.txt test_error.txt test_stderr.txt test_lex_error.cmm test_lex_out.txt test_lex_err.txt test_expr.cmm test_expr_out.txt

echo ""
echo "==================================="
echo "Testing complete!"
echo "==================================="
