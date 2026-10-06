#!/usr/bin/env bash

# =============================================================================
# 🦜 VISIBLE TECH REINSTALLER
# Frontend for: bin456789/reinstall
#
# Repository:
# https://github.com/wavy07/reinstallation
#
# Run:
#   curl -fsSL https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh | sudo bash
#
# Or:
#   sudo bash reinstall.sh
#
# ⚠️ WARNING:
# This program can completely erase the VPS/system disk.
# =============================================================================

set -u
set -o pipefail

export LANG=C
export LC_ALL=C

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

REPO_USER="wavy07"
REPO_NAME="reinstallation"

ENGINE_OVERRIDE="${REINSTALL_ENGINE:-}"

# Current upstream mirrors
declare -a ENGINE_URLS=(
    "https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    "https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh"
    "https://cdn.jsdelivr.net/gh/bin456789/reinstall@main/reinstall.sh"
)

TMP="/reinstall-tmp-visible-tech-$$"
SPIN_PID=""

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RST=$'\033[0m'
    BOLD=$'\033[1m'
    DIM=$'\033[2m'

    RED=$'\033[91m'
    GREEN=$'\033[92m'
    YELLOW=$'\033[93m'
    BLUE=$'\033[94m'
    MAG=$'\033[95m'
    CYAN=$'\033[96m'
    WHITE=$'\033[97m'
    GREY=$'\033[90m'
else
    RST=""
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAG=""
    CYAN=""
    WHITE=""
    GREY=""
fi

# -----------------------------------------------------------------------------
# Terminal layout
# -----------------------------------------------------------------------------

BOX_W=58

if command -v tput >/dev/null 2>&1; then
    _tw="$(tput cols 2>/dev/null || true)"

    if [ -n "${_tw:-}" ] &&
       [[ "${_tw}" =~ ^[0-9]+$ ]] &&
       [ "$_tw" -gt 0 ] &&
       [ "$_tw" -lt 72 ]; then

        BOX_W=$(( _tw - 6 ))
    fi
fi

[ "$BOX_W" -lt 32 ] && BOX_W=32

rep() {
    local c="$1"
    local n="$2"
    local o=""
    local i

    for ((i=0; i<n; i++)); do
        o+="$c"
    done

    printf '%s' "$o"
}

box_top() {
    printf '%s╔%s╗%s\n' \
        "$MAG" "$(rep '═' "$BOX_W")" "$RST"
}

box_mid() {
    printf '%s╠%s╣%s\n' \
        "$MAG" "$(rep '═' "$BOX_W")" "$RST"
}

box_bot() {
    printf '%s╚%s╝%s\n' \
        "$MAG" "$(rep '═' "$BOX_W")" "$RST"
}

box_row() {
    local text="$1"

    printf '%s║%s  %-*s %s║%s\n' \
        "$MAG" \
        "$WHITE" \
        "$((BOX_W-4))" \
        "$text" \
        "$MAG" \
        "$RST"
}

# -----------------------------------------------------------------------------
# Spinner
# -----------------------------------------------------------------------------

_spinner_loop() {
    local message="$1"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0

    while :; do
        printf '\r  %s%s%s %s%s%s' \
            "$CYAN" \
            "${frames[$i]}" \
            "$RST" \
            "$DIM" \
            "$message" \
            "$RST"

        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.07
    done
}

spin_start() {
    spin_stop silent 2>/dev/null || true

    _spinner_loop "$1" &
    SPIN_PID=$!
}

spin_stop() {
    local result="${1:-ok}"

    if [ -n "${SPIN_PID:-}" ]; then
        kill "$SPIN_PID" 2>/dev/null || true
        wait "$SPIN_PID" 2>/dev/null || true
        SPIN_PID=""
    fi

    printf '\r%s\r' "$(rep ' ' "$((BOX_W+20))")"

    case "$result" in
        ok)
            printf '  %s✔%s %sDone.%s\n' \
                "$GREEN" "$RST" "$DIM" "$RST"
            ;;

        fail)
            printf '  %s✖%s %sFailed.%s\n' \
                "$RED" "$RST" "$DIM" "$RST"
            ;;

        silent)
            ;;

        *)
            printf '\r'
            ;;
    esac
}

