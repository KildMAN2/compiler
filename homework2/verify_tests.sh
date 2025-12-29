#!/bin/bash

# Configuration
CHECKER="./checker"
RUNTIME="rx-runtime.rsk"

# Check prerequisites
if [ ! -f "$CHECKER" ]; then
    echo -e "\e[31mError: '$CHECKER' executable not found.\e[0m"
    echo "Please place the 'checker' tool and '$RUNTIME' in this directory."
    exit 1
fi

if [ ! -f "$RUNTIME" ]; then
    echo -e "\e[31mError: '$RUNTIME' not found.\e[0m"
    echo "The checker requires this file to run."
    exit 1
fi

# Ensure checker is executable
chmod +x "$CHECKER"

echo "========================================"
echo "Verifying 10 Tests using ./checker"
echo "========================================"

MISMATCH_COUNT=0

run_one_test_dir() {
    local TEST_DIR="$1"

    # Skip if directory doesn't exist
    if [ ! -d "$TEST_DIR" ]; then
        echo "[$TEST_DIR] Skipping (Directory not found)"
        return
    fi

    # Identify input/output files (support both spec naming and course example naming)
    local INPUT_FILE="$TEST_DIR/input.in"
    if [ ! -f "$INPUT_FILE" ]; then
        INPUT_FILE="$TEST_DIR/input.input"
    fi

    local OUTPUT_FILE="$TEST_DIR/output.out"

    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "[$TEST_DIR] \e[33mSkipping\e[0m (Missing input file: expected input.in or input.input)"
        return
    fi

    if [ ! -f "$OUTPUT_FILE" ]; then
        echo -e "[$TEST_DIR] \e[33mSkipping\e[0m (Missing output file: expected output.out)"
        return
    fi

    # Identify all .cmm files in the directory
    shopt -s nullglob
    local CMM_FILES=("$TEST_DIR"/*.cmm)
    shopt -u nullglob

    if [ ${#CMM_FILES[@]} -eq 0 ]; then
        echo -e "[$TEST_DIR] \e[33mSkipping\e[0m (No .cmm files found)"
        return
    fi

    # Determine expected behavior based on pass/fail file
    local EXPECTED_RESULT=""
    local TEST_TYPE=""
    if [ -f "$TEST_DIR/pass" ]; then
        EXPECTED_RESULT="True"
        TEST_TYPE="PASS"
    elif [ -f "$TEST_DIR/fail" ]; then
        EXPECTED_RESULT="Failed"
        TEST_TYPE="FAIL"
    else
        echo -e "[$TEST_DIR] \e[33mSkipping\e[0m (Missing 'pass' or 'fail' file)"
        return
    fi

    # Run the checker
    local OUTPUT
    OUTPUT="$($CHECKER "${CMM_FILES[@]}" "$INPUT_FILE" "$OUTPUT_FILE" 2>&1)"

    # Normalize output: take first token only (true/false/failed)
    local RESULT
    RESULT=$(echo "$OUTPUT" | tr -d '\r' | tr '\n' ' ' | xargs | awk '{print tolower($1)}')
    local EXPECTED_LOWER
    EXPECTED_LOWER=$(echo "$EXPECTED_RESULT" | tr '[:upper:]' '[:lower:]')

    # Verify result
    if [ "$RESULT" == "$EXPECTED_LOWER" ]; then
        echo -e "[$TEST_DIR] \e[32mVERIFIED\e[0m ($TEST_TYPE test)"
    else
        MISMATCH_COUNT=$((MISMATCH_COUNT + 1))
        echo -e "[$TEST_DIR] \e[31mMISMATCH\e[0m"
        echo "  Test Type: $TEST_TYPE"
        echo "  Expected:  $EXPECTED_RESULT"
        echo "  Got:       $RESULT"

        if [ "$RESULT" == "false" ]; then
            echo "  Hint: 'False' means the test compiled/ran, but output.out didn't match the actual output."
        elif [ "$RESULT" == "failed" ] && [ "$TEST_TYPE" == "PASS" ]; then
            echo "  Hint: 'Failed' means the test failed to compile, but it was expected to pass."
        elif [ "$RESULT" == "true" ] && [ "$TEST_TYPE" == "FAIL" ]; then
            echo "  Hint: 'True' means the test passed successfully, but it was expected to fail compilation."
        fi
    fi
}

for i in {1..10}; do
    run_one_test_dir "test$i"
done

echo "========================================"
echo "Verifying Examples using ./checker"
echo "========================================"
run_one_test_dir "examples/test1"
run_one_test_dir "examples/test2"
run_one_test_dir "examples/test3"
run_one_test_dir "examples/test_err"

echo "========================================"
echo "Done."

if [ "$MISMATCH_COUNT" -ne 0 ]; then
    echo "Mismatches: $MISMATCH_COUNT"
    exit 1
fi
