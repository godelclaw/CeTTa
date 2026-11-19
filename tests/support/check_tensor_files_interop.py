#!/usr/bin/env python3
"""Tensor files against the reference libraries, both ways (needs numpy and safetensors).

NumPy and safetensors write arrays of every element type, shape, byte order and
layout that CeTTa reads; CeTTa loads each (and maps those it can share) and
writes it back as .npy, which must equal NumPy's own conversion bit for bit.
Then CeTTa writes .npy and .safetensors files that NumPy and safetensors read."""
import argparse
import shutil
import struct
import subprocess
import sys
from pathlib import Path

import numpy as np
from safetensors import safe_open
from safetensors.numpy import load_file, save_file

ROOT = Path(__file__).resolve().parents[2]
SHAREABLE = {np.dtype("<f8"), np.dtype("<f4"), np.dtype("<i8"), np.dtype("|u1"), np.dtype("|b1")}


def cetta_kind(dtype):
    """The element type CeTTa loads a stored type as, and the NumPy cast that matches."""
    if dtype.kind == "f":
        return np.float64 if dtype.itemsize == 8 else np.float32
    if dtype.kind in "iu" and dtype.itemsize == 1 and dtype.kind == "u":
        return np.uint8
    if dtype.kind == "b":
        return np.uint8
    return np.int64


