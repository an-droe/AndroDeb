#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# COLOR DEFINITIONS
# ==========================================
C_RESET='\e[0m'
C_BOLD='\e[1m'
C_GREY='\e[1;90m'
C_YELLOW='\e[1;33m'
C_GREEN='\e[1;32m'
C_CYAN='\e[1;36m'
C_BLUE='\e[1;34m'

# ==========================================
# MAIN BANNER
# ==========================================
clear
echo -e "${C_CYAN}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${C_RESET}"
echo -e "${C_CYAN}┃ ${C_BOLD}    🚀 ${C_GREEN}ANDRODEB${C_RESET} ${C_CYAN}Debian Installer for Termux"
echo -e "${C_CYAN}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${C_RESET}"
echo ""

# --- 0. Warning & Setup Prompts ---
echo -e "${C_YELLOW}${C_BOLD}⚠️  WARNING:${C_RESET}"
echo -e "${C_YELLOW}   This script will download and install a Debian environment.${C_RESET}"
echo -e "${C_YELLOW}   Please ensure you have a stable internet connection.${C_RESET}"
echo ""

echo -e "${C_BOLD}${C_CYAN}   Select installation type:${C_RESET}"
echo -e "   ${C_BOLD}${C_CYAN}1)${C_RESET} CLI Only (Minimal, ~500MB required)"
echo -e "   ${C_BOLD}${C_CYAN}2)${C_RESET} Full Desktop (XFCE + Termux-X11, ~4GB required) [Default]"
echo -e -n "   ${C_CYAN}Option [1/2]: ${C_RESET}"
read INSTALL_TYPE </dev/tty
INSTALL_TYPE=${INSTALL_TYPE:-2}

echo -e -n "\n${C_BOLD}${C_CYAN}   Do you want to continue with the installation? (y/N): ${C_RESET}"
read CONFIRMATION </dev/tty

if [[ "$CONFIRMATION" != "y" && "$CONFIRMATION" != "Y" ]]; then
    echo -e "\n${C_YELLOW}❌ Installation cancelled. See you later! 😊${C_RESET}"
    exit 1
fi

echo -e "\n${C_BLUE}${C_BOLD}👤 USER CONFIGURATION${C_RESET}"
echo -e -n "${C_BOLD}${C_CYAN}   Enter a username for the new system [Default: droid]: ${C_RESET}"
read USERNAME </dev/tty
USERNAME=${USERNAME:-droid}

# Get Android Timezone
TZ=$(getprop persist.sys.timezone)
TZ=${TZ:-UTC}

echo -e "\n${C_CYAN}${C_BOLD}⏳ Starting installation... Warming up engines!${C_RESET}"
echo -e "${C_YELLOW}⚠️  Note: At the end, you will be prompted to create a password for '${C_CYAN}$USERNAME${C_YELLOW}'.${C_RESET}"
sleep 4
echo ""

# --- 1. Termux Configuration ---
echo -e "${C_GREY}${C_BOLD}[ 1 / 4 ] Configuring Termux storage and repositories...${C_RESET}"
termux-setup-storage
mkdir -p ~/Documents

yes | pkg up
pkg i -y tur-repo proot-distro

# Install GUI packages only if Full Desktop is selected
if [ "$INSTALL_TYPE" == "2" ]; then
    pkg i -y pulseaudio
    pkg i -y x11-repo && pkg i -y termux-x11-nightly
fi

# --- 2. Create Wrapper Command 'debian' ---
echo -e "\n${C_GREY}${C_BOLD}[ 2 / 4 ] Creating the magic 'debian' command...${C_RESET}"

cat << 'EOF' > $PREFIX/bin/debian
#!/data/data/com.termux/files/usr/bin/bash

# Colors
W_RESET='\e[0m'
W_BOLD='\e[1m'
W_GREY='\e[1;90m'
W_YELLOW='\e[1;33m'

TARGET_USER=$1
MODE=$2

# If empty, or if first parameter is --x11, assume 'root'
if [ -z "$TARGET_USER" ]; then
    TARGET_USER="root"
elif [ "$TARGET_USER" == "--x11" ]; then
    TARGET_USER="root"
    MODE="--x11"
fi

# Adjust home directory path
if [ "$TARGET_USER" == "root" ]; then
    TARGET_HOME="/root"
else
    TARGET_HOME="/home/$TARGET_USER"
fi

# Bind Android's Documents folder to the corresponding user
BIND_DOCS="--bind /data/data/com.termux/files/home/Documents:$TARGET_HOME/Documents"

