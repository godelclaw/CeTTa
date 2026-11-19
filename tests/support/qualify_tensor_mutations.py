#!/usr/bin/env python3
"""ASan/UBSan controls: compiled lifetime and value-policy defects must fail."""
import argparse
import os
from pathlib import Path
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCES = ("tests/test_tensor.c", "src/tensor_dense_v1.c", "src/atom.c", "src/symbol.c",
           "src/scalar_trie.c", "src/binding/frame_identity.c", "src/atom_wire.c",
           "src/durable_value.c", "src/tensor_files_v1.c")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    options = parser.parse_args()
    output = options.output_dir.resolve()
    output.mkdir(parents=True, exist_ok=True)
    cc = shlex.split(os.environ.get("CC", "cc"))
    flags = ["-O1", "-g", "-Wall", "-Werror", "-std=c11", "-pthread", "-Isrc", "-I.",
             "-fsanitize=address,undefined", "-fno-omit-frame-pointer"]

    def compile_source(source, target):
        result = subprocess.run(cc + flags + ["-c", str(source), "-o", str(target)],
                                cwd=ROOT, capture_output=True, text=True, timeout=120)
        (target.with_suffix(".compile.log")).write_text(result.stdout + result.stderr)
        if result.returncode:
            raise RuntimeError(f"Compilation failed: {source}; see {target.with_suffix('.compile.log')}")

    objects = []
    for name in SOURCES:
        target = output / (name.replace("/", "_") + ".o")
        compile_source(ROOT / name, target)
        objects.append(target)

    def run(label, inputs, broken=False):
        binary = output / label
        subprocess.run(cc + flags + [str(item) for item in inputs] + ["-lm", "-o", str(binary)],
                       cwd=ROOT, check=True, timeout=60)
        env = {**os.environ, "ASAN_OPTIONS": "detect_leaks=1:halt_on_error=1",
               "UBSAN_OPTIONS": "halt_on_error=1", "CETTA_SANITIZER_REPEATABLE": "1",
               "CETTA_WRAPPED_BIN": str(binary)}
        result = subprocess.run([str(ROOT / "scripts/cetta_exec.sh")], cwd=ROOT,
                                env=env, capture_output=True, text=True, timeout=60)
        evidence = result.stdout + result.stderr
        (output / f"{label}.run.log").write_text(evidence)
        if not broken:
            if result.returncode:
                raise RuntimeError(f"Correct baseline failed: {label}")
        elif not result.returncode or not any(marker in evidence for marker in
                ("Assertion", "heap-use-after-free", "runtime error:", "double-free",
                 "AddressSanitizer: SEGV")):
            raise RuntimeError(f"Mutation did not produce the expected rejection: {label}")
        print(f"PASS: {label}" + (" rejected" if broken else ""), flush=True)

    run("baseline", objects)
    # Exercise the portable rounding-admission branch on the same machine,
    # retaining the original numerical providers. FTZ/DAZ controls in the unit
    # fixture must still force a complete candidate set.
    original = (ROOT / "src/tensor_dense_v1.c").read_text()
    anchor = '#if CETTA_HAS_AVX4\n    /* FTZ and DAZ violate the absolute underflow allowance below. */'
    if original.count(anchor) != 1:
        raise RuntimeError("Portable admission anchor changed")
    source = output / "portable-admission.c"
    source.write_text(original.replace(anchor, anchor.replace('#if CETTA_HAS_AVX4', '#if 0')))
    target = source.with_suffix(".o")
    compile_source(source, target)
    inputs = list(objects)
    inputs[SOURCES.index("src/tensor_dense_v1.c")] = target
    run("portable-admission", inputs)
    controls = (
        ("missing-view-hold", "src/tensor_dense_v1.c",
         "size_t old = atomic_fetch_add_explicit(&tensor->storage->holds, 1u, memory_order_relaxed);\n"
         "        if (!old || old == SIZE_MAX) abort();", "/* missing hold */"),
        ("mutating-saved-input", "src/tensor_dense_v1.c",
         "memcpy((*out)->storage->data + index * width, element, width);",
         "memcpy(tensor->storage->data + index * width, element, width);"),
        ("overflow-before-zero-axis", "src/tensor_dense_v1.c",
         "    for (size_t i = 0; i < rank; ++i) {\n"
         "        if (!shape[i]) { *count = 0u; *bytes = 0u; return CETTA_DENSE_TENSOR_V1_OK; }\n    }\n",
         ""),
        ("reversed-decoder", "src/tensor_dense_v1.c",
         "value |= (uint64_t)src[i] << (8u * i);",
         "value |= (uint64_t)src[i] << (8u * (width - 1u - i));"),
        ("unaccounted-buffer", "src/atom.c",
         "arena_account_external_bytes(a, cetta_dense_tensor_v1_retained_bytes(value));",
         "/* omitted allocation charge */"),
        ("screening-drops-boundary-tie", "src/tensor_dense_v1.c",
         "double threshold = held ? heap[0] : INFINITY;",
         "double threshold = held ? nextafter(heap[0], INFINITY) : INFINITY;"),
        ("screening-ignores-error", "src/tensor_dense_v1.c",
         "double radius = add_up(mul_up(multiplier, add_up(error, mul_up(relative, magnitude))), underflow);",
         "double radius = 0 * (multiplier + error + relative + magnitude + underflow);"),
        ("int8-screen-ignores-query-error", "src/tensor_dense_v1.c",
         "(copy * qerror + relative_a * fabs(approximate))",
         "(relative_a * fabs(approximate))"),
        ("int8-dot-drops-last-code", "src/tensor_dense_v1.c",
         "    for (size_t j = 0; j < width; ++j) total += (int32_t)a[j] * (int32_t)b[j];",
         "    for (size_t j = 0; j + 1 < width; ++j) total += (int32_t)a[j] * (int32_t)b[j];"),
        ("lazy-hash-omits-shape", "src/tensor_dense_v1.c",
         "    for (size_t i = 0; i < tensor->rank; ++i) hash = hash_word(hash, tensor->shape[i]);\n    atomic_store_explicit(&cache->hash",
         "    atomic_store_explicit(&cache->hash"),
        ("equality-trusts-one-known-hash", "src/tensor_dense_v1.c",
         "if ((a & HASH_KNOWN) && (b & HASH_KNOWN) && a != b) return false;",
         "if (((a & HASH_KNOWN) || (b & HASH_KNOWN)) && a != b) return false;"),
        ("npy-ignores-fortran-order", "src/tensor_files_v1.c",
         "    if (!entry->fortran_order) {\n        for (size_t i = 0; i < count; ++i)",
         "    if (1) {\n        for (size_t i = 0; i < count; ++i)"),
        ("safetensors-allows-holes", "src/tensor_files_v1.c",
         "        if (file->entries[i].offset != next)\n",
         "        if (0)\n"),
        ("half-misplaces-exponent", "src/tensor_files_v1.c",
         "bits = sign | (exponent + 112u) << 23u | mantissa << 13u;",
         "bits = sign | (exponent + 111u) << 23u | mantissa << 13u;"),
        ("share-ignores-alignment", "src/tensor_files_v1.c",
         "    if (entry->offset % entry->width != 0u) return \"data not aligned to its element width\";\n",
         ""),
        ("u64-wraps-into-i64", "src/tensor_files_v1.c",
         "        if (raw > (uint64_t)INT64_MAX)\n",
         "        if (0)\n"),
        ("shared-view-drops-mapping", "src/tensor_files_v1.c",
         "        atomic_fetch_add_explicit(&mapping->refs, 1u, memory_order_relaxed);\n",
         ""),
        ("npy-writer-aligns-to-16", "src/tensor_files_v1.c",
         "size_t padded = (total + 63u) / 64u * 64u;",
         "size_t padded = (total + 15u) / 16u * 16u;"),
        ("string-count-checks-first", "src/tensor_files_v1.c",
         "    for (size_t i = 0; i < n; ++i) {\n        const char *text;\n        size_t length;\n"
         "        if (!cetta_tensor_string_at(offsets, bytes, i, &text, &length, e)) return false;",
         "    for (size_t i = 0; i < n && i < 1u; ++i) {\n        const char *text;\n        size_t length;\n"
         "        if (!cetta_tensor_string_at(offsets, bytes, i, &text, &length, e)) return false;"),
        ("int8-f32-reads-first-row", "src/tensor_dense_v1.c",
         "widened[j] = (double)narrow_data[row * width + j];",
         "widened[j] = (double)narrow_data[j];"),
        ("safetensors-writer-keeps-order", "src/tensor_files_v1.c",
         "for (; k > 0u && written_before(moving, order[k - 1u], names, tensors); --k)",
         "for (; 0 && k > 0u && written_before(moving, order[k - 1u], names, tensors); --k)"),
        ("string-index-accepts-duplicates", "src/tensor_files_v1.c",
         "if (string_span(offsets, bytes, row, &other, &size, e) && size == length && !memcmp(other, text, length)) {",
         "if (0 && string_span(offsets, bytes, row, &other, &size, e) && size == length && !memcmp(other, text, length)) {"),
        ("string-index-fills-every-slot", "src/tensor_files_v1.c",
         "while (capacity / 2u < n) {", "while (capacity < n) {"),
        ("string-find-trusts-its-slots", "src/tensor_files_v1.c",
         "if (size == length && !memcmp(text, value, length)) {\n            *row = slot;",
         "if (1) {\n            *row = slot;"),
        ("string-mask-matches-prefixes", "src/tensor_files_v1.c",
         "mask[i] = size == length && !memcmp(text, value, length);",
         "mask[i] = size >= length && !memcmp(text, value, length);"),
        ("boolean-values-unchecked", "src/tensor_files_v1.c",
         "if (booleans && booleans[i] && !boolean_values(tensors[i]))",
         "if (0 && booleans && booleans[i] && !boolean_values(tensors[i]))"),
        ("open-all-shares-converted-tensors", "src/tensor_files_v1.c",
         "bool share = mode == READ_SHARE || (mode == READ_SHARE_WHERE_STORED && !entry->copy_reason);",
         "bool share = mode != READ_COPY;"),
        ("mask-equal-reads-first-single", "src/tensor_dense_v1.c",
         "{ memcpy(&x, data + i * width, 4u); mask[i] = x == wanted; }",
         "{ memcpy(&x, data, 4u); mask[i] = x == wanted; }"),
    )
    for label, name, old, replacement in controls:
        original = (ROOT / name).read_text()
        if original.count(old) != 1:
            raise RuntimeError(f"Mutation anchor changed: {label}")
        source = output / f"{label}.c"
        source.write_text(original.replace(old, replacement))
        target = source.with_suffix(".o")
        compile_source(source, target)
        inputs = list(objects)
        inputs[SOURCES.index(name)] = target
        run(label, inputs, broken=True)
    print(f"PASS: {len(controls)} compiled tensor defects rejected")


if __name__ == "__main__":
    main()
