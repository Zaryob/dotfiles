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
when it is missing. `M-m c e` lists every tool with its install command.

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

Every key below works in a terminal. Meta (`M-`) is the **left Option** key in
iTerm2 (the right one still types `@`, `#`, `{`), Alt on Linux and Command in the
macOS app. Pressing `Esc` first always works too.

Emacs opens on a welcome screen with buttons for projects, recent files, the
command palette and the cheatsheet. Three keys are enough to begin:

- **`M-m`**: the menu. Everything this configuration adds is behind it. Press
  it and the groups below are listed on screen; press a group's letter and its
  commands are listed.
- **`M-m M-m`** (hold Option, tap `m` twice): the command palette. Type part of
  a name, such as `break` or `rename`; each command shows its shortcut, so the
  keys come with use. Any `M-x` command name also runs from here.
- **`C-g`**: cancel whatever is happening, including after `C-x p`, `C-x w`
  or any `M-m` menu prefix.

`M-m ?` opens a cheatsheet; press `RET` or click on a name to run it.

Emacs's own keys are untouched: `C-x C-f` opens a file, `C-x C-s` saves, `C-x b`
switches buffers, `C-x p` is the built-in project menu and `C-h k` explains a
key. With text selected, `C-c`, `C-x` and `C-v` copy, cut and paste (CUA) and
`C-z` / `M-z` undo and redo; add `(cua-mode -1)` to `local.el` for the classic
keys.

In a terminal on macOS, copy and paste use the system clipboard, so text moves
between Emacs and other applications. The mouse works: click to place the
cursor or press a button, scroll, and right-click in code for Run, Debug,
Breakpoint, Rename, Quick Fix and Format. Hold Option while dragging to select
text with iTerm2 itself.

## Keys

Every key below is defined in one file, `lisp/init-keys.el`.

| Menu | Group | Keys |
| --- | --- | --- |
| `M-m M-m` | Palette | Find any command by name |
| `M-m ?` | Cheatsheet | |
| `M-m p` | Project | `p` switch, `a` add a folder, `f` find file, `s` search, `t` tree, `b` buffers, `r` recent, `d` Dired, `D` rescan, `x` forget, `k` close its buffers |
| `M-m g` | Git | `s` status (also `C-x g`), `g` commit graph, `b` branches and tags, `f` file history, `d` unstaged diff, `B` blame |
| `M-m c` | Build | `c` configure, `b` build, `B` build a chosen target, `t` test, `r` run, `q` run this file alone, `x` clean, `k` stop, `s` CMake build directory and type, `e` check installed tools, `C` custom command, `l` repeat last |
| `M-m d` | Debug | `d` start or continue, `b` breakpoint, `n` step over, `i` step in, `o` step out, `c` continue, `r` restart, `q` quit, `w` watch, `v` variables and stack, `D` custom Dape configuration |
| `M-m e` | Edit | `p` / `n` move the line up / down, `d` duplicate, `k` delete the line, `m` add a cursor at the next match, `u` remove it, `a` cursors on all matches, `l` a cursor on each selected line, `r` redo |
| `M-m l` | Code | `r` rename, `a` quick fix, `f` format, `o` organize imports, `d` documentation, `i` inlay hints, `h` header/source |
| `M-m f` | Files | `f` open, `s` save, `r` recent |
| `M-m b` | Buffers | `b` switch, `d` close, `n` / `p` next / previous |
| `M-m w` | Windows | Emacs's `C-x w` menu |

After `M-m e p`, `n`, `d`, `m` or `u`, the last letter alone repeats: `M-m e d d d`
duplicates a line three times.

Direct keys, for what you press all day:

| Key | Action |
| --- | --- |
| `F5` / `F6` / `F7` / `F8` | Debug or continue / run / build / test |
| `F9` | Toggle breakpoint |
| `F10` / `F11` / `F12` | Step over / into / out |
| `M-<up>` / `M-<down>` | Move the line up / down |
| `C-z` / `M-z` | Undo / redo |
| `M-.` / `M-,` / `M-?` | Go to definition / back / find references |
| `M-s l` / `M-s r` | Search this buffer / the project with ripgrep |
| `M-g i` / `M-g f` | Go to a symbol / a problem in this file |
| `M-g n` / `M-g p` | Next / previous build error |

On a Mac laptop the function keys need `Fn` unless "Use F1, F2, etc. keys as
standard function keys" is on, and macOS takes `F11` for Show Desktop by
default; every one of them is also under `M-m c` or `M-m d`.
No Vim/modal editing package is enabled.

