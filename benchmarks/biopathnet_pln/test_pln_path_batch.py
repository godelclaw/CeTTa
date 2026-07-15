#!/usr/bin/env python3

from __future__ import annotations

import random
import unittest
from collections import defaultdict

from biopathnet_suite import SuiteError, Triple
from pln_path_model import PLNPathModel, PathGraph, TemplateEvidence, WitnessPath


def reference_paths(
    graph: PathGraph,
    head: str,
    tail: str,
    *,
    excluded: Triple | None,
    max_depth: int,
    cap: int,
) -> list[WitnessPath]:
    """Independent copy of the original one-target breadth-first semantics."""
    if max_depth < 1 or cap < 1:
        raise SuiteError("max_depth and path cap must be positive")
    graph.finalize()
    found: list[WitnessPath] = []
    frontier = [(head, (head,), (), ())]
    for _depth in range(max_depth):
        next_frontier = []
        for node, nodes, relations, edges in frontier:
            for edge in graph.adjacency.get(node, ()):
                if excluded is not None and edge.origin == excluded:
                    continue
                if edge.target in nodes:
                    continue
                new_nodes = nodes + (edge.target,)
                new_relations = relations + (edge.relation,)
                new_edges = edges + (edge,)
                if edge.target == tail:
                    found.append(WitnessPath(new_nodes, new_relations, new_edges))
                    if len(found) >= cap:
                        return found
                else:
                    next_frontier.append((edge.target, new_nodes, new_relations, new_edges))
        frontier = next_frontier
        if not frontier:
            break
    return found


def path_signature(path: WitnessPath) -> tuple:
    return path.nodes, path.relations, tuple(edge.provenance for edge in path.edges)


class BatchedTraversalTests(unittest.TestCase):
    def _graph(self) -> tuple[PathGraph, list[Triple]]:
        triples = [
            Triple("H", "r", "A"),
            Triple("H", "s", "B"),
            Triple("A", "t", "C"),
            Triple("B", "u", "C"),
            Triple("C", "v", "D"),
            Triple("A", "w", "D"),
            Triple("B", "x", "A"),
        ] + [Triple("H", f"z{index:02d}", f"X{index:02d}") for index in range(20)]
        graph = PathGraph()
        for line_number, triple in enumerate(triples, 1):
            graph.add(triple, split="train", line_number=line_number)
        graph.finalize()
        return graph, triples

    def test_many_matches_original_order_cap_and_exclusion(self) -> None:
        graph, triples = self._graph()
        requests = [
            ("D", None),
            ("A", triples[0]),
            ("C", triples[1]),
            ("D", triples[0]),
            ("missing", None),
        ]
        for depth in range(1, 5):
            for cap in (1, 2, 10):
                batched = graph.paths_many("H", requests, max_depth=depth, cap=cap)
                expected = [
                    reference_paths(
                        graph,
                        "H",
                        target,
                        excluded=excluded,
                        max_depth=depth,
                        cap=cap,
                    )
                    for target, excluded in requests
                ]
                self.assertEqual(
                    [[path_signature(path) for path in paths] for paths in batched],
                    [[path_signature(path) for path in paths] for paths in expected],
                )

    def test_template_projection_counts_paths_before_deduplication(self) -> None:
        graph, _triples = self._graph()
        requests = [("D", None), ("C", None)]
        paths = graph.paths_many("H", requests, max_depth=3, cap=2)
        templates = graph.path_templates_many("H", requests, max_depth=3, cap=2)
        self.assertEqual(templates, [{path.relations for path in result} for result in paths])

    def test_invalid_batch_parameters_fail(self) -> None:
        graph, _triples = self._graph()
        with self.assertRaises(SuiteError):
            graph.paths_many("H", [("D", None)], max_depth=0, cap=1)
        with self.assertRaises(SuiteError):
            graph.path_templates_many("H", [("D", None)], max_depth=1, cap=0)


