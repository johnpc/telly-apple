#!/usr/bin/env bash
# Install the repo's git hooks by pointing core.hooksPath at the tracked
# `scripts` directory (git runs only files named after a hook — `pre-commit`).
# Using core.hooksPath (rather than copying into .git/hooks) means the hook can
# never go stale relative to the version-controlled script.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

chmod +x scripts/pre-commit
git config core.hooksPath scripts
echo "✅ Installed git hooks (core.hooksPath=$(git config core.hooksPath))"
echo "   pre-commit runs: line-limit → gherkin sync → unit tests → build"
