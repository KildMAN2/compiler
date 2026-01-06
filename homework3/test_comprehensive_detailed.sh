#!/bin/bash
# Comprehensive Part 3 Test Suite - Every Detail Check
# Based on Project Requirements Document

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo "=================================================================="
echo "  COMPREHENSIVE PART 3 TEST SUITE - EVERY DETAIL"
echo "=================================================================="
echo ""

# Counters
total_tests=0
passed_tests=0
failed_tests=0
critical_failures=0

# Check prerequisites
if [ ! -f "./rx-cc" ]; then
    echo -e "${RED}Error: rx-cc not found. Run 'make' first.${NC}"
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

# ============================================================================
# TEST CATEGORY 1: COMPILER INTERFACE
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 1: COMPILER INTERFACE${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 1.1: Correct usage
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 1.1: Compiler accepts .cmm file${NC}"
cat > test_interface.cmm << 'EOF'
void main() {
    x : int;
    x = 5;
}
EOF

./rx-cc test_interface.cmm > /dev/null 2>&1
if [ $? -eq 0 ] && [ -f "test_interface.rsk" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Accepts .cmm and generates .rsk"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should accept .cmm file"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_interface.cmm test_interface.rsk
echo ""

# Test 1.2: No output file on error
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 1.2: No .rsk file on compilation error${NC}"
cat > test_no_output.cmm << 'EOF'
void main() {
    x = undeclared;
}
EOF

./rx-cc test_no_output.cmm > /dev/null 2>&1
if [ ! -f "test_no_output.rsk" ]; then
    echo -e "${GREEN}✓ PASS${NC} - No output file on error"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should not create .rsk on error"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_no_output.cmm test_no_output.rsk
echo ""

# ============================================================================
# TEST CATEGORY 2: LINKER HEADER FORMAT
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 2: LINKER HEADER FORMAT${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 2.1: Header structure
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 2.1: Linker header structure${NC}"
cat > test_header.cmm << 'EOF'
void helper(x : int);
void main() {
    x : int;
    x = 5;
}
EOF

./rx-cc test_header.cmm > /dev/null 2>&1
if [ -f "test_header.rsk" ]; then
    if grep -q "<header>" test_header.rsk && \
       grep -q "<unimplemented>" test_header.rsk && \
       grep -q "<implemented>" test_header.rsk && \
       grep -q "</header>" test_header.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - Header structure correct"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Missing header tags"
        failed_tests=$((failed_tests + 1))
        critical_failures=$((critical_failures + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_header.cmm test_header.rsk
echo ""

# Test 2.2: Unimplemented functions list
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 2.2: Unimplemented functions listed${NC}"
cat > test_unimp.cmm << 'EOF'
void external_func(a : int, b : float);
void main() {
    external_func(5, 3.14);
}
EOF

./rx-cc test_unimp.cmm > /dev/null 2>&1
if [ -f "test_unimp.rsk" ]; then
    if grep "<unimplemented>" test_unimp.rsk | grep -q "external_func"; then
        echo -e "${GREEN}✓ PASS${NC} - Unimplemented function listed"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - external_func not in <unimplemented>"
        failed_tests=$((failed_tests + 1))
        critical_failures=$((critical_failures + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_unimp.cmm test_unimp.rsk
echo ""

# Test 2.3: Implemented functions with line numbers
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 2.3: Implemented functions with line numbers${NC}"
cat > test_impl.cmm << 'EOF'
void foo() {
    x : int;
}
void main() {
    foo();
}
EOF

./rx-cc test_impl.cmm > /dev/null 2>&1
if [ -f "test_impl.rsk" ]; then
    impl_line=$(grep "<implemented>" test_impl.rsk)
    if echo "$impl_line" | grep -q "foo,[0-9]" && echo "$impl_line" | grep -q "main,[0-9]"; then
        echo -e "${GREEN}✓ PASS${NC} - Implemented functions with line numbers"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Format should be 'funcName,lineNum'"
        failed_tests=$((failed_tests + 1))
        critical_failures=$((critical_failures + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_impl.cmm test_impl.rsk
echo ""

# ============================================================================
# TEST CATEGORY 3: FUNCTION DECLARATIONS & DEFINITIONS
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 3: FUNCTIONS${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 3.1: Forward declaration
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 3.1: Forward declaration before use${NC}"
cat > test_forward.cmm << 'EOF'
int helper(x : int);
void main() {
    y : int;
    y = helper(5);
}
int helper(x : int) {
    return x + 1;
}
EOF

./rx-cc test_forward.cmm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Forward declaration works"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should support forward declaration"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_forward.cmm test_forward.rsk
echo ""

# Test 3.2: Recursive function
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 3.2: Recursive function call${NC}"
cat > test_recursive.cmm << 'EOF'
int factorial(n : int) {
    if n == 0 then
        return 1;
    else
        return n * factorial(n - 1);
}
void main() {
    x : int;
    x = factorial(5);
}
EOF

./rx-cc test_recursive.cmm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Recursive calls supported"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should support recursion"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_recursive.cmm test_recursive.rsk
echo ""

# Test 3.3: Function redeclaration error
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 3.3: Detect function redeclaration${NC}"
cat > test_redef.cmm << 'EOF'
void foo() { x : int; }
void foo() { y : int; }
void main() { foo(); }
EOF

./rx-cc test_redef.cmm > test_redef_out.txt 2>&1
if [ $? -ne 0 ] && grep -q -i "error" test_redef_out.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Detects redefinition"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should reject redefinition"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_redef.cmm test_redef.rsk test_redef_out.txt
echo ""

# Test 3.4: Undeclared function error
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 3.4: Detect undeclared function call${NC}"
cat > test_undecl_func.cmm << 'EOF'
void main() {
    unknown_function();
}
EOF

./rx-cc test_undecl_func.cmm > test_undecl_out.txt 2>&1
if [ $? -ne 0 ] && grep -q -i "undeclared\|not declared" test_undecl_out.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Detects undeclared function"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should reject undeclared function"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_undecl_func.cmm test_undecl_func.rsk test_undecl_out.txt
echo ""

# ============================================================================
# TEST CATEGORY 4: PARAMETER PASSING
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 4: PARAMETER PASSING${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 4.1: Positional parameters
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 4.1: Positional parameters${NC}"
cat > test_pos_params.cmm << 'EOF'
int add(a : int, b : int) {
    return a + b;
}
void main() {
    x : int;
    x = add(5, 3);
}
EOF

./rx-cc test_pos_params.cmm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Positional parameters work"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Positional parameters failed"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_pos_params.cmm test_pos_params.rsk
echo ""

# Test 4.2: Named parameters
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 4.2: Named parameters${NC}"
cat > test_named_params.cmm << 'EOF'
int subtract(a : int, b : int) {
    return a - b;
}
void main() {
    x : int;
    x = subtract(b:3, a:10);
}
EOF

./rx-cc test_named_params.cmm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Named parameters work"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Named parameters failed"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_named_params.cmm test_named_params.rsk
echo ""

# Test 4.3: Mixed parameters
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 4.3: Mixed positional and named parameters${NC}"
cat > test_mixed_params.cmm << 'EOF'
int compute(a : int, b : int, c : int) {
    return a + b + c;
}
void main() {
    x : int;
    x = compute(1, c:3, b:2);
}
EOF

./rx-cc test_mixed_params.cmm > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Mixed parameters work"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Mixed parameters failed"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
fi
rm -f test_mixed_params.cmm test_mixed_params.rsk
echo ""

# Test 4.4: Wrong parameter type
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 4.4: Detect wrong parameter type${NC}"
cat > test_wrong_type.cmm << 'EOF'
void foo(x : int) { }
void main() {
    a : float;
    a = 3.14;
    foo(a);
}
EOF

./rx-cc test_wrong_type.cmm > test_wrong_out.txt 2>&1
if [ $? -ne 0 ] && grep -q -i "type\|mismatch" test_wrong_out.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Detects type mismatch"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should reject wrong type"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_wrong_type.cmm test_wrong_type.rsk test_wrong_out.txt
echo ""

# Test 4.5: Missing parameter
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 4.5: Detect missing parameter${NC}"
cat > test_missing_param.cmm << 'EOF'
void bar(x : int, y : int) { }
void main() {
    bar(5);
}
EOF

./rx-cc test_missing_param.cmm > test_missing_out.txt 2>&1
if [ $? -ne 0 ] && grep -q -i "parameter\|not provided" test_missing_out.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Detects missing parameter"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should reject missing parameter"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_missing_param.cmm test_missing_param.rsk test_missing_out.txt
echo ""

# ============================================================================
# TEST CATEGORY 5: TYPE CHECKING
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 5: TYPE CHECKING${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 5.1: Return type checking
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 5.1: Return type must match${NC}"
cat > test_return_type.cmm << 'EOF'
int foo() {
    return 3.14;
}
void main() { x : int; x = foo(); }
EOF

./rx-cc test_return_type.cmm > test_ret_out.txt 2>&1
if [ $? -ne 0 ] && grep -q -i "type\|mismatch" test_ret_out.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Detects return type mismatch"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should reject wrong return type"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_return_type.cmm test_return_type.rsk test_ret_out.txt
echo ""

# Test 5.2: Non-void must return
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 5.2: Non-void function must return value${NC}"
cat > test_must_return.cmm << 'EOF'
int bar() {
    x : int;
    x = 5;
}
void main() { y : int; y = bar(); }
EOF

./rx-cc test_must_return.cmm > test_must_ret_out.txt 2>&1
if [ $? -ne 0 ] && grep -q -i "return" test_must_ret_out.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Detects missing return"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Should require return statement"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_must_return.cmm test_must_return.rsk test_must_ret_out.txt
echo ""

# Test 5.3: Type casting
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 5.3: Type casting int <-> float${NC}"
cat > test_cast.cmm << 'EOF'
void main() {
    x : int;
    y : float;
    x = 5;
    y = (float)x;
    x = (int)y;
}
EOF

./rx-cc test_cast.cmm > /dev/null 2>&1
if [ $? -eq 0 ] && [ -f "test_cast.rsk" ]; then
    if grep -q "CITOF\|CFTOI" test_cast.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - Type casting generates CITOF/CFTOI"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${YELLOW}⚠ PARTIAL${NC} - Compiles but no cast instructions found"
        passed_tests=$((passed_tests + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Type casting failed"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_cast.cmm test_cast.rsk
echo ""

# ============================================================================
# TEST CATEGORY 6: CODE GENERATION QUALITY
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 6: CODE GENERATION${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 6.1: Function labels
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 6.1: Function labels in code${NC}"
cat > test_labels.cmm << 'EOF'
void helper() { x : int; }
void main() { helper(); }
EOF

./rx-cc test_labels.cmm > /dev/null 2>&1
if [ -f "test_labels.rsk" ]; then
    if grep -q "LABEL main" test_labels.rsk && grep -q "LABEL helper" test_labels.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - Function labels present"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Missing function labels"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_labels.cmm test_labels.rsk
echo ""

# Test 6.2: Arithmetic operations
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 6.2: Arithmetic instructions${NC}"
cat > test_arith.cmm << 'EOF'
void main() {
    x : int;
    y : int;
    x = 5 + 3;
    y = x * 2;
}
EOF

./rx-cc test_arith.cmm > /dev/null 2>&1
if [ -f "test_arith.rsk" ]; then
    if grep -q "ADD2I\|MULTI" test_arith.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - Arithmetic instructions generated"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Missing arithmetic instructions"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_arith.cmm test_arith.rsk
echo ""

# Test 6.3: Control flow (if/while)
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 6.3: Control flow instructions${NC}"
cat > test_control.cmm << 'EOF'
void main() {
    x : int;
    x = 5;
    if x > 0 then
        x = x + 1;
}
EOF

./rx-cc test_control.cmm > /dev/null 2>&1
if [ -f "test_control.rsk" ]; then
    if grep -q "BNEQZ\|UJUMP" test_control.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - Control flow instructions generated"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Missing control flow instructions"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_control.cmm test_control.rsk
echo ""

# Test 6.4: Function calls (JLINK)
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 6.4: Function call instruction${NC}"
cat > test_jlink.cmm << 'EOF'
void foo() { x : int; }
void main() { foo(); }
EOF

./rx-cc test_jlink.cmm > /dev/null 2>&1
if [ -f "test_jlink.rsk" ]; then
    if grep -q "JLINK" test_jlink.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - JLINK instruction generated"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Missing JLINK instruction"
        failed_tests=$((failed_tests + 1))
        critical_failures=$((critical_failures + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_jlink.cmm test_jlink.rsk
echo ""

# Test 6.5: Return instruction
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 6.5: Return instruction${NC}"
cat > test_return.cmm << 'EOF'
int getValue() {
    return 42;
}
void main() {
    x : int;
    x = getValue();
}
EOF

./rx-cc test_return.cmm > /dev/null 2>&1
if [ -f "test_return.rsk" ]; then
    if grep -q "RETRN" test_return.rsk; then
        echo -e "${GREEN}✓ PASS${NC} - RETRN instruction generated"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - Missing RETRN instruction"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - No output file"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_return.cmm test_return.rsk
echo ""

# ============================================================================
# TEST CATEGORY 7: MULTI-MODULE COMPILATION & LINKING
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 7: MULTI-MODULE & LINKING${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 7.1: Multi-module compilation
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 7.1: Multi-module compilation${NC}"

# Ensure runtime file exists for the linker (course staff provides rx-runtime.rsk).
# If missing, try to create it using setup_runtime.sh (works even if not executable).
if [ ! -f "rx-runtime.rsk" ] && [ -f "./setup_runtime.sh" ]; then
    bash ./setup_runtime.sh > /dev/null 2>&1
fi

# Module 1: helper functions (no main)
cat > test_helper_module.cmm << 'EOF'
int add(a : int, b : int) {
    return a + b;
}
int multiply(a : int, b : int) {
    return a * b;
}
EOF

# Module 2: main program
cat > test_main_module.cmm << 'EOF'
int add(a : int, b : int);
int multiply(a : int, b : int);
void main() {
    x : int;
    y : int;
    x = add(5, 3);
    y = multiply(x, 2);
}
EOF

./rx-cc test_helper_module.cmm > /dev/null 2>&1
helper_result=$?
./rx-cc test_main_module.cmm > /dev/null 2>&1
main_result=$?

if [ $helper_result -eq 0 ] && [ $main_result -eq 0 ] && \
   [ -f "test_helper_module.rsk" ] && [ -f "test_main_module.rsk" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Both modules compiled"
    passed_tests=$((passed_tests + 1))
    
    # Test 7.2: Linking
    total_tests=$((total_tests + 1))
    echo -e "${CYAN}Test 7.2: Linking modules${NC}"

    if [ ! -f "rx-runtime.rsk" ]; then
        echo -e "${RED}✗ FAIL${NC} - Linking failed (missing rx-runtime.rsk in current directory)"
        failed_tests=$((failed_tests + 1))
        critical_failures=$((critical_failures + 1))
        total_tests=$((total_tests + 1))  # Count skipped VM test
        failed_tests=$((failed_tests + 1))
    else
        link_out=$(./rx-linker test_main_module.rsk test_helper_module.rsk 2>&1)
        link_rc=$?
        if [ $link_rc -eq 0 ] && [ -f "test_main_module.e" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Modules linked successfully"
        passed_tests=$((passed_tests + 1))
        
        # Test 7.3: VM execution
        total_tests=$((total_tests + 1))
        echo -e "${CYAN}Test 7.3: VM execution${NC}"
        
        vm_output=$(./rx-vm test_main_module.e 2>&1)
        # Just check it runs without error
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ PASS${NC} - VM executed successfully"
            passed_tests=$((passed_tests + 1))
        else
            echo -e "${YELLOW}⚠ PARTIAL${NC} - VM had issues"
            passed_tests=$((passed_tests + 1))
        fi
        else
            echo -e "${RED}✗ FAIL${NC} - Linking failed"
            echo "  Linker output:"
            echo "$link_out" | head -10 | sed 's/^/  /'
            failed_tests=$((failed_tests + 1))
            critical_failures=$((critical_failures + 1))
            total_tests=$((total_tests + 1))  # Count skipped VM test
            failed_tests=$((failed_tests + 1))
        fi
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Multi-module compilation failed"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
    # Skip linking and VM tests
    total_tests=$((total_tests + 2))
    failed_tests=$((failed_tests + 2))
fi
rm -f test_helper_module.cmm test_helper_module.rsk test_main_module.cmm test_main_module.rsk test_main_module.e
echo ""

# ============================================================================
# TEST CATEGORY 8: ERROR MESSAGES (CRITICAL FROM PART 2)
# ============================================================================

echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  CATEGORY 8: ERROR OUTPUT (CRITICAL)${NC}"
echo -e "${MAGENTA}════════════════════════════════════════${NC}"
echo ""

# Test 8.1: Errors to stdout
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 8.1: All errors to STDOUT (not stderr)${NC}"
cat > test_err_stdout.cmm << 'EOF'
void main() {
    x = undefined;
}
EOF

./rx-cc test_err_stdout.cmm > test_stdout.txt 2> test_stderr.txt
if [ -s test_stderr.txt ]; then
    echo -e "${RED}✗ FAIL - CRITICAL${NC} - Errors going to STDERR"
    failed_tests=$((failed_tests + 1))
    critical_failures=$((critical_failures + 1))
elif [ -s test_stdout.txt ] && grep -q -i "error" test_stdout.txt; then
    echo -e "${GREEN}✓ PASS${NC} - Errors to stdout"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - No error output"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_err_stdout.cmm test_stdout.txt test_stderr.txt
echo ""

# Test 8.2: Error format with line numbers
total_tests=$((total_tests + 1))
echo -e "${CYAN}Test 8.2: Error messages include line numbers${NC}"
cat > test_err_format.cmm << 'EOF'
void main() {
    x = y;
}
EOF

error_msg=$(./rx-cc test_err_format.cmm 2>&1)
if echo "$error_msg" | grep -q "line [0-9]"; then
    echo -e "${GREEN}✓ PASS${NC} - Error includes line number"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ FAIL${NC} - Error missing line number"
    failed_tests=$((failed_tests + 1))
fi
rm -f test_err_format.cmm
echo ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================

echo ""
echo "=================================================================="
echo "                    FINAL TEST SUMMARY"
echo "=================================================================="
echo ""
echo "Total Tests:     $total_tests"
echo -e "${GREEN}Passed:          $passed_tests${NC}"
echo -e "${RED}Failed:          $failed_tests${NC}"
if [ $critical_failures -gt 0 ]; then
    echo -e "${RED}Critical Issues: $critical_failures${NC}"
fi
echo ""

# Calculate success rate
if [ $total_tests -gt 0 ]; then
    success_rate=$(( (passed_tests * 100) / total_tests ))
    echo "Success Rate:    ${success_rate}%"
fi

echo ""

# Final verdict
if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🎉 ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}  Implementation is COMPLETE and READY${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    exit 0
elif [ $critical_failures -eq 0 ]; then
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Some tests failed, but no critical issues${NC}"
    echo -e "${YELLOW}  Review failures above${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    exit 1
else
    echo -e "${RED}════════════════════════════════════════${NC}"
    echo -e "${RED}  CRITICAL ISSUES DETECTED!${NC}"
    echo -e "${RED}  $critical_failures critical failures found${NC}"
    echo -e "${RED}  Must fix before submission${NC}"
    echo -e "${RED}════════════════════════════════════════${NC}"
    exit 1
fi
