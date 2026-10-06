#!/usr/bin/env bash

# ==============================================================
# 🦜 VISIBLE TECH REINSTALLER
# Powered by bin456789/reinstall
# GitHub: wavy07/reinstallation
# ==============================================================

set -u

UPSTREAM="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
TMP="/tmp/visible-tech-upstream-reinstall.sh"

# ==============================================================
# COLORS
# ==============================================================

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'

BRIGHT_RED='\033[1;31m'
BRIGHT_GREEN='\033[1;32m'
BRIGHT_YELLOW='\033[1;33m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_MAGENTA='\033[1;35m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_WHITE='\033[1;37m'

# ==============================================================
# TERMINAL
# ==============================================================

hide_cursor() {
    printf '\033[?25l'
}

show_cursor() {
    printf '\033[?25h'
}

trap show_cursor EXIT INT TERM

clear_screen() {
    clear 2>/dev/null || printf '\033c'
}

sleep_small() {
    sleep 0.08
}

# ==============================================================
# ANIMATIONS
# ==============================================================

spinner() {
    local pid="$1"
    local text="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    hide_cursor

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${BRIGHT_CYAN}${spin:i++%${#spin}:1}${RESET} ${WHITE}%s${RESET}" "$text"
        sleep 0.08
    done

    printf "\r\033[K"
    show_cursor
}

loading_bar() {
    local text="$1"
    local width=30

    hide_cursor

    printf "\n  ${CYAN}%s${RESET}\n  [" "$text"

    for ((i=0; i<width; i++)); do
        printf "${BRIGHT_CYAN}█${RESET}"
        sleep 0.025
    done

    printf "] ${BRIGHT_GREEN}100%%${RESET}\n"
    show_cursor
}

type_text() {
    local text="$1"
    local delay="${2:-0.015}"
    local i

    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:i:1}"
        sleep "$delay"
    done
}

# ==============================================================
# BANNER
# ==============================================================

banner() {
    echo
    echo "${BRIGHT_CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo "${BRIGHT_CYAN}║${RESET}                                                            ${BRIGHT_CYAN}║${RESET}"
    echo "${BRIGHT_CYAN}║${RESET}       ${BRIGHT_YELLOW}${BOLD}🦜 VISIBLE TECH${RESET} ${DIM}• VPS REINSTALLER${RESET}       ${BRIGHT_CYAN}║${RESET}"
    echo "${BRIGHT_CYAN}║${RESET}                                                            ${BRIGHT_CYAN}║${RESET}"
    echo "${BRIGHT_CYAN}║${RESET}       ${WHITE}Fast • Clean • Simple • Powerful${RESET}                 ${BRIGHT_CYAN}║${RESET}"
    echo "${BRIGHT_CYAN}║${RESET}                                                            ${BRIGHT_CYAN}║${RESET}"
    echo "${BRIGHT_CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo
}

small_banner() {
    echo
    echo "${BRIGHT_CYAN}┌────────────────────────────────────────────────────────────┐${RESET}"
    printf "${BRIGHT_CYAN}│${RESET}  ${BRIGHT_YELLOW}🦜 VISIBLE TECH${RESET}  ${DIM}OS REINSTALLER${RESET}"
    printf "%*s${BRIGHT_CYAN}│${RESET}\n" 35 ""
    echo "${BRIGHT_CYAN}└────────────────────────────────────────────────────────────┘${RESET}"
    echo
}

separator() {
    echo "${DIM}────────────────────────────────────────────────────────────${RESET}"
}

# ==============================================================
# INPUT
# ==============================================================

pause_menu() {
    echo
    read -rp "  ${DIM}Press ENTER to continue...${RESET}" _
}

invalid() {
    echo
    echo "  ${BRIGHT_RED}✖ Invalid selection.${RESET}"
    sleep 1
}

# ==============================================================
# DOWNLOAD UPSTREAM
# ==============================================================

download_upstream() {

    echo
    echo "  ${BRIGHT_CYAN}◉${RESET} ${WHITE}Preparing upstream installer...${RESET}"

    rm -f "$TMP"

    if command -v curl >/dev/null 2>&1; then

        curl -fsSL "$UPSTREAM" -o "$TMP" >/dev/null 2>&1 &
        local pid=$!

        spinner "$pid" "Downloading latest reinstall engine"

        wait "$pid"

    elif command -v wget >/dev/null 2>&1; then

        wget -q "$UPSTREAM" -O "$TMP" >/dev/null 2>&1 &
        local pid=$!

        spinner "$pid" "Downloading latest reinstall engine"

        wait "$pid"

    else
        echo
        echo "  ${BRIGHT_RED}✖ curl or wget is required.${RESET}"
        return 1
    fi

    if [ ! -s "$TMP" ]; then
        echo
        echo "  ${BRIGHT_RED}✖ Failed to download upstream installer.${RESET}"
        return 1
    fi

    chmod +x "$TMP"

    echo "  ${BRIGHT_GREEN}✔ Upstream installer ready.${RESET}"

    return 0
}

# ==============================================================
# CONFIRMATION
# ==============================================================

confirm_install() {

    local distro="$1"
    local version="$2"

    clear_screen
    small_banner

    echo "  ${BRIGHT_YELLOW}${BOLD}⚠  FINAL CONFIRMATION${RESET}"
    echo

    separator

    echo
    echo "  ${WHITE}Selected OS:${RESET} ${BRIGHT_CYAN}${BOLD}${distro}${RESET}"
    echo "  ${WHITE}Version:${RESET}    ${BRIGHT_GREEN}${BOLD}${version}${RESET}"
    echo
    separator

    echo
    echo "  ${BRIGHT_RED}${BOLD}⚠ WARNING${RESET}"
    echo
    echo "  ${YELLOW}This will reinstall your VPS operating system.${RESET}"
    echo "  ${YELLOW}Your existing system and data may be erased.${RESET}"
    echo
    echo "  ${DIM}Make sure important data has been backed up.${RESET}"
    echo

    read -rp "  ${BRIGHT_YELLOW}Type YES to continue: ${RESET}" answer

    if [ "$answer" != "YES" ]; then
        echo
        echo "  ${BRIGHT_GREEN}✔ Reinstallation cancelled.${RESET}"
        sleep 1
        return 1
    fi

    return 0
}

# ==============================================================
# RUN UPSTREAM
# ==============================================================

run_reinstall() {

    local distro="$1"
    local version="$2"

    if ! download_upstream; then
        pause_menu
        return
    fi

    if ! confirm_install "$distro" "$version"; then
        pause_menu
        return
    fi

    clear_screen
    small_banner

    echo
    echo "  ${BRIGHT_GREEN}${BOLD}🚀 Starting Visible Tech reinstallation...${RESET}"
    echo
    echo "  ${WHITE}OS:${RESET}      ${BRIGHT_CYAN}${distro}${RESET}"
    echo "  ${WHITE}Version:${RESET} ${BRIGHT_GREEN}${version}${RESET}"
    echo

    loading_bar "Initializing"

    echo
    echo "  ${BRIGHT_MAGENTA}🦜 Visible Tech${RESET} ${DIM}→${RESET} ${WHITE}bin456789/reinstall${RESET}"
    echo
    separator
    echo

    sleep 1

    # ----------------------------------------------------------
    # IMPORTANT:
    # Pass the selected distro/version directly to the official
    # upstream installer.
    # ----------------------------------------------------------

    exec bash "$TMP" "$distro" "$version"
}

# ==============================================================
# SIMPLE DISTRO SELECTION
# ==============================================================

select_simple() {

    local distro="$1"
    local display="$2"

    clear_screen
    small_banner

    echo "  ${BRIGHT_YELLOW}${BOLD}${display}${RESET}"
    echo
    separator
    echo

    echo "  ${BRIGHT_CYAN}1${RESET}) ${WHITE}Latest / Rolling${RESET}"
    echo
    echo "  ${BRIGHT_RED}0${RESET}) ${DIM}Back${RESET}"
    echo

    read -rp "  ${BRIGHT_CYAN}Select: ${RESET}" choice

    case "$choice" in
        1)
            run_reinstall "$distro" ""
            ;;
        0)
            return
            ;;
        *)
            invalid
            ;;
    esac
}

