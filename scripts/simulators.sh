#!/usr/bin/env bash
# Telly's OWN simulator devices. The Mac mini hosts several repos' runners that
# all pick simulators by stock name ("iPhone 17 Pro"); two UI-test jobs on the
# same device fight over the foreground app and every scenario fails for reasons
# that are not the app's. A dedicated device per platform (created on first use
# from the newest installed runtime) makes the acceptance runs independent of
# whatever else the host is doing — deterministic, never retried.
#
#   source scripts/simulators.sh
#   DEST=$(telly_destination ios)    # -> "id=<UDID>"
#   telly_warm "$DEST"               # boot + settle before an XCUITest run
set -euo pipefail

telly_device_name() { case "$1" in ios) echo "Telly CI iPhone" ;; tvos) echo "Telly CI Apple TV" ;; esac; }
telly_device_type() { case "$1" in ios) echo "iPhone 17 Pro" ;; tvos) echo "Apple TV 4K (3rd generation)" ;; esac; }
telly_runtime_prefix() { case "$1" in ios) echo "iOS" ;; tvos) echo "tvOS" ;; esac; }

# UDID of the dedicated device for ios|tvos, creating it when missing.
telly_udid() {
  local name type rt_prefix udid type_id runtime_id
  name=$(telly_device_name "$1"); type=$(telly_device_type "$1"); rt_prefix=$(telly_runtime_prefix "$1")
  udid=$({ xcrun simctl list devices available | grep -F "$name (" || true; } | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
  if [ -z "$udid" ]; then
    type_id=$(xcrun simctl list devicetypes | grep -F "$type (com.apple" | head -1 | sed -E 's/.*\((com[^)]*)\).*/\1/')
    runtime_id=$(xcrun simctl list runtimes available | grep "^$rt_prefix " | tail -1 | sed -E 's/.* - (com[^ ]*).*/\1/')
    udid=$(xcrun simctl create "$name" "$type_id" "$runtime_id")
    echo "   created simulator “$name” ($type, $runtime_id)" >&2
  fi
  printf '%s' "$udid"
}

# An xcodebuild -destination for ios|tvos: the dedicated device by id.
telly_destination() { printf 'id=%s' "$(telly_udid "$1")"; }

# Boot the destination and wait until it is fully up: a fresh XCUITest runner on
# a still-booting simulator can hang its first accessibility query.
telly_warm() {
  local udid; udid=${1#id=}
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
  sleep 10
}
