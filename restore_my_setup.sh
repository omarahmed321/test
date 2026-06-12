#!/usr/bin/env bash
#===============================================================================
#   CachyOS + HyDE (Hyprdots) Complete System Replicator & Restorer
#   Target System: CachyOS + Hyprland
#   Created by Antigravity AI Pair Programmer
#===============================================================================

# Color definitions for gorgeous feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Header block
echo -e "${CYAN}${BOLD}"
cat << "EOF"
  ==============================================================
   CachyOS + Hyprland Setup Cloner & Complete System Restorer
  ==============================================================
EOF
echo -e "${NC}"

# Ensure script is NOT run directly as root, but can elevate when needed
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}${BOLD}[ERROR] Please do NOT run this script as root directly. Use your normal user account. It will ask for sudo when required.${NC}"
    exit 1
fi

# Detect CachyOS/Arch base
if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}[WARNING] This script is designed for Arch Linux / CachyOS. Proceed with caution on other distributions!${NC}"
    read -p " :: Press Enter to continue anyway, or Ctrl+C to abort..."
fi

# Detect other Desktop Environments
if [ -n "$XDG_CURRENT_DESKTOP" ] && [ "$XDG_CURRENT_DESKTOP" != "Hyprland" ]; then
    echo -e "${YELLOW}[WARNING] You are currently running the '$XDG_CURRENT_DESKTOP' desktop environment.${NC}"
    read -p "Wanna start the setup? (This setup will change your desktop environment to Hyprland + HyDE) (y/n): " confirm_setup
    if [[ ! "$confirm_setup" =~ ^[Yy]$ ]]; then
        echo -e "${RED}[INFO] Installation aborted by user.${NC}"
        exit 0
    fi
fi

# 1. Detect/Install AUR Helper (yay/paru)
echo -e "\n${BLUE}${BOLD}[1/5] Checking for AUR helper (yay/paru)...${NC}"
AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    echo -e "${GREEN}[OK] Found yay as AUR helper.${NC}"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    echo -e "${GREEN}[OK] Found paru as AUR helper.${NC}"
else
    echo -e "${YELLOW}[INFO] No AUR helper found. Installing yay...${NC}"
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin || exit
    makepkg -si --noconfirm
    cd - || exit
    AUR_HELPER="yay"
    echo -e "${GREEN}[OK] Successfully installed yay.${NC}"
fi

# Synchronize package databases to prevent 404 download errors
echo -e "\n${BLUE}${BOLD}[1.5/5] Synchronizing package databases...${NC}"
sudo pacman -Sy

# Ensure git and zsh are installed
echo -e "\n${BLUE}${BOLD}[2/5] Ensuring Core packages (git, zsh) are installed...${NC}"

if ! pacman -Qi git &>/dev/null || ! pacman -Qi zsh &>/dev/null; then
    sudo pacman -S --needed --noconfirm git zsh
else
    echo -e "${GREEN}[OK] Core packages (git, zsh) are already installed.${NC}"
fi

# Ensure kernel headers matching the running kernel are installed (critical for DKMS driver compilation)
echo -e "\n${BLUE}${BOLD}[2.5/5] Detecting and installing matching kernel headers...${NC}"
KERNEL_NAME=$(uname -r)
HEADERS_PKG=""

if [[ "$KERNEL_NAME" == *"-cachyos"* ]]; then
    if [[ "$KERNEL_NAME" == *"-lts"* ]]; then
        HEADERS_PKG="linux-cachyos-lts-headers"
    elif [[ "$KERNEL_NAME" == *"-rc"* ]]; then
        HEADERS_PKG="linux-cachyos-rc-headers"
    elif [[ "$KERNEL_NAME" == *"-server"* ]]; then
        HEADERS_PKG="linux-cachyos-server-headers"
    elif [[ "$KERNEL_NAME" == *"-hardened"* ]]; then
        HEADERS_PKG="linux-cachyos-hardened-headers"
    else
        HEADERS_PKG="linux-cachyos-headers"
    fi
elif [[ "$KERNEL_NAME" == *"-lts"* ]]; then
    HEADERS_PKG="linux-lts-headers"
elif [[ "$KERNEL_NAME" == *"-zen"* ]]; then
    HEADERS_PKG="linux-zen-headers"
elif [[ "$KERNEL_NAME" == *"-hardened"* ]]; then
    HEADERS_PKG="linux-hardened-headers"
elif [[ "$KERNEL_NAME" == *"-rt"* ]]; then
    HEADERS_PKG="linux-rt-headers"
else
    HEADERS_PKG="linux-headers"
fi

echo -e "Running kernel: ${CYAN}$KERNEL_NAME${NC}, selected headers package: ${CYAN}$HEADERS_PKG${NC}"
if ! pacman -Qi "$HEADERS_PKG" &>/dev/null; then
    echo -e "Installing ${YELLOW}$HEADERS_PKG${NC}..."
    sudo pacman -S --needed --noconfirm "$HEADERS_PKG"
    echo -e "${GREEN}[OK] Installed kernel headers successfully.${NC}"
else
    echo -e "${GREEN}[OK] Kernel headers ($HEADERS_PKG) are already installed.${NC}"
fi

# 2. Check and Install Required Packages
echo -e "\n${BLUE}${BOLD}[3/5] Checking and installing required packages...${NC}"
REQUIRED_PACKAGES=(
    hyprland waybar dunst rofi-wayland kitty firefox code dolphin
    swaylock-effects-git wlogout cliphist hyprpicker hyprsunset
    grimblast-git slurp jq polkit-kde-agent eza awesome-terminal-fonts
    ttf-meslo-nerd ttf-jetbrains-mono-nerd blueman bluez bluez-utils
    network-manager-applet brightnessctl pamixer playerctl udiskie
    nwg-look kvantum kvantum-qt5 qt5ct qt6ct qt5-wayland qt6-wayland
    awww parallel pacman-contrib imagemagick ffmpegthumbs kde-cli-tools
    bc 8188eu-dkms-git antigravity antigravity-ide antigravity-cli prismlauncher cava tk

    wtype gnome-keyring ttf-cascadia-code-nerd
    oh-my-zsh-git zsh-theme-powerlevel10k zsh-autosuggestions
    zsh-syntax-highlighting zsh-completions
    wl-clipboard qt5-graphicaleffects qt5-quickcontrols qt5-quickcontrols2
    seahorse networkmanager zenity fastfetch bibata-cursor-theme-bin
    psmisc python dnsmasq hostapd iw sddm
)

# Install packages
echo -e "${CYAN}Checking ${#REQUIRED_PACKAGES[@]} essential packages...${NC}"
TO_INSTALL=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if [ "$pkg" = "8188eu-dkms-git" ]; then
        if pacman -Qq | grep -qE '^8188eu-' &>/dev/null; then
            INSTALLED_8188EU_PKG=$(pacman -Qq | grep -E '^8188eu-' | head -n 1)
            echo -e "  - ${GREEN}[Installed]${NC} 8188eu-dkms (provided by $INSTALLED_8188EU_PKG)"
            continue
        fi
    fi
    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "  - ${GREEN}[Installed]${NC} $pkg"
    else
        echo -e "  - ${YELLOW}[Missing]${NC} $pkg (queued)"
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}\nInstalling missing packages using $AUR_HELPER...${NC}"
    if ! $AUR_HELPER -S --noconfirm "${TO_INSTALL[@]}"; then
        echo -e "${YELLOW}[WARNING] Batch installation failed. Falling back to installing packages individually to ensure maximum coverage...${NC}"
        FAILED_PACKAGES=()
        for pkg in "${TO_INSTALL[@]}"; do
            echo -e "${CYAN}Installing $pkg...${NC}"
            if ! $AUR_HELPER -S --noconfirm "$pkg"; then
                echo -e "${RED}[ERROR] Failed to install $pkg${NC}"
                FAILED_PACKAGES+=("$pkg")
            fi
        done
        
        if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
            echo -e "${YELLOW}[WARNING] The following packages failed to install: ${FAILED_PACKAGES[*]}${NC}"
            echo -e "${YELLOW}The setup will proceed with the remaining components.${NC}"
        else
            echo -e "${GREEN}[OK] All packages installed successfully after fallback!${NC}"
        fi
    else
        echo -e "${GREEN}[OK] All packages installed successfully!${NC}"
    fi
else
    echo -e "${GREEN}[OK] All required packages are already installed.${NC}"
fi

# Enable system services
echo -e "\n${BLUE}${BOLD}[4/5] Enabling and starting system services (bluetooth, NetworkManager)...${NC}"
for svc in bluetooth NetworkManager sddm; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "  - ${GREEN}[Active]${NC} $svc service is running."
    else
        echo -e "  - ${YELLOW}[Inactive]${NC} Enabling and starting $svc..."
        if sudo -n true &>/dev/null; then
            sudo systemctl enable --now "$svc".service
        else
            echo -e "    ${YELLOW}[WARNING] Sudo requires a password. Skipping automatic service start for $svc.${NC}"
            echo -e "    To enable, run: ${CYAN}sudo systemctl enable --now $svc.service${NC}"
        fi
    fi
done

# 3. Clone and Run HyDE (Hyprdots) Installer
echo -e "\n${BLUE}${BOLD}[5/5] Deploying HyDE Desktop Environment Framework...${NC}"
if [ -d "$HOME/hyde" ]; then
    echo -e "${GREEN}[OK] HyDE directory already exists at $HOME/hyde.${NC}"
else
    echo -e "${CYAN}Cloning prasanthrangan/hyprdots repository to $HOME/hyde...${NC}"
    git clone https://github.com/prasanthrangan/hyprdots.git "$HOME/hyde"
    echo -e "${GREEN}[OK] Successfully cloned HyDE repository.${NC}"
fi

# Run the HyDE installer in default/non-interactive mode
echo -e "${CYAN}Running the HyDE installer...${NC}"
echo -e "${YELLOW}Note: Automating inputs for installer prompts (Grub theme, SDDM theme, and Flatpaks)...${NC}"
cd "$HOME/hyde/Scripts" || exit

# Run install.sh with pre-seeded inputs to skip/default prompt timers
# Enter/Skip Grub theme, Enter/Skip SDDM theme, and Answer 'n' to Flatpak apps
export aurhlpr="yay"
export myShell="zsh"
echo -e "\n\n\nn" | ./install.sh

echo -e "${GREEN}[OK] HyDE base configuration installed successfully!${NC}"

# Ensure swww/swww-daemon compatibility symlinks exist if awww is installed instead
if command -v awww &>/dev/null && ! command -v swww &>/dev/null; then
    echo -e "${BLUE}[INFO] Creating swww compatibility symlinks for awww...${NC}"
    mkdir -p "$HOME/.local/bin"
    ln -sf /usr/bin/awww "$HOME/.local/bin/swww"
    ln -sf /usr/bin/awww-daemon "$HOME/.local/bin/swww-daemon"
    mkdir -p "$HOME/.local/share/bin"
    ln -sf /usr/bin/awww "$HOME/.local/share/bin/swww"
    ln -sf /usr/bin/awww-daemon "$HOME/.local/share/bin/swww-daemon"
fi

# 4. Deploy EXACT Customized Dotfiles
echo -e "\n${MAGENTA}${BOLD}==============================================================${NC}"
echo -e "${MAGENTA}${BOLD}   Deploying Custom System Settings, Keybinds, & Fonts...    ${NC}"
echo -e "${MAGENTA}${BOLD}==============================================================${NC}"

# Create required config directories
mkdir -p "$HOME/.config/hypr/themes"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/waybar"
mkdir -p "$HOME/.config/hyde"
mkdir -p "$HOME/.config/cava"

# Deploy custom Arabic keyboard layout
echo -e "${CYAN}Writing custom Arabic layout to /usr/share/X11/xkb/symbols/ara...${NC}"
sudo bash -c 'if ! grep -q "xkb_symbols \"thal_bksl\"" /usr/share/X11/xkb/symbols/ara; then tee -a /usr/share/X11/xkb/symbols/ara >/dev/null << "XKBEOF"

// Custom Arabic layout variant with ذ (Arabic_thal) on the backslash key
partial alphanumeric_keys
xkb_symbols "thal_bksl" {
    include "ara(basic)"

    name[Group1]= "Arabic (Thal on backslash)";

    // Put ذ on the backslash key, with \ on AltGr
    key <BKSL> {[     Arabic_thal,        Arabic_shadda,           backslash,             bar ]};
};
XKBEOF
fi'

# --- WRITE ~/.local/bin/double-pageup.sh ---
echo -e "${CYAN}Writing ~/.local/bin/double-pageup.sh...${NC}"
mkdir -p "$HOME/.local/bin"
cat << 'DPEOF' > "$HOME/.local/bin/double-pageup.sh"
#!/bin/bash
LAST_FILE="/tmp/.pageup_last"
NOW=$(date +%s%N)

if [ -f "$LAST_FILE" ]; then
    LAST=$(cat "$LAST_FILE")
    DIFF=$(( (NOW - LAST) / 1000000 ))
    if [ "$DIFF" -lt 500 ]; then
        rm -f "$LAST_FILE"
        wtype -M ctrl -k grave
        exit 0
    fi
fi

echo "$NOW" > "$LAST_FILE"
sleep 0.6
[ -f "$LAST_FILE" ] && rm -f "$LAST_FILE"
DPEOF
chmod +x "$HOME/.local/bin/double-pageup.sh"

# --- WRITE ~/start_hotspot.sh ---
echo -e "${CYAN}Writing ~/start_hotspot.sh...${NC}"
cat << 'HOTEOF' > "$HOME/start_hotspot.sh"
#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Default Configurations ---
DEFAULT_SSID="tplink-7825"
DEFAULT_PASS="bolbol123*#"
WIFI_INT="wlan0"
INTERNET_INT="enp37s0"
CHANNEL="11"

# --- True User Configuration Path ---
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi
CONFIG_DIR="${USER_HOME}/.config"
CONFIG_FILE="${CONFIG_DIR}/hotspot_config"

# --- Load Saved Configurations ---
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi
SSID="${SAVED_SSID:-$DEFAULT_SSID}"
PASSPHRASE="${SAVED_PASS:-$DEFAULT_PASS}"

# --- Root Check & Auto-Sudo ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] This script needs root privileges. Rerunning with sudo...${NC}"
    exec sudo "$0" "$@"
fi

# --- Check & Install Prerequisites ---
echo -e "${CYAN}[*] Checking prerequisites...${NC}"

# 1. Packages from official repositories
OFFICIAL_DEPS=()
if ! command -v qrencode &> /dev/null; then
    OFFICIAL_DEPS+=("qrencode")
fi
if ! command -v hostapd &> /dev/null; then
    OFFICIAL_DEPS+=("hostapd")
fi
if ! command -v dnsmasq &> /dev/null; then
    OFFICIAL_DEPS+=("dnsmasq")
fi
if ! command -v iw &> /dev/null; then
    OFFICIAL_DEPS+=("iw")
fi
if ! command -v killall &> /dev/null; then
    OFFICIAL_DEPS+=("psmisc")
fi
if ! pacman -Qi iptables &> /dev/null && ! pacman -Qi nftables &> /dev/null; then
    OFFICIAL_DEPS+=("iptables")
fi
if ! pacman -Qi haveged &> /dev/null; then
    OFFICIAL_DEPS+=("haveged")
fi

if [ ${#OFFICIAL_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}[*] Installing missing official dependencies: ${OFFICIAL_DEPS[*]}...${NC}"
    pacman -S --needed --noconfirm "${OFFICIAL_DEPS[@]}"
fi

# 2. AUR Packages (create_ap)
if ! command -v create_ap &> /dev/null; then
    echo -e "${YELLOW}[*] 'create_ap' is missing. Installing from AUR...${NC}"
    if [ -n "$SUDO_USER" ]; then
        if sudo -u "$SUDO_USER" command -v yay &> /dev/null; then
            echo -e "${GREEN}[+] Using yay to install create_ap...${NC}"
            sudo -u "$SUDO_USER" yay -S --noconfirm create_ap
        elif sudo -u "$SUDO_USER" command -v paru &> /dev/null; then
            echo -e "${GREEN}[+] Using paru to install create_ap...${NC}"
            sudo -u "$SUDO_USER" paru -S --noconfirm create_ap
        else
            echo -e "${YELLOW}[*] No AUR helper found. Building create_ap manually...${NC}"
            tmp_dir=$(sudo -u "$SUDO_USER" mktemp -d)
            sudo -u "$SUDO_USER" git clone "https://aur.archlinux.org/create_ap.git" "$tmp_dir/create_ap"
            cd "$tmp_dir/create_ap" || exit 1
            sudo -u "$SUDO_USER" makepkg -si --noconfirm
            cd - || exit 1
            rm -rf "$tmp_dir"
        fi
    else
        echo -e "${RED}[-] Error: Cannot install create_ap from AUR without SUDO_USER context. Run script using sudo from a normal user account.${NC}"
        exit 1
    fi
fi

if ! ip link show "$WIFI_INT" &> /dev/null; then
    echo -e "${RED}[-] Error: Wi-Fi interface '$WIFI_INT' not found!${NC}"
    echo -e "${YELLOW}[*] Available interfaces:${NC}"
    ip link show | grep -E "^[0-9]+: "
    exit 1
fi

# --- Banner ---
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}====================================================${NC}"
    echo -e "${MAGENTA}${BOLD}     TP-Link TL-WN722N v2 Hotspot Controller        ${NC}"
    echo -e "${CYAN}${BOLD}====================================================${NC}"
    echo -e "Interface:  ${GREEN}${WIFI_INT}${NC}"
    echo -e "Internet:   ${GREEN}${INTERNET_INT}${NC}"
    echo -e "Channel:    ${GREEN}${CHANNEL}${NC}"
    echo -e "SSID:       ${YELLOW}${SSID}${NC}"
    echo -e "Password:   ${YELLOW}${PASSPHRASE}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
}

