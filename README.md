# dotfiles

Personal UNIX/Linux configuration files by Zaryob. These are historical, machine-specific settings, not a supported general-purpose desktop distribution.

## Review and install selected files

Clone the repository and inspect the settings before using them. In particular, Git identity, SSH hosts, editor packages and shell paths are personal configuration.

```sh
git clone https://github.com/Zaryob/dotfiles.git
cd dotfiles
less install.sh
sh install.sh --dry-run bash git
sh install.sh --apply bash git
```

The installer defaults to a dry run. Select one or more of `bash`, `zsh`, `git`, `ssh`, `emacs`. It links the current checkout; it downloads nothing and does not initialize submodules or build editor packages.

Existing destinations, including broken symbolic links, are moved to `~/.dotfiles-backups/<UTC timestamp>-<process id>/` before replacement. Already-correct links are left alone. Symlinked destination parents are rejected. The script validates all selected sources before making changes.

To restore a backed-up file, stop the affected application, remove only the installed link after inspecting it, and move the saved file back to its original path. Keep the checkout while its links are in use. Backups are private (`umask 077`); no automatic cleanup deletes them.

For an isolated trial, create a temporary directory yourself and pass `--target /path/to/trial`. This changes the link destination only; configuration contents may still refer to your real home and must not be executed as part of a trial.

## Scope and verification

The installation script uses POSIX shell, `readlink`, `mv`, `ln` and ordinary directory tools. It is tested with temporary target directories; this does not verify every configuration on Linux, macOS, FreeBSD or illumos. There is no supported OS/version matrix yet.

The old interactive installer and its automatic cloning are retained in Git history. Fonts, i3/XDM system configuration, editor submodule setup and service scripts require manual review; the current installer does not modify `/etc`, install packages or run system services.

Run installer regression checks without changing your home:

```sh
sh tests/install_test.sh
```

## Other configurations and attribution

The collection includes neofetch, ncmpcpp/mpd, XDM and experimental system/service settings. Some editor/shell files are intended for use with [skwp's dotfiles](https://github.com/skwp/dotfiles); original upstream credit and submodule references remain in the repository.

[License](LICENSE.md)
