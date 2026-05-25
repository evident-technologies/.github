#!/usr/bin/env bash
set -euo pipefail

echo "doctor_version=1"

# Tool versions
echo "git=$(git --version 2>/dev/null | cut -d' ' -f3 || echo missing)"
echo "gh=$(gh --version 2>/dev/null | head -n 1 | cut -d' ' -f3 || echo missing)"
echo "node=$(node -v 2>/dev/null || echo missing)"

# Git status
GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "not-a-repo")
if [ -z "$GIT_STATUS" ]; then
  echo "git_status=clean"
else
  echo "git_status=dirty"
fi

# Org meta-repo specific checks
if [ -f "versions.json" ]; then
  echo "versions_json=present"
else
  echo "versions_json=missing"
fi

if [ -d ".github/workflows/templates" ]; then
  TEMPLATE_COUNT=$(ls .github/workflows/templates/*.yml 2>/dev/null | wc -l)
  echo "workflow_templates=$TEMPLATE_COUNT"
else
  echo "workflow_templates=0"
fi

if [ -f ".github/workflows/governance-drift.yml" ]; then
  echo "drift_detection=active"
else
  echo "drift_detection=missing"
fi

# This is a meta-repo — no workspace_status or build gate
echo "repo_posture=org-governance"

# Exit code
if command -v git >/dev/null 2>&1; then
  exit 0
else
  exit 1
fi