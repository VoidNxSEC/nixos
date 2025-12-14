#!/usr/bin/env bash
# Quick alias: intel-dev - Scan ~/dev/Projects

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SCRIPT_DIR/intel.sh" dev "$@"
