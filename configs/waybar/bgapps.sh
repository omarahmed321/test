#!/usr/bin/env python3
"""Shows running Hyprland windows as icons for waybar."""
import json, subprocess

ICONS = {
    "firefox": "󰈹", "firefox-esr": "󰈹", "chromium": "󰊯",
    "google-chrome": "󰊯", "brave-browser": "󰖟", "antigravity": "󱪞",
    "code": "󰨞", "code-oss": "󰨞", "vscodium": "󰨞", "discord": "󰙯",
    "telegram-desktop": "󰔁", "spotify": "󰓇", "steam": "󰓓",
    "nautilus": "󰉋", "thunar": "󰉋", "dolphin": "󰉋",
    "kitty": "", "alacritty": "", "foot": "", "wezterm": "",
    "obsidian": "󰂺", "gimp": "", "vlc": "󰕼", "mpv": "󰎁",
    "pavucontrol": "󰕾", "libreoffice": "󰻫", "soffice": "󰻫",
    "zoom": "󰹿", "slack": "󰒱", "bitwarden": "󰌾",
}
DEFAULT_ICON = "󰣆"

try:
    result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2)
    clients = json.loads(result.stdout)
except Exception:
    print(""); exit(0)

if not clients:
    print(""); exit(0)

icons = [ICONS.get(c.get("class", "").lower(), DEFAULT_ICON) for c in clients]
print(" ".join(icons))
