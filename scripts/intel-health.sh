#!/usr/bin/env bash
# Quick alias: intel-health - Quick health check

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SCRIPT_DIR/intel.sh" health "${1:-.}" "${@:2}"