kill_spinner() {
    if [ -n "${SPIN_PID:-}" ]; then
        kill "$SPIN_PID" 2>/dev/null || true
        wait "$SPIN_PID" 2>/dev/null || true
        SPIN_PID=""
    fi
}

# -----------------------------------------------------------------------------
# Animation
# -----------------------------------------------------------------------------

progress_bar() {
    local pct="$1"
    local label="${2:-}"
    local width=28
    local filled
    local empty
    local bar

    filled=$(( width * pct / 100 ))
    empty=$(( width - filled ))

    bar="$(rep '█' "$filled")$(rep '░' "$empty")"

    printf '\r  %s│%s%s%s│%s %3d%%  %s%s%s' \
        "$CYAN" \
        "$GREEN" \
        "$bar" \
        "$CYAN" \
        "$RST" \
        "$pct" \
        "$DIM" \
        "$label" \
        "$RST"

    if [ "$pct" -ge 100 ]; then
        printf '\n'
    fi
}

type_text() {
    local text="$1"
    local delay="${2:-0.006}"
    local i

    if [ ! -t 1 ]; then
        printf '%s\n' "$text"
        return
    fi

    for ((i=0; i<${#text}; i++)); do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
    done

    printf '\n'
}

rainbow() {
    local text="$1"
    local i

    local -a colors=(91 93 92 96 94 95)

    for ((i=0; i<${#text}; i++)); do
        printf '\033[1;%sm%s' \
            "${colors[$((i % ${#colors[@]}))]}" \
            "${text:$i:1}"
    done

    printf '%s' "$RST"
}

# -----------------------------------------------------------------------------
# Interactive terminal
# -----------------------------------------------------------------------------

# When used like:
#
# curl ... | sudo bash
#
# stdin belongs to curl. We need /dev/tty for menu input.

if [ ! -t 0 ]; then
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        exec < /dev/tty
    else
        echo
        echo -e "  ${RED}✖ No interactive terminal available.${RST}"
        echo
        echo -e "  ${YELLOW}Run the downloaded file directly instead:${RST}"
        echo
        echo -e "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/reinstall.sh -o vt-reinstall.sh${RST}"
        echo -e "  ${CYAN}sudo bash vt-reinstall.sh${RST}"
        echo
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

cleanup() {
    kill_spinner
    rm -rf "$TMP" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# -----------------------------------------------------------------------------
# Root check
# -----------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "  ${RED}✖ Root privileges are required.${RST}"
    echo
    echo -e "  ${CYAN}sudo bash $0${RST}"
    echo
    exit 1
fi

# -----------------------------------------------------------------------------
# Required commands
# -----------------------------------------------------------------------------

missing=()

for cmd in bash curl sed awk grep head wc cut hostname uname id; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done

if [ "${#missing[@]}" -gt 0 ]; then
    echo
    echo -e "  ${RED}✖ Required commands are missing:${RST}"
    echo -e "    ${YELLOW}${missing[*]}${RST}"
    echo
    echo -e "  ${DIM}Install them first with:${RST}"
    echo -e "  ${CYAN}apt-get update && apt-get install -y bash curl sed gawk grep coreutils${RST}"
    echo
    exit 1
fi

# -----------------------------------------------------------------------------
# Banner
# -----------------------------------------------------------------------------

clear 2>/dev/null || true

if [ "$BOX_W" -ge 50 ]; then

cat <<'EOF'
██╗   ██╗██╗███████╗██╗██████╗ ██╗     ███████╗
██║   ██║██║██╔════╝██║██╔══██╗██║     ██╔════╝
██║   ██║██║███████╗██║██████╔╝██║     █████╗
╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║     ██╔══╝
 ╚████╔╝ ██║███████║██║██████╔╝███████╗███████╗
  ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝
EOF

else

printf '%s\n' "  ██╗   ██╗██╗███████╗██╗██████╗ ██╗     ███████╗"
printf '%s\n' "  ╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║     ██╔════╝"
printf '%s\n' "   ╚████╔╝ ██║███████║██║██████╔╝███████╗███████╗"
printf '%s\n' "    ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝"

fi

echo
printf '      '
rainbow "V I S I B L E   T E C H   R E I N S T A L L E R"
echo

echo -e "      ${DIM}Ubuntu / Debian / Multi-Distro VPS OS Installer${RST}"
echo

type_text "  ${CYAN}⚡ Initialising deployment shell ...${RST}"

echo
echo -e "  ${GREY}────────────────────────────────────────────────────${RST}"

echo -e "  ${DIM}Host${RST}   : ${WHITE}$(hostname 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Kernel${RST} : ${WHITE}$(uname -r 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Arch${RST}   : ${WHITE}$(uname -m 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Engine${RST} : ${WHITE}bin456789/reinstall${RST}"

echo -e "  ${GREY}────────────────────────────────────────────────────${RST}"

# -----------------------------------------------------------------------------
# Download upstream engine
# -----------------------------------------------------------------------------

ENGINE_URL=""

fetch_engine() {

    local -a urls=()
    local url

    if [ -n "$ENGINE_OVERRIDE" ]; then
        urls=("$ENGINE_OVERRIDE")
    else
        urls=("${ENGINE_URLS[@]}")
    fi

    for url in "${urls[@]}"; do

        rm -f "$TMP" 2>/dev/null || true

        echo
        echo -e "  ${DIM}Mirror:${RST} ${CYAN}${url}${RST}"

        spin_start "Downloading reinstall engine ..."

        if curl \
            -fsSL \
            --connect-timeout 12 \
            --max-time 120 \
            --retry 2 \
            --retry-delay 1 \
            "$url" \
            -o "$TMP" >/dev/null 2>&1
        then
            spin_stop ok
            ENGINE_URL="$url"
            return 0
        fi

        spin_stop fail
    done

    return 1
}

echo

if ! fetch_engine; then

    echo
    echo -e "  ${RED}✖ Unable to download the reinstall engine.${RST}"
    echo
    echo -e "  ${YELLOW}Possible causes:${RST}"
    echo -e "    • DNS is not working"
    echo -e "    • GitHub is blocked"
    echo -e "    • CNB is unreachable"
    echo -e "    • VPS has no Internet access"
    echo
    echo -e "  ${DIM}You can specify another engine manually:${RST}"
    echo -e "  ${CYAN}REINSTALL_ENGINE=\"https://example.com/reinstall.sh\" bash $0${RST}"
    echo
    exit 1
fi

# -----------------------------------------------------------------------------
# Validate downloaded engine
# -----------------------------------------------------------------------------

if [ ! -s "$TMP" ]; then
    echo
    echo -e "  ${RED}✖ Downloaded engine is empty.${RST}"
    exit 1
fi

FIRST_LINE="$(head -n 1 "$TMP" 2>/dev/null || true)"

case "$FIRST_LINE" in
    '#!'*)
        ;;
    *)
        echo
        echo -e "  ${RED}✖ Downloaded file is not a valid shell script.${RST}"
        echo -e "  ${DIM}First line:${RST} ${WHITE}${FIRST_LINE:0:100}${RST}"
        echo
        exit 1
        ;;
esac

ENGINE_SIZE="$(wc -c < "$TMP" 2>/dev/null || echo 0)"

if ! [[ "$ENGINE_SIZE" =~ ^[0-9]+$ ]] || [ "$ENGINE_SIZE" -lt 10000 ]; then
    echo
    echo -e "  ${RED}✖ Downloaded engine appears incomplete.${RST}"
    echo -e "  ${DIM}Size:${RST} ${ENGINE_SIZE} bytes"
    echo
    exit 1
fi

chmod +x "$TMP"

# -----------------------------------------------------------------------------
# Supported OS table
#
# Based on the current upstream usage list.
# -----------------------------------------------------------------------------

declare -a DISTROS=()
declare -A SPECS=()

add_distro() {

    local distro="$1"
    local versions="$2"

    printf '%s' "$distro" |
        grep -Eq '^[a-zA-Z0-9._-]+$' || return 1

    case "$distro" in

        anolis|opencloudos|rocky|oracle|almalinux|centos|fnos|fygoos|\
        nixos|fedora|debian|opensuse|alpine|kali|openeuler|ubuntu|arch|\
        gentoo|aosc|redhat|dd|windows|netboot.xyz|reset)
            ;;

        *)
            return 1
            ;;
    esac

    if [ -z "${SPECS[$distro]+x}" ]; then
        DISTROS+=("$distro")
    fi

    SPECS["$distro"]="$versions"
}

# Current upstream list
BUILTIN='
anolis              [7|8|23]
opencloudos         [8|9|23]
rocky               [8|9|10]
oracle              [8|9|10]
almalinux           [8|9|10]
centos              [9|10]
fnos                [1]
fygoos              [1]
nixos               [26.05]
fedora              [43|44]
debian              [9|10|11|12|13]
opensuse            [16.0|tumbleweed]
openeuler           [20.03|22.03|24.03]
alpine              [3.21|3.22|3.23|3.24]
kali                [last-snapshot|rolling]
ubuntu              [18.04|20.04|22.04|24.04|26.04]
arch                [latest]
gentoo              [latest]
aosc                [latest]
redhat              []
dd                  []
windows             []
netboot.xyz         []
reset               []
'

while IFS= read -r line; do

    line="$(printf '%s\n' "$line" |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    [ -z "$line" ] && continue

    distro="$(printf '%s\n' "$line" | awk '{print $1}')"
    versions="$(printf '%s\n' "$line" | cut -d' ' -f2-)"

    add_distro "$distro" "$versions"

done <<< "$BUILTIN"

# -----------------------------------------------------------------------------
# Try to discover additional upstream distro names
# -----------------------------------------------------------------------------

usage="$(sed -n \
    '/^usage_and_exit()/,/^}/p' \
    "$TMP" 2>/dev/null |
    sed -n '/cat <<EOF/,/^EOF/p' |
    sed '1d;$d' || true)"

if [ -n "$usage" ]; then

    while IFS= read -r line; do

        line="$(printf '%s\n' "$line" |
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        [ -z "$line" ] && continue

        case "$line" in
            Usage:*|Options:*|Manual:*|For\ *|Distro*|http://*|https://*)
                continue
                ;;
        esac

        distro="$(printf '%s\n' "$line" | awk '{print $1}')"
        versions="$(printf '%s\n' "$line" | cut -d' ' -f2-)"

        if [ -z "${SPECS[$distro]+x}" ]; then
            add_distro "$distro" "$versions"
        fi

    done <<< "$usage"

fi

if [ "${#DISTROS[@]}" -eq 0 ]; then
    echo
    echo -e "  ${RED}✖ No supported operating systems detected.${RST}"
    echo
    exit 1
fi

# -----------------------------------------------------------------------------
# Pretty names
# -----------------------------------------------------------------------------

pretty_name() {

    case "$1" in

        anolis)      echo "Anolis OS" ;;
        opencloudos) echo "OpenCloudOS" ;;
        rocky)       echo "Rocky Linux" ;;
        oracle)      echo "Oracle Linux" ;;
        almalinux)   echo "AlmaLinux" ;;
        centos)      echo "CentOS" ;;
        fnos)        echo "fnOS" ;;
        fygoos)      echo "FydeOS" ;;
        nixos)       echo "NixOS" ;;
        fedora)      echo "Fedora" ;;
        debian)      echo "Debian" ;;
        opensuse)    echo "openSUSE" ;;
        alpine)      echo "Alpine Linux" ;;
        kali)        echo "Kali Linux" ;;
        openeuler)   echo "openEuler" ;;
        ubuntu)      echo "Ubuntu" ;;
        arch)        echo "Arch Linux" ;;
        gentoo)      echo "Gentoo" ;;
        aosc)        echo "AOSC OS" ;;
        redhat)      echo "Red Hat Enterprise Linux" ;;
        dd)          echo "DD / Disk Image" ;;
        windows)     echo "Windows" ;;
        netboot.xyz) echo "netboot.xyz" ;;
        reset)       echo "Reset / Recovery" ;;
        *)           echo "$1" ;;

    esac
}

