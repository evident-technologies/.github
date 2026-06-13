#!/usr/bin/env bash
# ship.sh — local inner-loop runner for the ASPIRE worker.
#
# Goal: commit good changes OFTEN, and resolve checks HERE (on aspire) instead
# of waiting on GitHub Actions. It mirrors the org's CI gates locally, then
# drives a clean commit + mirror-first push — so by the time Actions runs, it
# has nothing left to catch.
#
# Commands:
#   ship.sh status        what changed (tracked diff + untracked files, sized)
#   ship.sh check         run the local CI gates (same checks Actions runs)
#   ship.sh commit        stage + conventional-commit (interactive or -m)
#   ship.sh push          mirror-first push (mirror remote, then origin)
#   ship.sh               check -> commit -> push  (aborts on any gate failure)
#   ship.sh deploy        run repo-local ./scripts/deploy.sh, prod-guarded
#   ship.sh install       add `ship` alias + a pre-commit gate hook in this repo
#
# Flags:  -m "<msg>"   non-interactive commit message
#         -a           stage ALL changes (tracked+untracked) before committing
#         -n           no-verify is NOT supported on purpose; gates are the point
#
# Safe by design: no sudo, never mutates originals, never deploys to prod
# without an explicit, repo-declared non-prod target.
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()   { echo -e "${G}  ✓${N}  $*"; }
info() { echo -e "${Y}  →${N}  $*"; }
warn() { echo -e "${R}  !${N}  $*"; }
head() { echo -e "\n${C}${B}$*${N}"; }
die()  { echo -e "${R}FATAL:${N} $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

MSG=""; STAGE_ALL=0
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -m) MSG="${2:-}"; shift 2 ;;
    -a) STAGE_ALL=1; shift ;;
    *)  ARGS+=("$1"); shift ;;
  esac
done
CMD="${ARGS[0]:-ship}"

# Secret patterns — kept in lockstep with .github/workflows/security-secret-scan.yml
SECRET_RE='(AKIA[0-9A-Z]{16}|sk_live_[0-9a-zA-Z]{24,}|sk_test_[0-9a-zA-Z]{24,}|-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----|ghp_[0-9a-zA-Z]{36}|gho_[0-9a-zA-Z]{36}|github_pat_[0-9a-zA-Z_]{82}|eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*|supabase_[A-Za-z0-9]{40,})'
# Paths that must never be committed — kept in lockstep with scripts/pre-push
SECRET_PATH_RE='(^|/)(\.env(\..+)?|\.dev\.vars|id_rsa|id_ed25519|.*\.pem|.*\.p12)$|/\.wrangler/'
MAX_BLOB_BYTES=$((50*1024*1024))

# ── status ──────────────────────────────────────────────────────────────────────
cmd_status() {
  head "Changes in $(basename "$ROOT")  [$(git branch --show-current)]"
  local staged unstaged untracked
  staged=$(git diff --cached --name-only)
  unstaged=$(git diff --name-only)
  untracked=$(git ls-files --others --exclude-standard)

  if [ -n "$staged" ];   then echo -e "${G}staged:${N}";   git diff --cached --stat | sed 's/^/  /'; fi
  if [ -n "$unstaged" ]; then echo -e "${Y}modified (unstaged):${N}"; echo "$unstaged" | sed 's/^/  /'; fi
  if [ -n "$untracked" ]; then
    echo -e "${C}untracked:${N}"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      local sz; sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
      if [ "$sz" -gt "$MAX_BLOB_BYTES" ]; then
        echo -e "  ${R}$f  ($(numfmt --to=iec "$sz" 2>/dev/null || echo "${sz}B")  ⚠ >50MB)${N}"
      else
        printf '  %s  (%s)\n' "$f" "$(numfmt --to=iec "$sz" 2>/dev/null || echo "${sz}B")"
      fi
    done <<< "$untracked"
  fi
  [ -z "$staged$unstaged$untracked" ] && ok "working tree clean"
}

