# Switch the current iTerm2 session's profile using its native OSC command.
# This changes appearance/session settings; it does not restart the shell.

iterm-profile() {
    local iterm_choice=${1:-select} iterm_shell iterm_name
    [ "$#" -le 1 ] || { printf '%s\n' 'Usage: iterm-profile [day|night|list|help]' >&2; return 2; }
    case "$iterm_choice" in
        help|--help|-h)
            printf '%s\n' "iterm-profile day|night: switch this tab to the current shell's Dotfiles profile." \
                'iterm-profile: interactive selector.  iterm-profile list: profile names.' \
                'The running shell and current directory are preserved.'
            return 0 ;;
        list)
            printf '%s\n' 'Dotfiles Zsh Night' 'Dotfiles Zsh Day' 'Dotfiles Bash Night' 'Dotfiles Bash Day'
            return 0 ;;
    esac
    if [ "${TERM_PROGRAM:-}" != iTerm.app ] && [ -z "${ITERM_SESSION_ID:-}" ]; then
        printf '%s\n' 'iterm-profile: run this command inside an iTerm2 tab.' >&2
        return 1
    fi
    # Multiplexers can filter OSC commands. Avoid pretending a switch succeeded.
    if [ -n "${TMUX:-}${STY:-}" ]; then
        printf '%s\n' 'iterm-profile: run outside tmux/screen in the iTerm2 tab.' >&2
        return 1
    fi
    if [ "$iterm_choice" = select ]; then
        printf '1) night\n2) day\nChoose [1/2, Enter to cancel]: '
        IFS= read -r iterm_choice || return 1
        case "$iterm_choice" in 1) iterm_choice=night ;; 2) iterm_choice=day ;; '') return 0 ;; esac
    fi
    if [ -n "${ZSH_VERSION:-}" ]; then iterm_shell=Zsh; else iterm_shell=Bash; fi
    case "$iterm_choice" in
        day|Day) iterm_name="Dotfiles $iterm_shell Day" ;;
        night|Night) iterm_name="Dotfiles $iterm_shell Night" ;;
        'Dotfiles Zsh Day'|'Dotfiles Zsh Night'|'Dotfiles Bash Day'|'Dotfiles Bash Night')
            iterm_name=$iterm_choice ;;
        *) printf 'Unknown iTerm2 profile: %s (use day or night)\n' "$iterm_choice" >&2; return 2 ;;
    esac
    # Only fixed profile names reach the terminal control sequence.
    printf '\033]1337;SetProfile=%s\007' "$iterm_name"
}

_dotfiles_iterm_profile_complete() {
    compadd day night list help
}

if [ -n "${ZSH_VERSION:-}" ]; then
    if command -v compdef >/dev/null 2>&1; then
        compdef _dotfiles_iterm_profile_complete iterm-profile
    fi
else
    complete -W 'day night list help' iterm-profile
fi
