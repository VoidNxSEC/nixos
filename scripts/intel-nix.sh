#!/usr/bin/env bash
# Quick alias: intel-nix - Audit NixOS configuration

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
exec "$SCRIPT_DIR/intel.sh" nix "$@"
