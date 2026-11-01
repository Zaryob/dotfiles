#!/bin/sh
# Test Make/Python builds, debugger setup and the command palette in isolation.
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
emacs_bin=${EMACS:-emacs}
if ! command -v "$emacs_bin" >/dev/null 2>&1; then
    echo 'SKIP: Emacs is not installed' >&2
    exit 77
fi

trial=$(mktemp -d)
trap 'rm -rf "$trial"' EXIT HUP INT TERM
mkdir "$trial/emacs"
HOME="$trial" DOTFILES_BUILD_TEST_DIRECTORY="$trial/emacs/" \
    DOTFILES_BUILD_TEST_PACKAGES="$repo/editors/emacs/elpa/" \
    "$emacs_bin" -Q --batch -L "$repo/editors/emacs/lisp" \
    -l "$repo/editors/emacs/early-init.el" \
    -l "$repo/tests/emacs_build_test.el" -f ert-run-tests-batch-and-exit
