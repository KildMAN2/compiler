#!/bin/bash

# Verifies the provided homework4_final/examples by running the produced .e in rx-vm
# and comparing stdout/stderr output against homework4_final/examples_expected/*.out.
#
# Usage:
#   ./check_examples_e.sh            # compare against existing expected outputs
#   ./check_examples_e.sh --update   # regenerate expected outputs from current run
#   ./check_examples_e.sh --include-vm  # compare including VM prompts + "Reached Halt."
#
# Notes:
# - By default, this compares *program output only* (it strips VM prompts and "Reached Halt.")
#   to match the student_tests checker behavior.
# - Runs compilation/linking in a temp dir so it doesn't dirty the repo.

set -u

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
EX_DIR="$ROOT_DIR/examples"
EXP_DIR="$ROOT_DIR/examples_expected"
COMPILER="$ROOT_DIR/rx-cc"
LINKER="$ROOT_DIR/rx-linker"
VM="$ROOT_DIR/rx-vm"

UPDATE=0
INCLUDE_VM=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --update) UPDATE=1 ;;
    --include-vm) INCLUDE_VM=1 ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ ! -x "$COMPILER" ] || [ ! -x "$LINKER" ] || [ ! -x "$VM" ]; then
  echo "Missing tools: ensure rx-cc, rx-linker, rx-vm are executable in $ROOT_DIR" >&2
  exit 2
fi

mkdir -p "$EXP_DIR"

normalize_out() {
  # normalize CRLF to LF
  tr -d '\r' \
  | (
      if [ "$INCLUDE_VM" -eq 1 ]; then
        cat
      else
        # Strip VM prompts + trailer and normalize trailing whitespace/newlines
        perl -0777 -pe 's/Input integer\?:|Input real\?:|Reached Halt\.//g; s/\s*\z/\n/'
      fi
    )
}

run_one() {
  local name="$1"    # example1..example7
  local main="$2"    # main cmm file name inside examples dir
  shift 2
  local libs=("$@")  # extra modules

  local tmp
  tmp="$(mktemp -d)"

  # Copy sources + inputs into temp
  cp "$EX_DIR/$main" "$tmp/"
  for l in "${libs[@]}"; do
    cp "$EX_DIR/$l" "$tmp/"
  done
  if [ -f "$EX_DIR/${name}.in" ]; then
    cp "$EX_DIR/${name}.in" "$tmp/input.in"
  else
    : > "$tmp/input.in"
  fi

  # Compile modules
  local rsk_files=()
  (cd "$tmp" && "$COMPILER" "$tmp/$main" >/dev/null 2>/dev/null) || { echo "[$name] Failed"; rm -rf "$tmp"; return 0; }
  rsk_files+=("$tmp/${main%.cmm}.rsk")
  for l in "${libs[@]}"; do
    (cd "$tmp" && "$COMPILER" "$tmp/$l" >/dev/null 2>/dev/null) || { echo "[$name] Failed"; rm -rf "$tmp"; return 0; }
    rsk_files+=("$tmp/${l%.cmm}.rsk")
  done

  # Link (from ROOT_DIR so runtime is found)
  (cd "$ROOT_DIR" && "$LINKER" "${rsk_files[@]}" >/dev/null 2>/dev/null) || { echo "[$name] Failed"; rm -rf "$tmp"; return 0; }

  local e_file="$tmp/${main%.cmm}.e"
  if [ ! -f "$e_file" ]; then
    echo "[$name] Failed"
    rm -rf "$tmp"
    return 0
  fi

  # Run VM
  local got="$tmp/got.out"
  if [ -s "$tmp/input.in" ]; then
    timeout 2 "$VM" "$e_file" < "$tmp/input.in" >"$got" 2>&1
  else
    timeout 2 "$VM" "$e_file" >"$got" 2>&1
  fi

  normalize_out < "$got" > "$tmp/got.norm"

  local expected="$EXP_DIR/${name}.out"
  if [ "$UPDATE" -eq 1 ] || [ ! -f "$expected" ]; then
    cp "$tmp/got.norm" "$expected"
    echo "[$name] UPDATED"
    rm -rf "$tmp"
    return 0
  fi

  normalize_out < "$expected" > "$tmp/exp.norm"

  if diff -q "$tmp/exp.norm" "$tmp/got.norm" >/dev/null 2>&1; then
    echo "[$name] VERIFIED"
  else
    echo "[$name] MISMATCH"
    echo "--- expected ---"
    cat "$tmp/exp.norm"
    echo "--- got ---"
    cat "$tmp/got.norm"
    echo "--- diff -u ---"
    diff -u "$tmp/exp.norm" "$tmp/got.norm" || true
    rm -rf "$tmp"
    return 1
  fi

  rm -rf "$tmp"
  return 0
}

# example3 is multi-module
FAIL=0
run_one example1 example1.cmm || FAIL=1
run_one example2 example2.cmm || FAIL=1
run_one example3 example3-main.cmm example3-funcs.cmm || FAIL=1
run_one example4 example4.cmm || FAIL=1
run_one example6 example6.cmm || FAIL=1
run_one example7 example7.cmm || FAIL=1

if [ $FAIL -eq 0 ]; then
  echo "All example .e outputs verified."
  exit 0
else
  echo "Some example .e outputs mismatched."
  exit 1
fi
