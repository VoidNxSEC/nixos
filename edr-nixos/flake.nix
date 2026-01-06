{
  description = "EDR-NixOS: Endpoint Detection and Response for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      nixosModules = {
        agent = import ./modules/edr/agent.nix;
        server = import ./modules/edr/server.nix;
        detection = import ./modules/edr/detection.nix;
        alerting = import ./modules/edr/alerting.nix;
        hardening-apparmor = import ./modules/hardening/apparmor.nix;
        hardening-seccomp = import ./modules/hardening/seccomp.nix;
      };
    };
}