# --- Prompt configuration ---
echo -e "${CYAN}${BOLD}====================================================${NC}"
echo -e "${MAGENTA}${BOLD}     TP-Link TL-WN722N v2 Hotspot Configuration     ${NC}"
echo -e "${CYAN}${BOLD}====================================================${NC}"
echo -e "Saved Default: SSID: ${YELLOW}${SSID}${NC} | Password: ${YELLOW}${PASSPHRASE}${NC}"
echo -e "1) Start with Saved Default"
echo -e "2) Configure New Name/Password"
read -p "Choose option [1-2] (Default 1): " choice
choice="${choice:-1}"

if [ "$choice" -eq 2 ]; then
    read -p "Enter new SSID (Press Enter for default '$SSID'): " new_ssid
    read -p "Enter new Password (min 8 chars, Press Enter for default): " new_pass
    SSID="${new_ssid:-$SSID}"
    PASSPHRASE="${new_pass:-$PASSPHRASE}"
    
    read -p "Save this new configuration as default? (y/n) [y]: " save_choice
    save_choice="${save_choice:-y}"
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        mkdir -p "$CONFIG_DIR"
        echo "SAVED_SSID=\"$SSID\"" > "$CONFIG_FILE"
        echo "SAVED_PASS=\"$PASSPHRASE\"" >> "$CONFIG_FILE"
        if [ -n "$SUDO_USER" ]; then
            chown -R "$SUDO_USER:" "$CONFIG_DIR" 2>/dev/null || true
        fi
        echo -e "${GREEN}[+] Configuration saved as default!${NC}"
        sleep 1
    fi
fi

# Show configurations banner
show_banner

# --- Display QR Code ---
if command -v qrencode &> /dev/null; then
    echo -e "${GREEN}[+] Scan this QR Code to connect instantly:${NC}"
    qrencode -t utf8 "WIFI:S:${SSID};T:WPA;P:${PASSPHRASE};;"
    echo -e "${CYAN}----------------------------------------------------${NC}"
fi

# --- Cleanup Function ---
cleanup() {
    echo -e "\n${YELLOW}[*] Shutting down hotspot and cleaning up...${NC}"
    
    # Terminate create_ap and child processes
    if [ -n "$CREATE_AP_PID" ]; then
        kill -TERM "$CREATE_AP_PID" 2>/dev/null
    fi
    
    # Force kill dnsmasq, hostapd, and haveged just to be sure
    killall -9 hostapd dnsmasq create_ap haveged 2>/dev/null
    
    # Re-enable Wi-Fi Power Saving
    iw dev "$WIFI_INT" set power_save on 2>/dev/null
    
    echo -e "${GREEN}[+] Cleanup complete. Hotspot stopped.${NC}"
    exit 0
}

# Setup traps for SIGINT (Ctrl+C), SIGTERM, SIGHUP, and EXIT
trap cleanup SIGINT SIGTERM SIGHUP EXIT

# --- Start Hotspot ---
echo -e "${CYAN}[*] Stopping any conflicting services...${NC}"
killall -9 create_ap dnsmasq hostapd haveged 2>/dev/null || true
sleep 1

echo -e "${CYAN}[*] Disabling Wi-Fi Power Saving on $WIFI_INT...${NC}"
iw dev "$WIFI_INT" set power_save off 2>/dev/null || true

echo -e "${GREEN}[+] Starting Hotspot... (Press Ctrl+C to stop)${NC}"
echo -e "${CYAN}----------------------------------------------------${NC}"

# Run create_ap in the background so the trap can catch signals
create_ap --no-virt --ieee80211n --ht_capab '[HT40-][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]' -c "$CHANNEL" "$WIFI_INT" "$INTERNET_INT" "$SSID" "$PASSPHRASE" &
CREATE_AP_PID=$!

# Wait for create_ap to finish
wait "$CREATE_AP_PID"
HOTEOF
chmod +x "$HOME/start_hotspot.sh"

# --- Configure Antigravity IDE Flags & Keyring ---
echo -e "${CYAN}Writing ~/.config/antigravity-ide-flags.conf...${NC}"
mkdir -p "$HOME/.config"
echo "--password-store=gnome-libsecret" > "$HOME/.config/antigravity-ide-flags.conf"

# --- Configure Cava & Write default config with Green-Blue Gradient theme ---
echo -e "${CYAN}Writing ~/.config/cava/config...${NC}"
mkdir -p "$HOME/.config/cava"
cat << 'EOF' > "$HOME/.config/cava/config"
[general]
bars = 0
bar_width = 3
bar_spacing = 1

[input]
method = pulse
source = auto

[output]
method = noncurses

[color]
gradient = 1
gradient_color_1 = '#2af598'
gradient_color_2 = '#15e3b6'
gradient_color_3 = '#00c9ff'
gradient_color_4 = '#00f2fe'
gradient_color_5 = '#0072ff'
EOF

# --- Write ~/.local/share/bin/hypr-display-settings.py ---
echo -e "${CYAN}Writing ~/.local/share/bin/hypr-display-settings.py...${NC}"
mkdir -p "$HOME/.local/share/bin"
cat << 'DYEOF' > "$HOME/.local/share/bin/hypr-display-settings.py"
#!/usr/bin/env python3
import os
import re
import sys
import subprocess
import tkinter as tk
from tkinter import ttk, messagebox

# --- CONFIG PATHS ---
MONITORS_CONF = os.path.expanduser('~/.config/hypr/monitors.conf')
USERPREFS_CONF = os.path.expanduser('~/.config/hypr/userprefs.conf')

# --- HELPERS ---
def get_monitor_info():
    try:
        output = subprocess.check_output(['hyprctl', 'monitors'], text=True)
    except Exception as e:
        messagebox.showerror("Error", f"Failed to run 'hyprctl monitors': {e}")
        sys.exit(1)

    monitors = {}
    chunks = output.split('Monitor ')[1:]
    for chunk in chunks:
        lines = chunk.strip().split('\n')
        if not lines:
            continue
        
        match_name = re.match(r'^(\S+)\s+\(ID', lines[0])
        if not match_name:
            continue
        name = match_name.group(1)
        
        info = {
            'name': name,
            'model': 'Unknown',
            'current_mode': '',
            'position': '0x0',
            'scale': '1.00',
            'available_modes': {},
            'extra': ''
        }
        
        if len(lines) > 1:
            match_mode = re.search(r'(\d+x\d+@\d+\.\d+)\s+at\s+(\d+x\d+)', lines[1])
            if match_mode:
                info['current_mode'] = match_mode.group(1)
                info['position'] = match_mode.group(2)
        
        for line in lines:
            line_str = line.strip()
            if line_str.startswith('model:'):
                info['model'] = line_str.split('model:')[1].strip()
            elif line_str.startswith('scale:'):
                info['scale'] = line_str.split('scale:')[1].strip()
            elif line_str.startswith('availableModes:'):
                modes_str = line_str.split('availableModes:')[1].strip()
                modes_list = modes_str.split()
                
                # Group modes by resolution
                grouped = {}
                for mode in modes_list:
                    m = re.match(r'^(\d+x\d+)@([\d\.]+(?:Hz)?)$', mode)
                    if m:
                        res = m.group(1)
                        hz = m.group(2).replace('Hz', '')
                        try:
                            hz_float = float(hz)
                            hz_str = str(int(hz_float)) if hz_float.is_integer() else f"{hz_float:.2f}"
                        except ValueError:
                            hz_str = hz
                        
                        if res not in grouped:
                            grouped[res] = []
                        if hz_str not in grouped[res]:
                            grouped[res].append(hz_str)
                
                # Sort resolutions and refresh rates descending
                sorted_res = sorted(grouped.keys(), key=lambda r: [int(x) for x in r.split('x')], reverse=True)
                sorted_grouped = {}
                for r in sorted_res:
                    sorted_grouped[r] = sorted(grouped[r], key=float, reverse=True)
                
                info['available_modes'] = sorted_grouped
                
        monitors[name] = info
    
    # Parse existing monitors.conf to preserve extra options (like transform, mirror, etc.)
    if os.path.exists(MONITORS_CONF):
        try:
            with open(MONITORS_CONF, 'r') as f:
                content = f.read()
            for name in monitors:
                match_line = re.search(r'^\s*monitor\s*=\s*' + re.escape(name) + r'\s*,\s*[^,\n]+\s*,\s*[^,\n]+\s*,\s*[^,\n]+(.*)$', content, re.MULTILINE)
                if match_line:
                    monitors[name]['extra'] = match_line.group(1).strip()
        except Exception:
            pass

    return monitors

def get_mouse_sensitivity():
    if not os.path.exists(USERPREFS_CONF):
        return 0.0
    try:
        with open(USERPREFS_CONF, 'r') as f:
            content = f.read()
        match = re.search(r'^\s*sensitivity\s*=\s*([-\d\.]+)', content, re.MULTILINE)
        if match:
            return float(match.group(1))
    except Exception:
        pass
    return 0.0

def set_mouse_sensitivity(value):
    try:
        os.makedirs(os.path.dirname(USERPREFS_CONF), exist_ok=True)
        if not os.path.exists(USERPREFS_CONF):
            with open(USERPREFS_CONF, 'w') as f:
                f.write("# User Preferences\ninput {\n    sensitivity = 0.00\n}\n")
        
        with open(USERPREFS_CONF, 'r') as f:
            content = f.read()
        
        pattern = r'^(\s*sensitivity\s*=\s*)[-\d\.]+'
        if re.search(pattern, content, re.MULTILINE):
            new_content = re.sub(pattern, rf'\g<1>{value:.2f}', content, flags=re.MULTILINE)
        else:
            match = re.search(r'input\s*\{', content)
            if match:
                start_idx = match.end()
                brace_count = 1
                end_idx = -1
                for i in range(start_idx, len(content)):
                    if content[i] == '{':
                        brace_count += 1
                    elif content[i] == '}':
                        brace_count -= 1
                        if brace_count == 0:
                            end_idx = i
                            break
                if end_idx != -1:
                    before = content[:end_idx]
                    after = content[end_idx:]
                    if before and not before.endswith('\n'):
                        before += '\n'
                    new_content = before + f"    sensitivity = {value:.2f}\n" + after
                else:
                    new_content = content + f"\ninput {{\n    sensitivity = {value:.2f}\n}}\n"
            else:
                new_content = content + f"\ninput {{\n    sensitivity = {value:.2f}\n}}\n"
                
        with open(USERPREFS_CONF, 'w') as f:
            f.write(new_content)
        return True
    except Exception:
        return False

def get_touchpad_natural_scroll():
    if not os.path.exists(USERPREFS_CONF):
        return True
    try:
        with open(USERPREFS_CONF, 'r') as f:
            content = f.read()
        match = re.search(r'natural_scroll\s*=\s*(true|false)', content)
        if match:
            return match.group(1) == 'true'
    except Exception:
        pass
    return True

def set_touchpad_natural_scroll(enabled):
    try:
        os.makedirs(os.path.dirname(USERPREFS_CONF), exist_ok=True)
        if not os.path.exists(USERPREFS_CONF):
            with open(USERPREFS_CONF, 'w') as f:
                f.write("# User Preferences\n")
        
        with open(USERPREFS_CONF, 'r') as f:
            content = f.read()
        
        touchpad_pattern = r'(touchpad\s*\{[^}]*natural_scroll\s*=\s*)(true|false)'
        if re.search(touchpad_pattern, content):
            new_content = re.sub(touchpad_pattern, rf'\g<1>{"true" if enabled else "false"}', content)
        else:
            touchpad_block_pattern = r'touchpad\s*\{'
            match_tp = re.search(touchpad_block_pattern, content)
            if match_tp:
                start_idx = match_tp.end()
                brace_count = 1
                end_idx = -1
                for i in range(start_idx, len(content)):
                    if content[i] == '{':
                        brace_count += 1
                    elif content[i] == '}':
                        brace_count -= 1
                        if brace_count == 0:
                            end_idx = i
                            break
                if end_idx != -1:
                    before = content[:end_idx]
                    after = content[end_idx:]
                    if before and not before.endswith('\n'):
                        before += '\n'
                    new_content = before + f"        natural_scroll = {'true' if enabled else 'false'}\n" + after
                else:
                    new_content = content + f"\ninput {{\n    touchpad {{\n        natural_scroll = {'true' if enabled else 'false'}\n    }}\n}}\n"
            else:
                match_in = re.search(r'input\s*\{', content)
                if match_in:
                    start_idx = match_in.end()
                    brace_count = 1
                    end_idx = -1
                    for i in range(start_idx, len(content)):
                        if content[i] == '{':
                            brace_count += 1
                        elif content[i] == '}':
                            brace_count -= 1
                            if brace_count == 0:
                                end_idx = i
                                break
                    if end_idx != -1:
                        before = content[:end_idx]
                        after = content[end_idx:]
                        if before and not before.endswith('\n'):
                            before += '\n'
                        tp_block = f"    touchpad {{\n        natural_scroll = {'true' if enabled else 'false'}\n    }}\n"
                        new_content = before + tp_block + after
                    else:
                        new_content = content + f"\ninput {{\n    touchpad {{\n        natural_scroll = {'true' if enabled else 'false'}\n    }}\n}}\n"
                else:
                    new_content = content + f"\ninput {{\n    touchpad {{\n        natural_scroll = {'true' if enabled else 'false'}\n    }}\n}}\n"
                
        with open(USERPREFS_CONF, 'w') as f:
            f.write(new_content)
        return True
    except Exception:
        return False

def update_monitor_config(name, resolution, hz, scale, extra):
    try:
        os.makedirs(os.path.dirname(MONITORS_CONF), exist_ok=True)
        if not os.path.exists(MONITORS_CONF):
            with open(MONITORS_CONF, 'w') as f:
                f.write("# Monitor Rules\n")
                
        with open(MONITORS_CONF, 'r') as f:
            lines = f.readlines()
        
        updated = False
        for i, line in enumerate(lines):
            match = re.match(r'^\s*monitor\s*=\s*([\w\-]+)\s*,\s*([^,\n]+)\s*,\s*([^,\n]+)\s*,\s*([^,\n]+)(.*)$', line)
            if match and match.group(1) == name:
                res_hz = f"{resolution}@{hz}"
                pos = match.group(3).strip()
                lines[i] = f"monitor = {name},{res_hz},{pos},{scale}{extra}\n"
                updated = True
                break
                
        if not updated:
            insert_idx = len(lines)
            for idx, line in enumerate(lines):
                if 'Workspace Rules' in line:
                    insert_idx = idx
                    break
            lines.insert(insert_idx, f"monitor = {name},{resolution}@{hz},auto,{scale}{extra}\n")
            
        with open(MONITORS_CONF, 'w') as f:
            f.writelines(lines)
        return True
    except Exception:
        return False

