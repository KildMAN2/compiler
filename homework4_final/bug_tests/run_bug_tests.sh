#!/bin/bash

# Script to run all bug tests and verify issues

echo "==============================================="
echo "Bug Test Suite for Compiler Issues"
echo "==============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

COMPILER="../rx-cc"
LINKER="../rx-linker"
VM="../rx-vm"

# Test counter
TOTAL=0
PASSED=0
FAILED=0

echo "----------------------------------------"
echo "1. VOID PARAMETER TESTS"
echo "----------------------------------------"
echo "Testing if compiler properly rejects void parameters..."
echo ""

for test in test_void_param.cmm test_void_param2.cmm test_void_param3.cmm; do
    TOTAL=$((TOTAL + 1))
    echo "Testing: $test"
    
    OUTPUT=$($COMPILER "$test" 2>&1)
    
    if echo "$OUTPUT" | grep -q "Semantic error"; then
        echo -e "${GREEN}✓ PASS${NC}: Properly rejects void parameter with semantic error"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Should produce semantic error for void parameter"
        echo "  Actual output: $OUTPUT"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "----------------------------------------"
echo "2. RECURSIVE FUNCTION RETURN VALUE TESTS"
echo "----------------------------------------"
echo "Testing if recursive functions return correct values..."
echo ""

for test in test_recursive_return test_recursive_return2 test_recursive_fibonacci; do
    TOTAL=$((TOTAL + 1))
    echo "Testing: ${test}.cmm"
    
    # Compile
    $COMPILER "${test}.cmm" 2>&1
    
    if [ $? -eq 0 ] && [ -f "${test}.rsk" ]; then
        # Link
        $LINKER "${test}.rsk" 2>&1
        
        if [ $? -eq 0 ] && [ -f "${test}.e" ]; then
            # Run
            $VM "${test}.e" < "${test}.in" > "${test}.out" 2>&1
        
            # Compare with expected output file (not the .e executable!)
            EXPECTED_FILE="${test}.expected"
            # Use the .e extension file we created during test creation as expected output
            if [ -f "${EXPECTED_FILE}" ]; then
                COMPARE_FILE="${EXPECTED_FILE}"
            else
                # Fallback: create expected file name from test name
                COMPARE_FILE=$(echo "${test}" | sed 's/test_recursive_//' | sed 's/_/./')
                COMPARE_FILE="${COMPARE_FILE}.expected"
                if [ ! -f "${COMPARE_FILE}" ]; then
                    # Just use inline expected values
                    case "${test}" in
                        test_recursive_return)
                            echo "5! = 120" > "${COMPARE_FILE}"
                            ;;
                        test_recursive_return2)
                            echo "2.0^3 = 8.000000" > "${COMPARE_FILE}"
                            ;;
                        test_recursive_fibonacci)
                            echo "0 1 1 2 3 5 8 13 " > "${COMPARE_FILE}"
                            ;;
                    esac
                fi
            fi
            
            if diff -q "${test}.out" "${COMPARE_FILE}" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ PASS${NC}: Recursive function works correctly"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}✗ FAIL${NC}: Output mismatch"
                echo "Expected:"
                cat "${COMPARE_FILE}"
                echo "Got:"
                cat "${test}.out"
                FAILED=$((FAILED + 1))
            fi
        else
            echo -e "${RED}✗ FAIL${NC}: Linking failed"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: Compilation failed"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "----------------------------------------"
echo "3. TYPE MISMATCH ERROR CLASSIFICATION TESTS"
echo "----------------------------------------"
echo "Testing if type mismatches produce semantic (not syntax) errors..."
echo ""

for test in test_type_mismatch_semantic.cmm test_type_mismatch_semantic2.cmm; do
    TOTAL=$((TOTAL + 1))
    echo "Testing: $test"
    
    OUTPUT=$($COMPILER "$test" 2>&1 | head -n 1)
    
    if echo "$OUTPUT" | grep -q "Semantic error"; then
        echo -e "${GREEN}✓ PASS${NC}: Type mismatch correctly reported as semantic error"
        PASSED=$((PASSED + 1))
    elif echo "$OUTPUT" | grep -q "Syntax error"; then
        echo -e "${RED}✗ FAIL${NC}: Type mismatch incorrectly reported as syntax error"
        echo "  Got: $OUTPUT"
        FAILED=$((FAILED + 1))
    else
        echo -e "${YELLOW}? UNKNOWN${NC}: Unexpected output"
        echo "  Got: $OUTPUT"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "----------------------------------------"
echo "4. FLOAT EQUALITY ASSEMBLY BUG TESTS"
echo "----------------------------------------"
echo "Testing if SEQLF (bug) or SEQEF (correct) is generated..."
echo ""

for test in test_float_equality_seqlf test_float_equality_complex; do
    TOTAL=$((TOTAL + 1))
    echo "Testing: ${test}.cmm"
    
    # Compile
    $COMPILER "${test}.cmm" 2>&1
    
    if [ $Link
        $LINKER "${test}.rsk" 2>&1
        
        if [ $? -eq 0 ] && [ -f "${test}.e" ]; then
            # Check assembly
            if grep -q "SEQLF" "${test}.rsk"; then
                echo -e "${YELLOW}⚠ BUG CONFIRMED${NC}: Uses SEQLF (should be SEQEF)"
                
                # But check if it still works
                $VM "${test}.et still works
            $VM "${test}.rsk" < "${test}.in" > "${test}.out" 2>&1
            if diff -q "${test}.out" "${test}.e" > /dev/null 2>&1; then
                echo -e "  ${GREEN}Note${NC}: Program produces correct output despite bug"
                PASSED=$((PASSED + 1))
                echo -e "${GREEN}✓ PASS${NC}: Correctly uses SEQEF"
                PASSED=$((PASSED + 1))
            else
                echo -e "${YELLOW}? UNKNOWN${NC}: Neither SEQLF nor SEQEF found"
                FAILED=$((FAILED + 1))
            fi
        else
            echo -e "${RED}✗ FAIL${NC}: Linking failed"
        elif grep -q "SEQEF" "${test}.rsk"; then
            echo -e "${GREEN}✓ PASS${NC}: Correctly uses SEQEF"
            PASSED=$((PASSED + 1))
        else
            echo -e "${YELLOW}? UNKNOWN${NC}: Neither SEQLF nor SEQEF found"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: Compilation failed"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "==============================================="
echo "Test Summary"
echo "==============================================="
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
