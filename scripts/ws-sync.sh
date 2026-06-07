#!/usr/bin/env bash
# ws-sync.sh — surface every Evident repo locally, mirror-first, with shortcuts.
#
# For each repo in the org it keeps:
#   ~/workspace/.mirrors/<repo>.git   bare --mirror clone   (local backup / safety net)
#   ~/workspace/<repo>                working clone built FROM the local mirror
#   ~/workspace/<repo> remotes:       origin -> GitHub,  mirror -> local bare mirror
# and installs a pre-push safety hook (blocks >50MB files and secret-like paths).
#
# Usage:  ./ws-sync.sh           # sync all repos
#         ORG=other ./ws-sync.sh # different org
set -euo pipefail

ORG="${ORG:-evident-technologies}"
WS="${WS:-$HOME/workspace}"
MIRRORS="$WS/.mirrors"
HOOK_SRC="$(cd "$(dirname "$0")" && pwd)/pre-push"
mkdir -p "$WS" "$MIRRORS"

command -v gh >/dev/null || { echo "gh CLI required (https://cli.github.com)"; exit 1; }

echo "==> Listing repos in $ORG"
mapfile -t REPOS < <(gh repo list "$ORG" --no-archived --limit 200 --json name --jq '.[].name' | sort)
[ "${#REPOS[@]}" -gt 0 ] || { echo "No repos found (is gh authed? run: gh auth login)"; exit 1; }

for r in "${REPOS[@]}"; do
  url="https://github.com/$ORG/$r.git"
  mirror="$MIRRORS/$r.git"
  work="$WS/$r"

  # 1) local bare mirror first (fast, offline, restorable backup)
  if [ -d "$mirror" ]; then
    git -C "$mirror" remote update --prune >/dev/null
  else
    echo "  mirror  $r"
    git clone --quiet --mirror "$url" "$mirror"
  fi

  # 2) working clone built from the local mirror, but pushing to GitHub
  if [ -d "$work/.git" ]; then
    git -C "$work" fetch --quiet --all --prune || true
  else
    echo "  clone   $r"
    git clone --quiet "$mirror" "$work"
    git -C "$work" remote set-url origin "$url"
    git -C "$work" remote add mirror "$mirror" 2>/dev/null || true
  fi

  # 3) install the safety hook
  if [ -f "$HOOK_SRC" ]; then
    install -m 0755 "$HOOK_SRC" "$work/.git/hooks/pre-push"
  fi
  echo "  ✓ $r"
done

echo
echo "Done. ${#REPOS[@]} repos under $WS"
echo "Add the shortcuts:  source $(cd "$(dirname "$0")" && pwd)/ws-shortcuts.sh"