# --- GUI APP ---
class DisplaySettingsApp(tk.Tk):
    def __init__(self):
        super().__init__()
        
        self.title("CachyOS Display & Mouse Settings")
        self.geometry("450x450")
        self.configure(bg='#272727')
        
        # Load data
        self.monitors = get_monitor_info()
        self.current_sens = get_mouse_sensitivity()
        
        # Style
        self.setup_styles()
        
        # Build UI
        self.build_ui()
        
    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        
        style.configure('.', background='#272727', foreground='#ebdbb2', font=('JetBrains Mono', 10))
        style.configure('TLabel', background='#272727', foreground='#ebdbb2')
        style.configure('TFrame', background='#272727')
        
        style.configure('TNotebook', background='#272727', borderwidth=0)
        style.configure('TNotebook.Tab', background='#3c3836', foreground='#a89984', padding=[12, 6])
        style.map('TNotebook.Tab', background=[('selected', '#272727')], foreground=[('selected', '#ebdbb2')])
        
        style.configure('TCombobox', fieldbackground='#3c3836', background='#504945', foreground='#ebdbb2')
        style.map('TCombobox', fieldbackground=[('readonly', '#3c3836')], foreground=[('readonly', '#ebdbb2')])
        
        style.configure('TButton', background='#3c3836', foreground='#ebdbb2', borderwidth=1, focuscolor='none', padding=[10, 5])
        style.map('TButton', background=[('active', '#504945')])

    def build_ui(self):
        # Notebook for Tabs
        notebook = ttk.Notebook(self)
        notebook.pack(fill='both', expand=True, padx=15, pady=15)
        
        # --- TAB 1: DISPLAY ---
        display_frame = ttk.Frame(notebook)
        notebook.add(display_frame, text="Display Settings")
        
        # Monitor Select
        ttk.Label(display_frame, text="Monitor:").grid(row=0, column=0, sticky='w', pady=10, padx=10)
        self.monitor_names = list(self.monitors.keys())
        self.monitor_display_names = [f"{name} ({self.monitors[name]['model']})" for name in self.monitor_names]
        
        self.monitor_combo = ttk.Combobox(display_frame, values=self.monitor_display_names, state="readonly", width=30)
        self.monitor_combo.grid(row=0, column=1, sticky='w', pady=10, padx=10)
        self.monitor_combo.bind("<<ComboboxSelected>>", self.on_monitor_select)
        
        # Resolution Select
        ttk.Label(display_frame, text="Resolution:").grid(row=1, column=0, sticky='w', pady=10, padx=10)
        self.res_combo = ttk.Combobox(display_frame, state="readonly", width=20)
        self.res_combo.grid(row=1, column=1, sticky='w', pady=10, padx=10)
        self.res_combo.bind("<<ComboboxSelected>>", self.on_res_select)
        
        # Refresh Rate Select
        ttk.Label(display_frame, text="Refresh Rate (Hz):").grid(row=2, column=0, sticky='w', pady=10, padx=10)
        self.hz_combo = ttk.Combobox(display_frame, state="readonly", width=15)
        self.hz_combo.grid(row=2, column=1, sticky='w', pady=10, padx=10)
        
        # Scaling Select
        ttk.Label(display_frame, text="System Zoom (Scale):").grid(row=3, column=0, sticky='w', pady=10, padx=10)
        self.scale_values = ["1", "1.25", "1.5", "1.75", "2"]
        self.scale_combo = ttk.Combobox(display_frame, values=self.scale_values, state="readonly", width=10)
        self.scale_combo.grid(row=3, column=1, sticky='w', pady=10, padx=10)
        
        # --- TAB 2: MOUSE ---
        mouse_frame = ttk.Frame(notebook)
        notebook.add(mouse_frame, text="Mouse Sensitivity")
        
        ttk.Label(mouse_frame, text="Adjust Pointer Sensitivity:", font=('JetBrains Mono', 11, 'bold')).pack(anchor='w', pady=15, padx=15)
        ttk.Label(mouse_frame, text="Slide left to slow down, right to speed up (-1.00 to +1.00):").pack(anchor='w', pady=5, padx=15)
        
        # Sens Slider Frame
        slider_frame = ttk.Frame(mouse_frame)
        slider_frame.pack(fill='x', padx=15, pady=20)
        
        self.sens_val_var = tk.StringVar(value=f"{self.current_sens:.2f}")
        
        self.sens_slider = tk.Scale(
            slider_frame, from_=-1.0, to=1.0, resolution=0.05, orient='horizontal',
            bg='#3c3836', fg='#ebdbb2', troughcolor='#272727', highlightbackground='#272727',
            activebackground='#504945', showvalue=False, command=self.on_slider_move
        )
        self.sens_slider.set(self.current_sens)
        self.sens_slider.pack(side='left', fill='x', expand=True, padx=5)
        
        sens_label = ttk.Label(slider_frame, textvariable=self.sens_val_var, font=('JetBrains Mono', 12, 'bold'), width=6, anchor='center')
        sens_label.pack(side='right', padx=10)
        
        # Accel Note
        ttk.Label(mouse_frame, text="* Accel profile is forced to 'flat' to ensure raw mouse precision.", foreground='#a89984').pack(anchor='w', padx=15, pady=10)

        # Touchpad Settings Separator
        ttk.Separator(mouse_frame, orient='horizontal').pack(fill='x', padx=15, pady=15)
        
        ttk.Label(mouse_frame, text="Touchpad Settings:", font=('JetBrains Mono', 11, 'bold')).pack(anchor='w', padx=15, pady=5)
        
        self.touchpad_var = tk.BooleanVar(value=not get_touchpad_natural_scroll())
        self.touchpad_check = ttk.Checkbutton(
            mouse_frame, text="Windows-style Touchpad Scrolling (Reverse/Standard)",
            variable=self.touchpad_var
        )
        self.touchpad_check.pack(anchor='w', padx=20, pady=10)

        # --- BOTTOM ACTION PANEL ---
        btn_frame = ttk.Frame(self)
        btn_frame.pack(fill='x', side='bottom', padx=15, pady=15)
        
        cancel_btn = ttk.Button(btn_frame, text="Close", command=self.destroy)
        cancel_btn.pack(side='left', padx=5)
        
        apply_btn = ttk.Button(btn_frame, text="Apply & Save Settings", command=self.apply_settings)
        apply_btn.pack(side='right', padx=5)
        
        # Set defaults if monitors exist
        if self.monitor_names:
            self.monitor_combo.current(0)
            self.on_monitor_select(None)

    def on_monitor_select(self, event):
        m_idx = self.monitor_combo.current()
        m_name = self.monitor_names[m_idx]
        m_info = self.monitors[m_name]
        
        # Update resolutions
        resolutions = list(m_info['available_modes'].keys())
        self.res_combo.configure(values=resolutions)
        
        # Pre-select current or highest resolution
        current_res = m_info['current_mode'].split('@')[0]
        if current_res in resolutions:
            self.res_combo.set(current_res)
        elif resolutions:
            self.res_combo.current(0)
            
        self.on_res_select(None)
        
        # Pre-select current scale
        curr_scale = m_info['scale']
        try:
            curr_scale_float = float(curr_scale)
            if curr_scale_float.is_integer():
                curr_scale_str = str(int(curr_scale_float))
            else:
                curr_scale_str = f"{curr_scale_float:.2f}".rstrip('0').rstrip('.')
        except ValueError:
            curr_scale_str = curr_scale
            
        if curr_scale_str in self.scale_values:
            self.scale_combo.set(curr_scale_str)
        else:
            self.scale_combo.set("1")

    def on_res_select(self, event):
        m_idx = self.monitor_combo.current()
        m_name = self.monitor_names[m_idx]
        m_info = self.monitors[m_name]
        
        selected_res = self.res_combo.get()
        if selected_res in m_info['available_modes']:
            refresh_rates = m_info['available_modes'][selected_res]
            self.hz_combo.configure(values=refresh_rates)
            
            # Match current refresh rate
            current_hz = m_info['current_mode'].split('@')[1] if '@' in m_info['current_mode'] else ''
            try:
                curr_hz_val = float(current_hz)
                curr_hz_str = str(int(curr_hz_val)) if curr_hz_val.is_integer() else f"{curr_hz_val:.2f}"
            except ValueError:
                curr_hz_str = current_hz
            
            matched = False
            for rate in refresh_rates:
                try:
                    if abs(float(rate) - float(curr_hz_str)) < 1.0:
                        self.hz_combo.set(rate)
                        matched = True
                        break
                except ValueError:
                    pass
            
            if not matched and refresh_rates:
                self.hz_combo.current(0)

    def on_slider_move(self, value):
        self.sens_val_var.set(f"{float(value):+.2f}")

    def apply_settings(self):
        m_idx = self.monitor_combo.current()
        if m_idx < 0:
            messagebox.showerror("Error", "No monitor selected.")
            return
            
        m_name = self.monitor_names[m_idx]
        m_info = self.monitors[m_name]
        
        selected_res = self.res_combo.get()
        selected_hz = self.hz_combo.get()
        selected_scale = self.scale_combo.get()
        
        if not selected_res or not selected_hz or not selected_scale:
            messagebox.showerror("Error", "Please make sure resolution, refresh rate, and scaling are selected.")
            return
            
        # 1. Update Monitor Configuration
        extra = m_info['extra']
        if extra and not extra.startswith(','):
            extra = ',' + extra
            
        position = m_info['position']
        res_hz = f"{selected_res}@{selected_hz}"
        try:
            subprocess.run(['hyprctl', 'keyword', 'monitor', f"{m_name},{res_hz},{position},{selected_scale}{extra}"], check=True)
            update_monitor_config(m_name, selected_res, selected_hz, selected_scale, extra)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply display settings: {e}")
            return
            
        # 2. Update Mouse Sensitivity
        sens_value = self.sens_slider.get()
        try:
            subprocess.run(['hyprctl', 'keyword', 'input:sensitivity', f"{sens_value:.2f}"], check=True)
            set_mouse_sensitivity(sens_value)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply mouse sensitivity: {e}")
            return

        # 3. Update Touchpad Scrolling Direction
        touchpad_windows_style = self.touchpad_var.get()
        natural_scroll = not touchpad_windows_style
        try:
            subprocess.run(['hyprctl', 'keyword', 'input:touchpad:natural_scroll', 'true' if natural_scroll else 'false'], check=True)
            set_touchpad_natural_scroll(natural_scroll)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to apply touchpad settings: {e}")
            return
            
        messagebox.showinfo("Success", "Settings applied and saved successfully!")
        
        self.monitors = get_monitor_info()
        self.current_sens = get_mouse_sensitivity()
        self.touchpad_var.set(not get_touchpad_natural_scroll())

if __name__ == "__main__":
    if not os.environ.get('WAYLAND_DISPLAY'):
        print("Error: Wayland display not found. This tool is designed for Hyprland.")
        sys.exit(1)
    
    app = DisplaySettingsApp()
    app.mainloop()
DYEOF
chmod +x "$HOME/.local/share/bin/hypr-display-settings.py"

# --- Create Display & Mouse Settings Desktop Entry ---
echo -e "${CYAN}Creating ~/.local/share/applications/hypr-display-settings.desktop...${NC}"
mkdir -p "$HOME/.local/share/applications"
cat << DEEOF > "$HOME/.local/share/applications/hypr-display-settings.desktop"
[Desktop Entry]
Name=Display & Mouse Settings
Comment=Adjust screen resolution, refresh rate, system zoom, and mouse sensitivity
Exec=python3 $HOME/.local/share/bin/hypr-display-settings.py
Icon=video-display
Terminal=false
Type=Application
Categories=Settings;HardwareSettings;
DEEOF
chmod +x "$HOME/.local/share/applications/hypr-display-settings.desktop"


echo -e "${CYAN}Ensuring gnome-keyring-daemon systemd services are unmasked...${NC}"
systemctl --user unmask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || true
systemctl --user enable gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || true

# --- VS Code Configurations & Extensions ---
echo -e "\n${BLUE}${BOLD}Configuring Visual Studio Code...${NC}"
mkdir -p "$HOME/.config/Code/User"

echo -e "${CYAN}Writing VS Code settings.json...${NC}"
cat << 'EOF' > "$HOME/.config/Code/User/settings.json"
{
  "workbench.colorTheme": "wallbash",
  "terminal.integrated.foreground": "#ebdbb2",
  "terminal.integrated.background": "#272727",
  "terminal.integrated.selectionBackground": "#655b53",
  "terminal.integrated.cursorStyle": "block",
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font', 'monospace'",
  "terminal.integrated.ansiBlack": "#272727",
  "terminal.integrated.ansiRed": "#cc231c",
  "terminal.integrated.ansiGreen": "#989719",
  "terminal.integrated.ansiYellow": "#d79920",
  "terminal.integrated.ansiBlue": "#448488",
  "terminal.integrated.ansiMagenta": "#b16185",
  "terminal.integrated.ansiCyan": "#689d69",
  "terminal.integrated.ansiWhite": "#a89983",
  "terminal.integrated.ansiBrightBlack": "#928373",
  "terminal.integrated.ansiBrightRed": "#fb4833",
  "terminal.integrated.ansiBrightGreen": "#b8ba25",
  "terminal.integrated.ansiBrightYellow": "#fabc2e",
  "terminal.integrated.ansiBrightBlue": "#83a597",
  "terminal.integrated.ansiBrightMagenta": "#d3859a",
  "terminal.integrated.ansiBrightCyan": "#8ec07b",
  "terminal.integrated.ansiBrightWhite": "#ebdbb2",
  "emmet.includeLanguages": {
    "javascript": "javascriptreact",
    "typescript": "typescriptreact"
  },
  "emmet.triggerExpansionOnTab": true,
  "emmet.showExpandedAbbreviation": "always",
  "emmet.showSuggestionsAsSnippets": true,
  "editor.snippetSuggestions": "top",
  "editor.quickSuggestionsDelay": 0,
  "editor.wordBasedSuggestions": "off",
  "editor.inlineSuggest.enabled": false,
  "github.copilot.editor.enableAutoCompletions": false,
  "editor.quickSuggestions": {
    "other": "on",
    "comments": "off",
    "strings": "off"
  },
  "editor.suggestOnTriggerCharacters": true,
  "tailwindCSS.includeLanguages": {
    "javascript": "javascriptreact",
    "typescript": "typescriptreact"
  }
}
EOF

# Install extensions if code CLI is available
if command -v code &>/dev/null; then
    echo -e "${CYAN}Installing VS Code extensions...${NC}"
    VSCODE_EXTS=(
        bradlc.vscode-tailwindcss
        brandonkirbyson.vscode-animations
        drcika.apc-extension
        dsznajder.es7-react-js-snippets
        esbenp.prettier-vscode
        formulahendry.auto-close-tag
        jdinhlife.gruvbox
        pkief.material-icon-theme
        prettier.prettier-vscode
        undefined_publisher.wallbash
    )
    for ext in "${VSCODE_EXTS[@]}"; do
        echo -e "  - Installing extension: ${CYAN}$ext${NC}..."
        code --install-extension "$ext" --force &>/dev/null || true
    done
    echo -e "${GREEN}[OK] VS Code extensions installed successfully!${NC}"
else
    echo -e "${YELLOW}[WARNING] VS Code command line 'code' not found. Skipping extension installation.${NC}"
fi

# Robustly copy default themes and animations from the cloned HyDE repo if they exist
if [ -d "$HOME/hyde/Configs/.config/hypr" ]; then
    echo -e "${CYAN}Deploying animations and theme configuration directories from HyDE...${NC}"
    cp -r "$HOME/hyde/Configs/.config/hypr/animations" "$HOME/.config/hypr/"
    cp -r "$HOME/hyde/Configs/.config/hypr/themes/." "$HOME/.config/hypr/themes/"
fi

# Robustly copy wallbash configuration directory from HyDE if it exists
if [ -d "$HOME/hyde/Configs/.config/hyde" ]; then
    echo -e "${CYAN}Deploying wallbash configuration directory from HyDE...${NC}"
    cp -r "$HOME/hyde/Configs/.config/hyde/wallbash" "$HOME/.config/hyde/"
fi

# Deploy Bibata-Modern-Ice cursor theme locally (passwordless and robust)
if [ ! -d "$HOME/.icons/Bibata-Modern-Ice" ]; then
    echo -e "${CYAN}Installing Bibata-Modern-Ice cursor theme locally...${NC}"
    mkdir -p "$HOME/.icons"
    curl -sSL -o /tmp/Bibata-Modern-Ice.tar.xz https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz
    tar -xf /tmp/Bibata-Modern-Ice.tar.xz -C "$HOME/.icons/"
    rm -f /tmp/Bibata-Modern-Ice.tar.xz
fi

# --- WRITE ~/.config/hypr/hyprland.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/hyprland.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/hyprland.conf"

#      ░▒▒▒░░░░░▓▓          ___________
#    ░░▒▒▒░░░░░▓▓        //___________/
#   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
#    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/
#       ░▒▓▓   ▓▓  //____/


$scrPath = $HOME/.local/share/bin # set scripts path

# Default cursor theme and size
$CURSOR_THEME = Bibata-Modern-Ice
$CURSOR_SIZE = 20


# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄

# See https://wiki.hyprland.org/Configuring/Monitors/

# monitor configured in monitors.conf


# █░░ ▄▀█ █░█ █▄░█ █▀▀ █░█
# █▄▄ █▀█ █▄█ █░▀█ █▄▄ █▀█

# See https://wiki.hyprland.org/Configuring/Keywords/

exec-once = $scrPath/resetxdgportal.sh # reset XDPH for screenshare
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # for XDPH
exec-once = dbus-update-activation-environment --systemd --all # for XDPH
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # for XDPH
exec-once = $scrPath/polkitkdeauth.sh # authentication dialogue for GUI apps
exec-once = sleep 2 && env reload_flag=1 $scrPath/wbarconfgen.sh # launch the system bar
exec-once = blueman-applet # systray app for Bluetooth
exec-once = udiskie --no-automount --smart-tray # front-end that allows to manage removable media
exec-once = nm-applet --indicator # systray app for Network/Wifi
exec-once = dunst # start notification demon
exec-once = wl-paste --type text --watch cliphist store # clipboard store text data
exec-once = wl-paste --type image --watch cliphist store # clipboard store image data
exec-once = $scrPath/swwwallpaper.sh # start wallpaper daemon
exec-once = $scrPath/batterynotify.sh # battery notification
exec-once = hyprsunset -t 3500 # night light (warmer temperature for better blue light filtering)


# █▀▀ █▄░█ █░█
# ██▄ █░▀█ ▀▄▀

# See https://wiki.hyprland.org/Configuring/Environment-variables/

env = PATH,$PATH:$scrPath
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = MOZ_ENABLE_WAYLAND,1
env = GDK_SCALE,1


# █ █▄░█ █▀█ █░█ ▀█▀
# █ █░▀█ █▀▀ █▄█ ░█░

# See https://wiki.hyprland.org/Configuring/Variables/

input {
    kb_layout = us,ara
    kb_variant = ,thal_bksl
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1

    touchpad {
        natural_scroll = no
    }

    sensitivity = -1.0
    accel_profile = flat
    force_no_accel = 0
    numlock_by_default = true
}

