
## Drop‑in version for your repo

Pointed at **`wavy07/reinstallation` → `reinstall.sh`**, with automatic branch detection (`main` → `master` → jsDelivr mirror), an env override, and a built‑in distro table so the menu still works even if the upstream usage text changes.

```bash
#!/usr/bin/env bash
# =============================================================================
#        🦜  VISIBLE TECH REINSTALLER
#        Animated frontend for wavy07/reinstallation (bin456789/reinstall)
#
#        Install on any VPS:
#          curl -fsSL https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh | sudo bash
# =============================================================================

set -u

# ---------------------------------------------------------------------------
# SOURCE CONFIG  (override with: REINSTALL_UPSTREAM=... sudo bash reinstall.sh)
# ---------------------------------------------------------------------------

GITHUB_USER="wavy07"
GITHUB_REPO="reinstallation"
GITHUB_FILE="reinstall.sh"

UPSTREAM="${REINSTALL_UPSTREAM:-}"
UPSTREAM_URL=""

TMP="/tmp/.visible-tech-reinstall.$$"

# ---------------------------------------------------------------------------
# COLOURS
# ---------------------------------------------------------------------------

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
    RST=""; BOLD=""; DIM=""; RED=""
    GREEN=""; YELLOW=""; BLUE=""; MAG=""; CYAN=""; WHITE=""; GREY=""
fi

# ---------------------------------------------------------------------------
# LAYOUT
# ---------------------------------------------------------------------------

BOX_W=54

_tput_w="$(tput cols 2>/dev/null || true)"
if [ -n "${_tput_w:-}" ] && [[ "${_tput_w}" =~ ^[0-9]+$ ]] && [ "$_tput_w" -gt 0 ]; then
    if [ "$_tput_w" -lt 66 ]; then
        BOX_W=$(( _tput_w - 6 ))
    fi
fi
[ "$BOX_W" -lt 30 ] && BOX_W=30

rep() {
    local ch="$1" n="$2" out="" i
    for ((i = 0; i < n; i++)); do out+="$ch"; done
    printf '%s' "$out"
}

box_top() { printf '%s╔%s╗%s\n' "$MAG" "$(rep '═' "$BOX_W")" "$RST"; }
box_mid() { printf '%s╠%s╣%s\n' "$MAG" "$(rep '═' "$BOX_W")" "$RST"; }
box_bot() { printf '%s╚%s╝%s\n' "$MAG" "$(rep '═' "$BOX_W")" "$RST"; }

box_row() {
    local txt="$1"
    printf '%s║%s  %-*s %s║%s\n' \
        "$MAG" "$WHITE" "$((BOX_W - 4))" "$txt" "$MAG" "$RST"
}

# ---------------------------------------------------------------------------
# SPINNER / PROGRESS / TYPEWRITER / RAINBOW
# ---------------------------------------------------------------------------

SPIN_PID=""
SPIN_DONE=0
SPIN_MSG=""

_spinner_loop() {
    local frames=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    while [ "$SPIN_DONE" -eq 0 ]; do
        printf '\r  %s%s%s %s%s%s' "$CYAN" "${frames[$i]}" "$RST" "$DIM" "$SPIN_MSG" "$RST"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.07
    done
}

spin_start() {
    SPIN_MSG="$1"
    SPIN_DONE=0
    _spinner_loop &
    SPIN_PID=$!
}

spin_stop() {
    local ok="${1:-ok}"
    SPIN_DONE=1
    [ -n "${SPIN_PID:-}" ] && wait "$SPIN_PID" 2>/dev/null
    SPIN_PID=""
    printf '\r%s' "$(rep ' ' $(( BOX_W + 14 )))"
    if [ "$ok" = "ok" ]; then
        printf '\r  %s✔%s %sDone.%s\n' "$GREEN" "$RST" "$DIM" "$RST"
    elif [ "$ok" = "fail" ]; then
        printf '\r  %s✖%s %sFailed.%s\n' "$RED" "$RST" "$DIM" "$RST"
    else
        printf '\r'
    fi
}

progress_bar() {
    local pct="$1" label="${2:-}" w=28 filled empty bar
    filled=$(( w * pct / 100 ))
    empty=$(( w - filled ))
    bar="$(rep '█' "$filled")$(rep '░' "$empty")"
    printf '\r  %s│%s%s%s│%s %3d%%  %s%s%s' \
        "$CYAN" "$GREEN" "$bar" "$CYAN" "$RST" "$pct" "$DIM" "$label" "$RST"
    if [ "$pct" -ge 100 ]; then printf '\n'; fi
}

type_text() {
    local text="$1" delay="${2:-0.010}" i
    if [ ! -t 1 ]; then printf '%s\n' "$text"; return; fi
    for ((i = 0; i < ${#text}; i++)); do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
    done
    printf '\n'
}

rainbow() {
    local text="$1" i
    local -a pal=( 91 93 92 96 94 95 )
    for ((i = 0; i < ${#text}; i++)); do
        printf '\033[1;%sm%s' "${pal[$(( i % ${#pal[@]} ))]}" "${text:$i:1}"
    done
    printf '%s' "$RST"
}

# ---------------------------------------------------------------------------
# INTERACTIVE STDIN  <-- FIXES THE ENDLESS MENU LOOP
# ---------------------------------------------------------------------------

if [ -t 0 ]; then
    :
elif [ -r /dev/tty ] && [ -w /dev/tty ]; then
    exec < /dev/tty
else
    echo
    echo -e "  ${RED}✖ No interactive terminal available.${RST}"
    echo -e "  ${DIM}Download it first, then run it locally:${RST}"
    echo -e "  ${CYAN}curl -fsSL ${UPSTREAM:-<script-url>} -o reinstall.sh${RST}"
    echo -e "  ${CYAN}sudo bash reinstall.sh${RST}"
    echo
    exit 1
fi

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# ROOT + CURL
# ---------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo
    echo -e "  ${RED}✖ Root privileges are required.${RST}"
    echo -e "  ${CYAN}sudo bash $0${RST}"
    echo
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo
    echo -e "  ${RED}✖ curl is required but is not installed.${RST}"
    echo
    exit 1
fi

# ---------------------------------------------------------------------------
# BANNER
# ---------------------------------------------------------------------------

clear 2>/dev/null || true

banner() {
    if [ "$BOX_W" -ge 50 ]; then
        cat <<'BANNER'
   ██╗   ██╗██╗███████╗██╗██████╗ ██╗     ███████╗
   ██║   ██║██║██╔════╝██║██╔══██╗██║     ██╔════╝
   ██║   ██║██║███████╗██║██████╔╝██║     █████╗
   ╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║     ██╔══╝
    ╚████╔╝ ██║███████║██║██████╔╝███████╗███████╗
     ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝
BANNER
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
    printf '      %sAnimated frontend for %s/%s%s\n' \
        "$DIM" "$GITHUB_USER" "$GITHUB_REPO" "$RST"
}

banner
echo
type_text "  ${CYAN}Initialising deployment shell ...${RST}"
echo
echo -e "  ${GREY}────────────────────────────────────────────────────${RST}"
echo -e "  ${DIM}Host${RST}    : ${WHITE}$(hostname 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Kernel${RST}  : ${WHITE}$(uname -r 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Arch${RST}    : ${WHITE}$(uname -m 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Engine${RST}  : ${WHITE}${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_FILE}${RST}"
echo -e "  ${GREY}────────────────────────────────────────────────────${RST}"

# ---------------------------------------------------------------------------
# DOWNLOAD UPSTREAM SCRIPT  (main → master → jsDelivr mirror)
# ---------------------------------------------------------------------------

fetch_engine() {

    local -a urls=()
    local url

    if [ -n "$UPSTREAM" ]; then
        urls+=( "$UPSTREAM" )
    else
        urls+=(
            "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/${GITHUB_FILE}"
            "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/master/${GITHUB_FILE}"
            "https://cdn.jsdelivr.net/gh/${GITHUB_USER}/${GITHUB_REPO}@main/${GITHUB_FILE}"
            "https://cdn.jsdelivr.net/gh/${GITHUB_USER}/${GITHUB_REPO}@master/${GITHUB_FILE}"
        )
    fi

    for url in "${urls[@]}"; do

        spin_start "Fetching reinstall engine ..."

        if curl -fsSL \
                --connect-timeout 10 \
                --max-time 90 \
                "$url" \
                -o "$TMP" >/dev/null 2>&1
        then
            spin_stop ok
            UPSTREAM_URL="$url"
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
    echo -e "  ${DIM}Check your network / DNS, or set REINSTALL_UPSTREAM to a mirror.${RST}"
    echo
    exit 1
fi

chmod +x "$TMP"

if ! head -n 20 "$TMP" | grep -qE '^(#|set |usage_and_exit|while)'; then
    echo
    echo -e "  ${RED}✖ Downloaded file does not look like a shell script.${RST}"
    echo
    exit 1
fi

# ---------------------------------------------------------------------------
# READ UPSTREAM USAGE
# ---------------------------------------------------------------------------

usage="$(
    sed -n '/^usage_and_exit()/,/^}/p' "$TMP" 2>/dev/null |
        sed -n '/cat <<EOF/,/^EOF/p' |
        sed '1d;$d'
)"

# ---------------------------------------------------------------------------
# DISTRO TABLE (parsed from upstream, with a safe fallback)
# ---------------------------------------------------------------------------

declare -a DISTROS=()
declare -A SPECS

# Fallback list — used only if upstream parsing yields nothing.
FALLBACK_USAGE='
alpine              [3.15|3.16|3.17|3.18|3.19|3.20]
arch                [latest]
centos              [7|8|stream8|stream9]
debian              [9|10|11|12|13]
fedora              [latest]
gentoo              [latest]
netboot.xyz         [netboot.xyz]
nixos               [latest]
openeuler           [22.03|22.09|24.03]
opensuse            [tumbleweed|leap-15.4|leap-15.5|leap-15.6]
oracle              [7|8|9]
redhat              [--img]
ubuntu              [16.04|18.04|20.04|22.04|24.04]
windows             [--img]
reset               [reset]
dd                  [--img]
'

if [ -z "$usage" ]; then
    usage="$FALLBACK_USAGE"
    echo
    echo -e "  ${YELLOW}⚠${RST}  ${DIM}Could not read the OS list upstream — using built-in table.${RST}"
fi

while IFS= read -r line; do

    line="$(printf '%s\n' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue

    case "$line" in
        Usage:* | Options:* | Manual:* | For\ * | Distro* | http://* | https://*)
            continue
            ;;
    esac

    distro="$(printf '%s\n' "$line" | awk '{print $1}')"
    rest="$(printf '%s\n' "$line" | cut -d' ' -f2-)"

    printf '%s' "$distro" | grep -Eq '^[a-zA-Z0-9._-]+$' || continue

    case "$distro" in
        anolis | opencloudos | rocky | oracle | almalinux | centos |
        fnos | fygoos | nixos | fedora | debian | opensuse | alpine |
        kali | openeuler | ubuntu | arch | gentoo | aosc | redhat |
        dd | windows | netboot.xyz | reset) ;;
        *) continue ;;
    esac

    if [ -z "${SPECS[$distro]+x}" ]; then
        DISTROS+=("$distro")
    fi

    SPECS["$distro"]="$rest"

done <<< "$usage"

if [ "${#DISTROS[@]}" -eq 0 ]; then
    echo
    echo -e "  ${RED}✖ No supported operating systems detected.${RST}"
    echo
    exit 1
fi

# ---------------------------------------------------------------------------
# PRETTY NAMES + ICONS
# ---------------------------------------------------------------------------

pretty_name() {
    case "$1" in
        anolis)       echo "Anolis OS" ;;
        opencloudos)  echo "OpenCloudOS" ;;
        rocky)        echo "Rocky Linux" ;;
        oracle)       echo "Oracle Linux" ;;
        almalinux)    echo "AlmaLinux" ;;
        centos)       echo "CentOS" ;;
        fnos)         echo "fnOS" ;;
        fygoos)       echo "FydeOS" ;;
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

# ---------------------------------------------------------------------------
# VERSION SELECTOR
# ---------------------------------------------------------------------------

SELECTED_VERSION=""

select_version() {
    local distro="$1" spec="${SPECS[$distro]}"
    local -a versions
    local choice version i

    SELECTED_VERSION=""
    [ -z "$spec" ] && return 0

    IFS='|' read -ra versions <<< "$spec"

    if [ "${#versions[@]}" -eq 1 ]; then
        SELECTED_VERSION="${versions[0]}"
        [[ "$SELECTED_VERSION" == --* ]] && SELECTED_VERSION=""
        return 0
    fi

    echo
    box_top
    printf '%s║%s   %s %s%-*s%s║%s\n' \
        "$GREEN" "$GREEN" "$(icon "$distro")" "$BOLD" \
        "$((BOX_W - 7))" "$(pretty_name "$distro")" "$GREEN" "$RST"
    box_mid

    i=1
    for version in "${versions[@]}"; do
        version="$(printf '%s' "$version" | xargs)"
        [ -z "$version" ] && continue
        printf '%s║%s   %s%2d%s    %-*s%s║%s\n' \
            "$GREEN" "$GREEN" "$CYAN" "$i" "$RST" \
            "$((BOX_W - 9))" "$version" "$GREEN" "$RST"
        i=$(( i + 1 ))
    done

    printf '%s║%s   %s%2d%s    %-*s%s║%s\n' \
        "$GREEN" "$GREEN" "$RED" 0 "$RST" \
        "$((BOX_W - 9))" "← Back" "$GREEN" "$RST"
    box_bot
    echo

    while true; do
        read -rp "  ${CYAN}➜${RST} Select version: " choice

        [ "$choice" = "0" ] && return 1

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
           [ "$choice" -ge 1 ] &&
           [ "$choice" -le "${#versions[@]}" ]; then
            SELECTED_VERSION="$(printf '%s' "${versions[$(( choice - 1 ))]}" | xargs)"
            return 0
        fi

        printf '\r  %s✖ Invalid selection — try again.%s\n' "$RED" "$RST"
    done
}

# ---------------------------------------------------------------------------
# MAIN OS MENU
# ---------------------------------------------------------------------------

DISTRO="${1:-}"

if [ -n "$DISTRO" ]; then
    found=0
    for d in "${DISTROS[@]}"; do
        [ "$d" = "$DISTRO" ] && found=1
    done
    [ "$found" -eq 0 ] && DISTRO=""
fi

while [ -z "$DISTRO" ]; do

    echo
    printf '%s╔%s╗%s\n' "$BLUE" "$(rep '═' "$BOX_W")" "$RST"
    printf '%s║%s      %s%s🌍  SELECT OPERATING SYSTEM%s%*s%s║%s\n' \
        "$BLUE" "$BLUE" "$BOLD" "$WHITE" "$RST" \
        "$((BOX_W - 33))" "" "$BLUE" "$RST"
    printf '%s╠%s╣%s\n' "$BLUE" "$(rep '═' "$BOX_W")" "$RST"

    i=1
    for distro in "${DISTROS[@]}"; do
        printf '%s║%s   %s%2d%s   %s %s%-*s%s║%s\n' \
            "$BLUE" "$BLUE" "$CYAN" "$i" "$RST" \
            "$(icon "$distro")" "$WHITE" \
            "$((BOX_W - 9))" "$(pretty_name "$distro")" "$BLUE" "$RST"
        i=$(( i + 1 ))
    done

    printf '%s║%s   %s%2d%s   %s %s%-*s%s║%s\n' \
        "$BLUE" "$BLUE" "$RED" 0 "$RST" \
        "❌" "$RED" "$((BOX_W - 9))" "Exit" "$BLUE" "$RST"
    printf '%s╚%s╝%s\n' "$BLUE" "$(rep '═' "$BOX_W")" "$RST"
    echo

    read -rp "  ${CYAN}🦜 Visible Tech ${DIM}➜${RST} Select OS: " choice

    if [ "$choice" = "0" ]; then
        echo
        echo -e "  ${YELLOW}👋  Reinstallation cancelled — nothing was changed.${RST}"
        echo
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "${#DISTROS[@]}" ]; then
        printf '\r  %s✖ Enter a number between 1 and %s.%s\n' \
            "$RED" "${#DISTROS[@]}" "$RST"
        sleep 0.6
        continue
    fi

    DISTRO="${DISTROS[$(( choice - 1 ))]}"

    if ! select_version "$DISTRO"; then
        DISTRO=""
    fi

done

# ---------------------------------------------------------------------------
# SPECIAL IMAGE OPTIONS
# ---------------------------------------------------------------------------

EXTRA_ARGS=()
IMAGE_URL=""

case "$DISTRO" in
    redhat | dd)
        echo
        echo -e "  ${YELLOW}💿  This option requires a disk image URL.${RST}"
        echo
        read -rp "  ${CYAN}➜${RST} Image URL: " IMAGE_URL
        if [ -z "$IMAGE_URL" ]; then
            echo -e "  ${RED}✖ Image URL is required.${RST}"
            exit 1
        fi
        EXTRA_ARGS+=(--img="$IMAGE_URL")
        ;;
    windows)
        echo
        echo -e "  ${YELLOW}🪟  Windows installation.${RST}"
        echo
        read -rp "  ${CYAN}➜${RST} Image / ISO URL: " IMAGE_URL
        if [ -z "$IMAGE_URL" ]; then
            echo -e "  ${RED}✖ Image URL is required.${RST}"
            exit 1
        fi
        EXTRA_ARGS+=(--img="$IMAGE_URL")
        ;;
esac

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------

echo
box_top
printf '%s║%s        %s📋  INSTALLATION SUMMARY%s%*s%s║%s\n' \
    "$MAG" "$MAG" "$BOLD" "$RST" "$((BOX_W - 29))" "" "$MAG" "$RST"
box_mid
box_row "🦜  Brand    : Visible Tech"
box_row "🌍  OS       : $(pretty_name "$DISTRO")"
[ -n "$SELECTED_VERSION" ] && box_row "📦  Version  : $SELECTED_VERSION"
[ -n "$IMAGE_URL" ] && box_row "💿  Image    : $IMAGE_URL"
box_row "⚙️   Engine   : wavy07/reinstallation"
box_bot

echo
echo -e "  ${RED}${BOLD}⚠️  WARNING${RST}"
echo -e "  ${RED}   This operation can erase the VPS system disk.${RST}"
echo -e "  ${RED}   Existing data may be permanently lost.${RST}"
echo

read -rp "  ${YELLOW}⚡ Start reinstallation? ${BOLD}[y/N]${RST} " confirm

case "$confirm" in
    y | Y | yes | YES | Yes) ;;
    *)
        echo
        echo -e "  ${YELLOW}👋  Reinstallation cancelled.${RST}"
        echo
        exit 0
        ;;
esac

# ---------------------------------------------------------------------------
# LAUNCH REAL INSTALLER
# ---------------------------------------------------------------------------

echo
type_text "  ${CYAN}${BOLD}🚀  Launching Visible Tech reinstallation engine ...${RST}"
echo

p=0
while [ "$p" -le 100 ]; do
    progress_bar "$p" "preparing chroot environment"
    sleep 0.03
    p=$(( p + 5 ))
done

CMD=(bash "$TMP" "$DISTRO")

if [ -n "${SELECTED_VERSION:-}" ]; then
    CMD+=("$SELECTED_VERSION")
fi

if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    CMD+=(${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"})
fi

# Hand over to the real installer — its prompts stay visible & interactive.
exec "${CMD[@]}"
