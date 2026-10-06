#!/usr/bin/env bash

# ==========================================================
# 🦜 VISIBLE TECH REINSTALLER
# Ubuntu 18.04 - 26.04
# Debian 9 - 13
# Powered by bin456789/reinstall
# ==========================================================

set -u

UPSTREAM="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
TMP="/tmp/bin456789-reinstall.sh"

# ----------------------------------------------------------
# REAL ANSI COLORS
# ----------------------------------------------------------

RESET="$(printf '\033[0m')"
BOLD="$(printf '\033[1m')"
CYAN="$(printf '\033[1;36m')"
GREEN="$(printf '\033[1;32m')"
YELLOW="$(printf '\033[1;33m')"
RED="$(printf '\033[1;31m')"
WHITE="$(printf '\033[1;37m')"
MAGENTA="$(printf '\033[1;35m')"
DIM="$(printf '\033[2m')"

# ----------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------

cleanup() {
    printf '%b' "$RESET"
    printf '\033[?25h'
}

trap cleanup EXIT INT TERM

clear_screen() {
    printf '\033[2J\033[H'
}

header() {
    clear_screen

    printf '%b\n' "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    printf '%b\n' "${CYAN}║${RESET}                                                      ${CYAN}║${RESET}"
    printf '%b\n' "${CYAN}║${RESET}              ${YELLOW}${BOLD}🦜 VISIBLE TECH${RESET}                       ${CYAN}║${RESET}"
    printf '%b\n' "${CYAN}║${RESET}              ${WHITE}VPS REINSTALLER${RESET}                       ${CYAN}║${RESET}"
    printf '%b\n' "${CYAN}║${RESET}                                                      ${CYAN}║${RESET}"
    printf '%b\n' "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
    printf '\n'
}

download_upstream() {

    printf '%b\n' "${CYAN}Downloading latest reinstall engine...${RESET}"

    rm -f "$TMP"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$UPSTREAM" -o "$TMP"; then
            printf '%b\n' "${RED}ERROR: Could not download upstream script.${RESET}"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$UPSTREAM" -O "$TMP"; then
            printf '%b\n' "${RED}ERROR: Could not download upstream script.${RESET}"
            return 1
        fi
    else
        printf '%b\n' "${RED}ERROR: curl or wget is required.${RESET}"
        return 1
    fi

    if [ ! -s "$TMP" ]; then
        printf '%b\n' "${RED}ERROR: Downloaded file is empty.${RESET}"
        return 1
    fi

    chmod +x "$TMP"

    printf '%b\n' "${GREEN}✓ Upstream installer ready.${RESET}"
    return 0
}

confirm_install() {

    local os="$1"
    local version="$2"

    clear_screen
    header

    printf '%b\n' "${YELLOW}${BOLD}Selected operating system${RESET}"
    printf '\n'

    printf '  OS:       %b\n' "${CYAN}${BOLD}${os}${RESET}"
    printf '  Version:  %b\n' "${GREEN}${BOLD}${version}${RESET}"

    printf '\n'
    printf '%b\n' "${RED}${BOLD}WARNING${RESET}"
    printf '%b\n' "${RED}This will reinstall the VPS operating system.${RESET}"
    printf '%b\n' "${RED}Existing data may be erased.${RESET}"
    printf '\n'

    printf '%b' "${YELLOW}Type YES to continue: ${RESET}"
    read -r answer

    if [ "$answer" != "YES" ]; then
        printf '\n%b\n' "${GREEN}Installation cancelled.${RESET}"
        sleep 1
        return 1
    fi

    return 0
}

start_install() {

    local os="$1"
    local version="$2"

    if ! download_upstream; then
        printf '\n'
        read -r -p "Press ENTER to return to menu..."
        return
    fi

    if ! confirm_install "$os" "$version"; then
        return
    fi

    clear_screen
    header

    printf '%b\n' "${GREEN}${BOLD}Starting reinstallation...${RESET}"
    printf '\n'

    printf '  ${WHITE}OS:${RESET} %b\n' "${CYAN}${os}${RESET}"
    printf '  ${WHITE}Version:${RESET} %b\n' "${GREEN}${version}${RESET}"

    printf '\n'
    printf '%b\n' "${MAGENTA}🦜 Visible Tech → bin456789/reinstall${RESET}"
    printf '\n'

    sleep 1

    # IMPORTANT:
    # Do not loop back to our menu.
    # Directly execute the official installer.

    exec bash "$TMP" "$os" "$version"
}