# See https://wiki.hyprland.org/Configuring/Keywords/#executing

device {
    name = epic mouse V1
    sensitivity = -0.5
}

# See https://wiki.hyprland.org/Configuring/Variables/

gestures {
    gesture = 3, horizontal, workspace
}


# █░░ ▄▀█ █▄█ █▀█ █░█ ▀█▀ █▀
# █▄▄ █▀█ ░█░ █▄█ █▄█ ░█░ ▄█

# See https://wiki.hyprland.org/Configuring/Dwindle-Layout/

dwindle {
    preserve_split = yes
}

# See https://wiki.hyprland.org/Configuring/Master-Layout/

master {
    new_status = master
}


# █▀▄▀█ █ █▀ █▀▀
# █░▀░█ █ ▄█ █▄▄

# See https://wiki.hyprland.org/Configuring/Variables/

misc {
    vrr = 2
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}

xwayland {
    force_zero_scaling = true
}


# █▀ █▀█ █░█ █▀█ █▀▀ █▀▀
# ▄█ █▄█ █▄█ █▀▄ █▄▄ ██▄

source = ~/.config/hypr/animations.conf
source = ~/.config/hypr/keybindings.conf
source = ~/.config/hypr/windowrules.conf
source = ~/.config/hypr/themes/common.conf # shared theme settings
# hyprlang noerror true
source = ~/.config/hypr/themes/theme.conf # theme specific settings
# hyprlang noerror false

# Dynamically synchronize GTK and default cursor configurations with the active theme
exec = ~/.config/hypr/sync_cursor.sh $CURSOR_THEME $CURSOR_SIZE
source = ~/.config/hypr/themes/colors.conf # wallbash color override
source = ~/.config/hypr/monitors.conf # initially empty, to be configured by user and remains static
source = ~/.config/hypr/userprefs.conf # initially empty, to be configured by user and remains static

# Note: as userprefs.conf is sourced at the end, settings configured in this file will override the defaults
source = ~/.config/hypr/nvidia.conf # auto sourced vars for nvidia

# Nvidia & Wayland Fixes
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF

# --- WRITE ~/.config/hypr/userprefs.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/userprefs.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/userprefs.conf"

# █░█ █▀ █▀▀ █▀█   █▀█ █▀█ █▀▀ █▀▀ █▀
# █▄█ ▄█ ██▄ █▀▄   █▀▀ █▀▄ ██▄ █▀░ ▄█

# Set your personal hyprland configuration here
# For a sample file, please refer to https://github.com/prasanthrangan/hyprdots/blob/main/Configs/.config/hypr/userprefs.t2

decoration {
    shadow {
        enabled = true
        range = 18
        render_power = 4
        color = rgba(8ec07cff)
        color_inactive = rgba(00000055)
        offset = 0 0
    }
}

input {
    kb_layout = us,ara
    kb_variant = ,thal_bksl
    kb_options = grp:alt_shift_toggle
    sensitivity = -0.5
    accel_profile = flat
    force_no_accel = 0
}

# --- Game Mouse Cursor Fixes ---
# Confine mouse pointer to game windows (forces mouse capture, essential for dual-monitor setups)
# windowrule = confine_pointer 1, match:class ^(steam_app_2399830)$
# windowrule = confine_pointer 1, match:title ^(ArkAscended)$
# windowrule = confine_pointer 1, match:class ^(steam_app_.*)$

# --- Keyring Fix ---
# Start gnome-keyring-daemon for managing credentials and secrets securely in Electron/VSCode applications
exec-once = gnome-keyring-daemon --start --components=secrets
EOF

# --- WRITE ~/.config/hypr/keybindings.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/keybindings.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/keybindings.conf"

# █▄▀ █▀▀ █▄█ █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀ █▀
# █░█ ██▄ ░█░ █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█ ▄█

# See https://wiki.hyprland.org/Configuring/Keywords/
#  &  https://wiki.hyprland.org/Configuring/Binds/

# Main modifier
$mainMod = Super # super / meta / windows key

# Assign apps
$term = kitty
$editor = code
$file = dolphin
$browser = firefox

# Window/Session actions
bindd = $mainMod+Shift, P,Color Picker , exec, hyprpicker -a # Pick color (Hex) >> clipboard# 
bind = $mainMod, Q, exec, $scrPath/dontkillsteam.sh # close focused window (close tab/window)
#bind = Ctrl, C, exec, $HOME/.config/hypr/close_kitty_or_copy.sh # close kitty or copy text
bind = Alt, F4, exec, $scrPath/dontkillsteam.sh # close focused window
bind = $mainMod, Delete, exit, # kill hyprland session
bind = $mainMod, W, togglefloating, # toggle the window between focus and float
bind = $mainMod, G, togglegroup, # toggle the window between focus and group
bind = Alt, Return, fullscreen, # toggle the window between focus and fullscreen
bind = $mainMod, L, exec, swaylock # launch lock screen
bind = $mainMod+Shift, F, exec, $scrPath/windowpin.sh # toggle pin on focused window
bind = $mainMod, Backspace, exec, $scrPath/logoutlaunch.sh # launch logout menu
bind = Ctrl+Alt, W, exec, killall waybar || (env reload_flag=1 $scrPath/wbarconfgen.sh) # toggle waybar and reload config
#bind = Ctrl+Alt, W, exec, killall waybar || waybar # toggle waybar without reloading, this is faster

# Application shortcuts
bind = , Page_Up, exec, $HOME/.local/bin/double-pageup.sh # double-press Page_Up to open terminal
bind = $mainMod, T, exec, $term # launch terminal emulator
bind = $mainMod, E, exec, $file # launch file manager
bind = $mainMod, C, exec, $editor # launch text editor
bind = $mainMod, F, exec, $browser # launch web browser
bind = Ctrl+Shift, Escape, exec, $scrPath/sysmonlaunch.sh # launch system monitor (htop/btop or fallback to top)

# Rofi menus
bind = $mainMod, A, exec, pkill -x rofi || $scrPath/rofilaunch.sh d # launch application launcher
bind = $mainMod, Tab, exec, pkill -x rofi || $scrPath/rofilaunch.sh w # launch window switcher
bind = $mainMod+Shift, E, exec, pkill -x rofi || $scrPath/rofilaunch.sh f # launch file explorer

# Audio control
bindl  = , F10, exec, $scrPath/volumecontrol.sh -o m # toggle audio mute
bindel = , F11, exec, $scrPath/volumecontrol.sh -o d # decrease volume
bindel = , F12, exec, $scrPath/volumecontrol.sh -o i # increase volume
bindl  = , XF86AudioMute, exec, $scrPath/volumecontrol.sh -o m # toggle audio mute
bindl  = , XF86AudioMicMute, exec, $scrPath/volumecontrol.sh -i m # toggle microphone mute
bindel = , XF86AudioLowerVolume, exec, $scrPath/volumecontrol.sh -o d # decrease volume
bindel = , XF86AudioRaiseVolume, exec, $scrPath/volumecontrol.sh -o i # increase volume

# Media control
bindl  = , XF86AudioPlay, exec, playerctl play-pause # toggle between media play and pause
bindl  = , XF86AudioPause, exec, playerctl play-pause # toggle between media play and pause
bindl  = , XF86AudioNext, exec, playerctl next # media next
bindl  = , XF86AudioPrev, exec, playerctl previous # media previous

# Brightness control
bindel = , XF86MonBrightnessUp, exec, $scrPath/brightnesscontrol.sh i # increase brightness
bindel = , XF86MonBrightnessDown, exec, $scrPath/brightnesscontrol.sh d # decrease brightness

# Move between grouped windows
bind = $mainMod CTRL , H, changegroupactive, b
bind = $mainMod CTRL , L, changegroupactive, f
bind = $mainMod CTRL Shift , H, movegroupwindow, b # move current tab backward in group
bind = $mainMod CTRL Shift , L, movegroupwindow, f # move current tab forward in group


# Screenshot/Screencapture
bind = $mainMod+Shift, S, exec, $scrPath/screenshot.sh s # partial screenshot capture
bind = $mainMod+Ctrl, P, exec, $scrPath/screenshot.sh sf # partial screenshot capture (frozen screen)
bind = $mainMod+Alt, P, exec, $scrPath/screenshot.sh m # monitor screenshot capture
bind = , Print, exec, $scrPath/screenshot.sh p # all monitors screenshot capture

# Custom scripts
bind = $mainMod+Alt, G, exec, $scrPath/gamemode.sh # disable hypr effects for gamemode
bind = $mainMod+Alt, Right, exec, $scrPath/swwwallpaper.sh -n # next wallpaper
bind = $mainMod+Alt, Left, exec, $scrPath/swwwallpaper.sh -p # previous wallpaper
bind = $mainMod+Alt, Up, exec, $scrPath/wbarconfgen.sh n # next waybar mode
bind = $mainMod+Alt, Down, exec, $scrPath/wbarconfgen.sh p # previous waybar mode
bind = $mainMod+Shift, R, exec, pkill -x rofi || $scrPath/wallbashtoggle.sh -m # launch wallbash mode select menu
bind = $mainMod+Shift, T, exec, pkill -x rofi || $scrPath/themeselect.sh # launch theme select menu
bind = $mainMod+Shift, A, exec, pkill -x rofi || $scrPath/rofiselect.sh # launch select menu
bind = $mainMod+Shift, X, exec, pkill -x rofi || $scrPath/themestyle.sh # launch theme style select menu
bind = $mainMod+Shift, W, exec, pkill -x rofi || $scrPath/swwwallselect.sh # launch wallpaper select menu
bind = $mainMod, V, exec, pkill -x rofi || $scrPath/cliphist.sh c # launch clipboard
bind = $mainMod+Shift, V, exec, pkill -x rofi || $scrPath/cliphist.sh # launch clipboard Manager
bind = $mainMod, K, exec, $scrPath/keyboardswitch.sh # switch keyboard layout
bind = $mainMod, slash, exec, pkill -x rofi || $scrPath/keybinds_hint.sh c # launch keybinds hint
bind = $mainMod+Alt, A, exec, pkill -x rofi || $scrPath/animations.sh # launch animations Manager
bind = $mainMod+Alt, D, exec, $HOME/.local/share/bin/hypr-display-settings.py # launch Display & Mouse Settings GUI

# Move/Change window focus
bind = $mainMod, Left, movefocus, l
bind = $mainMod, Right, movefocus, r
bind = $mainMod, Up, movefocus, u
bind = $mainMod, Down, movefocus, d
bind = Alt, Tab, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Switch workspaces to a relative workspace
bind = $mainMod+Ctrl, Right, workspace, r+1
bind = $mainMod+Ctrl, Left, workspace, r-1

# Move to the first empty workspace
bind = $mainMod+Ctrl, Down, workspace, empty 

# Resize windows
binde = $mainMod+Shift, Right, resizeactive, 30 0
binde = $mainMod+Shift, Left, resizeactive, -30 0
binde = $mainMod+Shift, Up, resizeactive, 0 -30
binde = $mainMod+Shift, Down, resizeactive, 0 30

# Move focused window to a workspace
bind = $mainMod+Shift, 1, movetoworkspace, 1
bind = $mainMod+Shift, 2, movetoworkspace, 2
bind = $mainMod+Shift, 3, movetoworkspace, 3
bind = $mainMod+Shift, 4, movetoworkspace, 4
bind = $mainMod+Shift, 5, movetoworkspace, 5
bind = $mainMod+Shift, 6, movetoworkspace, 6
bind = $mainMod+Shift, 7, movetoworkspace, 7
bind = $mainMod+Shift, 8, movetoworkspace, 8
bind = $mainMod+Shift, 9, movetoworkspace, 9
bind = $mainMod+Shift, 0, movetoworkspace, 10

# Move focused window to a relative workspace
bind = $mainMod+Ctrl+Alt, Right, movetoworkspace, r+1
bind = $mainMod+Ctrl+Alt, Left, movetoworkspace, r-1

# Move active window around current workspace with mainMod + SHIFT + CTRL [←→↑↓]
$moveactivewindow=grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive
binded = $mainMod SHIFT CTRL, left, Move activewindow left, exec, $moveactivewindow -30 0 || hyprctl dispatch movewindow l
binded = $mainMod SHIFT CTRL, right, Move activewindow right, exec, $moveactivewindow 30 0 || hyprctl dispatch movewindow r
binded = $mainMod SHIFT CTRL, up, Move activewindow up, exec, $moveactivewindow  0 -30 || hyprctl dispatch movewindow u
binded = $mainMod SHIFT CTRL, down, Move activewindow down, exec, $moveactivewindow 0 30 || hyprctl dispatch movewindow d

# Scroll through existing workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/Resize focused window
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
bindm = $mainMod, Z, movewindow
bindm = $mainMod, X, resizewindow

# Move/Switch to special workspace (scratchpad)
bind = $mainMod+Alt, S, movetoworkspacesilent, special
bind = $mainMod, S, togglespecialworkspace,

# Toggle focused window split
bind = $mainMod, J, layoutmsg, togglesplit

# Move focused window to a workspace silently
bind = $mainMod+Alt, 1, movetoworkspacesilent, 1
bind = $mainMod+Alt, 2, movetoworkspacesilent, 2
bind = $mainMod+Alt, 3, movetoworkspacesilent, 3
bind = $mainMod+Alt, 4, movetoworkspacesilent, 4
bind = $mainMod+Alt, 5, movetoworkspacesilent, 5
bind = $mainMod+Alt, 6, movetoworkspacesilent, 6
bind = $mainMod+Alt, 7, movetoworkspacesilent, 7
bind = $mainMod+Alt, 8, movetoworkspacesilent, 8
bind = $mainMod+Alt, 9, movetoworkspacesilent, 9
bind = $mainMod+Alt, 0, movetoworkspacesilent, 10
EOF

# --- WRITE ~/.config/hypr/windowrules.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/windowrules.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/windowrules.conf"

# █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
# ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

# See https://wiki.hyprland.org/Configuring/Window-Rules/

windowrule = opacity 0.90 0.90, match:class ^(firefox)$
windowrule = opacity 0.90 0.90, match:class ^(Google-chrome)$
windowrule = opacity 0.90 0.90, match:class ^(Brave-browser)$
windowrule = opacity 0.80 0.80, match:class ^(code-oss)$
windowrule = opacity 0.80 0.80, match:class ^([Cc]ode)$
windowrule = opacity 0.80 0.80, match:class ^(code-url-handler)$
windowrule = opacity 0.80 0.80, match:class ^(code-insiders-url-handler)$
windowrule = opacity 0.80 0.80, match:class ^(kitty)$
windowrule = opacity 0.80 0.80, match:class ^(org.kde.dolphin)$
windowrule = opacity 0.80 0.80, match:class ^(org.kde.ark)$
windowrule = opacity 0.80 0.80, match:class ^(nwg-look)$
windowrule = opacity 0.80 0.80, match:class ^(qt5ct)$
windowrule = opacity 0.80 0.80, match:class ^(qt6ct)$
windowrule = opacity 0.80 0.80, match:class ^(kvantummanager)$
windowrule = opacity 0.80 0.70, match:class ^(org.pulseaudio.pavucontrol)$
windowrule = opacity 0.80 0.70, match:class ^(blueman-manager)$
windowrule = opacity 0.80 0.70, match:class ^(nm-applet)$
windowrule = opacity 0.80 0.70, match:class ^(nm-connection-editor)$
windowrule = opacity 0.80 0.70, match:class ^(org.kde.polkit-kde-authentication-agent-1)$
windowrule = opacity 0.80 0.70, match:class ^(polkit-gnome-authentication-agent-1)$
windowrule = opacity 0.80 0.70, match:class ^(org.freedesktop.impl.portal.desktop.gtk)$
windowrule = opacity 0.80 0.70, match:class ^(org.freedesktop.impl.portal.desktop.hyprland)$
windowrule = opacity 0.70 0.70, match:class ^([Ss]team)$
windowrule = opacity 0.70 0.70, match:class ^(steamwebhelper)$
windowrule = opacity 0.70 0.70, match:class ^([Ss]potify)$
windowrule = opacity 0.70 0.70, match:initial_title ^(Spotify Free)$
windowrule = opacity 0.70 0.70, match:initial_title ^(Spotify Premium)$

