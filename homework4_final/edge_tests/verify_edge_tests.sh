#!/bin/bash

# Runs runtime edge-case tests (compile + link + run + compare output)
# Uses the same checker as student_tests to normalize VM noise.

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECKER="$ROOT_DIR/student_tests/checker.sh"

if [ ! -x "$CHECKER" ]; then
  if [ ! -f "$CHECKER" ]; then
    echo "Error: checker missing: $CHECKER"
    exit 1
  fi
fi

MISMATCH=0

run_dir() {
  local d="$1"

  local input="$d/input.in"
  local output="$d/output.out"

  if [ ! -f "$input" ] || [ ! -f "$output" ]; then
    echo "[$d] Skipping (missing input.in or output.out)"
    return
  fi

  shopt -s nullglob
  local cmm=("$d"/*.cmm)
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

  if [ "$result" = "True" ]; then
    echo "[$d] VERIFIED"
  else
    echo "[$d] MISMATCH: got $result"
    if [ "$result" = "False" ]; then
      bash "$CHECKER" --debug "${ordered[@]}" "$input" "$output" 2>/dev/null | tail -n +2
    fi
    MISMATCH=$((MISMATCH+1))
  fi
}

echo "========================================"
echo "Verifying edge_tests runtime suite"
echo "========================================"

for d in "$ROOT_DIR/edge_tests"/t*; do
  [ -d "$d" ] || continue
  run_dir "$d"
done

echo "========================================"
if [ $MISMATCH -eq 0 ]; then
  echo "All edge_tests verified."
  exit 0
else
  echo "Mismatches: $MISMATCH"
  exit 1
fi
