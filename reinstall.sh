#!/usr/bin/env bash

# ============================================================
#        🦜 VISIBLE TECH REINSTALLER
#        Dynamic frontend for bin456789/reinstall
# ============================================================

set -u

UPSTREAM="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
TMP="/tmp/.visible-tech-reinstall.$$"

RESET='\033[0m'
BOLD='\033[1m'
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
# ROOT CHECK
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "${RED}❌ Root privileges are required.${RESET}"
    echo -e "   ${CYAN}sudo bash $0${RESET}"
    echo
    exit 1
fi

# ============================================================
# REQUIRE CURL
# ============================================================

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}❌ curl is required.${RESET}"
    exit 1
fi

# ============================================================
# HEADER
# ============================================================

clear 2>/dev/null || true

echo
echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║${RESET}        🚀 VISIBLE TECH🦜 REINSTALLER             ${CYAN}${BOLD}║${RESET}"
echo -e "${CYAN}${BOLD}║${RESET}             VPS OS INSTALLATION                  ${CYAN}${BOLD}║${RESET}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"
echo

# ============================================================
# DOWNLOAD UPSTREAM SCRIPT
# ============================================================

printf "  ${CYAN}⠋${RESET} Loading supported operating systems..."

if ! curl -fsSL \
    --connect-timeout 10 \
    "$UPSTREAM" \
    -o "$TMP" >/dev/null 2>&1
then
    echo -e "\r  ${RED}✗${RESET} Unable to download reinstall engine."
    exit 1
fi

echo -e "\r  ${GREEN}✓${RESET} Reinstall engine loaded.                    "

chmod +x "$TMP"

# ============================================================
# READ UPSTREAM USAGE
# ============================================================

usage="$(
    sed -n '/^usage_and_exit()/,/^}/p' "$TMP" 2>/dev/null |
    sed -n '/cat <<EOF/,/^EOF/p' |
    sed '1d;$d'
)"

if [ -z "$usage" ]; then
    echo
    echo -e "${RED}❌ Could not read supported OS list.${RESET}"
    echo -e "${YELLOW}The upstream installer format may have changed.${RESET}"
    exit 1
fi

# ============================================================
# SUPPORTED OS STORAGE
# ============================================================

declare -a DISTROS=()
declare -A SPECS

# ============================================================
# PARSE OS LIST
# ============================================================

while IFS= read -r line; do

    line="$(printf '%s' "$line" |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    [ -z "$line" ] && continue

    case "$line" in
        Usage:*|Options:*|Manual:*|For\ *|http://*|https://*)
            continue
            ;;
    esac

    distro="$(printf '%s\n' "$line" | awk '{print $1}')"
    rest="$(printf '%s\n' "$line" | cut -d' ' -f2-)"

    if ! printf '%s' "$distro" |
        grep -Eq '^[a-zA-Z0-9._-]+$'
    then
        continue
    fi

    case "$distro" in

        anolis|opencloudos|rocky|oracle|almalinux|centos|\
        fnos|fygoos|nixos|fedora|debian|opensuse|alpine|\
        kali|openeuler|ubuntu|arch|gentoo|aosc|redhat|\
        dd|windows|netboot.xyz|reset)

            ;;

        *)
            continue
            ;;
    esac

    if [ -z "${SPECS[$distro]+x}" ]; then
        DISTROS+=("$distro")
    fi

    SPECS["$distro"]="$rest"

done <<< "$usage"

if [ "${#DISTROS[@]}" -eq 0 ]; then
    echo
    echo -e "${RED}❌ No supported operating systems detected.${RESET}"
    exit 1
fi

# ============================================================
# DISPLAY NAME
# ============================================================

pretty_name() {

    case "$1" in
        anolis)       echo "Anolis OS" ;;
        opencloudos)  echo "OpenCloudOS" ;;
        rocky)        echo "Rocky Linux" ;;
        oracle)       echo "Oracle Linux" ;;
        almalinux)    echo "AlmaLinux" ;;
        centos)       echo "CentOS" ;;
        fnos)         echo "fnOS" ;;
        fygoos)       echo "FydeOS / FygoOS" ;;
        nixos)        echo "NixOS" ;;
        fedora)       echo "Fedora" ;;
        debian)       echo "Debian" ;;
        opensuse)     echo "openSUSE" ;;
        alpine)       echo "Alpine Linux" ;;
        kali)         echo "Kali Linux" ;;
        openeuler)    echo "openEuler" ;;
        ubuntu)       echo "Ubuntu" ;;
        arch)         echo "Arch Linux" ;;
        gentoo)       echo "Gentoo" ;;
        aosc)         echo "AOSC OS" ;;
        redhat)       echo "Red Hat" ;;
        dd)           echo "DD / Disk Image" ;;
        windows)      echo "Windows" ;;
        netboot.xyz)  echo "netboot.xyz" ;;
        reset)        echo "Reset / Recovery" ;;
        *)            echo "$1" ;;
    esac
}

