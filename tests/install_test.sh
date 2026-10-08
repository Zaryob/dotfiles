#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
trial=$(mktemp -d)
trap 'rm -rf "$trial"' EXIT HUP INT TERM
mkdir "$trial/home with spaces"
target="$trial/home with spaces"
printf 'keep me\n' > "$target/.bashrc"
sh "$repo/install.sh" --dry-run --target "$target" bash > "$trial/dry.log"
[ "$(cat "$target/.bashrc")" = 'keep me' ]
[ ! -e "$target/.dotfiles" ]
[ ! -e "$target/.dotfiles-backups" ]
sh "$repo/install.sh" --apply --target "$target" bash > "$trial/apply.log"
[ -L "$target/.bashrc" ]
[ "$(cat "$target"/.dotfiles-backups/*/.bashrc)" = 'keep me' ]
sh "$repo/install.sh" --apply --target "$target" bash > "$trial/repeat.log"
[ "$(ls "$target/.dotfiles-backups" | wc -l | tr -d ' ')" = 1 ]
ln -s "$trial/missing" "$target/.zshrc"
sh "$repo/install.sh" --apply --target "$target" zsh > "$trial/zsh.log"
[ -L "$target/.zshrc" ]
found=false
for backup in "$target"/.dotfiles-backups/*/.zshrc; do
    if [ -L "$backup" ] && [ "$(readlink "$backup")" = "$trial/missing" ]; then found=true; fi
done
[ "$found" = true ]
mkdir "$trial/elsewhere"
ln -s "$trial/elsewhere" "$target/.ssh"
if sh "$repo/install.sh" --apply --target "$target" ssh > "$trial/refuse.log" 2>&1; then
    echo 'Expected symlink-parent rejection' >&2; exit 1
fi
[ ! -e "$trial/elsewhere/config" ]
if sh "$repo/install.sh" --apply --target "$target" unknown > "$trial/invalid.log" 2>&1; then
    echo 'Expected invalid-component rejection' >&2; exit 1
fi
echo 'PASS: dry run, backup, idempotence, spaces, broken links and unsafe-parent rejection'
