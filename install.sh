#!/bin/sh
# Install selected personal configurations. Existing destinations are moved to a backup.
set -eu
umask 077

usage() {
    echo "Usage: sh install.sh [--dry-run|--apply] [--target DIR] bash zsh git ssh emacs"
    echo "Default: dry run. Select at least one component. DIR must already exist."
}
mode=dry-run
target=${HOME:?HOME is required}
components=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run) mode=dry-run ;;
        --apply) mode=apply ;;
        --target) shift; [ "$#" -gt 0 ] || { usage; exit 2; }; target=$1 ;;
        --help|-h) usage; exit 0 ;;
        bash|zsh|git|ssh|emacs)
            case " $components " in *" $1 "*) ;; *) components="$components $1" ;; esac ;;
        *) echo "Unknown option or component: $1" >&2; usage; exit 2 ;;
    esac
    shift
done
[ -n "$components" ] || { usage; exit 2; }
[ -d "$target" ] || { echo "Target must be an existing directory" >&2; exit 2; }
target=$(CDPATH= cd -- "$target" && pwd -P)
repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
[ "$target" != "$repo" ] || { echo "Target must differ from the checkout" >&2; exit 2; }

plan=".dotfiles|$repo"
add() { plan="$plan
$1|$repo/$2"; }
for component in $components; do
    case "$component" in
        bash)
            add .bash_logout shell/bash/bash_logout
            add .bashrc shell/bash/bashrc
            add .profile shell/bash/profile ;;
        zsh)
            add .zshrc shell/zsh/zshrc
            add .zlogout shell/zsh/zlogout
            add .zprofile shell/zsh/zprofile ;;
        git)
            add .gitconfig git/gitconfig
            add .gitmessage git/gitmessage
            add .gitbin git/commands ;;
        ssh) add .ssh/config ssh/config ;;
        emacs) add .emacs.d editors/emacs ;;
    esac
done
case " $components " in
    *" bash "*|*" zsh "*) add .aliases shell/aliases; add .inputrc shell/inputrc ;;
esac

# Validate the whole plan before changing any destination.
printf '%s\n' "$plan" | while IFS='|' read -r relative source; do
    [ -e "$source" ] || { echo "Missing source: $source" >&2; exit 1; }
    parent=$(dirname "$target/$relative")
    while [ "$parent" != "$target" ]; do
        [ ! -L "$parent" ] || { echo "Refusing symlinked destination parent: $parent" >&2; exit 1; }
        [ ! -e "$parent" ] || [ -d "$parent" ] || { echo "Not a directory: $parent" >&2; exit 1; }
        parent=$(dirname "$parent")
    done
done

backup="$target/.dotfiles-backups/$(date -u +%Y%m%dT%H%M%SZ)-$$"
[ ! -L "$target/.dotfiles-backups" ] || { echo "Refusing symlinked backup directory" >&2; exit 1; }
[ ! -e "$target/.dotfiles-backups" ] || [ -d "$target/.dotfiles-backups" ] || exit 1
printf '%s\n' "$plan" | while IFS='|' read -r relative source; do
    destination="$target/$relative"
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
        echo "Already linked: $destination"
        continue
    fi
    # A checkout already installed at ~/.dotfiles is also a valid source.
    if [ "$destination" = "$repo" ]; then
        echo "Checkout already in place: $destination"
        continue
    fi
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        echo "Back up: $destination -> $backup/$relative"
        if [ "$mode" = apply ]; then
            mkdir -p "$(dirname "$backup/$relative")"
            mv "$destination" "$backup/$relative"
        fi
    fi
    echo "Link: $destination -> $source"
    if [ "$mode" = apply ]; then
        mkdir -p "$(dirname "$destination")"
        ln -s "$source" "$destination"
    fi
done
echo "Mode: $mode. Review configuration contents before starting a new shell or editor."
