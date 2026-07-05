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
CHANNEL="6"

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
create_ap --no-virt -c "$CHANNEL" "$WIFI_INT" "$INTERNET_INT" "$SSID" "$PASSPHRASE" &
CREATE_AP_PID=$!

# Wait for create_ap to finish
wait "$CREATE_AP_PID"