# ----------------------------------------------------------
# UBUNTU MENU
# ----------------------------------------------------------

ubuntu_menu() {

    while true; do

        header

        printf '%b\n' "${GREEN}${BOLD}UBUNTU${RESET}"
        printf '\n'

        printf '  %b) Ubuntu 18.04\n' "${CYAN}1${RESET}"
        printf '  %b) Ubuntu 20.04\n' "${CYAN}2${RESET}"
        printf '  %b) Ubuntu 22.04\n' "${CYAN}3${RESET}"
        printf '  %b) Ubuntu 24.04\n' "${CYAN}4${RESET}"
        printf '  %b) Ubuntu 26.04\n' "${CYAN}5${RESET}"

        printf '\n'
        printf '  %b) Back\n' "${RED}0${RESET}"
        printf '\n'

        printf '%b' "${CYAN}Select version: ${RESET}"
        read -r choice

        case "$choice" in
            1) start_install "ubuntu" "18.04"; return ;;
            2) start_install "ubuntu" "20.04"; return ;;
            3) start_install "ubuntu" "22.04"; return ;;
            4) start_install "ubuntu" "24.04"; return ;;
            5) start_install "ubuntu" "26.04"; return ;;
            0) return ;;
            *)
                printf '%b\n' "${RED}Invalid selection.${RESET}"
                sleep 1
                ;;
        esac

    done
}

# ----------------------------------------------------------
# DEBIAN MENU
# ----------------------------------------------------------

debian_menu() {

    while true; do

        header

        printf '%b\n' "${RED}${BOLD}DEBIAN${RESET}"
        printf '\n'

        printf '  %b) Debian 9\n' "${CYAN}1${RESET}"
        printf '  %b) Debian 10\n' "${CYAN}2${RESET}"
        printf '  %b) Debian 11\n' "${CYAN}3${RESET}"
        printf '  %b) Debian 12\n' "${CYAN}4${RESET}"
        printf '  %b) Debian 13\n' "${CYAN}5${RESET}"

        printf '\n'
        printf '  %b) Back\n' "${RED}0${RESET}"
        printf '\n'

        printf '%b' "${CYAN}Select version: ${RESET}"
        read -r choice

        case "$choice" in
            1) start_install "debian" "9"; return ;;
            2) start_install "debian" "10"; return ;;
            3) start_install "debian" "11"; return ;;
            4) start_install "debian" "12"; return ;;
            5) start_install "debian" "13"; return ;;
            0) return ;;
            *)
                printf '%b\n' "${RED}Invalid selection.${RESET}"
                sleep 1
                ;;
        esac

    done
}

# ----------------------------------------------------------
# MAIN MENU
# ----------------------------------------------------------

main_menu() {

    while true; do

        header

        printf '%b\n' "${WHITE}${BOLD}Choose your operating system${RESET}"
        printf '\n'

        printf '  %b) Ubuntu\n' "${CYAN}1${RESET}"
        printf '  %b) Debian\n' "${CYAN}2${RESET}"

        printf '\n'
        printf '%b\n' "${DIM}──────────────────────────────────────────────────────${RESET}"
        printf '\n'

        printf '  %b) Exit\n' "${RED}0${RESET}"
        printf '\n'

        printf '%b' "${CYAN}🦜 Select OS: ${RESET}"
        read -r choice

        case "$choice" in

            1)
                ubuntu_menu
                ;;

            2)
                debian_menu
                ;;

            0)
                clear_screen
                printf '\n'
                printf '%b\n' "${CYAN}${BOLD}🦜 Visible Tech${RESET}"
                printf '%b\n' "${GREEN}Goodbye.${RESET}"
                printf '\n'
                exit 0
                ;;

            *)
                printf '%b\n' "${RED}Invalid selection.${RESET}"
                sleep 1
                ;;

        esac

    done
}

# ----------------------------------------------------------
# START
# ----------------------------------------------------------

printf '\033[?25l'

main_menu
