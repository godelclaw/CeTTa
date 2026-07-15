#!/usr/bin/env python3
"""Fresh-train and frozen-score wrapper for the official BioPathNet control.

Imports of the GPU training stack are delayed so protocol checks and ``--help``
remain usable in a minimal environment.
"""

from __future__ import annotations

import argparse
import importlib.metadata
import json
import math
import os
import platform
import random
import subprocess
import sys
from pathlib import Path
from typing import Any, Mapping, Sequence

from biopathnet_suite import (
    TRAINING_ENVIRONMENT,
    SuiteError,
    canonical_json_bytes,
    claim_test_access,
    complete_test_access,
    load_json,
    sha256_file,
    write_json,
)


PINNED_COMMIT = "b051a9003a1363b5655cdb7dfdad60609c0e4fe3"


def _verify_training_environment(torch: Any, torchdrug: Any) -> dict[str, Any]:
    expected = load_json(TRAINING_ENVIRONMENT)
    actual_python = platform.python_version()
    if actual_python != expected["python"]:
        raise SuiteError(f"Python {actual_python} != pinned {expected['python']}")
    installed = {}
    for distribution, expected_version in expected["packages"].items():
        try:
            actual_version = importlib.metadata.version(distribution)
        except importlib.metadata.PackageNotFoundError as error:
            raise SuiteError(f"pinned training package is missing: {distribution}") from error
        if actual_version != expected_version:
            raise SuiteError(
                f"{distribution} {actual_version} != pinned {expected_version}"
            )
        installed[distribution] = actual_version
    if torch.version.cuda != expected["pytorch_cuda"]:
        raise SuiteError(
            f"PyTorch CUDA runtime {torch.version.cuda!r} != pinned {expected['pytorch_cuda']!r}"
        )

    source = Path(torchdrug.__file__).resolve().parent.parent
    torchdrug_pin = expected["source_builds"]["torchdrug"]
    try:
        commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=source, text=True, stderr=subprocess.STDOUT
        ).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SuiteError(f"TorchDrug must resolve to the pinned source checkout: {error}") from error
    if commit != torchdrug_pin["commit"]:
        raise SuiteError(f"TorchDrug source commit {commit} != pinned {torchdrug_pin['commit']}")

    patch = TRAINING_ENVIRONMENT.parent / torchdrug_pin["compatibility_patch"]
    if sha256_file(patch) != torchdrug_pin["compatibility_patch_sha256"]:
        raise SuiteError("TorchDrug compatibility patch hash differs from the environment manifest")
    for relative, digest in torchdrug_pin["patched_file_sha256"].items():
        path = source / relative
        if not path.is_file() or sha256_file(path) != digest:
            raise SuiteError(f"TorchDrug compatibility file differs from its pin: {relative}")
    return {
        "python": actual_python,
        "packages": installed,
        "pytorch_cuda": torch.version.cuda,
        "torchdrug_commit": commit,
        "compatibility_patch_sha256": torchdrug_pin["compatibility_patch_sha256"],
    }


def _verify_source(upstream: Path) -> dict[str, str]:
    expected = load_json(TRAINING_ENVIRONMENT)
    source_pin = expected["source_builds"]["biopathnet"]
    try:
        commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=upstream, text=True, stderr=subprocess.STDOUT
        ).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        raise SuiteError(f"cannot inspect BioPathNet source: {error}") from error
    if commit != PINNED_COMMIT or commit != source_pin["commit"]:
        raise SuiteError(
            f"BioPathNet source commit {commit} != pinned {source_pin['commit']}"
        )
    patch = TRAINING_ENVIRONMENT.parent / source_pin["compatibility_patch"]
    if sha256_file(patch) != source_pin["compatibility_patch_sha256"]:
        raise SuiteError("BioPathNet compatibility patch hash differs from the environment manifest")
    for relative, digest in source_pin["patched_file_sha256"].items():
        path = upstream / relative
        if not path.is_file() or sha256_file(path) != digest:
            raise SuiteError(f"BioPathNet compatibility file differs from its pin: {relative}")
    return {
        "biopathnet_commit": commit,
        "biopathnet_compatibility_patch_sha256": source_pin["compatibility_patch_sha256"],
    }


def _imports(upstream: Path) -> Mapping[str, Any]:
    source_environment = _verify_source(upstream)
    sys.path.insert(0, str(upstream))
    try:
        import numpy as np
        import torch
        import torchdrug
        from torchdrug import core, data, utils
        from torchdrug.utils import comm
        from biopathnet import dataset, layer, model, task, util  # noqa: F401
    except ImportError as error:
        raise SuiteError(f"BioPathNet training environment is incomplete: {error}") from error
    environment = _verify_training_environment(torch, torchdrug)
    return {
        "np": np,
        "torch": torch,
        "torchdrug": torchdrug,
        "core": core,
        "data": data,
        "utils": utils,
        "comm": comm,
        "util": util,
        "environment": environment,
        "source_environment": source_environment,
    }


