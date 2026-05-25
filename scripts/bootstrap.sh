#!/usr/bin/env bash
set -euo pipefail

echo "=== .github Org Meta-Repo Bootstrap ==="

# This is a governance meta-repo, not a product workspace.
# Bootstrap validates org-level artifacts only.

command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh CLI is required for governance ops"; exit 1; }

echo "Git version: $(git --version | cut -d' ' -f3)"
echo "gh version: $(gh --version | head -n 1 | cut -d' ' -f3)"

# Validate workflow templates exist
if [ -d ".github/workflows/templates" ]; then
  TEMPLATE_COUNT=$(ls .github/workflows/templates/*.yml 2>/dev/null | wc -l)
  echo "Reusable workflow templates: $TEMPLATE_COUNT"
else
  echo "WARNING: No reusable workflow templates found"
fi

# Validate versions.json exists
if [ -f "versions.json" ]; then
  echo "Central versions.json: present"
else
  echo "WARNING: versions.json missing — version governance unavailable"
fi

echo "=== Bootstrap complete ==="