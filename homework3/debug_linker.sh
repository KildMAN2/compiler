#!/bin/bash
# Debug script for linker failure

cd ~/compiler/homework3

# Create test modules
cat > test_helper_module.cmm << 'EOF'
int add(a : int, b : int) {
    return a + b;
}
int multiply(a : int, b : int) {
    return a * b;
}
EOF

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

# Compile both
echo "=== Compiling modules ==="
./rx-cc test_helper_module.cmm
echo "Helper exit code: $?"
./rx-cc test_main_module.cmm
echo "Main exit code: $?"

echo ""
echo "=== Generated .rsk files ==="
ls -la test_*.rsk

echo ""
echo "=== Helper module header ==="
head -20 test_helper_module.rsk

echo ""
echo "=== Main module header ==="
head -20 test_main_module.rsk

echo ""
echo "=== Attempting linker ==="
./rx-linker test_main_module.rsk test_helper_module.rsk
linker_exit=$?
echo "Linker exit code: $linker_exit"

if [ -f test_main_module.e ]; then
    echo "✓ Executable created"
    ls -la test_main_module.e
else
    echo "✗ No executable created"
fi

# Cleanup
rm -f test_helper_module.cmm test_main_module.cmm test_helper_module.rsk test_main_module.rsk test_main_module.e
