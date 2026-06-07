#!/usr/bin/env bash
# secure-keys.sh — protect your SSH keys "safely and forever".
#
# Three layers of durability, in order of importance:
#   1. PASSPHRASE   a stolen disk/laptop must not equal a stolen key
#   2. AGENT        type the passphrase once per login, not every connection
#   3. BACKUP       an encrypted, checksummed copy you can restore from
#                   if a machine dies, is lost, or is wiped
#
# It NEVER uploads anything. The encrypted backup is a single file YOU move
# to offline storage (USB, safe, password manager attachment).
#
# Run on each machine (MATRIX5 and ASPIRE) as your normal user.
#   ./secure-keys.sh                 # interactive: passphrase + backup
#   ./secure-keys.sh --backup-only   # skip passphrase prompt, just back up
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
warn() { echo -e "${R}  !${N}  $*"; }
head() { echo -e "\n${C}$*${N}"; }
die()  { echo -e "${R}FATAL:${N} $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && die "Run as your normal user, not root."
have() { command -v "$1" >/dev/null 2>&1; }

SSH_DIR="${HOME}/.ssh"
KEY="${SSH_DIR}/id_ed25519"
BACKUP_ONLY=0
[ "${1:-}" = "--backup-only" ] && BACKUP_ONLY=1

echo
echo "╔══════════════════════════════════════╗"
echo "║  Secure Your SSH Keys — Forever      ║"
echo "╚══════════════════════════════════════╝"
echo "  Host: $(hostname)"

[ -f "$KEY" ] || die "No ${KEY} found. Run setup-github-auth.sh first to create it."

# ── 1. Passphrase ──────────────────────────────────────────────────────────────
# An ssh private key with no passphrase is plaintext: whoever reads the file
# owns the key. ssh-keygen -y will FAIL on a passphrased key without the pass,
# so we use it to detect whether one is set.
head "1/3  Passphrase protection"
if [ "$BACKUP_ONLY" -eq 0 ]; then
  if ssh-keygen -y -P "" -f "$KEY" >/dev/null 2>&1; then
    warn "Your private key has NO passphrase (plaintext on disk)."
    info "Adding one now. Pick something long you can remember — a passphrase,"
    info "not a password. ssh-agent will cache it so you type it once per login."
    ssh-keygen -p -f "$KEY"
    ok "Passphrase set on ${KEY}"
  else
    ok "Private key is already passphrase-protected"
  fi
else
  info "Skipped (--backup-only)"
fi

# ── 2. ssh-agent convenience ───────────────────────────────────────────────────
head "2/3  Agent (type passphrase once per login)"
SHELL_RC="${HOME}/.bashrc"
AGENT_BLOCK_MARK="# >>> evident ssh-agent autostart >>>"
if ! grep -qF "$AGENT_BLOCK_MARK" "$SHELL_RC" 2>/dev/null; then
  cat >> "$SHELL_RC" << 'EOF'

# >>> evident ssh-agent autostart >>>
# Start a single ssh-agent per login and load the key on first use.
if [ -z "${SSH_AUTH_SOCK:-}" ] && command -v ssh-agent >/dev/null; then
  eval "$(ssh-agent -s)" >/dev/null
fi
ssh-add -l >/dev/null 2>&1 || ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
# <<< evident ssh-agent autostart <<<
EOF
  ok "ssh-agent autostart added to ~/.bashrc"
else
  ok "ssh-agent autostart already configured"
fi

# ── 3. Encrypted, checksummed backup ───────────────────────────────────────────
head "3/3  Encrypted backup bundle"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
HOST="$(hostname -s 2>/dev/null || hostname)"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# What to back up: the keypair, the ssh config, and authorized_keys.
# These together let you fully reconstruct identity + access on a new machine.
BUNDLE="${STAGE}/ssh-keys-${HOST}-${STAMP}.tar"
tar -cf "$BUNDLE" -C "$HOME" \
  .ssh/id_ed25519 .ssh/id_ed25519.pub \
  $( [ -f "${SSH_DIR}/config" ]          && echo .ssh/config ) \
  $( [ -f "${SSH_DIR}/authorized_keys" ] && echo .ssh/authorized_keys ) \
  2>/dev/null
ok "Staged keypair + config + authorized_keys"

# Encrypt. Prefer age, then gpg symmetric, then openssl. All are AES-grade and
# password-based so restore needs only the passphrase you choose now (store it
# in your password manager — it is the ONLY thing that can open this backup).
OUT_DIR="${HOME}/evident/secure/key-backups"
mkdir -p "$OUT_DIR"; chmod 700 "$OUT_DIR"

if have age; then
  ENC="${OUT_DIR}/$(basename "$BUNDLE").age"
  info "Encrypting with age (set a strong passphrase)..."
  age -p -o "$ENC" "$BUNDLE"
  DECRYPT_HINT="age -d -o restore.tar '$(basename "$ENC")'"
elif have gpg; then
  ENC="${OUT_DIR}/$(basename "$BUNDLE").gpg"
  info "Encrypting with gpg (set a strong passphrase)..."
  gpg --symmetric --cipher-algo AES256 -o "$ENC" "$BUNDLE"
  DECRYPT_HINT="gpg -d -o restore.tar '$(basename "$ENC")'"
else
  ENC="${OUT_DIR}/$(basename "$BUNDLE").enc"
  info "Encrypting with openssl AES-256 (set a strong passphrase)..."
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 600000 -in "$BUNDLE" -out "$ENC"
  DECRYPT_HINT="openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -in '$(basename "$ENC")' -out restore.tar"
fi
chmod 600 "$ENC"
ok "Encrypted backup: $ENC"

# Checksum so you can prove the backup is intact years later.
( cd "$OUT_DIR" && sha256sum "$(basename "$ENC")" > "$(basename "$ENC").sha256" )
ok "Checksum: ${ENC}.sha256"

# Restore instructions travel WITH the backup.
cat > "${OUT_DIR}/RESTORE-README.txt" << EOF
Evident SSH key backup — restore instructions
=============================================
Created : ${STAMP}
From    : ${HOST}
Cipher  : $(basename "${ENC##*.}")

To verify the file is intact:
    sha256sum -c $(basename "$ENC").sha256

To restore onto a new machine:
    1. Copy the encrypted file there.
    2. ${DECRYPT_HINT}
    3. tar -xf restore.tar -C ~          # recreates ~/.ssh/...
    4. chmod 700 ~/.ssh
       chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config ~/.ssh/authorized_keys
       chmod 644 ~/.ssh/id_ed25519.pub
    5. shred -u restore.tar              # remove the decrypted copy

The passphrase that opens this backup is NOT stored anywhere on disk.
Keep it in your password manager. Without it, this file is unrecoverable
(that is the point).
EOF
ok "Restore guide: ${OUT_DIR}/RESTORE-README.txt"

# ── Summary ────────────────────────────────────────────────────────────────────
echo
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Keys secured on $(printf '%-37s' "$HOST")║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  ✓ private key passphrase-protected                  ║"
echo "║  ✓ ssh-agent caches it (type once per login)         ║"
echo "║  ✓ encrypted + checksummed backup written            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
warn  "NOW DO THIS (the script cannot, by design):"
echo  "  1. Move the .age/.gpg/.enc file OFF this machine:"
echo  "       • a USB drive kept somewhere safe, AND"
echo  "       • your password manager (Bitwarden/1Password attachment)"
echo  "  2. Store the backup PASSPHRASE in your password manager."
echo  "  3. In the Tailscale admin console, disable key expiry on this node"
echo  "     so it never silently drops off the tailnet."
echo
echo  "  Two copies in two places = safe forever. One copy = one disk failure"
echo  "  away from a lockout."
echo