# ==============================================================
# VERSION MENU
# ==============================================================

version_menu() {

    local distro="$1"
    local display="$2"
    shift 2

    local versions=("$@")

    while true; do

        clear_screen
        small_banner

        echo "  ${BRIGHT_YELLOW}${BOLD}${display}${RESET}"
        echo
        separator
        echo

        local i=1

        for version in "${versions[@]}"; do
            printf "  ${BRIGHT_CYAN}%2d${RESET}) ${WHITE}%s${RESET}\n" "$i" "$version"
            ((i++))
        done

        echo
        echo "  ${BRIGHT_RED}0${RESET}) ${DIM}Back${RESET}"
        echo

        read -rp "  ${BRIGHT_CYAN}Select version: ${RESET}" choice

        if [[ "$choice" =~ ^[0-9]+$ ]]; then

            if [ "$choice" -eq 0 ]; then
                return
            fi

            local index=$((choice - 1))

            if [ "$index" -ge 0 ] &&
               [ "$index" -lt "${#versions[@]}" ]; then

                run_reinstall "$distro" "${versions[$index]}"
                return

            fi
        fi

        invalid
    done
}

# ==============================================================
# MAIN MENU
# ==============================================================

main_menu() {

    while true; do

        clear_screen
        banner

        echo "  ${BRIGHT_WHITE}${BOLD}Choose an operating system${RESET}"
        echo
        separator
        echo

        echo "  ${BRIGHT_CYAN} 1${RESET}) 🟠 ${WHITE}Anolis OS${RESET}"
        echo "  ${BRIGHT_CYAN} 2${RESET}) 🔵 ${WHITE}OpenCloudOS${RESET}"
        echo "  ${BRIGHT_CYAN} 3${RESET}) 🟢 ${WHITE}Rocky Linux${RESET}"
        echo "  ${BRIGHT_CYAN} 4${RESET}) 🟡 ${WHITE}Oracle Linux${RESET}"
        echo "  ${BRIGHT_CYAN} 5${RESET}) 🟢 ${WHITE}AlmaLinux${RESET}"
        echo "  ${BRIGHT_CYAN} 6${RESET}) 🔴 ${WHITE}CentOS Stream${RESET}"
        echo "  ${BRIGHT_CYAN} 7${RESET}) 🟣 ${WHITE}fnOS${RESET}"
        echo "  ${BRIGHT_CYAN} 8${RESET}) 🟣 ${WHITE}FygoOS${RESET}"
        echo "  ${BRIGHT_CYAN} 9${RESET}) 🔷 ${WHITE}NixOS${RESET}"
        echo "  ${BRIGHT_CYAN}10${RESET}) 🟦 ${WHITE}Fedora${RESET}"
        echo "  ${BRIGHT_CYAN}11${RESET}) 🔴 ${WHITE}Debian${RESET}"
        echo "  ${BRIGHT_CYAN}12${RESET}) 🦎 ${WHITE}openSUSE${RESET}"
        echo "  ${BRIGHT_CYAN}13${RESET}) 🏔️  ${WHITE}Alpine Linux${RESET}"
        echo "  ${BRIGHT_CYAN}14${RESET}) 🐉 ${WHITE}Kali Linux${RESET}"
        echo "  ${BRIGHT_CYAN}15${RESET}) 🟢 ${WHITE}openEuler${RESET}"
        echo "  ${BRIGHT_CYAN}16${RESET}) 🟠 ${WHITE}Ubuntu${RESET}"
        echo "  ${BRIGHT_CYAN}17${RESET}) ⚫ ${WHITE}Arch Linux${RESET}"
        echo "  ${BRIGHT_CYAN}18${RESET}) 🟣 ${WHITE}Gentoo${RESET}"
        echo "  ${BRIGHT_CYAN}19${RESET}) 🔵 ${WHITE}AOSC OS${RESET}"
        echo
        echo "  ${BRIGHT_MAGENTA}20${RESET}) 🪟 ${WHITE}Windows${RESET}"
        echo "  ${BRIGHT_MAGENTA}21${RESET}) 🌐 ${WHITE}netboot.xyz${RESET}"
        echo "  ${BRIGHT_MAGENTA}22${RESET}) 💿 ${WHITE}Custom Image / DD${RESET}"
        echo
        separator
        echo
        echo "  ${BRIGHT_RED}0${RESET}) ${DIM}Exit${RESET}"
        echo

        read -rp "  ${BRIGHT_CYAN}🦜 Select OS: ${RESET}" choice

        case "$choice" in

            1)
                version_menu anolis "ANOLIS OS" \
                    7 8 23
                ;;

            2)
                version_menu opencloudos "OPENCLOUDOS" \
                    8 9 23
                ;;

            3)
                version_menu rocky "ROCKY LINUX" \
                    8 9 10
                ;;

            4)
                version_menu oracle "ORACLE LINUX" \
                    8 9 10
                ;;

            5)
                version_menu almalinux "ALMALINUX" \
                    8 9 10
                ;;

            6)
                version_menu centos "CENTOS STREAM" \
                    9 10
                ;;

            7)
                version_menu fnos "fnOS" \
                    1
                ;;

            8)
                version_menu fygoos "FygoOS" \
                    1
                ;;

            9)
                version_menu nixos "NixOS" \
                    26.05
                ;;

            10)
                version_menu fedora "FEDORA" \
                    43 44
                ;;

            11)
                version_menu debian "DEBIAN" \
                    9 10 11 12 13
                ;;

            12)
                version_menu opensuse "openSUSE" \
                    16.0 tumbleweed
                ;;

            13)
                version_menu alpine "ALPINE LINUX" \
                    3.21 3.22 3.23 3.24
                ;;

            14)
                version_menu kali "KALI LINUX" \
                    last-snapshot rolling
                ;;

            15)
                version_menu openeuler "openEuler" \
                    20.03 22.03 24.03 26.09
                ;;

            16)
                version_menu ubuntu "UBUNTU" \
                    18.04 20.04 22.04 24.04 26.04
                ;;

            17)
                select_simple arch "ARCH LINUX"
                ;;

            18)
                select_simple gentoo "GENTOO"
                ;;

            19)
                select_simple aosc "AOSC OS"
                ;;

            20)
                clear_screen
                small_banner

                echo "  ${BRIGHT_YELLOW}${BOLD}WINDOWS${RESET}"
                echo
                separator
                echo
                echo "  ${YELLOW}Windows installation requires an image name.${RESET}"
                echo "  ${DIM}The upstream installer supports Windows through --image-name.${RESET}"
                echo
                echo "  Example:"
                echo "  ${CYAN}windows --image-name=\"windows 11\"${RESET}"
                echo
                echo "  ${BRIGHT_RED}0${RESET}) Back"
                echo

                read -rp "  ${BRIGHT_CYAN}Enter Windows image name: ${RESET}" winimage

                if [ -n "$winimage" ]; then
                    clear_screen
                    small_banner

                    echo
                    echo "  ${BRIGHT_RED}${BOLD}⚠ Windows Reinstallation${RESET}"
                    echo
                    echo "  Image: ${BRIGHT_CYAN}$winimage${RESET}"
                    echo

                    read -rp "  Type YES to continue: " confirm

                    if [ "$confirm" = "YES" ]; then

                        download_upstream || {
                            pause_menu
                            continue
                        }

                        exec bash "$TMP" windows \
                            --image-name="$winimage"
                    else
                        echo
                        echo "  ${GREEN}Cancelled.${RESET}"
                        sleep 1
                    fi
                fi
                ;;

            21)
                clear_screen
                small_banner

                echo "  ${BRIGHT_YELLOW}${BOLD}NETBOOT.XYZ${RESET}"
                echo
                separator
                echo
                echo "  ${WHITE}This will boot the netboot.xyz environment.${RESET}"
                echo
                read -rp "  Type YES to continue: " confirm

                if [ "$confirm" = "YES" ]; then
                    download_upstream || {
                        pause_menu
                        continue
                    }

                    exec bash "$TMP" netboot.xyz
                fi
                ;;

            22)
                clear_screen
                small_banner

                echo "  ${BRIGHT_YELLOW}${BOLD}CUSTOM IMAGE / DD${RESET}"
                echo
                separator
                echo
                echo "  ${DIM}Enter the image URL supported by the upstream script.${RESET}"
                echo
                read -rp "  ${BRIGHT_CYAN}Image URL: ${RESET}" image_url

                if [ -n "$image_url" ]; then

                    echo
                    echo "  ${BRIGHT_RED}${BOLD}⚠ DESTRUCTIVE OPERATION${RESET}"
                    echo
                    read -rp "  Type YES to continue: " confirm

                    if [ "$confirm" = "YES" ]; then

                        download_upstream || {
                            pause_menu
                            continue
                        }

                        exec bash "$TMP" dd --img="$image_url"

                    fi
                fi
                ;;

            0)
                clear_screen
                echo
                echo "  ${BRIGHT_CYAN}${BOLD}🦜 Visible Tech${RESET}"
                echo "  ${GREEN}Thank you for using Visible Tech Reinstaller.${RESET}"
                echo
                show_cursor
                exit 0
                ;;

            *)
                invalid
                ;;
        esac

    done
}

# ==============================================================
# START
# ==============================================================

hide_cursor

clear_screen

echo
echo "${BRIGHT_CYAN}${BOLD}"
type_text "        🦜 VISIBLE TECH" 0.04
echo
echo "${RESET}"

sleep 0.3

loading_bar "Starting reinstaller"

main_menu
