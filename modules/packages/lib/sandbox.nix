{ lib }:

with lib;

# ═══════════════════════════════════════════════════════════════
# SANDBOX LIBRARY - Bubblewrap Helper Functions
# ═══════════════════════════════════════════════════════════════
# Purpose: Generate bubblewrap arguments for hardware blocking and path access
# Used by: js-packages builder.nix
# ═══════════════════════════════════════════════════════════════

{
  # Generate hardware blocking arguments for bubblewrap
  mkHardwareBlockArgs =
    blockList:
    let
      blockMap = {
        gpu = "--dev-bind /dev/null /dev/dri";
        audio = "--dev-bind /dev/null /dev/snd";
        camera = "--dev-bind /dev/null /dev/video0";
        bluetooth = "--ro-bind /dev/null /sys/class/bluetooth";
        usb = "--dev-bind /dev/null /dev/bus/usb";
      };

      blockedArgs = map (hw: blockMap.${hw} or "") blockList;
    in
    concatStringsSep " " (filter (s: s != "") blockedArgs);

  # Generate path allow arguments for bubblewrap
  mkPathAllowArgs =
    pathList:
    let
      # Expand environment variables in paths
      expandPath =
        path: if hasInfix "$HOME" path then replaceStrings [ "$HOME" ] [ "\${HOME}" ] path else path;

      allowArgs = map (path: "--bind ${expandPath path} ${expandPath path}") pathList;
    in
    concatStringsSep " " allowArgs;
}
