#!/usr/bin/env python3
"""Executable regression for corrected symmetric relational candidate scoring."""

from __future__ import annotations

import argparse
import unittest
from pathlib import Path
from typing import Any

from control_runner import _imports


class _Graph:
    num_node = 9


class SymmetricCandidateTests(unittest.TestCase):
    modules: dict[str, Any]

    @classmethod
    def setUpClass(cls) -> None:
        upstream = Path(cls.upstream)
        cls.modules = dict(_imports(upstream))
        from biopathnet.model import NeuralBellmanFordNetwork

        cls.model_class = NeuralBellmanFordNetwork
        cls.torch = cls.modules["torch"]

    def _fake_model(self, chunk_size: int = 2) -> Any:
        torch = self.torch

        class FakeModel:
            num_relation = 3
            symmetric_query_chunk_size = chunk_size

            def __init__(self) -> None:
                self.query_batch_sizes: list[int] = []

            def bellmanford(self, graph: Any, source: Any, relation: Any) -> dict[str, Any]:
                self.query_batch_sizes.append(source.numel())
                node = torch.arange(graph.num_node, dtype=torch.int64).view(-1, 1)
                value = node * 100 + source.view(1, -1) * 10 + relation.view(1, -1)
                return {"node_feature": value.unsqueeze(-1)}

        model = FakeModel()
        model.negative_sample_to_tail = self.model_class.negative_sample_to_tail.__get__(model)
        model.symmetric_inverse_feature = self.model_class.symmetric_inverse_feature.__get__(model)
        return model

    def _scalar_reference(self, model: Any, h_index: Any, t_index: Any, r_index: Any) -> Any:
        torch = self.torch
        values = []
        for head, tail, relation in zip(
            h_index.reshape(-1), t_index.reshape(-1), r_index.reshape(-1)
        ):
            inverse_relation = (relation + model.num_relation) % (model.num_relation * 2)
            values.append(head * 100 + tail * 10 + inverse_relation)
        return torch.stack(values).view(*h_index.shape, 1)

    def _check_case(self, h_index: Any, t_index: Any, r_index: Any) -> None:
        model = self._fake_model(chunk_size=2)
        h_index, t_index, r_index = model.negative_sample_to_tail(h_index, t_index, r_index)
        actual = model.symmetric_inverse_feature(_Graph(), h_index, t_index, r_index)
        expected = self._scalar_reference(model, h_index, t_index, r_index)
        self.torch.testing.assert_close(actual, expected, rtol=0, atol=0)
        self.assertLessEqual(max(model.query_batch_sizes), model.symmetric_query_chunk_size)
        self.assertEqual(sum(model.query_batch_sizes), h_index.numel())

    def test_positive_pair_matches_scalar_inverse(self) -> None:
        torch = self.torch
        self._check_case(torch.tensor([[1]]), torch.tensor([[2]]), torch.tensor([[0]]))

    def test_tail_negative_candidates_match_scalar_inverse(self) -> None:
        torch = self.torch
        self._check_case(
            torch.tensor([[1, 1, 1]]),
            torch.tensor([[2, 4, 5]]),
            torch.tensor([[0, 0, 0]]),
        )

    def test_head_negative_candidates_match_scalar_inverse(self) -> None:
        torch = self.torch
        self._check_case(
            torch.tensor([[1, 4, 5]]),
            torch.tensor([[2, 2, 2]]),
            torch.tensor([[0, 0, 0]]),
        )

    def test_invalid_chunk_size_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "positive integer"):
            self.model_class(
                input_dim=2,
                hidden_dims=[2],
                num_relation=3,
                symmetric_query_chunk_size=0,
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("upstream", type=Path)
    args = parser.parse_args()
    SymmetricCandidateTests.upstream = args.upstream
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(SymmetricCandidateTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
