#!/usr/bin/env python3
"""Enforce a minimum line-coverage threshold over the app's logic files.

Reads an xccov JSON report and sums executable/covered lines for the `Telly`
app target only (test/UI-test/watch/widget targets excluded). Pure SwiftUI
view/screen files and the app entry point are excluded from measurement — they
are exercised by the Gherkin acceptance suite, not unit tests. Fails below
THRESHOLD.

Deviation from the jpc.* reference gate (documented on purpose): the reference
hardcodes an explicit `VIEW_FILES` basename allowlist. Telly is greenfield with
a strict naming convention ported from the Android app — every SwiftUI file ends
in `View.swift` or `Screen.swift` and contains no logic. So view exclusion here
is a suffix rule, not an allowlist. Logic (ViewModels / Stores / Services /
parsers / models) must be covered; naming a logic file `*View.swift` to dodge
coverage is a review-blocking smell, not a loophole to use.

Usage:
    xcrun xccov view --report --json TestResults.xcresult > coverage.json
    python3 scripts/coverage_check.py coverage.json
"""
import json
import sys

THRESHOLD = 80.0


def is_view(fname: str) -> bool:
    """A pure-rendering file excluded from unit coverage (acceptance-covered)."""
    return (
        fname.endswith("View.swift")
        or fname.endswith("Screen.swift")
        or fname == "TellyApp.swift"
    )


def measured(name: str) -> bool:
    if "Tests" in name or "UITests" in name:
        return False
    if "watch" in name.lower() or "widget" in name.lower():
        return False
    return "Telly" in name


def main(path: str) -> int:
    with open(path) as f:
        data = json.load(f)

    total_lines = 0
    covered_lines = 0
    per_file = []
    for target in data.get("targets", []):
        if not measured(target.get("name", "")):
            continue
        for file in target.get("files", []):
            fpath = file.get("path", "")
            fname = fpath.split("/")[-1]
            if is_view(fname):
                continue
            ex = file.get("executableLines", 0)
            cov = file.get("coveredLines", 0)
            total_lines += ex
            covered_lines += cov
            if ex > 0:
                per_file.append((fname, cov / ex * 100, cov, ex))

    pct = (covered_lines / total_lines * 100) if total_lines else 0.0

    per_file.sort(key=lambda r: r[1])
    print("Per-file coverage (lowest first):")
    for fname, fpct, cov, ex in per_file:
        flag = "⚠️ " if fpct < THRESHOLD else "   "
        print(f"  {flag}{fname:<40} {fpct:5.1f}%  ({cov}/{ex})")

    print(f"\nLogic file coverage: {pct:.1f}% ({covered_lines}/{total_lines} lines)")
    if pct < THRESHOLD:
        print(f"❌ FAIL: Coverage {pct:.1f}% is below {THRESHOLD:.0f}% threshold")
        return 1
    print(f"✅ PASS: Coverage {pct:.1f}% ≥ {THRESHOLD:.0f}%")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("usage: coverage_check.py <coverage.json>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
