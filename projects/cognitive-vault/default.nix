{ pkgs ? import <nixpkgs> {} }:

let
  vaultCore = pkgs.callPackage ./core/default.nix {};
in
  pkgs.callPackage ./cli/default.nix { inherit vaultCore; }
