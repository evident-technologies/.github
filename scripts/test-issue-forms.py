#!/usr/bin/env python3
"""Synthetic regressions for public issue routing and privacy checks."""
import copy
import importlib.util
from pathlib import Path
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("public_source", ROOT / "scripts/verify-public-source.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PublicForms(unittest.TestCase):
    def load(self, name):
        return yaml.load((ROOT / ".github/ISSUE_TEMPLATE" / name).read_text(), Loader=yaml.BaseLoader)

    def test_valid_forms(self):
        for name in ("bug_report.yml", "feature_request.yml", "config.yml"):
            with self.subTest(name=name):
                self.assertEqual([], module.issue_form_errors(name, self.load(name)))

    def test_blank_issue_bypass_rejected(self):
        data = self.load("config.yml")
        data["blank_issues_enabled"] = "true"
        self.assertIn("blank issue bypass enabled", module.issue_form_errors("config.yml", data))

    def test_missing_private_route_rejected(self):
        data = self.load("config.yml")
        data["contact_links"] = []
        self.assertIn("private security routing missing", module.issue_form_errors("config.yml", data))

    def test_duplicate_id_rejected(self):
        data = self.load("bug_report.yml")
        data["body"].append(copy.deepcopy(next(row for row in data["body"] if row.get("id"))))
        self.assertIn("issue form IDs missing or duplicated", module.issue_form_errors("bug_report.yml", data))

    def test_optional_consent_rejected(self):
        data = self.load("bug_report.yml")
        for row in data["body"]:
            if row["type"] == "checkboxes":
                for option in row["attributes"]["options"]:
                    option["required"] = "false"
        self.assertIn("required public privacy consent missing", module.issue_form_errors("bug_report.yml", data))

    def test_missing_policy_route_rejected(self):
        data = self.load("feature_request.yml")
        data["body"] = [row for row in data["body"] if row["type"] != "markdown"]
        self.assertIn("organization policy routing missing", module.issue_form_errors("feature_request.yml", data))


if __name__ == "__main__":
    unittest.main()
