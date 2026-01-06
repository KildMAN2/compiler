#!/bin/bash
# Fix permissions for all executables

cd ~/compiler/homework3

echo "Setting execute permissions..."
chmod +x rx-cc
chmod +x rx-linker
chmod +x rx-vm
chmod +x checker

echo "Verifying permissions..."
ls -la rx-cc rx-linker rx-vm checker 2>/dev/null

echo ""
echo "Done! All executables should now have execute permissions."
