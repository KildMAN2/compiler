#!/bin/bash

# Verifies test1..test10 using ./checker.sh
# PASS tests must print True, FAIL tests must print Failed

set -u

CHECKER="./checker.sh"

if [ ! -f "$CHECKER" ]; then
  echo "Error: checker.sh missing: $CHECKER"
  exit 1
fi

MISMATCH=0

run_dir() {
  local d="$1"

  if [ ! -d "$d" ]; then
    echo "[$d] Skipping (missing dir)"
    return
  fi

  local input="$d/input.in"
  local output="$d/output.out"

  if [ ! -f "$input" ] || [ ! -f "$output" ]; then
    echo "[$d] Skipping (missing input.in or output.out)"
    return
  fi

  local expected=""
  local kind=""
  if [ -f "$d/pass" ]; then
    expected="True"
    kind="PASS"
  elif [ -f "$d/fail" ]; then
    expected="Failed"
    kind="FAIL"
  else
    echo "[$d] Skipping (missing pass/fail marker)"
    return
  fi

  shopt -s nullglob
  local cmm=($d/*.cmm)
  shopt -u nullglob

  if [ ${#cmm[@]} -eq 0 ]; then
    echo "[$d] Skipping (no .cmm files)"
    return
  fi

  # Ensure test.cmm is first if present
  local ordered=()
  if [ -f "$d/test.cmm" ]; then
    ordered+=("$d/test.cmm")
    for f in "${cmm[@]}"; do
      [ "$f" = "$d/test.cmm" ] && continue
      ordered+=("$f")
    done
  else
    ordered=("${cmm[@]}")
  fi

  local result
  result=$(bash "$CHECKER" "${ordered[@]}" "$input" "$output" 2>/dev/null | tr -d '\r' | head -n 1)

  if [ "$result" = "$expected" ]; then
    echo "[$d] VERIFIED ($kind)"
  else
    echo "[$d] MISMATCH: expected $expected, got $result"
    if [ "$result" = "False" ]; then
      bash "$CHECKER" --debug "${ordered[@]}" "$input" "$output" 2>/dev/null | tail -n +2
    fi
    MISMATCH=$((MISMATCH+1))
  fi
}

echo "========================================"
echo "Verifying 10 student_tests"
echo "========================================"

for i in {1..10}; do
  run_dir "test$i"
done

echo "========================================"
if [ $MISMATCH -eq 0 ]; then
  echo "All student tests verified."
  exit 0
else
  echo "Mismatches: $MISMATCH"
  exit 1
fi
