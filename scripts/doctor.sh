#!/usr/bin/env bash
set -euo pipefail

echo "doctor_version=1"

# Tool versions
git_version=$(git --version 2>/dev/null | cut -d' ' -f3 || echo missing)
gh_version=$(gh --version 2>/dev/null | head -n 1 | cut -d' ' -f3 || echo missing)
node_version=$(node -v 2>/dev/null || echo missing)

echo "git=$git_version"
echo "gh=$gh_version"
echo "node=$node_version"

# Git status
if [ "$git_version" = "missing" ]; then
  git_status=unavailable
elif GIT_STATUS=$(git status --porcelain 2>/dev/null); then
  if [ -z "$GIT_STATUS" ]; then
    git_status=clean
  else
    git_status=dirty
  fi
else
  git_status=unavailable
fi
echo "git_status=$git_status"

# Org meta-repo specific checks
if [ -f "versions.json" ]; then
  versions_json=present
else
  versions_json=missing
fi
echo "versions_json=$versions_json"

if [ -d ".github/workflows/templates" ]; then
  TEMPLATE_COUNT=$(find .github/workflows/templates -maxdepth 1 -type f -name '*.yml' | wc -l)
  echo "workflow_templates=$TEMPLATE_COUNT"
else
  echo "workflow_templates=0"
fi

if [ -f ".github/workflows/governance-drift.yml" ]; then
  drift_detection=active
else
  drift_detection=missing
fi
echo "drift_detection=$drift_detection"

# This is a meta-repo — no workspace_status or build gate
echo "repo_posture=org-governance"

# Exit code
if [ "$git_version" != "missing" ] &&
  [ "$gh_version" != "missing" ] &&
  [ "$node_version" != "missing" ] &&
  [ "$git_status" = "clean" ] &&
  [ "$versions_json" = "present" ] &&
  [ "$drift_detection" = "active" ]; then
  exit 0
else
  exit 1
fi