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

## 🛠️ What this config actually does

The `restore_my_setup.sh` script automates the entire installation and configuration pipeline:

- **Core & AUR Preparation**: Checks for an AUR helper (`yay`/`paru`), installs `yay` if missing, and ensures basic system utilities (`git`, `zsh`) are installed.
- **Dynamic Kernel Headers Installation**: Automatically detects the running kernel (`uname -r`) and installs the matching headers package (e.g. `linux-cachyos-headers` or `linux-lts-headers`), which is required for compiling out-of-tree kernel modules.
- **Automated Package Deployment**: Verifies and installs **45+ system, font, and GUI packages** (including `hyprland`, `waybar`, `dunst`, `rofi-wayland`, `sddm`, `kitty`, `firefox`, `visual-studio-code-bin`, `dolphin`, `antigravity`, `prismlauncher`, etc.).
- **VS Code Settings & Extensions Restoration**: Deploys your custom editor settings (`settings.json`) and automatically installs all your active VS Code extensions (Tailwind CSS, animations, Gruvbox theme, Prettier, etc.) automatically.
- **Self-Sufficient Fallback Installer**: Uses a batch installation method with an automatic individual package installer fallback loop to prevent minor package or AUR failures from crashing the setup.
- **Dynamic Monitor & G-Sync Setup**: Automatically queries monitor layouts, native resolutions, and maximum refresh rates; configures the highest refresh rate monitor as the primary display, rotates the secondary monitor to portrait on the left, and configures G-Sync/VRR.
- **Interactive Mouse Offset Calibration**: Launches an interactive Zenity calibration loop at the end of the script, allowing the user to shift and align the monitors in real-time.
- **Custom Keyboard Layout**: Integrates a custom Arabic layout (`ara-custom`) mapping the letter `ذ` to the backslash key, allowing quick `Alt+Shift` toggles between US and custom layout.
- **Antigravity Keyring & Token Persistence**: Configures Electron keyring flags (`--password-store=gnome-libsecret`) and unmasks `gnome-keyring-daemon` services to securely persist login tokens on reboot.
- **Nvidia & Firefox Stability Fix**: Writes custom registry configuration tweaks (`PowerMizerDefaultAC=0x3`) to stop Firefox crash/stutter loops between P0 and P8 GPU states.
- **SDDM Login Screen (Candy Theme)**: Installs the SDDM Candy theme, configures Qt5 graphical effects, centers login prompts, and dynamically syncs the background image with the active desktop wallpaper.
- **Wi-Fi Hotspot Wrapper**: Installs `create_ap` and copies a helper script (`start_hotspot.sh`) to quickly spawn local hotspots, automatically disabling Wi-Fi power-save via `iw` for maximum stability.
- **Zsh & Fastfetch Customization**: Configures Oh My Zsh, Powerlevel10k, zsh autocomplete/syntax plugins, and displays a custom Braille anime mascot fastfetch logo.
- **Automated Wi-Fi Driver Patching**: Detects `/usr/src/8188eu-*` driver source directories and automatically executes `patch_driver.py` to fix compilation issues on kernels 6.1+, followed by rebuilding/reinstalling via DKMS.
- **HyDE Framework Setup**: Clones the official `hyprdots` (HyDE) framework, automated using pre-seeded inputs to skip standard installation prompt timers.
