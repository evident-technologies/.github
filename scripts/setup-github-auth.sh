#!/usr/bin/env bash
# setup-github-auth.sh — Fix GitHub CLI auth and SSH key setup
#
# Common mistake: gh auth login → "Other" → typing machine hostname.
# This script guides through the CORRECT flow: github.com + SSH + web browser.
#
# Idempotent: skips steps that are already done.
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
warn() { echo -e "${R}  !${N}  $*"; }
head() { echo -e "\n${C}$*${N}"; }
die()  { echo -e "${R}FATAL:${N} $*" >&2; exit 1; }

echo
echo "╔══════════════════════════════════════╗"
echo "║  GitHub Auth + SSH Setup             ║"
echo "╚══════════════════════════════════════╝"

# ── Prereqs ────────────────────────────────────────────────────────────────────
command -v gh  >/dev/null || die "gh not installed — sudo dnf install gh"
command -v git >/dev/null || die "git not installed — sudo dnf install git"
command -v ssh >/dev/null || die "openssh not found — sudo dnf install openssh"

# ── 1. SSH key ─────────────────────────────────────────────────────────────────
head "1/4  SSH key"

SSH_DIR="${HOME}/.ssh"
SSH_KEY="${SSH_DIR}/id_ed25519"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ ! -f "$SSH_KEY" ]; then
  info "Generating ed25519 SSH key..."
  read -rp "  Your GitHub email: " KEY_EMAIL
  ssh-keygen -t ed25519 -C "$KEY_EMAIL" -f "$SSH_KEY"
  ok "Key generated: ${SSH_KEY}.pub"
else
  ok "Key already exists: $SSH_KEY"
fi

# Ensure ssh-agent has the key
if ! ssh-add -l 2>/dev/null | grep -q "$SSH_KEY"; then
  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$SSH_KEY" 2>/dev/null || true
fi

# ── 2. ~/.ssh/config ───────────────────────────────────────────────────────────
head "2/4  SSH client config"

SSH_CONFIG="${SSH_DIR}/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" << 'EOF'

# ── GitHub ──────────────────────────────────────────────────────────────────────
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  IdentitiesOnly yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
EOF
  ok "~/.ssh/config: github.com block added"
else
  ok "~/.ssh/config: github.com already configured"
fi

# ── 3. gh CLI auth ─────────────────────────────────────────────────────────────
head "3/4  GitHub CLI auth"

if gh auth status --hostname github.com &>/dev/null; then
  ok "gh already authenticated to github.com"
  gh auth status
else
  echo
  warn "You will be prompted. Answer EXACTLY:"
  echo "  Where do you use GitHub?  →  GitHub.com          (NOT Other)"
  echo "  Protocol?                 →  SSH"
  echo "  Upload SSH key?           →  yes → id_ed25519.pub"
  echo "  Authenticate?             →  Login with a web browser"
  echo
  read -rp "  Press Enter to start..."
  echo

  gh auth login \
    --hostname github.com \
    --git-protocol ssh \
    --web

  ok "gh auth done"
fi

# ── 4. Verify ──────────────────────────────────────────────────────────────────
head "4/4  Verification"

info "Testing SSH to GitHub..."
SSH_OUT=$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
SSH_USER=$(echo "$SSH_OUT" | grep -oP 'Hi \K[^!]+' || echo "")
if echo "$SSH_OUT" | grep -q "successfully authenticated"; then
  ok "SSH key authenticates as: @${SSH_USER}"
else
  warn "SSH test returned: $SSH_OUT"
fi

info "Testing gh API..."
GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
[ -n "$GH_USER" ] && ok "gh token authenticates as: @${GH_USER}" \
  || warn "gh API test failed — check: gh auth status"

# ── Account-consistency check ──────────────────────────────────────────────────
# If the SSH key and the gh token belong to DIFFERENT GitHub accounts, cloning
# over SSH (as the key's account) can fail with "Repository not found" for repos
# only the token's account can see. Use whichever account can actually list the
# org's repos. The gh token is the source of truth, so route git through gh's
# HTTPS credential helper to keep listing and cloning on the SAME account.
if [ -n "$SSH_USER" ] && [ -n "$GH_USER" ] && [ "$SSH_USER" != "$GH_USER" ]; then
  warn "Account mismatch: SSH key=@${SSH_USER}, gh token=@${GH_USER}"
  warn "Routing git through gh (HTTPS) so clones use @${GH_USER} consistently."
  git config --global --unset-all url."git@github.com:".insteadOf 2>/dev/null || true
  gh auth setup-git
  ok "git: using gh credential helper (HTTPS as @${GH_USER})"
else
  info "Configuring git to use SSH for GitHub..."
  git config --global url."git@github.com:".insteadOf "https://github.com/"
  ok "git: SSH override set (single account @${GH_USER:-$SSH_USER})"
fi

info "Setting git identity (if not already set)..."
git config --global user.name  2>/dev/null | grep -q . \
  || { read -rp "  Full name for git commits: " GIT_NAME; git config --global user.name "$GIT_NAME"; }
git config --global user.email 2>/dev/null | grep -q . \
  || { read -rp "  Email for git commits:     " GIT_EMAIL; git config --global user.email "$GIT_EMAIL"; }
ok "git identity: $(git config --global user.name) <$(git config --global user.email)>"

echo
echo "╔══════════════════════════════════════╗"
echo "║  Auth complete.                      ║"
echo "║  Run: ~/workspace/bin/ws-sync.sh     ║"
echo "╚══════════════════════════════════════╝"
echo