def verify_environment(upstream: Path) -> dict[str, Any]:
    modules = _imports(upstream)
    return {
        "status": "ok",
        **modules["source_environment"],
        **modules["environment"],
    }


def _load_cfg(modules: Mapping[str, Any], config: Path, data_path: Path, output_dir: Path, gpus: str) -> Any:
    context = {
        "data_path": json.dumps(str(data_path)),
        "output_dir": json.dumps(str(output_dir)),
        "gpus": modules["utils"].literal_eval(gpus),
    }
    return modules["util"].load_config(config, context=context)


def _as_float(value: Any) -> float:
    if hasattr(value, "item"):
        value = value.item()
    result = float(value)
    if not math.isfinite(result):
        raise SuiteError(f"non-finite metric from BioPathNet: {result}")
    return result


def _load_checkpoint(modules: Mapping[str, Any], solver: Any, checkpoint: Path, *, optimizer: bool) -> None:
    torch = modules["torch"]
    state = torch.load(checkpoint, map_location=solver.device)
    for name in (
        "fact_graph",
        "fact_graph_supervision",
        "graph",
        "train_graph",
        "valid_graph",
        "test_graph",
        "full_valid_graph",
        "full_test_graph",
    ):
        state["model"].pop(name, None)
    solver.model.load_state_dict(state["model"], strict=False)
    if optimizer:
        solver.optimizer.load_state_dict(state["optimizer"])
        for optimizer_state in solver.optimizer.state.values():
            for key, value in optimizer_state.items():
                if isinstance(value, torch.Tensor):
                    optimizer_state[key] = value.to(solver.device)
    modules["comm"].synchronize()


def train_select(
    upstream: Path,
    config: Path,
    selection_data: Path,
    output_dir: Path,
    *,
    seed: int,
    gpus: str,
) -> dict[str, Any]:
    upstream = upstream.resolve()
    config = config.resolve()
    selection_data = selection_data.resolve()
    output_dir = output_dir.resolve()
    receipt_path = selection_data / "selection_view_receipt.json"
    receipt = load_json(receipt_path)
    if receipt.get("real_test_bytes_present") is not False or receipt.get("surrogate_test_is_validation") is not True:
        raise SuiteError("control training requires the audited selection-only data view")
    modules = _imports(upstream)
    torch = modules["torch"]
    np = modules["np"]
    comm = modules["comm"]
    core = modules["core"]
    util = modules["util"]

    output_dir.mkdir(parents=True, exist_ok=False)
    old_directory = Path.cwd()
    try:
        os.chdir(output_dir)
        random.seed(seed)
        np.random.seed(seed)
        torch.manual_seed(seed + int(comm.get_rank()))
        cfg = _load_cfg(modules, config, selection_data, output_dir, gpus)
        dataset = core.Configurable.load_config_dict(cfg.dataset)
        solver = util.build_solver(cfg, dataset)
        step = math.ceil(cfg.train.num_epoch / 10)
        best_result = float("-inf")
        best_epoch = -1
        for index in range(0, cfg.train.num_epoch, step):
            kwargs = cfg.train.copy()
            kwargs["num_epoch"] = min(step, cfg.train.num_epoch - index)
            solver.model.split = "train"
            solver.train(**kwargs)
            checkpoint = Path(f"model_epoch_{solver.epoch}.pth")
            solver.save(str(checkpoint))
            solver.model.split = "valid"
            metric = solver.evaluate("valid")
            result = _as_float(metric[cfg.metric])
            if result > best_result:
                best_result = result
                best_epoch = solver.epoch
        if best_epoch < 0:
            raise SuiteError("BioPathNet control produced no validation checkpoint")
        checkpoint = Path(f"model_epoch_{best_epoch}.pth")
        _load_checkpoint(modules, solver, checkpoint, optimizer=False)
        selection = {
            "schema_version": 1,
            "model": "biopathnet-control",
            "seed": seed,
            "upstream_commit": PINNED_COMMIT,
            "config_sha256": sha256_file(config),
            "selection_view_receipt_sha256": sha256_file(receipt_path),
            "checkpoint": checkpoint.name,
            "checkpoint_sha256": sha256_file(checkpoint),
            "validation_mrr": best_result,
            "best_epoch": best_epoch,
        }
        write_json(Path("selection.json"), selection, exclusive=True)
        return selection
    finally:
        os.chdir(old_directory)