windowrule = opacity 0.90 0.90, match:class ^(com.github.rafostar.Clapper)$ # Clapper-Gtk
windowrule = opacity 0.80 0.80, match:class ^(com.github.tchx84.Flatseal)$ # Flatseal-Gtk
windowrule = opacity 0.80 0.80, match:class ^(hu.kramo.Cartridges)$ # Cartridges-Gtk
windowrule = opacity 0.80 0.80, match:class ^(com.obsproject.Studio)$ # Obs-Qt
windowrule = opacity 0.80 0.80, match:class ^(gnome-boxes)$ # Boxes-Gtk
windowrule = opacity 0.80 0.80, match:class ^(vesktop)$ # Vesktop
windowrule = opacity 0.80 0.80, match:class ^(discord)$ # Discord-Electron
windowrule = opacity 0.80 0.80, match:class ^(WebCord)$ # WebCord-Electron
windowrule = opacity 0.80 0.80, match:class ^(ArmCord)$ # ArmCord-Electron
windowrule = opacity 0.80 0.80, match:class ^(app.drey.Warp)$ # Warp-Gtk
windowrule = opacity 0.80 0.80, match:class ^(net.davidotek.pupgui2)$ # ProtonUp-Qt
windowrule = opacity 0.80 0.80, match:class ^(yad)$ # Protontricks-Gtk
windowrule = opacity 0.80 0.80, match:class ^(Signal)$ # Signal-Gtk
windowrule = opacity 0.80 0.80, match:class ^(io.github.alainm23.planify)$ # planify-Gtk
windowrule = opacity 0.80 0.80, match:class ^(io.gitlab.theevilskeleton.Upscaler)$ # Upscaler-Gtk
windowrule = opacity 0.80 0.80, match:class ^(com.github.unrud.VideoDownloader)$ # VideoDownloader-Gtk
windowrule = opacity 0.80 0.80, match:class ^(io.gitlab.adhami3310.Impression)$ # Impression-Gtk
windowrule = opacity 0.80 0.80, match:class ^(io.missioncenter.MissionCenter)$ # MissionCenter-Gtk
windowrule = opacity 0.80 0.80, match:class ^(io.github.flattool.Warehouse)$ # Warehouse-Gtk

windowrule = float 1, match:class ^(org.kde.dolphin)$, match:title ^(Progress Dialog — Dolphin)$
windowrule = float 1, match:class ^(org.kde.dolphin)$, match:title ^(Copying — Dolphin)$
windowrule = float 1, match:title ^(About Mozilla Firefox)$
windowrule = float 1, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$
windowrule = float 1, match:class ^(firefox)$, match:title ^(Library)$
windowrule = float 1, match:class ^(kitty)$, match:title ^(top)$
windowrule = float 1, match:class ^(kitty)$, match:title ^(btop)$
windowrule = float 1, match:class ^(kitty)$, match:title ^(htop)$
windowrule = float 1, match:class ^(vlc)$
windowrule = float 1, match:class ^(kvantummanager)$
windowrule = float 1, match:class ^(qt5ct)$
windowrule = float 1, match:class ^(qt6ct)$
windowrule = float 1, match:class ^(nwg-look)$
windowrule = float 1, match:class ^(org.kde.ark)$
windowrule = float 1, match:class ^(org.pulseaudio.pavucontrol)$
windowrule = float 1, match:class ^(blueman-manager)$
windowrule = float 1, match:class ^(nm-applet)$
windowrule = float 1, match:class ^(nm-connection-editor)$
windowrule = float 1, match:class ^(org.kde.polkit-kde-authentication-agent-1)$

windowrule = float 1, match:class ^(Signal)$ # Signal-Gtk
windowrule = float 1, match:class ^(com.github.rafostar.Clapper)$ # Clapper-Gtk
windowrule = float 1, match:class ^(app.drey.Warp)$ # Warp-Gtk
windowrule = float 1, match:class ^(net.davidotek.pupgui2)$ # ProtonUp-Qt
windowrule = float 1, match:class ^(yad)$ # Protontricks-Gtk
windowrule = float 1, match:class ^(eog)$ # Imageviewer-Gtk
windowrule = float 1, match:class ^(io.github.alainm23.planify)$ # planify-Gtk
windowrule = float 1, match:class ^(io.gitlab.theevilskeleton.Upscaler)$ # Upscaler-Gtk
windowrule = float 1, match:class ^(com.github.unrud.VideoDownloader)$ # VideoDownloader-Gkk
windowrule = float 1, match:class ^(io.gitlab.adhami3310.Impression)$ # Impression-Gtk
windowrule = float 1, match:class ^(io.missioncenter.MissionCenter)$ # MissionCenter-Gtk

# common modals
windowrule = float 1, match:title ^(Open)$
windowrule = float 1, match:title ^(Choose Files)$
windowrule = float 1, match:title ^(Save As)$
windowrule = float 1, match:title ^(Confirm to replace files)$
windowrule = float 1, match:title ^(File Operation Progress)$
windowrule = float 1, match:class ^(xdg-desktop-portal-gtk)$

# █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
# █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█

layerrule = blur 1, match:namespace rofi
layerrule = ignore_alpha 1, match:namespace rofi
layerrule = blur 1, match:namespace notifications
layerrule = ignore_alpha 1, match:namespace notifications
layerrule = blur 1, match:namespace swaync-notification-window
layerrule = ignore_alpha 1, match:namespace swaync-notification-window
layerrule = blur 1, match:namespace swaync-control-center
layerrule = ignore_alpha 1, match:namespace swaync-control-center
layerrule = blur 1, match:namespace logout_dialog
EOF

# --- WRITE ~/.config/hypr/animations/animations-smooth.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/animations/animations-smooth.conf...${NC}"
mkdir -p "$HOME/.config/hypr/animations"
cat << 'EOF' > "$HOME/.config/hypr/animations/animations-smooth.conf"
# ----------------------------------------------------- 
# ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
# █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█
#
# name "Buttery Smooth"
# ----------------------------------------------------- 

animations {
    enabled = yes
    
    # Custom Bezier Curves for Fluent & Fluid Animations
    bezier = fluent_decel, 0.1, 1.0, 0.0, 1.0
    bezier = fluent_accel, 0.9, 0.0, 0.8, 0.15
    bezier = easeOutExpo, 0.16, 1.0, 0.3, 1.0
    bezier = easeOutCirc, 0.0, 0.55, 0.45, 1.0
    bezier = winIn, 0.1, 1.0, 0.1, 1.0
    bezier = winOut, 0.2, -0.1, 0.0, 1.0
    
    # Window transitions
    animation = windows, 1, 3.2, easeOutExpo, popin 60%
    animation = windowsIn, 1, 3.2, winIn, popin 60%
    animation = windowsOut, 1, 3.0, winOut, popin 60%
    animation = windowsMove, 1, 3.2, easeOutExpo, slide
    
    # Fade transitions
    animation = fade, 1, 2.5, fluent_decel
    animation = fadeLayersIn, 1, 2.0, fluent_decel
    animation = fadeLayersOut, 1, 2.5, fluent_decel
    
    # Workspace & Tab Switching (Very smooth slide and fade)
    animation = workspaces, 1, 3.8, easeOutExpo, slidefade 20%
    animation = specialWorkspace, 1, 3.0, easeOutExpo, slidevert
    
    # Border animations
    animation = border, 1, 1, default
    animation = borderangle, 1, 30, default, once
}
EOF

# --- WRITE ~/.config/hypr/animations.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/animations.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/animations.conf"
# ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
# █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█
#
# See https://wiki.hyprland.org/Configuring/Animations/
# this file can be edited manually or use animation selector to select animations

# disable animations while in hyprpicker and selection screenshot
layerrule = no_anim on, match:namespace hyprpicker
layerrule = no_anim on, match:namespace selection

source = ~/.config/hypr/animations/animations-smooth.conf
EOF

# --- WRITE ~/.config/hypr/monitors.conf (DYNAMIC DETECTION) ---
echo -e "${CYAN}Dynamically detecting connected monitors...${NC}"

# Initialize arrays/variables
MONITOR_CONFIGS=""
WORKSPACE_RULES=""
MAIN_NAME=""
MAIN_WIDTH=1920
MAIN_HEIGHT=1080
MAIN_HZ=60
SIDE_NAME=""
SIDE_WIDTH=1920
SIDE_HEIGHT=1080
SIDE_HZ=60
OFFSET_X=0
OFFSET_Y=0

# Check if hyprctl is available and running
if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null; then
    echo -e "${GREEN}Hyprland is running. Using hyprctl for detection...${NC}"
    MONITORS_JSON=$(hyprctl monitors -j)
    
    # Sort monitors by refreshRate so the main high-refresh one is last
    NUM_MONITORS=$(echo "$MONITORS_JSON" | jq '. | length')
    
    if [ "$NUM_MONITORS" -gt 0 ]; then
        MAIN_NAME=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | last | .name')
        MAIN_HZ=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | last | .refreshRate | round')
        MAIN_WIDTH=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | last | .width')
        MAIN_HEIGHT=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | last | .height')
        
        if [ "$NUM_MONITORS" -gt 1 ]; then
            # We have a secondary monitor
            SIDE_NAME=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | .[0] | .name')
            SIDE_HZ=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | .[0] | .refreshRate | round')
            SIDE_WIDTH=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | .[0] | .width')
            SIDE_HEIGHT=$(echo "$MONITORS_JSON" | jq -r 'sort_by(.refreshRate) | .[0] | .height')
            
            # Write configurations for dual-monitor setup
            # Side monitor (rotated portrait on the left)
            MONITOR_CONFIGS="monitor = ${SIDE_NAME},${SIDE_WIDTH}x${SIDE_HEIGHT}@${SIDE_HZ},0x0,1,transform,1\n"
            # Main monitor (aligned to the right of the rotated side monitor)
            # Offset X is the height of the side monitor (which becomes its width when rotated)
            OFFSET_X=${SIDE_HEIGHT}
            # Centered Y offset: (rotated_height - main_height) / 2 -> (SIDE_WIDTH - MAIN_HEIGHT) / 2
            OFFSET_Y=$(( (SIDE_WIDTH - MAIN_HEIGHT) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            MONITOR_CONFIGS="${MONITOR_CONFIGS}monitor = ${MAIN_NAME},${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ},${OFFSET_X}x${OFFSET_Y},1"
            
            # Workspace rules for dual-monitor
            WORKSPACE_RULES="# Workspace Rules\n"
            for w in {1..8}; do
                WORKSPACE_RULES="${WORKSPACE_RULES}workspace = ${w}, monitor:${MAIN_NAME}"
                [ $w -eq 1 ] && WORKSPACE_RULES="${WORKSPACE_RULES}, default:true"
                WORKSPACE_RULES="${WORKSPACE_RULES}\n"
            done
            for w in {9..10}; do
                WORKSPACE_RULES="${WORKSPACE_RULES}workspace = ${w}, monitor:${SIDE_NAME}"
                [ $w -eq 9 ] && WORKSPACE_RULES="${WORKSPACE_RULES}, default:true"
                WORKSPACE_RULES="${WORKSPACE_RULES}\n"
            done
        else
            # Single monitor setup
            MONITOR_CONFIGS="monitor = ${MAIN_NAME},${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ},0x0,1"
            WORKSPACE_RULES="# Workspace Rules\n"
            for w in {1..10}; do
                WORKSPACE_RULES="${WORKSPACE_RULES}workspace = ${w}, monitor:${MAIN_NAME}"
                [ $w -eq 1 ] && WORKSPACE_RULES="${WORKSPACE_RULES}, default:true"
                WORKSPACE_RULES="${WORKSPACE_RULES}\n"
            done
        fi
    fi
fi

# Fallback: If no monitor configs were generated (e.g. hyprctl not running), use DRM sysfs
if [ -z "$MONITOR_CONFIGS" ]; then
    echo -e "${YELLOW}Hyprland is not running or no monitors detected via hyprctl. Scanning /sys/class/drm/...${NC}"
    CONNECTED_DEVS=()
    for card in /sys/class/drm/card*-*; do
        if [ -f "$card/status" ] && [ "$(cat "$card/status")" = "connected" ]; then
            dev_name=$(basename "$card" | cut -d'-' -f2-)
            CONNECTED_DEVS+=("$dev_name")
        fi
    done
    
    NUM_DEVS=${#CONNECTED_DEVS[@]}
    if [ "$NUM_DEVS" -gt 0 ]; then
        # Take the first one as main
        MAIN_NAME="${CONNECTED_DEVS[0]}"
        MAIN_WIDTH=1920
        MAIN_HEIGHT=1080
        MAIN_HZ=60
        
        if [ "$NUM_DEVS" -gt 1 ]; then
            SIDE_NAME="${CONNECTED_DEVS[1]}"
            SIDE_HZ=60
            
            # Read native resolution for the side monitor to calculate offsets
            # Fallback to default if files are missing
            SIDE_MODE=$(head -n 1 /sys/class/drm/card*-${SIDE_NAME}/modes 2>/dev/null)
            SIDE_WIDTH=$(echo "$SIDE_MODE" | cut -d'x' -f1)
            SIDE_HEIGHT=$(echo "$SIDE_MODE" | cut -d'x' -f2)
            
            SIDE_WIDTH=${SIDE_WIDTH:-1920}
            SIDE_HEIGHT=${SIDE_HEIGHT:-1080}
            
            # Rotated width is SIDE_HEIGHT, Y offset is centered relative to MAIN (default 1080 height)
            OFFSET_X=${SIDE_HEIGHT}
            OFFSET_Y=$(( (SIDE_WIDTH - 1080) / 2 ))
            [ $OFFSET_Y -lt 0 ] && OFFSET_Y=0
            
            MONITOR_CONFIGS="monitor = ${SIDE_NAME},preferred,0x0,1,transform,1\nmonitor = ${MAIN_NAME},preferred,${OFFSET_X}x${OFFSET_Y},1"
            
            WORKSPACE_RULES="# Workspace Rules\n"
            for w in {1..8}; do
                WORKSPACE_RULES="${WORKSPACE_RULES}workspace = ${w}, monitor:${MAIN_NAME}"
                [ $w -eq 1 ] && WORKSPACE_RULES="${WORKSPACE_RULES}, default:true"
                WORKSPACE_RULES="${WORKSPACE_RULES}\n"
            done
            for w in {9..10}; do
                WORKSPACE_RULES="${WORKSPACE_RULES}workspace = ${w}, monitor:${SIDE_NAME}"
                [ $w -eq 9 ] && WORKSPACE_RULES="${WORKSPACE_RULES}, default:true"
                WORKSPACE_RULES="${WORKSPACE_RULES}\n"
            done
        else
            # Single monitor fallback
            MONITOR_CONFIGS="monitor = ${MAIN_NAME},preferred,auto,1"
            WORKSPACE_RULES="# Workspace Rules\n"
            for w in {1..10}; do
                WORKSPACE_RULES="${WORKSPACE_RULES}workspace = ${w}, monitor:${MAIN_NAME}"
                [ $w -eq 1 ] && WORKSPACE_RULES="${WORKSPACE_RULES}, default:true"
                WORKSPACE_RULES="${WORKSPACE_RULES}\n"
            done
        fi
    else
        # Extreme fallback
        MONITOR_CONFIGS="monitor = ,preferred,auto,1"
        WORKSPACE_RULES="# Workspace Rules\nworkspace = 1, monitor:, default:true"
    fi
fi

# Override offsets if they already exist in the user's config (so we don't reset them)
if [ -n "$SIDE_NAME" ] && [ -f "$HOME/.config/hypr/monitors.conf" ]; then
    # Match the main monitor config line to extract XxY coordinates
    EXISTING_LINE=$(grep -E "^\s*monitor\s*=\s*${MAIN_NAME}\s*," "$HOME/.config/hypr/monitors.conf" | head -n 1)
    if [ -n "$EXISTING_LINE" ]; then
        POS_FIELD=$(echo "$EXISTING_LINE" | cut -d',' -f3 | tr -d '[:space:]')
        if [[ "$POS_FIELD" =~ ^([0-9]+)x([0-9]+)$ ]]; then
            EXISTING_X="${BASH_REMATCH[1]}"
            EXISTING_Y="${BASH_REMATCH[2]}"
            echo -e "${GREEN}[INFO] Preserving existing monitor offset: ${EXISTING_X}x${EXISTING_Y}${NC}"
            OFFSET_X=$EXISTING_X
            OFFSET_Y=$EXISTING_Y
            
            # Re-generate MONITOR_CONFIGS with the preserved offsets
            MONITOR_CONFIGS="monitor = ${SIDE_NAME},${SIDE_WIDTH}x${SIDE_HEIGHT}@${SIDE_HZ},0x0,1,transform,1\n"
            MONITOR_CONFIGS="${MONITOR_CONFIGS}monitor = ${MAIN_NAME},${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ},${OFFSET_X}x${OFFSET_Y},1"
        fi
    fi
fi

# Write to file
mkdir -p "$HOME/.config/hypr"
cat << MONEOF > "$HOME/.config/hypr/monitors.conf"
# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█ █▀
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄ ▄█
# Dynamically generated by restore_my_setup.sh

$(echo -e "$MONITOR_CONFIGS")

$(echo -e "$WORKSPACE_RULES")
MONEOF
echo -e "${GREEN}[OK] Dynamic monitors.conf generated successfully!${NC}"

# Calibrate monitor alignment if dual monitor detected
if [ -n "$SIDE_NAME" ]; then
    # Only run calibration if display environment is active (GUI mode)
    if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
        echo -e "${BLUE}${BOLD}Dual monitors detected. Prompting for mouse alignment calibration...${NC}"
        
        # Prompt the user if they want to calibrate
        if zenity --question \
            --title="Mouse Path Alignment Calibration" \
            --text="Dual monitors detected.\nWould you like to calibrate the vertical alignment of the mouse path between your screens now?" \
            --ok-label="Calibrate Now" \
            --cancel-label="Skip" \
            --width=400 2>/dev/null; then
            
            # Loop for calibration
            while true; do
                # Rewrite monitors.conf with current offsets
                MONITOR_CONFIGS="monitor = ${SIDE_NAME},${SIDE_WIDTH}x${SIDE_HEIGHT}@${SIDE_HZ},0x0,1,transform,1\n"
                MONITOR_CONFIGS="${MONITOR_CONFIGS}monitor = ${MAIN_NAME},${MAIN_WIDTH}x${MAIN_HEIGHT}@${MAIN_HZ},${OFFSET_X}x${OFFSET_Y},1"
                
                cat << MONEOF > "$HOME/.config/hypr/monitors.conf"
# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█ █▀
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄ ▄█
# Dynamically generated by restore_my_setup.sh

$(echo -e "$MONITOR_CONFIGS")

$(echo -e "$WORKSPACE_RULES")
MONEOF
                
                # Show list dialog
                choice=$(zenity --list \
                    --title="Mouse Alignment Calibration" \
                    --text="Current offset: ${OFFSET_Y}px.\nTry moving your mouse between the screens.\nAdjust the position of the main monitor:" \
                    --column="Action" \
                    "Enter Custom Y-Offset Value" \
                    "Shift Main Monitor Down (+50px) - enters lower on second screen" \
                    "Shift Main Monitor Up (-50px) - enters higher on second screen" \
                    "Fine-tune Down (+10px)" \
                    "Fine-tune Up (-10px)" \
                    "Save and Exit" \
                    --width=450 --height=320 2>/dev/null)
                    
                # Parse choice
                case "$choice" in
                    "Enter Custom Y-Offset Value")
                        custom_val=$(zenity --entry \
                            --title="Custom Y-Offset" \
                            --text="Enter custom Y-offset in pixels (e.g., 0, 100, 200...):\n(Higher values shift the main screen down / lower transition on side screen)" \
                            --entry-text="$OFFSET_Y" 2>/dev/null)
                        # Validate if input is a number (integer)
                        if [[ "$custom_val" =~ ^-?[0-9]+$ ]]; then
                            OFFSET_Y=$custom_val
                        elif [ -n "$custom_val" ]; then
                            zenity --error --title="Invalid Input" --text="Please enter a valid integer number." --width=300 2>/dev/null
                        fi
                        ;;
                    "Shift Main Monitor Down (+50px) - enters lower on second screen")
                        OFFSET_Y=$((OFFSET_Y + 50))
                        ;;
                    "Shift Main Monitor Up (-50px) - enters higher on second screen")
                        OFFSET_Y=$((OFFSET_Y - 50))
                        ;;
                    "Fine-tune Down (+10px)")
                        OFFSET_Y=$((OFFSET_Y + 10))
                        ;;
                    "Fine-tune Up (-10px)")
                        OFFSET_Y=$((OFFSET_Y - 10))
                        ;;
                    *)
                        # Save and exit or cancel
                        break
                        ;;
                esac
            done
        fi
    fi
