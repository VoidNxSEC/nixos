# vmctl Module (DISABLED - project moved externally)
# Re-enable when vmctl is available as flake input
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.vmctl;
in
{
  options.programs.vmctl = {
    enable = mkEnableOption "vmctl - Lightweight QEMU VM Manager";
    package = mkOption {
      type = types.package;
      default = pkgs.hello; # Placeholder until flake input available
      description = "The vmctl package to install.";
    };
    vms = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = true;
            };
            image = mkOption {
              type = types.str;
              description = "Path to VM disk image.";
            };
            memory = mkOption {
              type = types.str;
              default = "4G";
            };
            cpus = mkOption {
              type = types.int;
              default = 2;
            };
            network = mkOption {
              type = types.str;
              default = "user";
            };
            display = mkOption {
              type = types.enum [
                "gtk"
                "sdl"
                "spice"
                "none"
              ];
              default = "gtk";
            };
          };
        }
      );
      default = { };
      description = "VM configuration definitions.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.qemu
      pkgs.qemu_kvm
    ];
    environment.etc."vmctl/config.toml".text =
      let
        vmToToml = name: vm: ''
          [vm.${name}]
          enabled = ${boolToString vm.enabled}
          image = "${vm.image}"
          memory = "${vm.memory}"
          cpus = ${toString vm.cpus}
          network = "${vm.network}"
          display = "${vm.display}"
        '';
      in
      concatStringsSep "\n" (mapAttrsToList vmToToml cfg.vms);
    systemd.tmpfiles.rules = [ "d /run/vmctl 0755 root root -" ];
  };
}
