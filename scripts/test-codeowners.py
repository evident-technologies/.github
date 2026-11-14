#!/usr/bin/env python3
"""Reject invalid CODEOWNER routing without changing protection settings."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("public_source", ROOT / "scripts/verify-public-source.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class Codeowners(unittest.TestCase):
    def test_approved_owner(self):
        self.assertEqual([], module.codeowners_errors((ROOT / ".github/CODEOWNERS").read_text()))

    def test_historical_ineligible_owner_rejected(self):
        self.assertTrue(module.codeowners_errors("* @xTx396\n"))

    def test_empty_routing_rejected(self):
        self.assertTrue(module.codeowners_errors("# comments only\n"))

    def test_unverified_owner_rejected(self):
        self.assertTrue(module.codeowners_errors("* @unverified-owner\n"))

    def test_later_override_rejected(self):
        self.assertTrue(module.codeowners_errors("* @devontyler\nscripts/* @unverified-owner\n"))

    def test_original_baseline_and_protection_retained(self):
        inventory = json.loads((ROOT / "docs/source-inventory.json").read_text())
        row = next(r for r in inventory["files"] if r["path"] == ".github/CODEOWNERS")
        self.assertTrue(row["preserve_bytes"])
        self.assertNotEqual(row["sha256"], row["approved_revision_sha256"])
        self.assertEqual(module.APPROVED_CODEOWNERS_SHA256, row["approved_revision_sha256"])


if __name__ == "__main__":
    unittest.main()