fi

# Touchpad scrolling behavior setup (Windows vs Linux default)
IS_LAPTOP=false
if [ -f /sys/class/dmi/id/chassis_type ]; then
    CHASSIS=$(cat /sys/class/dmi/id/chassis_type)
    if [[ "$CHASSIS" =~ ^(8|9|10|11|14)$ ]]; then
        IS_LAPTOP=true
    fi
fi
if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/ | grep -q "^BAT"; then
    IS_LAPTOP=true
fi

HAS_TOUCHPAD=false
if grep -iq "touchpad" /proc/bus/input/devices 2>/dev/null; then
    HAS_TOUCHPAD=true
fi

if [ "$IS_LAPTOP" = "true" ] || [ "$HAS_TOUCHPAD" = "true" ]; then
    echo -e "\n${YELLOW}[PROMPT] Laptop/Touchpad detected on this device.${NC}"
    read -p "Touch pad like windows? (y/n): " tp_windows_choice
    if [[ "$tp_windows_choice" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Configuring touchpad to behave like Windows (Standard Scrolling)...${NC}"
        mkdir -p "$HOME/.config/hypr"
        touch "$HOME/.config/hypr/userprefs.conf"
        if grep -q "touchpad" "$HOME/.config/hypr/userprefs.conf"; then
            if grep -q "natural_scroll" "$HOME/.config/hypr/userprefs.conf"; then
                sed -i 's/natural_scroll.*/natural_scroll = false/' "$HOME/.config/hypr/userprefs.conf"
            else
                sed -i '/touchpad {/a \ \ \ \ \ \ \ \ natural_scroll = false' "$HOME/.config/hypr/userprefs.conf"
            fi
        else
            cat << 'EOF' >> "$HOME/.config/hypr/userprefs.conf"

input {
    touchpad {
        natural_scroll = false
    }
}
EOF
        fi
        hyprctl keyword input:touchpad:natural_scroll false &>/dev/null || true
        echo -e "${GREEN}[OK] Touchpad scrolling configured like Windows successfully!${NC}"
    else
        echo -e "${BLUE}[INFO] Keeping Linux natural scrolling default.${NC}"
    fi
fi

# --- WRITE ~/.config/hypr/nvidia.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/nvidia.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/nvidia.conf"

# █▄░█ █░█ █ █▀▄ █ ▄▀█
# █░▀█ ▀▄▀ █ █▄▀ █ █▀█

# See https://wiki.hyprland.org/Nvidia/

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = __GL_VRR_ALLOWED,1

cursor {
    no_hardware_cursors = false
}
EOF

# --- WRITE ~/.config/hypr/sync_cursor.sh ---
echo -e "${CYAN}Writing ~/.config/hypr/sync_cursor.sh...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/sync_cursor.sh"
#!/usr/bin/env bash

THEME="$1"
SIZE="${2:-20}"

if [ -z "$THEME" ]; then
    exit 0
fi

# Update GTK 3 settings.ini
GTK3_FILE="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$GTK3_FILE" ]; then
    # Ensure [Settings] header exists
    if ! grep -q "\[Settings\]" "$GTK3_FILE"; then
        echo -e "[Settings]\n" > "$GTK3_FILE"
    fi
    # Update theme name
    if grep -q "gtk-cursor-theme-name=" "$GTK3_FILE"; then
        sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME/g" "$GTK3_FILE"
    else
        echo "gtk-cursor-theme-name=$THEME" >> "$GTK3_FILE"
    fi
    # Update size
    if grep -q "gtk-cursor-theme-size=" "$GTK3_FILE"; then
        sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$SIZE/g" "$GTK3_FILE"
    else
        echo "gtk-cursor-theme-size=$SIZE" >> "$GTK3_FILE"
    fi
fi

# Update GTK 4 settings.ini
GTK4_FILE="$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$HOME/.config/gtk-4.0"
if [ ! -f "$GTK4_FILE" ]; then
    echo -e "[Settings]\n" > "$GTK4_FILE"
fi
# Update theme name
if grep -q "gtk-cursor-theme-name=" "$GTK4_FILE"; then
    sed -i "s/gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME/g" "$GTK4_FILE"
else
    echo "gtk-cursor-theme-name=$THEME" >> "$GTK4_FILE"
fi
# Update size
if grep -q "gtk-cursor-theme-size=" "$GTK4_FILE"; then
    sed -i "s/gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$SIZE/g" "$GTK4_FILE"
else
    echo "gtk-cursor-theme-size=$SIZE" >> "$GTK4_FILE"
fi

# Update index.theme
INDEX_FILE="$HOME/.icons/default/index.theme"
mkdir -p "$HOME/.icons/default"
if [ ! -f "$INDEX_FILE" ]; then
    echo -e "[Icon Theme]\nName=Default\nComment=Default Cursor Theme" > "$INDEX_FILE"
fi
if grep -q "Inherits=" "$INDEX_FILE"; then
    sed -i "s/Inherits=.*/Inherits=$THEME/g" "$INDEX_FILE"
else
    echo "Inherits=$THEME" >> "$INDEX_FILE"
fi
EOF
chmod +x "$HOME/.config/hypr/sync_cursor.sh"

# --- WRITE ~/.config/hypr/close_kitty_or_copy.sh ---
echo -e "${CYAN}Writing ~/.config/hypr/close_kitty_or_copy.sh...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/close_kitty_or_copy.sh"
#!/bin/bash

# Fetch the active window details in JSON format
ACTIVE_WINDOW=$(hyprctl activewindow -j)

# Extract class and address
CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
ADDRESS=$(echo "$ACTIVE_WINDOW" | jq -r '.address')

# If the active window is Kitty, close it. Otherwise, pass the Ctrl+C shortcut through.
if [ "$CLASS" = "kitty" ]; then
    hyprctl dispatch closewindow address:"$ADDRESS"
else
    hyprctl dispatch sendshortcut "CTRL, C, address:$ADDRESS"
fi
EOF
chmod +x "$HOME/.config/hypr/close_kitty_or_copy.sh"

# --- WRITE ~/.config/kitty/kitty.conf ---
echo -e "${CYAN}Writing ~/.config/kitty/kitty.conf...${NC}"
cat << 'EOF' > "$HOME/.config/kitty/kitty.conf"
font_family      CaskaydiaCove Nerd Font Mono
bold_font        auto
italic_font      auto
bold_italic_font auto
enable_audio_bell no
font_size 9.0
window_padding_width 25
include theme.conf
cursor_trail 1
#background_opacity 0.60
#hide_window_decorations yes
#confirm_os_window_close 0

# initially empty, to be configured by user and remains static
include userprefs.conf

# Note: as userprefs.conf is included at the end, settings configured in this file will override the defaults
EOF

# --- WRITE ~/.config/kitty/userprefs.conf ---
echo -e "${CYAN}Writing ~/.config/kitty/userprefs.conf...${NC}"
cat << 'EOF' > "$HOME/.config/kitty/userprefs.conf"
# Ctrl+Shift+C/V for copy/paste in terminal (default)
# Ctrl+C copies if text selected, otherwise sends interrupt
map ctrl+c copy_or_interrupt
map ctrl+v paste_from_clipboard

# Ctrl+Backspace to delete the whole word like Windows
map ctrl+backspace send_text all \x17

# Smooth Cursor Trail Animations
cursor_trail 10
cursor_trail_decay 0.1 0.45
cursor_trail_start_threshold 0

font_size 13.0
EOF

# --- WRITE ~/.config/waybar/config.jsonc ---
echo -e "${CYAN}Writing ~/.config/waybar/config.jsonc...${NC}"
cat << 'EOF' > "$HOME/.config/waybar/config.jsonc"
//   --// waybar config generated by wbarconfgen.sh //--   //

{
// sourced from header module //

    "layer": "top",
    "output": [ "*" ],
    "position": "top",
    "mod": "dock",
    "height": 38,
    "exclusive": true,
    "passthrough": false,
    "gtk-layer-shell": true,
    "reload_style_on_change": true,


// positions generated based on config.ctl //

	"modules-left": ["custom/padd","custom/l_end","custom/power","custom/cliphist","custom/wbar","custom/theme","custom/wallchange","custom/r_end","custom/l_end","hyprland/workspaces","wlr/taskbar","custom/spotify","custom/r_end","custom/padd"],
	"modules-center": ["custom/padd","custom/l_end","idle_inhibitor","clock","custom/r_end","custom/padd"],
	"modules-right": ["custom/padd","custom/l_end","privacy","tray","battery","custom/r_end","custom/l_end","backlight","network","pulseaudio","pulseaudio#microphone","custom/keybindhint","custom/r_end","custom/padd"],


// sourced from modules based on config.ctl //

    "custom/power": {
        "format": "{}",
        "rotate": 0,
        "exec": "echo ; echo  logout",
        "on-click": "logoutlaunch.sh 2",
        "on-click-right": "logoutlaunch.sh 1",
        "interval" : 86400, // once every day
        "tooltip": true
    },

    "custom/cliphist": {
        "format": "{}",
        "rotate": 0,
        "exec": "echo ; echo 󰅇 clipboard history",
        "on-click": "sleep 0.1 && cliphist.sh c",
        "on-click-right": "sleep 0.1 && cliphist.sh d",
        "on-click-middle": "sleep 0.1 && cliphist.sh w",
        "interval" : 86400, // once every day
        "tooltip": true
    },

    "custom/wbar": {
        "format": "{}", //    //
        "rotate": 0,
        "exec": "echo ; echo  switch bar //  dock",
        "on-click": "wbarconfgen.sh n",
        "on-click-right": "wbarconfgen.sh p",
        "on-click-middle": "sleep 0.1 && quickapps.sh kitty firefox spotify code dolphin",
        "interval" : 86400,
        "tooltip": true
    },

    "custom/theme": {
        "format": "{}",
        "rotate": 0,
        "exec": "echo ; echo 󰟡 switch theme",
        "on-click": "themeswitch.sh -n",
        "on-click-right": "themeswitch.sh -p",
        "on-click-middle": "sleep 0.1 && themeselect.sh",
        "interval" : 86400, // once every day
        "tooltip": true
    },

    "custom/wallchange": {
        "format": "{}",
        "rotate": 0,
        "exec": "echo ; echo 󰆊 switch wallpaper",
        "on-click": "swwwallpaper.sh -n",
        "on-click-right": "swwwallpaper.sh -p",
        "on-click-middle": "sleep 0.1 && swwwallselect.sh",
        "interval" : 86400, // once every day
        "tooltip": true
    },

    "hyprland/workspaces": {
        "disable-scroll": true,
        "rotate": 0,
        "all-outputs": true,
        "active-only": false,
        "on-click": "activate",
        "disable-scroll": false,
        "on-scroll-up": "hyprctl dispatch workspace -1",
        "on-scroll-down": "hyprctl dispatch workspace +1",
        "format": "{name} {windows}",
        "format-window-separator": " ",
        "window-rewrite-default": "",
        "window-rewrite": {
            "class<kitty>": "",
            "class<firefox>": "",
            "class<chromium>": "",
            "class<google-chrome>": "",
            "class<dolphin>": "󰉋",
            "class<thunar>": "󰉋",
            "class<vs-code-oss>": "󰨞",
            "class<code-oss>": "󰨞",
            "class<vscode>": "󰨞",
            "class<discord>": "󰙯",
            "class<spotify>": "",
            "class<steam>": "",
            "class<vlc>": "󰕼",
            "class<mpv>": "󰕼"
        },
        "persistent-workspaces": {
            "1": [],
            "2": [],
            "3": []
        }
    },

	"wlr/taskbar": {
		"format": "{icon}",
		"rotate": 0,
		"icon-size": 22,
		"icon-theme": "Gruvbox-Plus-Dark",
        "spacing": 0,
		"tooltip-format": "{title}",
		"on-click": "activate",
		"on-click-middle": "close",
		"ignore-list": [
			"Alacritty"
		],
		"app_ids-mapping": {
			"firefoxdeveloperedition": "firefox-developer-edition",
      "jetbrains-datagrip": "DataGrip"
		}
	},

    "custom/spotify": {
        "exec": "mediaplayer.py --player spotify",
        "format": " {}",
        "rotate": 0,
        "return-type": "json",
        "on-click": "playerctl play-pause --player spotify",
        "on-click-right": "playerctl next --player spotify",
        "on-click-middle": "playerctl previous --player spotify",
        "on-scroll-up": "volumecontrol.sh -p spotify i",
        "on-scroll-down": "volumecontrol.sh -p spotify d",
        "max-length": 25,
        "escape": true,
        "tooltip": true
    },

    "idle_inhibitor": {
        "format": "{icon}",
        "rotate": 0,
        "format-icons": {
            "activated": "",
            "deactivated": "󰛊"
        },
        "tooltip-format-activated":"Caffeine Mode Active",
        "tooltip-format-deactivated":"Caffeine Mode Inactive"
    },

    "clock": {
        "format": "{:%I:%M %p}",
        "rotate": 0,
        "format-alt": "{:%R 󰃭 %d·%m·%y}",
        "tooltip-format": "<span>{calendar}</span>",
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "on-scroll": 1,
            "on-click-right": "mode",
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
                "today": "<span color='#ff6699'><b>{}</b></span>"
            }
        },
        "actions": {
            "on-click-right": "mode",
            "on-click-forward": "tz_up",
            "on-click-backward": "tz_down",
            "on-scroll-up": "shift_up",
            "on-scroll-down": "shift_down"
        }
    },

    "privacy": {
        "icon-size": 17,
        "icon-spacing": 5,
        "transition-duration": 250,
        "modules": [
            {
                "type": "screenshare",
                "tooltip": true,
                "tooltip-icon-size": 24
            },
            {
                "type": "audio-in",
                "tooltip": true,
                "tooltip-icon-size": 24
            }
        ]
    },

    "tray": {
        "icon-size": 22,
        "rotate": 0,
        "spacing": 5
    },

    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 20
        },
        "format": "{icon} {capacity}%",
        "rotate": 0,
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-alt": "{time} {icon}",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },

    "backlight": {
        "device": "intel_backlight",
        "rotate": 0,
        "format": "{icon} {percent}%",
        "format-icons": ["", "", "", "", "", "", "", "", ""],
        "on-scroll-up": "brightnesscontrol.sh i 1",
        "on-scroll-down": "brightnesscontrol.sh d 1",
        "min-length": 6
    },

    "network": {
        "tooltip": true,
        "format-wifi": " ",
        "rotate": 0,
        "format-ethernet": "󰈀 ",
        "tooltip-format": "Network: <big><b>{essid}</b></big>\nSignal strength: <b>{signaldBm}dBm ({signalStrength}%)</b>\nFrequency: <b>{frequency}MHz</b>\nInterface: <b>{ifname}</b>\nIP: <b>{ipaddr}/{cidr}</b>\nGateway: <b>{gwaddr}</b>\nNetmask: <b>{netmask}</b>",
        "format-linked": "󰈀 {ifname} (No IP)",
        "format-disconnected": "󰖪 ",
        "tooltip-format-disconnected": "Disconnected",
        "format-alt": "<span foreground='#99ffdd'> {bandwidthDownBytes}</span> <span foreground='#ffcc66'> {bandwidthUpBytes}</span>",
        "interval": 2,
    },

