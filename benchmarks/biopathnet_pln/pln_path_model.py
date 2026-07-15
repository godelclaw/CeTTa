#!/usr/bin/env python3
"""Relation-path PLN evidence model and nonnegative hybrid combiner."""

from __future__ import annotations

import argparse
import bisect
import hashlib
import json
import math
import random
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping, Sequence

from biopathnet_suite import (
    SuiteError,
    Triple,
    canonical_json_bytes,
    claim_test_access,
    complete_test_access,
    load_json,
    parse_entity_map,
    parse_triples,
    sha256_bytes,
    sha256_file,
    validate_certificate,
    write_json,
)


@dataclass(frozen=True)
class Edge:
    source: str
    relation: str
    target: str
    origin: Triple
    provenance: str
    split: str


@dataclass(frozen=True)
class WitnessPath:
    nodes: tuple[str, ...]
    relations: tuple[str, ...]
    edges: tuple[Edge, ...]

    def display(self) -> list[str]:
        result = [self.nodes[0]]
        for relation, node in zip(self.relations, self.nodes[1:]):
            result.extend((relation, node))
        return result


def _line_digest(split: str, line_number: int, triple: Triple) -> str:
    payload = f"{split}\t{line_number}\t{triple.head}\t{triple.relation}\t{triple.tail}\n".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


class PathGraph:
    def __init__(self) -> None:
        self.adjacency: dict[str, list[Edge]] = defaultdict(list)
        # Built lazily for final-hop target lookups.  Keeping Edge objects shared
        # avoids duplicating the million-edge graph while permitting a traversal
        # to batch many tails for one source.
        self._target_adjacency: dict[str, list[Edge]] = {}
        self._finalized = False

    def add(self, triple: Triple, *, split: str, line_number: int) -> None:
        if self._finalized:
            raise SuiteError("cannot add edges after graph finalization")
        provenance = _line_digest(split, line_number, triple)
        forward = Edge(triple.head, triple.relation, triple.tail, triple, provenance, split)
        inverse = Edge(triple.tail, "inverse:" + triple.relation, triple.head, triple, provenance, split)
        self.adjacency[forward.source].append(forward)
        self.adjacency[inverse.source].append(inverse)

    def finalize(self) -> None:
        for edges in self.adjacency.values():
            edges.sort(key=lambda edge: (edge.relation, edge.target, edge.provenance))
        self._finalized = True

    def _edges_to_targets(self, source: str, targets: set[str]) -> Iterable[Edge]:
        """Yield final-hop edges without changing per-target path order.

        A full adjacency scan is cheaper when the target set is broad.  For a
        narrow target set, a lazily cached target-major view avoids inspecting
        unrelated high-degree edges.  Within any one target, both views order
        edges by relation and provenance, exactly as ``paths`` historically did.
        """
        edges = self.adjacency.get(source, ())
        if not edges or not targets:
            return ()
        if len(targets) * 4 >= len(edges):
            return (edge for edge in edges if edge.target in targets)
        target_edges = self._target_adjacency.get(source)
        if target_edges is None:
            target_edges = sorted(edges, key=lambda edge: (edge.target, edge.relation, edge.provenance))
            self._target_adjacency[source] = target_edges
        selected: list[Edge] = []
        for target in sorted(targets):
            start = bisect.bisect_left(target_edges, target, key=lambda edge: edge.target)
            stop = bisect.bisect_right(target_edges, target, key=lambda edge: edge.target)
            selected.extend(target_edges[start:stop])
        return selected

    def _walk_many(
        self,
        head: str,
        requests: Sequence[tuple[str, Triple | None]],
        *,
        max_depth: int,
        cap: int,
        visit: Callable[[int, WitnessPath], None],
    ) -> None:
        """Run one exact BFS for many target/exclusion requests.

        ``visit(index, path)`` receives precisely the paths that an independent
        call to :meth:`paths` would receive, in the same order and under the
        same per-request cap.  Shared prefixes are expanded once.  Reaching the
        target for one request does not stop expansion for other targets; the
        simple-path condition makes that continuation irrelevant to the first
        target because it cannot be revisited.
        """
        if max_depth < 1 or cap < 1:
            raise SuiteError("max_depth and path cap must be positive")
        if not requests:
            return
        if not self._finalized:
            self.finalize()
        request_indices: dict[str, list[int]] = defaultdict(list)
        for index, (target, _excluded) in enumerate(requests):
            request_indices[target].append(index)
        found_counts = [0] * len(requests)

        def active_targets() -> set[str]:
            return {
                target
                for target, indices in request_indices.items()
                if any(found_counts[index] < cap for index in indices)
            }

        def record(
            target: str,
            nodes: tuple[str, ...],
            relations: tuple[str, ...],
            edges: tuple[Edge, ...],
        ) -> None:
            indices = request_indices.get(target)
            if indices is None:
                return
            path: WitnessPath | None = None
            for index in indices:
                if found_counts[index] >= cap:
                    continue
                excluded = requests[index][1]
                if excluded is not None and any(edge.origin == excluded for edge in edges):
                    continue
                if path is None:
                    path = WitnessPath(nodes, relations, edges)
                visit(index, path)
                found_counts[index] += 1

        frontier: list[tuple[tuple[str, ...], tuple[str, ...], tuple[Edge, ...]]] = [
            ((head,), (), ())
        ]
        for depth in range(max_depth):
            targets = active_targets()
            if not targets or not frontier:
                break
            final_hop = depth + 1 == max_depth
            next_frontier: list[tuple[tuple[str, ...], tuple[str, ...], tuple[Edge, ...]]] = []
            final_edges_by_source: dict[str, tuple[Edge, ...]] = {}
            for nodes, relations, path_edges in frontier:
                source = nodes[-1]
                if final_hop:
                    candidate_edges = final_edges_by_source.get(source)
                    if candidate_edges is None:
                        candidate_edges = tuple(self._edges_to_targets(source, targets))
                        final_edges_by_source[source] = candidate_edges
                else:
                    candidate_edges = self.adjacency.get(source, ())
                for edge in candidate_edges:
                    if edge.target in nodes:
                        continue
                    new_nodes = nodes + (edge.target,)
                    new_relations = relations + (edge.relation,)
                    new_edges = path_edges + (edge,)
                    if edge.target in targets:
                        record(edge.target, new_nodes, new_relations, new_edges)
                    if not final_hop:
                        next_frontier.append((new_nodes, new_relations, new_edges))
            frontier = next_frontier

    def paths_many(
        self,
        head: str,
        requests: Sequence[tuple[str, Triple | None]],
        *,
        max_depth: int,
        cap: int,
    ) -> list[list[WitnessPath]]:
        """Return exact capped paths for many tails sharing ``head``."""
        found: list[list[WitnessPath]] = [[] for _ in requests]
        self._walk_many(
            head,
            requests,
            max_depth=max_depth,
            cap=cap,
            visit=lambda index, path: found[index].append(path),
        )
        return found

    def path_templates_many(
        self,
        head: str,
        requests: Sequence[tuple[str, Triple | None]],
        *,
        max_depth: int,
        cap: int,
    ) -> list[set[tuple[str, ...]]]:
        """Return unique templates among each request's first ``cap`` paths."""
        templates: list[set[tuple[str, ...]]] = [set() for _ in requests]
        self._walk_many(
            head,
            requests,
            max_depth=max_depth,
            cap=cap,
            visit=lambda index, path: templates[index].add(path.relations),
        )
        return templates

    def paths(
        self,
        head: str,
        tail: str,
        *,
        excluded: Triple | None,
        max_depth: int,
        cap: int,
    ) -> list[WitnessPath]:
        return self.paths_many(
            head,
            [(tail, excluded)],
            max_depth=max_depth,
            cap=cap,
        )[0]