# ============================================================
# ICON
# ============================================================

icon() {

    case "$1" in
        ubuntu)      echo "🟠" ;;
        debian)      echo "🔴" ;;
        fedora)      echo "🔵" ;;
        rocky)       echo "🟢" ;;
        oracle)      echo "🔵" ;;
        almalinux)   echo "🟢" ;;
        centos)      echo "🟡" ;;
        anolis)      echo "🟠" ;;
        opencloudos) echo "🟡" ;;
        openeuler)   echo "🟢" ;;
        alpine)      echo "🔷" ;;
        kali)        echo "💀" ;;
        opensuse)    echo "🦎" ;;
        arch)        echo "🔵" ;;
        gentoo)      echo "🟣" ;;
        aosc)        echo "🟣" ;;
        nixos)       echo "❄️" ;;
        fnos)        echo "🟣" ;;
        fygoos)      echo "🟣" ;;
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

select_version() {

    local distro="$1"
    local spec="${SPECS[$distro]}"
    local -a versions
    local choice
    local i

    SELECTED_VERSION=""

    # No version list
    if [ -z "$spec" ]; then
        return 0
    fi

    IFS='|' read -ra versions <<< "$spec"

    # If there is only one version/value, use it directly
    if [ "${#versions[@]}" -eq 1 ]; then

        SELECTED_VERSION="${versions[0]}"

        # Don't treat command-line options as versions
        if [[ "$SELECTED_VERSION" == --* ]]; then
            SELECTED_VERSION=""
        fi

        return 0
    fi

    echo

    echo -e "${GREEN}${BOLD}┌──────────────────────────────────────────────────┐${RESET}"
    printf "${GREEN}${BOLD}│${RESET}  %s %-43s${GREEN}${BOLD}│${RESET}\n" \
        "$(icon "$distro")" \
        "$(pretty_name "$distro")"

    echo -e "${GREEN}${BOLD}├──────────────────────────────────────────────────┤${RESET}"

    i=1

    for version in "${versions[@]}"; do

        version="$(echo "$version" | xargs)"

        [ -z "$version" ] && continue

        printf "${GREEN}${BOLD}│${RESET}  ${CYAN}%2d${RESET}  %-43s${GREEN}${BOLD}│${RESET}\n" \
            "$i" "$version"

        i=$((i + 1))
    done

    printf "${GREEN}${BOLD}│${RESET}  ${RED} 0${RESET}  %-43s${GREEN}${BOLD}│${RESET}\n" \
        "← Back"

    echo -e "${GREEN}${BOLD}└──────────────────────────────────────────────────┘${RESET}"

    echo

    while true; do

        read -rp \
            "$(echo -e "  ${CYAN}➜${RESET} Select version: ")" \
            choice

        if [ "$choice" = "0" ]; then
            return 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
           [ "$choice" -ge 1 ] &&
           [ "$choice" -le "${#versions[@]}" ]
        then

            SELECTED_VERSION="$(
                echo "${versions[$((choice - 1))]}" |
                xargs
            )"

            return 0
        fi

        echo -e "  ${RED}❌ Invalid selection.${RESET}"
    done
}

# ============================================================
# MAIN OS MENU
# ============================================================