# -----------------------------------------------------------------------------
# Icons
# -----------------------------------------------------------------------------

icon() {

    case "$1" in

        ubuntu)      echo "🟠" ;;
        debian)      echo "🔴" ;;
        fedora)      echo "🔵" ;;
        rocky)       echo "🟢" ;;
        oracle)      echo "🟣" ;;
        almalinux)   echo "🟢" ;;
        centos)      echo "🟡" ;;
        anolis)      echo "🟠" ;;
        opencloudos) echo "🟡" ;;
        openeuler)   echo "🟢" ;;
        alpine)      echo "🔷" ;;
        kali)        echo "💀" ;;
        opensuse)    echo "🦎" ;;
        arch)        echo "🔷" ;;
        gentoo)      echo "🟣" ;;
        aosc)        echo "🟣" ;;
        nixos)       echo "❄️" ;;
        redhat)      echo "🔴" ;;
        fnos)        echo "💻" ;;
        fygoos)      echo "💻" ;;
        dd)          echo "💿" ;;
        windows)     echo "🪟" ;;
        netboot.xyz) echo "🌐" ;;
        reset)       echo "♻️" ;;
        *)           echo "💻" ;;

    esac
}

# -----------------------------------------------------------------------------
# Version selector
# -----------------------------------------------------------------------------

