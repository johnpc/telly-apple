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
