#!/usr/bin/env bash
# Quick alias: intel-scan - Scan multiple projects

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SCRIPT_DIR/intel.sh" scan "${1:-$HOME/dev/Projects}" "${@:2}"
