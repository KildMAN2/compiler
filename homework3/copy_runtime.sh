#!/bin/bash
# Copy rx-runtime.rsk from homework2 to homework3 if missing

cd ~/compiler

if [ ! -f homework3/rx-runtime.rsk ]; then
    echo "rx-runtime.rsk missing in homework3, copying from homework2..."
    if [ -f homework2/rx-runtime.rsk ]; then
        cp homework2/rx-runtime.rsk homework3/rx-runtime.rsk
        echo "✓ Copied rx-runtime.rsk to homework3"
    else
        echo "✗ ERROR: rx-runtime.rsk not found in homework2 either!"
        echo "Creating minimal rx-runtime.rsk..."
        cat > homework3/rx-runtime.rsk << 'EOF'
<header>
<unimplemented> main,12
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
        echo "✓ Created minimal rx-runtime.rsk"
    fi
else
    echo "✓ rx-runtime.rsk already exists in homework3"
fi

ls -la homework3/rx-runtime.rsk
