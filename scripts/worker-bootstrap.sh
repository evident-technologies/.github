#!/usr/bin/env bash
# worker-bootstrap.sh — one-shot: fetch this repo and provision the worker.
# Run via:  curl -fsSL <raw-url>/scripts/worker-bootstrap.sh | bash
set -euo pipefail
cd "$HOME"
if [ -d .github/.git ]; then
  git -C .github pull -q --ff-only || true
else
  git clone -q https://github.com/evident-technologies/.github.git
fi
exec bash .github/scripts/setup-worker-node.sh
