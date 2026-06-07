#!/usr/bin/env bash
# setup-ssh-remote.sh — Secure remote access to the founder workstation
#
# Approach: Tailscale (zero-trust mesh VPN) + hardened SSH + tmux command center.
#
# Why Tailscale over raw port-forwarding:
#   - No open ports on your router or firewall
#   - Works through NAT, hotel WiFi, cell data
#   - Auth is your GitHub/Google identity
#   - Each device is cryptographically identified
#   - Free for solo founders (up to 100 devices)
#
# What this script does:
#   1. Installs + starts Tailscale (you authenticate once via browser)
#   2. Hardens sshd (key-only, no password, no root, rate-limited)
#   3. Confirms your SSH public key is in authorized_keys
#   4. Creates a tmux command-center startup script (cc-start)
#   5. Writes a ~/.ssh/config block for connecting back FROM another machine
#   6. Prints your Tailscale IP for use in the SSH config
#
# Run as your normal user (sudo is used internally where needed).
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
warn() { echo -e "${R}  !${N}  $*"; }
head() { echo -e "\n${C}$*${N}"; }
die()  { echo -e "${R}FATAL:${N} $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Run as your normal user, not root. (sudo is called internally)"

echo
echo "╔══════════════════════════════════════╗"
echo "║  Secure Remote Access Setup          ║"
echo "║  Tailscale + SSH + tmux              ║"
echo "╚══════════════════════════════════════╝"

# ── 1. Tailscale ───────────────────────────────────────────────────────────────
head "1/5  Tailscale"

if ! command -v tailscale &>/dev/null; then
  info "Installing Tailscale..."
  # Official Tailscale Fedora install (https://tailscale.com/download/linux)
  curl -fsSL https://tailscale.com/install.sh | sh
else
  ok "Tailscale already installed: $(tailscale version | head -1)"
fi

if ! sudo tailscale status &>/dev/null; then
  sudo systemctl enable --now tailscaled
  ok "tailscaled service enabled"
fi

TS_STATUS=$(sudo tailscale status 2>/dev/null || echo "")
if echo "$TS_STATUS" | grep -q "100\."; then
  TS_IP=$(sudo tailscale ip -4 2>/dev/null)
  ok "Tailscale already connected — IP: ${TS_IP}"
else
  info "Starting Tailscale — a browser tab will open to authenticate..."
  sudo tailscale up --ssh
  TS_IP=$(sudo tailscale ip -4 2>/dev/null)
  ok "Tailscale connected — IP: ${TS_IP}"
fi

# ── 2. Harden sshd ────────────────────────────────────────────────────────────
head "2/5  SSH daemon hardening"

SSHD_CONF="/etc/ssh/sshd_config.d/99-evident-hardening.conf"
info "Writing ${SSHD_CONF}..."

# Backup existing conf if any
[ -f "$SSHD_CONF" ] && sudo cp "$SSHD_CONF" "${SSHD_CONF}.bak"

sudo tee "$SSHD_CONF" > /dev/null << EOF
# Evident Technologies — SSH hardening
# Written by setup-ssh-remote.sh — modify here, not in sshd_config

# Key auth only — no passwords, no empty passwords
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# No root login
PermitRootLogin no

# Limit auth attempts and session timeout
MaxAuthTries 3
LoginGraceTime 20s
MaxSessions 5

# Disable unused features (reduce attack surface)
X11Forwarding no
AllowAgentForwarding yes
AllowTcpForwarding yes
PermitTunnel no
PrintMotd no

# Use modern ciphers only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# Connection keepalive
ClientAliveInterval 120
ClientAliveCountMax 3
EOF

# Ensure host keys exist (fresh/minimal installs may have none -> "no hostkeys available")
if ! ls /etc/ssh/ssh_host_*_key &>/dev/null; then
  info "No SSH host keys found — generating them..."
  sudo ssh-keygen -A
  ok "Host keys generated"
fi

info "Validating sshd config..."
sudo sshd -t && ok "sshd config valid" || die "sshd config has errors — check ${SSHD_CONF}"

# Reload if active, otherwise enable+start (service name is sshd on Fedora, ssh on Debian/Ubuntu)
SSHD_UNIT=$(systemctl list-unit-files 2>/dev/null | grep -oE '^(sshd|ssh)\.service' | head -1)
SSHD_UNIT="${SSHD_UNIT:-sshd.service}"
if systemctl is-active --quiet "$SSHD_UNIT"; then
  sudo systemctl reload "$SSHD_UNIT" && ok "$SSHD_UNIT reloaded"
else
  sudo systemctl enable --now "$SSHD_UNIT" && ok "$SSHD_UNIT enabled and started"
fi

# ── 3. Authorized keys ────────────────────────────────────────────────────────
head "3/5  Authorized keys"

SSH_PUB="${HOME}/.ssh/id_ed25519.pub"
AUTH_KEYS="${HOME}/.ssh/authorized_keys"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"

if [ -f "$SSH_PUB" ]; then
  PUBKEY=$(cat "$SSH_PUB")
  if ! grep -qF "$PUBKEY" "$AUTH_KEYS" 2>/dev/null; then
    cat "$SSH_PUB" >> "$AUTH_KEYS"
    ok "Local public key added to authorized_keys"
  else
    ok "Local public key already in authorized_keys"
  fi
else
  warn "No ~/.ssh/id_ed25519.pub found — run setup-github-auth.sh first"
fi

echo
info "To add a key from another device (laptop, phone), paste its public key here."
info "Press Enter alone to skip."
read -rp "  Paste additional authorized key (or Enter to skip): " EXTRA_KEY
if [ -n "$EXTRA_KEY" ]; then
  echo "$EXTRA_KEY" >> "$AUTH_KEYS"
  ok "Additional key added"
fi

# ── 4. tmux command-center startup ────────────────────────────────────────────
head "4/5  tmux command center"

CC_SCRIPT="${HOME}/workspace/bin/cc-start"

cat > "$CC_SCRIPT" << 'TMUX_EOF'
#!/usr/bin/env bash
# cc-start — launch or attach to the Evident command-center tmux session
SESSION="evident"

tmux has-session -t "$SESSION" 2>/dev/null && { tmux attach -t "$SESSION"; exit; }

# Create session with 4 named windows
tmux new-session  -d -s "$SESSION" -n "platform"  -c "${WORKSPACE:-$HOME/workspace}/platform"     2>/dev/null || \
tmux new-session  -d -s "$SESSION" -n "platform"  -c "${HOME}/workspace"

tmux new-window   -t "$SESSION" -n ".github"   -c "${WORKSPACE:-$HOME/workspace}/.github"  2>/dev/null || true
tmux new-window   -t "$SESSION" -n "ops"       -c "${HOME}/evident/ops"                    2>/dev/null || true
tmux new-window   -t "$SESSION" -n "shell"     -c "${HOME}"

# Set window 1 (platform) as default
tmux select-window -t "${SESSION}:platform" 2>/dev/null || tmux select-window -t "${SESSION}:1"

# Show daily brief on attach (if briefing command exists)
tmux send-keys -t "${SESSION}:shell" '[ -f "$WORKSPACE/platform/scripts/brief.sh" ] && "$WORKSPACE/platform/scripts/brief.sh"' Enter 2>/dev/null || true

tmux attach -t "$SESSION"
TMUX_EOF

chmod +x "$CC_SCRIPT"
ok "Command center script: $CC_SCRIPT"
ok "Alias 'cc' → runs cc-start (attach or create)"

# Update .bashrc alias to use cc-start
grep -qF 'cc-start' "${HOME}/.bashrc" 2>/dev/null \
  || sed -i "s|alias cc=.*|alias cc='${CC_SCRIPT}'|" "${HOME}/.bashrc" 2>/dev/null || true

# ── 5. SSH client config for connecting FROM another machine ───────────────────
head "5/5  Client config (for your other devices)"

TS_IP="${TS_IP:-<your-tailscale-ip>}"
WHOAMI=$(id -un)

cat << EOF

Add this block to ~/.ssh/config on your LAPTOP or other devices:

─────────────────────────────────────────────────────────────
Host matrix5
  HostName ${TS_IP}
  User ${WHOAMI}
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  IdentitiesOnly yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
  RemoteCommand tmux new-session -A -s evident
  RequestTTY yes
─────────────────────────────────────────────────────────────

Then connect with:   ssh matrix5
It will drop you directly into the tmux command center.
EOF

# ── Summary ────────────────────────────────────────────────────────────────────
TS_IP_FINAL=$(sudo tailscale ip -4 2>/dev/null || echo "check: tailscale ip")

echo
echo "╔══════════════════════════════════════╗"
echo "║  Remote access ready.                ║"
echo "╠══════════════════════════════════════╣"
printf "║  Tailscale IP:  %-22s║\n" "${TS_IP_FINAL}"
echo "║  Connect from anywhere:              ║"
printf "║    ssh %s@%-24s║\n" "${WHOAMI}" "${TS_IP_FINAL}"
echo "║  Or after adding ssh config:         ║"
echo "║    ssh matrix5                       ║"
echo "║                                      ║"
echo "║  Local command center:               ║"
echo "║    cc  (or: cc-start)                ║"
echo "╚══════════════════════════════════════╝"
echo
echo "  Tailscale dashboard: https://login.tailscale.com/admin"
echo "  Install on other devices: https://tailscale.com/download"
echo
