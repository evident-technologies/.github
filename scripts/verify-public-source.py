#!/usr/bin/env python3
"""Offline public-source checks; no network, provider access, or mutation.

This verifies bounded source contracts, not product availability, legal rights,
secret absence, GitHub rendering, or live runner authorization.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
from xml.etree import ElementTree as ET

BASELINE = "743fc9ca2136ed0187f2730d5a736ba7fd88bae9"
REVIEWED_ISSUE_FORMS = frozenset({
    ".github/ISSUE_TEMPLATE/bug_report.yml",
    ".github/ISSUE_TEMPLATE/feature_request.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
})
REVIEWED_WORKFLOWS = frozenset({".github/workflows/static-shell.yml"})
APPROVED_CODEOWNERS_SHA256 = '80f5d8a3fd949eee761d542aa895611830c5124dc7a3c9583a4a384f168ee179'
SVG_NS = "{http://www.w3.org/2000/svg}"


def codeowners_errors(text: str) -> list[str]:
    rules = [line.strip() for line in text.splitlines()
             if line.strip() and not line.lstrip().startswith("#")]
    return [] if rules == ["* @devontyler"] else ["approved CODEOWNER routing changed"]


def source_paths(root: Path) -> list[Path]:
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        check=True, capture_output=True,
    )
    return sorted({root / name.decode() for name in result.stdout.split(b"\0") if name})


def contrast(a: str, b: str) -> float:
    def luminance(color: str) -> float:
        channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
        return sum(v * weight for v, weight in zip(linear, (0.2126, 0.7152, 0.0722)))
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


class ImageReferences(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.references: list[str] = []
        self.errors: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = dict(attrs)
        if tag == "img" and "alt" not in attr:
            self.errors.append("image missing alt attribute")
        for key in ("src", "href", "srcset"):
            if attr.get(key):
                self.references.append(str(attr[key]))


def issue_form_errors(name: str, data: dict) -> list[str]:
    """Check public routing and privacy independently of file fingerprints."""
    errors: list[str] = []
    if name == "config.yml":
        if str(data.get("blank_issues_enabled")).lower() != "false":
            errors.append("blank issue bypass enabled")
        links = data.get("contact_links", [])
        security = "https://github.com/evident-technologies/.github/blob/main/SECURITY.md"
        if not isinstance(links, list) or not any(
            isinstance(row, dict) and row.get("url") == security for row in links
        ):
            errors.append("private security routing missing")
        return errors
    body = data.get("body", [])
    if not data.get("name") or not data.get("description") or not isinstance(body, list) or not body:
        return ["issue form identity or body missing"]
    fields = [row for row in body if isinstance(row, dict) and row.get("type") != "markdown"]
    ids = [row.get("id") for row in fields]
    if not ids or any(not isinstance(value, str) or not value for value in ids):
        errors.append("issue form IDs missing or duplicated")
    elif len(ids) != len(set(ids)):
        errors.append("issue form IDs missing or duplicated")
    consent = False
    routing = False
    allowed = {"markdown", "input", "textarea", "dropdown", "checkboxes", "upload"}
    for row in body:
        if not isinstance(row, dict) or row.get("type") not in allowed:
            errors.append("unsupported issue form element")
            continue
        attrs = row.get("attributes", {})
        if not isinstance(attrs, dict):
            errors.append("issue form attributes missing")
            continue
        if row["type"] != "markdown" and not attrs.get("label"):
            errors.append("issue form field label missing")
        if row["type"] == "checkboxes":
            options = attrs.get("options", [])
            if isinstance(options, list):
                consent |= any(isinstance(option, dict) and
                               str(option.get("required")).lower() == "true" and
                               any(word in str(option.get("label", "")).lower()
                                   for word in ("sensitive", "confidential"))
                               for option in options)
        if row["type"] == "markdown":
            routing |= ("https://github.com/evident-technologies/.github/blob/main/"
                        in str(attrs.get("value", "")))
    if not consent:
        errors.append("required public privacy consent missing")
    if not routing:
        errors.append("organization policy routing missing")
    return errors


def static_shell_errors(data: dict, callee: dict) -> list[str]:
    """Constrain the compatibility wrapper to portable, read-only static builds."""
    errors: list[str] = []
    if set(data.get("on", {})) != {"workflow_call"}:
        errors.append("static-shell must remain callable only")
    if data.get("permissions") != {"contents": "read"}:
        errors.append("static-shell token must be read-only")
    if set(data.get("jobs", {})) != {"ci"}:
        return errors + ["static-shell job contract changed"]
    job = data["jobs"]["ci"]
    if set(job) != {"uses", "with"}:
        errors.append("static-shell must not pass secrets, environments, or extra execution")
    if job.get("uses") != "./.github/workflows/static-site-ci.yml":
        errors.append("static-shell must call the supported top-level CI entry point")
    args = job.get("with", {})
    expected = {"node-version": "22", "package-manager": "npm", "install-command": "npm ci",
                "lint-command": "npm run lint", "build-command": "npm run build",
                "output-path": "dist", "runs-on": '["ubuntu-24.04"]'}
    if args != expected:
        errors.append("static-shell portable npm build contract changed")
    if callee.get("permissions") != {"contents": "read"}:
        errors.append("static-shell callee token boundary changed")
    declared = callee.get("on", {}).get("workflow_call", {}).get("inputs", {})
    if not set(args) <= set(declared):
        errors.append("static-shell passes unsupported callee inputs")
    for name, definition in declared.items():
        if str(definition.get("required")).lower() == "true" and name not in args:
            errors.append("static-shell omits required callee input")
    return errors


def verify(root: Path) -> tuple[list[str], list[str], dict[str, int]]:
    errors: list[str] = []
    warnings: list[str] = []
    paths = source_paths(root)
    counts = {"files": len(paths), "markdown": 0, "svg": 0, "png": 0, "json": 0, "yaml": 0}

    def fail(path: Path, message: str) -> None:
        errors.append(f"{path.relative_to(root)}: {message}")

    for path in paths:
        if not path.is_file():
            fail(path, "source file missing")
            continue
        suffix = path.suffix.lower()
        try:
            if suffix == ".md":
                counts["markdown"] += 1
                text = path.read_text()
                # Exclude fenced examples from link and heading checks.
                prose = re.sub(r"^```[^\n]*\n.*?^```\s*$", "", text, flags=re.M | re.S)
                levels = [len(m) for m in re.findall(r"^(#{1,6})\s", prose, re.M)]
                if not levels or levels[0] != 1 or levels.count(1) != 1:
                    fail(path, "expected one leading level-one heading")
                if any(b > a + 1 for a, b in zip(levels, levels[1:])):
                    fail(path, "skipped heading level")
                parser = ImageReferences()
                parser.feed(prose)
                for message in parser.errors:
                    fail(path, message)
                refs = re.findall(r"!?\[[^\]]*\]\(([^\s)]+)(?:\s+[^)]*)?\)", prose)
                for ref in refs + parser.references:
                    parsed = urlsplit(ref.strip("<>"))
                    if parsed.scheme or parsed.netloc or not parsed.path:
                        continue
                    target = (path.parent / unquote(parsed.path)).resolve()
                    if not target.is_relative_to(root) or not target.exists():
                        fail(path, "missing or out-of-repository relative destination")
                if re.search(r"!\[\s*\]\(", prose):
                    fail(path, "Markdown image lacks meaningful alternative text")
                if "cdn.jsdelivr.net" in prose:
                    fail(path, "obsolete CDN recommendation")
            elif suffix == ".json":
                counts["json"] += 1
                json.loads(path.read_text())
            elif suffix == ".svg":
                counts["svg"] += 1
                raw = path.read_text()
                if re.search(r"<!DOCTYPE|<!ENTITY", raw, re.I):
                    fail(path, "SVG entity or document type declaration")
                tree = ET.fromstring(raw)
                if tree.tag != SVG_NS + "svg" or "viewBox" not in tree.attrib:
                    fail(path, "SVG namespace or viewBox missing")
                for elem in tree.iter():
                    tag = elem.tag.split("}")[-1].lower()
                    if tag in {"script", "foreignobject", "image", "iframe", "animate", "set"}:
                        fail(path, "SVG active or embedded content")
                    for key, value in elem.attrib.items():
                        attr = key.split("}")[-1].lower()
                        if attr.startswith("on") or (attr == "href" and not value.startswith("#")):
                            fail(path, "SVG event or external reference")
                        if re.search(r"url\(\s*['\"]?(?!#)[^)]+\)", value, re.I):
                            fail(path, "SVG external resource")
                if "candidates" in path.parts:
                    if tree.get("role") != "img" or tree.find(SVG_NS + "title") is None or tree.find(SVG_NS + "desc") is None:
                        fail(path, "candidate SVG accessible name or description missing")
            elif suffix == ".png":
                counts["png"] += 1
                raw = path.read_bytes()
                if raw[:8] != b"\x89PNG\r\n\x1a\n" or len(raw) < 24:
                    fail(path, "invalid PNG signature")
                else:
                    width, height = struct.unpack(">II", raw[16:24])
                    if not width or not height:
                        fail(path, "invalid PNG dimensions")
            elif suffix in {".yml", ".yaml"}:
                counts["yaml"] += 1
                try:
                    import yaml
                except ImportError:
                    if "YAML parsing unavailable: install through the approved toolchain" not in warnings:
                        warnings.append("YAML parsing unavailable: install through the approved toolchain")
                else:
                    # BaseLoader preserves GitHub's 'on' key under YAML 1.1 parsers.
                    data = yaml.load(path.read_text(), Loader=yaml.BaseLoader)
                    if not isinstance(data, dict):
                        fail(path, "YAML mapping expected")
                    elif path.parent == root / ".github/workflows" and not {"on", "jobs"} <= data.keys():
                        fail(path, "top-level workflow needs on and jobs")
                    elif str(path.relative_to(root)) in REVIEWED_ISSUE_FORMS:
                        for message in issue_form_errors(path.name, data):
                            fail(path, message)
                    if str(path.relative_to(root)) in REVIEWED_WORKFLOWS:
                        callee = yaml.load((root / ".github/workflows/static-site-ci.yml").read_text(),
                                           Loader=yaml.BaseLoader)
                        for message in static_shell_errors(data, callee):
                            fail(path, message)
        except (ValueError, ET.ParseError, UnicodeError) as exc:
            fail(path, f"parse error ({type(exc).__name__})")

    audit_path = root / "docs/documentation-audit.json"
    audit = json.loads(audit_path.read_text())
    documents = audit["documents"]
    if {item["path"] for item in documents} != {
        str(path.relative_to(root)) for path in paths if path.suffix == ".md"
    }:
        fail(audit_path, "Markdown audit does not cover every public document")
    required = {"purpose", "intake_classification", "identified_issue", "proposed_treatment",
                "source_authority", "acceptance_criteria", "final_disposition"}
    for item in documents:
        if not all(item.get(key) for key in required):
            fail(audit_path, "incomplete purpose, authority, treatment, or acceptance record")
        if any(source not in audit["sources"] for source in item.get("source_authority", [])):
            fail(audit_path, "unknown source authority identifier")
    for name in ("README.md", "profile/README.md"):
        if "Clear systems. Accountable technology." not in (root / name).read_text():
            fail(root / name, "owner-selected public positioning missing")

    candidates = root / "brand/candidates"
    manifest = json.loads((candidates / "manifest.json").read_text())
    if manifest.get("status") != "PROPOSED_UNAPPROVED" or manifest.get("approval") is not None:
        fail(candidates / "manifest.json", "candidate approval contract changed")
    listed = {item["path"] for item in manifest["assets"]}
    expected = {p.name for p in candidates.iterdir() if p.suffix in {".svg", ".json"} and p.name != "manifest.json"}
    if listed != expected:
        fail(candidates / "manifest.json", "candidate inventory does not match source")
    for item in manifest["assets"]:
        path = candidates / item["path"]
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            fail(candidates / "manifest.json", "candidate fingerprint mismatch")
    tokens = json.loads((candidates / "tokens.json").read_text())
    for pair in tokens["pairs"]:
        ratio = contrast(tokens["palette"][pair["foreground"]], tokens["palette"][pair["background"]])
        if ratio < pair["minimum"]:
            fail(candidates / "tokens.json", "declared contrast pair fails minimum")

    brand = json.loads((root / "brand/manifest.json").read_text())
    for name in list(brand["assets"].values()) + [brand["tokens"], brand["css"], brand["candidates"]]:
        if not (root / "brand" / name).is_file():
            fail(root / "brand/manifest.json", "missing asset destination")
    source = json.loads((root / "brand/source-inventory.json").read_text())
    for item in source["assets"]:
        path = root / item["path"]
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            fail(path, "preserved brand source changed or missing")

    inventory = json.loads((root / "docs/source-inventory.json").read_text())
    if inventory.get("baseline") != BASELINE:
        fail(root / "docs/source-inventory.json", "baseline identity drift")
    baseline_paths = set(subprocess.run(
        ["git", "-C", str(root), "ls-tree", "-r", "--name-only", BASELINE],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines())
    if {item["path"] for item in inventory["files"]} != baseline_paths:
        fail(root / "docs/source-inventory.json", "baseline inventory is incomplete")
    for item in inventory["files"]:
        name = item["path"]
        original = subprocess.run(
            ["git", "-C", str(root), "show", f"{BASELINE}:{name}"],
            check=True, capture_output=True,
        ).stdout
        original_hash = hashlib.sha256(original).hexdigest()
        if item["sha256"] != original_hash:
            fail(root / "docs/source-inventory.json", "baseline fingerprint does not match Git source")
        protected = (
            (name.startswith((".github/workflows/", "governance/", ".github/ISSUE_TEMPLATE/"))
             and name not in REVIEWED_ISSUE_FORMS and name not in REVIEWED_WORKFLOWS)
            or Path(name).suffix in {".svg", ".png"}
            or name in {".github/CODEOWNERS", ".github/dependabot.yml", "action-pins.json",
                        "scripts/ship.sh", "scripts/validate-runner-fabric.py", "brand/package.json"}
        )
        if item["preserve_bytes"] != protected:
            fail(root / "docs/source-inventory.json", "protected-source classification changed")
        if protected:
            path = root / name
            actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
            expected_hash = APPROVED_CODEOWNERS_SHA256 if name == ".github/CODEOWNERS" else original_hash
            if actual != expected_hash:
                fail(path, "protected baseline source changed")
            if name == ".github/CODEOWNERS":
                if item.get("approved_revision_sha256") != APPROVED_CODEOWNERS_SHA256:
                    fail(path, "approved CODEOWNERS revision record changed")
                for message in codeowners_errors(path.read_text()):
                    fail(path, message)
    # CSS compatibility is a separate contract from repaired syntax/comments.
    css_path = root / "brand/brand.css"
    css = css_path.read_text()
    old = subprocess.run(["git", "-C", str(root), "show", f"{BASELINE}:brand/brand.css"], check=True, capture_output=True, text=True).stdout
    declarations = lambda text: dict(re.findall(r"(--et-[\w-]+)\s*:\s*([^;]+);", text))
    if declarations(css) != declarations(old):
        fail(css_path, "existing CSS variable names or values changed")
    if css.count("/*") != css.count("*/") or css.count("{") != css.count("}"):
        fail(css_path, "unbalanced CSS comments or blocks")
    changes_path = root / "docs/change-manifest.json"
    changes = json.loads(changes_path.read_text())
    changed = set(subprocess.run(
        ["git", "-C", str(root), "diff", "--name-only", BASELINE],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines())
    changed.update(subprocess.run(
        ["git", "-C", str(root), "ls-files", "--others", "--exclude-standard"],
        check=True, capture_output=True, text=True,
    ).stdout.splitlines())
    if {item["path"] for item in changes["files"]} != changed:
        fail(changes_path, "changed-file manifest does not match Git scope")
    for item in changes["files"]:
        if item["path"] == "docs/change-manifest.json":
            continue  # A manifest cannot contain its own digest; Git binds it.
        path = root / item["path"]
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item["sha256"]:
            fail(changes_path, "changed-file fingerprint mismatch")
    return errors, warnings, counts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    errors, warnings, counts = verify(args.root.resolve())
    for message in errors:
        print("FAIL:", message)
    for message in warnings:
        print("UNVERIFIED:", message)
    print(json.dumps(counts, sort_keys=True))
    print(f"public-source-verification: {'FAIL' if errors else 'PASS'}; warnings={len(warnings)}")
    return 1 if errors else 2 if warnings else 0


if __name__ == "__main__":
    sys.exit(main())
