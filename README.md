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

Existing files are moved to `~/.dotfiles-backups/<UTC timestamp>-<pid>/` before being replaced. Files from older setups that would interfere are moved there too, with no replacement: `.gitbin`, `.config/git/ignore`, `.emacs`, `.emacs.el`, `.spacemacs`, `.spacemacs.env`. Existing `.zshenv` settings are preserved so non-interactive shells keep their environment. Nothing is deleted. To undo, remove the link and move the saved file back.

Before switching an existing machine, merge its private SSH host definitions into `~/.ssh/config.local`, and retain machine-specific Git and shell settings in the local files below. Backups preserve the old files, but only these local files keep their settings active after installation.

To try the result in isolation, pass `--target /some/empty/dir`.

## Packages

macOS (Homebrew):

```sh
brew install git gnupg emacs llvm cmake ninja fzf ripgrep
```

Debian/Ubuntu:

```sh
sudo apt install zsh git gnupg emacs clangd cmake ninja-build lldb gdb fzf ripgrep build-essential
```

Language servers for Emacs:
- Python: `pipx install basedpyright`
- Rust: `rustup component add rust-analyzer`

Emacs 31 builds tree-sitter grammars on first use and asks first. This needs git and a C compiler. Emacs 30 (for example Debian stable) can't do this automatically: run `M-x dotfiles-install-grammars` once and restart. Until then, files open in the classic modes.

## Layout

- `shell/env.sh` is shared by sh, bash and zsh. It sets up Homebrew (`/opt/homebrew`, `/usr/local` or Linuxbrew), cargo, the Android SDK, `~/.local/bin`, the git commands below, and `EDITOR` (emacsclient, falling back to vim).
- `shell/functions.sh` holds the Docker shortcuts, prompt helpers and `conda_init`. `conda_init` loads `~/miniconda3`, `~/miniforge3`, `~/anaconda3` or a Homebrew cask install, whichever exists.
- `git/commands/` adds `git browse`, `git license`, `git getb`, `git stats` and more. Their man pages are in `git/share/man`.
- `editors/emacs/` contains `early-init.el`, `init.el` and `lisp/init-*.el`:
  - completion: vertico, orderless, marginalia, consult, corfu
  - languages: eglot with tree-sitter modes for C/C++, Python and Rust
  - C++: clangd, CMake targets, CTest, snippets and Dape debugging; see the [C++ workflow and keys](editors/emacs/README.md)
  - git: magit, diff-hl
  - projects: Projectile and Treemacs, with an `M-m` leader menu and a Magit
    branch/commit graph; see the [project and Git keys](editors/emacs/README.md#first-project)
  - Packages, grammars and caches are written next to the configuration and ignored by git.

## Docker shortcuts

Bash and zsh load a shared `docker()` function with Git-style subcommand shortcuts:

| Shortcut | Expands to |
|----------|------------|
| `docker cu` | `docker compose up -d` |
| `docker cub` | `docker compose up -d --build` |
| `docker cd` | `docker compose down` |
| `docker cl` | `docker compose logs -f --tail=100` |
| `docker ce` | `docker compose exec` |
| `docker cr` | `docker compose run --rm` |

Arguments after the shortcut are passed through, so `docker cl api` follows the
`api` service logs and `docker ce api sh` opens a shell in that service. Leading
Docker options are preserved: `docker --context remote cu api` runs
`docker --context remote compose up -d api`. Short forms such as `-cremote` and
grouped options such as `-Dc remote` also work.

Native commands, leading help/version flags and unrecognized leading options are
forwarded unchanged. Use `command docker` to bypass the shortcuts. They apply
to interactive Bash and zsh sessions; they require Docker with Compose installed.

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
sh tests/docker_test.sh
sh tests/emacs_test.sh
sh tests/emacs_cpp_test.sh
sh tests/emacs_project_test.sh
sh tests/emacs_build_test.sh
```

The installer test runs against a temporary directory and never touches `$HOME`.
The Docker test checks argument forwarding and exit statuses in Bash and zsh
using a temporary fake executable; it requires no Docker installation or daemon.
The Emacs tests use isolated configuration state and require Emacs 30+.
The C++ integration checks also use temporary CMake projects and require CMake
and a C++ compiler.
The project suite also needs the configured Emacs packages installed; it uses
temporary projects and a temporary branching Git repository.

[License](LICENSE.md)
