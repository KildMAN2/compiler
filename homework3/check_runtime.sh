#!/bin/bash
# Check rx-runtime.rsk format

cd ~/compiler/homework3

echo "=== Content of rx-runtime.rsk ==="
cat rx-runtime.rsk

echo ""
echo "=== Try linking with verbose output ==="
./rx-linker test_main_module.rsk test_helper_module.rsk 2>&1 | head -20
