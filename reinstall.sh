#!/usr/bin/env bash
# =============================================================================
#   VISIBLE TECH REINSTALLER  -  frontend for bin456789/reinstall
#   curl -fsSL https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh | sudo bash
# =============================================================================
set -u
export LANG=C LC_ALL=C

REPO_USER="wavy07"
REPO_NAME="reinstallation"
ENGINE_OVERRIDE="${REINSTALL_ENGINE:-}"

declare -a ENGINE_URLS=(
    "https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    "https://raw.githubusercontent.com/bin456789/reinstall/master/reinstall.sh"
    "https://cdn.jsdelivr.net/gh/bin456789/reinstall@main/reinstall.sh"
)

TMP="/tmp/.visible-tech-reinstall.$$"
SPIN_PID=""

# ---------------- colours ----------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RST=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
    RED=$'\033[91m'; GREEN=$'\033[92m'; YELLOW=$'\033[93m'
    BLUE=$'\033[94m'; MAG=$'\033[95m'; CYAN=$'\033[96m'
    WHITE=$'\033[97m'; GREY=$'\033[90m'
else
    RST=""; BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""
    BLUE=""; MAG=""; CYAN=""; WHITE=""; GREY=""
fi

# ---------------- layout ----------------
BOX_W=54
_tw="$(tput cols 2>/dev/null || true)"
if [ -n "${_tw:-}" ] && [[ "${_tw}" =~ ^[0-9]+$ ]] && [ "$_tw" -gt 0 ] && [ "$_tw" -lt 66 ]; then
    BOX_W=$(( _tw - 6 ))
fi
[ "$BOX_W" -lt 30 ] && BOX_W=30

rep() { local c="$1" n="$2" o=""; local i; for ((i=0;i<n;i++)); do o+="$c"; done; printf '%s' "$o"; }
box_top() { printf '%s╔%s╗%s\n' "$MAG" "$(rep '═' "$BOX_W")" "$RST"; }
box_mid() { printf '%s╠%s╣%s\n' "$MAG" "$(rep '═' "$BOX_W")" "$RST"; }
box_bot() { printf '%s╚%s╝%s\n' "$MAG" "$(rep '═' "$BOX_W")" "$RST"; }
box_row() { printf '%s║%s  %-*s %s║%s\n' "$MAG" "$WHITE" "$((BOX_W-4))" "$1" "$MAG" "$RST"; }

