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
checked=0

# Check if compiler exists
if [ ! -f "./rx-cc" ]; then
    echo -e "${RED}Error: rx-cc compiler not found. Run 'make' first.${NC}"
    exit 1
fi

if [ ! -f "./rx-linker" ]; then
    echo -e "${RED}Error: rx-linker not found.${NC}"
    exit 1
fi

if [ ! -f "./rx-vm" ]; then
    echo -e "${RED}Error: rx-vm not found.${NC}"
    exit 1
fi

if [ ! -f "./rx-runtime.rsk" ]; then
    echo -e "${YELLOW}Warning: rx-runtime.rsk not found; linking tests may fail.${NC}"
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
    
    # Use a temp dir so we don't overwrite the staff-provided examples/*.rsk or examples/*.e
    tmpdir=$(mktemp -d 2>/dev/null)
    if [ -z "$tmpdir" ] || [ ! -d "$tmpdir" ]; then
        tmpdir="./.tmp_test_all_${basename}_$$"
        mkdir -p "$tmpdir"
    fi

    # Copy source into temp dir
    cp "$file" "$tmpdir/$basename.cmm"

    # Special case: example3-main depends on example3-funcs
    extra_rsk=""
    if [[ "$basename" == *"-main"* ]]; then
        funcs_src="$dirname/${basename%-main}-funcs.cmm"
        if [ -f "$funcs_src" ]; then
            cp "$funcs_src" "$tmpdir/${basename%-main}-funcs.cmm"
            ./rx-cc "$tmpdir/${basename%-main}-funcs.cmm" >"$tmpdir/compile_funcs.log" 2>&1
            extra_rsk="$tmpdir/${basename%-main}-funcs.rsk"
        fi
    fi

    # Compile
    ./rx-cc "$tmpdir/$basename.cmm" >"$tmpdir/compile.log" 2>&1
    cc_rc=$?
    rsk_file="$tmpdir/$basename.rsk"

    if [ $cc_rc -ne 0 ] || [ ! -f "$rsk_file" ]; then
        echo -e "${RED}✗ FAILED${NC} - Compilation error"
        echo "  Compiler output:"
        head -20 "$tmpdir/compile.log" | sed 's/^/    /'
        failed=$((failed + 1))
        rm -rf "$tmpdir"
        echo ""
        continue
    fi

    # Determine if this module defines main
    has_main=0
    if grep -q "<implemented>" "$rsk_file" && grep -q "\bmain," "$rsk_file"; then
        has_main=1
    fi

    # If there's a staff-provided .e for this example, compare VM output.
    expected_e="$dirname/$basename.e"
    if [ -f "$expected_e" ] && [ $has_main -eq 1 ]; then
        checked=$((checked + 1))

        # Run expected binary to capture expected output
        ./rx-vm "$expected_e" >"$tmpdir/expected.out" 2>&1
        expected_rc=$?

        if [ $expected_rc -ne 0 ]; then
            echo -e "${YELLOW}⚠ SKIP${NC} - Provided expected .e failed to run"
            echo "  Expected VM output (first 10 lines):"
            head -10 "$tmpdir/expected.out" | sed 's/^/    /'
            echo -e "${GREEN}✓ PASSED${NC} - Compiled successfully ($rsk_file)"
            passed=$((passed + 1))
            rm -rf "$tmpdir"
            echo ""
            continue
        fi

        # Link our output in temp dir (copy runtime if exists)
        if [ -f "./rx-runtime.rsk" ]; then
            cp ./rx-runtime.rsk "$tmpdir/rx-runtime.rsk"
        fi

        (cd "$tmpdir" && "$OLDPWD"/rx-linker "$rsk_file" $extra_rsk >"$tmpdir/link.log" 2>&1)
        link_rc=$?

        out_e="$tmpdir/$basename.e"
        if [ $link_rc -ne 0 ] || [ ! -f "$out_e" ]; then
            echo -e "${RED}✗ FAILED${NC} - Linking failed"
            echo "  Linker output:"
            head -20 "$tmpdir/link.log" | sed 's/^/    /'
            failed=$((failed + 1))
            rm -rf "$tmpdir"
            echo ""
            continue
        fi

        # Run our linked binary
        ./rx-vm "$out_e" >"$tmpdir/actual.out" 2>&1
        actual_rc=$?

        if [ $actual_rc -ne 0 ]; then
            echo -e "${RED}✗ FAILED${NC} - VM execution failed"
            echo "  VM output:"
            head -20 "$tmpdir/actual.out" | sed 's/^/    /'
            failed=$((failed + 1))
            rm -rf "$tmpdir"
            echo ""
            continue
        fi

        # Diff outputs
        if diff -u "$tmpdir/expected.out" "$tmpdir/actual.out" >"$tmpdir/diff.txt"; then
            echo -e "${GREEN}✓ PASSED${NC} - VM output matches expected"
            passed=$((passed + 1))
        else
            echo -e "${RED}✗ FAILED${NC} - VM output differs from expected"
            echo "  Diff (first 60 lines):"
            head -60 "$tmpdir/diff.txt" | sed 's/^/    /'
            failed=$((failed + 1))
        fi
    else
        # No expected .e to compare (or no main). Just report compilation success.
        echo -e "${GREEN}✓ PASSED${NC} - Compiled successfully"
        passed=$((passed + 1))
        echo "  First 5 lines of generated code:"
        head -5 "$rsk_file" | sed 's/^/    /'
        if [ $has_main -eq 0 ]; then
            echo -e "${YELLOW}  (note)${NC} - No main() in this module; skipping link/vm"
        elif [ ! -f "$expected_e" ]; then
            echo -e "${YELLOW}  (note)${NC} - No expected .e provided; skipping output diff"
        fi
    fi

    rm -rf "$tmpdir"
    
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
echo "Checked (VM diff): $checked"
echo ""

# Exit with appropriate code
if [ $failed -gt 0 ]; then
    exit 1
else
    exit 0
fi
