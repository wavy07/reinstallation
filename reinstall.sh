#!/usr/bin/env bash
# =============================================================================
#  reinstall.sh  -  OS chooser for the one-click reinstall script
# =============================================================================
#  Repo      : https://github.com/wavy07/reinstallation
#  Engine    : https://github.com/bin456789/reinstall  (downloaded fresh each run)
#
#  Run (menu):
#    curl -fsSL https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh -o reinstall.sh
#    bash reinstall.sh
#
#  Run without the menu (the arguments go straight to the engine):
#    bash reinstall.sh ubuntu 24.04
#    bash reinstall.sh debian 12 --password 'MyPass' --ssh-port 2222
#
#  Other:   bash reinstall.sh --list     show the supported systems
#           bash reinstall.sh reset      cancel a reinstall before you reboot
#
#  WARNING: installing an OS ERASES THE WHOLE DISK (all partitions).
#  Not supported: OpenVZ and LXC virtual machines.
# =============================================================================
set -u

UPSTREAM_URLS=(
  "${RI_UPSTREAM:-https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh}"
  "https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh"
)
WORKDIR="${RI_WORKDIR:-/root/reinstall-engine}"

# ----------------------------------------------------------------- colors
if [ -t 1 ]; then
  R=$'\033[0;31m'; G=$'\033[0;32m'; Y=$'\033[1;33m'; B=$'\033[0;34m'
  C=$'\033[0;36m'; W=$'\033[1;37m'; D=$'\033[2m'; N=$'\033[0m'
else
  R=''; G=''; Y=''; B=''; C=''; W=''; D=''; N=''
fi

die()  { echo -e "\n${R}✗ $*${N}" >&2; exit 1; }
warn() { echo -e "${Y}! $*${N}"; }
ok()   { echo -e "${G}✓ $*${N}"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------------- input (works with curl | bash too)
exec 3<&0
if [ ! -t 0 ] && [ -z "${RI_NO_TTY:-}" ] && [ -r /dev/tty ]; then exec 3</dev/tty; fi

ask() {   # prompt  varname  [default]
  local __p="$1" __v="$2" __d="${3:-}" __in=""
  if [ -n "$__d" ]; then printf '%s [%s]: ' "$__p" "$__d"; else printf '%s: ' "$__p"; fi
  IFS= read -r -u 3 __in || { echo; exit 1; }
  printf -v "$__v" '%s' "${__in:-$__d}"
}
ask_secret() {   # prompt  varname
  local __p="$1" __v="$2" __in=""
  printf '%s: ' "$__p"
  IFS= read -r -s -u 3 __in || { echo; exit 1; }
  echo
  printf -v "$__v" '%s' "$__in"
}

# ----------------------------------------------------------------- supported systems
# NAME | engine key | versions (space separated, empty = rolling) | type
NAMES=(); KEYS=(); VERS=(); TYPES=()
add() { NAMES+=("$1"); KEYS+=("$2"); VERS+=("$3"); TYPES+=("$4"); }

add "Ubuntu"         ubuntu      "18.04 20.04 22.04 24.04 26.04"  ver
add "Debian"         debian      "9 10 11 12 13"                  ver
add "Kali Linux"     kali        "last-snapshot rolling"          ver
add "Alpine"         alpine      "3.21 3.22 3.23 3.24"            ver
add "AlmaLinux"      almalinux   "8 9 10"                         ver
add "Rocky Linux"    rocky       "8 9 10"                         ver
add "Oracle Linux"   oracle      "8 9 10"                         ver
add "CentOS Stream"  centos      "9 10"                           ver
add "Fedora"         fedora      "43 44"                          ver
add "Anolis OS"      anolis      "7 8 23"                         ver
add "OpenCloudOS"    opencloudos "8 9 23"                         ver
add "openEuler"      openeuler   "20.03 22.03 24.03 26.09"        ver
add "openSUSE"       opensuse    "16.0 tumbleweed"                ver
add "NixOS"          nixos       "26.05"                          ver
add "Arch Linux"     arch        ""                               rolling
add "Gentoo"         gentoo      ""                               rolling
add "AOSC OS"        aosc        ""                               rolling
add "fnOS"           fnos        "1"                              ver
add "FygoOS"         fygoos      "1"                              ver
add "Red Hat"        redhat      ""                               redhat

NLINUX=${#NAMES[@]}
I_WIN=$((NLINUX + 1)); I_DD=$((NLINUX + 2)); I_LIVE=$((NLINUX + 3))
I_NETBOOT=$((NLINUX + 4)); I_RESET=$((NLINUX + 5))

print_list() {
  local i show
  echo -e "${W}Linux${N}"
  for i in "${!NAMES[@]}"; do
    show="${VERS[i]}"
    case "${TYPES[i]}" in
      rolling) show="rolling" ;;
      redhat)  show="needs a qcow2 link" ;;
    esac
    printf ' %s%2d)%s %-14s %s%s%s\n' "$C" $((i + 1)) "$N" "${NAMES[i]}" "$D" "$show" "$N"
  done
  echo -e "${W}Windows / other${N}"
  printf ' %s%2d)%s %-14s %sVista - 11, Server 2008 - 2025 (official ISO)%s\n' "$C" "$I_WIN" "$N" "Windows" "$D" "$N"
  printf ' %s%2d)%s %-14s %swrite a raw disk image%s\n' "$C" "$I_DD" "$N" "DD image" "$D" "$N"
  printf ' %s%2d)%s %-14s %sboot Alpine in memory, nothing erased%s\n' "$C" "$I_LIVE" "$N" "Alpine Live" "$D" "$N"
  printf ' %s%2d)%s %-14s %sboot netboot.xyz, nothing erased%s\n' "$C" "$I_NETBOOT" "$N" "netboot.xyz" "$D" "$N"
  printf ' %s%2d)%s %-14s %scancel a reinstall before reboot%s\n' "$C" "$I_RESET" "$N" "Cancel reinstall" "$D" "$N"
}

