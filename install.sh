#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_NAME="FL Solutions Debian/Proxmox Bootstrap"
MARKER_NAME="FL SOLUTIONS MANAGED BLOCK"
BEGIN_MARKER="# BEGIN ${MARKER_NAME}"
END_MARKER="# END ${MARKER_NAME}"
BACKUP_SUFFIX="fl-solutions"
LOG_FILE="/tmp/fl-solutions-bootstrap.log"

APPLY=0
ASSUME_YES=0
SYSTEM_SCOPE=0

REQUIRED_PACKAGES=(
  apt-transport-https
  bash-completion
  ca-certificates
  curl
  dnsutils
  fzf
  git
  grc
  htop
  iftop
  iotop
  iproute2
  jq
  lsof
  mtr-tiny
  ncdu
  net-tools
  nload
  rsync
  screen
  strace
  tcpdump
  tmux
  traceroute
  tree
  unzip
  vim
  wget
  zip
)

OPTIONAL_PACKAGES=(
  bat
  btop
  fd-find
  lsd
  ripgrep
)

usage() {
  cat <<'EOF'
FL Solutions Debian/Proxmox Bootstrap

Usage:
  ./install.sh [options]

Options:
  --apply          Apply changes. Without this, the script only shows a dry-run.
  --yes            Do not ask for interactive confirmation. Requires --apply.
  --system         Also manage /etc/bash.bashrc. Default: current user's ~/.bashrc only.
  --help           Show this help.

Examples:
  ./install.sh
  ./install.sh --apply
  sudo ./install.sh --apply --system
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >/dev/null
}

info() {
  printf '[INFO] %s\n' "$*"
  log "INFO $*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
  log "WARN $*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  log "ERROR $*"
  exit 1
}

is_root() {
  [[ "${EUID}" -eq 0 ]]
}

detect_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
    OS_PRETTY="${PRETTY_NAME:-unknown}"
  else
    OS_ID="unknown"
    OS_VERSION="unknown"
    OS_PRETTY="unknown"
  fi

  if command -v pveversion >/dev/null 2>&1; then
    IS_PROXMOX=1
    PROXMOX_VERSION="$(pveversion 2>/dev/null || true)"
  else
    IS_PROXMOX=0
    PROXMOX_VERSION=""
  fi

  if command -v apt-get >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1; then
    HAS_APT=1
  else
    HAS_APT=0
  fi
}

parse_args() {
  while (($#)); do
    case "$1" in
      --apply)
        APPLY=1
        ;;
      --yes|-y)
        ASSUME_YES=1
        ;;
      --system)
        SYSTEM_SCOPE=1
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done

  if [[ "$ASSUME_YES" -eq 1 && "$APPLY" -ne 1 ]]; then
    die "--yes requires --apply"
  fi
}

check_supported_host() {
  if [[ "$HAS_APT" -eq 1 ]]; then
    return 0
  fi

  warn "APT/dpkg not found. This project targets Debian/Proxmox hosts."

  if [[ "$APPLY" -eq 1 ]]; then
    die "Refusing to apply on a non-APT host"
  fi
}

confirm_apply() {
  if [[ "$APPLY" -ne 1 ]]; then
    return 0
  fi

  cat <<'EOF'

Impact warning:
- This script can install APT packages.
- This script can edit shell startup files using a managed block.
- It does not run apt upgrade, dist-upgrade, full-upgrade or autoremove.
- It does not change Proxmox repositories, network, storage, cluster, firewall or services.
- Review the dry-run output before applying on production servers.
EOF

  if [[ "$ASSUME_YES" -eq 1 ]]; then
    return 0
  fi

  read -r -p "Type APPLY to continue: " answer
  [[ "$answer" == "APPLY" ]] || die "Aborted by user"
}

package_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

package_available() {
  apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}' | grep -qv '^(none)$'
}

collect_packages() {
  PACKAGES_TO_INSTALL=()
  PACKAGES_INSTALLED=()
  PACKAGES_UNAVAILABLE=()
  OPTIONAL_INSTALLED=()
  OPTIONAL_AVAILABLE=()
  OPTIONAL_UNAVAILABLE=()

  for package in "${REQUIRED_PACKAGES[@]}"; do
    if package_installed "$package"; then
      PACKAGES_INSTALLED+=("$package")
    elif package_available "$package"; then
      PACKAGES_TO_INSTALL+=("$package")
    else
      PACKAGES_UNAVAILABLE+=("$package")
    fi
  done

  for package in "${OPTIONAL_PACKAGES[@]}"; do
    if package_installed "$package"; then
      OPTIONAL_INSTALLED+=("$package")
    elif package_available "$package"; then
      OPTIONAL_AVAILABLE+=("$package")
    else
      OPTIONAL_UNAVAILABLE+=("$package")
    fi
  done
}

