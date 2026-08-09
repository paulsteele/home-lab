#!/bin/sh
set -eu

SNIPPETS_DIR=${SNIPPETS_DIR:-/etc/ser2net/snippets}
found=0

for tty_path in /sys/class/tty/*; do
  [ -e "$tty_path" ] || continue
  tty=$(basename "$tty_path")

  case "$tty" in
    ttyS[0-9]*|ttyHS[0-9]*|ttyUSB[0-9]*|ttyACM[0-9]*|ttyAMA[0-9]*|rfcomm[0-9]*|ttyO[0-9]*|ttymxc[0-9]*) ;;
    *) continue ;;
  esac

  real_device=$(readlink -f "$tty_path/device" 2>/dev/null || true)
  [ -n "$real_device" ] || continue
  [ -d "$real_device" ] || continue

  # Multi-interface USB serial devices, such as the HUSBZB-1, expose the
  # same vendor/product IDs for each endpoint. Prefer the interface-specific
  # mapping and retain the old vendor/product-only fallback for single-port
  # devices.
  interface_number=$(cat "$real_device/bInterfaceNumber" 2>/dev/null || true)
  if [ -z "$interface_number" ]; then
    interface_number=$(cat "$(dirname "$real_device")/bInterfaceNumber" 2>/dev/null || true)
  fi

  subsystem=$(basename "$(readlink -f "$real_device/subsystem" 2>/dev/null || true)")
  case "$subsystem" in
    usb-serial) usbdir=$(dirname "$(dirname "$real_device")") ;;
    usb) usbdir=$(dirname "$real_device") ;;
    *) continue ;;
  esac

  [ -f "$usbdir/idProduct" ] || continue
  [ -f "$usbdir/idVendor" ] || continue
  product_id=$(cat "$usbdir/idProduct")
  vendor_id=$(cat "$usbdir/idVendor")
  snippet="$SNIPPETS_DIR/$vendor_id-$product_id.yaml"
  if [ -n "$interface_number" ] && [ -f "$SNIPPETS_DIR/$vendor_id-$product_id-if$interface_number.yaml" ]; then
    snippet="$SNIPPETS_DIR/$vendor_id-$product_id-if$interface_number.yaml"
  fi

  if [ -f "$snippet" ]; then
    serial_device="/dev/$tty"
    for stable_path in /dev/serial/by-id/*; do
      [ -e "$stable_path" ] || continue
      if [ "$(readlink -f "$stable_path" 2>/dev/null || true)" = "$serial_device" ]; then
        serial_device="$stable_path"
        break
      fi
    done
    sed "s#DEVNODE#$serial_device#g" "$snippet"
    printf '\n'
    found=1
  fi
done

if [ "$found" -eq 0 ]; then
  echo '# No configured USB serial devices were discovered.'
fi