while true; do

    echo

    echo -e "${BLUE}${BOLD}┌──────────────────────────────────────────────────┐${RESET}"
    echo -e "${BLUE}${BOLD}│${RESET}          🌍 SELECT OPERATING SYSTEM             ${BLUE}${BOLD}│${RESET}"
    echo -e "${BLUE}${BOLD}├──────────────────────────────────────────────────┤${RESET}"

    i=1

    for distro in "${DISTROS[@]}"; do

        printf \
            "${BLUE}${BOLD}│${RESET}  ${CYAN}%2d${RESET}  %s %-39s${BLUE}${BOLD}│${RESET}\n" \
            "$i" \
            "$(icon "$distro")" \
            "$(pretty_name "$distro")"

        i=$((i + 1))
    done

    printf \
        "${BLUE}${BOLD}│${RESET}  ${RED}%2d${RESET}  ❌ %-39s${BLUE}${BOLD}│${RESET}\n" \
        0 \
        "Exit"

    echo -e "${BLUE}${BOLD}└──────────────────────────────────────────────────┘${RESET}"

    echo

    read -rp \
        "$(echo -e "  ${CYAN}🦜 Visible Tech ➜${RESET} Select OS: ")" \
        choice

    if [ "$choice" = "0" ]; then

        echo
        echo -e "  ${YELLOW}👋 Reinstallation cancelled.${RESET}"
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "${#DISTROS[@]}" ]
    then

        echo -e "  ${RED}❌ Invalid selection.${RESET}"
        continue
    fi

    DISTRO="${DISTROS[$((choice - 1))]}"

    if select_version "$DISTRO"; then
        break
    fi

done

# ============================================================
# SPECIAL IMAGE OPTIONS
# ============================================================

EXTRA_ARGS=()

case "$DISTRO" in

    redhat|dd)

        echo

        echo -e "${YELLOW}💿 This option requires an image URL.${RESET}"

        read -rp \
            "$(echo -e "  ${CYAN}➜${RESET} Image URL: ")" \
            IMAGE_URL

        if [ -z "$IMAGE_URL" ]; then
            echo -e "${RED}❌ Image URL is required.${RESET}"
            exit 1
        fi

        EXTRA_ARGS+=(--img="$IMAGE_URL")
        ;;

    windows)

        echo

        echo -e "${YELLOW}🪟 Windows installation${RESET}"

        read -rp \
            "$(echo -e "  ${CYAN}➜${RESET} Image/ISO URL: ")" \
            IMAGE_URL

        if [ -z "$IMAGE_URL" ]; then
            echo -e "${RED}❌ Image URL is required.${RESET}"
            exit 1
        fi

        EXTRA_ARGS+=(--img="$IMAGE_URL")
        ;;

esac

# ============================================================
# SUMMARY
# ============================================================

echo

echo -e "${MAGENTA}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}${BOLD}║${RESET}              📋 INSTALLATION SUMMARY             ${MAGENTA}${BOLD}║${RESET}"
echo -e "${MAGENTA}${BOLD}╠════════════════════════════════════════════════════╣${RESET}"

printf \
    "${MAGENTA}${BOLD}║${RESET}  🦜 Brand    : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
    "Visible Tech"

printf \
    "${MAGENTA}${BOLD}║${RESET}  🌍 OS       : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
    "$(pretty_name "$DISTRO")"

if [ -n "${SELECTED_VERSION:-}" ]; then

    printf \
        "${MAGENTA}${BOLD}║${RESET}  📦 Version  : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
        "$SELECTED_VERSION"

fi

echo -e "${MAGENTA}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"

echo

echo -e "${RED}${BOLD}⚠️  WARNING${RESET}"
echo -e "${RED}   This operation can erase the VPS system disk.${RESET}"
echo -e "${RED}   Existing data may be permanently lost.${RESET}"

echo

read -rp \
    "$(echo -e "  ${YELLOW}⚡ Start reinstallation? [y/N]: ${RESET}")" \
    confirm

case "$confirm" in

    y|Y|yes|YES|Yes)
        ;;

    *)
        echo
        echo -e "  ${YELLOW}👋 Reinstallation cancelled.${RESET}"
        exit 0
        ;;

esac

# ============================================================
# START REAL REINSTALLER
# ============================================================

echo

echo -e "${CYAN}${BOLD}🚀 Starting Visible Tech🦜 reinstallation...${RESET}"

sleep 0.5

echo
echo -e "  ${GREEN}✓${RESET} OS       : ${WHITE}$(pretty_name "$DISTRO")${RESET}"

if [ -n "${SELECTED_VERSION:-}" ]; then
    echo -e "  ${GREEN}✓${RESET} Version  : ${WHITE}$SELECTED_VERSION${RESET}"
fi

echo -e "  ${GREEN}✓${RESET} Engine   : ${WHITE}bin456789/reinstall${RESET}"

echo

# ============================================================
# EXECUTE UPSTREAM INSTALLER
# ============================================================

CMD=(bash "$TMP" "$DISTRO")

if [ -n "${SELECTED_VERSION:-}" ]; then
    CMD+=("$SELECTED_VERSION")
fi

if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    CMD+=("${EXTRA_ARGS[@]}")
fi

# Keep upstream prompts visible and interactive.
exec "${CMD[@]}"
