#!/bin/bash
# OpenSpec wrapper script for TemporalEcho project
# Usage: ./openspec.sh [command] [options]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENSPEC_CLI="/home/sdon/.openclaw/workspace/OpenSpec/dist/cli/index.js"

cd "$SCRIPT_DIR"
env -u NODE_OPTIONS node "$OPENSPEC_CLI" "$@"
