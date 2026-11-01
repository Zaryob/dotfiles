# Emacs

This configuration combines clangd/Eglot completion, diagnostics and refactoring
with CMake, Make and Python (setup.py/pyproject) builds, tests and Dape debugging.
It works like a CLion/VSCode-style IDE, with a command palette, so you can use it
without memorizing Emacs keys first.

The editor uses the dark Modus Vivendi theme, an installed monospace font,
Vertico/Orderless minibuffer completion, Corfu code completion and Magit for Git.
Python language servers are selected in this order: basedpyright, pyright, pylsp.
Install one separately; for example, `pipx install basedpyright`. Rust uses
`rust-analyzer` from `rustup component add rust-analyzer`.

## Install

From the dotfiles checkout:

```sh
sh install.sh --apply emacs
```

The installer links this directory to `~/.emacs.d` and backs up an existing
configuration. Restart Emacs after installing. Emacs packages install on first
startup; compilers, language servers and debug adapters are separate dependencies.

macOS with Homebrew:

```sh
xcode-select --install
brew install emacs git cmake ninja llvm ripgrep
```

The configuration finds Homebrew's clangd without adding LLVM to your shell PATH.
Debugging uses `lldb-dap` from the selected Xcode toolchain (`xcrun --find lldb-dap`),
PATH or Homebrew LLVM. Installing the `lldb` command alone is insufficient: Dape
needs a Debug Adapter Protocol executable. See the [LLDB adapter guide](https://lldb.llvm.org/use/lldbdap.html).

Debian/Ubuntu:

```sh
sudo apt install emacs git build-essential cmake ninja-build clangd lldb gdb ripgrep
```

Python debugging and tests need `debugpy` and `pytest` in the project's Python
(`python -m pip install debugpy pytest`). The debugger offers to install debugpy
when it is missing. `C-c p e` lists every tool with its install command.

Use an Emacs build with tree-sitter support, version 30 or newer. Install a recent
LLVM/LLDB package if your distribution does not provide `lldb-dap`. Versioned
`/usr/bin/lldb-dap-N` and the older `lldb-vscode` adapter are detected too. On Linux,
GDB 14.1 or newer with Python/DAP support is also supported. Check the installed
version with `gdb --version`; older distribution packages may need upgrading.

Emacs 31 asks before installing tree-sitter grammars on first use. On Emacs 30,
run `M-x dotfiles-install-grammars` and restart. Grammar installation needs Git and
a C compiler. C/C++ editing and Eglot also work in the classic modes when grammars
are unavailable.
An Emacs build without tree-sitter can still use classic C/C++ and Python modes
and CMake highlighting. Graphical `emacsclient` windows get the same font as the
initial window; macOS daemon sessions also import the login shell's PATH.

## Start here

Emacs opens on a welcome screen with buttons for projects, recent files, the
command palette and the cheatsheet. Three keys are enough to begin:

- **`C-S-p`** (Ctrl+Shift+P): the command palette, as in VSCode. Type part of a
  name, such as `break` or `rename`; each command shows its shortcut, so the
  keys come with use. In a terminal, use `M-m SPC`. Any `M-x` command name also
  runs from here.
- **`C-c ?`**: cheatsheet with the first keys to learn and every palette command
  that has a shortcut. Click a name to run it.
- **`C-g`**: cancel whatever is happening.

Right-click in code for Run, Debug, Toggle Breakpoint, Rename, Quick Fix and
Format. With text selected, `C-c`, `C-x` and `C-v` copy, cut and paste (CUA);
without a selection they remain Emacs prefixes. `C-z` / `C-S-z` undo and redo.
Add `(cua-mode -1)` to `local.el` for the classic Emacs keys.

Open files appear as tabs above the editor. Errors and warnings appear at the
end of their line; build and program output opens in a bottom panel.

## Everyday editing

- `C-x C-f`: open a file; `C-x b`: find an open buffer or recent file.
- `M-s l`: search the current buffer; `M-s r`: search with ripgrep.
- `C-x g`: open Magit; `C-c c`: compile; `C-c C`: repeat compilation.
- `C-S-j` / `C-S-l`: move a line down/up, preserving its column and final newline.
- `C-S-k`: duplicate; `C-S-d`: delete the whole line.
- `C-h k`: explain a key; `C-h v`: inspect an option. Pause after a prefix to see
  available keys through Which Key.

Personal overrides belong in `~/.emacs.d/local.el`, which loads last. Restart
Emacs after changing startup settings.

## First project

The Spacemacs-style leader is **`M-m`**, keeping ordinary Emacs editing keys.
On this macOS configuration, Meta is Command, so press Command+M, release it,
then the remaining keys. On Linux/terminal Emacs, use Alt+M (or `Esc m`).
Pause after the leader or a group key to see Which Key's available commands.

- `M-m p a`: choose a new project directory, remember it, and open Dired plus
  the Treemacs sidebar. Use a Git repository, a CMake project, or a directory
  containing an empty `.projectile` marker.
- `M-m p p`: switch to a known project. Projects directly under `~/Development`,
  `~/Projects` and `~/projects` are discovered when those directories exist.
  `M-m p D` rescans these locations; `M-m p x` forgets a project without deleting
  its files.
- `M-m p f`: find a project file; `M-m p b`: switch among its open buffers;
  `M-m p r`: recent project files; `M-m p s`: search the entire project.
- `M-m p t`: show/hide the tree. In Treemacs, `TAB` expands a directory, `RET`
  opens a file, and `?` shows help. Multiple projects can stay in the sidebar.

The tree follows the current file, watches filesystem changes, and marks Git
changes. Magit operations refresh its Git status. Projectile also makes non-VC
projects available to Emacs's built-in project system and Eglot.

## Git visualizer

- `M-m g g` (or `M-m g l`): colored commit graph across all local and remote
  refs, including branch labels and merges. The initial view shows 256 commits;
  `+` shows more. Remote refs reflect the last fetch.
- `RET` on a commit opens its changes; `q` returns to the previous view.
- `M-m g s` or `C-x g`: Magit status, staging, commits and other Git operations.
- `M-m g b`: compare branches and tags; `M-m g f`: current file's history;
  `M-m g d`: unstaged diff; `M-m g B`: blame the current file.

Other leader groups are `M-m f` for files, `M-m b` for buffers, `M-m w` for
windows (the built-in `C-x w` menu), and `M-m c` for the existing CMake commands:
`c` configure, `b` build, `t` test, `r` run, `d` debug and `s` build settings.
`M-m SPC` opens the command palette and `M-m ?` the cheatsheet; `M-m c x` cleans
and `M-m c k` stops a running build. No Vim/modal editing package is enabled.
The existing `C-c p` and `C-c d` shortcuts remain available.

## C++ project workflow

1. Open a C++ file in a project containing `CMakeLists.txt`, or use
   `C-c p p` to switch to a known project.
2. Press `C-c p c` to configure. The defaults use `build/`, a Debug build and Ninja
   when available. Configuration enables `CMAKE_EXPORT_COMPILE_COMMANDS` and
   requests CMake's File API metadata for target discovery.
3. Press `C-c p b` to build. Follow compiler errors with `M-g n` / `M-g p`, or
   `C-x \`` / `M-x previous-error`.
4. Press `C-c p t` to build and run CTest, `C-c p r` to build and run an executable, or
   `C-c p d` / `F5` to build and debug one. Choose a target when prompted and enter
   program arguments, using quotes around arguments containing spaces.

Build, run and debug commands use the configured build directory. Executable
selection comes from CMake's File API. Build, test, run and debug configure first
when needed. Run and debug wait for a successful build before launching the
chosen target; programs start with the project root as their working directory.

clangd starts automatically in C/C++ buffers when installed. It needs the correct
include paths, definitions and C++ standard from `compile_commands.json` to give
accurate results. Configuration links the build's database into the project root
when safe; existing user-owned files are preserved. CMake exports the database
with Ninja and Makefile generators. Other generators, including Xcode, do not
export it. See [clangd project setup](https://clangd.llvm.org/installation#project-setup)
and [CMake's export option](https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html).

## Make and Python projects

The build keys detect the project's build system from the nearest
`CMakeLists.txt`, then `Makefile` (`GNUmakefile`, `makefile`), then
`pyproject.toml`, `setup.py` or `setup.cfg`:

| Action | Keys | CMake | Make | Python |
| --- | --- | --- | --- | --- |
| Build | `C-S-b`, `C-F9`, `C-c p b` | `cmake --build` | `make -k -jN` | `pip install -e .` |
| Build (choose) | `C-u C-S-b` | target name | Makefile target | `setup.py build_ext --inplace`, `setup.py build`, `python -m build` |
| Run | `C-F5`, `S-F10`, `C-c p r` | executable target | chosen program, after `make` | current `.py` file |
| Test | `C-c p t` | CTest | `make test`, `check` or `tests` | pytest, else unittest |
| Debug | `F5`, `S-F9`, `C-c p d` | lldb-dap/GDB | lldb-dap/GDB, after `make` | debugpy |
| Configure | `C-c p c` | `cmake -S -B` | `./configure` (or `autogen.sh`) | create `.venv` and `pip install -e .` |
| Clean | `M-m c x` | `clean` target | `make clean` | `setup.py clean --all` |
| Stop | `S-F5`, `M-m c k` | debugger, else the running build or program | | |

A Python buffer always runs and debugs as Python, even beside a Makefile. Python
commands use the project's `.venv`, `venv` or `env` first, then `$VIRTUAL_ENV`,
then `python3`. Make projects ask for the program to run or debug once and offer
it again next time. Build programs with debug symbols (`-g`) for breakpoints.
Without any build file, `C-S-b` runs `M-x compile`.

To force one build system for a project, add it to `.dir-locals.el`:

```elisp
((nil . ((dotfiles-build-system . make))))
```

## Keys

`C-c p` extends Emacs's built-in project menu:

| Key | Action |
| --- | --- |
| `C-c p p` | Switch project |
| `C-c p f` | Find project file |
| `C-c p g` | Search project with ripgrep |
| `C-c p D` | Browse the project root in Dired |
| `C-c p c` | Configure (CMake, `./configure` or a Python virtualenv) |
| `C-c p b` | Build; `C-u C-c p b` selects a target or command |
| `C-c p t` | Build and run the tests |
| `C-c p r` | Build and run a program |
| `C-c p d` | Build and debug a program |
| `C-c p s` | Choose build directory and configuration for this session |
| `C-c p h` | Switch between source and header |
| `C-c p e` | Report installed tools, install commands and the build system |

Language features:

| Key | Action |
| --- | --- |
| `M-.` / `M-,` | Go to definition / return |
| `M-?` | Find references |
| `C-M-i` | Complete at point |
| `C-c l r` | Rename symbol across the project |
| `C-c l a` | Apply a code action or fix |
| `C-c l f` | Format buffer or selected region |
| `C-c l o` | Organize imports, when supported by the server |
| `C-c l d` | Show documentation in an Eldoc buffer |
| `C-c l i` | Toggle inlay hints |
| `M-x flymake-show-project-diagnostics` | Show diagnostics across open project buffers |

clangd runs with background indexing and clang-tidy checks. Formatting and lint
rules use the project's `.clang-format` and `.clang-tidy`. Emacs does not replace
those files or force formatting on save. See [clangd configuration](https://clangd.llvm.org/config).

C/C++ snippets come from YASnippet and `yasnippet-snippets`. Use `TAB` to expand
a snippet, or `M-x yas-expand` when completion takes precedence. Browse snippets
with `M-x yas-insert-snippet`.

Debugging:

| Key | Action |
| --- | --- |
| `F5` / `S-F9` | Start debugging (CMake, Make or Python), or continue the active session |
| `S-F5` / `C-c d q` | Quit debugging; `S-F5` also stops a running build or program |
| `F9` / `C-c d b` | Toggle breakpoint |
| `F10` / `C-c d n` | Step over |
| `F11` / `C-c d i` | Step into |
| `S-F11` / `C-c d o` | Step out |
| `C-c d c` | Continue |
| `C-c d r` | Restart session |
| `C-c d w` | Add a watch expression |
| `C-c d v` | Show debugger information buffers |
| `C-c d d` | Launch Dape manually, including custom/attach configurations |

Dape displays stack frames, local variables, watches and a debugger REPL. Build
with debug symbols, normally `Debug`, so stepping and breakpoints can map back to
the source. For other adapters, attach or remote sessions, use `M-x dape` and a
custom launch configuration; see the [Dape documentation](https://github.com/svaante/dape).

## Project settings

`C-c p s` changes the build directory and configuration for the current session.
To persist them and add configure arguments, put a `.dir-locals.el` in the
project root:

```elisp
((nil . ((dotfiles-cmake-build-directory . "build/debug")
         (dotfiles-cmake-build-type . "Debug")
         (dotfiles-cmake-configure-arguments . ("-G" "Ninja"
                                                "-DBUILD_TESTING=ON")))))
```

The build directory is relative to the project root unless it is an absolute
path. Configure arguments are a list of individual arguments, so paths containing
spaces remain one argument. Emacs may ask whether to trust project-local values;
review them before accepting. Keep personal machine paths in `.dir-locals-2.el`
or `~/.emacs.d/local.el`.

To enable formatting on save for one project, add
`(dotfiles-cpp-format-on-save . t)` to its directory-local settings. For tools in
a custom location, set explicit paths in `~/.emacs.d/local.el`:

```elisp
(setq dotfiles-cpp-clangd-executable "/path/to/llvm/bin/clangd"
      dotfiles-cpp-debug-adapter "/path/to/llvm/bin/lldb-dap")
```

For a project using a configure preset:

```elisp
((nil . ((dotfiles-cmake-build-directory . "out/build/dev")
         (dotfiles-cmake-build-type . "Debug")
         (dotfiles-cmake-configure-arguments . ("--preset" "dev")))))
```

Set the build directory to the intended preset's directory explicitly. The
commands do not resolve preset inheritance or automatically choose build/test
presets; build and test still operate on that directory and build type. Read the
project's [CMake presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)
before choosing it.

## Troubleshooting

- macOS native-compilation workers use a valid minimum deployment target to
  avoid bundled libgccjit inferring `-mmacosx-version-min=18.0` on Darwin 27.
  The setting is applied in `early-init.el` before packages start compiling.
  Explicit driver targets and `MACOSX_DEPLOYMENT_TARGET` remain respected.
- Run `C-c p e` first to inspect tool discovery and the active build directory.
- For missing headers or incorrect diagnostics, configure successfully and check
  the project's `compile_commands.json`. After changing toolchains or clangd
  settings, use `M-x eglot-reconnect`.
- If no executable is offered, check that CMake has an `add_executable` target and
  rerun configure to refresh its File API reply.
- If the selected generator differs from an existing CMake cache, choose another
  build directory with `C-c p s` before configuring.
- For a missing adapter, install `lldb-dap` or a DAP-enabled GDB 14.1+; a debugger
  CLI alone does not provide the protocol Dape needs.
- Non-CMake projects can still use clangd, `C-c c` (`compile`), `C-c C`
  (`recompile`) and manual Dape configurations. Supply a compilation database for
  the project's build system.

The CMake commands wrap the standard tools; consult the [CMake command reference](https://cmake.org/cmake/help/latest/manual/cmake.1.html)
for generator, toolchain and cache options.

## Verify the configuration

```sh
sh tests/emacs_test.sh
sh tests/emacs_cpp_test.sh
sh tests/emacs_project_test.sh
sh tests/emacs_build_test.sh
```

The editing and language tests need only Emacs 30+; they use no external packages
or network access. A native-code compilation check also runs when Emacs provides
that compiler. Set `EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs` before a
test command to check the macOS GUI application's toolchain instead of the
terminal build. The C++ integration tests also need CMake and a C++ compiler.
All suites isolate their state from your personal Emacs configuration.
The project suite uses the installed Projectile, Treemacs and Magit packages,
with temporary projects and a branching Git repository. It checks discovery,
project switching, the sidebar, search roots, key bindings and commit graphs.
It skips with exit code 77 if required packages are not installed.
The build suite builds, runs and tests real Make and Python projects and checks
the debugger configurations, key bindings, command palette and welcome screen.