def train_smoke(
    upstream: Path,
    config: Path,
    selection_data: Path,
    output_dir: Path,
    *,
    seed: int,
    gpus: str,
) -> dict[str, Any]:
    """Run one optimizer step and one held-out sampled-negative validation batch."""
    upstream = upstream.resolve()
    config = config.resolve()
    selection_data = selection_data.resolve()
    output_dir = output_dir.resolve()
    receipt_path = selection_data / "selection_view_receipt.json"
    receipt = load_json(receipt_path)
    if receipt.get("real_test_bytes_present") is not False or receipt.get("surrogate_test_is_validation") is not True:
        raise SuiteError("control smoke requires the audited selection-only data view")
    modules = _imports(upstream)
    torch = modules["torch"]
    np = modules["np"]
    comm = modules["comm"]
    core = modules["core"]
    data = modules["data"]
    utils = modules["utils"]
    util = modules["util"]

    output_dir.mkdir(parents=True, exist_ok=False)
    old_directory = Path.cwd()
    try:
        os.chdir(output_dir)
        random.seed(seed)
        np.random.seed(seed)
        torch.manual_seed(seed + int(comm.get_rank()))
        cfg = _load_cfg(modules, config, selection_data, output_dir, gpus)
        if cfg.train.num_epoch != 1 or cfg.train.batch_per_epoch != 1:
            raise SuiteError("control smoke config must request exactly one epoch and one batch")
        dataset = core.Configurable.load_config_dict(cfg.dataset)
        solver = util.build_solver(cfg, dataset)
        solver.model.split = "train"
        solver.train(**cfg.train)
        optimizer_steps = []
        for state in solver.optimizer.state.values():
            step = state.get("step")
            if step is not None:
                optimizer_steps.append(int(step.item() if hasattr(step, "item") else step))
        if not optimizer_steps or max(optimizer_steps) != 1:
            raise SuiteError(f"control smoke expected optimizer step 1, observed {optimizer_steps!r}")

        checkpoint = Path(f"model_epoch_{solver.epoch}.pth")
        solver.save(str(checkpoint))
        validation_loader = data.DataLoader(
            solver.valid_set,
            min(solver.batch_size, 2),
            sampler=None,
            num_workers=0,
        )
        validation_batch = next(iter(validation_loader))
        if solver.device.type == "cuda":
            validation_batch = utils.cuda(validation_batch, device=solver.device)
        solver.model.split = "valid"
        solver.model.eval()
        with torch.no_grad():
            validation_loss, validation_metric = solver.model(validation_batch)
        validation_loss = _as_float(validation_loss)
        metrics = {name: _as_float(value) for name, value in validation_metric.items()}
        result = {
            "schema_version": 1,
            "status": "ok",
            "kind": "optimizer-and-sampled-validation-smoke",
            "seed": seed,
            "upstream_commit": PINNED_COMMIT,
            "config_sha256": sha256_file(config),
            "selection_view_receipt_sha256": sha256_file(receipt_path),
            "optimizer_step": max(optimizer_steps),
            "checkpoint": checkpoint.name,
            "checkpoint_sha256": sha256_file(checkpoint),
            "validation_batch_size": len(validation_batch),
            "validation_loss": validation_loss,
            "validation_metrics": metrics,
            "validation_scope": "one held-out batch with task-sampled negatives; not ranking MRR",
        }
        write_json(Path("smoke.json"), result, exclusive=True)
        return result
    finally:
        os.chdir(old_directory)


def _build_frozen_solver(
    modules: Mapping[str, Any],
    config: Path,
    data_path: Path,
    output_dir: Path,
    checkpoint: Path,
    gpus: str,
) -> Any:
    cfg = _load_cfg(modules, config, data_path, output_dir, gpus)
    dataset = modules["core"].Configurable.load_config_dict(cfg.dataset)
    solver = modules["util"].build_solver(cfg, dataset)
    _load_checkpoint(modules, solver, checkpoint, optimizer=False)
    return cfg, dataset, solver