SELECTED_VERSION=""

select_version() {

    local distro="$1"
    local spec="${SPECS[$distro]:-}"

    local -a versions=()

    local choice
    local version
    local i

    SELECTED_VERSION=""

    [ -z "$spec" ] && return 0

    spec="$(printf '%s' "$spec" |
        sed 's/^\[//;s/\]$//')"

    if [ -z "$spec" ]; then
        return 0
    fi

    IFS='|' read -ra versions <<< "$spec"

    if [ "${#versions[@]}" -eq 0 ]; then
        return 0
    fi

    # Only one version
    if [ "${#versions[@]}" -eq 1 ]; then

        SELECTED_VERSION="$(
            printf '%s' "${versions[0]}" | xargs
        )"

        return 0
    fi

    echo

    box_top

    printf '%s║%s   %s %s%-*s%s║%s\n' \
        "$GREEN" \
        "$GREEN" \
        "$(icon "$distro")" \
        "$BOLD" \
        "$((BOX_W-7))" \
        "$(pretty_name "$distro")" \
        "$GREEN" \
        "$RST"

    box_mid

    i=1

    for version in "${versions[@]}"; do

        version="$(printf '%s' "$version" | xargs)"

        [ -z "$version" ] && continue

        printf '%s║%s   %s%2d%s    %-*s%s║%s\n' \
            "$GREEN" \
            "$GREEN" \
            "$CYAN" \
            "$i" \
            "$RST" \
            "$((BOX_W-9))" \
            "$version" \
            "$GREEN" \
            "$RST"

        i=$((i + 1))
    done

    printf '%s║%s   %s%2d%s    %-*s%s║%s\n' \
        "$GREEN" \
        "$GREEN" \
        "$RED" \
        0 \
        "$RST" \
        "$((BOX_W-9))" \
        "← Back" \
        "$GREEN" \
        "$RST"

    box_bot

    echo

    while true; do

        read -r -p \
            "  ${CYAN}➜${RST} Select version: " \
            choice

        if [ "$choice" = "0" ]; then
            return 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
           [ "$choice" -ge 1 ] &&
           [ "$choice" -le "${#versions[@]}" ]; then

            SELECTED_VERSION="$(
                printf '%s' \
                    "${versions[$((choice-1))]}" |
                    xargs
            )"

            return 0
        fi

        printf '\r  %s✖ Invalid selection — try again.%s\n' \
            "$RED" "$RST"
    done
}

