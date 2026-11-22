# For the prompt: HAT_GH, the GitHub account git uses in this repo, only when it isn't
# your default one (the repo's email differs from the global one): hat's rule for the
# folder, else the hat account with that email, else the email itself.
# Runs every prompt, after direnv: one git call outside a repo.
_hat_precmd() {
  local e s f l
  unset HAT_GH
  command git rev-parse --git-dir >/dev/null 2>&1 || return 0
  e=$(command git config --get user.email 2>/dev/null)
  [ "$e" = "$(command git config --global --get user.email 2>/dev/null)" ] && return 0
  s=$(command git config --get core.sshCommand 2>/dev/null)
  case "$s" in */hat/github/*.ssh_config*) s=${s##*/hat/github/}; export HAT_GH="${s%%.ssh_config*}"; return 0 ;; esac
  [ -n "$e" ] || return 0
  [ -n "${ZSH_VERSION:-}" ] && setopt localoptions nullglob
  for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/hat/github/*.gitconfig; do
    while read -r l; do
      case "$l" in "email = $e") s=${f##*/}; export HAT_GH="${s%.gitconfig}"; return 0 ;; esac
    done <"$f"
  done
  export HAT_GH="$e"
}
if [ -n "${ZSH_VERSION:-}" ]; then
  autoload -Uz add-zsh-hook && add-zsh-hook precmd _hat_precmd
elif declare -F starship_precmd >/dev/null; then
  case "${STARSHIP_PROMPT_COMMAND:-}" in *_hat_precmd*) ;; *)
    STARSHIP_PROMPT_COMMAND="${STARSHIP_PROMPT_COMMAND:+$STARSHIP_PROMPT_COMMAND;}_hat_precmd" ;; esac
else
  case "${PROMPT_COMMAND:-}" in *_hat_precmd*) ;; *)
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_hat_precmd" ;; esac
fi

# gh as the folder's GitHub account (hat), not just gh's active one. gh auth stays
# as it is (a sign-in can't run with a token set). Skipped if you have your own gh.
case "$(type gh 2>/dev/null)" in *function*) _work_gh_own=${_work_gh:-1} ;; *) _work_gh_own="" ;; esac
if [ -z "$_work_gh_own" ] || [ -n "${_work_gh:-}" ]; then
  _work_gh=1
  gh() {
    if [ "${1:-}" = auth ] || ! command -v hat >/dev/null 2>&1; then command gh "$@"; else hat __gh "$@"; fi
  }
fi
unset _work_gh_own

# hat: the second word of claude / github, then the profile or account
_work_complete_hat() {
  local d
  case "$COMP_CWORD:${COMP_WORDS[1]}" in
    2:claude) printf '%s\n' add rm ;;
    2:github) printf '%s\n' add rm login ;;
    3:claude) [ "${COMP_WORDS[2]}" = rm ] && command ls -1 "${CLAUDE_PROFILES_DIR:-$HOME/.claude-profiles}" ;;
    3:github)
      case "${COMP_WORDS[2]}" in rm|login)
        for d in "${XDG_CONFIG_HOME:-$HOME/.config}"/hat/github/*.gitconfig; do
          [ -f "$d" ] && { d=${d##*/}; printf '%s\n' "${d%.gitconfig}"; }
        done ;;
      esac ;;
  esac
}
# hat show/set/off take a folder: with no word of ours, the shell completes paths.
# _work_complete (unikit's shell/complete.sh) gives the first word from hat's help page.
if [ -n "${ZSH_VERSION:-}" ]; then
  autoload -U +X bashcompinit 2>/dev/null && bashcompinit
fi
complete -o default -F _work_complete hat 2>/dev/null
