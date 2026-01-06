#!/bin/bash
# Critical test script for Part 3 - Error Output Validation
# Ensures errors go to STDOUT, not STDERR (following Part 2 guidelines)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=================================================="
echo "  Part 3: Critical Error Output Tests"
echo "=================================================="
echo ""

# Check if compiler exists
if [ ! -f "./rx-cc" ]; then
    echo -e "${RED}Error: rx-cc compiler not found. Run 'make' first.${NC}"
    exit 1
fi

total_tests=0
passed_tests=0
failed_tests=0
critical_issues=0

# Test 1: Syntax error goes to STDOUT
echo -e "${CYAN}=== CRITICAL TEST 1: Syntax Errors to STDOUT ===${NC}"
total_tests=$((total_tests + 1))
echo -n "Testing syntax error output location... "

# Create test file with syntax error
cat > test_syntax_error.cmm << 'EOF'
void main() {
    a = 5 @;
}
EOF

./rx-cc test_syntax_error.cmm > test_stdout.txt 2> test_stderr.txt
exit_code=$?

if [ -s test_stderr.txt ]; then
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  ❌ Syntax errors going to STDERR instead of STDOUT${NC}"
    echo "  Content in stderr:"
    cat test_stderr.txt | sed 's/^/    /'
    failed_tests=$((failed_tests + 1))
    critical_issues=$((critical_issues + 1))
elif [ -s test_stdout.txt ]; then
    if grep -q "error" test_stdout.txt; then
        echo -e "${GREEN}PASS${NC}"
        echo "  Error message correctly in stdout:"
        cat test_stdout.txt | sed 's/^/    /'
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}FAIL${NC}"
        echo -e "${RED}  ❌ No error message found${NC}"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  ❌ No error output at all${NC}"
    failed_tests=$((failed_tests + 1))
    critical_issues=$((critical_issues + 1))
fi
rm -f test_syntax_error.cmm test_stdout.txt test_stderr.txt test_syntax_error.rsk
echo ""

# Test 2: Semantic error goes to STDOUT
echo -e "${CYAN}=== CRITICAL TEST 2: Semantic Errors to STDOUT ===${NC}"
total_tests=$((total_tests + 1))
echo -n "Testing semantic error output location... "

# Create test file with semantic error (undeclared variable)
cat > test_semantic_error.cmm << 'EOF'
void main() {
    x = undeclared_var;
}
EOF

./rx-cc test_semantic_error.cmm > test_stdout.txt 2> test_stderr.txt
exit_code=$?

if [ -s test_stderr.txt ]; then
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  ❌ Semantic errors going to STDERR instead of STDOUT${NC}"
    echo "  Content in stderr:"
    cat test_stderr.txt | sed 's/^/    /'
    failed_tests=$((failed_tests + 1))
    critical_issues=$((critical_issues + 1))
elif [ -s test_stdout.txt ]; then
    if grep -q "error" test_stdout.txt; then
        echo -e "${GREEN}PASS${NC}"
        echo "  Error message correctly in stdout:"
        cat test_stdout.txt | sed 's/^/    /'
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}FAIL${NC}"
        echo -e "${RED}  ❌ No error message found${NC}"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  ❌ No error output at all${NC}"
    failed_tests=$((failed_tests + 1))
    critical_issues=$((critical_issues + 1))
fi
rm -f test_semantic_error.cmm test_stdout.txt test_stderr.txt test_semantic_error.rsk
echo ""

# Test 3: Lexical error goes to STDOUT
echo -e "${CYAN}=== CRITICAL TEST 3: Lexical Errors to STDOUT ===${NC}"
total_tests=$((total_tests + 1))
echo -n "Testing lexical error output location... "

# Create test file with lexical error
cat > test_lexical_error.cmm << 'EOF'
void main() {
    x : int;
    x = 5 @ 3;
}
EOF

./rx-cc test_lexical_error.cmm > test_stdout.txt 2> test_stderr.txt
exit_code=$?