# -----------------------------------------------------------------------------
# Detect current OS
# -----------------------------------------------------------------------------

DISTRO="${1:-}"
HOST_ID=""

if [ -r /etc/os-release ]; then

    # shellcheck disable=SC1091
    . /etc/os-release 2>/dev/null || true

    HOST_ID="${ID:-}"

fi

# -----------------------------------------------------------------------------
# Main OS menu
# -----------------------------------------------------------------------------

if [ -z "$DISTRO" ] && [ -n "$HOST_ID" ]; then

    for distro in "${DISTROS[@]}"; do

        if [ "$distro" = "$HOST_ID" ]; then
            DISTRO="$distro"
            break
        fi

    done

fi

while [ -z "$DISTRO" ]; do

    echo

    printf '%s╔%s╗%s\n' \
        "$BLUE" \
        "$(rep '═' "$BOX_W")" \
        "$RST"

    printf '%s║%s      %s%s🌍 SELECT OPERATING SYSTEM%s%*s%s║%s\n' \
        "$BLUE" \
        "$BLUE" \
        "$BOLD" \
        "$WHITE" \
        "$RST" \
        "$((BOX_W-33))" \
        "" \
        "$BLUE" \
        "$RST"

    printf '%s╠%s╣%s\n' \
        "$BLUE" \
        "$(rep '═' "$BOX_W")" \
        "$RST"

    i=1

    for distro in "${DISTROS[@]}"; do

        printf '%s║%s   %s%2d%s   %s %s%-*s%s║%s\n' \
            "$BLUE" \
            "$BLUE" \
            "$CYAN" \
            "$i" \
            "$RST" \
            "$(icon "$distro")" \
            "$WHITE" \
            "$((BOX_W-9))" \
            "$(pretty_name "$distro")" \
            "$BLUE" \
            "$RST"

        i=$((i + 1))

    done

    printf '%s║%s   %s%2d%s   %s %s%-*s%s║%s\n' \
        "$BLUE" \
        "$BLUE" \
        "$RED" \
        0 \
        "$RST" \
        "❌" \
        "$RED" \
        "$((BOX_W-9))" \
        "Exit" \
        "$BLUE" \
        "$RST"

    printf '%s╚%s╝%s\n' \
        "$BLUE" \
        "$(rep '═' "$BOX_W")" \
        "$RST"

    echo

    read -r -p \
        "  ${CYAN}🦜 Visible Tech ${DIM}➜${RST} Select OS: " \
        choice

    if [ "$choice" = "0" ]; then

        echo
        echo -e "  ${YELLOW}👋 Reinstallation cancelled — nothing was changed.${RST}"
        echo
        exit 0

    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "${#DISTROS[@]}" ]; then

        printf '\r  %s✖ Enter a number between 1 and %s.%s\n' \
            "$RED" \
            "${#DISTROS[@]}" \
            "$RST"

        sleep 0.6
        continue
    fi

    DISTRO="${DISTROS[$((choice-1))]}"

    if ! select_version "$DISTRO"; then
        DISTRO=""
    fi

