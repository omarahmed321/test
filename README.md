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
* **Dynamic Kernel Headers Detection**: Automatically detects the running kernel (`uname -r`) and installs the matching headers package (e.g. `linux-cachyos-headers` or `linux-lts-headers`), which is required for compilation of out-of-tree kernel modules.

### 2. Complete Package Deployment
* Verifies and installs **45+ system and GUI packages**, including:
  * **Window Manager / Bars:** `hyprland`, `waybar`, `dunst`, `rofi-wayland`, `sddm`
  * **Core Tools:** `kitty`, `firefox`, `visual-studio-code-bin` (code), `dolphin`
  * **Developer & Gaming:** `antigravity`, `antigravity-ide`, `prismlauncher`, `python`
  * **Enhancements:** `swaylock-effects-git`, `wlogout`, `cliphist`, `hyprpicker`, `hyprsunset` (for warm night light), `wtype`, `wl-clipboard`, `zenity`, `fastfetch`
  * **UI / Engine styling:** `nwg-look`, `kvantum`, `kvantum-qt5`, `qt5ct`, `qt6ct`, `qt5-wayland`, `qt6-wayland`, `qt5-graphicaleffects`, `qt5-quickcontrols`, `qt5-quickcontrols2`
  * **Hotspot & Network:** `create_ap`, `gnome-keyring`, `blueman`, `bluez`, `seahorse`, `networkmanager`, `dnsmasq`, `hostapd`, `iw`
* **Fallback Package Installer Loop**: If the batch installation command fails, the script automatically falls back to installing packages individually. This prevents minor package or AUR failures from crashing the replication process.

### 3. HyDE Framework Setup
* Clones the official `hyprdots` (HyDE) framework.
* Automates the installation script using pre-seeded inputs to skip standard installation prompt timers.

### 4. Custom Dotfiles & Configurations Integration
Applies your exact customized environment configurations:
* **Hyprland:** Custom screen configurations, inputs (US/Arabic layout with `Alt+Shift` toggle using a custom keyboard layout map `ara-custom` that puts the letter `ذ` on the backslash key), trackpad settings, window rules, keybindings, opacity overlays, and Nvidia optimizations.
* **Waybar:** Complete bar layout configuration, modules (Spotify media playback integration, clock, CPU, battery, and tray modules), and customized themes/colors.
* **Kitty Terminal:** Font sizes (CaskaydiaCove Nerd Font), smooth cursor trail effects (`cursor_trail 10`), custom keymaps for clipboard operations.
* **Zsh Config:** Completely customized `.zshrc` with advanced system aliases (`ll`, `ls`, `lt`, `up`, `un`), custom prompt integrations, and autocomplete optimizations.
* **Fastfetch Mascot Logo:** Deploys a customized, beautifully downscaled 30-column Braille anime mascot art (`logo.txt`) with an aligned, vertically centered hardware information block (`config.jsonc`).
* **SDDM Login Screen (Candy Theme):** Automated SDDM Candy installation with dynamic active wallpaper synchronization (via `$HOME/.cache/hyde/wall.set`) and Gruvbox orange theme accents (`#fe8019`).
* **Wi-Fi Hotspot Controller:** Deploys a convenient CLI script (`start_hotspot.sh`) to quickly spawn local NATed/Bridged Wi-Fi hotspots using `create_ap` and disables power-save via `iw`.
* **Automated Wi-Fi Driver Patching**: Detects `/usr/src/8188eu-*` driver source directories and automatically executes `patch_driver.py` to fix compilation issues on kernels 6.1+, followed by rebuilding/reinstalling via DKMS.
* **Antigravity Keyring Persistence:** Automatically configures `--password-store=gnome-libsecret` flags and unmasks the `gnome-keyring-daemon` service to securely persist authentication tokens.
