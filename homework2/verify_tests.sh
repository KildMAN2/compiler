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

for i in {1..10}; do
    TEST_DIR="test$i"
    
    # Skip if directory doesn't exist
    if [ ! -d "$TEST_DIR" ]; then
        echo "[$TEST_DIR] Skipping (Directory not found)"
        continue
    fi

    # Identify input/output files
    INPUT_FILE="$TEST_DIR/input.in"
    OUTPUT_FILE="$TEST_DIR/output.out"
    
    # Identify all .cmm files in the directory
    CMM_FILES=$(ls $TEST_DIR/*.cmm 2>/dev/null)
    
    if [ -z "$CMM_FILES" ]; then
        echo -e "[$TEST_DIR] \e[33mSkipping\e[0m (No .cmm files found)"
        continue
    fi

    # Determine expected behavior based on pass/fail file
    if [ -f "$TEST_DIR/pass" ]; then
        EXPECTED_RESULT="True"
        TEST_TYPE="PASS"
    elif [ -f "$TEST_DIR/fail" ]; then
        EXPECTED_RESULT="Failed"
        TEST_TYPE="FAIL"
    else
        echo -e "[$TEST_DIR] \e[33mSkipping\e[0m (Missing 'pass' or 'fail' file)"
        continue
    fi

    # Run the checker
    # Syntax: ./checker test.cmm [other.cmm] input.in output.out
    OUTPUT=$($CHECKER $CMM_FILES "$INPUT_FILE" "$OUTPUT_FILE")
    
    # Clean output (trim whitespace)
    RESULT=$(echo "$OUTPUT" | xargs)

    # Verify result
    if [ "$RESULT" == "$EXPECTED_RESULT" ]; then
        echo -e "[$TEST_DIR] \e[32mVERIFIED\e[0m ($TEST_TYPE test)"
    else
        echo -e "[$TEST_DIR] \e[31mMISMATCH\e[0m"
        echo "  Test Type: $TEST_TYPE"
        echo "  Expected:  $EXPECTED_RESULT"
        echo "  Got:       $RESULT"
        
        if [ "$RESULT" == "False" ]; then
            echo "  Hint: 'False' means the test compiled/ran, but output.out didn't match the actual output."
        elif [ "$RESULT" == "Failed" ] && [ "$TEST_TYPE" == "PASS" ]; then
            echo "  Hint: 'Failed' means the test failed to compile, but it was expected to pass."
        elif [ "$RESULT" == "True" ] && [ "$TEST_TYPE" == "FAIL" ]; then
            echo "  Hint: 'True' means the test passed successfully, but it was expected to fail compilation."
        fi
    fi
done

echo "========================================"
echo "Done."
