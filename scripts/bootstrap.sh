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
  nullglob_was_set=0
  if shopt -q nullglob; then
    nullglob_was_set=1
  else
    shopt -s nullglob
  fi

  template_files=(.github/workflows/templates/*.yml)
  TEMPLATE_COUNT=${#template_files[@]}

  if [ "$nullglob_was_set" -eq 0 ]; then
    shopt -u nullglob
  fi

  if [ "$TEMPLATE_COUNT" -gt 0 ]; then
    echo "Reusable workflow templates: $TEMPLATE_COUNT"
  else
    echo "WARNING: No reusable workflow templates found"
  fi
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