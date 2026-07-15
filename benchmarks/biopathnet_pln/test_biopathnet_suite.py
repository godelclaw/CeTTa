#!/usr/bin/env python3

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from biopathnet_suite import (
    EXPERIMENT_CONFIG,
    HERE,
    SuiteError,
    Triple,
    arm_test_plan,
    claim_test_access,
    complete_test_access,
    generate_run_plan,
    paired_bootstrap,
    parse_triples,
    rank_candidate_rows,
    ranking_metrics,
    sha256_file,
    validate_certificate,
    write_json,
)
from pln_path_model import (
    NonnegativeLogisticStacker,
    PLNPathModel,
    PathGraph,
    join_control_pln_features,
    score_hybrid,
    synthetic_smoke,
    train_hybrid,
)


def write_jsonl(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            json.dump(row, handle, sort_keys=True, separators=(",", ":"))
            handle.write("\n")


class ManifestTests(unittest.TestCase):
    def test_five_seeds_and_three_fresh_models(self) -> None:
        config = json.loads(EXPERIMENT_CONFIG.read_text(encoding="utf-8"))
        self.assertEqual(len(config["seeds"]), 5)
        self.assertEqual(len(set(config["seeds"])), 5)
        self.assertEqual(
            config["models"],
            ["biopathnet-control", "pln-path-evidence", "biopathnet-pln-hybrid"],
        )
        self.assertFalse(config["sampled_negatives"]["biological_falsehood_claimed"])

    def test_generation_is_deterministic_and_has_fifteen_jobs(self) -> None:
        with tempfile.TemporaryDirectory() as first_name, tempfile.TemporaryDirectory() as second_name:
            first = Path(first_name)
            second = Path(second_name)
            first_plan = generate_run_plan(first)
            second_plan = generate_run_plan(second)
            self.assertEqual(first_plan, second_plan)
            self.assertEqual(len(first_plan["jobs"]), 15)
            self.assertIn("pln_path_model.py", first_plan["suite_source_sha256"])
            self.assertIn("biopathnet_symmetric_candidates.patch", first_plan["suite_source_sha256"])
            for relative in (
                "run_plan.json",
                "configs/biopathnet-control.yaml",
                "configs/pln-path-evidence.json",
                "configs/biopathnet-pln-hybrid.json",
                "plan_manifest.json",
            ):
                self.assertEqual(sha256_file(first / relative), sha256_file(second / relative))
            yaml = (first / "configs/biopathnet-control.yaml").read_text(encoding="utf-8")
            self.assertIn("{{ data_path }}", yaml)
            self.assertIn("{{ output_dir }}", yaml)

    def test_public_artifacts_have_no_machine_path_or_council_language(self) -> None:
        forbidden = ("/home/", "/shared/", "imagined council", "quorum")
        for path in HERE.iterdir():
            if path.suffix not in {".py", ".json", ".txt"} or path.name.startswith("test_"):
                continue
            text = path.read_text(encoding="utf-8").lower()
            for needle in forbidden:
                self.assertNotIn(needle, text, f"{needle!r} leaked through {path.name}")


class BoundaryTests(unittest.TestCase):
    def test_malformed_triple_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bad.txt"
            path.write_text("head\trelation\n", encoding="utf-8")
            with self.assertRaises(SuiteError):
                list(parse_triples(path))

    def test_test_lock_is_irreversible_per_job(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            plan = generate_run_plan(directory / "plan")
            selections = {
                "selections": [
                    {
                        "job_id": job["job_id"],
                        "checkpoint_sha256": "a" * 64,
                        "validation_mrr": 0.25,
                    }
                    for job in plan["jobs"]
                ]
            }
            selections_path = directory / "selections.json"
            write_json(selections_path, selections)
            lock_path = directory / "test-lock.json"
            arm_test_plan(directory / "plan" / "run_plan.json", selections_path, lock_path)
            job_id = plan["jobs"][0]["job_id"]
            claim_test_access(lock_path, job_id, "unit-test scoring")
            artifact = directory / "scores.jsonl"
            artifact.write_text("{}\n", encoding="utf-8")
            complete_test_access(lock_path, job_id, artifact)
            with self.assertRaises(SuiteError):
                claim_test_access(lock_path, job_id, "second scoring")

    def test_selection_manifest_cannot_name_test_fields(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            plan = generate_run_plan(directory / "plan")
            records = [
                {
                    "job_id": job["job_id"],
                    "checkpoint_sha256": "a" * 64,
                    "validation_mrr": 0.2,
                }
                for job in plan["jobs"]
            ]
            records[0]["test_mrr"] = 1.0
            selections = directory / "selections.json"
            write_json(selections, {"selections": records})
            with self.assertRaises(SuiteError):
                arm_test_plan(directory / "plan" / "run_plan.json", selections, directory / "lock.json")


class PLNTests(unittest.TestCase):
    def _graph(self) -> tuple[PathGraph, list[Triple], dict[str, str]]:
        graph = PathGraph()
        train1 = [
            Triple("P1", "interacts-with", "G1"),
            Triple("P2", "interacts-with", "G2"),
            Triple("P3", "interacts-with", "G3"),
        ]
        train2 = [
            Triple("L1", "interact with protein", "P1"),
            Triple("L1", "expression association", "G1"),
            Triple("L2", "interact with protein", "P2"),
            Triple("L2", "expression association", "G2"),
            Triple("L3", "interact with protein", "P3"),
        ]
        for index, triple in enumerate(train1, 1):
            graph.add(triple, split="train1", line_number=index)
        for index, triple in enumerate(train2, 1):
            graph.add(triple, split="train2", line_number=index)
        graph.finalize()
        types = {
            "P1": "protein",
            "P2": "protein",
            "P3": "protein",
            "G1": "gene",
            "G2": "gene",
            "G3": "gene",
            "GX": "gene",
            "L1": "lncRNA",
            "L2": "lncRNA",
            "L3": "lncRNA",
        }
        return graph, train2, types

    def test_synthetic_smoke(self) -> None:
        result = synthetic_smoke()
        self.assertEqual(result["status"], "ok")
        self.assertGreater(result["pln_positive_score"], result["pln_negative_control_score"])
        self.assertTrue(all(weight >= 0 for weight in result["hybrid_weights"]))

    def test_query_edge_and_inverse_are_removed(self) -> None:
        graph = PathGraph()
        query = Triple("L", "expression association", "G")
        graph.add(query, split="train2", line_number=1)
        graph.finalize()
        self.assertEqual(graph.paths("L", "G", excluded=query, max_depth=2, cap=10), [])
        self.assertEqual(graph.paths("G", "L", excluded=query, max_depth=2, cap=10), [])

    def test_singleton_typed_negative_pool_is_recorded_without_fabrication(self) -> None:
        graph = PathGraph()
        positive = Triple("L", "expression association", "G")
        graph.add(positive, split="train2", line_number=1)
        graph.finalize()
        model = PLNPathModel(minimum_support=1, negatives_per_positive=1)
        model.fit(
            graph,
            [positive],
            {"L": "lncRNA", "G": "gene"},
            training_manifest_sha256="a" * 64,
        )
        self.assertEqual(model.training_statistics["actual_sampled_negative_count"], 0)
        self.assertEqual(
            model.training_statistics["positives_without_type_matched_negative_candidates"],
            1,
        )
        self.assertIn("never broaden", model.training_statistics["sampled_negative_shortfall_policy"])

    def test_certificate_rejects_unaccounted_evidence(self) -> None:
        graph, train2, types = self._graph()
        model = PLNPathModel(max_depth=2, minimum_support=1, negatives_per_positive=2)
        model.fit(graph, train2, types, training_manifest_sha256="a" * 64)
        _, certificate = model.score_with_certificate(
            graph,
            Triple("L3", "expression association", "G3"),
            split="valid",
            prediction_id="positive",
        )
        certificate["aggregation"]["input_evidence_ids"] = []
        with self.assertRaises(SuiteError):
            validate_certificate(certificate)


class MetricsAndHybridTests(unittest.TestCase):
    def test_candidate_scores_become_honest_rank_rows(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            candidates = directory / "candidates.jsonl"
            predictions = directory / "predictions.jsonl"
            write_jsonl(
                candidates,
                [
                    {"query_id": "q", "candidate_id": "true", "is_observed_positive": True, "score": 0.8},
                    {"query_id": "q", "candidate_id": "n1", "is_observed_positive": False, "score": 0.1},
                    {"query_id": "q", "candidate_id": "n2", "is_observed_positive": False, "score": 0.2},
                ],
            )
            rank_candidate_rows(candidates, predictions, score_field="score", sampled_candidates=2, seed=1)
            rows = [json.loads(line) for line in predictions.read_text(encoding="utf-8").splitlines()]
            self.assertEqual(rows[0]["rank"], 1.0)
            self.assertTrue(
                all(
                    example["label_origin"] == "type-matched-sampled-negative"
                    for example in rows[0]["calibration_examples"]
                    if example["label"] == 0
                )
            )

    def test_metrics_and_paired_bootstrap(self) -> None:
        better = [
            {"query_id": "q1", "rank": 1, "candidate_count": 4},
            {"query_id": "q2", "rank": 2, "candidate_count": 4},
        ]
        worse = [
            {"query_id": "q1", "rank": 2, "candidate_count": 4},
            {"query_id": "q2", "rank": 4, "candidate_count": 4},
        ]
        self.assertAlmostEqual(ranking_metrics(better)["mrr"], 0.75)
        result = paired_bootstrap(better, worse, replicates=100, confidence=0.95, seed=1)
        self.assertGreater(result["left_minus_right_mrr"], 0)

    def test_unpaired_bootstrap_fails(self) -> None:
        with self.assertRaises(SuiteError):
            paired_bootstrap(
                [{"query_id": "q1", "rank": 1}],
                [{"query_id": "q2", "rank": 1}],
                replicates=10,
                confidence=0.95,
                seed=1,
            )

    def test_end_to_end_join_train_predict_and_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            control = directory / "control.jsonl"
            pln = directory / "pln.jsonl"
            joined = directory / "joined.jsonl"
            model = directory / "hybrid.json"
            predictions = directory / "predictions.jsonl"
            control_rows = []
            pln_rows = []
            for query_id, positive in (("valid:1", "A"), ("valid:2", "B")):
                for candidate, bio, pln_score in ((positive, 0.8, 0.9), ("X", 0.2, 0.1), ("Y", 0.3, 0.2)):
                    is_positive = candidate == positive
                    control_rows.append(
                        {
                            "query_id": query_id,
                            "candidate_id": candidate,
                            "is_observed_positive": is_positive,
                            "biopathnet_score": bio,
                        }
                    )
                    pln_rows.append(
                        {
                            "query_id": query_id,
                            "candidate_id": candidate,
                            "is_observed_positive": is_positive,
                            "pln_score": pln_score,
                            "label": 1 if is_positive else 0,
                            "label_origin": (
                                "observed-positive" if is_positive else "type-matched-sampled-negative"
                            ),
                        }
                    )
            write_jsonl(control, control_rows)
            write_jsonl(pln, pln_rows)
            join_control_pln_features(control, pln, joined)
            train_hybrid(joined, model, l2=0.001)
            result = score_hybrid(joined, model, predictions)
            self.assertEqual(result["queries"], 2)
            rows = [json.loads(line) for line in predictions.read_text(encoding="utf-8").splitlines()]
            metrics = ranking_metrics(rows)
            self.assertEqual(metrics["mrr"], 1.0)
            artifact = json.loads(model.read_text(encoding="utf-8"))
            self.assertTrue(all(weight >= 0 for weight in artifact["weights"]))

    def test_hybrid_rejects_unqualified_zero_label(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            features = directory / "features.jsonl"
            write_jsonl(
                features,
                [
                    {
                        "query_id": "q",
                        "candidate_id": "x",
                        "biopathnet_score": 0.2,
                        "pln_score": 0.3,
                        "label": 0,
                        "label_origin": "known-false",
                    }
                ],
            )
            with self.assertRaises(SuiteError):
                train_hybrid(features, directory / "model.json", l2=0.001)


if __name__ == "__main__":
    unittest.main()
