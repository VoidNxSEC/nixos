# overlays/weston-patch-fix.nix
# Fix for weston-14.0.1 build failure on nixpkgs 26.05
#
# Problem: nixpkgs records hash sha256-mkIOup44C9Kp42tFMXz8Sis4URmPi4t605MQG672nJU=
#          but GitLab now serves different content for the same commit patch URL
#          (likely metadata/format change), resulting in a hash mismatch.
# Fix: Override the patch with the hash that GitLab actually serves today.
# Patch: vnc: Allow neatvnc 0.9.0 (weston MR#1649)
# Date: 2026-02-21

final: prev: {
  weston = prev.weston.overrideAttrs (_old: {
    patches = [
      (prev.fetchpatch2 {
        url = "https://gitlab.freedesktop.org/wayland/weston/-/commit/b4386289d614f26e89e1c6eb17e048826e925ed1.patch";
        hash = "sha256-j3UnX/KeWg4dbedKip/O74lNP0qmlfUruKXM5GKjx/s=";
      })
    ];
  });
}
