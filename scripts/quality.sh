#!/usr/bin/env bash
# Full local quality gate for telly-apple — the same checks CI enforces, in one
# command: source-line limit, Gherkin sync, static checks (dead code,
# duplication, banned types, Halstead ≤20), unit tests + coverage ≥80%,
# the Gherkin acceptance suite (XCUITest over the in-process demo provider —
# no server, no network), CRAP ≤30, and a clean build on BOTH platforms.
#
# There is no such thing as a flaky test: every gate here must pass on every
# run. A test that fails intermittently is a bug in the test or the code and
# gets fixed (made deterministic) — never retried, skipped or quarantined.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SCHEME="Telly"
DESTINATION="${TELLY_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
TVOS_DESTINATION="${TELLY_TVOS_DESTINATION:-platform=tvOS Simulator,name=Apple TV 4K (3rd generation)}"
RESULT="TestResults.xcresult"

# `xcodebuild -quiet` prints a spurious "error: the following command failed with
# exit code 0 but produced no further output" for silent sub-steps. Drop exactly
# those lines; `awk` always exits 0 so `pipefail` still reports xcodebuild's own
# status (the gate is never masked).
xcb() { xcodebuild "$@" 2>&1 | awk '!/exit code 0 but produced no further output/'; }

# The XCUITest runner is a fresh install on every run; on a simulator that is
# still settling after boot (SpringBoard/widget daemons churning) its first
# accessibility queries can hang and xcodebuild restarts the runner mid-scenario.
# Boot the destination and wait for it to be fully up BEFORE the acceptance phase.
# The Mac mini hosts several repos' runners. XCUITest on a simulator that shares
# the host with other simulator-heavy jobs (parallel clones, emulators) has its
# CoreSimulator services die ("ipc/mig server died"). Wait — bounded — for the
# host to be quiet before starting the acceptance phase; if it never is, proceed.
wait_for_quiet_host() {
  local waited=0
  while [ "$waited" -lt 900 ]; do
    # `set -euo pipefail`-safe: pgrep exits 1 when nothing matches, so it is braced;
    # awk/wc never fail. Our own xcodebuild (this script's child) is not running yet.
    others=$({ pgrep -f "xcodebuild test" || true; } | awk -v me="$$" '$1 != me' | wc -l | tr -d ' ')
    load=$(sysctl -n vm.loadavg | awk '{print int($2)}')
    [ "$others" -le 1 ] && [ "$load" -lt 24 ] && return 0
    [ "$waited" -eq 0 ] && echo "   waiting for a quiet simulator host (xcodebuild test procs=$others load=$load)…"
    sleep 30; waited=$((waited + 30))
  done
  echo "   host still busy after 15 min — proceeding anyway"
}

warm_simulator() {
  local name udid
  name=$(printf '%s' "$1" | sed -n 's/.*name=\([^,]*\).*/\1/p')
  udid=$({ xcrun simctl list devices available | grep "$name (" || true; } | awk '!/Clone/' | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
  [ -n "$udid" ] || return 0
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
  sleep 10
}

echo "▶ [1/8] Source file line limit (≤100)"
bash scripts/check_source_lines.sh

echo "▶ [2/8] Acceptance tests generated from .feature files are in sync"
python3 scripts/generate_acceptance_tests.py --check

echo "▶ [3/8] Static checks: dead code, duplication, banned types, Halstead"
python3 scripts/dead_code_check.py
python3 scripts/duplication_check.py
python3 scripts/banned_types_check.py
python3 scripts/halstead_check.py

echo "▶ [4/8] Unit tests + coverage (iOS)"
rm -rf "$RESULT"
xcb test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:"TellyTests" \
  -derivedDataPath DerivedData \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT" \
  -quiet
xcrun xccov view --report --json "$RESULT" > coverage.json

echo "▶ [5/8] Acceptance tests (iOS) — Gherkin scenarios over the built-in demo provider"
wait_for_quiet_host
warm_simulator "$DESTINATION"
xcb test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:"TellyUITests" \
  -derivedDataPath DerivedData \
  -quiet

echo "▶ [6/8] Coverage threshold (≥80%) + CRAP (≤30)"
python3 scripts/coverage_check.py coverage.json
python3 scripts/crap_check.py coverage.json

echo "▶ [7/8] Build app (iOS)"
xcb build \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath DerivedData \
  -quiet

echo "▶ [8/8] Build app (tvOS)"
xcb build \
  -scheme "$SCHEME" \
  -destination "$TVOS_DESTINATION" \
  -derivedDataPath DerivedData \
  -quiet

echo "✅ Quality gate passed"