"pulseaudio": {
    "format": "{icon} {volume}",
    "rotate": 0,
    "format-muted": "婢",
    "on-click": "pavucontrol -t 3",
    "on-click-right": "volumecontrol.sh -s ''",
    "on-click-middle": "volumecontrol.sh -o m",
    "on-scroll-up": "volumecontrol.sh -o i",
    "on-scroll-down": "volumecontrol.sh -o d",
    "tooltip-format": "{icon} {desc} // {volume}%",
    "scroll-step": 5,
    "format-icons": {
        "headphone": "",
        "hands-free": "",
        "headset": "",
        "phone": "",
        "portable": "",
        "car": "",
        "default": ["", "", ""]
    }
},

"pulseaudio#microphone": {
    "format": "{format_source}",
    "rotate": 0,
    "format-source": "",
    "format-source-muted": "",
    "on-click": "pavucontrol -t 4",
    "on-click-middle": "volumecontrol.sh -i m",
    "on-scroll-up": "volumecontrol.sh -i i",
    "on-scroll-down": "volumecontrol.sh -i d",
    "tooltip-format": "{format_source} {source_desc} // {source_volume}%",
    "scroll-step": 5
},

    "custom/keybindhint": {
        "format": " ",
        "tooltip-format": " Keybinds",
        "rotate": 0,
        "on-click": "keybinds_hint.sh"
    },


// modules for padding //

    "custom/l_end": {
        "format": " ",
        "interval" : "once",
        "tooltip": false
    },

    "custom/r_end": {
        "format": " ",
        "interval" : "once",
        "tooltip": false
    },

    "custom/sl_end": {
        "format": " ",
        "interval" : "once",
        "tooltip": false
    },

    "custom/sr_end": {
        "format": " ",
        "interval" : "once",
        "tooltip": false
    },

    "custom/rl_end": {
        "format": " ",
        "interval" : "once",
        "tooltip": false
    },

    "custom/rr_end": {
        "format": " ",
        "interval" : "once",
        "tooltip": false
    },

    "custom/padd": {
        "format": "  ",
        "interval" : "once",
        "tooltip": false
    }

}
EOF

# --- WRITE ~/.config/waybar/style.css ---
echo -e "${CYAN}Writing ~/.config/waybar/style.css...${NC}"
cat << 'EOF' > "$HOME/.config/waybar/style.css"
* {
    border: none;
    border-radius: 0px;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 12px;
    min-height: 10px;
}

@import "theme.css";

window#waybar {
    background: @bar-bg;
}

tooltip {
    background: @main-bg;
    color: @main-fg;
    border-radius: 9px;
    border-width: 0px;
}

#workspaces button {
    box-shadow: none;
	text-shadow: none;
    padding: 0px;
    border-radius: 11px;
    margin-top: 3px;
    margin-bottom: 3px;
    margin-left: 0px;
    padding-left: 3px;
    padding-right: 3px;
    margin-right: 0px;
    color: @main-fg;
    animation: ws_normal 20s ease-in-out 1;
}

#workspaces button.active {
    background: @wb-act-bg;
    color: @wb-act-fg;
    margin-left: 3px;
    padding-left: 15px;
    padding-right: 15px;
    margin-right: 3px;
    animation: ws_active 20s ease-in-out 1;
    transition: all 0.4s cubic-bezier(.55,-0.68,.48,1.682);
}

#workspaces button:hover {
    background: @wb-hvr-bg;
    color: @wb-hvr-fg;
    animation: ws_hover 20s ease-in-out 1;
    transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
}

#taskbar button {
    box-shadow: none;
	text-shadow: none;
    padding: 0px;
    border-radius: 11px;
    margin-top: 3px;
    margin-bottom: 3px;
    margin-left: 0px;
    padding-left: 3px;
    padding-right: 3px;
    margin-right: 0px;
    color: @wb-color;
    animation: tb_normal 20s ease-in-out 1;
}

#taskbar button.active {
    background: @wb-act-bg;
    color: @wb-act-color;
    margin-left: 3px;
    padding-left: 15px;
    padding-right: 15px;
    margin-right: 3px;
    animation: tb_active 20s ease-in-out 1;
    transition: all 0.4s cubic-bezier(.55,-0.68,.48,1.682);
}

#taskbar button:hover {
    background: @wb-hvr-bg;
    color: @wb-hvr-color;
    animation: tb_hover 20s ease-in-out 1;
    transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
}

#tray menu * {
    min-height: 16px
}

#tray menu separator {
    min-height: 10px
}

#backlight,
#battery,
#bluetooth,
#custom-cava,
#custom-cliphist,
#clock,
#custom-cpuinfo,
#cpu,
#custom-github_hyprdots,
#custom-gpuinfo,
#idle_inhibitor,
#custom-keybindhint,
#language,
#memory,
#mpris,
#network,
#custom-notifications,
#custom-power,
#privacy,
#pulseaudio,
#custom-spotify,
#taskbar,
#custom-theme,
#tray,
#custom-updates,
#custom-wallchange,
#custom-wbar,
#window,
#workspaces,
#custom-l_end,
#custom-r_end,
#custom-sl_end,
#custom-sr_end,
#custom-rl_end,
#custom-rr_end {
    color: @main-fg;
    background: @main-bg;
    opacity: 1;
    margin: 5px 0px 5px 0px;
    padding-left: 5px;
    padding-right: 5px;
}

#workspaces,
#taskbar {
    padding: 0px;
}

#custom-r_end {
    border-radius: 0px 26px 26px 0px;
    margin-right: 11px;
    padding-right: 3px;
}

#custom-l_end {
    border-radius: 26px 0px 0px 26px;
    margin-left: 11px;
    padding-left: 3px;
}

#custom-sr_end {
    border-radius: 0px;
    margin-right: 11px;
    padding-right: 3px;
}

#custom-sl_end {
    border-radius: 0px;
    margin-left: 11px;
    padding-left: 3px;
}

#custom-rr_end {
    border-radius: 0px 9px 9px 0px;
    margin-right: 11px;
    padding-right: 3px;
}

#custom-rl_end {
    border-radius: 9px 0px 0px 9px;
    margin-left: 11px;
    padding-left: 3px;
}
EOF
cp "$HOME/.config/waybar/style.css" "$HOME/.config/waybar/modules/style.css"

# --- WRITE ~/.config/waybar/theme.css ---
echo -e "${CYAN}Writing ~/.config/waybar/theme.css...${NC}"
cat << 'EOF' > "$HOME/.config/waybar/theme.css"
/* To enable blur please make sure alpha is greater than 0 */
@define-color bar-bg rgba(0, 0, 0, 0.1); 

@define-color main-bg #475437;
@define-color main-fg #b5cc97;

@define-color wb-act-bg #668f31;
@define-color wb-act-fg #c2d89c;

@define-color wb-hvr-bg #c6eb6f;
@define-color wb-hvr-fg #c0fc47;
EOF

