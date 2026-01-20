#!/bin/bash

# Minimal checker (homework2-like):
# ./checker.sh [--debug] test.cmm [more.cmm ...] input.in output.out
# Prints: True | False | Failed

set -u

# Resolve homework4_final root (so rx-linker can find rx-runtime.rsk)
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER="$ROOT_DIR/rx-cc"
LINKER="$ROOT_DIR/rx-linker"
VM="$ROOT_DIR/rx-vm"

DEBUG=0
if [ "$#" -ge 1 ] && [ "$1" = "--debug" ]; then
  DEBUG=1
  shift
fi

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

# Compile each module (compile in the module's directory so outputs land there)
RSK_FILES=()
for src in "${SRC_FILES[@]}"; do
  src_abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
  src_dir="$(dirname "$src_abs")"

  (cd "$src_dir" && "$COMPILER" "$src_abs" >/dev/null 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Failed"
    exit 0
  fi

  rsk="${src_abs%.cmm}.rsk"
  if [ ! -f "$rsk" ]; then
    echo "Failed"
    exit 0
  fi
  RSK_FILES+=("$rsk")
done

# Link (run from root so rx-runtime.rsk is found; output .e is created next to FIRST .rsk)
(cd "$ROOT_DIR" && "$LINKER" "${RSK_FILES[@]}" >/dev/null 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Failed"
  exit 0
fi

MAIN_SRC="${SRC_FILES[0]}"
main_abs="$(cd "$(dirname "$MAIN_SRC")" && pwd)/$(basename "$MAIN_SRC")"
E_FILE="${main_abs%.cmm}.e"
if [ ! -f "$E_FILE" ]; then
  echo "Failed"
  exit 0
fi

# Run VM and compare output
ACTUAL_OUT="$(mktemp)"

# Timeout keeps infinite loops from hanging verification.
# Collect both stdout+stderr just like the course checker does.
input_abs="$(cd "$(dirname "$INPUT_FILE")" && pwd)/$(basename "$INPUT_FILE")"

if [ -s "$input_abs" ]; then
  timeout 2 "$VM" "$E_FILE" < "$input_abs" >"$ACTUAL_OUT" 2>&1
else
  timeout 2 "$VM" "$E_FILE" >"$ACTUAL_OUT" 2>&1
fi

# Compare only the program output (write/print).
# The VM may also print input prompts ("Input integer?:" / "Input real?:")
# and always prints "Reached Halt." at the end; these should NOT be part of
# the expected output files for this checker.
normalize_out() {
  tr -d '\r' \
    | perl -0777 -pe 's/Input integer\?:|Input real\?:|Reached Halt\.//g; s/[\s\n]+\z/\n/'
}

normalize_out < "$ACTUAL_OUT" > "${ACTUAL_OUT}.norm"
normalize_out < "$EXPECTED_OUT" > "${ACTUAL_OUT}.exp"

if diff -q "${ACTUAL_OUT}.norm" "${ACTUAL_OUT}.exp" >/dev/null 2>&1; then
  echo "True"
else
  echo "False"
  if [ "$DEBUG" -eq 1 ]; then
    echo "--- expected (normalized) ---"
    cat "${ACTUAL_OUT}.exp"
    echo "--- got (normalized) ---"
    cat "${ACTUAL_OUT}.norm"
    echo "--- diff -u ---"
    diff -u "${ACTUAL_OUT}.exp" "${ACTUAL_OUT}.norm" || true
  fi
fi

rm -f "$ACTUAL_OUT" "${ACTUAL_OUT}.norm" "${ACTUAL_OUT}.exp"
