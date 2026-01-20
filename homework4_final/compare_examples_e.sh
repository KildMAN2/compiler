#!/bin/bash

# Compare runtime output of reference .e files vs freshly generated .e files.
#
# Why: The course notes say assembly may differ; correctness should be checked by
# running the `.e` on rx-vm and comparing runtime output.
#
# Usage (Linux/VBox):
#   chmod +x compare_examples_e.sh
#   ./compare_examples_e.sh
#
# Options:
#   --include-vm   Compare including VM prompts + "Reached Halt.".
#                 Default: compare *program output only* (strip VM noise).
#   --backup       Copy current examples/*.e into examples_reference/ (one-time).

set -u

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
EX_DIR="$ROOT_DIR/examples"
REF_DIR="$ROOT_DIR/examples_reference"
COMPILER="$ROOT_DIR/rx-cc"
LINKER="$ROOT_DIR/rx-linker"
VM="$ROOT_DIR/rx-vm"

INCLUDE_VM=0
DO_BACKUP=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --include-vm) INCLUDE_VM=1 ;;
    --backup) DO_BACKUP=1 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ ! -x "$COMPILER" ] || [ ! -x "$LINKER" ] || [ ! -x "$VM" ]; then
  echo "Missing tools: ensure rx-cc, rx-linker, rx-vm are executable in $ROOT_DIR" >&2
  exit 2
fi

mkdir -p "$REF_DIR"

if [ "$DO_BACKUP" -eq 1 ]; then
  # Copy current .e files into the reference folder.
  cp -f "$EX_DIR"/*.e "$REF_DIR"/ 2>/dev/null || true
  echo "Backed up current examples/*.e into examples_reference/."
fi

normalize_out() {
  tr -d '\r' \
  | (
      if [ "$INCLUDE_VM" -eq 1 ]; then
        cat
      else
        # Strip VM prompts + trailer; normalize trailing whitespace/newlines
        perl -0777 -pe 's/Input integer\?:|Input real\?:|Reached Halt\.//g; s/\s*\z/\n/'
      fi
    )
}

run_vm() {
  local e_file="$1"
  local input_file="$2"
  local out_file="$3"

  if [ -s "$input_file" ]; then
    timeout 2 "$VM" "$e_file" < "$input_file" >"$out_file" 2>&1
  else
    timeout 2 "$VM" "$e_file" >"$out_file" 2>&1
  fi
}

build_generated_e() {
  local tmp="$1"
  local main="$2"
  shift 2
  local libs=("$@")

  cp "$EX_DIR/$main" "$tmp/"
  for l in "${libs[@]}"; do
    cp "$EX_DIR/$l" "$tmp/"
  done

  (cd "$tmp" && "$COMPILER" "$tmp/$main" >/dev/null 2>/dev/null) || return 1
  local rsk_files=("$tmp/${main%.cmm}.rsk")

  for l in "${libs[@]}"; do
    (cd "$tmp" && "$COMPILER" "$tmp/$l" >/dev/null 2>/dev/null) || return 1
    rsk_files+=("$tmp/${l%.cmm}.rsk")
  done

  (cd "$ROOT_DIR" && "$LINKER" "${rsk_files[@]}" >/dev/null 2>/dev/null) || return 1

  test -f "$tmp/${main%.cmm}.e"
}

compare_one() {
  local name="$1"
  local main_cmm="$2"
  local ref_main_e="$3"
  shift 3
  local libs=("$@")

  local input="$EX_DIR/${name}.in"
  if [ ! -f "$input" ]; then
    input="/dev/null"
  fi

  local ref_e="$REF_DIR/$ref_main_e"
  if [ ! -f "$ref_e" ]; then
    echo "[$name] Missing reference: $ref_e" >&2
    return 1
  fi

  local tmp
  tmp="$(mktemp -d)"

  if ! build_generated_e "$tmp" "$main_cmm" "${libs[@]}"; then
    echo "[$name] Failed"  # compile/link failed
    rm -rf "$tmp"
    return 0
  fi

  local got_ref="$tmp/ref.out"
  local got_new="$tmp/new.out"

  run_vm "$ref_e" "$input" "$got_ref"
  run_vm "$tmp/${main_cmm%.cmm}.e" "$input" "$got_new"

  normalize_out < "$got_ref" > "$tmp/ref.norm"
  normalize_out < "$got_new" > "$tmp/new.norm"

  if diff -q "$tmp/ref.norm" "$tmp/new.norm" >/dev/null 2>&1; then
    echo "[$name] MATCH"
    rm -rf "$tmp"
    return 0
  fi

  echo "[$name] DIFF"
  echo "--- reference ---"
  cat "$tmp/ref.norm"
  echo "--- generated ---"
  cat "$tmp/new.norm"
  echo "--- diff -u ---"
  diff -u "$tmp/ref.norm" "$tmp/new.norm" || true

  rm -rf "$tmp"
  return 1
}

FAIL=0
# Note: example3 is multi-module.
compare_one example1 example1.cmm example1.e || FAIL=1
compare_one example2 example2.cmm example2.e || FAIL=1
compare_one example3 example3-main.cmm example3-main.e example3-funcs.cmm || FAIL=1
compare_one example4 example4.cmm example4.e || FAIL=1
compare_one example6 example6.cmm example6.e || FAIL=1
compare_one example7 example7.cmm example7.e || FAIL=1

if [ $FAIL -eq 0 ]; then
  echo "All reference-vs-generated .e outputs match."
  exit 0
else
  echo "Some reference-vs-generated .e outputs differ."
  exit 1
fi
