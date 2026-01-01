#!/bin/bash
# Comprehensive test script for C-- compiler
# Tests all features including edge cases and error cases

echo "=================================================="
echo "   Comprehensive C-- Compiler Test Suite"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
total_tests=0
total_passed=0
total_failed=0
feature_tests=0
feature_passed=0
error_tests=0
error_passed=0

# Check if compiler exists
if [ ! -f "./rx-cc" ]; then
    echo -e "${RED}Error: rx-cc compiler not found. Run 'make' first.${NC}"
    exit 1
fi

# Create tests directory if it doesn't exist
mkdir -p tests

# Function to run a single test
run_test() {
    local file="$1"
    local should_pass="$2"  # "pass" or "error"
    local test_num="$3"
    local category="$4"
    
    total_tests=$((total_tests + 1))
    
    basename=$(basename "$file" .cmm)
    rsk_file="${file%.cmm}.rsk"
    
    echo -e "${CYAN}Test $test_num [$category]: $basename${NC}"
    
    # Run compiler and capture output
    output=$(./rx-cc "$file" "$rsk_file" 2>&1)
    exit_code=$?
    
    if [ "$should_pass" == "pass" ]; then
        # Test should compile successfully
        feature_tests=$((feature_tests + 1))
        
        if [ $exit_code -eq 0 ] && [ -f "$rsk_file" ]; then
            echo -e "${GREEN}✓ PASSED${NC} - Generated $rsk_file"
            feature_passed=$((feature_passed + 1))
            total_passed=$((total_passed + 1))
            
            # Show first 3 lines of generated code
            echo -e "${BLUE}  Generated code (first 3 lines):${NC}"
            head -n 3 "$rsk_file" | sed 's/^/    /'
            
            # Count instructions
            line_count=$(wc -l < "$rsk_file")
            echo -e "${BLUE}  Total instructions: $line_count${NC}"
        else
            echo -e "${RED}✗ FAILED${NC} - Compilation error"
            total_failed=$((total_failed + 1))
            echo -e "${RED}  Error output:${NC}"
            echo "$output" | sed 's/^/    /'
        fi
    else
        # Test should fail (error case)
        error_tests=$((error_tests + 1))
        
        if [ $exit_code -ne 0 ]; then
            echo -e "${GREEN}✓ PASSED${NC} - Correctly detected error"
            error_passed=$((error_passed + 1))
            total_passed=$((total_passed + 1))
            echo -e "${MAGENTA}  Error message:${NC}"
            echo "$output" | sed 's/^/    /'
        else
            echo -e "${RED}✗ FAILED${NC} - Should have failed but compiled successfully"
            total_failed=$((total_failed + 1))
        fi
    fi
    
    echo ""
}

# Run feature tests
echo "=================================================="
echo "  FEATURE TESTS (Should compile successfully)"
echo "=================================================="
echo ""

test_num=1

# Find and run all feature tests
feature_files=$(find tests -name "test_*.cmm" 2>/dev/null | sort)

if [ -z "$feature_files" ]; then
    echo -e "${YELLOW}No feature test files found in tests/ directory${NC}"
else
    for file in $feature_files; do
        run_test "$file" "pass" "$test_num" "FEATURE"
        test_num=$((test_num + 1))
    done
fi

echo ""
echo "=================================================="
echo "  ERROR DETECTION TESTS (Should fail gracefully)"
echo "=================================================="
echo ""

# Find and run all error tests
error_files=$(find tests -name "error_*.cmm" 2>/dev/null | sort)

if [ -z "$error_files" ]; then
    echo -e "${YELLOW}No error test files found in tests/ directory${NC}"
else
    for file in $error_files; do
        run_test "$file" "error" "$test_num" "ERROR"
        test_num=$((test_num + 1))
    done
fi

# Summary
echo ""
echo "=================================================="
echo "               TEST SUMMARY"
echo "=================================================="
echo ""
echo -e "${CYAN}Total Tests Run:${NC}      $total_tests"
echo -e "${GREEN}Total Passed:${NC}        $total_passed"
echo -e "${RED}Total Failed:${NC}        $total_failed"
echo ""
echo -e "${BLUE}Feature Tests:${NC}       $feature_tests (Passed: $feature_passed)"
echo -e "${MAGENTA}Error Tests:${NC}         $error_tests (Passed: $error_passed)"
echo ""

# Calculate success rate
if [ $total_tests -gt 0 ]; then
    success_rate=$((total_passed * 100 / total_tests))
    echo -e "${CYAN}Success Rate:${NC}        ${success_rate}%"
    echo ""
    
    if [ $success_rate -eq 100 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    elif [ $success_rate -ge 80 ]; then
        echo -e "${YELLOW}⚠️  Most tests passed, but some issues remain${NC}"
    else
        echo -e "${RED}❌ Many tests failed, needs attention${NC}"
    fi
fi

echo ""
echo "=================================================="

# Exit with appropriate code
if [ $total_failed -eq 0 ]; then
    exit 0
else
    exit 1
fi