# ---------------- spinner (KILL based - no shared flags) ----------------
_spinner_loop() {
    local f=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    while :; do
        printf '\r  %s%s%s %s%s%s' "$CYAN" "${f[$i]}" "$RST" "$DIM" "$1" "$RST"
        i=$(( (i+1) % ${#f[@]} )); sleep 0.07
    done
}
spin_start() {
    [ -n "${SPIN_PID:-}" ] && kill "$SPIN_PID" 2>/dev/null
    _spinner_loop "$1" & SPIN_PID=$!
}
spin_stop() {
    local ok="${1:-ok}"
    if [ -n "${SPIN_PID:-}" ]; then
        kill "$SPIN_PID" 2>/dev/null
        wait "$SPIN_PID" 2>/dev/null
        SPIN_PID=""
    fi
    printf '\r%s' "$(rep ' ' $((BOX_W+14)))"
    if [ "$ok" = ok ]; then
        printf '\r  %s✔%s %sDone.%s\n' "$GREEN" "$RST" "$DIM" "$RST"
    elif [ "$ok" = fail ]; then
        printf '\r  %s✖%s %sFailed.%s\n' "$RED" "$RST" "$DIM" "$RST"
    else
        printf '\r'
    fi
}
kill_spinner() { [ -n "${SPIN_PID:-}" ] && { kill "$SPIN_PID" 2>/dev/null; wait "$SPIN_PID" 2>/dev/null; }; }

progress_bar() {
    local pct="$1" label="${2:-}" w=28 f e bar
    f=$(( w*pct/100 )); e=$(( w-f )); bar="$(rep '█' "$f")$(rep '░' "$e")"
    printf '\r  %s│%s%s%s│%s %3d%%  %s%s%s' "$CYAN" "$GREEN" "$bar" "$CYAN" "$RST" "$pct" "$DIM" "$label" "$RST"
    [ "$pct" -ge 100 ] && printf '\n'
}
type_text() {
    local t="$1" d="${2:-0.008}" i
    if [ ! -t 1 ]; then printf '%s\n' "$t"; return; fi
    for ((i=0;i<${#t};i++)); do printf '%s' "${t:$i:1}"; sleep "$d"; done
    printf '\n'
}
rainbow() {
    local t="$1" i; local -a p=( 91 93 92 96 94 95 )
    for ((i=0;i<${#t};i++)); do printf '\033[1;%sm%s' "${p[$((i % ${#p[@]}))]}" "${t:$i:1}"; done
    printf '%s' "$RST"
}

# ---------------- FIX: interactive stdin even when piped ----------------
if [ -t 0 ]; then
    :
elif [ -r /dev/tty ] && [ -w /dev/tty ]; then
    exec < /dev/tty
else
    echo; echo -e "  ${RED}✖ No interactive terminal available.${RST}"
    echo -e "  ${DIM}Download it first, then run locally:${RST}"
    echo -e "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/reinstall.sh -o vt.sh${RST}"
    echo -e "  ${CYAN}sudo bash vt.sh${RST}"; echo
    exit 1
fi

cleanup() { kill_spinner; rm -f "$TMP"; }
trap cleanup EXIT INT TERM

# ---------------- requirements ----------------
if [ "$(id -u)" -ne 0 ]; then
    echo; echo -e "  ${RED}✖ Root privileges are required.${RST}"
    echo -e "  ${CYAN}sudo bash $0${RST}"; echo; exit 1
fi

for _c in curl sed awk grep; do
    if ! command -v "$_c" >/dev/null 2>&1; then
        echo; echo -e "  ${RED}✖ Required tool missing: ${WHITE}$_c${RST}"
        echo -e "  ${DIM}apt-get update && apt-get install -y curl sed gawk grep${RST}"; echo
        exit 1
    fi
done

# ---------------- banner ----------------
clear 2>/dev/null || true
if [ "$BOX_W" -ge 50 ]; then
cat <<'B'
   ██╗   ██╗██╗███████╗██╗██████╗ ██╗     ███████╗
   ██║   ██║██║██╔════╝██║██╔══██╗██║     ██╔════╝
   ██║   ██║██║███████╗██║██████╔╝██║     █████╗
   ╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║     ██╔══╝
    ╚████╔╝ ██║███████║██║██████╔╝███████╗███████╗
     ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝
B
else
    printf '%s\n' "  ██╗   ██╗██╗███████╗██╗██████╗ ██╗     ███████╗"
    printf '%s\n' "  ╚██╗ ██╔╝██║╚════██║██║██╔══██╗██║     ██╔════╝"
    printf '%s\n' "   ╚████╔╝ ██║███████║██║██████╔╝███████╗███████╗"
    printf '%s\n' "    ╚═══╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚══════╝╚══════╝"
fi
echo; printf '      '; rainbow "V I S I B L E   T E C H   R E I N S T A L L E R"; echo
printf '      %sUbuntu / Debian / multi-distro VPS OS installer%s\n' "$DIM" "$RST"
echo
type_text "  ${CYAN}Initialising deployment shell ...${RST}"
echo
echo -e "  ${GREY}────────────────────────────────────────────────────${RST}"
echo -e "  ${DIM}Host${RST}   : ${WHITE}$(hostname 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Kernel${RST} : ${WHITE}$(uname -r 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Arch${RST}   : ${WHITE}$(uname -m 2>/dev/null || echo unknown)${RST}"
echo -e "  ${DIM}Engine${RST} : ${WHITE}bin456789/reinstall${RST}"
echo -e "  ${GREY}────────────────────────────────────────────────────${RST}"

# ---------------- download the ENGINE (bin456789, NOT this repo) ----------------
ENGINE_URL=""
fetch_engine() {
    local -a urls=() url
    if [ -n "$ENGINE_OVERRIDE" ]; then urls=( "$ENGINE_OVERRIDE" ); else urls=( "${ENGINE_URLS[@]}" ); fi
    for url in "${urls[@]}"; do
        spin_start "Fetching reinstall engine ..."
        if curl -fsSL --connect-timeout 10 --max-time 90 --retry 2 "$url" -o "$TMP" >/dev/null 2>&1; then
            spin_stop ok; ENGINE_URL="$url"; return 0
        fi
        spin_stop fail
    done
    return 1
}

echo
if ! fetch_engine; then
    echo
    echo -e "  ${RED}✖ Unable to download the reinstall engine.${RST}"
    echo -e "  ${DIM}Check DNS/network, or set REINSTALL_ENGINE to a mirror.${RST}"; echo
    exit 1
fi
chmod +x "$TMP"

_first="$(head -c 4096 "$TMP" 2>/dev/null || true)"
if ! printf '%s' "$_first" | grep -qE '^#!/?(usr/bin/)?(env )?(ba)?sh'; then
    echo; echo -e "  ${RED}✖ Downloaded engine is not a shell script.${RST}"
    echo -e "  ${DIM}Got: ${WHITE}$(printf '%s' "$_first" | head -n1 | cut -c1-60)${RST}"; echo
    exit 1
fi
if [ "$(wc -c < "$TMP")" -lt 2000 ]; then
    echo; echo -e "  ${RED}✖ Downloaded engine is too small / truncated.${RST}"; echo; exit 1
fi

# ---------------- distro table (AUTHITATIVE for Ubuntu/Debian) ----------------
declare -a DISTROS=()
declare -A SPECS

add_distro() {
    local d="$1" r="$2"
    printf '%s' "$d" | grep -Eq '^[a-zA-Z0-9._-]+$' || return 1
    case "$d" in
        anolis|opencloudos|rocky|oracle|almalinux|centos|fnos|fygoos|nixos|\
        fedora|debian|opensuse|alpine|kali|openeuler|ubuntu|arch|gentoo|\
        aosc|redhat|dd|windows|netboot.xyz|reset) ;;
        *) return 1 ;;
    esac
    if [ -z "${SPECS[$d]+x}" ]; then DISTROS+=( "$d" ); fi
    SPECS["$d"]="$r"
}

# 1) guaranteed-correct table
BUILTIN='
ubuntu              [16.04|18.04|20.04|22.04|23.10|24.04|24.10]
debian              [9|10|11|12|13|trixie|bookworm]
alpine              [3.15|3.16|3.17|3.18|3.19|3.20|3.21]
arch                [latest]
centos              [7|8|stream8|stream9]
rocky               [8|9]
almalinux           [8|9]
oracle              [7|8|9]
fedora              [latest]
gentoo              [latest]
opensuse            [tumbleweed|leap-15.4|leap-15.5|leap-15.6]
openeuler           [22.03|22.09|24.03]
anolis              [8|23]
opencloudos         [latest]
kali                [latest]
nixos               [latest]
aosc                [latest]
netboot.xyz         [netboot.xyz]
reset               [reset]
redhat              [7|8|9]
dd                  []
windows             []
'

while IFS= read -r line; do
    line="$(printf '%s\n' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    d="$(printf '%s\n' "$line" | awk '{print $1}')"
    r="$(printf '%s\n' "$line" | cut -d' ' -f2-)"
    add_distro "$d" "$r"
done <<< "$BUILTIN"

# 2) merge anything extra the upstream engine supports
usage="$( sed -n '/^usage_and_exit()/,/^}/p' "$TMP" 2>/dev/null |
          sed -n '/cat <<EOF/,/^EOF/p' | sed '1d;$d' )"

if [ -n "$usage" ]; then
    while IFS= read -r line; do
        line="$(printf '%s\n' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -z "$line" ] && continue
        case "$line" in
            Usage:*|Options:*|Manual:*|For\ *|Distro*|http://*|https:*) continue ;;
        esac
        d="$(printf '%s\n' "$line" | awk '{print $1}')"
        r="$(printf '%s\n' "$line" | cut -d' ' -f2-)"
        if [ -z "${SPECS[$d]+x}" ]; then add_distro "$d" "$r"; fi
    done <<< "$usage"
fi

if [ "${#DISTROS[@]}" -eq 0 ]; then
    echo; echo -e "  ${RED}✖ No supported operating systems detected.${RST}"; echo; exit 1
fi

# ---------------- names + icons ----------------
pretty_name() {
    case "$1" in
        anolis) echo "Anolis OS" ;; opencloudos) echo "OpenCloudOS" ;;
        rocky) echo "Rocky Linux" ;; oracle) echo "Oracle Linux" ;;
        almalinux) echo "AlmaLinux" ;; centos) echo "CentOS" ;;
        fnos) echo "fnOS" ;; fygoos) echo "FydeOS" ;; nixos) echo "NixOS" ;;
        fedora) echo "Fedora" ;; debian) echo "Debian" ;; opensuse) echo "openSUSE" ;;
        alpine) echo "Alpine Linux" ;; kali) echo "Kali Linux" ;; openeuler) echo "openEuler" ;;
        ubuntu) echo "Ubuntu" ;; arch) echo "Arch Linux" ;; gentoo) echo "Gentoo" ;;
        aosc) echo "AOSC OS" ;; redhat) echo "Red Hat" ;; dd) echo "DD / Disk Image" ;;
        windows) echo "Windows" ;; netboot.xyz) echo "netboot.xyz" ;; reset) echo "Reset / Recovery" ;;
        *) echo "$1" ;;
    esac
}
icon() {
    case "$1" in
        ubuntu) echo "🟠" ;; debian) echo "🔴" ;; fedora) echo "🔵" ;; rocky) echo "🟢" ;;
        oracle) echo "🟣" ;; almalinux) echo "🟢" ;; centos) echo "🟡" ;; anolis) echo "🟠" ;;
        opencloudos) echo "🟡" ;; openeuler) echo "🟢" ;; alpine) echo "🔷" ;; kali) echo "💀" ;;
        opensuse) echo "🦎" ;; arch) echo "🔷" ;; gentoo) echo "🟣" ;; aosc) echo "🟣" ;;
        nixos) echo "❄️" ;; redhat) echo "🔴" ;; dd) echo "💿" ;; windows) echo "🪟" ;;
        netboot.xyz) echo "🌐" ;; reset) echo "♻️" ;; *) echo "💻" ;;
    esac
}