@dataclass
class TemplateEvidence:
    positive_count: int = 0
    sampled_negative_count: int = 0

    def posterior(self, alpha: int, beta: int) -> float:
        return (self.positive_count + alpha) / (
            self.positive_count + self.sampled_negative_count + alpha + beta
        )


class PLNPathModel:
    def __init__(
        self,
        *,
        max_depth: int = 3,
        minimum_support: int = 2,
        alpha: int = 1,
        beta: int = 1,
        path_cap: int = 512,
        negatives_per_positive: int = 32,
        seed: int = 1729,
    ) -> None:
        if min(max_depth, minimum_support, alpha, beta, path_cap, negatives_per_positive) < 1:
            raise SuiteError("PLN path-model integer parameters must be positive")
        self.max_depth = max_depth
        self.minimum_support = minimum_support
        self.alpha = alpha
        self.beta = beta
        self.path_cap = path_cap
        self.negatives_per_positive = negatives_per_positive
        self.seed = seed
        self.templates: dict[tuple[str, tuple[str, ...]], TemplateEvidence] = {}
        self.training_manifest_sha256 = ""
        self.training_statistics: dict[str, int | str] = {}

    @staticmethod
    def _unique_templates(paths: Iterable[WitnessPath]) -> set[tuple[str, ...]]:
        return {path.relations for path in paths}

    def fit(
        self,
        graph: PathGraph,
        supervision: Sequence[Triple],
        entity_types: Mapping[str, str],
        *,
        training_manifest_sha256: str,
    ) -> None:
        generator = random.Random(self.seed)
        pools: dict[str, list[str]] = defaultdict(list)
        for entity, entity_type in entity_types.items():
            pools[entity_type].append(entity)
        for pool in pools.values():
            pool.sort()
        known_training = {(triple.head, triple.relation, triple.tail) for triple in supervision}
        counts: dict[tuple[str, tuple[str, ...]], TemplateEvidence] = defaultdict(TemplateEvidence)
        # Build requests in the historical supervision order so seeded negative
        # sampling remains byte-for-byte deterministic.  Traversal is then
        # grouped by source; count addition is commutative.
        work_by_head: dict[
            str,
            dict[tuple[str, Triple | None], list[tuple[str, bool]]],
        ] = defaultdict(lambda: defaultdict(list))
        sampled_negative_requests = 0
        positives_without_negative_candidates = 0
        for positive in supervision:
            work_by_head[positive.head][(positive.tail, positive)].append((positive.relation, True))

            target_type = entity_types.get(positive.tail)
            if target_type is None:
                raise SuiteError(f"training target lacks entity type: {positive.tail}")
            candidates = [
                candidate
                for candidate in pools[target_type]
                if candidate != positive.tail
                and (positive.head, positive.relation, candidate) not in known_training
            ]
            if not candidates:
                positives_without_negative_candidates += 1
                continue
            sample_count = min(self.negatives_per_positive, len(candidates))
            sampled_negative_requests += sample_count
            for negative_tail in generator.sample(candidates, sample_count):
                work_by_head[positive.head][(negative_tail, None)].append((positive.relation, False))

        for head in sorted(work_by_head):
            work = work_by_head[head]
            requests = list(work)
            template_sets = graph.path_templates_many(
                head,
                requests,
                max_depth=self.max_depth,
                cap=self.path_cap,
            )
            for request, templates in zip(requests, template_sets):
                for query_relation, is_positive in work[request]:
                    for template in templates:
                        evidence = counts[(query_relation, template)]
                        if is_positive:
                            evidence.positive_count += 1
                        else:
                            evidence.sampled_negative_count += 1

        self.templates = {
            key: value
            for key, value in counts.items()
            if value.positive_count + value.sampled_negative_count >= self.minimum_support
        }
        self.training_manifest_sha256 = training_manifest_sha256
        requested_negative_requests = len(supervision) * self.negatives_per_positive
        self.training_statistics = {
            "supervised_positive_count": len(supervision),
            "requested_sampled_negative_count": requested_negative_requests,
            "actual_sampled_negative_count": sampled_negative_requests,
            "sampled_negative_shortfall_count": (
                requested_negative_requests - sampled_negative_requests
            ),
            "positives_without_type_matched_negative_candidates": (
                positives_without_negative_candidates
            ),
            "sampled_negative_shortfall_policy": (
                "use-all-available-and-record; never broaden target type"
            ),
        }

    def _supported_paths(
        self,
        graph: PathGraph,
        query: Triple,
    ) -> list[tuple[WitnessPath, TemplateEvidence]]:
        paths = graph.paths(
            query.head,
            query.tail,
            excluded=query,
            max_depth=self.max_depth,
            cap=self.path_cap,
        )
        supported = []
        for path in paths:
            evidence = self.templates.get((query.relation, path.relations))
            if evidence is not None:
                supported.append((path, evidence))
        return supported

    def _score_selected(
        self,
        query: Triple,
        grouped: Mapping[str, tuple[WitnessPath, TemplateEvidence]],
        *,
        split: str,
        prediction_id: str,
        emit_certificate: bool,
    ) -> tuple[float, dict[str, Any] | None]:
        selected = [(group, *grouped[group]) for group in sorted(grouped)]
        positive = self.alpha + sum(item[2].positive_count for item in selected)
        negative = self.beta + sum(item[2].sampled_negative_count for item in selected)
        score = positive / (positive + negative)
        if not emit_certificate:
            return score, None
        certificate_evidence = []
        for group, path, evidence in selected:
            evidence_id = sha256_bytes(
                canonical_json_bytes(
                    {
                        "query": query.as_tuple(),
                        "template": path.relations,
                        "path": path.display(),
                        "group": group,
                    }
                )
            )
            certificate_evidence.append(
                {
                    "evidence_id": evidence_id,
                    "path": path.display(),
                    "template": list(path.relations),
                    "positive_count": evidence.positive_count,
                    "sampled_negative_count": evidence.sampled_negative_count,
                    "dependence_group": group,
                    "provenance": [
                        {"split": edge.split, "line_sha256": edge.provenance} for edge in path.edges
                    ],
                }
            )
        certificate = {
            "schema_version": 1,
            "prediction_id": prediction_id,
            "model": "pln-path-evidence",
            "split": split,
            "seed": self.seed,
            "query": {"head": query.head, "relation": query.relation, "tail": query.tail},
            "training_manifest_sha256": self.training_manifest_sha256,
            "score": {"kind": "pln-evidence-probability", "value": score},
            "evidence": certificate_evidence,
            "aggregation": {
                "rule": "pln-count-revision",
                "input_evidence_ids": [item["evidence_id"] for item in certificate_evidence],
                "dependence_policy": "shared-first-edge-max-before-revision",
            },
        }
        validate_certificate(certificate)
        return score, certificate

    def score_many_with_certificates(
        self,
        graph: PathGraph,
        queries: Sequence[Triple],
        *,
        split: str,
        prediction_ids: Sequence[str],
        certificate_indices: set[int] | None = None,
    ) -> list[tuple[float, dict[str, Any] | None]]:
        """Score queries while sharing traversal among queries with one head.

        ``certificate_indices`` may restrict certificate materialization without
        changing any scores.  Traversal still accounts for every query and the
        selected witnesses remain available for requested certificates.
        """
        if split not in {"valid", "test"}:
            raise SuiteError("prediction certificates are only emitted for valid or test")
        if len(queries) != len(prediction_ids):
            raise SuiteError("queries and prediction IDs must be aligned")
        if certificate_indices is None:
            certificate_indices = set(range(len(queries)))
        elif any(index < 0 or index >= len(queries) for index in certificate_indices):
            raise SuiteError("certificate index outside query batch")
        grouped_selected: list[dict[str, tuple[WitnessPath, TemplateEvidence]]] = [
            {} for _ in queries
        ]
        query_indices_by_head: dict[str, list[int]] = defaultdict(list)
        for index, query in enumerate(queries):
            query_indices_by_head[query.head].append(index)

        for head in sorted(query_indices_by_head):
            global_indices = query_indices_by_head[head]
            requests = [(queries[index].tail, queries[index]) for index in global_indices]

            def select(local_index: int, path: WitnessPath) -> None:
                global_index = global_indices[local_index]
                query = queries[global_index]
                evidence = self.templates.get((query.relation, path.relations))
                if evidence is None:
                    return
                group = path.edges[0].provenance
                candidate_key = (
                    -abs(
                        evidence.posterior(self.alpha, self.beta)
                        - self.alpha / (self.alpha + self.beta)
                    ),
                    path.relations,
                    path.nodes,
                )
                current = grouped_selected[global_index].get(group)
                if current is None:
                    grouped_selected[global_index][group] = (path, evidence)
                    return
                current_path, current_evidence = current
                current_key = (
                    -abs(
                        current_evidence.posterior(self.alpha, self.beta)
                        - self.alpha / (self.alpha + self.beta)
                    ),
                    current_path.relations,
                    current_path.nodes,
                )
                if candidate_key < current_key:
                    grouped_selected[global_index][group] = (path, evidence)

            graph._walk_many(
                head,
                requests,
                max_depth=self.max_depth,
                cap=self.path_cap,
                visit=select,
            )

        return [
            self._score_selected(
                query,
                grouped_selected[index],
                split=split,
                prediction_id=prediction_ids[index],
                emit_certificate=index in certificate_indices,
            )
            for index, query in enumerate(queries)
        ]

    def score_with_certificate(
        self,
        graph: PathGraph,
        query: Triple,
        *,
        split: str,
        prediction_id: str,
    ) -> tuple[float, dict[str, Any]]:
        result = self.score_many_with_certificates(
            graph,
            [query],
            split=split,
            prediction_ids=[prediction_id],
        )[0]
        score, certificate = result
        if certificate is None:
            raise AssertionError("single-query scoring failed to emit a certificate")
        return score, certificate

    def to_json(self) -> dict[str, Any]:
        templates = []
        for (query_relation, path_relations), evidence in sorted(self.templates.items()):
            templates.append(
                {
                    "query_relation": query_relation,
                    "path_relations": list(path_relations),
                    "positive_count": evidence.positive_count,
                    "sampled_negative_count": evidence.sampled_negative_count,
                }
            )
        return {
            "schema_version": 1,
            "model": "pln-path-evidence",
            "parameters": {
                "max_depth": self.max_depth,
                "minimum_support": self.minimum_support,
                "alpha": self.alpha,
                "beta": self.beta,
                "path_cap": self.path_cap,
                "negatives_per_positive": self.negatives_per_positive,
                "seed": self.seed,
            },
            "training_manifest_sha256": self.training_manifest_sha256,
            "training_statistics": self.training_statistics,
            "templates": templates,
        }

    @classmethod
    def from_json(cls, payload: Mapping[str, Any]) -> "PLNPathModel":
        if payload.get("schema_version") != 1 or payload.get("model") != "pln-path-evidence":
            raise SuiteError("not a PLN path-model artifact")
        model = cls(**payload["parameters"])
        model.training_manifest_sha256 = payload["training_manifest_sha256"]
        statistics = payload.get("training_statistics", {})
        if not isinstance(statistics, dict):
            raise SuiteError("PLN path-model training_statistics must be an object")
        model.training_statistics = dict(statistics)
        model.templates = {
            (item["query_relation"], tuple(item["path_relations"])): TemplateEvidence(
                item["positive_count"], item["sampled_negative_count"]
            )
            for item in payload["templates"]
        }
        return model