def score_control(
    upstream: Path,
    config: Path,
    data_path: Path,
    checkpoint: Path,
    output: Path,
    *,
    split: str,
    gpus: str,
    test_lock: Path | None,
    job_id: str | None,
) -> dict[str, Any]:
    if split not in {"valid", "test"}:
        raise SuiteError("control scoring split must be valid or test")
    if split == "valid":
        receipt_path = data_path / "selection_view_receipt.json"
        if not receipt_path.is_file():
            raise SuiteError("validation scoring requires the selection-only data view")
        receipt = load_json(receipt_path)
        if receipt.get("real_test_bytes_present") is not False:
            raise SuiteError("validation scoring data view is not test-free")
    if split == "test":
        if test_lock is None or not job_id:
            raise SuiteError("test scoring requires --test-lock and --job-id")
        claim_test_access(test_lock, job_id, "fresh BioPathNet control scoring")
    modules = _imports(upstream)
    torch = modules["torch"]
    data = modules["data"]
    utils = modules["utils"]
    cfg, dataset, solver = _build_frozen_solver(
        modules, config, data_path, output.parent, checkpoint, gpus
    )
    selected_set = solver.valid_set if split == "valid" else solver.test_set
    loader = data.DataLoader(selected_set, solver.batch_size, sampler=None, num_workers=solver.num_worker)
    solver.model.split = split
    solver.model.eval()
    rows = []
    with torch.no_grad():
        query_offset = 0
        for batch in loader:
            if solver.device.type == "cuda":
                batch = utils.cuda(batch, device=solver.device)
            prediction, (mask, target) = solver.model.predict_and_target(batch)
            prediction = prediction.detach().cpu()
            mask = mask.detach().cpu()
            target = target.detach().cpu()
            for batch_index in range(len(batch)):
                positive_index = int(target[batch_index, 0])
                candidate_indices = torch.nonzero(mask[batch_index, 0], as_tuple=False).flatten().tolist()
                if positive_index not in candidate_indices:
                    candidate_indices.append(positive_index)
                query_id = f"{split}:{query_offset + batch_index + 1}"
                for candidate_index in sorted(candidate_indices):
                    raw_score = float(prediction[batch_index, 0, candidate_index])
                    rows.append(
                        {
                            "query_id": query_id,
                            "candidate_id": dataset.entity_vocab[candidate_index],
                            "is_observed_positive": candidate_index == positive_index,
                            "biopathnet_score": float(torch.sigmoid(torch.tensor(raw_score))),
                            "biopathnet_logit": raw_score,
                        }
                    )
            query_offset += len(batch)
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        raise SuiteError(f"refusing to replace existing control scores: {output}")
    temporary = output.with_name(output.name + ".new")
    with temporary.open("wb") as handle:
        for row in rows:
            handle.write(canonical_json_bytes(row))
        handle.flush()
    temporary.replace(output)
    result = {
        "status": "ok",
        "model": "biopathnet-control",
        "split": split,
        "queries": len(selected_set),
        "candidate_rows": len(rows),
        "scores_sha256": sha256_file(output),
        "evaluation_direction": "tail-target",
    }
    if split == "test":
        complete_test_access(test_lock, job_id, output)
    return result


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    verify = subparsers.add_parser("verify-environment")
    verify.add_argument("upstream", type=Path)

    train = subparsers.add_parser("train-select")
    train.add_argument("upstream", type=Path)
    train.add_argument("config", type=Path)
    train.add_argument("selection_data", type=Path)
    train.add_argument("output_dir", type=Path)
    train.add_argument("--seed", type=int, required=True)
    train.add_argument("--gpus", default="[0]")

    smoke = subparsers.add_parser("train-smoke")
    smoke.add_argument("upstream", type=Path)
    smoke.add_argument("config", type=Path)
    smoke.add_argument("selection_data", type=Path)
    smoke.add_argument("output_dir", type=Path)
    smoke.add_argument("--seed", type=int, required=True)
    smoke.add_argument("--gpus", default="[0]")

    score = subparsers.add_parser("score-control")
    score.add_argument("upstream", type=Path)
    score.add_argument("config", type=Path)
    score.add_argument("data_path", type=Path)
    score.add_argument("checkpoint", type=Path)
    score.add_argument("output", type=Path)
    score.add_argument("--split", choices=("valid", "test"), required=True)
    score.add_argument("--gpus", default="[0]")
    score.add_argument("--test-lock", type=Path)
    score.add_argument("--job-id")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "verify-environment":
        result = verify_environment(args.upstream)
    elif args.command == "train-select":
        result = train_select(
            args.upstream,
            args.config,
            args.selection_data,
            args.output_dir,
            seed=args.seed,
            gpus=args.gpus,
        )
    elif args.command == "train-smoke":
        result = train_smoke(
            args.upstream,
            args.config,
            args.selection_data,
            args.output_dir,
            seed=args.seed,
            gpus=args.gpus,
        )
    else:
        result = score_control(
            args.upstream,
            args.config,
            args.data_path,
            args.checkpoint,
            args.output,
            split=args.split,
            gpus=args.gpus,
            test_lock=args.test_lock,
            job_id=args.job_id,
        )
    sys.stdout.buffer.write(canonical_json_bytes(result))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SuiteError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
