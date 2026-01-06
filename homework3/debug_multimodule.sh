#!/bin/bash
# Debug script for multi-module compilation test

cd ~/compiler/homework3

# Create test files manually
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
    write(y);
}
EOF

# Try compiling each module
echo "=== Compiling helper module ==="
./rx-cc test_helper_module.cmm
echo "Exit code: $?"
ls -la test_helper_module.rsk 2>&1

echo ""
echo "=== Compiling main module ==="
./rx-cc test_main_module.cmm
echo "Exit code: $?"
ls -la test_main_module.rsk 2>&1

# Show any errors
echo ""
echo "=== Helper module output ==="
if [ -f test_helper_module.rsk ]; then
    cat test_helper_module.rsk
else
    echo "No .rsk file generated"
fi

echo ""
echo "=== Main module output ==="
if [ -f test_main_module.rsk ]; then
    cat test_main_module.rsk
else
    echo "No .rsk file generated"
fi

# Try linking if both compiled
echo ""
echo "=== Attempting to link ==="
if [ -f test_helper_module.rsk ] && [ -f test_main_module.rsk ]; then
    ./rx-linker test_main_module.rsk test_helper_module.rsk
    echo "Linker exit code: $?"
    if [ -f test_main_module.e ]; then
        echo "Executable created successfully"
        echo ""
        echo "=== Running VM ==="
        ./rx-vm test_main_module.e
    else
        echo "No executable created"
    fi
else
    echo "Cannot link - one or both .rsk files missing"
fi

# Cleanup
rm -f test_helper_module.cmm test_main_module.cmm test_helper_module.rsk test_main_module.rsk test_main_module.e