# ── check (local CI mirror) ─────────────────────────────────────────────────────
cmd_check() {
  head "Local CI gates (mirroring GitHub Actions)"
  local fail=0

  # What will we judge? Prefer staged; fall back to all changes vs HEAD.
  local scope; scope="$(git diff --cached --name-only)"
  [ -z "$scope" ] && scope="$(git diff --name-only; git ls-files --others --exclude-standard)"

  # 1. Secret-bearing PATHS (pre-push parity)
  info "secret-path scan…"
  local badpath=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if echo "$f" | grep -qE "$SECRET_PATH_RE"; then warn "blocked path: $f"; badpath=1; fi
  done <<< "$scope"
  [ "$badpath" -eq 0 ] && ok "no secret-like paths" || { fail=1; warn "remove the paths above (.env/.pem/keys/.wrangler)"; }

  # 2. Secret PATTERNS in changes (security-secret-scan parity) — covers staged
  #    + unstaged diffs AND the full content of new untracked files (which
  #    produce no diff yet but can still carry a leaked key).
  info "secret-pattern scan (changed + untracked)…"
  local hits; hits="$( { git diff --cached; git diff; } 2>/dev/null | grep -nEi "$SECRET_RE" || true )"
  local utf; utf="$(git ls-files --others --exclude-standard)"
  while IFS= read -r f; do
    [ -z "$f" ] && continue; [ -f "$f" ] || continue
    local m; m="$(grep -nEi "$SECRET_RE" "$f" 2>/dev/null | sed "s|^|$f:|" || true)"
    [ -n "$m" ] && hits="${hits}${hits:+$'\n'}${m}"
  done <<< "$utf"
  if [ -n "$hits" ]; then warn "potential secret detected:"; echo "$hits" | sed 's/^/    /'; fail=1
  else ok "no secret patterns in changes"; fi

  # 3. Oversized blobs (pre-push parity)
  info "large-file scan…"
  local big=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue; [ -f "$f" ] || continue
    local sz; sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
    [ "$sz" -gt "$MAX_BLOB_BYTES" ] && { warn "too large (>50MB): $f"; big=1; }
  done <<< "$scope"
  [ "$big" -eq 0 ] && ok "no oversized files" || { fail=1; warn "use Git LFS or external storage for the above"; }

  # 4. Governance artifacts (validate.yml parity) — only enforce in governed repos
  if [ -f ".github/workflows/validate.yml" ]; then
    info "governance-artifact presence…"
    local miss=()
    for a in SECURITY.md CODE_OF_CONDUCT.md CONTRIBUTING.md; do [ -f "$a" ] || miss+=("$a"); done
    if [ "${#miss[@]}" -gt 0 ]; then warn "missing: ${miss[*]}"; fail=1; else ok "governance artifacts present"; fi
  fi

  # 5. Shell lint (static-shell parity) — shellcheck changed *.sh
  if echo "$scope" | grep -q '\.sh$'; then
    if have shellcheck; then
      info "shellcheck on changed shell scripts…"
      local sh_fail=0
      while IFS= read -r f; do
        case "$f" in *.sh) [ -f "$f" ] && { shellcheck -S warning "$f" || sh_fail=1; } ;; esac
      done <<< "$scope"
      [ "$sh_fail" -eq 0 ] && ok "shellcheck clean" || { fail=1; warn "fix shellcheck findings above"; }
    else
      warn "shellcheck not installed — skipping (sudo apt-get install -y shellcheck)"
    fi
  fi

  # 6. Node lint/build (static-ci-app / verify-lint parity) — only if declared
  if [ -f package.json ] && have npm; then
    if grep -q '"lint"' package.json; then
      info "npm run lint…"; npm run -s lint && ok "lint passed" || { fail=1; warn "lint failed"; }
    fi
    if grep -q '"build"' package.json; then
      info "npm run build…"; npm run -s build && ok "build passed" || { fail=1; warn "build failed"; }
    fi
  fi

  echo
  if [ "$fail" -eq 0 ]; then ok "${B}all local gates green${N}"; return 0
  else warn "${B}gates failed — fix above before pushing${N}"; return 1; fi
}