if [ "$MODE" == "--x11" ]; then
    if ! command -v termux-x11 &> /dev/null; then
        echo -e "${W_YELLOW}${W_BOLD}❌ GUI packages are not installed. Please reinstall and select Full Desktop mode.${W_RESET}"
        exit 1
    fi

    echo -e "${W_GREY}${W_BOLD}🖥️ Starting the X11 graphical environment for ${W_RESET}$TARGET_USER${W_GREY}${W_BOLD}...${W_RESET}"
    pkill -9 -f "termux-x11" 2>/dev/null
    pkill -9 -f "dbus" 2>/dev/null
    pulseaudio --kill 2>/dev/null
    
    # Start pulseaudio
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    termux-x11 :0 -ac &
    
    # Automatically execute run-x11 inside the proot environment
    proot-distro login debian --shared-tmp --user "$TARGET_USER" $BIND_DOCS -- bash -c "run-x11"
else
    echo -e "${W_GREY}${W_BOLD}💻 Starting terminal for ${W_RESET}$TARGET_USER${W_GREY}${W_BOLD}...${W_RESET}"
    proot-distro login debian --shared-tmp --user "$TARGET_USER" $BIND_DOCS
fi
EOF
chmod +x $PREFIX/bin/debian

# --- 3. Install Debian ---
echo -e "\n${C_GREY}${C_BOLD}[ 3 / 4 ] Downloading and installing Debian base system...${C_RESET}"
proot-distro install debian:stable

# --- 4. Configure Debian Internally ---
echo -e "\n${C_GREY}${C_BOLD}[ 4 / 4 ] Configuring environment and user...${C_RESET}"

DEBIAN_PACKAGES="sudo adduser wget git fastfetch"
if [ "$INSTALL_TYPE" == "2" ]; then
    DEBIAN_PACKAGES="$DEBIAN_PACKAGES task-xfce-desktop dbus-x11"
fi

# Pass variables to Debian using double quotes, redirecting input from /dev/tty for password prompt
proot-distro login debian --shared-tmp -- bash -c "
# Prevent interactive prompts during apt install
export DEBIAN_FRONTEND=noninteractive

echo -e '\n\e[1;36m⚙️  Automatically setting Timezone to: \e[1;33m$TZ\e[0m'
ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

apt update && apt upgrade -y

# Install packages depending on user choice
apt install -y $DEBIAN_PACKAGES

# Re-enable interactive mode for adduser password prompt
unset DEBIAN_FRONTEND

echo -e '\n\e[1;36m╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮\e[0m'
echo -e '\e[1;36m┃ 👤 CREATING USER: \e[1;37m$USERNAME'
echo -e '\e[1;36m┃ \e[1;33m Please type a password for your new user.'
echo -e '\e[1;36m╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯\e[0m'

adduser $USERNAME
usermod -aG sudo $USERNAME

# Create XFCE launcher only if GUI is selected
if [ \"$INSTALL_TYPE\" == \"2\" ]; then
    cat << 'EOF2' > /usr/local/bin/run-x11
#!/bin/bash

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Audio and Display Settings
export PULSE_SERVER=127.0.0.1
export DISPLAY=:0

exec startxfce4
EOF2
    chmod +x /usr/local/bin/run-x11
fi
" </dev/tty

# ==========================================
# FINAL SCREEN
# ==========================================
clear
echo -e "${C_CYAN}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${C_RESET}"
echo -e "${C_CYAN}┃ ${C_BOLD}   ✅ INSTALLATION AND SETUP SUCCESSFUL!"
echo -e "${C_CYAN}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${C_RESET}"
echo ""
echo -e "${C_YELLOW}${C_BOLD}⚡ HOW TO USE YOUR NEW SYSTEM:${C_RESET}"
echo ""
echo -e "${C_BLUE}  👨‍💻 To login as ROOT (Administrator):${C_RESET}"
echo -e "      ${C_CYAN}$ ${C_RESET}${C_GREEN}${C_BOLD}debian${C_RESET}"
if [ "$INSTALL_TYPE" == "2" ]; then
    echo -e "      ${C_CYAN}$ ${C_RESET}${C_GREEN}${C_BOLD}debian --x11${C_RESET}"
fi
echo ""
echo -e "${C_BLUE}  👤 To login as ${C_BOLD}$USERNAME${C_RESET}${C_BLUE}:${C_RESET}"
echo -e "      ${C_CYAN}$ ${C_RESET}${C_GREEN}${C_BOLD}debian $USERNAME${C_RESET}"
if [ "$INSTALL_TYPE" == "2" ]; then
    echo -e "      ${C_CYAN}$ ${C_RESET}${C_GREEN}${C_BOLD}debian $USERNAME --x11${C_RESET}    ${C_GREY}(for Desktop)${C_RESET}"
fi
echo ""
echo -e "${C_GREY}======================================================${C_RESET}"
if [ "$INSTALL_TYPE" == "2" ]; then
    echo -e "${C_YELLOW}💡 GUI Note:${C_RESET} When using Desktop mode, the Android app"
    echo -e "   ${C_BOLD}Termux-X11${C_RESET} will open automatically."
else
    echo -e "${C_YELLOW}💡 Note:${C_RESET} You installed the CLI-Only version."
    echo -e "   Enjoy your lightweight Debian environment!"
fi
echo -e "${C_GREY}======================================================${C_RESET}"
echo -e ""