## Projects

`M-m p a` adds a project directory and opens it with the Treemacs sidebar. Use a
Git repository, a CMake project, or a directory containing an empty `.projectile`
marker. Projects directly under `~/Development`, `~/Projects` and `~/projects` are
discovered on their own. In the tree, `TAB` expands a directory, `RET` opens a
file and `?` shows help; it follows the current file and marks Git changes.
Use `C-x o` to move between the sidebar and the editor.
Graphical Emacs uses Treemacs's image icons. Terminal Emacs uses Unicode folder
and file icons, without requiring a Nerd Font.

Open files and Welcome appear as tabs above the editor. `M-m b n` / `M-m b p`
or `C-x <right>` / `C-x <left>` cycle through them in their visible order,
wrapping from the last tab to the first and back. Errors and warnings appear at the
end of their line; build and program output opens in a bottom panel.

In the commit graph (`M-m g g`), `RET` opens a commit, `+` shows more than the
first 256 and `q` goes back. Remote refs reflect the last fetch.

## Build, run, test and debug

The same keys work in every project. The build system is detected from the
nearest `CMakeLists.txt`, then `Makefile` (`GNUmakefile`, `makefile`), then
`pyproject.toml`, `setup.py` or `setup.cfg`:

| Action | Key | CMake | Make | Python |
| --- | --- | --- | --- | --- |
| Configure | `M-m c c` | `cmake -S -B` | `./configure` (or `autogen.sh`) | create `.venv` and `pip install -e .` |
| Build | `F7` | `cmake --build` | `make -k -jN` | `pip install -e .` |
| Build (choose) | `M-m c B` | target name | Makefile target | `setup.py build_ext --inplace`, `setup.py build`, `python -m build` |
| Run | `F6` | executable target | chosen program, after `make` | current `.py` file |
| Test | `F8` | CTest | `make test`, `check` or `tests` | pytest, else unittest |
| Debug | `F5` | lldb-dap/GDB | lldb-dap/GDB, after `make` | debugpy |
| Clean | `M-m c x` | `clean` target | `make clean` | `setup.py clean --all` |
| Stop | `M-m c k` | debugger, else the running build or program | | |

CMake defaults to `build/`, a Debug build and Ninja when available. Build, test,
run and debug configure first when needed; run and debug wait for a successful
build, ask for a target and program arguments, and start in the project root.
Executable targets come from CMake's File API.

A Python buffer always runs and debugs as Python, even beside a Makefile. Python
commands use the project's `.venv`, `venv` or `env` first, then `$VIRTUAL_ENV`,
then `python3`. Make projects ask for the program to run or debug once and offer
it again next time. Build programs with debug symbols (`-g`) for breakpoints.
Without any build file, `F7` runs `M-x compile`.

To force one build system for a project, add it to `.dir-locals.el`:

```elisp
((nil . ((dotfiles-build-system . make))))
```

clangd starts automatically in C/C++ buffers when installed, with background
indexing and clang-tidy checks. It needs `compile_commands.json` for accurate
results; configuring links the build's database into the project root when safe
and preserves existing user-owned files. CMake exports it with Ninja and Makefile
generators only. Formatting and lint rules use the project's `.clang-format` and
`.clang-tidy`; nothing is formatted on save unless you enable it below. See
[clangd project setup](https://clangd.llvm.org/installation#project-setup).

C/C++ snippets come from YASnippet: `TAB` expands one, `M-x yas-insert-snippet`
browses them. Dape shows stack frames, locals, watches and a debugger REPL; for
attach or remote sessions use `M-m d D` with a custom configuration, as in the
[Dape documentation](https://github.com/svaante/dape).

## Project settings

`M-m c s` changes the build directory and configuration for the current session.
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
- Run `M-m c e` first to inspect tool discovery and the active build directory.
- For missing headers or incorrect diagnostics, configure successfully and check
  the project's `compile_commands.json`. After changing toolchains or clangd
  settings, use `M-x eglot-reconnect`.
- If no executable is offered, check that CMake has an `add_executable` target and
  rerun configure to refresh its File API reply.
- If the selected generator differs from an existing CMake cache, choose another
  build directory with `M-m c s` before configuring.
- For a missing adapter, install `lldb-dap` or a DAP-enabled GDB 14.1+; a debugger
  CLI alone does not provide the protocol Dape needs.
- Non-CMake projects can still use clangd, `M-m c C` (`compile`), `M-m c l`
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