# ---------------- version selector ----------------
SELECTED_VERSION=""
select_version() {
    local distro="$1" spec="${SPECS[$distro]}"
    local -a versions
    local choice v i
    SELECTED_VERSION=""
    [ -z "$spec" ] && return 0

    spec="$(printf '%s' "$spec" | sed 's/^\[//;s/\]$//')"
    IFS='|' read -ra versions <<< "$spec"
    [ "${#versions[@]}" -eq 0 ] && return 0

    if [ "${#versions[@]}" -eq 1 ]; then
        SELECTED_VERSION="${versions[0]}"
        [[ "$SELECTED_VERSION" == --* || -z "$SELECTED_VERSION" ]] && SELECTED_VERSION=""
        return 0
    fi

    echo
    box_top
    printf '%s║%s   %s %s%-*s%s║%s\n' "$GREEN" "$GREEN" "$(icon "$distro")" "$BOLD" \
        "$((BOX_W-7))" "$(pretty_name "$distro")" "$GREEN" "$RST"
    box_mid
    i=1
    for v in "${versions[@]}"; do
        v="$(printf '%s' "$v" | xargs)"; [ -z "$v" ] && continue
        printf '%s║%s   %s%2d%s    %-*s%s║%s\n' "$GREEN" "$GREEN" "$CYAN" "$i" "$RST" \
            "$((BOX_W-9))" "$v" "$GREEN" "$RST"
        i=$(( i+1 ))
    done
    printf '%s║%s   %s%2d%s    %-*s%s║%s\n' "$GREEN" "$GREEN" "$RED" 0 "$RST" \
        "$((BOX_W-9))" "← Back" "$GREEN" "$RST"
    box_bot; echo

    while true; do
        read -rp "  ${CYAN}➜${RST} Select version: " choice
        [ "$choice" = "0" ] && return 1
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#versions[@]}" ]; then
            SELECTED_VERSION="$(printf '%s' "${versions[$(( choice-1 ))]}" | xargs)"
            return 0
        fi
        printf '\r  %s✖ Invalid selection — try again.%s\n' "$RED" "$RST"
    done
}