# ----------------------------------------------------------------- checks
check_env() {
  [ -n "${BASH_VERSION:-}" ] || die "Run this with bash:  bash reinstall.sh"
  [ "$(id -u)" -eq 0 ] || die "Run as root (sudo -i)."
  [ "$(uname -s)" = "Linux" ] || die "This script runs on Linux (use reinstall.bat on Windows)."
  have curl || have wget || die "curl or wget is required."
  local virt=""
  if have systemd-detect-virt; then virt=$(systemd-detect-virt -c 2>/dev/null || true); fi
  case "$virt" in
    openvz|lxc|lxc-libvirt)
      if [ -z "${RI_FORCE:-}" ]; then
        die "This is a $virt container. OpenVZ and LXC are not supported by the engine."
      fi ;;
  esac
}

# ----------------------------------------------------------------- engine download
fetch_engine() {
  mkdir -p "$WORKDIR" || die "Cannot create $WORKDIR"
  ENGINE="$WORKDIR/reinstall.sh"
  local tmp="$WORKDIR/reinstall.sh.new" url got=0
  echo -e "${B}↓ Downloading the reinstall engine...${N}"
  for url in "${UPSTREAM_URLS[@]}"; do
    rm -f "$tmp"
    if have curl; then
      curl -fsSL --retry 3 --connect-timeout 10 "$url" -o "$tmp" 2>/dev/null
    else
      wget -q -T 15 -t 3 -O "$tmp" "$url" 2>/dev/null
    fi
    if [ -s "$tmp" ] && head -n 1 "$tmp" | grep -Eq '^#!.*sh' && bash -n "$tmp" 2>/dev/null; then
      got=1; break
    fi
  done
  [ "$got" -eq 1 ] || { rm -f "$tmp"; die "Could not download the engine (check the network / DNS)."; }
  mv -f "$tmp" "$ENGINE"
  chmod 755 "$ENGINE"
  ok "Engine ready: $ENGINE"
}