class NonnegativeLogisticStacker:
    def __init__(self, *, l2: float = 0.001, learning_rate: float = 0.1, steps: int = 2000) -> None:
        if l2 < 0 or learning_rate <= 0 or steps < 1:
            raise SuiteError("invalid logistic-stacker parameters")
        self.l2 = l2
        self.learning_rate = learning_rate
        self.steps = steps
        self.weights = [0.0, 0.0]
        self.intercept = 0.0

    @staticmethod
    def _sigmoid(value: float) -> float:
        if value >= 0:
            inverse = math.exp(-value)
            return 1.0 / (1.0 + inverse)
        exponent = math.exp(value)
        return exponent / (1.0 + exponent)

    def fit(self, features: Sequence[tuple[float, float]], labels: Sequence[int]) -> None:
        if len(features) != len(labels) or not features:
            raise SuiteError("hybrid features and labels must be nonempty and aligned")
        if any(label not in (0, 1) for label in labels):
            raise SuiteError("hybrid labels must be observed-positive or sampled-negative indicators")
        prevalence = (sum(labels) + 0.5) / (len(labels) + 1.0)
        self.intercept = math.log(prevalence / (1.0 - prevalence))
        self.weights = [0.0, 0.0]
        count = len(labels)
        for step in range(self.steps):
            gradient_w = [0.0, 0.0]
            gradient_b = 0.0
            for feature, label in zip(features, labels):
                prediction = self.predict(feature)
                residual = prediction - label
                gradient_b += residual
                gradient_w[0] += residual * feature[0]
                gradient_w[1] += residual * feature[1]
            rate = self.learning_rate / math.sqrt(1.0 + step / 100.0)
            self.intercept -= rate * gradient_b / count
            for index in range(2):
                gradient = gradient_w[index] / count + self.l2 * self.weights[index]
                self.weights[index] = max(0.0, self.weights[index] - rate * gradient)

    def predict(self, feature: tuple[float, float]) -> float:
        value = self.intercept + sum(weight * item for weight, item in zip(self.weights, feature))
        return self._sigmoid(value)

    def to_json(self) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "model": "biopathnet-pln-hybrid",
            "feature_semantics": ["biopathnet-logit", "pln-evidence-log-odds"],
            "weights": self.weights,
            "intercept": self.intercept,
            "l2": self.l2,
            "nonnegative_feature_weights": True,
            "label_semantics": "observed positives versus type-matched sampled negatives",
        }

    @classmethod
    def from_json(cls, payload: Mapping[str, Any]) -> "NonnegativeLogisticStacker":
        if payload.get("schema_version") != 1 or payload.get("model") != "biopathnet-pln-hybrid":
            raise SuiteError("not a BioPathNet/PLN hybrid artifact")
        model = cls(l2=float(payload["l2"]))
        weights = payload.get("weights")
        if not isinstance(weights, list) or len(weights) != 2 or any(float(weight) < 0 for weight in weights):
            raise SuiteError("hybrid artifact has invalid nonnegative weights")
        model.weights = [float(weight) for weight in weights]
        model.intercept = float(payload["intercept"])
        return model


