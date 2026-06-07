#!/usr/bin/env bash
# setup-worker-node.sh — provision an Ubuntu Server LTS box as a private,
# headless Evident worker.  Classification: local-ci-and-derivative-worker.
#
# ROLE: offload repo checks, builds, tests, linting, dependency audits,
#       long-running jobs, Docker sidecars, Supabase local stack, and
#       evidence derivative processing (PDF/media/OCR) from the workstation.
#
# ALLOWED:     private-repo validation, local CI mirror, Docker/service hosting,
#              PDF/media processing, OCR/transcription, hash-verified derivative
#              generation, secure transfer to Supabase / Cloudflare R2.
# NOT ALLOWED: public web serving, production deploy authority, prod DB
#              migrations, plaintext long-lived secrets, mutation of immutable
#              originals, GitHub Actions for PUBLIC fork pull requests.
#
# Run on the Ubuntu laptop as your normal user (sudo is used internally).
#   ENABLE_ACTIONS_RUNNER=1 ./setup-worker-node.sh   # also register a runner
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
warn() { echo -e "${R}  !${N}  $*"; }
head() { echo -e "\n${C}$*${N}"; }
die()  { echo -e "${R}FATAL:${N} $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Run as your normal user, not root."
command -v apt-get >/dev/null || die "This script is for Ubuntu/Debian (apt). Use setup-ssh-remote.sh on Fedora."

WORKER_HOME="${HOME}/evident-worker"
TS_TAG="${TS_TAG:-tag:ci-worker}"

echo
echo "╔══════════════════════════════════════════╗"
echo "║  Evident Worker Node — Ubuntu Server     ║"
echo "║  local-ci-and-derivative-worker          ║"
echo "╚══════════════════════════════════════════╝"

# ── 1. Base packages ───────────────────────────────────────────────────────────
head "1/7  Base packages"
sudo apt-get update -qq
sudo apt-get install -y -qq \
  build-essential git curl wget jq ca-certificates gnupg lsb-release \
  unzip zip tmux htop rsync openssh-server uidmap
ok "base toolchain installed"

# ── 2. Derivative-processing toolchain ─────────────────────────────────────────
head "2/7  Derivative / evidence processing toolchain"
sudo apt-get install -y -qq \
  tesseract-ocr tesseract-ocr-eng \
  ffmpeg \
  poppler-utils \
  imagemagick \
  qpdf \
  libimage-exiftool-perl
ok "OCR (tesseract), media (ffmpeg), PDF (poppler/qpdf), exiftool installed"

# ── 3. Tailscale enrollment ────────────────────────────────────────────────────
head "3/7  Tailscale (private mesh, SSH on)"
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl enable --now tailscaled
if sudo tailscale status &>/dev/null && sudo tailscale ip -4 &>/dev/null; then
  ok "already connected: $(sudo tailscale ip -4)"
else
  info "Authenticate in the browser tab that opens..."
  # --ssh enables Tailscale SSH; tag keeps ACL policy clear
  sudo tailscale up --ssh --hostname evident-worker-01 --advertise-tags "$TS_TAG" || \
  sudo tailscale up --ssh --hostname evident-worker-01   # fall back if tag not pre-authorized
  ok "connected: $(sudo tailscale ip -4)"
fi

# ── 4. SSH hardening (Ubuntu unit is 'ssh') ────────────────────────────────────
head "4/7  SSH hardening"
if ! ls /etc/ssh/ssh_host_*_key &>/dev/null; then
  sudo ssh-keygen -A && ok "host keys generated"
fi
SSHD_CONF="/etc/ssh/sshd_config.d/99-evident-hardening.conf"
sudo tee "$SSHD_CONF" > /dev/null << 'EOF'
# Evident worker — SSH hardening
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 20s
X11Forwarding no
PrintMotd no
ClientAliveInterval 120
ClientAliveCountMax 3
EOF
sudo sshd -t && ok "sshd config valid"
sudo systemctl enable --now ssh
sudo systemctl reload ssh && ok "ssh reloaded"

# ── 5. Docker (rootless-friendly; for sidecars + Supabase local stack) ─────────
head "5/7  Docker engine"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  ok "Docker installed — log out/in for group to take effect"
else
  ok "Docker already present: $(docker --version)"
fi

# ── 6. Worker directory layout + policy ────────────────────────────────────────
head "6/7  Worker layout + policy guardrails"
mkdir -p \
  "${WORKER_HOME}/originals" \
  "${WORKER_HOME}/derivatives" \
  "${WORKER_HOME}/manifests" \
  "${WORKER_HOME}/work" \
  "${WORKER_HOME}/logs" \
  "${WORKER_HOME}/inbox"

# Originals are immutable by policy: anything dropped here is the source of truth.
cat > "${WORKER_HOME}/POLICY.md" << 'EOF'
# Evident Worker Policy — local-ci-and-derivative-worker

## Allowed
- Private repository validation (build, test, lint, dependency audit)
- Local CI mirror workflows
- Docker / service hosting for development (sidecars, Supabase local stack)
- PDF / media processing, OCR / transcription experiments
- Hash-verified derivative generation (see derive.sh)
- Secure transfer to approved storage (Supabase, Cloudflare R2)

## Not allowed by default
- Public web serving
- Production deploy authority
- Production database migrations
- Plaintext long-lived secrets on disk
- Mutation of immutable originals (originals/ is write-once)
- GitHub Actions execution for PUBLIC fork pull requests

## Directories
- originals/    write-once source files (mark immutable: chattr +i <file>)
- derivatives/  generated outputs (safe to delete & regenerate)
- manifests/    sha256 provenance records, one JSON per derivative
- work/         scratch for jobs (ephemeral)
- inbox/        new files awaiting processing
- logs/         job logs

## Secrets
Use Tailscale identity + short-lived tokens. Never store long-lived prod
credentials here. Dev/test creds only, in ~/.config (mode 600), never in repos.
EOF
chmod 600 "${WORKER_HOME}/POLICY.md"
ok "layout + POLICY.md at ${WORKER_HOME}"

# ── 7. Optional: private-repo self-hosted Actions runner ───────────────────────
head "7/7  GitHub Actions runner (optional)"
if [ "${ENABLE_ACTIONS_RUNNER:-0}" = "1" ]; then
  warn "Registering a self-hosted runner. Attach it to a PRIVATE repo/org only."
  warn "In repo Settings → Actions → Fork PRs: keep public-fork workflows DISABLED."
  read -rp "  Repo or org URL (e.g. https://github.com/evident-technologies/platform): " RUNNER_URL
  read -rp "  Runner registration token (Settings → Actions → Runners → New): " RUNNER_TOKEN
  RUNNER_DIR="${HOME}/actions-runner"
  mkdir -p "$RUNNER_DIR"; cd "$RUNNER_DIR"
  RUNNER_VER=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  curl -fsSL -o runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz"
  tar xzf runner.tar.gz && rm runner.tar.gz
  ./config.sh --url "$RUNNER_URL" --token "$RUNNER_TOKEN" \
    --name evident-worker-01 --labels evident-ci-worker,linux,self-hosted \
    --work _work --unattended
  sudo ./svc.sh install && sudo ./svc.sh start
  ok "Actions runner installed as a service (label: evident-ci-worker)"
else
  info "Skipped. Re-run with ENABLE_ACTIONS_RUNNER=1 to register a runner."
fi

# ── Summary ────────────────────────────────────────────────────────────────────
TS_IP=$(sudo tailscale ip -4 2>/dev/null || echo "?")
echo
echo "╔══════════════════════════════════════════╗"
echo "║  Worker provisioned.                     ║"
echo "╠══════════════════════════════════════════╣"
printf "║  Tailscale IP:  %-24s║\n" "$TS_IP"
echo "║  Reach it:  ssh <user>@<tailscale-ip>    ║"
echo "║  Layout:    ~/evident-worker/            ║"
echo "║  Policy:    ~/evident-worker/POLICY.md   ║"
echo "║  Derive:    derive.sh <file>             ║"
echo "╚══════════════════════════════════════════╝"
echo
