#!/bin/sh
# Real repositories, local-only upstreams, and shared checks in both shells.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
trial=$(mktemp -d)
trap 'rm -rf "$trial"' EXIT HUP INT TERM
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME='Prompt Test' GIT_COMMITTER_NAME='Prompt Test'
export GIT_AUTHOR_EMAIL=test@example.invalid GIT_COMMITTER_EMAIL=test@example.invalid

cat > "$trial/check.sh" <<'CHECKS'
set -eu
. "$1/shell/prompt.sh"
trial=$2
XDG_CONFIG_HOME="$trial/config with spaces"
export XDG_CONFIG_HOME
mkdir -p "$trial/plain"
cd "$trial/plain"
checks=0
assert_equal() {
    if [ "$1" != "$2" ]; then
        printf 'FAIL: %s\nExpected: %s\nActual: %s\n' "$3" "$2" "$1" >&2
        exit 1
    fi
    checks=$((checks + 1))
}
assert_has() {
    case "$1" in *"$2"*) checks=$((checks + 1)) ;;
        *) printf 'FAIL: missing %s in %s\n' "$2" "$1" >&2; exit 1 ;; esac
}
assert_lacks() {
    case "$1" in *"$2"*) printf 'FAIL: unexpected %s in %s\n' "$2" "$1" >&2; exit 1 ;;
        *) checks=$((checks + 1)) ;; esac
}
unset DOTFILES_PROMPT_TYPE
dotfiles_prompt_init
assert_equal "$DOTFILES_PROMPT_TYPE" extended 'default layout'
assert_equal "$_dotfiles_prompt_git" '' 'outside a repository'
assert_equal "$CONDA_CHANGEPS1" false 'Conda prompt managed once'
prompt simple
assert_equal "$(prompt current)" simple 'select simple'
assert_equal "$(cat "$XDG_CONFIG_HOME/dotfiles/prompt")" simple 'persist selection'
unset DOTFILES_PROMPT_TYPE
dotfiles_prompt_init
assert_equal "$DOTFILES_PROMPT_TYPE" simple 'reload selection'
prompt --session extended
assert_equal "$DOTFILES_PROMPT_TYPE" extended 'session selection'
assert_equal "$(cat "$XDG_CONFIG_HOME/dotfiles/prompt")" simple 'session leaves saved choice'
if prompt invalid > /dev/null 2>&1; then exit 1; fi
assert_equal "$DOTFILES_PROMPT_TYPE" extended 'invalid choice leaves active type'
printf '1\n' | prompt > /dev/null
assert_equal "$(cat "$XDG_CONFIG_HOME/dotfiles/prompt")" simple 'interactive selector'
printf '%s\n' '$(touch MUST_NOT_EXIST)' > "$XDG_CONFIG_HOME/dotfiles/prompt"
unset DOTFILES_PROMPT_TYPE
dotfiles_prompt_init
assert_equal "$DOTFILES_PROMPT_TYPE" extended 'untrusted settings are ignored'
[ ! -e MUST_NOT_EXIST ]

old_hook() { :; }
if [ -n "${ZSH_VERSION:-}" ]; then
    precmd_functions=(old_hook)
    dotfiles_prompt_init
    dotfiles_prompt_init
    assert_equal "${#precmd_functions[@]}" 2 'zsh preserves hooks without duplicates'
else
    PROMPT_COMMAND=old_hook
    dotfiles_prompt_init
    dotfiles_prompt_init
    assert_equal "$PROMPT_COMMAND" '_dotfiles_prompt_update; old_hook' 'Bash scalar hooks'
    PROMPT_COMMAND=(old_hook)
    dotfiles_prompt_init
    dotfiles_prompt_init
    assert_equal "${#PROMPT_COMMAND[@]}" 2 'Bash array hooks'
    assert_equal "${PROMPT_COMMAND[1]}" old_hook 'Bash original hook retained'
fi
set +e
(exit 7)
_dotfiles_prompt_update
set -e
assert_has "$_dotfiles_prompt_error" 7
_dotfiles_prompt_update
assert_equal "$_dotfiles_prompt_error" '' 'clear successful exit status'
CONDA_DEFAULT_ENV='/environments/my%env'
_dotfiles_prompt_update
if [ -n "${ZSH_VERSION:-}" ]; then
    assert_equal "$_dotfiles_prompt_conda" '(my%%env) ' 'zsh escapes Conda percent'