# ----------------------------------------------------------------- menu helpers
VERSION=""
pick_version() {   # name  "versions"   -> sets VERSION ("" = latest)
  local name="$1" list="$2" v i=1 choice
  local -a arr=($list)
  VERSION=""
  echo -e "\n${W}$name - choose a version${N}\n"
  for v in "${arr[@]}"; do
    printf ' %s%2d)%s %s\n' "$C" "$i" "$N" "$v"
    i=$((i + 1))
  done
  printf ' %s L)%s Latest (let the engine choose)\n' "$C" "$N"
  printf ' %s M)%s Type a version by hand\n' "$C" "$N"
  printf ' %s 0)%s Back\n\n' "$Y" "$N"
  while true; do
    ask "Select" choice
    case "$choice" in
      0) return 1 ;;
      [Ll]) VERSION=""; return 0 ;;
      [Mm]) ask "Version" VERSION; [ -n "$VERSION" ] && return 0 ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#arr[@]} )); then
          VERSION="${arr[choice-1]}"; return 0
        fi
        warn "Invalid choice." ;;
    esac
  done
}

common_options() {   # $1 = yes -> also ask for an SSH key
  local pw ssh_port key
  echo -e "\n${D}Optional settings - press Enter to skip (the engine will ask or use defaults).${N}"
  ask_secret "Root/admin password" pw
  [ -n "$pw" ] && ARGS+=(--password "$pw")
  ask "SSH port" ssh_port
  if [ -n "$ssh_port" ]; then
    [[ "$ssh_port" =~ ^[0-9]+$ ]] && (( ssh_port >= 1 && ssh_port <= 65535 )) \
      && ARGS+=(--ssh-port "$ssh_port") || warn "Invalid SSH port, skipped."
  fi
  if [ "${1:-no}" = "yes" ]; then
    ask "SSH public key (text, URL, github:USER or path)" key
    [ -n "$key" ] && ARGS+=(--ssh-key "$key")
  fi
  return 0
}

show_command() {
  local out="bash reinstall.sh" a masknext=0
  for a in "${ARGS[@]}"; do
    if [ "$masknext" -eq 1 ]; then out+=" '****'"; masknext=0; continue; fi
    [ "$a" = "--password" ] && masknext=1
    out+=" $(printf '%q' "$a")"
  done
  echo -e "\n${W}Command that will run:${N}\n  ${C}${out}${N}"
}

confirm_run() {   # $1 = destructive | safe
  local ans
  show_command
  if [ "$1" = "destructive" ]; then
    echo -e "\n${R}⚠ This ERASES THE WHOLE DISK (every partition) and installs the new system.${N}"
    echo -e "${D}Make sure you have a backup and console/VNC access.${N}"
    ask "Type YES to continue" ans
    [ "$ans" = "YES" ] || { echo -e "${Y}Cancelled.${N}"; return 1; }
  else
    ask "Continue? (y/N)" ans "N"
    [[ "$ans" =~ ^[Yy]$ ]] || { echo -e "${Y}Cancelled.${N}"; return 1; }
  fi
}

run_engine() {
  fetch_engine
  echo
  ( cd "$WORKDIR" && bash "$ENGINE" "${ARGS[@]}" )
  local rc=$?
  echo
  if [ $rc -eq 0 ]; then
    ok "The engine finished. If it did not reboot by itself, run:  reboot"
    echo -e "${D}Changed your mind? Run 'bash reinstall.sh reset' before rebooting.${N}"
  else
    warn "The engine stopped with code $rc (see the messages above)."
  fi
  return $rc
}

# ----------------------------------------------------------------- flows
flow_linux() {   # index (0-based)
  local i="$1" key="${KEYS[i]}" type="${TYPES[i]}" img mini
  ARGS=("$key")
  case "$type" in
    ver)
      pick_version "${NAMES[i]}" "${VERS[i]}" || return 1
      [ -n "$VERSION" ] && ARGS+=("$VERSION") ;;
    redhat)
      echo -e "\n${D}Get the qcow2 link from https://access.redhat.com/downloads/content/rhel${N}"
      ask "qcow2 image link" img
      [ -n "$img" ] || { warn "A link is required."; return 1; }
      ARGS+=("--img=$img") ;;
  esac
  if [ "$key" = "ubuntu" ]; then
    ask "Minimal install? (y/N)" mini "N"
    [[ "$mini" =~ ^[Yy]$ ]] && ARGS+=(--minimal)
  fi
  common_options yes
  confirm_run destructive || return 1
  run_engine
}

