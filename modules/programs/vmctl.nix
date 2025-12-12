{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.vmctl;
  
  # Import vmctl from local projects directory
  packageSource = ../../projects/vmctl;
  
  vmctl = pkgs.buildGoModule {
    pname = "vmctl";
    version = "0.1.0";
    src = packageSource;
    vendorHash = null;
    
    nativeBuildInputs = with pkgs; [
      pkg-config
    ];
    
    buildInputs = with pkgs; [
      # GTK4 for optional GUI
      gtk4
      glib
    ];
    
    ldflags = [ "-s" "-w" ];
    
    meta = with pkgs.lib; {
      description = "Lightweight VM manager with optional GTK4 GUI";
      homepage = "https://github.com/VoidNxSEC/vmctl";
      license = licenses.mit;
      mainProgram = "vmctl";
    };
  };
in {
  options.programs.vmctl = {
    enable = mkEnableOption "vmctl - Lightweight QEMU VM Manager";

    package = mkOption {
      type = types.package;
      default = vmctl;
      description = "The vmctl package to install.";
    };

    # VM Configuration
    vms = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this VM is enabled.";
          };
          
          image = mkOption {
            type = types.str;
            description = "Path to the VM disk image (qcow2).";
          };
          
          memory = mkOption {
            type = types.str;
            default = "4G";
            description = "Memory allocation (e.g., '4G', '2048M').";
          };
          
          cpus = mkOption {
            type = types.int;
            default = 2;
            description = "Number of virtual CPUs.";
          };
          
          network = mkOption {
            type = types.str;
            default = "user";
            description = "Network mode: 'user' (NAT) or 'bridge:<name>'.";
          };
          
          display = mkOption {
            type = types.enum [ "gtk" "sdl" "spice" "none" ];
            default = "gtk";
            description = "Display mode for the VM.";
          };
        };
      });
      default = {};
      description = "VM configuration definitions.";
    };
  };

  config = mkIf cfg.enable {
    # Install vmctl binary
    environment.systemPackages = [ 
      cfg.package 
      pkgs.qemu
      pkgs.qemu_kvm
    ];
    
    # Generate TOML config from Nix definitions
    environment.etc."vmctl/config.toml".text = let
      vmToToml = name: vm: ''
        [vm.${name}]
        enabled = ${boolToString vm.enabled}
        image = "${vm.image}"
        memory = "${vm.memory}"
        cpus = ${toString vm.cpus}
        network = "${vm.network}"
        display = "${vm.display}"
      '';
    in concatStringsSep "\n" (mapAttrsToList vmToToml cfg.vms);
    
    # Ensure runtime directory exists
    systemd.tmpfiles.rules = [
      "d /run/vmctl 0755 root root -"
    ];
  };
}
