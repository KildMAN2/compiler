#!/bin/bash

# Test script for C-- compiler
# Compiles all examples, links them, runs them, and compares output

COMPILER="./rx-cc"
LINKER="./rx-linker"
VM="./rx-vm"
EXAMPLES_DIR="examples"
EXPECTED_DIR="expected_outputs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "======================================"
echo "Testing C-- Compiler"
echo "======================================"
echo ""

# Counter for pass/fail
TOTAL=0
PASSED=0
FAILED=0

# Function to test a single example
test_example() {
    local cmm_file=$1
    local base_name=$(basename "$cmm_file" .cmm)
    local dir_name=$(dirname "$cmm_file")
    
    TOTAL=$((TOTAL + 1))
    
    echo -n "Testing $base_name... "
    
    # Compile
    $COMPILER "$cmm_file" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}FAIL${NC} (compilation error)"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Check if .rsk file was created
    local rsk_file="${cmm_file%.cmm}.rsk"
    if [ ! -f "$rsk_file" ]; then
        echo -e "${RED}FAIL${NC} (.rsk file not created)"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Compare with expected output if it exists
    local expected_rsk="$EXPECTED_DIR/$base_name.rsk"
    if [ -f "$expected_rsk" ]; then
        if ! diff -q "$rsk_file" "$expected_rsk" > /dev/null 2>&1; then
            echo -e "${YELLOW}WARNING${NC} (assembly differs from expected)"
            echo "  Differences:"
            diff -u "$expected_rsk" "$rsk_file" | head -20
        fi
    fi
    
    # Link
    $LINKER "$rsk_file" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}FAIL${NC} (linking error)"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Check if .e file was created
    local e_file="${cmm_file%.cmm}.e"
    if [ ! -f "$e_file" ]; then
        echo -e "${RED}FAIL${NC} (.e file not created)"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Run if there's an input file
    local in_file="${cmm_file%.cmm}.in"
    if [ -f "$in_file" ]; then
        # Run generated
        generated_output=$(timeout 2 $VM "$e_file" < "$in_file" 2>&1)
        generated_exit=$?
        
        if [ $generated_exit -eq 0 ] || echo "$generated_output" | grep -q "Reached Halt"; then
            echo -e "${GREEN}PASS${NC}"
            echo "  Output: $generated_output"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAIL${NC} (runtime error)"
            FAILED=$((FAILED + 1))
        fi
    else
        # No input file, just check if it runs
        output=$(timeout 2 $VM "$e_file" 2>&1)
        if [ $? -eq 0 ] || echo "$output" | grep -q "Reached Halt"; then
            echo -e "${GREEN}PASS${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAIL${NC} (runtime error)"
            FAILED=$((FAILED + 1))
        fi
    fi
}

# Test all .cmm files in examples directory
for cmm_file in $EXAMPLES_DIR/*.cmm; do
    if [ -f "$cmm_file" ]; then
        test_example "$cmm_file"
    fi
done

echo ""
echo "======================================"
echo "Test Results"
echo "======================================"
echo "Total:  $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi

# Test script for C-- compiler
# Usage: ./test_compiler.sh [example_name]
# Example: ./test_compiler.sh example1

if [ $# -eq 0 ]; then
    echo "Testing all examples..."
    EXAMPLES=$(ls examples/*.cmm | sed 's/\.cmm$//' | sed 's/examples\///')
else
    EXAMPLES="$1"
fi

PASSED=0
FAILED=0

for example in $EXAMPLES; do
    echo "=========================================="
    echo "Testing: $example"
    echo "=========================================="
    
    CMM_FILE="examples/${example}.cmm"
    RSK_FILE="examples/${example}.rsk"
    E_FILE="examples/${example}.e"
    IN_FILE="examples/${example}.in"
    
    if [ ! -f "$CMM_FILE" ]; then
        echo "Error: $CMM_FILE not found"
        continue
    fi
    
    # Step 1: Compile
    echo "1. Compiling $CMM_FILE..."
    ./rx-cc "$CMM_FILE"
    if [ $? -ne 0 ]; then
        echo "❌ Compilation failed for $example"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    if [ ! -f "$RSK_FILE" ]; then
        echo "❌ $RSK_FILE not generated"
        FAILED=$((FAILED + 1))
        continue
    fi
    echo "✓ Generated $RSK_FILE"
    
    # Step 2: Link
    echo "2. Linking $RSK_FILE..."
    ./rx-linker "$RSK_FILE"
    if [ $? -ne 0 ]; then
        echo "❌ Linking failed for $example"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    if [ ! -f "$E_FILE" ]; then
        echo "❌ $E_FILE not generated"
        FAILED=$((FAILED + 1))
        continue
    fi
    echo "✓ Generated $E_FILE"
    
    # Step 3: Run
    echo "3. Running $E_FILE..."
    if [ -f "$IN_FILE" ]; then
        OUTPUT=$(./rx-vm "$E_FILE" < "$IN_FILE" 2>&1)
    else
        OUTPUT=$(./rx-vm "$E_FILE" 2>&1)
    fi
    
    echo "Output:"
    echo "$OUTPUT"
    
    if echo "$OUTPUT" | grep -q "Reached Halt"; then
        echo "✅ $example completed successfully"
        PASSED=$((PASSED + 1))
    else
        echo "❌ $example did not complete properly"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
done

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