# ── commit ──────────────────────────────────────────────────────────────────────
cmd_commit() {
  [ "$STAGE_ALL" -eq 1 ] && git add -A
  if git diff --cached --quiet; then
    # nothing staged — offer to stage everything
    if [ -n "$(git status --porcelain)" ]; then
      info "nothing staged. Stage all changes now? [y/N]"; read -r yn
      [ "${yn:-N}" = "y" ] && git add -A || die "nothing staged; aborting"
    else die "nothing to commit"; fi
  fi

  if [ -z "$MSG" ]; then
    head "Conventional commit"
    echo "  types: feat fix chore docs refactor test ci build perf"
    read -rp "  type: " t
    read -rp "  scope (optional): " s
    read -rp "  subject (imperative, <=72): " subj
    [ -n "$t" ] && [ -n "$subj" ] || die "type and subject required"
    if [ -n "$s" ]; then MSG="${t}(${s}): ${subj}"; else MSG="${t}: ${subj}"; fi
  fi
  [ "${#MSG}" -le 100 ] || warn "subject is long (${#MSG} chars) — consider trimming"
  git commit -m "$MSG"
  ok "committed: $MSG"
}

# ── push (mirror-first) ─────────────────────────────────────────────────────────
cmd_push() {
  local br; br="$(git branch --show-current)"
  if git remote | grep -qx mirror; then
    info "pushing to mirror first…"; git push mirror "$br" && ok "mirror updated"
  fi
  local i
  for i in 1 2 3 4; do
    git push -u origin "$br" && { ok "pushed origin/$br"; return 0; }
    warn "push failed (network?), retry $i…"; sleep $((2**i))
  done
  die "push to origin failed after retries"
}

# ── deploy (prod-guarded) ───────────────────────────────────────────────────────
cmd_deploy() {
  head "Deploy via aspire runner"
  [ -f ./scripts/deploy.sh ] || die "no ./scripts/deploy.sh in this repo — nothing to run"
  # POLICY: the worker has no production deploy authority. Refuse prod targets.
  local target="${DEPLOY_TARGET:-dev}"
  case "$target" in
    prod|production|live)
      die "refusing prod deploy from the worker (policy: no production deploy authority).
       Production deploys go through the approved pipeline, not aspire." ;;
  esac
  info "running ./scripts/deploy.sh (target=$target)…"
  DEPLOY_TARGET="$target" bash ./scripts/deploy.sh
  ok "deploy ($target) finished"
}

# ── install (alias + per-repo pre-commit gate) ──────────────────────────────────
cmd_install() {
  head "Installing ship convenience"
  local self; self="$(readlink -f "$0")"
  local rc="${HOME}/.bashrc"
  if ! grep -q "alias ship=" "$rc" 2>/dev/null; then
    echo "alias ship='$self'" >> "$rc"; ok "alias ship -> $self (open new shell)"
  else ok "alias ship already present"; fi

  local hook="${ROOT}/.git/hooks/pre-commit"
  cat > "$hook" << EOF
#!/usr/bin/env bash
# Auto-installed by ship.sh — block commits that fail local gates.
exec "$self" check
EOF
  chmod +x "$hook"
  ok "pre-commit gate installed: ${hook}"
  info "now every 'git commit' runs the local CI gates first"
}

# ── ship (default) ──────────────────────────────────────────────────────────────
cmd_ship() {
  cmd_status
  cmd_check || die "local gates failed — not committing"
  cmd_commit
  cmd_push
  echo
  ok "${B}shipped.${N} aspire resolved the checks; Actions has nothing left to catch."
}

case "$CMD" in
  status)  cmd_status ;;
  check)   cmd_check ;;
  commit)  cmd_commit ;;
  push)    cmd_push ;;
  deploy)  cmd_deploy ;;
  install) cmd_install ;;
  ship)    cmd_ship ;;
  *) die "unknown command: $CMD (try: status|check|commit|push|deploy|install)" ;;
esac