done

# -----------------------------------------------------------------------------
# Special options
# -----------------------------------------------------------------------------

EXTRA_ARGS=()
IMAGE_URL=""

case "$DISTRO" in

    redhat|dd)

        echo
        echo -e "  ${YELLOW}💿 Disk image installation${RST}"
        echo

        read -r -p \
            "  ${CYAN}➜${RST} Image URL: " \
            IMAGE_URL

        if [ -z "$IMAGE_URL" ]; then
            echo
            echo -e "  ${RED}✖ Image URL is required.${RST}"
            echo
            exit 1
        fi

        EXTRA_ARGS+=(
            "--img=$IMAGE_URL"
        )

        ;;

    windows)

        echo
        echo -e "  ${YELLOW}🪟 Windows installation${RST}"
        echo

        echo -e "  ${DIM}Choose how to install Windows:${RST}"
        echo
        echo -e "  ${CYAN}1${RST}) ISO URL"
        echo -e "  ${CYAN}2${RST}) Existing upstream image name"
        echo -e "  ${CYAN}0${RST}) Back"
        echo

        while true; do

            read -r -p \
                "  ${CYAN}➜${RST} Select method: " \
                win_method

            case "$win_method" in

                1)

                    read -r -p \
                        "  ${CYAN}➜${RST} ISO URL: " \
                        IMAGE_URL

                    if [ -z "$IMAGE_URL" ]; then
                        echo -e "  ${RED}✖ ISO URL is required.${RST}"
                        continue
                    fi

                    EXTRA_ARGS+=(
                        "--iso"
                        "$IMAGE_URL"
                    )

                    break
                    ;;

                2)

                    read -r -p \
                        "  ${CYAN}➜${RST} Windows image name: " \
                        WIN_IMAGE_NAME

                    if [ -z "$WIN_IMAGE_NAME" ]; then
                        echo -e "  ${RED}✖ Image name is required.${RST}"
                        continue
                    fi

                    EXTRA_ARGS+=(
                        "--image-name"
                        "$WIN_IMAGE_NAME"
                    )

                    break
                    ;;

                0)

                    echo
                    echo -e "  ${YELLOW}👋 Installation cancelled.${RST}"
                    echo
                    exit 0
                    ;;

                *)

                    echo -e "  ${RED}✖ Invalid selection.${RST}"
                    ;;

            esac

        done

        ;;

