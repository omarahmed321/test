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

## 🖥️ GUI Tools Included

The setup script installs two graphical settings panels that are also available as standalone tools in this repository.

### 🌙 Night Light GUI (`nightlight-gui.py`)

A GTK4/Adwaita panel for controlling **display color temperature and brightness** via `hyprsunset`.

**During installation** — the Night Light wizard opens automatically at the end of the setup process, letting you choose your preferred color temperature before the first reboot.

**After installation** — open it anytime with:

| Method | Command |
|--------|---------|
| **Keyboard shortcut** | `Super + Alt + N` |
| **Terminal** | `python3 ~/.local/share/bin/nightlight-gui.py` |
| **App launcher** (Rofi/wofi) | Search for **"Night Light"** |

**Features:**
- 🎚️ Temperature slider: 1000K (very warm) → 6500K (cool daylight)
- 💡 Brightness (gamma) slider: 10% → 100%
- ⚡ 6 quick presets: Night Mode · Evening · Home Comfort · Daytime · Cool Blue · Dim Night
- 💾 Saves settings to `~/.config/hypr/nightlight.conf` — persists across reboots
- 🔄 Live preview — changes apply instantly as you move the slider

**Run the setup wizard manually:**
```bash
python3 ~/.local/share/bin/nightlight-gui.py --setup
```

---

### 🖥️ Display & Mouse Settings GUI (`hypr-display-settings.py`)

A GTK4 panel for configuring **monitor resolution, refresh rate, scaling, and mouse sensitivity**.

| Method | Command |
|--------|---------|
| **Keyboard shortcut** | `Super + Alt + D` |
| **Terminal** | `python3 ~/.local/share/bin/hypr-display-settings.py` |
| **App launcher** | Search for **"Display & Mouse Settings"** |

---

## 🛠️ What this config actually does

The `restore_my_setup.sh` script automates the entire installation and configuration pipeline:

- **Core & AUR Preparation**: Checks for an AUR helper (`yay`/`paru`), installs `yay` if missing, and ensures basic system utilities (`git`, `zsh`) are installed.
- **Dynamic Kernel Headers Installation**: Automatically detects the running kernel (`uname -r`) and installs the matching headers package (e.g. `linux-cachyos-headers` or `linux-lts-headers`), which is required for compiling out-of-tree kernel modules.
- **Automated Package Deployment**: Verifies and installs **45+ system, font, and GUI packages** (including `hyprland`, `waybar`, `dunst`, `rofi-wayland`, `sddm`, `kitty`, `firefox`, `visual-studio-code-bin`, `dolphin`, `antigravity`, `antigravity-ide`, `prismlauncher`, etc.).
- **VS Code Settings & Extensions Restoration**: Deploys your custom editor settings (`settings.json`) and automatically installs all your active VS Code extensions (Tailwind CSS, animations, Gruvbox theme, Prettier, etc.) automatically.
- **Self-Sufficient Fallback Installer**: Uses a batch installation method with an automatic individual package installer fallback loop to prevent minor package or AUR failures from crashing the setup.
- **Dynamic Monitor & G-Sync Setup**: Automatically queries monitor layouts, native resolutions, and maximum refresh rates; configures the highest refresh rate monitor as the primary display, rotates the secondary monitor to portrait on the left, and configures G-Sync/VRR.
- **Interactive Mouse Offset Calibration**: Launches an interactive Zenity calibration loop at the end of the script, allowing the user to shift and align the monitors in real time.
- **Custom Keyboard Layout**: Integrates a custom Arabic layout variant (`thal_bksl` on the standard `ara` layout) mapping the letter `ذ` to the backslash key, allowing quick `Alt+Shift` toggles between US and Arabic layouts.
- **Antigravity Keyring & Token Persistence**: Configures Electron keyring flags (`--password-store=gnome-libsecret`) and unmasks `gnome-keyring-daemon` services to securely persist login tokens on reboot.
- **Nvidia & Firefox Stability Fix**: Writes custom registry configuration tweaks (`PowerMizerDefaultAC=0x3`) to stop Firefox crash/stutter loops between P0 and P8 GPU states.
- **SDDM Login Screen (Candy Theme)**: Installs the SDDM Candy theme, configures Qt5 graphical effects, centers login prompts, and dynamically syncs the background image with the active desktop wallpaper.
- **Wi-Fi Hotspot Wrapper**: Installs `create_ap` and copies a helper script (`start_hotspot.sh`) to quickly spawn local hotspots, automatically disabling Wi-Fi power-save via `iw` for maximum stability.
- **Zsh & Fastfetch Customization**: Configures Oh My Zsh, Powerlevel10k, zsh autocomplete/syntax plugins, and displays a custom Braille anime mascot fastfetch logo.
- **Automated Wi-Fi Driver Patching**: Detects `/usr/src/8188eu-*` driver source directories and automatically executes `patch_driver.py` to fix compilation issues on kernels 6.1+, followed by rebuilding/reinstalling via DKMS.
- **HyDE Framework Setup**: Clones the official `hyprdots` (HyDE) framework, automated using pre-seeded inputs to skip standard installation prompt timers.
- **Night Light & Display GUI Wizards**: At the end of the installation, graphical setup wizards open automatically to let you configure your display color temperature and monitor layout before the first reboot.
- **Compositor Animations**: Completely preserves native Hyprland/HyDE default animations and does not overwrite or touch any animation configuration files, letting you manage your curves via the standard HyDE animation selector.

---

## 📂 Repository File Structure & Descriptions

When you clone this repository, you will find the following files:

| File | Description |
| :--- | :--- |
| **`restore_my_setup.sh`** | **The main installer & configuration script.** Handles core packages, kernel headers, SDDM Candy theme, HyDE config, monitor layout, VS Code sync, keyboard layout, and driver building. |
| **`nightlight-gui.py`** | **Night Light settings GUI.** A GTK4/Adwaita panel for controlling display color temperature (1000–6500K) and brightness via `hyprsunset`. Supports a `--setup` flag for the first-run wizard launched during installation. Installed to `~/.local/share/bin/nightlight-gui.py`. Launch with `Super + Alt + N`. |
| **`patch_driver.py`** | **Wi-Fi driver patcher.** Automatically modifies the RTL8188EUS (`8188eu`) wireless driver source files so it compiles on 6.x/7.x kernels. |
| **`start_hotspot.sh`** | **Hotspot activation utility.** Spawns a Wi-Fi hotspot on the Realtek `wlan0` interface using `create_ap`. |
| **`double-pageup.sh`** | **Key-binding helper.** Captures double-taps of the `Page_Up` key and simulates `Ctrl + \`` to toggle the integrated terminal. |
| **`ara-custom`** | **Custom keyboard layout reference.** Maps the Arabic letter `ذ` (Thal) to the backslash (`\`) key for natural Arabic typing. |
| **`ioctl_cfg80211_patched.c`** | **Patched source reference.** Backup of the patched wireless driver configuration interfaces. |
| **`README.md`** | **Documentation.** This file. |
