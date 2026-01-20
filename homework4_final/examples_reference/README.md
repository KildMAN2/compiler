# examples_reference

This folder is a backup of **reference** `.e` executables (e.g., from the course site or a known-good build).

The goal matches the course instructions: validate your compiler by **running the `.e` on `rx-vm`** and comparing runtime output.

## Files

Place/copy reference executables here:
- `example1.e`, `example2.e`, `example3-main.e`, `example3-funcs.e`, `example4.e`, `example6.e`, `example7.e`

Inputs should remain in `../examples/*.in`.

## Compare

From `homework4_final/` on Linux:
- `./compare_examples_e.sh`

This recompiles the `.cmm` in `examples/` to a *fresh* `.e` (in a temp dir), runs both reference and generated `.e` on `rx-vm`, and diffs the outputs.
