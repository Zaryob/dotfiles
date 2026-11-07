# iTerm2 themes and login profiles

`Dotfiles Night` is a dark palette; `Dotfiles Day` is a light palette. Each has
a full 16-color ANSI palette plus foreground, background, selection and cursor
colors. Day uses a white background, dark foreground and deeper accent colors.
Its profile enables minimum contrast and disables cursor dimming and automatic
brightening of bold colors. ANSI white remains white for applications that use
it as a background. Both use the built-in Menlo font and ordinary Unicode
symbols; a Nerd Font is optional.

## Install

From the checkout on macOS:

```sh
sh install.sh --dry-run zsh bash iterm2
sh install.sh --apply zsh bash iterm2
```

The shell components install their existing login/interactive startup files.
The iTerm2 component installs:

- `~/Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json`
- `~/.config/iterm2/themes/`

The installer backs up existing destinations. Other dynamic profile files and
the default iTerm2 profile are kept. The dynamic profile names are:

- `Dotfiles Zsh Night` / `Dotfiles Zsh Day`: `/bin/zsh -l`
- `Dotfiles Bash Night` / `Dotfiles Bash Day`: `/bin/bash -l`

Open **Profiles** in iTerm2 and select one. The profiles start in your home
directory with their complete color palette, Menlo 13 and 10,000 lines of
scrollback. macOS's system Bash 3.2 is supported. To use Homebrew Bash, duplicate
the profile in iTerm2 and set its command to your installed Bash path plus `-l`.

iTerm2 watches its [DynamicProfiles directory](https://iterm2.com/documentation-dynamic-profiles.html)
for changes. Reopen the Profiles menu or restart iTerm2 if a new entry is not
shown. Dynamic profiles inherit unspecified settings from the default profile.
Their stable GUIDs let updates retain the same profile identities.

## Switch the current tab

```sh
iterm-profile day            # current shell's Dotfiles Day profile
iterm-profile night          # current shell's Dotfiles Night profile
iterm-profile                # interactive selector
iterm-profile list           # all four profile names
iterm-profile "Dotfiles Zsh Day"
```

`day` and `night` select the Bash or Zsh profile matching the shell currently
running. The helper sends iTerm2's native
[SetProfile escape sequence](https://iterm2.com/documentation-escape-codes.html).
It changes the active session's profile while retaining its running shell,
working directory and history. Switching to a Bash-named profile from Zsh
does not start Bash; its startup command applies when creating a new session.
Run this helper directly in iTerm2, outside tmux/screen.

For a tab that was already open before installing the helper:

```sh
. "$DOTFILES/shell/iterm2.sh"
iterm-profile day
```

Profile changes are local to the current session. They do not change the
separately saved `simple`/`extended` shell prompt preference.

## Use a theme with an existing profile

In **Settings → Profiles → Colors → Color Presets → Import**, select a
`.itermcolors` file from `~/.config/iterm2/themes/`, then choose that preset.
The four supplied dynamic profiles already include the colors, so importing is
only needed for other profiles. Edit `profiles.json` through the generator, or
duplicate a profile for personal changes in the iTerm2 UI.

## Choose the shell prompt

In a new Bash or Zsh tab, run `prompt` for the selector, `prompt simple` for one
line or `prompt extended` for two lines. Both shells use the same saved choice.
See [the prompt helper documentation](../../shell/README.md).

## Change the palettes

`palettes.json` is the color source. Regenerate both native presets and the
dynamic profiles after editing it:

```sh
python3 terminal/iterm2/generate_profiles.py
python3 tests/iterm2_test.py
```

Python is only needed for generation and tests. Installation and shell startup
use the checked-in artifacts directly.

The generator also notifies iTerm2's watched directory when the installed
profile is a symlink into this checkout. Select the profile again with
`iterm-profile day` to apply regenerated settings to an existing tab.
