#!/bin/bash
# Test script for C-- compiler
# Tests all example .cmm files

echo "====================================="
echo "Testing C-- Compiler on All Examples"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total=0
passed=0
failed=0

# Check if compiler exists
if [ ! -f "./rx-cc" ]; then
    echo -e "${RED}Error: rx-cc compiler not found. Run 'make' first.${NC}"
    exit 1
fi

# Find all .cmm files in examples directory
echo "Finding all .cmm files in examples/..."
cmm_files=$(find examples -name "*.cmm" | sort)

if [ -z "$cmm_files" ]; then
    echo -e "${YELLOW}No .cmm files found in examples/ directory${NC}"
    exit 0
fi

echo ""
echo "Found $(echo "$cmm_files" | wc -l) test files"
echo "-------------------------------------"
echo ""

# Test each file
for file in $cmm_files; do
    total=$((total + 1))
    basename=$(basename "$file" .cmm)
    dirname=$(dirname "$file")
    
    echo -e "${YELLOW}Test $total: $file${NC}"
    
    # Set output file path
    rsk_file="${file%.cmm}.rsk"
    
    # Run compiler
    ./rx-cc "$file" "$rsk_file" 2>&1
    
    # Check if compilation succeeded
    if [ $? -eq 0 ]; then
        # Check if .rsk file was created
        if [ -f "$rsk_file" ]; then
            echo -e "${GREEN}✓ PASSED${NC} - Generated $rsk_file"
            passed=$((passed + 1))
            
            # Show first few lines of generated code
            echo "  First 5 lines of generated code:"
            head -5 "$rsk_file" | sed 's/^/    /'
        else
            echo -e "${RED}✗ FAILED${NC} - No .rsk file generated"
            failed=$((failed + 1))
        fi
    else
        echo -e "${RED}✗ FAILED${NC} - Compilation error"
        failed=$((failed + 1))
    fi
    
    echo ""
done

# Summary
echo "====================================="
echo "Test Summary"
echo "====================================="
echo "Total:  $total"
echo -e "${GREEN}Passed: $passed${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}Failed: $failed${NC}"
else
    echo "Failed: $failed"
fi
echo ""

# Exit with appropriate code
if [ $failed -gt 0 ]; then
    exit 1
else
    exit 0
fi
