# overlays/libcanberra-patch-fix.nix
# Fix for libcanberra-0.30 build failure on nixpkgs 26.05
#
# Problem: nixpkgs fetches a patch from http://git.0pointer.net/libcanberra.git
#          but that cgit instance now returns an HTML page instead of the raw patch.
# Fix: Redirect the patch fetch to the Distrotech GitHub mirror which serves
#      the identical commit diff, so fetchpatch normalization yields the same hash.
# Date: 2026-02-21

final: prev: {
  libcanberra = prev.libcanberra.overrideAttrs (_old: {
    patches = [
      (prev.fetchpatch {
        name = "0001-gtk-Don-t-assume-all-GdkDisplays-are-GdkX11Displays-.patch";
        url = "https://github.com/Distrotech/libcanberra/commit/c0620e432650e81062c1967cc669829dbd29b310.patch";
        sha256 = "0rc7zwn39yxzxp37qh329g7375r5ywcqcaak8ryd0dgvg8m5hcx9";
      })
    ];
  });
}