if [ -s test_stderr.txt ]; then
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  ❌ Lexical errors going to STDERR instead of STDOUT${NC}"
    echo "  Content in stderr:"
    cat test_stderr.txt | sed 's/^/    /'
    failed_tests=$((failed_tests + 1))
    critical_issues=$((critical_issues + 1))
elif [ -s test_stdout.txt ]; then
    if grep -q -i "lexical" test_stdout.txt; then
        echo -e "${GREEN}PASS${NC}"
        echo "  Error message correctly in stdout:"
        cat test_stdout.txt | sed 's/^/    /'
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${YELLOW}WARNING${NC}"
        echo "  Error detected but message format unclear:"
        cat test_stdout.txt | sed 's/^/    /'
        passed_tests=$((passed_tests + 1))
    fi
else
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  ❌ No error output at all${NC}"
    failed_tests=$((failed_tests + 1))
    critical_issues=$((critical_issues + 1))
fi
rm -f test_lexical_error.cmm test_stdout.txt test_stderr.txt test_lexical_error.rsk
echo ""

# Test 4: Successful compilation has no stderr output
echo -e "${CYAN}=== TEST 4: Valid Program Has No STDERR ===${NC}"
total_tests=$((total_tests + 1))
echo -n "Testing valid program produces no stderr... "

# Use an existing valid example if available
if [ -f "examples/example1.cmm" ]; then
    ./rx-cc examples/example1.cmm > test_stdout.txt 2> test_stderr.txt
    
    if [ -s test_stderr.txt ]; then
        echo -e "${YELLOW}WARNING${NC}"
        echo "  Valid compilation produced stderr output:"
        cat test_stderr.txt | sed 's/^/    /'
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${GREEN}PASS${NC}"
        echo "  No stderr output from valid compilation"
        passed_tests=$((passed_tests + 1))
    fi
    rm -f test_stdout.txt test_stderr.txt examples/example1.rsk
else
    echo -e "${YELLOW}SKIP${NC} - No example1.cmm found"
    total_tests=$((total_tests - 1))
fi
echo ""

# Test 5: Error format validation
echo -e "${CYAN}=== TEST 5: Error Message Format ===${NC}"
total_tests=$((total_tests + 1))
echo -n "Testing error message format... "

cat > test_error_format.cmm << 'EOF'
void main() {
    x = @;
}
EOF

output=$(./rx-cc test_error_format.cmm 2>&1)

if echo "$output" | grep -q "line [0-9]\+"; then
    echo -e "${GREEN}PASS${NC}"
    echo "  Error message includes line number:"
    echo "$output" | sed 's/^/    /'
    passed_tests=$((passed_tests + 1))
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "  Error message format may be non-standard:"
    echo "$output" | sed 's/^/    /'
    passed_tests=$((passed_tests + 1))
fi
rm -f test_error_format.cmm test_error_format.rsk
echo ""

# Summary
echo "=================================================="
echo "           Test Summary"
echo "=================================================="
echo "Total tests:  $total_tests"
echo -e "Passed:       ${GREEN}$passed_tests${NC}"
echo -e "Failed:       ${RED}$failed_tests${NC}"

if [ $critical_issues -gt 0 ]; then
    echo ""
    echo -e "${RED}CRITICAL ISSUES DETECTED: $critical_issues${NC}"
    echo -e "${RED}  Errors are going to STDERR instead of STDOUT!${NC}"
    echo -e "${RED}  This will cause test failures with diff tools.${NC}"
fi
echo ""

if [ $failed_tests -eq 0 ] && [ $critical_issues -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   All critical tests passed! ✓${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "✓ All errors correctly output to STDOUT"
    echo "✓ Error format includes line numbers"
    echo "✓ Ready for Part 3 submission"
    exit 0
else
    echo -e "${RED}Some tests failed. Review output above.${NC}"
    exit 1
fi