# ---------------- main menu ----------------
DISTRO="${1:-}"
HOST_ID=""
[ -r /etc/os-release ] && HOST_ID="$( . /etc/os-release 2>/dev/null && printf '%s' "${ID:-}" )"

if [ -z "$DISTRO" ] && [ -n "$HOST_ID" ]; then
    for d in "${DISTROS[@]}"; do [ "$d" = "$HOST_ID" ] && DISTRO="$d"; done
fi

while [ -z "$DISTRO" ]; do
    echo
    printf '%s╔%s╗%s\n' "$BLUE" "$(rep '═' "$BOX_W")" "$RST"
    printf '%s║%s      %s%s🌍  SELECT OPERATING SYSTEM%s%*s%s║%s\n' "$BLUE" "$BLUE" "$BOLD" \
        "$WHITE" "$RST" "$((BOX_W-33))" "" "$BLUE" "$RST"
    printf '%s╠%s╣%s\n' "$BLUE" "$(rep '═' "$BOX_W")" "$RST"
    i=1
    for d in "${DISTROS[@]}"; do
        printf '%s║%s   %s%2d%s   %s %s%-*s%s║%s\n' "$BLUE" "$BLUE" "$CYAN" "$i" "$RST" \
            "$(icon "$d")" "$WHITE" "$((BOX_W-9))" "$(pretty_name "$d")" "$BLUE" "$RST"
        i=$(( i+1 ))
    done
    printf '%s║%s   %s%2d%s   %s %s%-*s%s║%s\n' "$BLUE" "$BLUE" "$RED" 0 "$RST" \
        "❌" "$RED" "$((BOX_W-9))" "Exit" "$BLUE" "$RST"
    printf '%s╚%s╝%s\n' "$BLUE" "$(rep '═' "$BOX_W")" "$RST"
    echo

    read -rp "  ${CYAN}🦜 Visible Tech ${DIM}➜${RST} Select OS: " choice

    if [ "$choice" = "0" ]; then
        echo; echo -e "  ${YELLOW}👋  Reinstallation cancelled — nothing was changed.${RST}"; echo; exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#DISTROS[@]}" ]; then
        printf '\r  %s✖ Enter a number between 1 and %s.%s\n' "$RED" "${#DISTROS[@]}" "$RST"
        sleep 0.6; continue
    fi

    DISTRO="${DISTROS[$(( choice-1 ))]}"
    if ! select_version "$DISTRO"; then DISTRO=""; fi
