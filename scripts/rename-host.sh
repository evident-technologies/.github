#!/usr/bin/env bash
# rename-host.sh — give a machine ONE consistent name across every layer.
#
# There are three places a machine is named, and they drift apart over time:
#   1. System hostname   (what the shell prompt / `hostname` shows)
#   2. Tailscale name    (becomes the MagicDNS name: <name>.<tailnet>.ts.net)
#   3. SSH config alias  (what you type: `ssh matrix5`)
#
# This sets all three to the same value so there is never any confusion.
#
# Run ON the machine you are naming:
#   ./rename-host.sh MATRIX5      # on the mini PC (Fedora)
#   ./rename-host.sh ASPIRE       # on the laptop (Ubuntu)
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
warn() { echo -e "${R}  !${N}  $*"; }
die()  { echo -e "${R}FATAL:${N} $*" >&2; exit 1; }

NAME="${1:-}"
[ -n "$NAME" ] || die "usage: rename-host.sh <NAME>   e.g. rename-host.sh MATRIX5"

# Tailscale/MagicDNS names must be lowercase DNS labels. Keep a pretty display
# name for the system, a safe lowercase one for the network.
DISPLAY="$NAME"
DNS="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')"
[ -n "$DNS" ] || die "name has no usable DNS characters"

echo
echo "  Naming this machine:"
echo "    system hostname : ${DISPLAY}"
echo "    tailscale/DNS   : ${DNS}"
echo "    ssh alias       : ${DNS}"
echo

# ── 1. System hostname ──────────────────────────────────────────────────────────
if command -v hostnamectl >/dev/null; then
  sudo hostnamectl set-hostname "$DISPLAY"
  ok "system hostname → ${DISPLAY}"
else
  sudo hostname "$DISPLAY" 2>/dev/null || true
  warn "hostnamectl not found; set transient hostname only"
fi

# ── 2. Tailscale name ───────────────────────────────────────────────────────────
if command -v tailscale >/dev/null; then
  sudo tailscale set --hostname="$DNS"
  ok "tailscale name → ${DNS}  (MagicDNS: ${DNS}.<tailnet>.ts.net)"
else
  warn "tailscale not installed here — skipping network name"
fi

# ── 3. Local SSH alias for the OTHER machine ────────────────────────────────────
# With MagicDNS on, `ssh matrix5` / `ssh aspire` just work by tailnet name with
# no config at all. We still drop explicit aliases so connections work even if
# MagicDNS is off, using the stable Tailscale IPs you already have.
echo
info "MagicDNS tip: once enabled in the Tailscale admin console, you can simply"
info "  ssh ${DNS}        (no ~/.ssh/config entry needed, works from anywhere)"

echo
echo "  Reboot is NOT required, but open a fresh shell to see the new prompt."
echo "  Verify with:  hostname  &&  tailscale status"
echo
