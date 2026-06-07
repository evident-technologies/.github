#!/usr/bin/env bash
# setup-workstation.sh — Evident Technologies founder workstation bootstrap
# Creates ~/evident/ doc structure, ~/workspace/ git structure, shell config,
# and GNOME Files bookmarks. Idempotent: safe to re-run.
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
head() { echo -e "\n${C}$*${N}"; }

EVIDENT="${HOME}/evident"
WORKSPACE="${HOME}/workspace"

echo
echo "╔══════════════════════════════════════╗"
echo "║  Evident Workstation Setup           ║"
echo "╚══════════════════════════════════════╝"

# ── Workspace (git repos only) ─────────────────────────────────────────────────
head "1/5  Workspace structure"
mkdir -p \
  "${WORKSPACE}/.mirrors" \
  "${WORKSPACE}/bin"
ok "~/workspace ready"

# ── Evident (documents, ops, legal) ───────────────────────────────────────────
head "2/5  Evident directory tree"
mkdir -p \
  "${EVIDENT}/company/brand" \
  "${EVIDENT}/company/comms" \
  "${EVIDENT}/company/strategy" \
  "${EVIDENT}/company/_ref" \
  "${EVIDENT}/products/_shared" \
  "${EVIDENT}/products/evident-icu/specs" \
  "${EVIDENT}/products/evident-icu/design" \
  "${EVIDENT}/products/evident-icu/docs" \
  "${EVIDENT}/products/evident-icu/research" \
  "${EVIDENT}/ops/_shared" \
  "${EVIDENT}/ops/engineering" \
  "${EVIDENT}/ops/finance" \
  "${EVIDENT}/ops/security" \
  "${EVIDENT}/ops/infra" \
  "${EVIDENT}/legal/contracts/vendor-agreements" \
  "${EVIDENT}/legal/contracts/customer-agreements" \
  "${EVIDENT}/legal/contracts/employment" \
  "${EVIDENT}/legal/compliance" \
  "${EVIDENT}/legal/ip" \
  "${EVIDENT}/legal/finance" \
  "${EVIDENT}/people/hiring" \
  "${EVIDENT}/people/onboarding" \
  "${EVIDENT}/people/handbook" \
  "${EVIDENT}/people/performance" \
  "${EVIDENT}/clients/_shared" \
  "${EVIDENT}/_archive/2024" \
  "${EVIDENT}/_archive/2025" \
  "${EVIDENT}/_archive/2026" \
  "${EVIDENT}/_inbox"
ok "~/evident tree ready ($(find "${EVIDENT}" -type d | wc -l) dirs)"

# ── README stubs (prevent empty dirs from being invisible) ────────────────────
for dir in \
  "${EVIDENT}/company" \
  "${EVIDENT}/products/evident-icu" \
  "${EVIDENT}/legal" \
  "${EVIDENT}/ops" \
  "${EVIDENT}/people" \
  "${EVIDENT}/clients" \
  "${EVIDENT}/_inbox"; do
  readme="${dir}/README.md"
  [ -f "$readme" ] || printf '# %s\n' "$(basename "$dir")" > "$readme"
done
ok "README stubs created"

# ── GNOME Files (Nautilus) sidebar bookmarks ───────────────────────────────────
head "3/5  GNOME Files bookmarks"
BOOKMARKS="${HOME}/.config/gtk-3.0/bookmarks"
mkdir -p "$(dirname "$BOOKMARKS")"
touch "$BOOKMARKS"

bm() {
  local uri="file://${1}" label="${2}"
  grep -qF "$uri" "$BOOKMARKS" 2>/dev/null || echo "$uri $label" >> "$BOOKMARKS"
}

bm "${WORKSPACE}"                        "Workspace (git)"
bm "${EVIDENT}"                          "Evident"
bm "${EVIDENT}/products/evident-icu"     "ICU"
bm "${EVIDENT}/ops"                      "Ops"
bm "${EVIDENT}/legal"                    "Legal"
bm "${EVIDENT}/clients"                  "Clients"
bm "${EVIDENT}/_inbox"                   "Inbox"
ok "Bookmarks written — restart Nautilus or re-login to see them"

# ── Shell config block ─────────────────────────────────────────────────────────
head "4/5  Shell configuration"

BASHRC="${HOME}/.bashrc"
MARKER="# ── Evident Workstation"

if ! grep -qF "$MARKER" "$BASHRC" 2>/dev/null; then
  cat >> "$BASHRC" << 'BASHRC_EOF'

# ── Evident Workstation ────────────────────────────────────────────────────────
export WORKSPACE="$HOME/workspace"
export EVIDENT="$HOME/evident"
export PATH="$HOME/workspace/bin:$PATH"
export CDPATH=".:$WORKSPACE"

# Source workspace shortcuts (ws, repos, gpush) if available
[ -f "$WORKSPACE/bin/ws-shortcuts.sh" ] && source "$WORKSPACE/bin/ws-shortcuts.sh"

# Quick jumps
alias ev='cd "$EVIDENT"'
alias icu='cd "$EVIDENT/products/evident-icu"'
alias inbox='cd "$EVIDENT/_inbox"'
alias legal='cd "$EVIDENT/legal"'
alias platform='cd "$WORKSPACE/platform" 2>/dev/null || cd "$WORKSPACE"'

# Git
alias gs='git status --short'
alias gl='git log --oneline -12'
alias gd='git diff --stat'
alias gco='git checkout'
alias gb='git branch -a'

# Safety rails (confirm destructive ops)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Attach to or create the persistent 'evident' tmux session
alias cc='tmux new-session -A -s evident'
# ── End Evident Workstation ────────────────────────────────────────────────────
BASHRC_EOF
  ok "~/.bashrc updated"
else
  ok "~/.bashrc already configured, skipping"
fi

# ── tmux config for the command center ────────────────────────────────────────
head "5/5  tmux command-center config"

TMUX_CONF="${HOME}/.tmux.conf"
if ! grep -qF "evident" "$TMUX_CONF" 2>/dev/null; then
  cat >> "$TMUX_CONF" << 'TMUX_EOF'

# Evident command center
set -g mouse on
set -g history-limit 50000
set -g base-index 1
set -g pane-base-index 1
set -g status-interval 5
set -g status-left " #[bold]EVIDENT#[nobold] | #S "
set -g status-right " %Y-%m-%d %H:%M "
set -g status-style "bg=colour235,fg=colour250"
set -g window-status-current-style "bold,fg=colour220"

# Prefix: Ctrl-a (ergonomic for regular use)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded"

# Split panes with | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Navigate panes with vim keys
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
TMUX_EOF
  ok "~/.tmux.conf written"
else
  ok "~/.tmux.conf already has evident config, skipping"
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════╗"
echo "║  Done.                               ║"
echo "╠══════════════════════════════════════╣"
echo "║  source ~/.bashrc                    ║"
echo "║  cc          → command center tmux   ║"
echo "║  ev          → ~/evident             ║"
echo "║  ws-sync.sh  → clone all repos       ║"
echo "╚══════════════════════════════════════╝"
echo