esac

# -----------------------------------------------------------------------------
# Installation summary
# -----------------------------------------------------------------------------

echo

box_top

printf '%s║%s        %s📋 INSTALLATION SUMMARY%s%*s%s║%s\n' \
    "$MAG" \
    "$MAG" \
    "$BOLD" \
    "$RST" \
    "$((BOX_W-29))" \
    "" \
    "$MAG" \
    "$RST"

box_mid

box_row "🦜 Brand    : Visible Tech"
box_row "🌍 OS       : $(pretty_name "$DISTRO")"

if [ -n "${SELECTED_VERSION:-}" ]; then
    box_row "📦 Version  : $SELECTED_VERSION"
fi

if [ -n "${IMAGE_URL:-}" ]; then
    box_row "💿 Image    : $IMAGE_URL"
fi

box_row "⚙️  Engine   : bin456789/reinstall"

box_bot

echo

# -----------------------------------------------------------------------------
# Dangerous operation confirmation
# -----------------------------------------------------------------------------

echo -e "  ${RED}${BOLD}⚠️  WARNING${RST}"
echo -e "  ${RED}   This operation can erase the VPS system disk.${RST}"
echo -e "  ${RED}   Existing data may be permanently lost.${RST}"
echo

read -r -p \
    "  ${YELLOW}⚡ Start reinstallation? ${BOLD}[y/N]${RST} " \
    confirm

case "$confirm" in

    y|Y|yes|YES|Yes)
        ;;

    *)
        echo
        echo -e "  ${YELLOW}👋 Reinstallation cancelled.${RST}"
        echo
        exit 0
        ;;

esac

# -----------------------------------------------------------------------------
# Launch animation
# -----------------------------------------------------------------------------

echo

type_text \
    "  ${CYAN}${BOLD}🚀 Launching reinstallation engine ...${RST}"

echo

p=0

while [ "$p" -le 100 ]; do

    progress_bar \
        "$p" \
        "preparing installation environment"

    sleep 0.025

    p=$((p + 5))

done

echo

# -----------------------------------------------------------------------------
# Build upstream command
# -----------------------------------------------------------------------------

CMD=(
    bash
    "$TMP"
    "$DISTRO"
)

if [ -n "${SELECTED_VERSION:-}" ]; then
    CMD+=(
        "$SELECTED_VERSION"
    )
fi

if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    CMD+=(
        "${EXTRA_ARGS[@]}"
    )
fi

# -----------------------------------------------------------------------------
# Final handoff
# -----------------------------------------------------------------------------

echo -e "  ${GREEN}✔ Visible Tech configuration complete.${RST}"
echo -e "  ${DIM}Handing control to the upstream reinstall engine...${RST}"
echo

sleep 1

exec "${CMD[@]}"
