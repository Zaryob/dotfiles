#!/usr/bin/env python3
"""Generate native color presets and shell profiles from the same palettes."""

import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import uuid


def color(value):
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise ValueError(f"Invalid color: {value}")
    return {
        "Color Space": "sRGB",
        **{f"{component} Component": int(value[offset:offset + 2], 16) / 255
           for component, offset in (("Red", 1), ("Green", 3), ("Blue", 5))},
    }


def artifacts(directory):
    palettes = json.loads((directory / "palettes.json").read_text())
    profiles = []
    output = {}
    for theme, palette in palettes.items():
        colors = {key: color(value) for key, value in palette.items()}
        readability = ({"Minimum Contrast": 0.25, "Cursor Boost": 0.0,
                        "Use Bright Bold": False, "Brighten Bold Text": False,
                        "Use Bold Font": True}
                       if theme == "Day" else {})
        output[directory / "themes" / f"Dotfiles {theme}.itermcolors"] = plistlib.dumps(colors)
        for shell in ("zsh", "bash"):
            profiles.append({
                "Name": f"Dotfiles {shell.capitalize()} {theme}",
                "Guid": str(uuid.uuid5(uuid.NAMESPACE_URL,
                                     f"https://github.com/Zaryob/dotfiles/iterm2/{shell}/{theme}")),
                "Tags": ["Dotfiles", shell, theme],
                "Custom Command": "Yes",
                "Command": f"/bin/{shell} -l",
                "Custom Directory": "No",
                "Normal Font": "Menlo-Regular 13",
                "Non Ascii Font": "Menlo-Regular 13",
                "Use Non-ASCII Font": False,
                "Terminal Type": "xterm-256color",
                "Scrollback Lines": 10000,
                "Unlimited Scrollback": False,
                "Transparency": 0.0,
                "Use Separate Colors for Light and Dark Mode": False,
                **readability,
                **colors,
            })
    output[directory / "profiles.json"] = (json.dumps({"Profiles": profiles}, indent=2) + "\n").encode()
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify generated files without writing")
    args = parser.parse_args()
    for path, expected in artifacts(Path(__file__).resolve().parent).items():
        if args.check:
            if not path.is_file() or path.read_bytes() != expected:
                parser.exit(1, f"Out of date: {path}\nRun python3 terminal/iterm2/generate_profiles.py\n")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(expected)
    if not args.check:
        installed = Path.home() / "Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json"
        generated = Path(__file__).resolve().parent / "profiles.json"
        if installed.is_symlink() and installed.resolve() == generated:
            # iTerm2 watches the link's directory, not the external checkout.
            os.utime(installed, follow_symlinks=False)
    print("PASS: iTerm2 profiles and themes match palettes" if args.check else "Generated iTerm2 profiles and themes")


if __name__ == "__main__":
    main()
