# Environment shared by sh, bash and zsh (sourced from profile, bash_profile,
# bashrc, zprofile and zshrc). POSIX only; safe to source more than once.

DOTFILES=${DOTFILES:-$HOME/.dotfiles}
export DOTFILES

path_prepend() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

# Homebrew: Apple silicon, Intel macOS, Linuxbrew.
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
    for brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$brew" ]; then
            eval "$("$brew" shellenv)"
            break
        fi
    done
    unset brew
fi

[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

case "$(uname -s)" in
    Darwin) android_sdk=$HOME/Library/Android/sdk ;;
    *) android_sdk=$HOME/Android/Sdk ;;
esac
if [ -d "$android_sdk" ]; then
    export ANDROID_HOME="$android_sdk"
    path_prepend "$android_sdk/cmdline-tools/latest/bin"
    path_prepend "$android_sdk/platform-tools"
fi
unset android_sdk

path_prepend "$HOME/.ghcup/bin"
path_prepend "$DOTFILES/git/commands"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
export PATH

# A leading or trailing ':' keeps the system man path.
case ":${MANPATH:-}:" in
    *":$DOTFILES/git/share/man:"*) ;;
    *) MANPATH="$DOTFILES/git/share/man:${MANPATH:-}" ;;
esac
export MANPATH

export PAGER=less
export LESS=-R
if command -v emacsclient >/dev/null 2>&1; then
    export EDITOR="emacsclient -t -a ''"
    export VISUAL="$EDITOR"
else
    export EDITOR=vim
    export VISUAL=vim
fi
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
