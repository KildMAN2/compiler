#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="${1:-}"
if [[ -z "${ARCHIVE}" ]]; then
  echo "Usage: $0 proj-part3-tests-<id1>-<id2>.tar.bz2"
  exit 2
fi

if [[ ! -f "${ARCHIVE}" ]]; then
  echo "ERROR: Archive not found: ${ARCHIVE}"
  exit 1
fi

echo "== (1) Checking tar.bz2 can be listed =="
if ! tar -tjf "${ARCHIVE}" >/dev/null 2>&1; then
  echo "ERROR: tar can't read this as .tar.bz2 (corrupt or wrong format)."
  exit 1
fi
echo "OK: archive is readable."

echo "== (2) Checking structure inside archive =="
mapfile -t RAW < <(tar -tjf "${ARCHIVE}" | sed 's#^\./##' | sed '/^$/d')

# Collect top-level dirs (before first '/')
# Use version sort so test10 comes after test9
TOPS="$(printf '%s\n' "${RAW[@]}" | awk -F/ '{print $1}' | sort -u -V)"

# Expect exactly test1..test10 and nothing else
EXPECTED="$(printf 'test%d\n' {1..10} | sort -V)"
if ! diff -u <(echo "${EXPECTED}") <(echo "${TOPS}") >/dev/null; then
  echo "ERROR: Top-level entries must be exactly test1..test10"
  echo "Found:"
  echo "${TOPS}"
  exit 1
fi
echo "OK: top-level dirs are test1..test10"

# Ensure no nested dirs beyond testX/<file>
BAD_NEST="$(printf '%s\n' "${RAW[@]}" | awk -F/ 'NF>=3 {print}' | head -n 1 || true)"
if [[ -n "${BAD_NEST}" ]]; then
  echo "ERROR: Found nested subdirectory/file path (should be only testX/<file>): ${BAD_NEST}"
  exit 1
fi
echo "OK: no subdirectories inside test folders"

echo "== (3) Checking required files per test folder =="
FAIL=0
for i in {1..10}; do
  T="test$i"
  HAS_INPUT=0
  HAS_OUTPUT=0
  HAS_PASS=0
  HAS_FAIL=0
  HAS_CMM=0
  HAS_INPUT_IN=0
  HAS_INPUT_INPUT=0

  while IFS= read -r p; do
    [[ "${p}" == "${T}/"* ]] || continue
    f="${p#${T}/}"
    [[ -z "${f}" ]] && continue

    case "${f}" in
      input.in)   HAS_INPUT=1 ;;
      input.input) HAS_INPUT=1 ;;
      output.out) HAS_OUTPUT=1 ;;
      pass)       HAS_PASS=1 ;;
      fail)       HAS_FAIL=1 ;;
      *.cmm)      HAS_CMM=1 ;;
      *)          echo "ERROR: ${T} has unexpected file: ${f}"; FAIL=1 ;;
    esac
  done < <(printf '%s\n' "${RAW[@]}")

  # Accept either input.in (spec) or input.input (course examples)
  if [[ "${HAS_INPUT}" -ne 1 ]]; then echo "ERROR: ${T} missing input file (expected input.in or input.input)"; FAIL=1; fi
  if [[ "${HAS_OUTPUT}" -ne 1 ]]; then echo "ERROR: ${T} missing output.out"; FAIL=1; fi
  if [[ "${HAS_CMM}" -ne 1 ]]; then echo "ERROR: ${T} missing at least one .cmm file"; FAIL=1; fi
  if [[ $((HAS_PASS + HAS_FAIL)) -ne 1 ]]; then
    echo "ERROR: ${T} must contain exactly one of: pass OR fail"
    FAIL=1
  fi
done

if [[ "${FAIL}" -ne 0 ]]; then
  echo "STRUCTURE CHECK: FAILED"
  exit 1
fi
echo "STRUCTURE CHECK: OK"

echo "== (4) Optional: run checker on extracted archive =="
if [[ -x "./checker" && -f "./rx-runtime.rsk" ]]; then
  BASE_DIR="$(pwd)"
  CHECKER_PATH="${BASE_DIR}/checker"
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT

  tar -xjf "${ARCHIVE}" -C "${TMP}"

  ALL_OK=1
  for i in {1..10}; do
    T="test$i"
    CMM=( "${TMP}/${T}"/*.cmm )
    INPUT_FILE="${TMP}/${T}/input.in"
    if [[ ! -f "${INPUT_FILE}" ]]; then
      INPUT_FILE="${TMP}/${T}/input.input"
    fi
    RES="$(cd "${BASE_DIR}" && "${CHECKER_PATH}" "${CMM[@]}" "${INPUT_FILE}" "${TMP}/${T}/output.out" | xargs)"
    if [[ -f "${T}/pass" ]]; then
      [[ "${RES}" == "True" ]] || { echo "MISMATCH: ${T} expected True, got ${RES}"; ALL_OK=0; }
    else
      [[ "${RES}" == "Failed" ]] || { echo "MISMATCH: ${T} expected Failed, got ${RES}"; ALL_OK=0; }
    fi
  done


  if [[ "${ALL_OK}" -ne 1 ]]; then
    echo "CHECKER RUN: FAILED"
    exit 1
  fi
  echo "CHECKER RUN: OK"
else
  echo "SKIP: ./checker or rx-runtime.rsk not found here (structure checks already passed)."
fi

echo "ALL GOOD."
