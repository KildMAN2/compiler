#!/bin/bash
# Create rx-runtime.rsk if missing

if [ ! -f rx-runtime.rsk ]; then
    echo "Creating rx-runtime.rsk..."
    cat > rx-runtime.rsk << 'EOF'
<header>
<unimplemented> main,8
<implemented> 
</header>
COPYI I1 0
COPYI I2 0
COPYI I3 0
COPYI I4 0
COPYI I5 0
COPYI I6 0
COPYI I7 0
JLINK -1
HALT
EOF
    echo "✓ Created rx-runtime.rsk"
else
    echo "✓ rx-runtime.rsk already exists"
fi

ls -la rx-runtime.rsk