class BatchedModelTests(unittest.TestCase):
    def _fixture(self) -> tuple[PathGraph, list[Triple], dict[str, str]]:
        graph = PathGraph()
        train1 = [
            Triple("P1", "protein-gene", "G1"),
            Triple("P2", "protein-gene", "G2"),
            Triple("P3", "protein-gene", "G3"),
            Triple("P4", "protein-gene", "G4"),
        ]
        supervision = [
            Triple("L", "lnc-protein", "P1"),
            Triple("L", "lnc-gene", "G1"),
            Triple("L", "lnc-protein", "P2"),
            Triple("L", "lnc-gene", "G2"),
        ]
        for line_number, triple in enumerate(train1, 1):
            graph.add(triple, split="train1", line_number=line_number)
        for line_number, triple in enumerate(supervision, 1):
            graph.add(triple, split="train2", line_number=line_number)
        graph.finalize()
        types = {"L": "lncRNA"}
        types.update({f"P{index}": "protein" for index in range(1, 5)})
        types.update({f"G{index}": "gene" for index in range(1, 5)})
        return graph, supervision, types

    def _reference_counts(
        self,
        graph: PathGraph,
        supervision: list[Triple],
        entity_types: dict[str, str],
        model: PLNPathModel,
    ) -> dict[tuple[str, tuple[str, ...]], TemplateEvidence]:
        generator = random.Random(model.seed)
        pools: dict[str, list[str]] = defaultdict(list)
        for entity, entity_type in entity_types.items():
            pools[entity_type].append(entity)
        for pool in pools.values():
            pool.sort()
        known = {triple.as_tuple() for triple in supervision}
        counts: dict[tuple[str, tuple[str, ...]], TemplateEvidence] = defaultdict(TemplateEvidence)
        for positive in supervision:
            positive_paths = reference_paths(
                graph,
                positive.head,
                positive.tail,
                excluded=positive,
                max_depth=model.max_depth,
                cap=model.path_cap,
            )
            for template in {path.relations for path in positive_paths}:
                counts[(positive.relation, template)].positive_count += 1
            candidates = [
                candidate
                for candidate in pools[entity_types[positive.tail]]
                if candidate != positive.tail
                and (positive.head, positive.relation, candidate) not in known
            ]
            for target in generator.sample(candidates, min(model.negatives_per_positive, len(candidates))):
                negative_paths = reference_paths(
                    graph,
                    positive.head,
                    target,
                    excluded=None,
                    max_depth=model.max_depth,
                    cap=model.path_cap,
                )
                for template in {path.relations for path in negative_paths}:
                    counts[(positive.relation, template)].sampled_negative_count += 1
        return {
            key: value
            for key, value in counts.items()
            if value.positive_count + value.sampled_negative_count >= model.minimum_support
        }

    def test_batched_fit_matches_original_fit_and_is_deterministic(self) -> None:
        graph, supervision, types = self._fixture()
        first = PLNPathModel(max_depth=3, minimum_support=1, path_cap=8, negatives_per_positive=2)
        expected = self._reference_counts(graph, supervision, types, first)
        first.fit(graph, supervision, types, training_manifest_sha256="a" * 64)
        second = PLNPathModel(max_depth=3, minimum_support=1, path_cap=8, negatives_per_positive=2)
        second.fit(graph, supervision, types, training_manifest_sha256="a" * 64)
        self.assertEqual(first.templates, expected)
        self.assertEqual(first.to_json(), second.to_json())

    def test_batched_scores_and_certificates_match_single_target_evidence(self) -> None:
        graph, supervision, types = self._fixture()
        model = PLNPathModel(max_depth=3, minimum_support=1, path_cap=8, negatives_per_positive=2)
        model.fit(graph, supervision, types, training_manifest_sha256="b" * 64)
        queries = [
            Triple("L", "lnc-gene", "G1"),
            Triple("L", "lnc-gene", "G3"),
            Triple("L", "lnc-protein", "P2"),
        ]
        results = model.score_many_with_certificates(
            graph,
            queries,
            split="valid",
            prediction_ids=["q1", "q2", "q3"],
            certificate_indices={0, 2},
        )
        self.assertIsNotNone(results[0][1])
        self.assertIsNone(results[1][1])
        self.assertIsNotNone(results[2][1])
        for index in (0, 2):
            reference = reference_paths(
                graph,
                queries[index].head,
                queries[index].tail,
                excluded=queries[index],
                max_depth=model.max_depth,
                cap=model.path_cap,
            )
            grouped = {}
            for path in reference:
                evidence = model.templates.get((queries[index].relation, path.relations))
                if evidence is None:
                    continue
                group = path.edges[0].provenance
                candidate_key = (
                    -abs(
                        evidence.posterior(model.alpha, model.beta)
                        - model.alpha / (model.alpha + model.beta)
                    ),
                    path.relations,
                    path.nodes,
                )
                current = grouped.get(group)
                if current is None:
                    grouped[group] = (path, evidence)
                else:
                    current_path, current_evidence = current
                    current_key = (
                        -abs(
                            current_evidence.posterior(model.alpha, model.beta)
                            - model.alpha / (model.alpha + model.beta)
                        ),
                        current_path.relations,
                        current_path.nodes,
                    )
                    if candidate_key < current_key:
                        grouped[group] = (path, evidence)
            expected = model._score_selected(
                queries[index],
                grouped,
                split="valid",
                prediction_id=f"q{index + 1}",
                emit_certificate=True,
            )
            self.assertEqual(results[index], expected)


if __name__ == "__main__":
    unittest.main()
