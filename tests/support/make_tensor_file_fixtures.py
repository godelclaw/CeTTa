#!/usr/bin/env python3
"""Write the tensor-file fixtures with NumPy and safetensors themselves.

The C tests read these files and compare with values they state on their own,
so the fixtures stand for files the reference libraries produce. Rerun after
changing the fixture set; it needs numpy and safetensors (bf16 bytes are
written by hand, since NumPy has no bf16)."""
import json
import struct
import sys
from pathlib import Path

import numpy as np
from safetensors.numpy import save_file

out = Path(sys.argv[1] if len(sys.argv) > 1 else "tests/fixtures/tensor_files")
out.mkdir(parents=True, exist_ok=True)

np.save(out / "f64_2x3.npy", np.array([[1.5, -2.0, 0.25], [3.0, -0.0, 1e300]], dtype="<f8"))
np.save(out / "f32_vector.npy", np.array([1.0, -0.5, 3.25, 1e-30], dtype="<f4"))
np.save(out / "i64_matrix.npy", np.array([[-9007199254740993, 2], [3, 9223372036854775807]], dtype="<i8"))
np.save(out / "u8_vector.npy", np.array([0, 1, 254, 255], dtype="|u1"))
np.save(out / "bool_vector.npy", np.array([True, False, True], dtype="|b1"))
np.save(out / "f16_vector.npy", np.array([1.0, -2.5, 65504.0, 6e-08, 0.0, np.inf, -np.inf], dtype="<f2"))
np.save(out / "f64_big_endian.npy", np.array([1.5, -3.0, 1e-300], dtype=">f8"))
np.save(out / "i32_fortran.npy", np.asfortranarray(np.arange(6, dtype="<i4").reshape(2, 3) - 2))
np.save(out / "u64_fits.npy", np.array([0, 9223372036854775807], dtype="<u8"))
np.save(out / "u64_beyond.npy", np.array([9223372036854775808], dtype="<u8"))
np.save(out / "f64_scalar.npy", np.array(2.5, dtype="<f8"))
np.save(out / "f64_empty.npy", np.zeros((0, 3), dtype="<f8"))
with open(out / "f32_v2.npy", "wb") as f:
    np.lib.format.write_array(f, np.array([[1.0, 2.0]], dtype="<f4"), version=(2, 0))
with open(out / "f32_v3.npy", "wb") as f:
    np.lib.format.write_array(f, np.array([[1.0, 2.0]], dtype="<f4"), version=(3, 0))

save_file({
    "embeddings": np.array([[0.6, 0.8], [1.0, 0.0], [0.0, -1.0]], dtype="<f4"),
    "ids": np.array([7, -8, 9], dtype="<i8"),
    "flags": np.array([1, 0, 1], dtype="|u1"),
    "half": np.array([0.5, -1.0], dtype="<f2"),
    "wide": np.array([2.0 ** -1074, -1.0], dtype="<f8"),
    "small": np.array([-128, 127], dtype="|i1"),
    "count": np.array([65535], dtype="<u2"),
    "mask": np.array([True, False], dtype="|b1"),
}, str(out / "mixed.safetensors"), metadata={"model": "fixture", "dimensions": "2", "note": "é✓"})


def bf16(value):
    return struct.pack("<f", value)[2:]  # the upper half of an exact f32


data = b"".join(bf16(v) for v in (1.0, -2.0, 0.15625))
header = json.dumps({"bf": {"dtype": "BF16", "shape": [3], "data_offsets": [0, len(data)]}}, separators=(",", ":")).encode()
header += b" " * ((8 - (8 + len(header)) % 8) % 8)
(out / "bf16.safetensors").write_bytes(struct.pack("<Q", len(header)) + header + data)
print("wrote", len(list(out.iterdir())), "fixtures to", out)
