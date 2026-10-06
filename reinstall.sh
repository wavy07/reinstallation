#!/usr/bin/env bash

# ============================================================
# 🦜 VISIBLE TECH REINSTALLER
# Powered by bin456789/reinstall
# ============================================================

set -u

UPSTREAM="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
TMP="/reinstall-tmp-visible-tech.sh"

# ============================================================
# COLORS
# ============================================================

R='\033[0m'
B='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[97m'
DIM='\033[2m'

# ============================================================
# CLEAN EXIT
# ============================================================

cleanup() {
    rm -f "$TMP"
}

exit_now() {
    echo
    echo -e "${YELLOW}👋 Visible Tech🦜 installer stopped.${R}"
    cleanup
    exit 130
}

trap cleanup EXIT
trap exit_now INT TERM

# ============================================================
# ROOT CHECK
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "${RED}${B}❌ ROOT ACCESS REQUIRED${R}"
    echo
    echo -e "   Run:"
    echo -e "   ${CYAN}sudo bash $0${R}"
    echo
    exit 1
fi

# ============================================================
# HEADER
# ============================================================

clear 2>/dev/null || true

echo
echo -e "${CYAN}${B}╔════════════════════════════════════════════════════════╗${R}"
echo -e "${CYAN}${B}║${R}          🚀 VISIBLE TECH🦜 REINSTALLER              ${CYAN}${B}║${R}"
echo -e "${CYAN}${B}║${R}              VPS OS INSTALLATION                    ${CYAN}${B}║${R}"
echo -e "${CYAN}${B}╚════════════════════════════════════════════════════════╝${R}"
echo

# ============================================================
# DOWNLOAD UPSTREAM
# ============================================================

printf "  ${CYAN}⠋${R} Downloading reinstall engine..."

if command -v curl >/dev/null 2>&1; then
    if ! curl -fsSL "$UPSTREAM" -o "$TMP" >/dev/null 2>&1; then
        echo -e "\r  ${RED}❌ Failed to download reinstall engine.${R}"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    if ! wget -qO "$TMP" "$UPSTREAM"; then
        echo -e "\r  ${RED}❌ Failed to download reinstall engine.${R}"
        exit 1
    fi
else
    echo -e "\r  ${RED}❌ curl or wget is required.${R}"
    exit 1
fi

if [ ! -s "$TMP" ]; then
    echo -e "\r  ${RED}❌ Downloaded reinstall engine is empty.${R}"
    exit 1
fi

chmod +x "$TMP"

echo -e "\r  ${GREEN}✓${R} Reinstall engine ready.                         "

# ============================================================
# CURRENT UPSTREAM OS LIST
# ============================================================
#
# Based on the current bin456789/reinstall usage list:
#
# anolis
# opencloudos
# rocky
# oracle
# almalinux
# centos
# fnos
# fygoos
# nixos
# fedora
# debian
# opensuse
# alpine
# kali
# openeuler
# ubuntu
# arch
# gentoo
# aosc
# redhat
# dd
# windows
# netboot.xyz
# reset
#
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
    "Alpine Linux"
    "Kali Linux"
    "openEuler"
    "Ubuntu"
    "Arch Linux"
    "Gentoo"
    "AOSC OS"
    "Red Hat"
    "DD / Disk Image"
    "Windows"
    "netboot.xyz"
    "Reset / Recovery"
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
    "alpine"
    "kali"
    "openeuler"
    "ubuntu"
    "arch"
    "gentoo"
    "aosc"
    "redhat"
    "dd"
    "windows"
    "netboot.xyz"
    "reset"
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
        alpine)      echo "🔷" ;;
        kali)        echo "💀" ;;
        openeuler)   echo "🟢" ;;
        ubuntu)      echo "🟠" ;;
        arch)        echo "🔵" ;;
        gentoo)      echo "🟣" ;;
        aosc)        echo "🟣" ;;
        redhat)      echo "🔴" ;;
        dd)          echo "💿" ;;
        windows)     echo "🪟" ;;
        netboot.xyz) echo "🌐" ;;
        reset)       echo "♻️" ;;
        *)           echo "💻" ;;
    esac
}

# ============================================================
# VERSION SELECTOR
# ============================================================

