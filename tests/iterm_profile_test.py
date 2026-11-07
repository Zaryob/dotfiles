#!/usr/bin/env python3
"""Verify current-tab OSC commands without controlling a terminal application."""
import os
from pathlib import Path
import shutil
import subprocess

helper = Path(__file__).resolve().parents[1] / "shell" / "iterm2.sh"
checks = 0
for shell, args in (("bash", ["--noprofile", "--norc"]), ("zsh", ["-f"])):
    executable = shutil.which(shell)
    if not executable:
        continue
    env = {key: value for key, value in os.environ.items()
           if key not in ("TMUX", "STY", "ITERM_SESSION_ID")}
    env["TERM_PROGRAM"] = "iTerm.app"

    def invoke(argument=None, extra_env=None, input_text=None):
        return subprocess.run([executable, *args, "-c", '. "$1"; shift; iterm-profile "$@"',
                               "iterm-test", str(helper), *([argument] if argument is not None else [])],
                              env={**env, **(extra_env or {})}, input=input_text,
                              capture_output=True)

    for choice in ("day", "night"):
        result = invoke(choice)
        expected = f"\x1b]1337;SetProfile=Dotfiles {shell.capitalize()} {choice.capitalize()}\x07".encode()
        assert result.returncode == 0 and result.stdout == expected, result
        checks += 1
    for name in ("Dotfiles Zsh Night", "Dotfiles Bash Day"):
        result = invoke(name)
        assert result.returncode == 0 and result.stdout == f"\x1b]1337;SetProfile={name}\x07".encode()
        checks += 1
    result = invoke(input_text=b"2\n")
    assert result.returncode == 0 and result.stdout.endswith(f"SetProfile=Dotfiles {shell.capitalize()} Day\x07".encode())
    checks += 1
    for invalid in ("invalid", "day\x07Injected", "day\nInjected"):
        result = invoke(invalid)
        assert result.returncode == 2 and not result.stdout, result
        checks += 1
    for extra_env in ({"TERM_PROGRAM": "OtherTerminal"}, {"TMUX": "test"}, {"STY": "test"}):
        result = invoke("day", extra_env)
        assert result.returncode == 1 and not result.stdout, result
        checks += 1
    result = invoke("list", {"TERM_PROGRAM": "OtherTerminal"})
    assert result.returncode == 0 and len(result.stdout.splitlines()) == 4
    checks += 1
print(f"PASS: {checks} Bash/Zsh current-tab profile, selector and escape validation checks")
