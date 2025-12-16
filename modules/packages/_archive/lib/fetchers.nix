# Shared Fetcher Functions for Package Modules
# Purpose: Unified fetch and extract logic for all package types
{ pkgs, lib }:

with lib;

rec {
  # =============================================================================
  # GENERIC SOURCE FETCHER
  # =============================================================================
  # Fetches from URL or uses local path
  fetchSource =
    name: source: ext:
    if source.path != null then
      source.path
    else if source.url != null then
      pkgs.fetchurl {
        url = source.url;
        sha256 = source.sha256;
        name = "${name}.${ext}";
      }
    else
      throw "Package ${name}: Either 'path' or 'url' must be specified in source";

  # =============================================================================
  # DEB EXTRACTION
  # =============================================================================
  extractDeb =
    name: debFile:
    pkgs.runCommand "${name}-extracted"
      {
        buildInputs = [
          pkgs.binutils
          pkgs.gzip
        ];
      }
      ''
        mkdir -p $out
        local tmp_dir=$(mktemp -d)
        cd "$tmp_dir"

        # Extract data.tar.xz from .deb (ar archive)
        ar x "${debFile}"
        tar --no-same-permissions --no-same-owner -xJf data.tar.xz -C "$out"

        # Remove setuid bit from chrome-sandbox (Electron apps)
        find "$out" -type f -name "chrome-sandbox" -exec chmod -s {} + 2>/dev/null || true
      '';

  # =============================================================================
  # TARBALL EXTRACTION
  # =============================================================================
  extractTarball =
    name: tarFile:
    pkgs.runCommand "${name}-extracted"
      {
        buildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];
      }
      ''
        mkdir -p $out
        tar -xzf ${tarFile} -C $out

        # If extraction created a single directory, move contents up
        if [ $(ls -A $out | wc -l) -eq 1 ] && [ -d $out/* ]; then
          mv $out/*/* $out/ 2>/dev/null || true
          rmdir $out/*/ 2>/dev/null || true
        fi
      '';

  # =============================================================================
  # BINARY DETECTION HELPERS
  # =============================================================================
  detectDynamicLinking =
    binary:
    pkgs.runCommand "check-dynamic"
      {
        buildInputs = [
          pkgs.file
          pkgs.glibc.bin
        ];
      }
      ''
        if [ ! -f "${binary}" ]; then
          echo "unknown" > $out
          exit 0
        fi
        if file "${binary}" | grep -q "dynamically linked"; then
          echo "dynamic" > $out
        elif file "${binary}" | grep -q "statically linked"; then
          echo "static" > $out
        else
          echo "unknown" > $out
        fi
      '';

  detectTargetTriple =
    execName:
    if lib.hasSuffix "-musl" execName then
      "musl"
    else if lib.hasSuffix "-gnu" execName then
      "gnu"
    else if lib.hasInfix "musl" execName then
      "musl"
    else if lib.hasInfix "gnu" execName then
      "gnu"
    else
      "unknown";
}
