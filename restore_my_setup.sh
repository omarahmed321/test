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

# Ensure git and zsh are installed
echo -e "\n${BLUE}${BOLD}[2/5] Ensuring Core packages (git, zsh) are installed...${NC}"
if ! pacman -Qi git &>/dev/null || ! pacman -Qi zsh &>/dev/null; then
    sudo pacman -S --needed --noconfirm git zsh
else
    echo -e "${GREEN}[OK] Core packages (git, zsh) are already installed.${NC}"
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
)

# Install packages
echo -e "${CYAN}Checking ${#REQUIRED_PACKAGES[@]} essential packages...${NC}"
TO_INSTALL=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "  - ${GREEN}[Installed]${NC} $pkg"
    else
        echo -e "  - ${YELLOW}[Missing]${NC} $pkg (queued)"
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}\nInstalling missing packages using $AUR_HELPER...${NC}"
    $AUR_HELPER -S --noconfirm "${TO_INSTALL[@]}"
    echo -e "${GREEN}[OK] All packages installed successfully!${NC}"
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
exec-once = waybar # launch the system bar
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
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1

    touchpad {
        natural_scroll = no
    }

    sensitivity = -1.0
    accel_profile = flat
    force_no_accel = 1
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
    vrr = 1
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
source = ~/.config/hypr/themes/colors.conf # wallbash color override
source = ~/.config/hypr/monitors.conf # initially empty, to be configured by user and remains static
source = ~/.config/hypr/userprefs.conf # initially empty, to be configured by user and remains static

# Note: as userprefs.conf is sourced at the end, settings configured in this file will override the defaults
source = ~/.config/hypr/nvidia.conf # auto sourced vars for nvidia
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
    kb_options = grp:alt_shift_toggle
    sensitivity = 0.0
    accel_profile = custom 100 0.1
    force_no_accel = false
}

device {
    name = -------x3pro
    accel_profile = custom 100 0.1
}

device {
    name = -------skyloong-gaming-keyboard-mouse
    accel_profile = custom 100 0.1
}

# --- Game Mouse Cursor Fixes ---
# Confine mouse pointer to game windows (forces mouse capture, essential for dual-monitor setups)
# windowrule = confine_pointer 1, match:class ^(steam_app_2399830)$
# windowrule = confine_pointer 1, match:title ^(ArkAscended)$
# windowrule = confine_pointer 1, match:class ^(steam_app_.*)$
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

source = $HOME/.config/hypr/animations/animations-default.conf
EOF

# --- WRITE ~/.config/hypr/monitors.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/monitors.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/monitors.conf"

# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█ █▀
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄ ▄█

# DP-2 (CMT GM238-FFS) - 144Hz main display
monitor = DP-2,1920x1080@144,1080x700,1

# DP-1 (HP Z23n) - Portrait mode, left of DP-2, fine-tuned alignment
monitor = DP-1,1920x1080@60,0x0,1,transform,1

# Workspace Rules
# Assign workspaces 1 to 8 to DP-2 (144Hz main display)
workspace = 1, monitor:DP-2, default:true
workspace = 2, monitor:DP-2
workspace = 3, monitor:DP-2
workspace = 4, monitor:DP-2
workspace = 5, monitor:DP-2
workspace = 6, monitor:DP-2
workspace = 7, monitor:DP-2
workspace = 8, monitor:DP-2

# Assign workspaces 9 and 10 to DP-1 (60Hz portrait side screen)
workspace = 9, monitor:DP-1, default:true
workspace = 10, monitor:DP-1
EOF

# --- WRITE ~/.config/hypr/nvidia.conf ---
echo -e "${CYAN}Writing ~/.config/hypr/nvidia.conf...${NC}"
cat << 'EOF' > "$HOME/.config/hypr/nvidia.conf"

# █▄░█ █░█ █ █▀▄ █ ▄▀█
# █░▀█ ▀▄▀ █ █▄▀ █ █▀█

# See https://wiki.hyprland.org/Nvidia/

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = __GL_VRR_ALLOWED,1
env = WLR_DRM_NO_ATOMIC,1

cursor {
    no_hardware_cursors = true
}
EOF

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
    fi

    # Customize SDDM Candy AccentColor to match GruvboxRetro orange theme
    if [ -f "/usr/share/sddm/themes/Candy/theme.conf" ]; then
        echo -e "${CYAN}Setting SDDM Candy accent color to theme-compatible orange...${NC}"
        sudo sed -i 's/^AccentColor=.*/AccentColor="#fe8019"/' /usr/share/sddm/themes/Candy/theme.conf
    fi

    echo -e "${GREEN}[OK] SDDM Candy theme configured successfully!${NC}"
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

echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}   CONGRATULATIONS! Replicator script generation is complete!        ${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "${YELLOW}To use this on your new CachyOS + Hyprland system:${NC}"
echo -e "  1. Copy this script to the new machine."
echo -e "  2. Run: ${CYAN}chmod +x restore_my_setup.sh${NC}"
echo -e "  3. Run: ${CYAN}./restore_my_setup.sh${NC}"
echo -e "======================================================================"
