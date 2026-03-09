#!/usr/bin/env bash
set -euo pipefail

main() {
    echo "Uninstalling claude-mint..."

    rm -rf "${HOME}/.claude/skills/mint"

    echo "claude-mint uninstalled."
    echo "Restart Claude Code to complete removal."
}

main "$@"