choose_version() {

    local title="$1"
    shift

    local versions=("$@")
    local choice

    while true; do

        echo
        echo -e "${GREEN}${B}┌──────────────────────────────────────────────────┐${R}"
        printf "${GREEN}${B}│${R}  📦 %-46s${GREEN}${B}│${R}\n" "$title"
        echo -e "${GREEN}${B}├──────────────────────────────────────────────────┤${R}"

        for i in "${!versions[@]}"; do
            printf "${GREEN}${B}│${R}  ${CYAN}%2d${R}  %-43s${GREEN}${B}│${R}\n" \
                "$((i + 1))" \
                "${versions[$i]}"
        done

        echo -e "${GREEN}${B}│${R}   ${RED}0${R}  ↩ Back                                      ${GREEN}${B}│${R}"
        echo -e "${GREEN}${B}└──────────────────────────────────────────────────┘${R}"
        echo

        read -r -p "$(echo -e "  ${CYAN}🦜 Visible Tech ➜${R} Select version: ")" choice

        # Ctrl+D / empty input
        if [ -z "$choice" ]; then
            echo -e "  ${YELLOW}Please select a version.${R}"
            continue
        fi

        # BACK
        if [ "$choice" = "0" ]; then
            return 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
           [ "$choice" -ge 1 ] &&
           [ "$choice" -le "${#versions[@]}" ]
        then
            VERSION="${versions[$((choice - 1))]}"
            return 0
        fi

        echo
        echo -e "  ${RED}❌ Invalid version.${R}"
    done
}

# ============================================================
# MAIN MENU
# ============================================================

