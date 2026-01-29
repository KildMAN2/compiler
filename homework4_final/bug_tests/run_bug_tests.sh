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

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
}

normalize_file() {
    local in_file="$1" out_file="$2"
    # - trim trailing whitespace
    # - squeeze multiple spaces into one
    # - drop VM halt marker line
    sed -e 's/[[:space:]]\+$//' -e 's/  \+/ /g' -e '/^Reached Halt\.$/d' "$in_file" > "$out_file"
}

compare_output_normalized() {
    local expected="$1" actual="$2" label="$3"
    local exp_norm="${expected}.norm"
    local act_norm="${actual}.norm"
    normalize_file "$expected" "$exp_norm"
    normalize_file "$actual" "$act_norm"

    if diff -u "$exp_norm" "$act_norm" >/dev/null 2>&1; then
        pass "$label"
        PASSED=$((PASSED + 1))
        return 0
    fi

    fail "$label"
    echo "--- expected (normalized)"
    cat "$exp_norm"
    echo "--- got (normalized)"
    cat "$act_norm"
    FAILED=$((FAILED + 1))
    return 1
}

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
        pass "Properly rejects void parameter with semantic error"
        PASSED=$((PASSED + 1))
    else
        fail "Should produce semantic error for void parameter"
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
    $COMPILER "${test}.cmm" >/dev/null 2>&1
    if [ $? -ne 0 ] || [ ! -f "${test}.rsk" ]; then
        fail "Compilation failed"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    # Link
    $LINKER "${test}.rsk" >/dev/null 2>&1
    if [ $? -ne 0 ] || [ ! -f "${test}.e" ]; then
        fail "Linking failed"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    # Run
    $VM "${test}.e" < "${test}.in" > "${test}.out" 2>&1

    # Find or create expected output
    local_expected="${test}.expected"
    if [ -f "$local_expected" ]; then
        compare_file="$local_expected"
    else
        compare_file="${test}.expected"
        case "${test}" in
            test_recursive_return)
                printf "5! = 120\nReached Halt.\n" > "$compare_file"
                ;;
            test_recursive_return2)
                printf "2.0^3 = 8.000000\nReached Halt.\n" > "$compare_file"
                ;;
            test_recursive_fibonacci)
                printf "0 1 1 2 3 5 8 13\nReached Halt.\n" > "$compare_file"
                ;;
        esac
    fi

    compare_output_normalized "$compare_file" "${test}.out" "Recursive function works correctly"
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
        pass "Type mismatch correctly reported as semantic error"
        PASSED=$((PASSED + 1))
    elif echo "$OUTPUT" | grep -q "Syntax error"; then
        fail "Type mismatch incorrectly reported as syntax error"
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
    $COMPILER "${test}.cmm" >/dev/null 2>&1
    if [ $? -ne 0 ] || [ ! -f "${test}.rsk" ]; then
        fail "Compilation failed"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    # Link
    $LINKER "${test}.rsk" >/dev/null 2>&1
    if [ $? -ne 0 ] || [ ! -f "${test}.e" ]; then
        fail "Linking failed"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    # Check assembly
    if grep -q "SEQLF" "${test}.rsk"; then
        echo -e "${YELLOW}⚠ BUG CONFIRMED${NC}: Uses SEQLF (should be SEQEF)"
        FAILED=$((FAILED + 1))
    elif grep -q "SEQEF" "${test}.rsk"; then
        pass "Correctly uses SEQEF"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}? UNKNOWN${NC}: Neither SEQLF nor SEQEF found"
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
