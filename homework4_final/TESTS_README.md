# homework4_final – Test Bundle

This folder contains a full “run everything” test runner plus 3 suites:
- `student_tests/` – runtime tests (some expected PASS, some expected FAIL)
- `edge_tests/` – runtime edge cases focused on spec-sensitive behavior
- `error_format_tests/` – golden tests for exact stderr format (lex/syntax/semantic)
- `compare_examples_e.sh` – reference-vs-generated **runtime equivalence** using `.e` output

## Prerequisites (VirtualBox / Linux recommended)
From inside `homework4_final/`, you should have these executables present:
- `./rx-cc`
- `./rx-linker`
- `./rx-vm`
- `./rx-runtime.rsk`

The scripts assume common Linux tools exist: `bash`, `diff`, `perl`, `timeout`.

## Quick start (run everything)
```bash
cd homework4_final
chmod +x run_all_tests.sh compare_examples_e.sh \
  student_tests/checker.sh student_tests/verify_tests.sh \
  edge_tests/verify_edge_tests.sh error_format_tests/run_error_format_tests.sh

bash ./run_all_tests.sh
```

Expected final line:
- `All test suites passed.`

## Run suites individually
```bash
cd homework4_final

# Runtime equivalence: compare reference .e vs freshly generated .e
bash ./compare_examples_e.sh

# Student suite
(cd student_tests && bash ./verify_tests.sh)

# Edge suite
(cd edge_tests && bash ./verify_edge_tests.sh)

# Error format (stderr golden tests)
(cd error_format_tests && bash ./run_error_format_tests.sh)
```

## Notes for Windows editors (CRLF)
If you edit `.sh` files on Windows and then run on Linux, you may hit CRLF issues.
Fix by running (Linux):
```bash
sed -i 's/\r$//' run_all_tests.sh compare_examples_e.sh \
  student_tests/*.sh edge_tests/*.sh error_format_tests/*.sh
```

## What is checked
- Correctness is judged by **program output** (not assembly diffs).
- VM noise is stripped by the checker by default (`Input integer?:`, `Input real?:`, `Reached Halt.`).
- Error-format tests compare exact stderr strings.

## Comment style
- Source comments are **part1-style**: single-line comments start with `#`.
- Using `//` is **not allowed** and is expected to produce a **Lexical error** (tested under `error_format_tests`).
