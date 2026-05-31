# CachyOS + Hyprland Complete System Replicator & Restorer

This repository contains an automated setup script designed to replicate and restore a highly customized, gorgeous **CachyOS + Hyprland + HyDE** desktop environment in a single execution.

It was created and verified to run flawlessly on Arch Linux / CachyOS bases.

---

## 🚀 Quick Start (Replicate on Any Device)

To deploy your complete setup onto a fresh installation, you can run it either as a combined **one-liner command** or by executing the steps individually.

### Option 1: The Automated One-Liner (Recommended)
Copy and paste this single command into your terminal to clone, enter, and execute the restorer automatically:
```bash
git clone https://github.com/omarahmed321/cachyos-restore.git && cd cachyos-restore && chmod +x restore_my_setup.sh && ./restore_my_setup.sh
```

### Option 2: Run directly via `curl` (No manual cloning required)
Since the restoration script is fully self-contained, you can execute it directly from the cloud without even cloning the repository manually:
```bash
curl -sSL https://raw.githubusercontent.com/omarahmed321/cachyos-restore/main/restore_my_setup.sh | bash
```

### Option 3: Step-by-Step Execution
If you prefer running each step individually:
```bash
# 1. Clone the repository
git clone https://github.com/omarahmed321/cachyos-restore.git

# 2. Enter the repository directory
cd cachyos-restore

# 3. Make the script executable
chmod +x restore_my_setup.sh

# 4. Run the replicator script
./restore_my_setup.sh
```

---

## 🛠️ What This Replicator Does

The `restore_my_setup.sh` script automates the entire installation and configuration pipeline:

### 1. Core & AUR Preparation
* Checks for an AUR helper (`yay` or `paru`). If missing, it installs `yay` automatically.
* Installs crucial system utilities like `git` and `zsh`.

### 2. Complete Package Deployment
* Verifies and installs **29+ system and GUI packages**, including:
  * **Window Manager / Bars:** `hyprland`, `waybar`, `dunst`, `rofi-wayland`
  * **Core Tools:** `kitty`, `firefox`, `visual-studio-code-bin` (code), `dolphin`
  * **Enhancements:** `swaylock-effects-git`, `wlogout`, `cliphist`, `hyprpicker`, `hyprsunset` (for warm night light)
  * **UI / Engine styling:** `nwg-look`, `kvantum`, `qt5ct`, `qt6ct`
  * **System Services:** Automatically configures and enables `bluetooth`, `NetworkManager`, and `sddm`.

### 3. HyDE Framework Setup
* Clones the official `hyprdots` (HyDE) framework.
* Automates the installation script using pre-seeded inputs to skip standard installation prompt timers.

### 4. Custom Dotfiles & Configurations Integration
Applies your exact customized environment configurations:
* **Hyprland:** Custom screen configurations, inputs (US/Arabic layout with `Alt+Shift` toggle), trackpad settings, window rules, keybindings, opacity overlays, and Nvidia optimizations.
* **Waybar:** Complete bar layout configuration, modules (Spotify media playback integration, clock, CPU, battery, and tray modules), and customized themes/colors.
* **Kitty Terminal:** Font sizes (CaskaydiaCove Nerd Font), smooth cursor trail effects (`cursor_trail 10`), custom keymaps for clipboard operations.
* **Zsh Config:** Completely customized `.zshrc` with advanced system aliases (`ll`, `ls`, `lt`, `up`, `un`), custom prompt integrations, and autocomplete optimizations.
