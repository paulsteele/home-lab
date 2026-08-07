#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage: flash-talos-installer.sh [options]

Generate the Talos Image Factory ISO URL, download the ISO, and flash it to a
removable/USB disk. The target must not be mounted, read-only, active swap, or
used by any filesystem belonging to the running system.

Options:
  --config-file PATH  Talhelper configuration (default: talos/talconfig.yaml)
  --env-file PATH     Talhelper environment file (default: talos/talenv.sops.yaml)
  --disk PATH         Target disk; otherwise an interactive menu is shown
  --node HOSTNAME     Generate the image for one node when schematics differ
  --dry-run           Download and validate, but do not write the disk
  -h, --help          Show this help

Environment:
  DISK                 Same as --disk
  NODE                 Same as --node
  CONFIRM=FLASH        Skip the final confirmation prompt (checks still run)
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

config_file='talos/talconfig.yaml'
env_file='talos/talenv.sops.yaml'
requested_disk="${DISK:-}"
requested_node="${NODE:-}"
confirmation="${CONFIRM:-}"
dry_run=false

while (($# > 0)); do
  case "$1" in
    --config-file)
      (($# >= 2)) || die "--config-file requires a path"
      config_file=$2
      shift 2
      ;;
    --env-file)
      (($# >= 2)) || die "--env-file requires a path"
      env_file=$2
      shift 2
      ;;
    --disk)
      (($# >= 2)) || die "--disk requires a path"
      requested_disk=$2
      shift 2
      ;;
    --node)
      (($# >= 2)) || die "--node requires a hostname"
      requested_node=$2
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1 (use --help for usage)"
      ;;
  esac
done

for command_name in talhelper curl lsblk findmnt readlink mktemp dd sync awk sed grep; do
  require_command "$command_name"
done

if ((EUID != 0)); then
  require_command sudo
fi

if [[ ! -f "$config_file" ]]; then
  die "Talos config does not exist: $config_file"
fi
if [[ ! -f "$env_file" ]]; then
  die "Talos environment file does not exist: $env_file"
fi

# A disk is protected if it backs any mounted filesystem or active swap. This
# covers the root disk as well as separate /boot, /home, and LVM/RAID parents.
declare -a protected_disks=()

add_protected_disk() {
  local disk=$1
  local existing

  disk=$(readlink -f -- "$disk" 2>/dev/null || true)
  [[ -n "$disk" && -b "$disk" ]] || return 0

  for existing in "${protected_disks[@]}"; do
    [[ "$existing" == "$disk" ]] && return 0
  done
  protected_disks+=("$disk")
}

add_protected_source() {
  local source=$1
  local name type

  # findmnt may append a Btrfs subvolume, e.g. /dev/nvme0n1p2[/@].
  source=${source%%\[*}
  [[ -b "$source" ]] || return 0

  while read -r name type; do
    [[ "$type" == disk ]] && add_protected_disk "$name"
  done < <(lsblk -s -nrpo NAME,TYPE -- "$source" 2>/dev/null || true)
}

collect_protected_disks() {
  local source root_source root_disk_count
  protected_disks=()

  root_source=$(findmnt -n -o SOURCE / 2>/dev/null || true)
  root_source=${root_source%%\[*}
  [[ -b "$root_source" ]] || die \
    'Could not identify a block device for the running root filesystem; refusing to flash.'
  add_protected_source "$root_source"
  root_disk_count=${#protected_disks[@]}
  ((root_disk_count > 0)) || die \
    'Could not identify the disk hosting the running root filesystem; refusing to flash.'

  while IFS= read -r source; do
    [[ -n "$source" ]] && add_protected_source "$source"
  done < <(findmnt -rn -o SOURCE 2>/dev/null || true)

  if command -v swapon >/dev/null 2>&1; then
    while IFS= read -r source; do
      [[ -n "$source" ]] && add_protected_source "$source"
    done < <(swapon --show=NAME --noheadings 2>/dev/null || true)
  fi

  ((${#protected_disks[@]} > 0)) || die \
    'Could not identify the disk hosting the running system; refusing to flash.'
}

is_protected_disk() {
  local disk=$1
  local protected

  for protected in "${protected_disks[@]}"; do
    [[ "$protected" == "$disk" ]] && return 0
  done
  return 1
}

has_mounts() {
  local disk=$1
  local mountpoints

  mountpoints=$(lsblk -nrpo MOUNTPOINT -- "$disk" 2>/dev/null || true)
  [[ -n "$(printf '%s\n' "$mountpoints" | sed '/^[[:space:]]*$/d')" ]]
}

is_removable_or_usb() {
  local disk=$1
  local removable transport

  removable=$(lsblk -dnro RM -- "$disk" 2>/dev/null || true)
  transport=$(lsblk -dnro TRAN -- "$disk" 2>/dev/null || true)
  [[ "$removable" == 1 || "$transport" == usb ]]
}

is_safe_candidate() {
  local disk=$1
  local type readonly

  type=$(lsblk -dnro TYPE -- "$disk" 2>/dev/null || true)
  readonly=$(lsblk -dnro RO -- "$disk" 2>/dev/null || true)
  [[ "$type" == disk && "$readonly" == 0 ]] || return 1
  is_protected_disk "$disk" && return 1
  has_mounts "$disk" && return 1
  is_removable_or_usb "$disk"
}

canonical_disk() {
  readlink -f -- "$1" 2>/dev/null || true
}

validate_target() {
  local target=$1
  local type readonly mountpoints removable transport

  [[ -n "$target" && -b "$target" ]] || die "Not a block device: ${target:-<empty>}"

  type=$(lsblk -dnro TYPE -- "$target" 2>/dev/null || true)
  [[ "$type" == disk ]] || die "Refusing to flash a partition; select the whole disk: $target"

  collect_protected_disks
  if is_protected_disk "$target"; then
    die "Refusing to flash $target: it backs the running system, a mounted filesystem, or active swap."
  fi

  mountpoints=$(lsblk -nrpo MOUNTPOINT -- "$target" 2>/dev/null || true)
  if [[ -n "$(printf '%s\n' "$mountpoints" | sed '/^[[:space:]]*$/d')" ]]; then
    die "Refusing to flash $target because one or more partitions are mounted. Unmount them first."
  fi

  readonly=$(lsblk -dnro RO -- "$target" 2>/dev/null || true)
  [[ "$readonly" == 0 ]] || die "Refusing to flash read-only disk: $target"

  removable=$(lsblk -dnro RM -- "$target" 2>/dev/null || true)
  transport=$(lsblk -dnro TRAN -- "$target" 2>/dev/null || true)
  if [[ "$removable" != 1 && "$transport" != usb ]]; then
    die "Refusing non-removable, non-USB disk $target. Select a USB/removable disk."
  fi
}

printf 'Generating the Talos boot ISO URL...\n'
declare -a genurl_args=(
  genurl image
  --config-file "$config_file"
  --env-file "$env_file"
  --boot-method iso
  --offline-mode
)
if [[ -n "$requested_node" ]]; then
  genurl_args+=(--node "$requested_node")
fi
url_output=$(talhelper "${genurl_args[@]}" 2>&1) || {
  printf '%s\n' "$url_output" >&2
  die 'talhelper could not generate the Talos ISO URL.'
}

declare -a image_urls=()
while IFS= read -r line; do
  case "$line" in
    *': https://factory.talos.dev/image/'*)
      image_urls+=("${line#*: }")
      ;;
  esac
done <<< "$url_output"

((${#image_urls[@]} > 0)) || {
  printf '%s\n' "$url_output" >&2
  die 'No Talos ISO URL was produced.'
}

image_url=${image_urls[0]}
[[ "$image_url" == https://factory.talos.dev/image/*/*.iso ]] || \
  die "Unexpected Talos ISO URL: $image_url"

for url in "${image_urls[@]}"; do
  [[ "$url" == "$image_url" ]] || die \
    'Nodes use different ISO schematics. Re-run with NODE=<hostname> to choose one.'
done

printf 'ISO URL: %s\n' "$image_url"
iso_file=$(mktemp "${TMPDIR:-/tmp}/talos-installer.XXXXXX.iso")
cleanup() {
  rm -f -- "$iso_file"
}
trap cleanup EXIT

printf 'Downloading the ISO...\n'
curl --fail --location --retry 3 --progress-bar \
  --output "$iso_file" "$image_url"
[[ -s "$iso_file" ]] || die 'Downloaded ISO is empty.'

# Enumerate only after the download so a newly inserted USB can be selected.
collect_protected_disks

target=''
if [[ -n "$requested_disk" ]]; then
  target=$(canonical_disk "$requested_disk")
else
  declare -a candidates=()
  while read -r disk type; do
    [[ "$type" == disk ]] || continue
    if is_safe_candidate "$disk"; then
      candidates+=("$disk")
    fi
  done < <(lsblk -dnpo NAME,TYPE)

  if ((${#candidates[@]} == 0)); then
    die 'No unmounted removable/USB disks found. Insert the USB and try again.'
  fi

  printf '\nAvailable removable/USB disks:\n'
  for index in "${!candidates[@]}"; do
    printf '  [%d] ' "$((index + 1))"
    lsblk -dnro NAME,SIZE,MODEL,TRAN,RM,RO -- "${candidates[index]}"
  done
  printf 'Select a disk number (or enter a /dev/disk path): '
  IFS= read -r selection

  if [[ "$selection" =~ ^[0-9]+$ ]] &&
     ((selection >= 1 && selection <= ${#candidates[@]})); then
    target=${candidates[selection - 1]}
  else
    target=$(canonical_disk "$selection")
  fi
fi

[[ -n "$target" ]] || die 'No target disk selected.'
validate_target "$target"

printf '\nSelected target disk:\n'
lsblk -d -o NAME,SIZE,MODEL,TRAN,RM,RO -- "$target"
printf '\nThis will permanently overwrite %s with the Talos boot ISO.\n' "$target"

if [[ "$dry_run" == true ]]; then
  printf 'Dry run: disk was not written.\n'
  exit 0
fi

if [[ "$confirmation" != FLASH ]]; then
  printf 'Type FLASH to continue: '
  IFS= read -r confirmation
fi
[[ "$confirmation" == FLASH ]] || die 'Aborted.'

if ((EUID != 0)); then
  sudo -v
fi

# Re-check immediately before the destructive operation.
target=$(canonical_disk "$target")
validate_target "$target"

printf 'Flashing %s...\n' "$target"
if ((EUID == 0)); then
  dd if="$iso_file" of="$target" bs=4M status=progress conv=fsync
  sync
else
  sudo dd if="$iso_file" of="$target" bs=4M status=progress conv=fsync
  sudo sync
fi

printf '\nDone. Remove the USB and boot the machines from it into Talos maintenance mode.\n'
