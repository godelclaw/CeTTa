#!/usr/bin/env python3
"""Unit tests for the frozen incomplete-context FCA comparator."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from run_incomplete_context_baseline import (
    EXPECTED_MAPPINGS,
    LOWER_ID,
    UPPER_ID,
    complete_rows,
    midpoint_cell_scores,
)


class IncompleteContextBaselineTests(unittest.TestCase):
    def test_lower_and_upper_preserve_known_and_bound_unknown(self) -> None:
        source = ("10u.",)
        lower = complete_rows(source, EXPECTED_MAPPINGS[LOWER_ID])
        upper = complete_rows(source, EXPECTED_MAPPINGS[UPPER_ID])
        self.assertEqual(lower, ("1000",))
        self.assertEqual(upper, ("1011",))

    def test_unsupported_status_fails_closed(self) -> None:
        with self.assertRaisesRegex(ValueError, "unsupported observation status"):
            complete_rows(("1x",), EXPECTED_MAPPINGS[LOWER_ID])

    def test_midpoint_scores_known_and_unknown_cells(self) -> None:
        scores = midpoint_cell_scores(("1000",), ("1011",), ("1010",))
        self.assertAlmostEqual(float(scores["brier"]), 0.125)
        self.assertAlmostEqual(float(scores["ece"]), 0.0)
        self.assertAlmostEqual(float(scores["interval_coverage"]), 1.0)
        self.assertAlmostEqual(float(scores["mean_width"]), 0.5)

    def test_observed_error_is_not_hidden_by_completion(self) -> None:
        scores = midpoint_cell_scores(("0",), ("0",), ("1",))
        self.assertAlmostEqual(float(scores["brier"]), 1.0)
        self.assertAlmostEqual(float(scores["interval_coverage"]), 0.0)
        self.assertAlmostEqual(float(scores["mean_width"]), 0.0)


if __name__ == "__main__":
    unittest.main()