flow_windows() {
  local name lang iso rdp ping
  echo -e "\n${W}Windows (official ISO)${N}"
  echo -e "${D}Examples: Windows 11 Pro | Windows 10 Pro | Windows 11 Enterprise LTSC 2024${N}"
  echo -e "${D}          Windows Server 2022 ServerStandard | Windows Server 2025 ServerDatacenter${N}"
  ask "Image name" name "Windows 11 Pro"
  ask "Language (en-us, fr-fr, zh-cn, ...)" lang "en-us"
  ask "ISO link (Enter = let the engine find it)" iso
  ARGS=(windows --image-name "$name" --lang "$lang")
  [ -n "$iso" ] && ARGS+=(--iso "$iso")
  ask "RDP port" rdp
  if [ -n "$rdp" ]; then
    [[ "$rdp" =~ ^[0-9]+$ ]] && (( rdp >= 1 && rdp <= 65535 )) && ARGS+=(--rdp-port "$rdp") || warn "Invalid RDP port, skipped."
  fi
  ask "Allow ping in the firewall? (y/N)" ping "N"
  [[ "$ping" =~ ^[Yy]$ ]] && ARGS+=(--allow-ping)
  common_options no
  confirm_run destructive || return 1
  run_engine
}

flow_dd() {
  local img
  echo -e "\n${W}DD a raw image to the disk${N}"
  echo -e "${D}Supports raw/vhd, also .gz .xz .zst .tar(.gz/.xz/.zst)${N}"
  ask "Image link" img
  [ -n "$img" ] || { warn "A link is required."; return 1; }
  ARGS=(dd --img "$img")
  common_options yes
  confirm_run destructive || return 1
  run_engine
}

flow_live() {
  ARGS=(alpine --hold 1)
  echo -e "\n${W}Alpine Live OS${N}  ${D}(boots in memory; reboot again to return to your old system)${N}"
  common_options yes
  confirm_run safe || return 1
  run_engine
}

flow_netboot() {
  ARGS=(netboot.xyz)
  echo -e "\n${W}netboot.xyz${N}  ${D}(install other systems by hand from the provider VNC)${N}"
  confirm_run safe || return 1
  run_engine
}

flow_reset() {
  ARGS=(reset)
  echo -e "\n${W}Cancel a pending reinstall${N}  ${D}(only works before the reboot)${N}"
  confirm_run safe || return 1
  run_engine
}

main_menu() {
  local choice
  while true; do
    echo
    echo -e "${B}════════════════════════════════════════════${N}"
    echo -e "${W}        ONE-CLICK OS REINSTALL (wavy07)${N}"
    echo -e "${B}════════════════════════════════════════════${N}"
    print_list
    printf ' %s 0)%s Exit\n\n' "$Y" "$N"
    ask "Select the system to install" choice
    if [ "$choice" = "0" ]; then exit 0; fi
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if (( choice >= 1 && choice <= NLINUX )); then flow_linux $((choice - 1)); continue; fi
      case "$choice" in
        "$I_WIN")     flow_windows; continue ;;
        "$I_DD")      flow_dd; continue ;;
        "$I_LIVE")    flow_live; continue ;;
        "$I_NETBOOT") flow_netboot; continue ;;
        "$I_RESET")   flow_reset; continue ;;
      esac
    fi
    warn "Invalid choice."
  done
}

# ----------------------------------------------------------------- start
case "${1:-}" in
  -h|--help)
    sed -n '2,22p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  --list|list)
    print_list; exit 0 ;;
esac

check_env

if [ "$#" -gt 0 ]; then
  # direct mode: the arguments go to the engine as they are
  ARGS=("$@")
  if [ "$1" = "reset" ]; then confirm_run safe || exit 1; else confirm_run destructive || exit 1; fi
  run_engine
  exit $?
fi

main_menu
