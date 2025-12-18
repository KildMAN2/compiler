#!/bin/bash

# Enhanced C-- Parser Testing Script
# Tests valid programs, error cases, and comprehensive edge cases

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
total_tests=0
passed_tests=0
failed_tests=0

# Ensure parser exists
if [ ! -f "./part2" ]; then
    echo -e "${RED}Error: Parser executable './part2' not found!${NC}"
    echo "Please run 'make' first."
    exit 1
fi

echo "=========================================="
echo "  Enhanced C-- Parser Testing Suite"
echo "=========================================="
echo ""

# Test a valid program
test_valid() {
    local test_file=$1
    local test_name=$(basename "$test_file" .cmm)
    
    total_tests=$((total_tests + 1))
    
    echo -n "Testing $test_name ... "
    
    # Run parser and capture exit code
    ./part2 < "$test_file" > "${test_file%.cmm}.out" 2>&1
    exit_code=$?
    
    # Check if it should succeed
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}PASS${NC} (parsed successfully)"
        passed_tests=$((passed_tests + 1))
        rm -f "${test_file%.cmm}.out"
    else
        echo -e "${RED}FAIL${NC} (parser returned error code $exit_code)"
        echo "  Input: $test_file"
        failed_tests=$((failed_tests + 1))
    fi
}

# Test an error case
test_error() {
    local test_file=$1
    local test_name=$(basename "$test_file" .cmm)
    
    total_tests=$((total_tests + 1))
    
    echo -n "Testing $test_name ... "
    
    # Run parser and capture exit code
    ./part2 < "$test_file" > "${test_file%.cmm}.out" 2>&1
    exit_code=$?
    
    # Check if it detected an error (non-zero exit code)
    if [ $exit_code -ne 0 ]; then
        echo -e "${GREEN}PASS${NC} (error detected correctly)"
        passed_tests=$((passed_tests + 1))
        rm -f "${test_file%.cmm}.out"
    else
        echo -e "${RED}FAIL${NC} (parser should have rejected this)"
        echo "  Input: $test_file"
        failed_tests=$((failed_tests + 1))
    fi
}

# Test with expected output comparison
test_with_expected() {
    local test_file=$1
    local expected_file=$2
    local test_name=$(basename "$test_file" .cmm)
    
    total_tests=$((total_tests + 1))
    
    echo -n "Testing $test_name ... "
    
    # Run parser
    ./part2 < "$test_file" > "${test_file%.cmm}.out" 2>&1
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        if [[ "$test_file" == *"error_"* ]]; then
            echo -e "${GREEN}PASS${NC} (error detected correctly)"
            passed_tests=$((passed_tests + 1))
            rm -f "${test_file%.cmm}.out"
            return
        else
            echo -e "${RED}FAIL${NC} (parser error)"
            failed_tests=$((failed_tests + 1))
            return
        fi
    fi
    
    # Compare with expected if exists
    if [ -f "$expected_file" ]; then
        if diff -q "$expected_file" "${test_file%.cmm}.out" > /dev/null 2>&1; then
            echo -e "${GREEN}PASS${NC}"
            passed_tests=$((passed_tests + 1))
            rm -f "${test_file%.cmm}.out"
        else
            echo -e "${RED}FAIL${NC} (output differs from expected)"
            echo "  Expected: $expected_file"
            echo "  Got:      ${test_file%.cmm}.out"
            echo "  Run 'diff $expected_file ${test_file%.cmm}.out' to see differences"
            failed_tests=$((failed_tests + 1))
        fi
    else
        echo -e "${GREEN}PASS${NC} (parsed successfully, no expected output)"
        passed_tests=$((passed_tests + 1))
        rm -f "${test_file%.cmm}.out"
    fi
}

# Run original example tests with expected output
echo -e "${BLUE}=== Original Test Suite ===${NC}"
if [ -d "examples" ]; then
    for input in examples/example[0-9]*.cmm; do
        if [ -f "$input" ] && [[ ! "$input" =~ err ]]; then
            expected="${input%.cmm}.tree"
            test_with_expected "$input" "$expected"
        fi
    done
    
    for input in examples/*err*.cmm; do
        if [ -f "$input" ]; then
            test_error "$input"
        fi
    done
fi
echo ""

# Run comprehensive valid tests
echo -e "${BLUE}=== Basic Functionality Tests ===${NC}"
for input in examples/test_0[1-9]*.cmm examples/test_1[0-9]*.cmm; do
    if [ -f "$input" ]; then
        test_valid "$input"
    fi
done
echo ""

echo -e "${BLUE}=== Function Call Tests ===${NC}"
for input in examples/test_2[0-4]*.cmm; do
    if [ -f "$input" ]; then
        test_valid "$input"
    fi
done
echo ""

echo -e "${BLUE}=== Boolean Expression Tests ===${NC}"
for input in examples/test_2[5-9]*.cmm; do
    if [ -f "$input" ]; then
        test_valid "$input"
    fi
done
echo ""

echo -e "${BLUE}=== Literal and Identifier Tests ===${NC}"
for input in examples/test_3[0-9]*.cmm; do
    if [ -f "$input" ]; then
        test_valid "$input"
    fi
done
echo ""

echo -e "${BLUE}=== Edge Case Tests ===${NC}"
for input in examples/test_4[0-9]*.cmm; do
    if [ -f "$input" ]; then
        test_valid "$input"
    fi
done
echo ""

# Run error tests
echo -e "${BLUE}=== Error Detection Tests ===${NC}"
for input in examples/error_*.cmm; do
    if [ -f "$input" ]; then
        test_error "$input"
    fi
done
echo ""

# Print summary
echo "=========================================="
echo "           Test Results"
echo "=========================================="
echo "Total tests:  $total_tests"
echo -e "Passed:       ${GREEN}$passed_tests${NC}"
echo -e "Failed:       ${RED}$failed_tests${NC}"
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output.${NC}"
    exit 1
fi
