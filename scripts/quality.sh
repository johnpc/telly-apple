#!/usr/bin/env bash
# Full local quality gate for telly-apple — the same checks CI enforces, in one
# command: source-line limit, Gherkin sync, static checks (dead code,
# duplication, banned types, Halstead ≤20), unit tests + coverage ≥80%,
# CRAP ≤30, and a clean build on BOTH platforms (iOS + tvOS).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SCHEME="Telly"
DESTINATION="${TELLY_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
TVOS_DESTINATION="${TELLY_TVOS_DESTINATION:-platform=tvOS Simulator,name=Apple TV 4K (3rd generation),OS=26.5}"
RESULT="TestResults.xcresult"

echo "▶ [1/7] Source file line limit (≤100)"
bash scripts/check_source_lines.sh

echo "▶ [2/7] Acceptance tests generated from .feature files are in sync"
python3 scripts/generate_acceptance_tests.py --check

echo "▶ [3/7] Static checks: dead code, duplication, banned types, Halstead"
python3 scripts/dead_code_check.py
python3 scripts/duplication_check.py
python3 scripts/banned_types_check.py
python3 scripts/halstead_check.py

echo "▶ [4/7] Unit tests + coverage (iOS)"
rm -rf "$RESULT"
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:"TellyTests" \
  -derivedDataPath DerivedData \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT" \
  -quiet
xcrun xccov view --report --json "$RESULT" > coverage.json

echo "▶ [5/7] Coverage threshold (≥80%) + CRAP (≤30)"
python3 scripts/coverage_check.py coverage.json
python3 scripts/crap_check.py coverage.json

echo "▶ [6/7] Build app (iOS)"
xcodebuild build \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath DerivedData \
  -quiet

echo "▶ [7/7] Build app (tvOS)"
xcodebuild build \
  -scheme "$SCHEME" \
  -destination "$TVOS_DESTINATION" \
  -derivedDataPath DerivedData \
  -quiet

echo "✅ Quality gate passed"
