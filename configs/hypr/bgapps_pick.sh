#!/usr/bin/env python3
"""Rofi picker for running Hyprland windows. Use: Super+Tab"""
import json, subprocess, sys

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
    sys.exit(0)

if not clients:
    sys.exit(0)

entries, addresses = [], []
for c in clients:
    cls = c.get("class", "")
    title = c.get("title", cls)[:50]
    icon = ICONS.get(cls.lower(), DEFAULT_ICON)
    entries.append(f"{icon}  {cls}  —  {title}")
    addresses.append(c.get("address", ""))

result = subprocess.run(
    ["rofi", "-dmenu", "-i", "-p", "Switch to",
     "-theme-str", "window { width: 50%; } listview { lines: 8; }",
     "-font", "JetBrainsMono Nerd Font 12"],
    input="\n".join(entries), capture_output=True, text=True
)

chosen = result.stdout.strip()
for i, entry in enumerate(entries):
    if entry == chosen:
        subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{addresses[i]}"])
        break
