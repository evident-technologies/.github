#!/usr/bin/env python3
"""Exact integration regression tests and optional branch-preserving combined check."""
import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("public_source", ROOT / "scripts/verify-public-source.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class Admission(unittest.TestCase):
    def setUp(self):
        self.actual = dict(m.APPROVED_PR27_FILES)
        self.record = {"head": m.APPROVED_PR27_SHA, "files": dict(self.actual)}
    def test_exact_combined(self):
        self.assertEqual([], m.integration_errors(self.actual, self.record))
    def test_baseline_only(self):
        actual = dict.fromkeys(self.actual)
        actual[".github/workflows/security-secret-scan.yml"] = m.BASELINE_SCANNER_SHA256
        self.assertEqual([], m.integration_errors(actual, self.record))
    def test_every_altered_file_rejected(self):
        for name in self.actual:
            with self.subTest(name=name):
                actual = dict(self.actual); actual[name] = "0" * 64
                self.assertTrue(m.integration_errors(actual, self.record))
    def test_every_missing_file_rejected(self):
        for name in self.actual:
            with self.subTest(name=name):
                actual = dict(self.actual); actual[name] = None
                self.assertTrue(m.integration_errors(actual, self.record))
    def test_unknown_addition_rejected(self):
        self.actual["unknown"] = "0" * 64
        self.assertTrue(m.integration_errors(self.actual, self.record))
    def test_approval_cannot_self_authorize(self):
        self.actual[next(iter(self.actual))] = "0" * 64
        self.record["files"] = self.actual
        self.assertTrue(m.integration_errors(self.actual, self.record))
    def test_wrong_revision_rejected(self):
        self.record["head"] = "0" * 40
        self.assertTrue(m.integration_errors(self.actual, self.record))
    def test_missing_record_rejected(self):
        self.assertTrue(m.integration_errors(self.actual, None))
    def test_unapproved_isolated_scanner_rejected(self):
        actual = dict.fromkeys(self.actual)
        actual[".github/workflows/security-secret-scan.yml"] = "0" * 64
        self.assertTrue(m.integration_errors(actual, self.record))
    def test_original_protection_retained(self):
        inv = json.loads((ROOT / "docs/source-inventory.json").read_text())
        row = next(x for x in inv["files"] if x["path"] == ".github/workflows/security-secret-scan.yml")
        self.assertTrue(row["preserve_bytes"])
        self.assertEqual(m.BASELINE_SCANNER_SHA256, row["sha256"])

def combined():
    def git(*args):
        return subprocess.check_output(["git", "-C", str(ROOT), *args])
    tree = git("merge-tree", "--write-tree", m.APPROVED_PR27_SHA, "HEAD").decode().strip()
    common = git("rev-parse", "--path-format=absolute", "--git-common-dir").decode().strip()
    with tempfile.TemporaryDirectory(prefix="approved-combined-") as td:
        tarfile.open(fileobj=io.BytesIO(git("archive", tree))).extractall(td, filter="data")
        for args in [["init", "-q"], ["add", "--all"], ["-c", "commit.gpgsign=false", "commit", "-qm", "Temporary integration qualification"]]:
            subprocess.run(["git", "-C", td, *args], check=True, capture_output=True)
        env = {**os.environ, "GIT_ALTERNATE_OBJECT_DIRECTORIES": common + "/objects"}
        for cmd in [["python3", "scripts/verify-public-source.py"], ["python3", "scripts/test-approved-integration.py"], ["python3", "scripts/test-codeowners.py"], ["python3", "scripts/test-issue-forms.py"], ["python3", "scripts/test-static-shell.py"], ["python3", "scripts/validate-runner-fabric.py"], ["node", "scripts/qualify-secret-scan.cjs"]]:
            subprocess.run(cmd, cwd=td, env=env, check=True, timeout=90)
    print("Exact combined tree qualification PASS: " + tree)

if __name__ == "__main__":
    if sys.argv[1:] == ["--combined"]:
        combined()
    else:
        unittest.main()
