# Bash and Zsh prompts

The two shells share `prompt.sh` for Git status, rendering and prompt selection.
Their normal login profiles load the interactive configuration automatically;
no oh-my-zsh installation is required.

To change the current iTerm2 tab's theme, run `iterm-profile day` or
`iterm-profile night`. Run `iterm-profile` for its selector. This helper lives
in `iterm2.sh`; [profile switching details](../terminal/iterm2/README.md#switch-the-current-tab).

```sh
prompt                      # interactive simple/extended selector
prompt simple               # select and remember the one-line layout
prompt extended             # select and remember the two-line layout
prompt --session simple     # change this shell only
prompt list                 # available types and current choice
prompt current              # current type
prompt help                 # usage and Git symbol legend
```

Both Bash and Zsh complete the command's choices with TAB. The default is
`extended`. A choice made through `prompt` is saved as plain text to
`${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/prompt` and shared by new Bash/Zsh
sessions. Only the literal values `simple` and `extended` are accepted from this
file. An exported `DOTFILES_PROMPT_TYPE` overrides the saved preference.

Example layouts (colors omitted):

```text
simple:
~/Development/app [⎇ main ↓1 ↑2 !1 +2 ?1] >>

extended:
┌─[● host]─[user]─[~/Development/app:main ↓1 ↑2 !1 +2 ?1]─[14:32]: $
└─╼ < conda: environment > >>
```

The extended layout retains the original blue frame, yellow host/time, bold
neutral directory and purple `>>`. The environment appears when Conda is active.
Its first line uses `$` for an ordinary user and `#` for root. A failed command adds its exit
status, for example `✘1`. Existing Bash `PROMPT_COMMAND` and Zsh `precmd` hooks
are retained without adding duplicate prompt hooks when reloading the helper.
Conda's own prompt prefix is disabled to avoid displaying its name twice.

## Git symbols

- `⎇ main`: cyan branch; `@abc1234` replaces the branch in detached HEAD state.
- `!2`: red; two files with unstaged changes.
- `+3`: green; three files with staged changes, including staged renames/deletions.
- `?1`: yellow; one untracked file.
- `✖1`: bold red; one file with an unresolved merge conflict.
- `↓2`: blue; two upstream commits to pull.
- `↑3`: cyan; three local commits to push.
- `✓`: green; clean and synchronized with no pending status.

A file with both staged and unstaged edits contributes to both counts. Conflict
files use their own count. Repositories without an upstream omit the arrows.
Pull/push counts compare against the cached upstream: run `git fetch` to refresh
it. Rendering never fetches, pulls or pushes. Git is queried once per prompt,
without optional index locking. Outside a repository, the Git segment is empty.
Unborn branches and Git worktrees are supported.

## Options

For a session with basic fonts or no colors:

```sh
export DOTFILES_PROMPT_ASCII=1
export NO_COLOR=1
prompt --session simple
```

ASCII mode uses `git:main`, `v2` (pull), `^3` (push), `x1` (conflict) and `ok`
(clean); `!`, `+` and `?` keep their meanings. `TERM=dumb` also disables colors.
The Unicode version does not require powerline/Nerd Font glyphs.

Keep personal overrides in `~/.bashrc.local` / `~/.zshrc.local`, for example:

```sh
export DOTFILES_PROMPT_ASCII=1
prompt --session simple
```

Already-open tabs can load the helper without restarting the shell:

```sh
. "$DOTFILES/shell/prompt.sh"
. "$DOTFILES/shell/iterm2.sh"
dotfiles_prompt_init
```

Open a new tab when migrating from the old prompt, so its previous prompt hook
is also replaced by the new startup configuration.

## Tests

```sh
sh tests/prompt_test.sh
python3 tests/prompt_pty_test.py
```

The checks use temporary repositories and local-only remotes, covering staged,
unstaged and untracked changes, conflicts, renames, upstream divergence, detached
HEAD and worktrees. Real interactive shells also verify line layouts, exit
status, retained hooks and literal rendering of shell-like text in paths and
Git branch names. No personal prompt preference or Git configuration is changed.
