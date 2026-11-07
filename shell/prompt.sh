# Shared prompt helper for Bash 3.2+ and zsh. No framework or special font needed.
# Git data stays in variables, never in executable PS1/PROMPT substitutions.

_dotfiles_prompt_git_state() {
    _dotfiles_prompt_git=
    _dotfiles_prompt_git_inline=
    _dotfiles_prompt_git_branch='' _dotfiles_prompt_git_open='' _dotfiles_prompt_git_close=''
    _dotfiles_prompt_git_inline_open=
    _dotfiles_prompt_git_ahead='' _dotfiles_prompt_git_behind='' _dotfiles_prompt_git_conflicts=''
    _dotfiles_prompt_git_unstaged='' _dotfiles_prompt_git_staged='' _dotfiles_prompt_git_untracked=''
    _dotfiles_prompt_git_clean=
    local prompt_git_output prompt_line prompt_xy prompt_head prompt_oid
    local prompt_staged=0 prompt_unstaged=0 prompt_untracked=0 prompt_conflicts=0
    local prompt_ahead=0 prompt_behind=0 prompt_counts prompt_label prompt_marks=
    prompt_head='' prompt_oid=''
    prompt_git_output=$(GIT_OPTIONAL_LOCKS=0 command git -c color.status=false \
        status --porcelain=v2 --branch --untracked-files=normal 2>/dev/null) || return 0
    while IFS= read -r prompt_line; do
        case "$prompt_line" in
            '# branch.head '*) prompt_head=${prompt_line#\# branch.head } ;;
            '# branch.oid '*) prompt_oid=${prompt_line#\# branch.oid } ;;
            '# branch.ab '*)
                prompt_counts=${prompt_line#\# branch.ab }
                prompt_ahead=${prompt_counts%% *}; prompt_ahead=${prompt_ahead#+}
                prompt_behind=${prompt_counts##* }; prompt_behind=${prompt_behind#-} ;;
            '1 '*|'2 '*)
                prompt_xy=${prompt_line#? }; prompt_xy=${prompt_xy%% *}
                [ "${prompt_xy%?}" = . ] || prompt_staged=$((prompt_staged + 1))
                [ "${prompt_xy#?}" = . ] || prompt_unstaged=$((prompt_unstaged + 1)) ;;
            '? '*) prompt_untracked=$((prompt_untracked + 1)) ;;
            'u '*) prompt_conflicts=$((prompt_conflicts + 1)) ;;
        esac
    done <<EOF
$prompt_git_output
EOF
    [ -n "$prompt_head" ] || return 0
    case "$prompt_head" in
        '(detached)') prompt_head="@${prompt_oid:0:7}" ;;
    esac
    if [ "${DOTFILES_PROMPT_ASCII:-0}" = 1 ]; then
        prompt_label="git:$prompt_head"
        _dotfiles_prompt_git_open=" [git:"
        if [ "$prompt_behind" -ne 0 ]; then
            _dotfiles_prompt_git_behind=" v$prompt_behind"
            prompt_marks="$prompt_marks$_dotfiles_prompt_git_behind"
        fi
        if [ "$prompt_ahead" -ne 0 ]; then
            _dotfiles_prompt_git_ahead=" ^$prompt_ahead"
            prompt_marks="$prompt_marks$_dotfiles_prompt_git_ahead"
        fi
        if [ "$prompt_conflicts" -ne 0 ]; then
            _dotfiles_prompt_git_conflicts=" x$prompt_conflicts"
            prompt_marks="$prompt_marks$_dotfiles_prompt_git_conflicts"
        fi
    else
        prompt_label="⎇ $prompt_head"
        _dotfiles_prompt_git_open=" [⎇ "
        if [ "$prompt_behind" -ne 0 ]; then
            _dotfiles_prompt_git_behind=" ↓$prompt_behind"
            prompt_marks="$prompt_marks$_dotfiles_prompt_git_behind"
        fi
        if [ "$prompt_ahead" -ne 0 ]; then
            _dotfiles_prompt_git_ahead=" ↑$prompt_ahead"
            prompt_marks="$prompt_marks$_dotfiles_prompt_git_ahead"
        fi
        if [ "$prompt_conflicts" -ne 0 ]; then
            _dotfiles_prompt_git_conflicts=" ✖$prompt_conflicts"
            prompt_marks="$prompt_marks$_dotfiles_prompt_git_conflicts"
        fi
    fi
    if [ "$prompt_unstaged" -ne 0 ]; then
        _dotfiles_prompt_git_unstaged=" !$prompt_unstaged"
        prompt_marks="$prompt_marks$_dotfiles_prompt_git_unstaged"
    fi
    if [ "$prompt_staged" -ne 0 ]; then
        _dotfiles_prompt_git_staged=" +$prompt_staged"
        prompt_marks="$prompt_marks$_dotfiles_prompt_git_staged"
    fi
    if [ "$prompt_untracked" -ne 0 ]; then
        _dotfiles_prompt_git_untracked=" ?$prompt_untracked"
        prompt_marks="$prompt_marks$_dotfiles_prompt_git_untracked"
    fi
    if [ -z "$prompt_marks" ]; then
        if [ "${DOTFILES_PROMPT_ASCII:-0}" = 1 ]; then
            prompt_marks=' ok'
        else
            prompt_marks=' ✓'
        fi
    fi
    case "$prompt_marks" in ' ok'|' ✓') _dotfiles_prompt_git_clean=$prompt_marks ;; esac
    _dotfiles_prompt_git_branch=$prompt_head
    _dotfiles_prompt_git_close=']'
    _dotfiles_prompt_git_inline_open=':'
    _dotfiles_prompt_git=" [$prompt_label$prompt_marks]"
    _dotfiles_prompt_git_inline=":$prompt_head$prompt_marks"
    # zsh expands percent escapes after parameter substitution.
    if [ -n "${ZSH_VERSION:-}" ]; then
        _dotfiles_prompt_git_branch=${_dotfiles_prompt_git_branch//\%/%%}
        _dotfiles_prompt_git=${_dotfiles_prompt_git//\%/%%}
        _dotfiles_prompt_git_inline=${_dotfiles_prompt_git_inline//\%/%%}
    fi
}

_dotfiles_prompt_update() {
    local prompt_exit_code=$?
    _dotfiles_prompt_error=
    _dotfiles_prompt_conda=
    _dotfiles_prompt_conda_extended=
    if [ "$prompt_exit_code" -ne 0 ]; then
        if [ "${DOTFILES_PROMPT_ASCII:-0}" = 1 ]; then
            _dotfiles_prompt_error="x$prompt_exit_code "
        else
            _dotfiles_prompt_error="✘$prompt_exit_code "
        fi
    fi
    if [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
        _dotfiles_prompt_conda="(${CONDA_DEFAULT_ENV##*/}) "
        _dotfiles_prompt_conda_extended="< conda: ${CONDA_DEFAULT_ENV##*/} > "
        if [ -n "${ZSH_VERSION:-}" ]; then
            _dotfiles_prompt_conda=${_dotfiles_prompt_conda//\%/%%}
            _dotfiles_prompt_conda_extended=${_dotfiles_prompt_conda_extended//\%/%%}
        fi
    fi
    _dotfiles_prompt_git_state
    return 0
}

# PS1 templates deliberately defer expansion of the data variables.
# shellcheck disable=SC2016
_dotfiles_prompt_apply() {
    local prompt_reset='' prompt_blue='' prompt_user_color='' prompt_yellow='' prompt_red=''
    local prompt_magenta='' prompt_bold='' prompt_cyan='' prompt_green=''
    local prompt_git_body prompt_git_simple prompt_git_inline
    local prompt_path prompt_user prompt_host prompt_clock prompt_symbol prompt_newline
    local prompt_top='┌─' prompt_join='─' prompt_bottom='└─╼ ' prompt_bullet='●'
    if [ "${DOTFILES_PROMPT_ASCII:-0}" = 1 ]; then
        prompt_top='+--'; prompt_join='-'; prompt_bottom='+-> '; prompt_bullet='*'
    fi
    if [ -n "${ZSH_VERSION:-}" ]; then
        prompt_path='%~'; prompt_user='%n'; prompt_host='%m'; prompt_clock='%T'
        prompt_symbol='%(!.#.$)'; prompt_newline=$'\n'
        if [ "${TERM:-dumb}" != dumb ] && [ -z "${NO_COLOR:-}" ]; then
            prompt_reset='%f%b'; prompt_blue='%F{blue}'; prompt_user_color='%F{green}'
            prompt_yellow='%F{yellow}'; prompt_red='%F{red}'
            prompt_magenta='%F{magenta}'; prompt_bold='%B'
            prompt_cyan='%F{cyan}'; prompt_green='%F{green}'
        fi
    else
        prompt_path='\w'; prompt_user='\u'; prompt_host='\h'; prompt_clock='\A'
        prompt_symbol='\$'; prompt_newline='\n'
        if [ "${TERM:-dumb}" != dumb ] && [ -z "${NO_COLOR:-}" ]; then
            prompt_reset='\[\e[0m\]'; prompt_blue='\[\e[34m\]'
            prompt_user_color='\[\e[36m\]'; prompt_yellow='\[\e[33m\]'; prompt_red='\[\e[31m\]'
            prompt_magenta='\[\e[35m\]'; prompt_bold='\[\e[1m\]'
            prompt_cyan='\[\e[36m\]'; prompt_green='\[\e[32m\]'
        fi
    fi
    # Color escapes stay in the template; branch names remain literal data.
    prompt_git_body="${prompt_cyan}"'${_dotfiles_prompt_git_branch}'\
"${prompt_blue}"'${_dotfiles_prompt_git_behind}'\
"${prompt_cyan}"'${_dotfiles_prompt_git_ahead}'\
"${prompt_bold}${prompt_red}"'${_dotfiles_prompt_git_conflicts}'\
"${prompt_reset}${prompt_red}"'${_dotfiles_prompt_git_unstaged}'\
"${prompt_green}"'${_dotfiles_prompt_git_staged}'\
"${prompt_yellow}"'${_dotfiles_prompt_git_untracked}'\
"${prompt_green}"'${_dotfiles_prompt_git_clean}'"${prompt_reset}"
    prompt_git_simple='${_dotfiles_prompt_git_open}'"${prompt_git_body}"'${_dotfiles_prompt_git_close}'
    prompt_git_inline='${_dotfiles_prompt_git_inline_open}'"${prompt_git_body}"
    case "$DOTFILES_PROMPT_TYPE" in
        simple)
            PS1='${_dotfiles_prompt_conda}'"${prompt_bold}${prompt_path}${prompt_reset}${prompt_git_simple} ${prompt_red}"'${_dotfiles_prompt_error}'"${prompt_reset}${prompt_bold}${prompt_magenta}>>${prompt_reset} " ;;
        extended)
            # Preserve the original host/user/path/time frame and purple chevrons.
            PS1="${prompt_blue}${prompt_top}[${prompt_reset}${prompt_bold}${prompt_yellow}${prompt_bullet} ${prompt_host}${prompt_reset}${prompt_blue}]${prompt_join}[${prompt_reset}${prompt_bold}${prompt_user_color}${prompt_user}${prompt_reset}${prompt_blue}]${prompt_join}[${prompt_reset}${prompt_bold}${prompt_path}${prompt_reset}"
            PS1="${PS1}${prompt_git_inline}${prompt_blue}]${prompt_join}${prompt_reset}[${prompt_bold}${prompt_yellow}${prompt_clock}${prompt_reset}]${prompt_red}"'${_dotfiles_prompt_error:+ }${_dotfiles_prompt_error% }'
            PS1="${PS1}${prompt_reset}: ${prompt_symbol}${prompt_newline}${prompt_blue}${prompt_bottom}${prompt_reset}${prompt_yellow}"'${_dotfiles_prompt_conda_extended}'"${prompt_reset}${prompt_bold}${prompt_magenta}>>${prompt_reset} " ;;
    esac
}

_dotfiles_prompt_save() (
    umask 077
    prompt_directory=${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles
    mkdir -p "$prompt_directory" || return 1
    prompt_temporary=$(mktemp "$prompt_directory/.prompt.XXXXXX") || return 1
    trap 'rm -f "$prompt_temporary"' EXIT
    printf '%s\n' "$1" > "$prompt_temporary" &&
        mv -f "$prompt_temporary" "$prompt_directory/prompt"
)

prompt() {
    local prompt_save=true prompt_choice
    if [ "${1:-}" = --session ]; then
        prompt_save=false
        shift
    fi
    [ "$#" -le 1 ] || { printf '%s\n' 'Usage: prompt [--session] [simple|extended|list|current|help]' >&2; return 2; }
    prompt_choice=${1:-select}
    case "$prompt_choice" in
        help|--help|-h)
            printf '%s\n' 'prompt: choose simple or extended (saved for Bash and zsh).' \
                '  prompt                 interactive selector' \
                '  prompt simple          one line: directory, Git and exit status' \
                '  prompt extended        two lines: user, host, directory, Git and time' \
                '  prompt --session TYPE  change only this session' \
                '  prompt list | current  list choices or show the active type' \
                'Git: ! unstaged, + staged, ? untracked, ✖ conflicts, ↓ pull, ↑ push, ✓ clean.' \
                'Pull/push counts use the cached upstream; the prompt never fetches.'
            return 0 ;;
        current) printf '%s\n' "$DOTFILES_PROMPT_TYPE"; return 0 ;;
        list)
            printf 'simple    directory + Git (one line)\nextended  user@host + directory + Git + time (two lines)\nCurrent: %s\n' "$DOTFILES_PROMPT_TYPE"
            return 0 ;;
        select)
            printf '1) simple\n2) extended\nCurrent: %s\nChoose [1/2, Enter to cancel]: ' "$DOTFILES_PROMPT_TYPE"
            IFS= read -r prompt_choice || return 1
            case "$prompt_choice" in
                1) prompt_choice=simple ;;
                2) prompt_choice=extended ;;
                '') return 0 ;;
            esac ;;
    esac
    case "$prompt_choice" in
        simple|extended) ;;
        *) printf 'Unknown prompt type: %s (use simple or extended)\n' "$prompt_choice" >&2; return 2 ;;
    esac
    if [ "$prompt_save" = true ]; then
        _dotfiles_prompt_save "$prompt_choice" || return 1
    fi
    DOTFILES_PROMPT_TYPE=$prompt_choice
    export DOTFILES_PROMPT_TYPE
    _dotfiles_prompt_apply
}

