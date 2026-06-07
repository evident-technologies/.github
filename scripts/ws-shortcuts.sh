# ws-shortcuts.sh — pinned, easy access to every repo. Source from ~/.bashrc:
#   echo 'source ~/workspace/bin/ws-shortcuts.sh' >> ~/.bashrc
export WORKSPACE="${WORKSPACE:-$HOME/workspace}"

# `cd <reponame>` works from anywhere (tab-completes via filesystem too)
export CDPATH=".:$WORKSPACE"

# jump to workspace or a repo:  ws            -> workspace root
#                               ws evident-icu -> that repo
ws() { cd "$WORKSPACE/${1:-}" || return; }

# list pinned repos
repos() { command ls -1 "$WORKSPACE" | grep -vE '^(\.|bin$)'; }

# safe push: write to the LOCAL MIRROR first, then GitHub.
# Catches bad pushes locally (the pre-push hook runs) before anything leaves.
gpush() {
  git push mirror HEAD || { echo "mirror push failed — fix before pushing to origin"; return 1; }
  git push origin HEAD "$@"
}

# tab-completion for `ws`
if [ -n "${BASH_VERSION:-}" ]; then
  _ws_complete() { COMPREPLY=( $(compgen -W "$(repos)" -- "${COMP_WORDS[COMP_CWORD]}") ); }
  complete -F _ws_complete ws
fi