done

# ---------------- image options ----------------
EXTRA_ARGS=()
IMAGE_URL=""
case "$DISTRO" in
    redhat|dd)
        echo; echo -e "  ${YELLOW}💿  This option requires a disk image URL.${RST}"; echo
        read -rp "  ${CYAN}➜${RST} Image URL: " IMAGE_URL
        [ -z "$IMAGE_URL" ] && { echo -e "  ${RED}✖ Image URL is required.${RST}"; exit 1; }
        EXTRA_ARGS+=(--img="$IMAGE_URL") ;;
    windows)
        echo; echo -e "  ${YELLOW}🪟  Windows installation.${RST}"; echo
        read -rp "  ${CYAN}➜${RST} Image / ISO URL: " IMAGE_URL
        [ -z "$IMAGE_URL" ] && { echo -e "  ${RED}✖ Image URL is required.${RST}"; exit 1; }
        EXTRA_ARGS+=(--img="$IMAGE_URL") ;;
esac

# ---------------- summary ----------------
echo
box_top
printf '%s║%s        %s📋  INSTALLATION SUMMARY%s%*s%s║%s\n' "$MAG" "$MAG" "$BOLD" "$RST" \
    "$((BOX_W-29))" "" "$MAG" "$RST"
box_mid
box_row "🦜  Brand    : Visible Tech"
box_row "🌍  OS       : $(pretty_name "$DISTRO")"
[ -n "${SELECTED_VERSION}" ] && box_row "📦  Version  : $SELECTED_VERSION"
[ -n "$IMAGE_URL" ] && box_row "💿  Image    : $IMAGE_URL"
box_row "⚙️   Engine   : bin456789/reinstall"
box_bot
echo
echo -e "  ${RED}${BOLD}⚠️  WARNING${RST}"
echo -e "  ${RED}   This operation can erase the VPS system disk.${RST}"
echo -e "  ${RED}   Existing data may be permanently lost.${RST}"
echo
read -rp "  ${YELLOW}⚡ Start reinstallation? ${BOLD}[y/N]${RST} " confirm
case "$confirm" in
    y|Y|yes|YES|Yes) ;;
    *) echo; echo -e "  ${YELLOW}👋  Reinstallation cancelled.${RST}"; echo; exit 0 ;;
esac

# ---------------- launch ----------------
echo
type_text "  ${CYAN}${BOLD}🚀  Launching reinstallation engine ...${RST}"
echo
p=0
while [ "$p" -le 100 ]; do
    progress_bar "$p" "preparing chroot environment"
    sleep 0.03; p=$(( p+5 ))
done

CMD=(bash "$TMP" "$DISTRO")
[ -n "${SELECTED_VERSION}" ] && CMD+=( "$SELECTED_VERSION" )
[ "${#EXTRA_ARGS[@]}" -gt 0 ] && CMD+( ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} )

exec "${CMD[@]}"