_dotfiles_prompt_complete() {
    compadd simple extended list current help --session
}

dotfiles_prompt_init() {
    local prompt_saved prompt_hook
    if [ -z "${DOTFILES_PROMPT_TYPE:-}" ]; then
        if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/prompt" ]; then
            IFS= read -r prompt_saved < "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/prompt" || prompt_saved=
            case "$prompt_saved" in simple|extended) DOTFILES_PROMPT_TYPE=$prompt_saved ;; esac
        fi
    fi
    case "${DOTFILES_PROMPT_TYPE:-}" in
        simple|extended) ;;
        *) DOTFILES_PROMPT_TYPE=extended ;;
    esac
    export DOTFILES_PROMPT_TYPE
    # This helper displays the environment, including after `conda activate`.
    export CONDA_CHANGEPS1=false
    if [ -n "${ZSH_VERSION:-}" ]; then
        setopt prompt_subst
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd _dotfiles_prompt_update
        if command -v compdef >/dev/null 2>&1; then
            compdef _dotfiles_prompt_complete prompt
        fi
    else
        shopt -s promptvars
        case "$(declare -p PROMPT_COMMAND 2>/dev/null)" in
            'declare -a '*)
                local -a prompt_hooks
                prompt_hooks=()
                for prompt_hook in ${PROMPT_COMMAND[@]+"${PROMPT_COMMAND[@]}"}; do
                    [ "$prompt_hook" = _dotfiles_prompt_update ] || prompt_hooks+=("$prompt_hook")
                done
                PROMPT_COMMAND=(_dotfiles_prompt_update ${prompt_hooks[@]+"${prompt_hooks[@]}"}) ;;
            *)
                case "${PROMPT_COMMAND:-}" in
                    _dotfiles_prompt_update|_dotfiles_prompt_update'; '*) ;;
                    *)
                        # This branch handles the scalar form, not the array form above.
                        # shellcheck disable=SC2178,SC2128
                        PROMPT_COMMAND="_dotfiles_prompt_update${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
                esac ;;
        esac
        complete -W 'simple extended list current help --session' prompt
    fi
    _dotfiles_prompt_update
    _dotfiles_prompt_apply
}
