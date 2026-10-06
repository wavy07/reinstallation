#!/usr/bin/env bash

# ============================================================
# 🦜 VISIBLE TECH REINSTALLER
# Powered by bin456789/reinstall
# ============================================================

set -u

UPSTREAM="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
TMP="/tmp/visible-tech-reinstall.sh"

# Colors
R='\033[0m'
B='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[97m'

cleanup() {
    rm -f "$TMP"
}

trap cleanup EXIT INT TERM

# ============================================================
# ROOT
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "${RED}❌ Please run as root.${R}"
    echo
    echo -e "   ${CYAN}sudo bash $0${R}"
    echo
    exit 1
fi

# ============================================================
# DOWNLOAD ENGINE
# ============================================================

clear 2>/dev/null || true

echo
echo -e "${CYAN}${B}╔════════════════════════════════════════════════════╗${R}"
echo -e "${CYAN}${B}║${R}        🚀 VISIBLE TECH🦜 REINSTALLER             ${CYAN}${B}║${R}"
echo -e "${CYAN}${B}║${R}             VPS OS INSTALLATION                  ${CYAN}${B}║${R}"
echo -e "${CYAN}${B}╚════════════════════════════════════════════════════╝${R}"
echo

printf "  ${CYAN}⠋${R} Connecting to reinstall server..."

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$UPSTREAM" -o "$TMP" >/dev/null 2>&1
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP" "$UPSTREAM"
else
    echo -e "\r  ${RED}✗ curl or wget is required.${R}"
    exit 1
fi

if [ ! -s "$TMP" ]; then
    echo -e "\r  ${RED}✗ Failed to download reinstall engine.${R}"
    exit 1
fi

echo -e "\r  ${GREEN}✓ Reinstall engine ready.                    ${R}"

chmod +x "$TMP"

# ============================================================
# OS DATA
# ============================================================

OS_NAMES=(
    "Anolis OS"
    "OpenCloudOS"
    "Rocky Linux"
    "Oracle Linux"
    "AlmaLinux"
    "CentOS"
    "fnOS"
    "FydeOS / FygoOS"
    "NixOS"
    "Fedora"
    "Debian"
    "openSUSE"
    "openEuler"
    "Alpine Linux"
    "Kali Linux"
    "Ubuntu"
    "Arch Linux"
    "Gentoo"
    "AOSC OS"
    "Red Hat"
    "DD / Disk Image"
    "Windows"
    "netboot.xyz"
)

OS_CODES=(
    "anolis"
    "opencloudos"
    "rocky"
    "oracle"
    "almalinux"
    "centos"
    "fnos"
    "fygoos"
    "nixos"
    "fedora"
    "debian"
    "opensuse"
    "openeuler"
    "alpine"
    "kali"
    "ubuntu"
    "arch"
    "gentoo"
    "aosc"
    "redhat"
    "dd"
    "windows"
    "netboot.xyz"
)

# ============================================================
# ICONS
# ============================================================

get_icon() {
    case "$1" in
        anolis)      echo "🟠" ;;
        opencloudos) echo "🟡" ;;
        rocky)       echo "🟢" ;;
        oracle)      echo "🔵" ;;
        almalinux)   echo "🟢" ;;
        centos)      echo "🟡" ;;
        fnos)        echo "🟣" ;;
        fygoos)      echo "🟣" ;;
        nixos)       echo "❄️" ;;
        fedora)      echo "🔵" ;;
        debian)      echo "🔴" ;;
        opensuse)    echo "🦎" ;;
        openeuler)   echo "🟢" ;;
        alpine)      echo "🔷" ;;
        kali)        echo "💀" ;;
        ubuntu)      echo "🟠" ;;
        arch)        echo "🔵" ;;
        gentoo)      echo "🟣" ;;
        aosc)        echo "🟣" ;;
        redhat)      echo "🔴" ;;
        dd)          echo "💿" ;;
        windows)     echo "🪟" ;;
        netboot.xyz) echo "🌐" ;;
        *)           echo "💻" ;;
    esac
}

# ============================================================
# MAIN OS MENU
# ============================================================

while true; do

    echo
    echo -e "${BLUE}${B}┌──────────────────────────────────────────────────┐${R}"
    echo -e "${BLUE}${B}│${R}          🌍 SELECT OPERATING SYSTEM             ${BLUE}${B}│${R}"
    echo -e "${BLUE}${B}├──────────────────────────────────────────────────┤${R}"

    for i in "${!OS_NAMES[@]}"; do

        number=$((i + 1))

        printf \
            "${BLUE}${B}│${R}  ${CYAN}%2d${R}  %s %-39s${BLUE}${B}│${R}\n" \
            "$number" \
            "$(get_icon "${OS_CODES[$i]}")" \
            "${OS_NAMES[$i]}"

    done

    echo -e "${BLUE}${B}│${R}  ${RED} 0${R}  ❌ Exit                                         ${BLUE}${B}│${R}"
    echo -e "${BLUE}${B}└──────────────────────────────────────────────────┘${R}"
    echo

    read -r -p "$(echo -e "  ${CYAN}🦜 Visible Tech ➜${R} Select OS: ")" choice

    if [ "$choice" = "0" ]; then
        echo
        echo -e "  ${YELLOW}👋 Cancelled.${R}"
        exit 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] &&
       [ "$choice" -ge 1 ] &&
       [ "$choice" -le "${#OS_NAMES[@]}" ]
    then
        INDEX=$((choice - 1))
        DISTRO="${OS_CODES[$INDEX]}"
        OS_NAME="${OS_NAMES[$INDEX]}"
        break
    fi

    echo
    echo -e "  ${RED}❌ Invalid selection. Please enter a number from 0-${#OS_NAMES[@]}.${R}"
done

# ============================================================
# VERSION FUNCTION
# ============================================================

choose_version() {

    local title="$1"
    shift

    local versions=("$@")
    local choice

    echo

    echo -e "${GREEN}${B}┌──────────────────────────────────────────────────┐${R}"
    printf
