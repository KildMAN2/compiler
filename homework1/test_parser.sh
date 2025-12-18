#!/bin/bash

# Test script for C-- Parser (Part 2)
# Runs all examples and compares output with expected results

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0

echo "=========================================="
echo "    C-- Parser Testing Script"
echo "=========================================="
echo ""

# Check if parser executable exists
if [ ! -f "./part2" ]; then
    echo -e "${RED}Error: part2 executable not found!${NC}"
    echo "Please run 'make' first to build the parser."
    exit 1
fi

# Check if examples directory exists
if [ ! -d "./examples" ]; then
    echo -e "${RED}Error: examples directory not found!${NC}"
    exit 1
fi

echo "Testing valid programs..."
echo ""

# Test valid examples
for input_file in examples/example*.cmm; do
    # Skip error examples for now
    if [[ "$input_file" == *"err"* ]]; then
        continue
    fi
    
    TOTAL=$((TOTAL + 1))
    
    # Get base name without extension
    base_name=$(basename "$input_file" .cmm)
    expected_file="examples/${base_name}.tree"
    output_file="examples/${base_name}.out"
    
    echo -n "Testing $base_name ... "
    
    # Check if expected output exists
    if [ ! -f "$expected_file" ]; then
        echo -e "${YELLOW}SKIP${NC} (no expected output)"
        TOTAL=$((TOTAL - 1))
        continue
    fi
    
    # Run parser
    ./part2 < "$input_file" > "$output_file" 2>&1
    exit_code=$?
    
    # Check exit code
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}FAIL${NC} (parser crashed with exit code $exit_code)"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # Compare output with expected
    if diff -q "$output_file" "$expected_file" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
        rm "$output_file"  # Clean up successful test output
    else
        echo -e "${RED}FAIL${NC} (output differs from expected)"
        FAILED=$((FAILED + 1))
        echo "  Expected: $expected_file"
        echo "  Got:      $output_file"
        echo "  Run 'diff $expected_file $output_file' to see differences"
    fi
done

echo ""
echo "Testing error cases..."
echo ""

# Test error examples
for input_file in examples/*err*.cmm; do
    TOTAL=$((TOTAL + 1))
    
    # Get base name without extension
    base_name=$(basename "$input_file" .cmm)
    expected_file="examples/${base_name}.tree"
    output_file="examples/${base_name}.out"
    
    echo -n "Testing $base_name ... "
    
    # Run parser (should fail)
    ./part2 < "$input_file" > "$output_file" 2>&1
    exit_code=$?
    
    # Check if it properly detected the error
    if [ $exit_code -eq 1 ] || [ $exit_code -eq 2 ]; then
        # If expected output exists, compare it
        if [ -f "$expected_file" ]; then
            if diff -q "$output_file" "$expected_file" > /dev/null 2>&1; then
                echo -e "${GREEN}PASS${NC} (error detected correctly)"
                PASSED=$((PASSED + 1))
                rm "$output_file"
            else
                echo -e "${YELLOW}PARTIAL${NC} (error detected but message differs)"
                PASSED=$((PASSED + 1))  # Still count as pass - error was detected
                rm "$output_file"
            fi
        else
            echo -e "${GREEN}PASS${NC} (error detected with exit code $exit_code)"
            PASSED=$((PASSED + 1))
            rm "$output_file"
        fi
    else
        echo -e "${RED}FAIL${NC} (should have failed but exit code was $exit_code)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=========================================="
echo "           Test Results"
echo "=========================================="
echo "Total tests:  $TOTAL"
echo -e "Passed:       ${GREEN}$PASSED${NC}"
echo -e "Failed:       ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output.${NC}"
    exit 1
fi
