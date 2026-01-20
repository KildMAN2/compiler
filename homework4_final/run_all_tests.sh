#!/bin/bash

# One command to run everything "staff-like":
# - runtime correctness via reference-vs-generated .e outputs
# - student_tests suite
# - edge_tests suite
# - error format suite (lex/syntax/semantic golden stderr)

set -u

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
FAIL=0

run_step() {
  local name="$1"
  local cmd="$2"

  echo "========================================"
  echo "$name"
  echo "========================================"

  (cd "$ROOT_DIR" && bash -lc "$cmd")
  if [ $? -ne 0 ]; then
    echo "[FAIL] $name"
    FAIL=1
  else
    echo "[OK] $name"
  fi
}

run_step "compare_examples_e (.e runtime equivalence)" "bash ./compare_examples_e.sh"
run_step "student_tests" "cd student_tests && bash ./verify_tests.sh"
run_step "edge_tests" "cd edge_tests && bash ./verify_edge_tests.sh"
run_step "error_format_tests" "cd error_format_tests && bash ./run_error_format_tests.sh"

echo "========================================"
if [ $FAIL -eq 0 ]; then
  echo "All test suites passed."
  exit 0
else
  echo "Some test suites failed."
  exit 1
fi