def _clipped_logit(probability: float) -> float:
    if not 0 <= probability <= 1:
        raise SuiteError(f"probability outside [0, 1]: {probability}")
    clipped = min(1.0 - 1e-8, max(1e-8, probability))
    return math.log(clipped / (1.0 - clipped))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, raw in enumerate(handle, start=1):
            try:
                row = json.loads(raw)
            except json.JSONDecodeError as error:
                raise SuiteError(f"{path.name}:{line_number}: invalid JSON: {error}") from error
            if not isinstance(row, dict):
                raise SuiteError(f"{path.name}:{line_number}: expected a JSON object")
            rows.append(row)
    if not rows:
        raise SuiteError(f"{path.name}: no rows")
    return rows


def _write_jsonl(path: Path, rows: Iterable[Mapping[str, Any]], *, exclusive: bool = True) -> None:
    if exclusive and path.exists():
        raise SuiteError(f"refusing to replace existing artifact: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".new")
    with temporary.open("wb") as handle:
        for row in rows:
            handle.write(canonical_json_bytes(row))
        handle.flush()
    temporary.replace(path)


def train_hybrid(feature_path: Path, output: Path, *, l2: float) -> dict[str, Any]:
    rows = _read_jsonl(feature_path)
    features = []
    labels = []
    for line_number, row in enumerate(rows, start=1):
        origin = row.get("label_origin")
        label = row.get("label")
        if origin not in {"observed-positive", "type-matched-sampled-negative"}:
            raise SuiteError(f"{feature_path.name}:{line_number}: dishonest or missing label_origin")
        if label not in (0, 1):
            raise SuiteError(f"{feature_path.name}:{line_number}: label must be zero or one")
        if label == 0 and origin != "type-matched-sampled-negative":
            raise SuiteError(f"{feature_path.name}:{line_number}: zero labels must be named sampled negatives")
        features.append(
            (
                _clipped_logit(float(row["biopathnet_score"])),
                _clipped_logit(float(row["pln_score"])),
            )
        )
        labels.append(label)
    model = NonnegativeLogisticStacker(l2=l2)
    model.fit(features, labels)
    artifact = model.to_json()
    artifact["training_features_sha256"] = sha256_file(feature_path)
    write_json(output, artifact, exclusive=True)
    return {"status": "ok", "model_sha256": sha256_file(output), "weights": model.weights}


def score_hybrid(feature_path: Path, model_path: Path, output: Path) -> dict[str, Any]:
    model = NonnegativeLogisticStacker.from_json(load_json(model_path))
    source_rows = _read_jsonl(feature_path)
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for line_number, row in enumerate(source_rows, start=1):
        query_id = row.get("query_id")
        candidate = row.get("candidate_id")
        if not isinstance(query_id, str) or not isinstance(candidate, str):
            raise SuiteError(f"{feature_path.name}:{line_number}: query_id and candidate_id are required")
        scored = dict(row)
        scored["hybrid_score"] = model.predict(
            (
                _clipped_logit(float(row["biopathnet_score"])),
                _clipped_logit(float(row["pln_score"])),
            )
        )
        grouped[query_id].append(scored)
    predictions = []
    for query_id, candidates in sorted(grouped.items()):
        positives = [candidate for candidate in candidates if candidate.get("is_observed_positive") is True]
        if len(positives) != 1:
            raise SuiteError(f"{query_id}: expected exactly one observed-positive candidate")
        positive = positives[0]
        higher = sum(candidate["hybrid_score"] > positive["hybrid_score"] for candidate in candidates)
        tied = sum(candidate["hybrid_score"] == positive["hybrid_score"] for candidate in candidates) - 1
        rank = 1.0 + higher + tied / 2.0
        predictions.append(
            {
                "query_id": query_id,
                "rank": rank,
                "candidate_count": len(candidates),
                "positive_score": positive["hybrid_score"],
                "calibration_examples": [
                    {
                        "label": 1 if candidate.get("is_observed_positive") is True else 0,
                        "label_origin": (
                            "observed-positive"
                            if candidate.get("is_observed_positive") is True
                            else "type-matched-sampled-negative"
                        ),
                        "score": candidate["hybrid_score"],
                    }
                    for candidate in candidates
                    if candidate.get("is_observed_positive") is True
                    or candidate.get("label_origin") == "type-matched-sampled-negative"
                ],
            }
        )
    _write_jsonl(output, predictions)
    return {"status": "ok", "queries": len(predictions), "predictions_sha256": sha256_file(output)}


def score_pln_queries(
    model_path: Path,
    data_dir: Path,
    queries_path: Path,
    output: Path,
    certificates: Path,
    features_output: Path,
    *,
    split: str,
    sampled_candidates: int,
) -> dict[str, Any]:
    if split not in {"valid", "test"}:
        raise SuiteError("PLN scoring split must be valid or test")
    model = PLNPathModel.from_json(load_json(model_path))
    graph, supervision, entity_types, training_manifest = load_training_graph(data_dir)
    if training_manifest != model.training_manifest_sha256:
        raise SuiteError("PLN model was not trained from the supplied training graph")
    pools: dict[str, list[str]] = defaultdict(list)
    for entity, entity_type in entity_types.items():
        pools[entity_type].append(entity)
    for pool in pools.values():
        pool.sort()
    training_truth = {(triple.head, triple.relation, triple.tail) for triple in supervision}
    query_rows = list(parse_triples(queries_path))
    current_truth = {(triple.head, triple.relation, triple.tail) for _, triple in query_rows}
    predictions = []
    certificate_rows = []
    feature_rows = []
    generator = random.Random(model.seed + (1 if split == "valid" else 2))
    for line_number, query in query_rows:
        target_type = entity_types.get(query.tail)
        if target_type is None:
            raise SuiteError(f"{queries_path.name}:{line_number}: target lacks entity type")
        candidates = pools[target_type]
        candidate_ids: list[str] = []
        candidate_queries: list[Triple] = []
        for candidate in candidates:
            if candidate != query.tail and (
                (query.head, query.relation, candidate) in training_truth
                or (query.head, query.relation, candidate) in current_truth
            ):
                continue
            candidate_ids.append(candidate)
            candidate_queries.append(Triple(query.head, query.relation, candidate))
        try:
            true_index = candidate_ids.index(query.tail)
        except ValueError as error:
            raise SuiteError(f"{queries_path.name}:{line_number}: true target was not scored") from error
        scored = model.score_many_with_certificates(
            graph,
            candidate_queries,
            split=split,
            prediction_ids=[f"{split}:{line_number}:{candidate}" for candidate in candidate_ids],
            certificate_indices={true_index},
        )
        candidate_scores = [
            (candidate, score)
            for candidate, (score, _certificate) in zip(candidate_ids, scored)
        ]
        true_certificate = scored[true_index][1]
        if true_certificate is None:
            raise AssertionError("true-target certificate was not emitted")
        score_by_candidate = dict(candidate_scores)
        true_score = score_by_candidate[query.tail]
        higher = sum(score > true_score for _, score in candidate_scores)
        tied = sum(score == true_score for _, score in candidate_scores) - 1
        rank = 1.0 + higher + tied / 2.0
        negative_pool = [item for item in candidate_scores if item[0] != query.tail]
        negative_examples = generator.sample(negative_pool, min(sampled_candidates, len(negative_pool)))
        sampled_negative_ids = {candidate for candidate, _ in negative_examples}
        for candidate, score in candidate_scores:
            feature_row = {
                "query_id": f"{split}:{line_number}",
                "candidate_id": candidate,
                "is_observed_positive": candidate == query.tail,
                "pln_score": score,
            }
            if candidate == query.tail:
                feature_row.update({"label": 1, "label_origin": "observed-positive"})
            elif candidate in sampled_negative_ids:
                feature_row.update({"label": 0, "label_origin": "type-matched-sampled-negative"})
            feature_rows.append(feature_row)
        predictions.append(
            {
                "query_id": f"{split}:{line_number}",
                "rank": rank,
                "candidate_count": len(candidate_scores),
                "positive_score": true_score,
                "calibration_examples": [
                    {"label": 1, "label_origin": "observed-positive", "score": true_score}
                ]
                + [
                    {"label": 0, "label_origin": "type-matched-sampled-negative", "score": score}
                    for _, score in negative_examples
                ],
            }
        )
        certificate_rows.append(true_certificate)
    _write_jsonl(output, predictions)
    _write_jsonl(certificates, certificate_rows)
    _write_jsonl(features_output, feature_rows)
    return {
        "status": "ok",
        "queries": len(predictions),
        "predictions_sha256": sha256_file(output),
        "certificates_sha256": sha256_file(certificates),
        "features_sha256": sha256_file(features_output),
    }


def join_control_pln_features(control_path: Path, pln_path: Path, output: Path) -> dict[str, Any]:
    control_rows = _read_jsonl(control_path)
    pln_rows = _read_jsonl(pln_path)
    control = {(row["query_id"], row["candidate_id"]): row for row in control_rows}
    pln = {(row["query_id"], row["candidate_id"]): row for row in pln_rows}
    if len(control) != len(control_rows) or len(pln) != len(pln_rows):
        raise SuiteError("control and PLN feature keys must each be unique")
    if set(control) != set(pln):
        missing_control = sorted(set(pln) - set(control))[:5]
        missing_pln = sorted(set(control) - set(pln))[:5]
        raise SuiteError(
            f"control/PLN candidate sets differ: control-missing={missing_control}, PLN-missing={missing_pln}"
        )
    joined = []
    for key in sorted(control):
        left = control[key]
        right = pln[key]
        if left.get("is_observed_positive") is not right.get("is_observed_positive"):
            raise SuiteError(f"positive-label disagreement for {key}")
        row = {
            "query_id": key[0],
            "candidate_id": key[1],
            "is_observed_positive": left["is_observed_positive"],
            "biopathnet_score": left["biopathnet_score"],
            "pln_score": right["pln_score"],
        }
        if "label_origin" in right:
            row["label"] = right["label"]
            row["label_origin"] = right["label_origin"]
        joined.append(row)
    _write_jsonl(output, joined)
    return {"status": "ok", "candidate_rows": len(joined), "features_sha256": sha256_file(output)}


def load_training_graph(data_dir: Path) -> tuple[PathGraph, list[Triple], dict[str, str], str]:
    graph = PathGraph()
    file_hashes = {}
    for split_name in ("train1", "train2"):
        path = data_dir / f"{split_name}.txt"
        file_hashes[path.name] = sha256_file(path)
        for line_number, triple in parse_triples(path):
            graph.add(triple, split=split_name, line_number=line_number)
    graph.finalize()
    supervision = [triple for _, triple in parse_triples(data_dir / "train2.txt")]
    entity_types = parse_entity_map(data_dir / "entity_types.txt")
    training_manifest = {
        "files": file_hashes,
        "fact_graph": ["train1.txt", "train2.txt"],
        "held_out_files_read": [],
        "sampled_negative_semantics": "type-matched sampled negatives; not biological falsehoods",
    }
    return graph, supervision, entity_types, sha256_bytes(canonical_json_bytes(training_manifest))


def synthetic_smoke() -> dict[str, Any]:
    graph = PathGraph()
    train1 = [
        Triple("P1", "interacts-with", "G1"),
        Triple("P2", "interacts-with", "G2"),
        Triple("P3", "interacts-with", "G3"),
        Triple("PX", "controls-expression-of", "GX"),
    ]
    train2 = [
        Triple("L1", "interact with protein", "P1"),
        Triple("L1", "expression association", "G1"),
        Triple("L2", "interact with protein", "P2"),
        Triple("L2", "expression association", "G2"),
        Triple("L3", "interact with protein", "P3"),
    ]
    for line_number, triple in enumerate(train1, start=1):
        graph.add(triple, split="train1", line_number=line_number)
    for line_number, triple in enumerate(train2, start=1):
        graph.add(triple, split="train2", line_number=line_number)
    graph.finalize()
    entity_types = {
        "P1": "protein",
        "P2": "protein",
        "P3": "protein",
        "PX": "protein",
        "G1": "gene",
        "G2": "gene",
        "G3": "gene",
        "GX": "gene",
        "L1": "lncRNA",
        "L2": "lncRNA",
        "L3": "lncRNA",
    }
    training_manifest = sha256_bytes(canonical_json_bytes({"fixture": "synthetic-v1"}))
    model = PLNPathModel(
        max_depth=2,
        minimum_support=1,
        alpha=1,
        beta=1,
        path_cap=64,
        negatives_per_positive=3,
        seed=1729,
    )
    model.fit(
        graph,
        train2,
        entity_types,
        training_manifest_sha256=training_manifest,
    )
    positive_query = Triple("L3", "expression association", "G3")
    wrong_query = Triple("L3", "expression association", "GX")
    positive_score, certificate = model.score_with_certificate(
        graph, positive_query, split="valid", prediction_id="synthetic-positive"
    )
    wrong_score, _ = model.score_with_certificate(
        graph, wrong_query, split="valid", prediction_id="synthetic-negative-control"
    )
    if not positive_score > wrong_score:
        raise SuiteError(f"synthetic PLN ranking failed: positive={positive_score}, control={wrong_score}")
    stacker = NonnegativeLogisticStacker(l2=0.001, learning_rate=0.2, steps=1000)
    features = [(2.0, 2.0), (1.0, 1.5), (-1.0, -1.0), (-2.0, -1.5)]
    labels = [1, 1, 0, 0]
    stacker.fit(features, labels)
    if any(weight < 0 for weight in stacker.weights):
        raise SuiteError("nonnegative hybrid constraint failed")
    if not stacker.predict(features[0]) > stacker.predict(features[-1]):
        raise SuiteError("synthetic hybrid ranking failed")
    return {
        "status": "ok",
        "pln_positive_score": positive_score,
        "pln_negative_control_score": wrong_score,
        "certificate_evidence": len(certificate["evidence"]),
        "hybrid_weights": stacker.weights,
        "hybrid_positive_score": stacker.predict(features[0]),
        "hybrid_negative_control_score": stacker.predict(features[-1]),
        "model_templates": len(model.templates),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("synthetic-smoke")

    train = subparsers.add_parser("train-pln")
    train.add_argument("data_dir", type=Path)
    train.add_argument("output", type=Path)
    train.add_argument("--seed", type=int, default=1729)
    train.add_argument("--max-depth", type=int, default=3)
    train.add_argument("--minimum-support", type=int, default=2)
    train.add_argument("--alpha", type=int, default=1)
    train.add_argument("--beta", type=int, default=1)
    train.add_argument("--path-cap", type=int, default=512)
    train.add_argument("--negatives-per-positive", type=int, default=32)

    score = subparsers.add_parser("score-pln")
    score.add_argument("model", type=Path)
    score.add_argument("data_dir", type=Path)
    score.add_argument("queries", type=Path)
    score.add_argument("output", type=Path)
    score.add_argument("certificates", type=Path)
    score.add_argument("features", type=Path)
    score.add_argument("--split", choices=("valid", "test"), required=True)
    score.add_argument("--sampled-candidates", type=int, default=32)
    score.add_argument("--test-lock", type=Path)
    score.add_argument("--job-id")

    hybrid_train = subparsers.add_parser("train-hybrid")
    hybrid_train.add_argument("features", type=Path)
    hybrid_train.add_argument("output", type=Path)
    hybrid_train.add_argument("--l2", type=float, default=0.001)

    hybrid_score = subparsers.add_parser("score-hybrid")
    hybrid_score.add_argument("features", type=Path)
    hybrid_score.add_argument("model", type=Path)
    hybrid_score.add_argument("output", type=Path)
    hybrid_score.add_argument("--split", choices=("valid", "test"), required=True)
    hybrid_score.add_argument("--test-lock", type=Path)
    hybrid_score.add_argument("--job-id")

    join = subparsers.add_parser("join-features")
    join.add_argument("control", type=Path)
    join.add_argument("pln", type=Path)
    join.add_argument("output", type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "synthetic-smoke":
        sys.stdout.buffer.write(canonical_json_bytes(synthetic_smoke()))
        return 0
    if args.command == "train-pln":
        graph, supervision, entity_types, training_manifest = load_training_graph(args.data_dir)
        model = PLNPathModel(
            max_depth=args.max_depth,
            minimum_support=args.minimum_support,
            alpha=args.alpha,
            beta=args.beta,
            path_cap=args.path_cap,
            negatives_per_positive=args.negatives_per_positive,
            seed=args.seed,
        )
        model.fit(
            graph,
            supervision,
            entity_types,
            training_manifest_sha256=training_manifest,
        )
        write_json(args.output, model.to_json(), exclusive=True)
        sys.stdout.buffer.write(
            canonical_json_bytes(
                {
                    "status": "ok",
                    "model_sha256": sha256_file(args.output),
                    "templates": len(model.templates),
                }
            )
        )
        return 0
    if args.command == "score-pln":
        if args.sampled_candidates < 0:
            raise SuiteError("sampled-candidates must be nonnegative")
        if args.split == "test":
            if args.test_lock is None or not args.job_id:
                raise SuiteError("test scoring requires --test-lock and --job-id")
            claim_test_access(args.test_lock, args.job_id, "PLN path-model scoring")
        result = score_pln_queries(
            args.model,
            args.data_dir,
            args.queries,
            args.output,
            args.certificates,
            args.features,
            split=args.split,
            sampled_candidates=args.sampled_candidates,
        )
        if args.split == "test":
            complete_test_access(args.test_lock, args.job_id, args.output)
        sys.stdout.buffer.write(canonical_json_bytes(result))
        return 0
    if args.command == "join-features":
        sys.stdout.buffer.write(
            canonical_json_bytes(join_control_pln_features(args.control, args.pln, args.output))
        )
        return 0
    if args.command == "train-hybrid":
        sys.stdout.buffer.write(canonical_json_bytes(train_hybrid(args.features, args.output, l2=args.l2)))
        return 0
    if args.command == "score-hybrid":
        if args.split == "test":
            if args.test_lock is None or not args.job_id:
                raise SuiteError("test scoring requires --test-lock and --job-id")
            claim_test_access(args.test_lock, args.job_id, "frozen hybrid scoring")
        result = score_hybrid(args.features, args.model, args.output)
        if args.split == "test":
            complete_test_access(args.test_lock, args.job_id, args.output)
        sys.stdout.buffer.write(canonical_json_bytes(result))
        return 0
    raise SuiteError(f"unknown command: {args.command}")


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SuiteError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2)
