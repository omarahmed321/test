# CachyOS + Hyprland + HyDE Ultimate Restorer

This repository contains the complete configuration files and a lightweight, dynamic installation script to restore a fully-customized, high-performance desktop environment on **any Arch Linux system** (vanilla Arch Linux or CachyOS).

---

## 🚀 One-Command Installation

Open your terminal and run the following single command to clone this repository and start the interactive installer:

```bash
git clone https://github.com/omarahmed321/test.git ~/cachyos-restore && cd ~/cachyos-restore && ./install_my_setup.sh
```

---

## 🛠️ What the Installer Does

The script `install_my_setup.sh` runs interactively and allows you to select exactly which components to configure:

### 1. Auto-installs System Packages & Dependencies
- Installs `hyprland` (compositor), `waybar` (status bar), `dunst` (notifications), `rofi-wayland` (launcher), `kitty` (terminal), `dolphin` (file manager), and `sddm` (login screen).
- Installs Pipewire audio server (`pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`).
- Installs XDG portals (`xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`) and initializes default user directories (Downloads, Documents, Desktop, etc.).
- Automatically detects your GPU (Nvidia, AMD, Intel) and installs the appropriate graphics drivers.
- Installs `yay` AUR helper automatically to build AUR packages like `zen-browser-bin`, `sddm-astronaut-theme`, and `swaylock-effects-git`.

### 2. Deploys the HyDE Base Framework
- Clones and installs the base HyDE framework for themes and core keybindings.

### 3. Copies Verbatim Configurations (Dotfiles)
- Copies error-free, custom configuration files directly:
  - **Hyprland:** Main configs, monitor setups, user preferences, and window rules.
  - **Waybar:** Verbatim status bar styling, layouts, and modular widgets—including the custom **Prayer Times** countdown widget.
  - **Kitty & Cava:** Colors, visualizer configs, fonts, and transparency.
  - **VS Code:** Native preferences (`settings.json`) and keybindings (formatting and copy line hotkeys).
  - **Zsh:** Shell shell integrations (`.zshrc`), autocompletion, and themes.
  - **SDDM Login:** Autologin config, custom Astronaut theme, and login screen startup scripts.
  - **Arabic Keyboard Layout:** Maps the Arabic letter **ذ** onto the backslash key (**\\**) for rapid typing.

### 4. Custom Wallpaper Auto-Deployment
- Copies the custom wallpaper `background_for_me.jpg` to your Pictures directory and active theme wallpapers.
- Sets the wallpaper active instantly using the `swww` image daemon.

### 5. Zen Browser Optimization (Glassy & Lightweight)
- Pre-seeds the default profile directory and `profiles.ini` before the browser is launched for the first time.
- Applies the borderless transparent glassy UI theme.
- Limits process count to 1, caps caching, disables prefetching, and enables automatic tab discarding to keep memory usage extremely low.

### 6. Installs Helper Scripts & settings GUI
- **Display Settings GUI:** Program written from scratch (`hypr-display-settings.py`) to manage dual screen resolution, Hz, mouse sensitivity (tap-to-click enabled), and nightlight. Adds a shortcut in the applications menu.
- **Dropdown Terminal:** Toggles dropdown console by pressing `Page_Up` twice.
- **WiFi Hotspot:** Script `start_hotspot.sh` to run a native Wi-Fi hotspot with NetworkManager.
- **omar command:** Type `omar` in the terminal to view helpful keyboard shortcuts.

### 7. pam_faillock Lockout Bypass
- Permanently disables the account lockout policy so that your user is never locked out of sudo after 3 incorrect password attempts.