else
    assert_equal "$_dotfiles_prompt_conda" '(my%env) ' 'Bash Conda label'
fi
unset CONDA_DEFAULT_ENV
TERM=dumb
prompt --session simple
assert_lacks "$PS1" '\e['
assert_lacks "$PS1" '%F{'
TERM=xterm-256color NO_COLOR=1
prompt --session extended
assert_lacks "$PS1" '\e['
assert_lacks "$PS1" '%F{'
unset NO_COLOR

git init -q -b main "$trial/project with spaces"
cd "$trial/project with spaces"
printf 'base\n' > unstaged
printf 'base\n' > staged
printf 'base\n' > both
git add .
git -c commit.gpgsign=false commit -qm initial
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '⎇ main ✓'
printf 'edit\n' >> unstaged
printf 'edit\n' >> staged
printf 'stage\n' >> both
git add staged both
printf 'worktree\n' >> both
printf 'untracked\n' > 'file with spaces'
printf 'untracked\n' > "file
with newline"
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '!2'
assert_has "$_dotfiles_prompt_git" '+2'
assert_has "$_dotfiles_prompt_git" '?2'
git add .
git -c commit.gpgsign=false commit -qm changes
git mv staged renamed
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '+1'
assert_lacks "$_dotfiles_prompt_git" '!'
git -c commit.gpgsign=false commit -qm rename
git init -q --bare -b main "$trial/origin.git"
git remote add origin "$trial/origin.git"
git push -qu origin main
git clone -q "$trial/origin.git" "$trial/peer"
printf 'local\n' > local
git add local
git -c commit.gpgsign=false commit -qm local
git -C "$trial/peer" -c commit.gpgsign=false commit -qm remote --allow-empty
git -C "$trial/peer" push -q
git fetch -q
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '↓1'
assert_has "$_dotfiles_prompt_git" '↑1'
# Advancing the remote again must not cause the prompt to fetch it.
git -C "$trial/peer" -c commit.gpgsign=false commit -qm remote-again --allow-empty
git -C "$trial/peer" push -q
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '↓1'
DOTFILES_PROMPT_ASCII=1
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" 'git:main v1 ^1'
unset DOTFILES_PROMPT_ASCII
git checkout -qb no-upstream
_dotfiles_prompt_update
assert_lacks "$_dotfiles_prompt_git" '↓'
assert_lacks "$_dotfiles_prompt_git" '↑'
git checkout -q --detach
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" "@$(git rev-parse --short=7 HEAD)"
git checkout -q main
git worktree add -qb worktree "$trial/worktree"
cd "$trial/worktree"
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '⎇ worktree ✓'
cd "$trial/project with spaces"
git checkout -qb conflict
printf 'branch\n' > unstaged
git add unstaged
git -c commit.gpgsign=false commit -qm branch
git checkout -q main
printf 'main\n' > unstaged
git add unstaged
git -c commit.gpgsign=false commit -qm main
if git -c commit.gpgsign=false merge conflict > /dev/null 2>&1; then exit 1; fi
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '✖1'
git init -q -b unborn "$trial/unborn"
cd "$trial/unborn"
_dotfiles_prompt_update
assert_has "$_dotfiles_prompt_git" '⎇ unborn'
git checkout -qb 'literal%F{red}$(touch${IFS}MUST_NOT_EXIST)'
_dotfiles_prompt_update
if [ -n "${ZSH_VERSION:-}" ]; then
    assert_has "$_dotfiles_prompt_git" '%%F{red}'
else
    assert_has "$_dotfiles_prompt_git" '%F{red}'
fi
[ ! -e MUST_NOT_EXIST ]
printf 'PASS: %s prompt checks (%s)\n' "$checks" "${ZSH_VERSION:-bash $BASH_VERSION}"
CHECKS

mkdir "$trial/bash" "$trial/zsh"
bash --noprofile --norc "$trial/check.sh" "$repo" "$trial/bash"
if command -v zsh >/dev/null 2>&1; then
    zsh -f "$trial/check.sh" "$repo" "$trial/zsh"
else
    printf 'SKIP: zsh is unavailable\n'
fi