def same_bits(a, b):
    return a.dtype == b.dtype and a.shape == b.shape and a.tobytes() == b.tobytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cetta", required=True, type=Path)
    args = parser.parse_args()
    work = ROOT / "runtime" / "tensor-files-interop"
    shutil.rmtree(work, ignore_errors=True)
    (work / "in").mkdir(parents=True)
    (work / "out").mkdir()
    rng = np.random.default_rng(20261119)
    cases = []

    def add(name, array, fmt="npy"):
        cases.append((name, array, fmt))

    for dtype in ("<f8", "<f4", "<f2", ">f8", ">f4", "<i8", "<i4", "<i2", "|i1", ">i8", "<u4", "<u2", "|u1", "|b1"):
        dt = np.dtype(dtype)
        for shape in ((), (0,), (5,), (3, 4), (2, 3, 4)):
            if dt.kind == "f":
                data = rng.standard_normal(shape) * 1e3
                data = data.astype(dt)
            elif dt.kind == "b":
                data = rng.integers(0, 2, shape).astype(dt)
            else:
                info = np.iinfo(dt)
                data = rng.integers(info.min, info.max, shape, endpoint=True, dtype=np.int64 if dt.kind == "i" else np.uint64).astype(dt)
            add(f"{dt.str.replace('<', 'le').replace('>', 'be').replace('|', '')}_{'x'.join(map(str, shape)) or 'scalar'}", data)
            if len(shape) >= 2:
                add(f"{dt.str.replace('<', 'le').replace('>', 'be').replace('|', '')}_{'x'.join(map(str, shape))}_fortran",
                    np.asfortranarray(data))
    add("u64_fits", np.array([0, 2 ** 63 - 1, 12345], dtype="<u8"))
    special = np.array([np.inf, -np.inf, np.nan, -0.0, 5e-324, 1e308], dtype="<f8")
    add("f64_special", special)
    add("f16_special", np.array([np.inf, -np.inf, np.nan, -0.0, 6e-8, 65504], dtype="<f2"))
    for dtype in ("<f8", "<f4", "<f2", "<i8", "<i4", "<i2", "|i1", "<u4", "<u2", "|u1", "|b1"):
        dt = np.dtype(dtype)
        data = rng.standard_normal((3, 2)).astype(dt) if dt.kind == "f" else rng.integers(0, 100, (3, 2)).astype(dt)
        add(f"st_{dt.kind}{dt.itemsize}", data, "safetensors")

    lines = ["!(import! &self (library lib_tensor))"]
    for i, (name, array, fmt) in enumerate(cases):
        source = work / "in" / f"{i}.{fmt}"
        if fmt == "npy":
            np.save(source, array)
        else:
            save_file({"t": np.array(array, order="C")}, str(source))
        load = f'(tensor:load "{source}")'
        lines.append(f'!(tensor:save-npy "{work / "out" / f"{i}.npy"}" {load})')
        if fmt == "npy" and array.dtype in SHAREABLE and (array.ndim < 2 or array.flags["C_CONTIGUOUS"]):
            lines.append(f'!(tensor:save-npy "{work / "out" / f"{i}.mapped.npy"}" (tensor:map "{source}"))')
    # bf16 has no NumPy type: written by hand as the upper halves of f32 values.
    bf_values = np.array([1.0, -2.0, 0.15625, 3.0e38, -1e-38], dtype="<f4")
    bf_bytes = b"".join(struct.pack("<f", v)[2:] for v in bf_values)
    header = ('{"b":{"dtype":"BF16","shape":[5],"data_offsets":[0,%d]}}' % len(bf_bytes)).encode()
    header += b" " * ((8 - (8 + len(header)) % 8) % 8)
    (work / "in" / "bf16.safetensors").write_bytes(struct.pack("<Q", len(header)) + header + bf_bytes)
    lines.append(f'!(tensor:save-npy "{work / "out" / "bf16.npy"}" (tensor:load "{work / "in" / "bf16.safetensors"}"))')
    # CeTTa writes; NumPy and safetensors read.
    lines.append(f'!(tensor:save-safetensors "{work / "out" / "cetta.safetensors"}" '
                 '(("f64" (tensor:from f64 (2 2) (1.5 -2 0.25 1e300))) ("f32" (tensor:from f32 (3) (0.5 -1 2))) '
                 '("i64" (tensor:from i64 (2) (-9223372036854775808 9223372036854775807))) ("u8" (tensor:from u8 (2 1) (0 255)))) '
                 '(("producer" "cetta") ("note" "é")))')
    # A matrix file written by the documented NumPy writer opens with each
    # column as stored; CeTTa writes it back with its booleans as BOOL.
    readme = (ROOT / "docs/memory/README.md").read_text()
    snippet = next(block for block in readme.split("```python\n")[1:] if "def save_matrix" in block)
    writer = {}
    exec(snippet.split("```")[0], writer)
    matrix_ids = ["a", "bé", "", "d", "e"]
    matrix_meta = {"lang": ["cs", "en", "cs", "", "de"], "rank": [3, -1, 0, 7, 2 ** 40],
                   "score": [0.5, -2.0, 1e-300, 3.0, 0.0], "flag": [True, False, False, True, True]}
    writer["save_matrix"](str(work / "in" / "matrix.safetensors"), rng.standard_normal((5, 3)), matrix_ids, "p",
                          documents=[f"text {i}" for i in range(5)], metadata=matrix_meta)
    opened = f'(tensor:open-all "{work / "in" / "matrix.safetensors"}")'
    lines.append(f'!(let (TensorFile $f $entries $m) {opened} (tensor:save-safetensors "{work / "out" / "matrix.safetensors"}" '
                 '(collapse (let ($name $t) (superpose $entries) (if (== $name "metadata.flag") ($name $t bool) ($name $t))))))')
    pick = '(car-atom (collapse (let ($name $t) (superpose $entries) (if (== $name "{}") $t (empty)))))'
    lines.append(f'!(let (TensorFile $f $entries $m) {opened} (let* (($o {pick.format("ids.offsets")}) '
                 f'($b {pick.format("ids.bytes")}) ($index (tensor:string-index $o $b)) '
                 f'($row (tensor:string-find $index $o $b "d"))) (tensor:save-npy "{work / "out" / "find.npy"}" '
                 '(tensor:from i64 (1) ($row)))))')
    program = work / "program.metta"
    program.write_text("\n".join(lines) + "\n")
    result = subprocess.run([str(args.cetta), "--lang", "petta", str(program)], cwd=ROOT,
                            text=True, capture_output=True, timeout=600)
    if result.returncode or "TensorFailure" in result.stdout:
        sys.stderr.write(result.stdout[-4000:] + result.stderr[-2000:])
        return 1
    checked = 0
    for i, (name, array, fmt) in enumerate(cases):
        expected = np.array(array, order="C").astype(cetta_kind(array.dtype))
        for suffix in ("", ".mapped"):
            path = work / "out" / f"{i}{suffix}.npy"
            if suffix and not path.exists():
                continue
            back = np.load(path)
            if not same_bits(back, expected):
                print(f"FAIL: {name}{suffix}: {back!r} != {expected!r}")
                return 1
            checked += 1
    bf = np.load(work / "out" / "bf16.npy")
    expected_bf = np.frombuffer(b"".join(b"\0\0" + struct.pack("<f", v)[2:] for v in bf_values), dtype="<f4")
    if not same_bits(bf, expected_bf):
        print(f"FAIL: bf16: {bf!r} != {expected_bf!r}")
        return 1
    written = load_file(str(work / "out" / "cetta.safetensors"))
    wanted = {"f64": np.array([[1.5, -2.0], [0.25, 1e300]]), "f32": np.array([0.5, -1, 2], dtype=np.float32),
              "i64": np.array([-2 ** 63, 2 ** 63 - 1], dtype=np.int64), "u8": np.array([[0], [255]], dtype=np.uint8)}
    for key, value in wanted.items():
        if not same_bits(written[key], value):
            print(f"FAIL: CeTTa safetensors {key}: {written[key]!r}")
            return 1
    with safe_open(str(work / "out" / "cetta.safetensors"), framework="numpy") as f:
        if f.metadata() != {"producer": "cetta", "note": "é"}:
            print(f"FAIL: metadata {f.metadata()!r}")
            return 1
    original, back = load_file(str(work / "in" / "matrix.safetensors")), load_file(str(work / "out" / "matrix.safetensors"))
    if set(original) != set(back) or back["metadata.flag"].dtype != np.bool_ or \
            any(not same_bits(back[key], value) for key, value in original.items()):
        print(f"FAIL: a matrix file read back as {back!r}")
        return 1
    if np.load(work / "out" / "find.npy").tolist() != [3]:
        print("FAIL: tensor:string-find in a NumPy string column")
        return 1
    checked += 1
    mapped = np.load(work / "out" / "0.npy", mmap_mode="r")
    if mapped.offset % 64:
        print("FAIL: a CeTTa .npy file's data is not 64-byte aligned")
        return 1
    shutil.rmtree(work)
    print(f"PASS: tensor files interoperate with NumPy and safetensors ({checked + 1} arrays read back, "
          f"{len(cases)} written by the references)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
