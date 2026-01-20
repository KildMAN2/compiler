#!/bin/bash

set -u

COMPILER="../rx-cc"

if [ ! -x "$COMPILER" ]; then
  echo "Error: rx-cc not found (run from homework4_final/error_format_tests)."
  exit 1
fi

TMP_OUT="$(mktemp)"
FAIL=0

run_one() {
  local base="$1"
  local src="$base.cmm"
  local exp="$base.err"

  if [ ! -f "$src" ] || [ ! -f "$exp" ]; then
    echo "[$base] missing files"
    FAIL=$((FAIL+1))
    return
  fi

  "$COMPILER" "$src" >/dev/null 2>"$TMP_OUT"

  tr -d '\r' < "$TMP_OUT" > "${TMP_OUT}.norm"
  tr -d '\r' < "$exp" > "${TMP_OUT}.exp"

  if diff -q "${TMP_OUT}.norm" "${TMP_OUT}.exp" >/dev/null 2>&1; then
    echo "[$base] OK"
  else
    echo "[$base] MISMATCH"
    echo "--- expected"
    cat "$exp"
    echo "--- got"
    cat "$TMP_OUT"
    FAIL=$((FAIL+1))
  fi
}

echo "========================================"
echo "Error message format tests"
echo "========================================"

run_one lexical_error
run_one syntax_error
run_one semantic_error

echo "========================================"
rm -f "$TMP_OUT" "${TMP_OUT}.norm" "${TMP_OUT}.exp"

if [ $FAIL -eq 0 ]; then
  echo "All error-format tests passed."
  exit 0
else
  echo "Failures: $FAIL"
  exit 1
fi
