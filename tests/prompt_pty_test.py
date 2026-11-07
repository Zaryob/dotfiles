#!/usr/bin/env python3
"""Check actual prompt expansion in Bash and zsh, including hostile Git labels."""
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import time

repo = Path(__file__).resolve().parents[1]


def check(shell, arguments):
    with tempfile.TemporaryDirectory(prefix="prompt pty ") as trial:
        root = Path(trial).resolve() / 'path$(touch${IFS}PATH_EXECUTED)%F{red}'
        root.mkdir()
        branch = 'literal%F{red}$(touch${IFS}BRANCH_EXECUTED)'
        env = {**os.environ, "HISTFILE": "/dev/null", "TERM": "xterm-256color",
               "NO_COLOR": "1", "DOTFILES_PROMPT_ASCII": "1",
               "DOTFILES_PROMPT_TYPE": "simple", "XDG_CONFIG_HOME": str(Path(trial) / "config"),
               "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null"}
        subprocess.run(["git", "init", "-q", "-b", branch, str(root)], env=env, check=True)
        for index in range(17):
            (root / f"tracked-{index}").write_text("initial\n")
        subprocess.run(["git", "-C", str(root), "add", "."], env=env, check=True)
        subprocess.run(["git", "-C", str(root), "-c", "user.name=Prompt Test", "-c",
                        "user.email=test@example.invalid", "-c", "commit.gpgsign=false",
                        "commit", "-qm", "initial"], env=env, check=True)
        for index in range(17):
            (root / f"tracked-{index}").write_text("edited\n")
        subprocess.run(["git", "-C", str(root), "add", "tracked-0"], env=env, check=True)
        (root / "tracked-0").write_text("edited again\n")
        for index in range(5):
            (root / f"untracked-{index}").write_text("new\n")
        pid, terminal = pty.fork()
        if pid == 0:
            os.chdir(root)
            os.execve(shell, [shell, *arguments], env)
        pending = b""
        fcntl.ioctl(terminal, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 240, 0, 0))

        def send(command):
            os.write(terminal, (command + "\n").encode())

        def until(marker):
            nonlocal pending
            deadline = time.monotonic() + 10
            while marker not in pending:
                remaining = deadline - time.monotonic()
                if remaining <= 0 or not select.select([terminal], [], [], remaining)[0]:
                    raise AssertionError(f"{shell}: timed out waiting for {marker!r}: {pending!r}")
                try:
                    chunk = os.read(terminal, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        raise AssertionError(f"{shell} exited: {pending!r}") from error
                    raise
                if not chunk:
                    raise AssertionError(f"{shell} exited: {pending!r}")
                pending += chunk
            end = pending.index(marker) + len(marker)
            result, pending = pending[:end], pending[end:]
            return result.decode(errors="replace")

        symbol = b">> "
        try:
            hooks = ("precmd_functions=(old_hook)" if "zsh" in shell else "PROMPT_COMMAND=old_hook")
            send(f". {shlex.quote(str(repo / 'shell/prompt.sh'))}; old_hook() {{ return 0; }}; "
                 f"{hooks}; dotfiles_prompt_init; printf '\\nREADY_FOR_PROMPT\\n'")
            until(b"\r\nREADY_FOR_PROMPT\r\n")
            simple = until(symbol)
            assert branch in simple, (shell, simple)
            assert str(root) in simple, (shell, simple)
            assert "[git:" in simple, (shell, simple)
            assert "\x1b[3" not in simple, (shell, simple)
            send("false")
            failed = until(symbol)
            assert "x1 " in failed, (shell, failed)
            send("true")
            successful = until(symbol)
            assert "x1 " not in successful, (shell, successful)
            send("prompt --session extended")
            extended = until(symbol)
            assert "+--[* " in extended and "+-> " in extended, (shell, extended)
            assert f"]-[{root}:" in extended, (shell, extended)
            send("unset NO_COLOR; prompt --session extended")
            colored = until(b">>")
            assert "\x1b[33m" in colored, (shell, colored)  # original yellow host/time
            assert "\x1b[35m" in colored, (shell, colored)  # original purple chevrons
            assert f"\x1b[1m{root}" in colored, (shell, colored)  # neutral bold directory
            assert f"\x1b[36m{branch}" in colored, (shell, colored)
            assert "\x1b[31m !17" in colored, (shell, colored)
            assert "\x1b[32m +1" in colored, (shell, colored)
            assert "\x1b[33m ?5" in colored, (shell, colored)
            assert not (root / "BRANCH_EXECUTED").exists(), shell
            assert not (root / "PATH_EXECUTED").exists(), shell
            print(f"PASS: {Path(shell).name} renders both layouts, preserves exit status and quotes Git/path data")
        finally:
            os.kill(pid, signal.SIGKILL)
            os.waitpid(pid, 0)
            os.close(terminal)


check(shutil.which("bash"), ["--noprofile", "--norc", "-i"])
if shutil.which("zsh"):
    check(shutil.which("zsh"), ["-f", "-i"])