while true; do

    clear 2>/dev/null || true

    echo
    echo -e "${CYAN}${B}╔════════════════════════════════════════════════════════╗${R}"
    echo -e "${CYAN}${B}║${R}             🌍 SELECT OPERATING SYSTEM              ${CYAN}${B}║${R}"
    echo -e "${CYAN}${B}╠════════════════════════════════════════════════════════╣${R}"

    for i in "${!OS_NAMES[@]}"; do

        number=$((i + 1))

        printf "${CYAN}${B}║${R}  ${WHITE}%2d${R}  %s %-43s ${CYAN}${B}║${R}\n" \
            "$number" \
            "$(get_icon "${OS_CODES[$i]}")" \
            "${OS_NAMES[$i]}"

    done

    echo -e "${CYAN}${B}║${R}   ${RED}0${R}  ❌ Exit                                          ${CYAN}${B}║${R}"
    echo -e "${CYAN}${B}╚════════════════════════════════════════════════════════╝${R}"
    echo

    read -r -p "$(echo -e "  ${CYAN}🦜 Visible Tech ➜${R} Select OS: ")" choice

    # ========================================================
    # EXIT
    # ========================================================

    if [ "$choice" = "0" ]; then
        echo
        echo -e "  ${YELLOW}👋 Cancelled.${R}"
        exit 0
    fi

    # ========================================================
    # VALIDATE OS
    # ========================================================

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "${#OS_NAMES[@]}" ]
    then
        echo
        echo -e "  ${RED}❌ Invalid selection.${R}"
        sleep 1
        continue
    fi

    INDEX=$((choice - 1))
    DISTRO="${OS_CODES[$INDEX]}"
    OS_NAME="${OS_NAMES[$INDEX]}"

    VERSION=""

    # ========================================================
    # RESET
    # ========================================================

    if [ "$DISTRO" = "reset" ]; then

        echo
        echo -e "${YELLOW}${B}⚠️  RESET / RECOVERY${R}"
        echo
        echo -e "  This will execute the upstream:"
        echo -e "  ${WHITE}reinstall.sh reset${R}"
        echo

        read -r -p "$(echo -e "  ${RED}⚡ Continue? [y/N]: ${R}")" confirm

        case "$confirm" in
            y|Y|yes|YES|Yes)
                exec bash "$TMP" reset
                ;;
            *)
                echo -e "  ${YELLOW}Cancelled.${R}"
                sleep 1
                continue
                ;;
        esac
    fi

    # ========================================================
    # VERSION SELECTION
    # ========================================================

    case "$DISTRO" in

        anolis)
            choose_version "Anolis OS" \
                "7" "8" "23" || continue
            ;;

        opencloudos)
            choose_version "OpenCloudOS" \
                "8" "9" "23" || continue
            ;;

        rocky)
            choose_version "Rocky Linux" \
                "8" "9" "10" || continue
            ;;

        oracle)
            choose_version "Oracle Linux" \
                "8" "9" "10" || continue
            ;;

        almalinux)
            choose_version "AlmaLinux" \
                "8" "9" "10" || continue
            ;;

        centos)
            choose_version "CentOS" \
                "9" "10" || continue
            ;;

        fnos)
            VERSION="1"
            ;;

        fygoos)
            VERSION="1"
            ;;

        nixos)
            VERSION="26.05"
            ;;

        fedora)
            choose_version "Fedora" \
                "43" "44" || continue
            ;;

        debian)
            choose_version "Debian" \
                "9" "10" "11" "12" "13" || continue
            ;;

        opensuse)
            choose_version "openSUSE" \
                "16.0" "Tumbleweed" || continue

            VERSION=$(echo "$VERSION" | tr '[:upper:]' '[:lower:]')
            ;;

        alpine)
            choose_version "Alpine Linux" \
                "3.21" "3.22" "3.23" "3.24" || continue
            ;;

        kali)
            choose_version "Kali Linux" \
                "Last-Snapshot" "Rolling" || continue

            VERSION=$(echo "$VERSION" | tr '[:upper:]' '[:lower:]')
            ;;

        openeuler)
            choose_version "openEuler" \
                "20.03" "22.03" "24.03" "26.09" || continue
            ;;

        ubuntu)
            choose_version "Ubuntu" \
                "18.04" "20.04" "22.04" "24.04" "26.04" || continue
            ;;

        arch|gentoo|aosc|netboot.xyz)
            VERSION=""
            ;;

        redhat)
            echo
            echo -e "${YELLOW}Red Hat requires an image URL.${R}"
            echo
            read -r -p "  Image URL: " IMAGE_URL

            if [ -z "$IMAGE_URL" ]; then
                echo -e "${RED}❌ Image URL cannot be empty.${R}"
                sleep 1
                continue
            fi

            VERSION="--img=$IMAGE_URL"
            ;;

        dd)
            echo
            echo -e "${YELLOW}DD requires a raw image URL.${R}"
            echo

            read -r -p "  Image URL: " IMAGE_URL

            if [ -z "$IMAGE_URL" ]; then
                echo -e "${RED}❌ Image URL cannot be empty.${R}"
                sleep 1
                continue
            fi

            VERSION="--img=$IMAGE_URL"
            ;;

        windows)
            echo
            echo -e "${YELLOW}Windows installation options${R}"
            echo

            read -r -p "  Windows image name: " IMAGE_NAME

            if [ -z "$IMAGE_NAME" ]; then
                echo -e "${RED}❌ Image name cannot be empty.${R}"
                sleep 1
                continue
            fi

            VERSION="--image-name=$IMAGE_NAME"
            ;;

        *)
            VERSION=""
            ;;
    esac

    # ========================================================
    # SUMMARY
    # ========================================================

    echo

    echo -e "${MAGENTA}${B}╔════════════════════════════════════════════════════════╗${R}"
    echo -e "${MAGENTA}${B}║${R}             📋 INSTALLATION SUMMARY                 ${MAGENTA}${B}║${R}"
    echo -e "${MAGENTA}${B}╠════════════════════════════════════════════════════════╣${R}"

    printf "${MAGENTA}${B}║${R}  🦜 Brand   : %-40s ${MAGENTA}${B}║${R}\n" \
        "Visible Tech"

    printf "${MAGENTA}${B}║${R}  🌍 OS      : %-40s ${MAGENTA}${B}║${R}\n" \
        "$OS_NAME"

    if [ -n "$VERSION" ]; then
        printf "${MAGENTA}${B}║${R}  📦 Version : %-40s ${MAGENTA}${B}║${R}\n" \
            "$VERSION"
    fi

    echo -e "${MAGENTA}${B}╚════════════════════════════════════════════════════════╝${R}"

    echo
    echo -e "${RED}${B}⚠️  WARNING${R}"
    echo -e "${RED}   This operation can erase the VPS system disk.${R}"
    echo -e "${RED}   Existing data may be permanently lost.${R}"
    echo

    read -r -p "$(echo -e "  ${YELLOW}⚡ Start reinstallation? [y/N]: ${R}")" confirm

    case "$confirm" in
        y|Y|yes|YES|Yes)
            ;;
        *)
            echo
            echo -e "  ${YELLOW}👋 Reinstallation cancelled.${R}"
            sleep 1
            continue
            ;;
    esac

    # ========================================================
    # BUILD COMMAND
    # ========================================================

    CMD=(bash "$TMP" "$DISTRO")

    if [ -n "$VERSION" ]; then

        if [[ "$DISTRO" = "redhat" || "$DISTRO" = "dd" || "$DISTRO" = "windows" ]]; then
            CMD+=("$VERSION")
        else
            CMD+=("$VERSION")
        fi

    fi

    # ========================================================
    # START
    # ========================================================

    clear 2>/dev/null || true

    echo
    echo -e "${CYAN}${B}╔════════════════════════════════════════════════════════╗${R}"
    echo -e "${CYAN}${B}║${R}          🚀 VISIBLE TECH🦜 REINSTALLING            ${CYAN}${B}║${R}"
    echo -e "${CYAN}${B}╚════════════════════════════════════════════════════════╝${R}"
    echo

    echo -e "  ${GREEN}✓${R} OS      : ${WHITE}$OS_NAME${R}"

    if [ -n "$VERSION" ]; then
        echo -e "  ${GREEN}✓${R} Version : ${WHITE}$VERSION${R}"
    fi

    echo -e "  ${GREEN}✓${R} Engine  : ${WHITE}bin456789/reinstall${R}"
    echo

    echo -e "${YELLOW}⚠️  Starting upstream installer...${R}"
    echo

    sleep 2

    # ========================================================
    # RUN REAL REINSTALLER
    # ========================================================

    exec "${CMD[@]}"

done
