#!/usr/bin/env python3
"""Workflow routing/security regressions and an offline synthetic npm build."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("public_source", ROOT / "scripts/verify-public-source.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class StaticShell(unittest.TestCase):
    def setUp(self):
        self.workflow = yaml.load((ROOT / ".github/workflows/static-shell.yml").read_text(),
                                  Loader=yaml.BaseLoader)
        self.callee = yaml.load((ROOT / ".github/workflows/static-site-ci.yml").read_text(),
                                Loader=yaml.BaseLoader)

    def test_actual_wrapper_is_valid(self):
        self.assertEqual([], module.static_shell_errors(self.workflow, self.callee))

    def test_old_nested_reference_rejected(self):
        data = copy.deepcopy(self.workflow)
        data["jobs"]["ci"]["uses"] = "./.github/workflows/templates/static-ci-app.yml"
        self.assertTrue(module.static_shell_errors(data, self.callee))

    def test_self_hosted_routing_rejected(self):
        data = copy.deepcopy(self.workflow)
        data["jobs"]["ci"].setdefault("with", {})["runs-on"] = '["self-hosted"]'
        self.assertIn("static-shell portable npm build contract changed",
                      module.static_shell_errors(data, self.callee))

    def test_token_write_rejected(self):
        data = copy.deepcopy(self.workflow)
        data["permissions"] = {"contents": "write"}
        self.assertIn("static-shell token must be read-only",
                      module.static_shell_errors(data, self.callee))

    def test_secret_inheritance_and_environment_rejected(self):
        for key, value in (("secrets", "inherit"), ("environment", "production")):
            data = copy.deepcopy(self.workflow)
            data["jobs"]["ci"][key] = value
            self.assertIn("static-shell must not pass secrets, environments, or extra execution",
                          module.static_shell_errors(data, self.callee))

    def test_new_required_callee_input_rejected(self):
        callee = copy.deepcopy(self.callee)
        callee["on"]["workflow_call"]["inputs"]["new-required"] = {"required": "true"}
        self.assertIn("static-shell omits required callee input",
                      module.static_shell_errors(self.workflow, callee))

    def synthetic_build(self, invalid=False):
        self.assertEqual([], module.static_shell_errors(self.workflow, self.callee))
        args = self.workflow["jobs"]["ci"]["with"]
        with tempfile.TemporaryDirectory(prefix="static-shell-") as temp:
            root = Path(temp)
            package = {"name": "static-shell-fixture", "version": "1.0.0", "private": True,
                       "scripts": {"lint": "node lint.cjs", "build": "node build.cjs"}}
            (root / "package.json").write_text(json.dumps(package))
            (root / "package-lock.json").write_text(json.dumps({"name": package["name"],
                "version": "1.0.0", "lockfileVersion": 3, "requires": True,
                "packages": {"": {"name": package["name"], "version": "1.0.0"}}}))
            (root / "source.txt").write_text("Synthetic static site")
            (root / "lint.cjs").write_text("const fs=require('node:fs');"
                "if(fs.readFileSync('source.txt','utf8')!=='Synthetic static site')process.exit(2);")
            (root / "build.cjs").write_text("const fs=require('node:fs');fs.mkdirSync('dist');"
                "fs.writeFileSync('dist/index.html',fs.readFileSync('source.txt','utf8'));")
            env = dict(os.environ, npm_config_offline="true", npm_config_audit="false",
                       npm_config_fund="false", npm_config_cache=str(root / "cache"))
            subprocess.run(args["install-command"], shell=True, cwd=root, env=env,
                           check=True, capture_output=True, timeout=20)
            if invalid:
                (root / "source.txt").write_text("Invalid source")
            lint = subprocess.run(args["lint-command"], shell=True, cwd=root, env=env,
                                  capture_output=True, timeout=20)
            if invalid:
                self.assertNotEqual(0, lint.returncode)
                self.assertFalse((root / args["output-path"]).exists())
                return
            self.assertEqual(0, lint.returncode, lint.stderr.decode())
            subprocess.run(args["build-command"], shell=True, cwd=root, env=env,
                           check=True, capture_output=True, timeout=20)
            self.assertEqual("Synthetic static site",
                             (root / args["output-path"] / "index.html").read_text())

    def test_synthetic_static_build(self):
        self.synthetic_build()

    def test_bad_source_fails_before_build(self):
        self.synthetic_build(invalid=True)


if __name__ == "__main__":
    unittest.main()
