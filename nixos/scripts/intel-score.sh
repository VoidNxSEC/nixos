#!/usr/bin/env bash
# Quick alias: intel-score - Get viability score

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SCRIPT_DIR/intel.sh" score "${1:-.}" "${@:2}"
