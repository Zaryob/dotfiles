# dotfiles

Personal configuration for zsh, bash, git, ssh and Emacs, used on macOS and Linux.

| Module  | Links into `$HOME` |
|---------|--------------------|
| `zsh`   | `.zprofile`, `.zshrc`, `.zlogout` |
| `bash`  | `.bash_profile`, `.bashrc`, `.bash_logout` |
| `zsh`/`bash` (shared) | `.profile`, `.aliases`, `.inputrc`, `.condarc` |
| `git`   | `.gitconfig`, `.gitmessage` |
| `ssh`   | `.ssh/config` |
| `emacs` | `.emacs.d` |

Every module also links the checkout itself as `~/.dotfiles`; the shell, git and Emacs files refer to that path.

## Install

```sh
git clone https://github.com/Zaryob/dotfiles.git
cd dotfiles
sh install.sh --dry-run zsh bash git ssh emacs
sh install.sh --apply zsh bash git ssh emacs
```

The installer defaults to a dry run and only creates symbolic links. It installs no packages and runs no network commands.

Existing files are moved to `~/.dotfiles-backups/<UTC timestamp>-<pid>/` before being replaced. Files from older setups that would interfere are moved there too, with no replacement: `.zshenv`, `.gitbin`, `.config/git/ignore`, `.emacs`, `.emacs.el`, `.spacemacs`, `.spacemacs.env`. Nothing is deleted. To undo, remove the link and move the saved file back.

To try the result in isolation, pass `--target /some/empty/dir`.

## Packages

macOS (Homebrew):

```sh
brew install git gnupg emacs llvm fzf ripgrep
```

Debian/Ubuntu:

```sh
sudo apt install zsh git gnupg emacs clangd fzf ripgrep build-essential
```

Language servers for Emacs:
- Python: `pipx install basedpyright`
- Rust: `rustup component add rust-analyzer`

Emacs builds tree-sitter grammars on first use and asks first. This needs git and a C compiler.

## Layout

- `shell/env.sh` is shared by sh, bash and zsh. It sets up Homebrew (`/opt/homebrew`, `/usr/local` or Linuxbrew), cargo, the Android SDK, `~/.local/bin`, the git commands below, and `EDITOR` (emacsclient, falling back to vim).
- `shell/functions.sh` holds the prompt helpers and `conda_init`. `conda_init` loads `~/miniconda3`, `~/miniforge3`, `~/anaconda3` or a Homebrew cask install, whichever exists.
- `git/commands/` adds `git browse`, `git license`, `git getb`, `git stats` and more. Their man pages are in `git/share/man`.
- `editors/emacs/` contains `early-init.el`, `init.el` and `lisp/init-*.el`:
  - completion: vertico, orderless, marginalia, consult, corfu
  - languages: eglot with tree-sitter modes for C/C++, Python and Rust
  - git: magit, diff-hl
  - Packages, grammars and caches are written next to the configuration and ignored by git.

## Machine-specific settings

These files are read if they exist and are never tracked:

| File | Used for |
|------|----------|
| `~/.zshrc.local`, `~/.bashrc.local` | extra shell settings |
| `~/.gitconfig.local` | for example `gpg.program` or a work identity |
| `~/.ssh/config.local` | private hosts (read before the shared settings) |
| `~/.emacs.d/local.el` | extra Emacs settings |

## Migrating from Spacemacs and oh-my-zsh

1. Install the `emacs` module. It moves `~/.emacs.d`, `~/.spacemacs` and `~/.spacemacs.env` into the backup directory.
2. Install the `zsh` module, then open a new terminal. oh-my-zsh is no longer loaded. Once you are happy with the new setup, delete `~/.oh-my-zsh` yourself.
3. Old completion dumps (`~/.zcompdump*`) can be deleted. The new one lives in `~/.cache/zsh/`.

## Tests

```sh
sh tests/install_test.sh
```

The test runs the installer against a temporary directory and never touches `$HOME`.

[License](LICENSE.md)
