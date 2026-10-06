```bash
#!/usr/bin/env bash

# ============================================================
#        🦜 VISIBLE TECH REINSTALLER
#        Dynamic frontend for bin456789/reinstall
# ============================================================
# GitHub: https://github.com/wavy07/reinstallation
# File: reinstall.sh
# ============================================================

set -u

UPSTREAM="https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
REPO_URL="https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh"
TMP="/tmp/.visible-tech-reinstall.$$"

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[97m'
GRAY='\033[90m'

# ============================================================
# CLEANUP
# ============================================================

cleanup() {
    rm -f "$TMP" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# ============================================================
# ROOT CHECK
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "${RED}${BOLD}❌ Root privileges are required.${RESET}"
    echo -e "   ${CYAN}${BOLD}sudo bash $0${RESET}"
    echo
    exit 1
fi

# ============================================================
# REQUIRE CURL
# ============================================================

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}${BOLD}❌ curl is required but not installed.${RESET}"
    echo -e "   ${YELLOW}Please install curl and try again.${RESET}"
    exit 1
fi

# ============================================================
# ENSURE INTERACTIVE INPUT WORKS EVEN WHEN PIPED (curl | bash)
# ============================================================

if [ -t 0 ]; then
    : # stdin is already a terminal, nothing to do
elif [ -r /dev/tty ]; then
    exec < /dev/tty
else
    echo -e "${RED}${BOLD}❌ No interactive terminal available.${RESET}"
    echo -e "${YELLOW}${BOLD}Download the script first and run it locally:${RESET}"
    echo
    echo -e "   ${CYAN}${BOLD}curl -fsSL $REPO_URL -o reinstall.sh${RESET}"
    echo -e "   ${CYAN}${BOLD}sudo bash reinstall.sh${RESET}"
    echo
    exit 1
fi

# ============================================================
# ANIMATION HELPERS
# ============================================================

spinner() {
    local pid=$1
    local message="${2:-Loading}"
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0

    while kill -0 $pid 2>/dev/null; do
        printf "\r  ${CYAN}${chars[$((i % 10))]}${RESET} ${message}..."
        i=$((i + 1))
        sleep 0.1
    done
}

success_msg() {
    echo -e "\r  ${GREEN}${BOLD}✓${RESET} $1                                             "
}

error_msg() {
    echo -e "\r  ${RED}${BOLD}✗${RESET} $1"
}

info_msg() {
    echo -e "  ${CYAN}${BOLD}ℹ${RESET} $1"
}

# ============================================================
# DETECT OS FOR OPTIMIZATION
# ============================================================

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "${DISTRIB_ID:-unknown}" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# ============================================================
# HEADER ANIMATION
# ============================================================

clear 2>/dev/null || true

echo
echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
sleep 0.05
echo -e "${CYAN}${BOLD}║${RESET}        🚀 ${MAGENTA}${BOLD}VISIBLE TECH${RESET} 🦜 ${CYAN}${BOLD}REINSTALLER${RESET}         ${CYAN}${BOLD}║${RESET}"
sleep 0.05
echo -e "${CYAN}${BOLD}║${RESET}           ${WHITE}${BOLD}VPS OS INSTALLATION${RESET}                  ${CYAN}${BOLD}║${RESET}"
sleep 0.05
echo -e "${CYAN}${BOLD}║${RESET}     ${GRAY}Powered by bin456789/reinstall${RESET}            ${CYAN}${BOLD}║${RESET}"
sleep 0.05
echo -e "${CYAN}${BOLD}║${RESET}   ${GRAY}by wavy07 | github.com/wavy07/reinstallation${RESET}   ${CYAN}${BOLD}║${RESET}"
sleep 0.05
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"
echo

sleep 0.3

# ============================================================
# DOWNLOAD UPSTREAM SCRIPT
# ============================================================

echo -n "  ${CYAN}⠋${RESET} Downloading reinstall engine from upstream"

(
    curl -fsSL \
        --connect-timeout 15 \
        --max-time 30 \
        "$UPSTREAM" \
        -o "$TMP" >/dev/null 2>&1
) &

local_pid=$!
spinner $local_pid "Downloading reinstall engine" &
local_spinner_pid=$!

wait $local_pid 2>/dev/null
local_exit=$?

kill $local_spinner_pid 2>/dev/null
wait $local_spinner_pid 2>/dev/null

if [ $local_exit -ne 0 ]; then
    error_msg "Failed to download reinstall engine (network error)"
    echo
    echo -e "  ${YELLOW}${BOLD}💡 Troubleshooting:${RESET}"
    echo -e "     • Check your internet connection"
    echo -e "     • Verify firewall/VPN settings"
    echo -e "     • Check if bin456789/reinstall repository is accessible"
    echo -e "     • Try again in a moment"
    echo
    exit 1
fi

success_msg "Reinstall engine downloaded successfully"
echo

chmod +x "$TMP" 2>/dev/null || true

sleep 0.3

# ============================================================
# READ UPSTREAM USAGE
# ============================================================

echo -n "  ${CYAN}⠙${RESET} Parsing OS database from engine"

usage="$(
    sed -n '/^usage_and_exit()/,/^}/p' "$TMP" 2>/dev/null |
    sed -n '/cat <<EOF/,/^EOF/p' |
    sed '1d;$d'
)"

echo -e "\r  ${GREEN}${BOLD}✓${RESET} OS database parsed successfully              "
sleep 0.2

if [ -z "$usage" ]; then
    echo
    error_msg "Could not read supported OS list from engine"
    echo -e "${YELLOW}${BOLD}The upstream installer format may have changed.${RESET}"
    echo -e "  ${GRAY}Please ensure bin456789/reinstall is up to date.${RESET}"
    exit 1
fi

echo

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
    error_msg "No supported operating systems detected"
    exit 1
fi

sleep 0.3

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

    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
    printf "${GREEN}${BOLD}║${RESET}  %-52s${GREEN}${BOLD}║${RESET}\n" \
        "$(icon "$distro") $(pretty_name "$distro") - ${CYAN}${BOLD}Select Version${RESET}"

    echo -e "${GREEN}${BOLD}╠════════════════════════════════════════════════════╣${RESET}"

    i=1

    for version in "${versions[@]}"; do

        version="$(echo "$version" | xargs)"

        [ -z "$version" ] && continue

        printf "${GREEN}${BOLD}║${RESET}  ${CYAN}${BOLD}[%2d]${RESET}  %-45s${GREEN}${BOLD}║${RESET}\n" \
            "$i" "$version"

        i=$((i + 1))
    done

    printf "${GREEN}${BOLD}║${RESET}  ${RED}${BOLD}[ 0]${RESET}  %-45s${GREEN}${BOLD}║${RESET}\n" \
        "← Back to OS selection"

    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"

    echo

    while true; do

        read -rp \
            "$(echo -e "  ${MAGENTA}🦜 Select version${RESET} ${GRAY}(0-$((i-1)))${RESET}: ${CYAN}${BOLD}➜${RESET} ")" \
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

            echo -e "  ${GREEN}${BOLD}✓${RESET} Version selected: ${WHITE}${BOLD}$SELECTED_VERSION${RESET}"
            sleep 0.5
            return 0
        fi

        echo -e "  ${RED}${BOLD}❌ Invalid selection. Please enter a number between 0 and $((i-1)).${RESET}"
    done
}

# ============================================================
# MAIN OS MENU
# ============================================================

while true; do

    echo

    echo -e "${BLUE}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}${BOLD}║${RESET}          🌍 ${WHITE}${BOLD}SELECT OPERATING SYSTEM${RESET}             ${BLUE}${BOLD}║${RESET}"
    echo -e "${BLUE}${BOLD}╠════════════════════════════════════════════════════╣${RESET}"

    i=1

    for distro in "${DISTROS[@]}"; do

        printf \
            "${BLUE}${BOLD}║${RESET}  ${CYAN}${BOLD}[%2d]${RESET}  %s  %-38s${BLUE}${BOLD}║${RESET}\n" \
            "$i" \
            "$(icon "$distro")" \
            "$(pretty_name "$distro")"

        i=$((i + 1))
    done

    echo -e "${BLUE}${BOLD}╠════════════════════════════════════════════════════╣${RESET}"
    printf \
        "${BLUE}${BOLD}║${RESET}  ${RED}${BOLD}[ 0]${RESET}  ❌ %-40s${BLUE}${BOLD}║${RESET}\n" \
        "Exit"

    echo -e "${BLUE}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"

    echo

    read -rp \
        "$(echo -e "  ${MAGENTA}🦜 Visible Tech${RESET} ${GRAY}(0-$((i-1)))${RESET}: ${CYAN}${BOLD}➜${RESET} ")" \
        choice

    if [ "$choice" = "0" ]; then

        echo
        echo -e "${YELLOW}${BOLD}👋 Reinstallation cancelled by user.${RESET}"
        echo -e "  ${GRAY}Thank you for using Visible Tech Reinstaller!${RESET}"
        echo -e "  ${GRAY}GitHub: https://github.com/wavy07/reinstallation${RESET}"
        echo
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "${#DISTROS[@]}" ]
    then

        echo -e "  ${RED}${BOLD}❌ Invalid selection. Please enter a number between 0 and $((i-1)).${RESET}"
        sleep 0.5
        continue
    fi

    DISTRO="${DISTROS[$((choice - 1))]}"
    echo -e "  ${GREEN}${BOLD}✓${RESET} OS selected: ${WHITE}${BOLD}$(pretty_name "$DISTRO")${RESET}"
    sleep 0.5

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
        echo -e "${YELLOW}${BOLD}💿 This option requires a disk image URL.${RESET}"
        echo -e "  ${GRAY}Examples:${RESET}"
        echo -e "    ${GRAY}• https://example.com/image.iso${RESET}"
        echo -e "    ${GRAY}• https://example.com/disk.img${RESET}"
        echo -e "    ${GRAY}• https://example.com/image.gz${RESET}"

        while true; do
            read -rp \
                "$(echo -e "  ${MAGENTA}🦜 Image URL${RESET}: ${CYAN}${BOLD}➜${RESET} ")" \
                IMAGE_URL

            if [ -z "$IMAGE_URL" ]; then
                echo -e "  ${RED}${BOLD}❌ Image URL cannot be empty.${RESET}"
                continue
            fi

            # Validate URL format
            if [[ $IMAGE_URL =~ ^https?:// ]]; then
                echo -e "  ${GREEN}${BOLD}✓${RESET} Image URL set: ${WHITE}${BOLD}$(echo "$IMAGE_URL" | cut -c1-50)...${RESET}"
                sleep 0.5
                break
            else
                echo -e "  ${RED}${BOLD}❌ Invalid URL format. URL must start with http:// or https://${RESET}"
            fi
        done

        EXTRA_ARGS+=(--img="$IMAGE_URL")
        ;;

    windows)

        echo
        echo -e "${YELLOW}${BOLD}🪟 Windows Installation${RESET}"
        echo -e "  ${GRAY}Provide a Windows ISO or image URL${RESET}"
        echo -e "  ${GRAY}Examples:${RESET}"
        echo -e "    ${GRAY}• https://example.com/windows-10.iso${RESET}"
        echo -e "    ${GRAY}• https://example.com/windows-server.iso${RESET}"

        while true; do
            read -rp \
                "$(echo -e "  ${MAGENTA}🦜 Image/ISO URL${RESET}: ${CYAN}${BOLD}➜${RESET} ")" \
                IMAGE_URL

            if [ -z "$IMAGE_URL" ]; then
                echo -e "  ${RED}${BOLD}❌ Image URL cannot be empty.${RESET}"
                continue
            fi

            # Validate URL format
            if [[ $IMAGE_URL =~ ^https?:// ]]; then
                echo -e "  ${GREEN}${BOLD}✓${RESET} Image URL set: ${WHITE}${BOLD}$(echo "$IMAGE_URL" | cut -c1-50)...${RESET}"
                sleep 0.5
                break
            else
                echo -e "  ${RED}${BOLD}❌ Invalid URL format. URL must start with http:// or https://${RESET}"
            fi
        done

        EXTRA_ARGS+=(--img="$IMAGE_URL")
        ;;

esac

# ============================================================
# SUMMARY
# ============================================================

echo

echo -e "${MAGENTA}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
sleep 0.1
echo -e "${MAGENTA}${BOLD}║${RESET}              📋 ${WHITE}${BOLD}INSTALLATION SUMMARY${RESET}             ${MAGENTA}${BOLD}║${RESET}"
sleep 0.1
echo -e "${MAGENTA}${BOLD}╠════════════════════════════════════════════════════╣${RESET}"
sleep 0.1

printf \
    "${MAGENTA}${BOLD}║${RESET}  🦜 Brand${RESET}    : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
    "${CYAN}${BOLD}Visible Tech${RESET}"

sleep 0.1

printf \
    "${MAGENTA}${BOLD}║${RESET}  🌍 OS${RESET}       : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
    "${WHITE}${BOLD}$(pretty_name "$DISTRO")${RESET}"

sleep 0.1

if [ -n "${SELECTED_VERSION:-}" ]; then

    printf \
        "${MAGENTA}${BOLD}║${RESET}  📦 Version${RESET}  : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
        "${WHITE}${BOLD}$SELECTED_VERSION${RESET}"

    sleep 0.1

fi

printf \
    "${MAGENTA}${BOLD}║${RESET}  ⚙️  Engine${RESET}   : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
    "${CYAN}bin456789/reinstall${RESET}"

sleep 0.1

printf \
    "${MAGENTA}${BOLD}║${RESET}  👤 Author${RESET}   : %-34s ${MAGENTA}${BOLD}║${RESET}\n" \
    "${CYAN}wavy07${RESET}"

sleep 0.1
echo -e "${MAGENTA}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"

echo

echo -e "${RED}${BOLD}⚠️  ${UNDERLINE}WARNING - READ CAREFULLY${UNDERLINE}${RESET}"
echo -e "${RED}   This operation will ${BOLD}ERASE${RESET}${RED} the VPS system disk.${RESET}"
echo -e "${RED}   ${BOLD}→${RESET} Existing data may be ${BOLD}PERMANENTLY LOST${RESET}${RED}.${RESET}"
echo -e "${RED}   → This action ${BOLD}CANNOT${RESET}${RED} be undone.${RESET}"
echo -e "${RED}   → Make ${BOLD}BACKUPS${RESET}${RED} before proceeding.${RESET}"

echo

read -rp \
    "$(echo -e "  ${YELLOW}${BOLD}⚡ Start reinstallation?${RESET} ${GRAY}(type 'yes' to confirm)${RESET}: ${CYAN}${BOLD}➜${RESET} ")" \
    confirm

echo

case "$confirm" in

    yes|YES|Yes)
        echo -e "  ${GREEN}${BOLD}✓${RESET} Confirmed by user. Proceeding with reinstallation..."
        sleep 1.5
        ;;

    *)
        echo -e "  ${YELLOW}${BOLD}👋 Reinstallation cancelled.${RESET}"
        echo -e "  ${GRAY}No changes were made to your system.${RESET}"
        echo
        exit 0
        ;;

esac

# ============================================================
# START REAL REINSTALLER
# ============================================================

echo

echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║${RESET}     🚀 ${MAGENTA}${BOLD}STARTING REINSTALLATION${RESET}               ${CYAN}${BOLD}║${RESET}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════╝${RESET}"

sleep 0.5

echo

echo -e "  ${GREEN}${BOLD}✓${RESET} OS       ${GRAY}:${RESET} ${WHITE}${BOLD}$(pretty_name "$DISTRO")${RESET}"

if [ -n "${SELECTED_VERSION:-}" ]; then
    echo -e "  ${GREEN}${BOLD}✓${RESET} Version  ${GRAY}:${RESET} ${WHITE}${BOLD}$SELECTED_VERSION${RESET}"
fi

echo -e "  ${GREEN}${BOLD}✓${RESET} Engine   ${GRAY}:${RESET} ${WHITE}${BOLD}bin456789/reinstall${RESET}"
echo -e "  ${GREEN}${BOLD}✓${RESET} Brand    ${GRAY}:${RESET} ${WHITE}${BOLD}Visible Tech 🦜${RESET}"
echo -e "  ${GREEN}${BOLD}✓${RESET} Author   ${GRAY}:${RESET} ${WHITE}${BOLD}wavy07${RESET}"

echo

sleep 1

echo -e "${YELLOW}${BOLD}→${RESET} Handing over control to ${CYAN}bin456789/reinstall${RESET} engine..."
echo -e "${YELLOW}${BOLD}→${RESET} System will begin reinstallation process..."

sleep 2

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
