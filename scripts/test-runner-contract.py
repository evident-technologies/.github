#!/usr/bin/env python3
"""Exercise actual qualification steps with current and adverse runner identities.

These synthetic checks do not attest provider assignment or runtime admission.
"""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("public_source", ROOT / "scripts/verify-public-source.py")
SOURCE_CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SOURCE_CHECK)
CI_RUNNERS = ("aspire-et-ci", "et-ws-02-et-ci")
DENIED_RUNNERS = (
    "aspire-physical-ci", "et-ws-02-fabric", "unknown-ci",
    "et-ws-02-deploy", "et-ws-02-org-deploy",
)


class RunnerContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = yaml.load(
            (ROOT / ".github/workflows/runner-contract.yml").read_text(),
            Loader=yaml.BaseLoader,
        )

    def run_step(self, job, identity, *, os_name="Linux", arch="X64", private="false"):
        script = self.workflow["jobs"][job]["steps"][0]["run"]
        return subprocess.run(
            ["bash", "--noprofile", "--norc", "-c", script],
            env={**os.environ, "RUNNER_NAME": identity, "RUNNER_OS": os_name,
                 "RUNNER_ARCH": arch, "PRIVATE_EVIDENCE": private},
            capture_output=True, text=True, timeout=5,
        )

    def test_shared_accepts_current_runtime_ci_identities(self):
        for identity in CI_RUNNERS:
            with self.subTest(identity=identity):
                result = self.run_step("shared", identity)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertIn(f"runner={identity}", result.stdout)

    def test_qualification_binds_each_exact_identity(self):
        for job, expected, other in (
            ("primary", CI_RUNNERS[0], CI_RUNNERS[1]),
            ("secondary", CI_RUNNERS[1], CI_RUNNERS[0]),
        ):
            with self.subTest(job=job):
                self.assertEqual(0, self.run_step(job, expected).returncode)
                self.assertNotEqual(0, self.run_step(job, other).returncode)

    def test_legacy_unknown_and_deploy_identities_are_rejected(self):
        for job in ("shared", "primary", "secondary"):
            for identity in DENIED_RUNNERS:
                with self.subTest(job=job, identity=identity):
                    self.assertNotEqual(0, self.run_step(job, identity).returncode)

    def test_wrong_operating_system_and_architecture_are_rejected(self):
        for job, identity in (("shared", CI_RUNNERS[0]),
                              ("primary", CI_RUNNERS[0]),
                              ("secondary", CI_RUNNERS[1])):
            with self.subTest(job=job):
                self.assertNotEqual(0, self.run_step(job, identity, os_name="Windows").returncode)
                self.assertNotEqual(0, self.run_step(job, identity, arch="ARM64").returncode)

    def test_shared_evidence_boundary_remains_closed(self):
        self.assertNotEqual(0, self.run_step("shared", CI_RUNNERS[0], private="true").returncode)

    def test_fixed_routing_and_read_only_permissions_are_preserved(self):
        self.assertEqual({"contents": "read"}, self.workflow["permissions"])
        selectors = ["self-hosted", "Linux", "X64", "evident-ci", "ci", "no-private-evidence"]
        for job, selector in (("portable", "ubuntu-24.04"), ("shared", selectors),
                              ("primary", selectors + ["ci-primary"]),
                              ("secondary", selectors + ["ci-secondary"])):
            data = self.workflow["jobs"][job]
            self.assertEqual(selector, data["runs-on"])
            for item in (data, *data["steps"]):
                self.assertNotIn("environment", item)
                self.assertNotIn("secrets", item)
                self.assertNotIn("continue-on-error", item)
        self.assertEqual("false", self.workflow["jobs"]["shared"]["steps"][0]["env"]["PRIVATE_EVIDENCE"])

    def test_exact_baseline_successor_and_original_fingerprint(self):
        original = subprocess.check_output(
            ["git", "-C", str(ROOT), "show", f"{SOURCE_CHECK.BASELINE}:.github/workflows/runner-contract.yml"]
        )
        actual = (ROOT / ".github/workflows/runner-contract.yml").read_bytes()
        self.assertEqual(SOURCE_CHECK.current_runner_contract(original), actual)
        inventory = json.loads((ROOT / "docs/source-inventory.json").read_text())
        row = next(row for row in inventory["files"] if row["path"] == ".github/workflows/runner-contract.yml")
        self.assertTrue(row["preserve_bytes"])
        self.assertEqual(hashlib.sha256(original).hexdigest(), row["sha256"])
        for altered in (actual + b"# unrelated edit\n",
                        actual.replace(b"contents: read", b"contents: write"),
                        actual.replace(b"aspire-et-ci", b"et-ws-02-org-deploy")):
            self.assertNotEqual(SOURCE_CHECK.current_runner_contract(original), altered)

    def test_unexpected_or_ambiguous_baseline_fails_closed(self):
        for original in (b"", b'          test "$RUNNER_NAME" = "aspire-physical-ci"\n' * 2):
            with self.assertRaises(ValueError):
                SOURCE_CHECK.current_runner_contract(original)

    def test_original_workflow_rejects_current_identity(self):
        original = subprocess.check_output(
            ["git", "-C", str(ROOT), "show", f"{SOURCE_CHECK.BASELINE}:.github/workflows/runner-contract.yml"]
        )
        prior = yaml.load(original, Loader=yaml.BaseLoader)
        for identity in CI_RUNNERS:
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c", prior["jobs"]["shared"]["steps"][0]["run"]],
                env={**os.environ, "RUNNER_NAME": identity, "RUNNER_OS": "Linux",
                     "RUNNER_ARCH": "X64", "PRIVATE_EVIDENCE": "false"},
                capture_output=True, text=True, timeout=5,
            )
            self.assertNotEqual(0, result.returncode)


if __name__ == "__main__":
    unittest.main()
