#!/bin/bash

# Minimal checker (homework2-like):
# ./checker.sh test.cmm [more.cmm ...] input.in output.out
# Prints: True | False | Failed

set -u

COMPILER="../rx-cc"
LINKER="../rx-linker"
VM="../rx-vm"

if [ "$#" -lt 3 ]; then
  echo "Failed"
  exit 0
fi

EXPECTED_OUT="${@: -1}"
INPUT_FILE="${@: -2:1}"
SRC_FILES=("${@:1:$#-2}")

if [ ! -x "$COMPILER" ] || [ ! -x "$LINKER" ] || [ ! -x "$VM" ]; then
  echo "Failed"
  exit 0
fi

if [ ! -f "$INPUT_FILE" ] || [ ! -f "$EXPECTED_OUT" ]; then
  echo "Failed"
  exit 0
fi

# Compile each module
RSK_FILES=()
for src in "${SRC_FILES[@]}"; do
  "$COMPILER" "$src" >/dev/null 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed"
    exit 0
  fi

  rsk="${src%.cmm}.rsk"
  if [ ! -f "$rsk" ]; then
    echo "Failed"
    exit 0
  fi
  RSK_FILES+=("$rsk")
done

# Link (output .e is created next to the FIRST .rsk)
"$LINKER" "${RSK_FILES[@]}" >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Failed"
  exit 0
fi

MAIN_SRC="${SRC_FILES[0]}"
E_FILE="${MAIN_SRC%.cmm}.e"
if [ ! -f "$E_FILE" ]; then
  echo "Failed"
  exit 0
fi

# Run VM and compare output
ACTUAL_OUT="$(mktemp)"

# Timeout keeps infinite loops from hanging verification.
# Collect both stdout+stderr just like the course checker does.
if [ -s "$INPUT_FILE" ]; then
  timeout 2 "$VM" "$E_FILE" < "$INPUT_FILE" >"$ACTUAL_OUT" 2>&1
else
  timeout 2 "$VM" "$E_FILE" >"$ACTUAL_OUT" 2>&1
fi

# Normalize CRLF just in case
tr -d '\r' < "$ACTUAL_OUT" > "${ACTUAL_OUT}.norm"
tr -d '\r' < "$EXPECTED_OUT" > "${ACTUAL_OUT}.exp"

if diff -q "${ACTUAL_OUT}.norm" "${ACTUAL_OUT}.exp" >/dev/null 2>&1; then
  echo "True"
else
  echo "False"
fi

rm -f "$ACTUAL_OUT" "${ACTUAL_OUT}.norm" "${ACTUAL_OUT}.exp"