print_list() {
  local title="$1"
  shift

  printf '\n%s\n' "$title"
  if (($# == 0)); then
    printf '  none\n'
    return
  fi

  local item
  for item in "$@"; do
    printf '  - %s\n' "$item"
  done
}

managed_block() {
  cat <<'EOF'
# FL Solutions: safer Bash history and daily admin helpers.
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=50000
export HISTFILESIZE=100000
shopt -s histappend

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
elif [[ -r /etc/bash_completion ]]; then
  . /etc/bash_completion
fi

if [[ -r /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  . /usr/share/doc/fzf/examples/key-bindings.bash
fi

if command -v grc >/dev/null 2>&1; then
  alias ping='grc ping'
  alias traceroute='grc traceroute'
  alias mtr='grc mtr'
  alias tail='grc tail'
  alias ps='grc ps'
fi

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c'
EOF
}

target_files() {
  printf '%s\n' "${HOME}/.bashrc"
  if [[ "$SYSTEM_SCOPE" -eq 1 ]]; then
    printf '%s\n' "/etc/bash.bashrc"
  fi
}

backup_file() {
  local file="$1"
  local timestamp backup

  [[ -e "$file" ]] || return 0
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  backup="${file}.bak.${BACKUP_SUFFIX}-${timestamp}"
  cp -a "$file" "$backup"
  info "Backup created: $backup"
}

write_managed_block() {
  local file="$1"
  local tmp

  if [[ ! -e "$file" ]]; then
    install -m 0644 /dev/null "$file"
  fi

  if grep -Fq "$BEGIN_MARKER" "$file" && ! grep -Fq "$END_MARKER" "$file"; then
    die "Managed block in $file has begin marker but no end marker"
  fi

  tmp="$(mktemp)"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin {skip = 1; next}
    $0 == end {skip = 0; next}
    skip != 1 {print}
  ' "$file" > "$tmp"

  {
    cat "$tmp"
    printf '\n%s\n' "$BEGIN_MARKER"
    managed_block
    printf '%s\n' "$END_MARKER"
  } > "$file"

  rm -f "$tmp"
}

check_existing_shell_customizations() {
  local file="$1"

  [[ -r "$file" ]] || return 0

  if grep -Eq 'fzf|bash_completion|grc|HISTCONTROL|HISTSIZE|alias (ping|tail|ps|ip|grep)=' "$file"; then
    warn "Existing shell customizations found in $file. The script will only manage its own marked block."
  fi
}

install_packages() {
  if ((${#PACKAGES_TO_INSTALL[@]} == 0)); then
    info "No required packages to install"
    return 0
  fi

  if [[ "$APPLY" -ne 1 ]]; then
    info "Dry-run: would run apt-get update"
    info "Dry-run: would install: ${PACKAGES_TO_INSTALL[*]}"
    return 0
  fi

  is_root || die "Package installation requires root. Re-run with sudo or run dry-run only."
  apt-get update
  apt-get install -y --no-install-recommends "${PACKAGES_TO_INSTALL[@]}"
}

apply_shell_config() {
  local file

  while IFS= read -r file; do
    check_existing_shell_customizations "$file"

    if [[ "$APPLY" -ne 1 ]]; then
      info "Dry-run: would backup and manage block in $file"
      continue
    fi

    if [[ "$file" == /etc/* ]]; then
      is_root || die "Editing $file requires root. Re-run with sudo or omit --system."
    fi

    backup_file "$file"
    write_managed_block "$file"
    bash -n "$file" || die "Bash syntax validation failed for $file"
    info "Managed block applied: $file"
  done < <(target_files)
}

validate_environment() {
  local failures=0
  local command_name

  for command_name in grc fzf curl git bash; do
    if command -v "$command_name" >/dev/null 2>&1; then
      info "Validation ok: command found: $command_name"
    else
      warn "Validation failed: command not found: $command_name"
      failures=$((failures + 1))
    fi
  done

  if [[ "$SYSTEM_SCOPE" -eq 1 && -r /etc/bash.bashrc ]]; then
    bash -n /etc/bash.bashrc || failures=$((failures + 1))
  fi

  if [[ -r "${HOME}/.bashrc" ]]; then
    bash -n "${HOME}/.bashrc" || failures=$((failures + 1))
  fi

  if [[ "$failures" -gt 0 ]]; then
    warn "Validation finished with $failures warning(s)"
  else
    info "Validation finished successfully"
  fi
}

main() {
  parse_args "$@"
  : > "$LOG_FILE"

  detect_os
  check_supported_host

  printf '%s\n' "$PROJECT_NAME"
  printf 'Mode: %s\n' "$([[ "$APPLY" -eq 1 ]] && printf apply || printf dry-run)"
  printf 'OS: %s\n' "$OS_PRETTY"
  printf 'Proxmox detected: %s\n' "$([[ "$IS_PROXMOX" -eq 1 ]] && printf yes || printf no)"
  if [[ "$IS_PROXMOX" -eq 1 ]]; then
    printf 'Proxmox version: %s\n' "$PROXMOX_VERSION"
  fi

  collect_packages

  print_list "Required packages already installed:" "${PACKAGES_INSTALLED[@]}"
  print_list "Required packages to install:" "${PACKAGES_TO_INSTALL[@]}"
  print_list "Required packages unavailable:" "${PACKAGES_UNAVAILABLE[@]}"
  print_list "Optional packages already installed:" "${OPTIONAL_INSTALLED[@]}"
  print_list "Optional packages available but not installed by default:" "${OPTIONAL_AVAILABLE[@]}"
  print_list "Optional packages unavailable:" "${OPTIONAL_UNAVAILABLE[@]}"

  print_list "Shell files in scope:" "$(target_files)"

  confirm_apply
  install_packages
  apply_shell_config

  if [[ "$APPLY" -eq 1 ]]; then
    validate_environment
  else
    info "Dry-run complete. Re-run with --apply after reviewing the output."
  fi

  info "Log file: $LOG_FILE"
}

main "$@"
