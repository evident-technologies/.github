#!/usr/bin/env python3
"""Exercise the actual reusable-workflow guards with synthetic adverse inputs."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/polyglot-ci.yml"


class PolyglotContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.wf = yaml.load(WORKFLOW.read_text(), Loader=yaml.BaseLoader)
        cls.job = cls.wf["jobs"]["verify"]
        cls.steps = {step["name"]: step for step in cls.job["steps"]}

    def env(self, **changes):
        values = {
            "INPUT_PLATFORM": "linux", "INPUT_NODE": "24.22.3",
            "INPUT_NPM": "11.9.0", "INPUT_PYTHON": "", "INPUT_DOTNET": "",
            "INPUT_GO": "", "INPUT_RUST": "", "INPUT_WORKDIR": ".",
            "INPUT_ARTIFACT": "artifacts/ci", "INPUT_ARTIFACT_NAME": "runtime",
            "INPUT_VERIFY": "node --version",
        }
        values.update(changes)
        return {**os.environ, **values}

    def guard(self, root, **changes):
        return subprocess.run(
            ["bash", "--noprofile", "--norc", "-c",
             self.steps["Validate bounded inputs"]["run"]],
            cwd=root, env=self.env(**changes), capture_output=True, text=True, timeout=5,
        )

    def reports(self, root, path="artifacts/ci"):
        return subprocess.run(
            ["bash", "--noprofile", "--norc", "-c",
             self.steps["Validate explicit report directory"]["run"]],
            cwd=root, env={**os.environ, "REPORT_DIRECTORY": path},
            capture_output=True, text=True, timeout=5,
        )

    def test_only_callable_read_only_mechanism(self):
        self.assertEqual({"workflow_call"}, set(self.wf["on"]))
        self.assertEqual({"contents": "read"}, self.wf["permissions"])
        self.assertNotIn("secrets", self.wf["on"]["workflow_call"])
        self.assertEqual({"verify"}, set(self.wf["jobs"]))
        for item in [self.job, *self.job["steps"]]:
            self.assertNotIn("environment", item)
            self.assertNotIn("secrets", item)
            self.assertNotIn("continue-on-error", item)

    def test_runner_allocation_has_no_arbitrary_label_input(self):
        self.assertEqual(
            "${{ inputs.platform == 'windows' && 'windows-2025' || "
            "inputs.platform == 'macos' && 'macos-15' || 'ubuntu-24.04' }}",
            self.job["runs-on"],
        )
        self.assertNotIn("runs-on", self.wf["on"]["workflow_call"]["inputs"])

    def test_actions_are_verified_immutable_references(self):
        expected = {
            "actions/checkout": "3d3c42e5aac5ba805825da76410c181273ba90b1",
            "actions/setup-node": "949feb2413d6458794dcd2491c4babbbce0c15c1",
            "actions/setup-python": "6d4fd22b20465ccc0f7354476588e8df7c9ca0e0",
            "actions/setup-dotnet": "0f4a354dd5547a28c70b7853dbd95d5b67886e73",
            "actions/setup-go": "d8cbb8045d7f43706b9177cceb36c1f91a6644d5",
            "actions/upload-artifact": "cf430e030ddbb5b0abf93d22962f4752f3646cd9",
        }
        actual = {}
        for step in self.job["steps"]:
            if "uses" in step:
                owner, sha = step["uses"].split("@")
                self.assertRegex(sha, r"^[0-9a-f]{40}$")
                actual[owner] = sha
        self.assertEqual(expected, actual)
        checkout = self.steps["Checkout exact event source"]["with"]
        self.assertEqual("false", checkout["persist-credentials"])
        self.assertEqual("false", checkout["allow-unsafe-pr-checkout"])
        self.assertNotIn("ref", checkout)

    def test_toolchains_are_opt_in_and_caches_are_explicit(self):
        for name, key in [
            ("Setup Node.js", "node-version"), ("Select exact npm", "npm-version"),
            ("Setup Python", "python-version"), ("Setup .NET SDK", "dotnet-version"),
            ("Setup Go", "go-version"), ("Setup Rust components", "rust-toolchain"),
        ]:
            self.assertEqual(f"inputs.{key} != ''", self.steps[name]["if"])
            self.assertEqual("", self.wf["on"]["workflow_call"]["inputs"][key]["default"])
        self.assertEqual("false", self.steps["Setup Node.js"]["with"]["package-manager-cache"])
        self.assertEqual("false", self.steps["Setup Go"]["with"]["cache"])
        self.assertEqual("true", self.steps["Setup .NET SDK"]["with"]["skip-lts-prepass"])
        self.assertEqual("false", self.steps["Setup Python"]["with"]["allow-prereleases"])

    def test_exact_supported_input_shapes(self):
        with tempfile.TemporaryDirectory() as temp:
            for platform in ("linux", "windows", "macos"):
                self.assertEqual(0, self.guard(temp, INPUT_PLATFORM=platform).returncode)
            self.assertEqual(0, self.guard(temp, INPUT_NODE="", INPUT_NPM="").returncode)
            self.assertEqual(0, self.guard(temp, INPUT_RUST="1.92.1", INPUT_GO="1.27.0",
                                          INPUT_PYTHON="3.14.0", INPUT_DOTNET="10.0.100").returncode)

    def test_versions_are_data_and_no_shell_injection_runs(self):
        with tempfile.TemporaryDirectory() as temp:
            canary = Path(temp) / "INJECTION_EXECUTED"
            for value in ("lts/*", "24", "24.x", "24.22.3-rc.1", "24.22.3;touch INJECTION_EXECUTED",
                          "$(touch INJECTION_EXECUTED)", "24.22.3\n"):
                self.assertNotEqual(0, self.guard(temp, INPUT_NODE=value).returncode)
                self.assertFalse(canary.exists())
            self.assertNotEqual(0, self.guard(temp, INPUT_NODE="", INPUT_NPM="11.9.0").returncode)

    def test_unknown_runner_classes_and_empty_commands_are_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            for value in ("self-hosted", "ci-primary", '["ubuntu-24.04"]', "linux\n"):
                self.assertNotEqual(0, self.guard(temp, INPUT_PLATFORM=value).returncode)
            for value in ("", " ", "\n\t"):
                self.assertNotEqual(0, self.guard(temp, INPUT_VERIFY=value).returncode)

    def test_dotnet_selection_is_checked_from_product_directory(self):
        step = self.steps["Verify selected SDK and runtime versions"]
        self.assertEqual("${{ inputs.working-directory }}", step["working-directory"])
        self.assertIn('test "$(dotnet --version)" = "$EXPECTED_DOTNET"', step["run"])

    def test_working_directory_and_artifact_traversal(self):
        with tempfile.TemporaryDirectory() as temp:
            for value in ("../outside", "/tmp", "nested/../../outside", "a//b", "x;touch bad"):
                self.assertNotEqual(0, self.guard(temp, INPUT_WORKDIR=value).returncode)
            for value in (".", "**", "src", "/tmp", "artifacts/../src", "reports/./x", "artifacts//x"):
                self.assertNotEqual(0, self.guard(temp, INPUT_ARTIFACT=value).returncode)
            for value in ("", "x/y", "x\n", "a" * 65):
                self.assertNotEqual(0, self.guard(temp, INPUT_ARTIFACT_NAME=value).returncode)

    def test_symlink_escape_is_rejected_without_reading_destination(self):
        with tempfile.TemporaryDirectory() as temp, tempfile.TemporaryDirectory() as outside:
            (Path(temp) / "escape").symlink_to(outside, target_is_directory=True)
            self.assertNotEqual(0, self.guard(temp, INPUT_WORKDIR="escape").returncode)
            (Path(temp) / "artifacts").mkdir()
            (Path(temp) / "artifacts/ci").symlink_to(outside, target_is_directory=True)
            self.assertNotEqual(0, self.reports(temp).returncode)

    def test_report_guards_accept_bounded_files_and_reject_missing_or_links(self):
        with tempfile.TemporaryDirectory() as temp:
            self.assertNotEqual(0, self.reports(temp).returncode)
            directory = Path(temp) / "artifacts/ci"
            directory.mkdir(parents=True)
            self.assertNotEqual(0, self.reports(temp).returncode)
            (directory / "receipt.json").write_text('{"status":"FAIL"}\n')
            self.assertEqual(0, self.reports(temp).returncode)
            (directory / "link").symlink_to("receipt.json")
            self.assertNotEqual(0, self.reports(temp).returncode)

    def test_failed_verification_is_not_masked(self):
        step = self.steps["Product verification"]
        self.assertNotIn("${{", step["run"])
        self.assertNotIn("${{", self.steps["Locked product installation"]["run"])
        with tempfile.TemporaryDirectory() as temp:
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c", step["run"]],
                env={**os.environ, "EVIDENT_VERIFY_COMMAND": "exit 7",
                     "EVIDENT_RUST_TOOLCHAIN": ""}, cwd=temp, timeout=5,
                capture_output=True,
            )
            self.assertEqual(7, result.returncode)

    def test_failure_reports_and_source_identities_stay_distinct(self):
        reports = self.steps["Preserve product verification reports"]
        self.assertEqual("always() && steps.reports.outcome == 'success'", reports["if"])
        self.assertEqual("false", reports["with"]["include-hidden-files"])
        self.assertEqual("false", reports["with"]["overwrite"])
        self.assertEqual("7", reports["with"]["retention-days"])
        self.assertEqual("error", reports["with"]["if-no-files-found"])
        env = self.steps["Product verification"]["env"]
        self.assertEqual("${{ github.sha }}", env["EVIDENT_SOURCE_EVENT_SHA"])
        self.assertEqual("${{ steps.checkout.outputs.commit }}", env["EVIDENT_SOURCE_CHECKOUT_SHA"])
        self.assertEqual("${{ github.event.pull_request.head.sha }}", env["EVIDENT_PR_HEAD_SHA"])

    def test_every_bash_step_parses(self):
        for name, step in self.steps.items():
            if "run" in step:
                with self.subTest(step=name):
                    result = subprocess.run(["bash", "-n"], input=step["run"],
                                            text=True, capture_output=True, timeout=5)
                    self.assertEqual(0, result.returncode, result.stderr)


if __name__ == "__main__":
    unittest.main()