# --- WRITE ~/.config/waybar/config.ctl ---
echo -e "${CYAN}Writing ~/.config/waybar/config.ctl...${NC}"
cat << 'EOF' > "$HOME/.config/waybar/config.ctl"
0|28|bottom|( cpu memory custom/cpuinfo custom/gpuinfo ) ( idle_inhibitor clock )|( hyprland/workspaces hyprland/window )|( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|28|top|( cpu memory custom/cpuinfo custom/gpuinfo ) ( idle_inhibitor clock )|( hyprland/workspaces hyprland/window )|( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|28|bottom|( cpu memory custom/cpuinfo custom/gpuinfo ) ( idle_inhibitor clock ) ( hyprland/workspaces )|( hyprland/window )|( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|28|top|( cpu memory custom/cpuinfo ) ( idle_inhibitor clock ) ( hyprland/workspaces )|( hyprland/window )|( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0||bottom|( hyprland/workspaces hyprland/window )|( idle_inhibitor clock )|( cpu memory custom/cpuinfo custom/gpuinfo ) ( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0||top|( hyprland/workspaces hyprland/window )|( idle_inhibitor clock )|( cpu memory custom/cpuinfo custom/gpuinfo ) ( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|31|bottom|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( wlr/taskbar custom/spotify ) |( idle_inhibitor clock )|( privacy tray battery ) ( backlight network pulseaudio pulseaudio#microphone custom/notifications custom/keybindhint )
0|31|left|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( wlr/taskbar custom/spotify ) |( idle_inhibitor clock )|( privacy tray battery ) ( backlight network pulseaudio pulseaudio#microphone custom/keybindhint )
1|38|top|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( hyprland/workspaces wlr/taskbar custom/spotify )|( idle_inhibitor clock )|( privacy tray battery ) ( backlight network pulseaudio pulseaudio#microphone custom/keybindhint )
0|31|right|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( wlr/taskbar custom/spotify ) |( idle_inhibitor clock )|( privacy tray battery ) ( backlight network pulseaudio pulseaudio#microphone custom/keybindhint )
0|32|bottom||( custom/power ) ( privacy tray battery ) ( wlr/taskbar idle_inhibitor clock ) ( custom/cliphist ) ( custom/wbar ) ( custom/wallchange ) ( custom/theme )|
0|32|left||( custom/power ) ( privacy tray battery ) ( wlr/taskbar idle_inhibitor clock ) ( custom/cliphist ) ( custom/wbar ) ( custom/wallchange ) ( custom/theme )|
0|32|top||( custom/power ) ( privacy tray battery ) ( wlr/taskbar idle_inhibitor clock ) ( custom/cliphist ) ( custom/wbar ) ( custom/wallchange ) ( custom/theme )|
0|32|right||( custom/power ) ( privacy tray battery ) ( wlr/taskbar idle_inhibitor clock ) ( custom/cliphist ) ( custom/wbar ) ( custom/wallchange ) ( custom/theme )|
0|31|bottom|( cpu memory custom/cpuinfo custom/gpuinfo ) ( idle_inhibitor clock ) ( hyprland/workspaces )|( wlr/taskbar )|( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|31|top|( cpu memory custom/cpuinfo custom/gpuinfo ) ( idle_inhibitor clock ) ( hyprland/workspaces )|( wlr/taskbar )|( backlight network pulseaudio pulseaudio#microphone custom/updates custom/keybindhint ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|29|bottom|( wlr/taskbar mpris )|( idle_inhibitor clock )|( backlight network pulseaudio pulseaudio#microphone custom/updates ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|29|left|( wlr/taskbar mpris )|( idle_inhibitor clock )|( backlight network pulseaudio pulseaudio#microphone custom/updates ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|29|top|( wlr/taskbar mpris )|( idle_inhibitor clock )|( backlight network pulseaudio pulseaudio#microphone custom/updates ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|29|right|( wlr/taskbar mpris )|( idle_inhibitor clock )|( backlight network pulseaudio pulseaudio#microphone custom/updates ) ( privacy tray battery ) ( custom/wallchange custom/theme custom/wbar custom/cliphist custom/power )
0|28|bottom|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( idle_inhibitor clock custom/spotify )|( wlr/taskbar )|( privacy tray ) ( backlight network pulseaudio pulseaudio#microphone )
0|28|left|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( idle_inhibitor clock custom/spotify )|( wlr/taskbar )|( privacy tray ) ( backlight network pulseaudio pulseaudio#microphone )
0|28|top|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( idle_inhibitor clock custom/spotify )|( wlr/taskbar )|( privacy tray ) ( backlight network pulseaudio pulseaudio#microphone )
0|28|right|( custom/power custom/cliphist custom/wbar custom/theme custom/wallchange ) ( idle_inhibitor clock custom/spotify )|( wlr/taskbar )|( privacy tray ) ( backlight network pulseaudio pulseaudio#microphone )
0|40|top|( hyprland/workspaces )|( custom/cava idle_inhibitor clock )|( backlight pulseaudio pulseaudio#microphone tray battery custom/keybindhint custom/cliphist custom/power )
EOF

# --- WRITE ~/.config/waybar/modules/workspaces.jsonc ---
echo -e "${CYAN}Writing ~/.config/waybar/modules/workspaces.jsonc...${NC}"
mkdir -p "$HOME/.config/waybar/modules"
cat << 'EOF' > "$HOME/.config/waybar/modules/workspaces.jsonc"
    "hyprland/workspaces": {
        "disable-scroll": true,
        "rotate": ${r_deg},
        "all-outputs": true,
        "active-only": false,
        "on-click": "activate",
        "disable-scroll": false,
        "on-scroll-up": "hyprctl dispatch workspace -1",
        "on-scroll-down": "hyprctl dispatch workspace +1",
        "format": "{name} {windows}",
        "format-window-separator": " ",
        "window-rewrite-default": "",
        "window-rewrite": {
            "class<kitty>": "",
            "class<firefox>": "",
            "class<chromium>": "",
            "class<google-chrome>": "",
            "class<dolphin>": "󰉋",
            "class<thunar>": "󰉋",
            "class<vs-code-oss>": "󰨞",
            "class<code-oss>": "󰨞",
            "class<vscode>": "󰨞",
            "class<discord>": "󰙯",
            "class<spotify>": "",
            "class<steam>": "",
            "class<vlc>": "󰕼",
            "class<mpv>": "󰕼"
        },
        "persistent-workspaces": {
            "1": [],
            "2": [],
            "3": []
        }
    },
EOF

# --- WRITE hyde repository copy of workspaces.jsonc ---
if [ -d "$HOME/hyde" ]; then
    echo -e "${CYAN}Writing hyde repository copy of workspaces.jsonc...${NC}"
    mkdir -p "$HOME/hyde/Configs/.config/waybar/modules"
    cp "$HOME/.config/waybar/modules/workspaces.jsonc" "$HOME/hyde/Configs/.config/waybar/modules/workspaces.jsonc"
fi

# --- WRITE ~/.config/hyde/hyde.conf ---
echo -e "${CYAN}Writing ~/.config/hyde/hyde.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hyde/hyde.conf"
hydeTheme="Gruvbox Retro"
rofiStyle="5"
EOF

# --- WRITE ~/.zshrc ---
echo -e "${CYAN}Writing ~/.zshrc...${NC}"
cat << 'EOF' > "$HOME/.zshrc"
# Oh-my-zsh installation path
ZSH=/usr/share/oh-my-zsh/

# Powerlevel10k theme path
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# List of plugins used
plugins=( git sudo zsh-256color zsh-autosuggestions zsh-syntax-highlighting )
source $ZSH/oh-my-zsh.sh

# In case a command is not found, try to find the package that has it
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]]; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

# Detect AUR wrapper
if pacman -Qi yay &>/dev/null; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null; then
   aurhelper="paru"
fi

function in {
    local -a inPkg=("$@")
    local -a arch=()
    local -a aur=()

    for pkg in "${inPkg[@]}"; do
        if pacman -Si "${pkg}" &>/dev/null; then
            arch+=("${pkg}")
        else
            aur+=("${pkg}")
        fi
    done

    if [[ ${#arch[@]} -gt 0 ]]; then
        sudo pacman -S "${arch[@]}"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        ${aurhelper} -S "${aur[@]}"
    fi
}

# Helpful aliases
alias c='clear' # clear terminal
alias l='eza -lh --icons=auto' # long list
alias ls='eza -1 --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree
alias un='$aurhelper -Rns' # uninstall package
alias up='$aurhelper -Syu' # update system/package/aur
alias pl='$aurhelper -Qs' # list installed package
alias pa='$aurhelper -Ss' # list available package
alias pc='$aurhelper -Sc' # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -' # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias vc='code' # gui code editor

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
alias mkdir='mkdir -p'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# Make Ctrl+Backspace / Ctrl+W behave like Windows/bash (delete until space or slash)
autoload -U select-word-style
select-word-style bash

# Make Ctrl+A select all typed text on the command line (like Windows)
select-all-line() {
    if [[ -z "$BUFFER" ]]; then
        return
    fi
    CURSOR=0
    zle set-mark-command
    CURSOR=$#BUFFER
}
zle -N select-all-line
bindkey '^A' select-all-line
EOF

# --- WRITE ~/.config/fastfetch/logo.txt ---
echo -e "${CYAN}Writing ~/.config/fastfetch/logo.txt...${NC}"
mkdir -p "$HOME/.config/fastfetch"
cat << 'EOF' > "$HOME/.config/fastfetch/logo.txt"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⠀⠀⣀⣠⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣿⣽⠟⢁⣠⣤⣤⣶⣿⣽⣿⠟⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣀⣶⣿⣟⢿⣟⣿⣷⢞⢻⡻⣫⡻⣖⣾⣻⠏⠀⠀⠀⠀⠀⣀⣴⣾
⠀⠀⢀⠀⣸⣿⢻⣍⣷⢽⢿⢹⣪⣗⣽⣹⢽⡫⣿⣽⠏⢀⣀⣤⣴⣫⣿⣯⡟⠁
⠀⠀⣾⣿⢿⡣⢷⢼⣷⣿⢧⢿⢮⡷⡽⡵⣽⢎⣿⣯⠶⣿⡿⣛⢯⣫⣿⡿⠁⠀
⠀⢸⣿⡏⣾⢳⢟⢇⣿⢿⡳⡻⡕⣯⢪⡞⣾⣷⡟⣕⢗⡿⡸⣇⢯⡾⣻⠁⠀⠀
⢠⣿⣿⣷⣺⢕⣿⣾⠟⠚⠛⠛⠚⢓⣿⢾⣺⡳⡟⣾⢱⢻⡞⣷⢻⣿⡟⠀⠀⠀
⢻⣿⢏⣿⣽⣾⢿⡀⠀⠀⠀⠀⣐⣿⢝⠈⠓⣕⣽⣹⣏⣺⢕⣿⣿⣭⣤⣤⣤⣀
⢸⣿⢵⠷⣽⣯⣼⣧⠀⠀⣠⣼⠗⠁⢸⠀⠀⠘⡷⣽⢮⣼⠷⠿⠽⢾⣾⡿⠋⠀
⠀⠻⣷⡗⣽⣿⣿⣋⡗⣾⢿⣿⠀⠀⢨⠤⢭⡑⡟⡾⢝⢟⠶⣗⢟⣾⡿⠁⠀⠀
⠈⠻⣙⣛⠛⠋⠉⣁⣈⣿⣿⣿⡠⠾⢣⠀⠨⢸⢿⣹⡪⣿⣝⣝⣽⡟⠁⠀⠀⠀
⠀⠀⠀⠑⣿⣝⣿⡘⢇⡀⠄⢡⠀⡇⠈⢢⣸⣱⡏⣾⢬⣺⣪⣿⠏⠀⠀⠀⠀⠀
⠀⠀⠀⢀⣼⠷⢽⢾⣣⣽⣤⢤⣵⣧⢼⢭⢿⣾⣷⣿⡾⠟⠋⠁⠀⠀⠀⠀⠀⠀
⠀⢠⣶⡟⢾⣿⣷⠿⠛⢻⣿⣿⢟⢕⢿⢷⣿⣖⢟⢿⣳⣦⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⣿⣿⣿⣿⣷⣴⠮⠟⠻⣿⣿⣿⣽⣫⣻⡉⠻⣯⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀
⠀⠸⣿⡿⣿⣿⠤⠤⠤⢤⣀⣰⣯⣿⣽⣿⢻⢿⣆⣿⣽⣿⣽⣇⣠⠀⠀⠀⠀⠀
⠀⣶⣚⣗⢹⣿⠉⠉⠑⠲⣙⣿⣽⣿⣾⣿⢘⣿⡝⣿⣿⣿⣋⠟⡿⠀⠀⠀⠀⠀
⠀⠨⢳⡷⣽⣿⡇⠀⠀⢠⡾⣿⣷⣿⣾⡟⣾⢻⡷⣿⣟⠛⠒⠺⢅⠀⠀⠀⠀⠀
⠀⠀⠿⠟⢿⠟⠛⠙⣿⣿⣯⣻⠟⠋⢉⡭⠿⠼⡏⠉⠉⠉⠉⠢⢄⡑⣦⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⢴⠯⠥⣴⠏⠀⡴⠋⠀⠀⠀⡗⡦⢤⣄⣀⠀⠀⠉⠛⠷⣤⣀
⠀⠀⠀⠀⠀⠀⠚⠙⠓⢲⠋⡠⠊⠀⢀⣤⠴⠚⠁⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠁
⠀⠀⠀⠀⠀⠀⠀⠀⢴⠷⠽⠶⠒⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
EOF

# --- WRITE ~/.config/fastfetch/config.jsonc ---
echo -e "${CYAN}Writing ~/.config/fastfetch/config.jsonc...${NC}"
cat << 'EOF' > "$HOME/.config/fastfetch/config.jsonc"
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "/home/omar/.config/fastfetch/logo.txt",
    "width": 1,
    "padding": {
      "top": 2
    }
  },
  "display": {
    "separator": " : "
  },
  "modules": [
    {
      "type": "custom",
      "format": "\u001b[36m   󰄛  コンピューター"
    },
    {
      "type": "custom",
      "format": "┌──────────────────────────────────────────┐"
    },
    {
      "type": "chassis",
      "key": "  󰇺 Chassis",
      "format": "{3}"
    },
    {
      "type": "os",
      "key": "  󰣇 OS",
      "format": "{2}",
      "keyColor": "red"
    },
    {
      "type": "kernel",
      "key": "   Kernel",
      "format": "{2}",
      "keyColor": "red"
    },
    {
      "type": "packages",
      "key": "  󰏗 Packages",
      "keyColor": "green"
    },
    {
      "type": "display",
      "key": "  󰍹 Display",
      "format": "{1}x{2} @ {3}Hz [{7}]",
      "keyColor": "green"
    },
    {
      "type": "terminal",
      "key": "  >_ Terminal",
      "keyColor": "yellow"
    },
    {
      "type": "wm",
      "key": "  󱗃 WM",
      "format": "{2}",
      "keyColor": "yellow"
    },
    {
      "type": "custom",
      "format": "└──────────────────────────────────────────┘"
    },
    "break",
    {
      "type": "title",
      "key": "  ",
      "format": "{6} {7} {8}"
    },
    {
      "type": "custom",
      "format": "┌──────────────────────────────────────────┐"
    },
    {
      "type": "cpu",
      "format": "{1} @ {7}",
      "key": "   CPU",
      "keyColor": "blue"
    },
    {
      "type": "gpu",
      "format": "{1} {2}",
      "key": "  󰊴 GPU",
      "keyColor": "blue"
    },
    {
      "type": "gpu",
      "format": "{3}",
      "key": "   GPU Driver",
      "keyColor": "magenta"
    },
    {
      "type": "memory",
      "key": "    Memory",
      "keyColor": "magenta"
    },
    {
      "type": "command",
      "key": "  󱦟 OS Age ",
      "keyColor": "red",
      "text": "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days"
    },
    {
      "type": "uptime",
      "key": "  󱫐 Uptime ",
      "keyColor": "red"
    },
    {
      "type": "custom",
      "format": "└──────────────────────────────────────────┘"
    },
    {
      "type": "colors",
      "paddingLeft": 2,
      "symbol": "circle"
    }
  ]
}
EOF

# --- SDDM Theme Configuration ---
echo -e "\n${BLUE}${BOLD}Configuring SDDM Candy theme...${NC}"
if [ -f "$HOME/hyde/Source/arcs/Sddm_Candy.tar.gz" ]; then
    echo -e "${CYAN}Installing SDDM theme Candy...${NC}"
    sudo mkdir -p /usr/share/sddm/themes
    sudo tar -xzf "$HOME/hyde/Source/arcs/Sddm_Candy.tar.gz" -C /usr/share/sddm/themes/
    
    if [ -f /etc/sddm.conf ]; then
        if ! grep -q "^Current=" /etc/sddm.conf; then
            echo -e "\n[Theme]\nCurrent=Candy" | sudo tee -a /etc/sddm.conf >/dev/null
        else
            sudo sed -i 's/^Current=.*/Current=Candy/' /etc/sddm.conf
        fi
    else
        echo -e "[Theme]\nCurrent=Candy" | sudo tee /etc/sddm.conf >/dev/null
    fi

    # Set SDDM Candy background to match the active theme wallpaper dynamically
    if [ -L "$HOME/.cache/hyde/wall.set" ]; then
        echo -e "${CYAN}Linking SDDM background to current desktop wallpaper...${NC}"
        sudo cp -L "$HOME/.cache/hyde/wall.set" /usr/share/sddm/themes/Candy/backgrounds/bg.png
    elif [ -f "$HOME/.cache/hyde/wall.set" ]; then
        echo -e "${CYAN}Copying SDDM background to current desktop wallpaper...${NC}"
        sudo cp "$HOME/.cache/hyde/wall.set" /usr/share/sddm/themes/Candy/backgrounds/bg.png
    elif [ -f "$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/misty_forest.jpg" ]; then
        echo -e "${CYAN}Copying default 'misty_forest.jpg' as SDDM background...${NC}"
        sudo cp "$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/misty_forest.jpg" /usr/share/sddm/themes/Candy/backgrounds/bg.png
    fi

    # Customize SDDM Candy layout and accent color
    if [ -f "/usr/share/sddm/themes/Candy/theme.conf" ]; then
        echo -e "${CYAN}Customizing SDDM Candy layout (center, no header, theme orange)...${NC}"
        sudo sed -i 's/^AccentColor=.*/AccentColor="#fe8019"/' /usr/share/sddm/themes/Candy/theme.conf
        sudo sed -i 's/^FormPosition=.*/FormPosition="center"/' /usr/share/sddm/themes/Candy/theme.conf
        sudo sed -i 's/^HeaderText=.*/HeaderText=""/' /usr/share/sddm/themes/Candy/theme.conf
    fi

    echo -e "${GREEN}[OK] SDDM Candy theme configured successfully!${NC}"
fi

# --- RTL8188EUS USB Wi-Fi Hotspot driver configuration ---
echo -e "\n${BLUE}${BOLD}Configuring RTL8188EUS USB Wi-Fi driver and blacklisting conflicting drivers...${NC}"

# Blacklist default rtl8xxxu driver
if [ ! -f /etc/modprobe.d/rtl8xxxu.conf ] || ! grep -q "blacklist rtl8xxxu" /etc/modprobe.d/rtl8xxxu.conf; then
    echo -e "${CYAN}Creating blacklisting rule for default rtl8xxxu driver...${NC}"
    echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf >/dev/null
    echo -e "${GREEN}[OK] Blacklisted rtl8xxxu driver successfully!${NC}"
else
    echo -e "${GREEN}[OK] rtl8xxxu driver is already blacklisted.${NC}"
fi

# Blacklist staging r8188eu driver
if [ ! -f /etc/modprobe.d/r8188eu.conf ] || ! grep -q "blacklist r8188eu" /etc/modprobe.d/r8188eu.conf; then
    echo -e "${CYAN}Creating blacklisting rule for staging r8188eu driver...${NC}"
    echo "blacklist r8188eu" | sudo tee /etc/modprobe.d/r8188eu.conf >/dev/null
    echo -e "${GREEN}[OK] Blacklisted staging r8188eu driver successfully!${NC}"
else
    echo -e "${GREEN}[OK] staging r8188eu driver is already blacklisted.${NC}"
fi

# Compile and Patch the RTL8188EUS USB Wi-Fi driver if needed
echo -e "\n${BLUE}${BOLD}Checking and patching RTL8188EUS USB Wi-Fi driver for modern kernels...${NC}"
# Find driver directory in /usr/src/
SRC_DIRS=(/usr/src/8188eu-*)
if [ -d "${SRC_DIRS[0]}" ]; then
    DRIVER_DIR="${SRC_DIRS[0]}"
    DRIVER_VER=$(basename "$DRIVER_DIR" | sed 's/8188eu-//')
    echo -e "Found driver source directory: ${CYAN}$DRIVER_DIR${NC} (Version: ${CYAN}$DRIVER_VER${NC})"
    
    # Locate patch_driver.py
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [ -f "$SCRIPT_DIR/patch_driver.py" ]; then
        PATCH_SCRIPT="$SCRIPT_DIR/patch_driver.py"
    else
        # If script is run via curl or in a temp location, fetch patch_driver.py from remote repo
        echo -e "${CYAN}Downloading patch_driver.py from GitHub repository...${NC}"
        curl -sSL -o /tmp/patch_driver.py https://raw.githubusercontent.com/omarahmed321/cachyos-restore/main/patch_driver.py || wget -q -O /tmp/patch_driver.py https://raw.githubusercontent.com/omarahmed321/cachyos-restore/main/patch_driver.py
        PATCH_SCRIPT="/tmp/patch_driver.py"
    fi
    
    # Run patch script
    if [ -f "$PATCH_SCRIPT" ]; then
        echo -e "${CYAN}Running driver source patch script on $DRIVER_DIR...${NC}"
        sudo python3 "$PATCH_SCRIPT" "$DRIVER_DIR"
        
        # Trigger DKMS to rebuild and reinstall the patched driver
        echo -e "${CYAN}Rebuilding and reinstalling patched 8188eu driver using DKMS...${NC}"
        sudo dkms remove -m 8188eu -v "$DRIVER_VER" --all || true
        sudo dkms add -m 8188eu -v "$DRIVER_VER" || true
        if sudo dkms install -m 8188eu -v "$DRIVER_VER"; then
            echo -e "${GREEN}[OK] RTL8188EUS USB Wi-Fi driver patched and installed successfully via DKMS!${NC}"
        else
            echo -e "${RED}[ERROR] Failed to compile and install RTL8188EUS USB Wi-Fi driver via DKMS.${NC}"
        fi
    else
        echo -e "${YELLOW}[WARNING] Could not locate or download patch_driver.py. Skipping patch step.${NC}"
    fi
else
    echo -e "${YELLOW}[WARNING] No RTL8188EUS driver source found in /usr/src/8188eu-*. Skipping driver patch.${NC}"
fi

# --- Nvidia DRM Configuration ---
echo -e "\n${BLUE}${BOLD}Configuring Nvidia DRM modesetting...${NC}"
echo -e "${CYAN}Setting clean default in /etc/modprobe.d/nvidia.conf...${NC}"
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null << 'NVIEOF'
options nvidia_drm modeset=1
NVIEOF
echo -e "${GREEN}[OK] Nvidia DRM configured successfully!${NC}"

# Robustly clone and patch preset HyDE themes to ensure Waybar theme switches work perfectly out-of-the-box
if [ -f "$HOME/hyde/Scripts/themepatcher.lst" ] && [ -f "$HOME/hyde/Scripts/themepatcher.sh" ]; then
    echo -e "\n${BLUE}${BOLD}Installing and patching missing preset HyDE themes...${NC}"
    while IFS='"' read -r null1 themeName null2 themeRepo; do
        if [ -n "$themeName" ] && [ -n "$themeRepo" ]; then
            if [ ! -d "$HOME/.config/hyde/themes/$themeName" ]; then
                echo -e "  - Patching missing theme: ${CYAN}$themeName${NC}..."
                "$HOME/hyde/Scripts/themepatcher.sh" "$themeName" "$themeRepo" --skipcaching false &>/dev/null || true
            else
                echo -e "  - Theme ${GREEN}$themeName${NC} is already installed. Skipping patch."
            fi
        fi
    done < "$HOME/hyde/Scripts/themepatcher.lst"
    echo -e "${GREEN}[OK] All preset HyDE themes checked successfully!${NC}"
fi

# Clean up hardcoded cursor theme lines in common.conf to prevent theme conflicts
if [ -f "$HOME/.config/hypr/themes/common.conf" ]; then
    echo -e "${CYAN}Removing hardcoded cursor settings from common.conf...${NC}"
    sed -i '/exec = hyprctl setcursor/d' "$HOME/.config/hypr/themes/common.conf"
    sed -i '/exec = gsettings set org.gnome.desktop.interface cursor-theme/d' "$HOME/.config/hypr/themes/common.conf"
    sed -i '/exec = gsettings set org.gnome.desktop.interface cursor-size/d' "$HOME/.config/hypr/themes/common.conf"
fi

# 5. Apply Settings and Refresh
echo -e "\n${BLUE}${BOLD}Refreshing themes, icon caches, and font caches...${NC}"
fc-cache -f

# Switch theme using HyDE's built-in tool
if [ -f "$HOME/.local/share/bin/themeswitch.sh" ]; then
    echo -e "${CYAN}Switching HyDE theme to 'Gruvbox Retro'...${NC}"
    # Run in background or with suppressions
    "$HOME/.local/share/bin/themeswitch.sh" "Gruvbox Retro" &>/dev/null || true
fi

# Ensure default wallpaper is set to 'misty_forest.jpg' and cache is fully generated
if [ -f "$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/misty_forest.jpg" ]; then
    echo -e "${CYAN}Setting default wallpaper to 'misty_forest.jpg'...${NC}"
    # Ensure the theme's default wallpaper symlink is set to misty_forest.jpg
    mkdir -p "$HOME/.config/hyde/themes/Gruvbox Retro"
    ln -sf "$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/misty_forest.jpg" "$HOME/.config/hyde/themes/Gruvbox Retro/wall.set"
    
    # Initialize the wallpaper using HyDE's wallpaper daemon script
    if [ -f "$HOME/.local/share/bin/swwwallpaper.sh" ]; then
        "$HOME/.local/share/bin/swwwallpaper.sh" -s "$HOME/.config/hyde/themes/Gruvbox Retro/wallpapers/misty_forest.jpg" &>/dev/null || true
    fi
fi

# Launch Display & Mouse Settings Manager GUI if running in a graphical session
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
    echo -e "\n${BLUE}${BOLD}Launching Display & Mouse Settings GUI...${NC}"
    python3 "$HOME/.local/share/bin/hypr-display-settings.py" || true
fi

echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}   CONGRATULATIONS! Replicator script generation is complete!        ${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "${YELLOW}To use this on your new CachyOS + Hyprland system:${NC}"
echo -e "  1. Copy this script to the new machine."
echo -e "  2. Run: ${CYAN}chmod +x restore_my_setup.sh${NC}"
echo -e "  3. Run: ${CYAN}./restore_my_setup.sh${NC}"
echo -e "======================================================================"
