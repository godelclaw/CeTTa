#!/usr/bin/env python3

import json
import hashlib
import math
import os
import sys
import tempfile
import unittest
from pathlib import Path


SUITE_DIR = Path(__file__).resolve().parent
REPO_ROOT = SUITE_DIR.parents[1]
CETTA_TEST_BINARY = Path(
    os.environ.get("CETTA_WRAPPED_BIN")
    or os.environ.get("CETTA_BIN")
    or REPO_ROOT / "cetta"
).resolve()
sys.path.insert(0, str(SUITE_DIR))

from cafa5_suite import (  # noqa: E402
    CalibrationArtifact,
    CeTTaGroupFoldReducer,
    FusionSpec,
    SourceSpec,
    build_canonical_evaluator_summary,
    build_parser,
    canonical_tsv_semantic_digest,
    compare_prediction_files,
    fuse_prediction_files,
    iter_prediction_rows,
    load_fusion_spec,
    run_cetta_smoke,
    safe_metta_symbol,
    validate_source_specs,
    write_cetta_packets,
)


class Cafa5SuiteTests(unittest.TestCase):
    def fresh_directory(self):
        runtime = REPO_ROOT / "runtime"
        runtime.mkdir(exist_ok=True)
        return tempfile.TemporaryDirectory(prefix="cafa5-suite-test-", dir=runtime)

    @staticmethod
    def write_predictions(path: Path, rows):
        path.write_text(
            "".join(f"{protein}\t{term}\t{score}\n" for protein, term, score in rows),
            encoding="utf-8",
        )

    def test_conservative_max_is_primary_across_dependence_groups(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            a = root / "a.tsv"
            b = root / "b.tsv"
            c = root / "c.tsv"
            self.write_predictions(a, [("P", "GO:0001", 0.8)])
            self.write_predictions(b, [("P", "GO:0001", 0.7)])
            self.write_predictions(c, [("P", "GO:0001", 0.5)])
            output = root / "fused.tsv"
            trail = root / "trail.jsonl"
            result = fuse_prediction_files(
                [
                    SourceSpec("a", "sequence", a),
                    SourceSpec("b", "sequence", b),
                    SourceSpec("c", "structure", c),
                ],
                output,
                trail,
                root / "fusion.sqlite3",
            )
            self.assertEqual(result["packet_rows"], 3)
            self.assertEqual(result["candidate_rows"], 1)
            rows = list(iter_prediction_rows(output))
            self.assertEqual(rows[0][:2], ("P", "GO:0001"))
            self.assertAlmostEqual(rows[0][2], 0.8)
            evidence = json.loads(trail.read_text(encoding="utf-8"))
            self.assertEqual([group["max_score"] for group in evidence["groups"]], [0.8, 0.5])
            self.assertEqual(evidence["policy"], "conservative-max")
            self.assertEqual(evidence["between_groups"], "maximum")

    def test_calibrated_noisy_or_requires_and_records_declarations(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            a = root / "a.tsv"
            b = root / "b.tsv"
            self.write_predictions(a, [("P", "GO:0001", 0.8)])
            self.write_predictions(b, [("P", "GO:0001", 0.5)])
            sources = [
                SourceSpec("a", "sequence", a),
                SourceSpec("b", "structure", b),
            ]
            cal_a = root / "cal-a.json"
            cal_b = root / "cal-b.json"
            cal_a.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "calibration_id": "cal-v1",
                        "method": "logistic",
                        "slope": 4.0,
                        "intercept": -2.0,
                    },
                    sort_keys=True,
                )
                + "\n",
                encoding="utf-8",
            )
            cal_b.write_text(cal_a.read_text(encoding="utf-8"), encoding="utf-8")
            policy = FusionSpec(
                policy="calibrated-noisy-or",
                calibrations={
                    "a": CalibrationArtifact(
                        "cal-v1",
                        hashlib.sha256(cal_a.read_bytes()).hexdigest(),
                        cal_a,
                        4.0,
                        -2.0,
                    ),
                    "b": CalibrationArtifact(
                        "cal-v1",
                        hashlib.sha256(cal_b.read_bytes()).hexdigest(),
                        cal_b,
                        4.0,
                        -2.0,
                    ),
                },
                independent_group_pairs=frozenset({("sequence", "structure")}),
            )
            output = root / "fused.tsv"
            trail = root / "trail.jsonl"
            result = fuse_prediction_files(
                sources, output, trail, root / "fusion.sqlite3", policy
            )
            self.assertEqual(result["fusion_policy"], "calibrated-noisy-or")
            probability_a = 1.0 / (1.0 + math.exp(-1.2))
            probability_b = 0.5
            expected = 1.0 - (1.0 - probability_a) * (1.0 - probability_b)
            self.assertAlmostEqual(list(iter_prediction_rows(output))[0][2], expected)
            self.assertNotAlmostEqual(expected, 0.9)
            evidence = json.loads(trail.read_text(encoding="utf-8"))
            self.assertEqual(
                evidence["between_groups"],
                "noisy-or-over-declared-independent-groups",
            )
            self.assertEqual(
                evidence["calibrations"]["a"]["artifact_sha256"],
                hashlib.sha256(cal_a.read_bytes()).hexdigest(),
            )
            cetta_output = root / "cetta-fused.tsv"
            cetta_result = fuse_prediction_files(
                sources,
                cetta_output,
                root / "cetta-trail.jsonl",
                root / "cetta.workspace",
                policy,
                CeTTaGroupFoldReducer(CETTA_TEST_BINARY, run_size=2),
            )
            self.assertEqual(cetta_result["backend_role"], "load-bearing-reducer")
            self.assertEqual(output.read_bytes(), cetta_output.read_bytes())

    def test_noisy_or_rejects_missing_calibration_or_independence(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            a = root / "a.tsv"
            b = root / "b.tsv"
            self.write_predictions(a, [("P", "GO:0001", 0.8)])
            self.write_predictions(b, [("P", "GO:0001", 0.5)])
            sources = [
                SourceSpec("a", "sequence", a),
                SourceSpec("b", "structure", b),
            ]
            invalid = FusionSpec(
                policy="calibrated-noisy-or",
                calibrations={
                    "a": CalibrationArtifact(
                        "cal-a", "a" * 64, root / "missing", 1.0, 0.0
                    )
                },
            )
            with self.assertRaises(ValueError):
                fuse_prediction_files(
                    sources,
                    root / "fused.tsv",
                    root / "trail.jsonl",
                    root / "fusion.sqlite3",
                    invalid,
                )

    def test_fusion_declaration_resolves_and_executes_relative_calibration(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            artifact = root / "calibration.json"
            artifact.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "calibration_id": "regime-v1",
                        "method": "logistic",
                        "slope": 2.0,
                        "intercept": -1.0,
                    },
                    sort_keys=True,
                )
                + "\n",
                encoding="utf-8",
            )
            declaration = root / "fusion.json"
            declaration.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "policy": "calibrated-noisy-or",
                        "calibrations": {
                            "source": {
                                "calibration_id": "regime-v1",
                                "artifact": artifact.name,
                                "artifact_sha256": hashlib.sha256(
                                    artifact.read_bytes()
                                ).hexdigest(),
                            }
                        },
                        "independent_group_pairs": [],
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            spec = load_fusion_spec("calibrated-noisy-or", declaration)
            self.assertEqual(spec.calibrations["source"].path, artifact.resolve())
            self.assertAlmostEqual(spec.calibrations["source"].apply(0.5), 0.5)

            artifact.write_text('{"calibration":"placeholder"}\n', encoding="utf-8")
            declaration_document = json.loads(declaration.read_text(encoding="utf-8"))
            declaration_document["calibrations"]["source"]["artifact_sha256"] = (
                hashlib.sha256(artifact.read_bytes()).hexdigest()
            )
            declaration.write_text(
                json.dumps(declaration_document) + "\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(ValueError, "schema_version"):
                load_fusion_spec("calibrated-noisy-or", declaration)

    def test_single_source_fusion_is_identity(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            source = root / "source.tsv"
            self.write_predictions(
                source,
                [("P1", "GO:0001", 0.25), ("P2", "GO:0002", 0.75)],
            )
            output = root / "fused.tsv"
            fuse_prediction_files(
                [SourceSpec("source", "group", source)],
                output,
                root / "trail.jsonl",
                root / "fusion.sqlite3",
            )
            result = compare_prediction_files(source, output)
            self.assertEqual(result["rows"], 2)
            self.assertLessEqual(result["maximum_absolute_error"], 1e-12)

    def test_cetta_packet_audit_streams_atom_lines_and_proves_one_route(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            source = root / "source.tsv"
            self.write_predictions(
                source,
                [("P1", "GO:0000001", 0.25), ("P2", "GO:0000002", 0.75)],
            )
            packets = root / "packets.metta"
            count, first = write_cetta_packets(
                [SourceSpec("source", "group", source)], packets
            )
            result = run_cetta_smoke(
                CETTA_TEST_BINARY,
                root,
                packets,
                first,
                count,
                None,
            )
            self.assertEqual(result["packet_audit_count"], 2)
            self.assertEqual(result["concrete_proof_count"], 1)
            self.assertRegex(result["packet_audit_sha256"], r"^[0-9a-f]{64}$")

    def test_cetta_group_fold_matches_sqlite_oracle(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            a = root / "a.tsv"
            b = root / "b.tsv"
            self.write_predictions(
                a,
                [("P2", "GO:0002", 0.4), ("P1", "GO:0001", 0.8)],
            )
            self.write_predictions(
                b,
                [("P1", "GO:0001", 0.5), ("P2", "GO:0002", 0.9)],
            )
            sources = [
                SourceSpec("source-a", "sequence", a),
                SourceSpec("source-b", "structure", b),
            ]
            oracle_output = root / "oracle.tsv"
            oracle = fuse_prediction_files(
                sources,
                oracle_output,
                root / "oracle.jsonl",
                root / "oracle.sqlite3",
            )
            cetta_output = root / "cetta.tsv"
            cetta = fuse_prediction_files(
                sources,
                cetta_output,
                root / "cetta.jsonl",
                root / "cetta.workspace",
                reducer_backend=CeTTaGroupFoldReducer(
                    CETTA_TEST_BINARY, run_size=2
                ),
            )
            self.assertEqual(cetta["backend_role"], "load-bearing-reducer")
            self.assertEqual(cetta["differential_oracle"]["status"], "passed")
            self.assertEqual(
                cetta["differential_oracle"]["comparison"]["maximum_absolute_error"],
                0.0,
            )
            self.assertEqual(oracle["candidate_rows"], cetta["candidate_rows"])
            self.assertEqual(oracle_output.read_bytes(), cetta_output.read_bytes())

    def test_cetta_certificate_count_is_checked_against_packet_frontier(self):
        class WrongCountReducer(CeTTaGroupFoldReducer):
            @staticmethod
            def _parse_group_results(output: str, key_arity: int):
                results = CeTTaGroupFoldReducer._parse_group_results(output, key_arity)
                if key_arity == 3 and results:
                    first = next(iter(results.values()))
                    first["audit_count"] += 1
                return results

        with self.fresh_directory() as directory:
            root = Path(directory)
            source = root / "source.tsv"
            self.write_predictions(source, [("P", "GO:0001", 0.5)])
            with self.assertRaisesRegex(ValueError, "certificate count"):
                fuse_prediction_files(
                    [SourceSpec("source", "group", source)],
                    root / "fused.tsv",
                    root / "trail.jsonl",
                    root / "workspace",
                    reducer_backend=WrongCountReducer(CETTA_TEST_BINARY),
                )

    def test_cetta_file_cursor_shards_above_per_shard_bound_deterministically(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            proteins = {}
            candidate = 0
            while len(proteins) < 8:
                protein = f"P{candidate:04d}"
                shard = CeTTaGroupFoldReducer._protein_shard(protein, 8)
                proteins.setdefault(shard, protein)
                candidate += 1
            source = root / "source.tsv"
            self.write_predictions(
                source,
                [
                    (protein, f"GO:{index + 1:07d}", 0.1 + index / 100)
                    for index, protein in enumerate(proteins.values())
                ],
            )
            sources = [SourceSpec("source", "group", source)]
            oracle_output = root / "oracle.tsv"
            fuse_prediction_files(
                sources,
                oracle_output,
                root / "oracle.jsonl",
                root / "oracle.sqlite3",
            )

            summaries = []
            for run in (1, 2):
                output = root / f"cetta-{run}.tsv"
                summary = fuse_prediction_files(
                    sources,
                    output,
                    root / f"cetta-{run}.jsonl",
                    root / f"cetta-{run}.workspace",
                    reducer_backend=CeTTaGroupFoldReducer(
                        CETTA_TEST_BINARY,
                        run_size=2,
                        shard_count=8,
                        max_shard_packets=1,
                    ),
                )
                self.assertEqual(output.read_bytes(), oracle_output.read_bytes())
                self.assertEqual(summary["input_rows"], 8)
                self.assertEqual(summary["active_shards"], 8)
                self.assertEqual(summary["candidate_rows"], 8)
                summaries.append(summary)
            self.assertEqual(
                summaries[0]["shard_manifest_sha256"],
                summaries[1]["shard_manifest_sha256"],
            )

    def test_invalid_score_is_rejected(self):
        with self.fresh_directory() as directory:
            path = Path(directory) / "bad.tsv"
            self.write_predictions(path, [("P", "GO:0001", 1.1)])
            with self.assertRaises(ValueError):
                list(iter_prediction_rows(path))

    def test_metta_symbol_encoding(self):
        self.assertEqual(safe_metta_symbol("GO:0005215"), "go-0005215")
        self.assertEqual(safe_metta_symbol("A0A0B7P9G0"), "A0A0B7P9G0")
        with self.assertRaises(ValueError):
            safe_metta_symbol("unsafe symbol")

    def test_duplicate_source_labels_are_rejected(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                validate_source_specs(
                    [
                        SourceSpec("duplicate", "group-a", root / "a.tsv"),
                        SourceSpec("duplicate", "group-b", root / "b.tsv"),
                    ]
                )

    def test_identical_duplicate_rows_are_idempotent(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            source = root / "source.tsv"
            self.write_predictions(
                source,
                [("P", "GO:0001", 0.25), ("P", "GO:0001", 0.25)],
            )
            output = root / "fused.tsv"
            result = fuse_prediction_files(
                [SourceSpec("source", "group", source)],
                output,
                root / "trail.jsonl",
                root / "fusion.sqlite3",
            )
            self.assertEqual(result["input_rows"], 2)
            self.assertEqual(result["packet_rows"], 1)
            self.assertEqual(result["exact_duplicate_rows_collapsed"], 1)
            self.assertEqual(list(iter_prediction_rows(output)), [("P", "GO:0001", 0.25)])

    def test_conflicting_duplicate_rows_are_rejected(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            source = root / "source.tsv"
            self.write_predictions(
                source,
                [("P", "GO:0001", 0.25), ("P", "GO:0001", 0.5)],
            )
            with self.assertRaisesRegex(ValueError, "conflicting duplicate"):
                fuse_prediction_files(
                    [SourceSpec("source", "group", source)],
                    root / "fused.tsv",
                    root / "trail.jsonl",
                    root / "fusion.sqlite3",
                )

    def test_canonical_tsv_hash_ignores_row_and_column_order(self):
        with self.fresh_directory() as directory:
            root = Path(directory)
            left = root / "left.tsv"
            right = root / "right.tsv"
            left.write_text("a\tb\n1\t2\n3\t4\n", encoding="utf-8")
            right.write_text("b\ta\n4\t3\n2\t1\n", encoding="utf-8")
            self.assertEqual(
                canonical_tsv_semantic_digest(left),
                canonical_tsv_semantic_digest(right),
            )

    def test_weighted_semantic_distance_is_selected_from_s_w(self):
        with self.fresh_directory() as directory:
            results = Path(directory)
            header = "filename\tns\ttau\tf\tf_w\ts\ts_w\tcov\tcov_w\n"
            rows = (
                "m.tsv\tbiological_process\t0.1\t0.4\t0.3\t1.0\t9.0\t1.0\t1.0\n"
                "m.tsv\tbiological_process\t0.2\t0.5\t0.6\t8.0\t2.0\t0.9\t0.8\n"
            )
            (results / "evaluation_all.tsv").write_text(
                header + rows, encoding="utf-8"
            )
            summary = build_canonical_evaluator_summary(results, "unit-test")
            weighted = summary["metrics"]["weighted_semantic_distance_min"][0]
            unweighted = summary["metrics"]["unweighted_semantic_distance_min"][0]
            self.assertEqual(weighted["threshold"], 0.2)
            self.assertEqual(weighted["value"], 2.0)
            self.assertEqual(unweighted["threshold"], 0.1)

    def test_run_full_is_a_distinct_command(self):
        parser = build_parser()
        args = parser.parse_args(
            [
                "run-full",
                "--source",
                "source:group:predictions.tsv",
                "--data-root",
                "data",
                "--evaluator-root",
                "evaluator-repository",
                "--evaluator",
                "cafaeval",
                "--cetta",
                "cetta",
                "--output",
                "run",
            ]
        )
        self.assertEqual(args.command, "run-full")
        self.assertEqual(args.fusion_policy, "conservative-max")


if __name__ == "__main__":
    unittest.main()
