{
  description = "Laptop Defense Framework - Hardware Forensics Suite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  # Phase 5 split: each tool lives in ./apps/<name>.nix; the thermal
  # protection NixOS module lives in ./thermal-protection.nix.
  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      thermalForensics = import ./apps/thermal-forensics.nix { inherit pkgs; };
      mcpLogExtractor = import ./apps/mcp-log-extract.nix { inherit pkgs; };
      thermalMonitor = import ./apps/thermal-warroom.nix { inherit pkgs; };
      decisionFramework = import ./apps/laptop-verdict.nix { inherit pkgs; };
      fullInvestigation = import ./apps/laptop-investigation.nix {
        inherit
          pkgs
          thermalForensics
          mcpLogExtractor
          decisionFramework
          ;
      };
    in
    {
      packages.${system} = {
        inherit
          thermalForensics
          mcpLogExtractor
          thermalMonitor
          decisionFramework
          fullInvestigation
          ;
      };

      apps.${system} = {
        thermal-forensics = {
          type = "app";
          program = "${thermalForensics}/bin/thermal-forensics";
        };

        thermal-warroom = {
          type = "app";
          program = "${thermalMonitor}/bin/thermal-warroom";
        };

        mcp-extract = {
          type = "app";
          program = "${mcpLogExtractor}/bin/mcp-log-extract";
        };

        verdict = {
          type = "app";
          program = "${decisionFramework}/bin/laptop-verdict";
        };

        full-investigation = {
          type = "app";
          program = "${fullInvestigation}/bin/laptop-investigation";
        };
      };

      # NixOS module for thermal protection
      nixosModules.thermalProtection = import ./thermal-protection.nix {
        defensePackages = self.packages.${system};
      };
    };
}
