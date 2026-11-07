#!/usr/bin/env python3
"""Validate native iTerm2 presets and the dynamic profiles that consume them."""
import json
from pathlib import Path
import plistlib
import subprocess
import uuid

directory = Path(__file__).resolve().parents[1] / "terminal" / "iterm2"
subprocess.run(["python3", str(directory / "generate_profiles.py"), "--check"], check=True)
profiles = json.loads((directory / "profiles.json").read_text())["Profiles"]
assert len(profiles) == 4
assert len({profile["Guid"] for profile in profiles}) == 4
assert len({profile["Name"] for profile in profiles}) == 4
for profile in profiles:
    uuid.UUID(profile["Guid"])
    _, shell, theme = profile["Tags"]
    assert shell in ("bash", "zsh")
    assert theme in ("Night", "Day")
    assert profile["Command"] == f"/bin/{shell} -l"
    assert profile["Custom Command"] == "Yes"
    assert profile["Custom Directory"] == "No"
    assert profile["Use Separate Colors for Light and Dark Mode"] is False
    preset = plistlib.loads((directory / "themes" / f"Dotfiles {theme}.itermcolors").read_bytes())
    assert len(preset) == (24 if theme == "Day" else 23)
    assert all(f"Ansi {index} Color" in preset for index in range(16))
    for key, color in preset.items():
        assert profile[key] == color
        assert color["Color Space"] == "sRGB"
        assert all(0 <= color[component] <= 1
                   for component in ("Red Component", "Green Component", "Blue Component"))

    if theme == "Day":
        def luminance(color):
            values = [color[f"{component} Component"] for component in ("Red", "Green", "Blue")]
            linear = [value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
                      for value in values]
            return sum(value * weight for value, weight in zip(linear, (0.2126, 0.7152, 0.0722)))

        def contrast(first, second):
            light, dark = sorted((luminance(preset[first]), luminance(preset[second])), reverse=True)
            return (light + 0.05) / (dark + 0.05)

        for key in ("Foreground Color", "Bold Color"):
            assert contrast(key, "Background Color") >= 12, key
        for index in (0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14):
            assert contrast(f"Ansi {index} Color", "Background Color") >= 4.5, index
        assert contrast("Link Color", "Background Color") >= 4.5
        assert contrast("Selected Text Color", "Selection Color") >= 7
        assert contrast("Cursor Text Color", "Cursor Color") >= 4.5
        # Preserve white-as-background semantics for programs that use SGR 47/107.
        assert luminance(preset["Ansi 7 Color"]) > 0.7
        assert luminance(preset["Ansi 15 Color"]) > 0.95
        assert contrast("Ansi 0 Color", "Ansi 15 Color") >= 12
        assert profile["Minimum Contrast"] == 0.25
        assert profile["Cursor Boost"] == 0
        assert profile["Brighten Bold Text"] is False
print("PASS: four unique login profiles and two matching native color presets")
print("PASS: Day text/selection/cursor contrast and ANSI black/white semantics")
