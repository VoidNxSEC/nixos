{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.containers.nixos.enable = mkEnableOption "Enable NixOS containers support";
  };

  config = mkIf config.kernelcore.containers.nixos.enable {
    boot.enableContainers = true;

    # ═══════════════════════════════════════════════════════════
    # LAYER 1: Host Network Configuration
    # ═══════════════════════════════════════════════════════════

    networking = {
      # NAT/Masquerading: O host vira roteador L3
      nat = {
        enable = true;

        # Interfaces "internas" (lado container)
        internalInterfaces = [ "ve-+" ]; # ← wildcard pra todos ve-*

        # Interface "externa" (lado internet)
        externalInterface = "wlp62s0"; # ← tua WiFi

        # OPCIONAL: Se quiser rotear ATRAVÉS do NordVPN quando conectado
        # externalInterface = "wgnord";
        # internalIPs = [ "192.168.100.0/24" ];
      };

      # Firewall: Confia nas interfaces dos containers
      firewall = {
        enable = true;

        # Permite tráfego livre do/pro container
        trustedInterfaces = [ "ve-+" ];

        # Se quiser acessar serviços do container do host
        allowedTCPPorts = [
          80
          443
        ];

        # Regra crítica: permite FORWARD entre interfaces
        extraCommands = ''
          # Permite containers falarem com o mundo
          iptables -A FORWARD -i ve-+ -o wlp62s0 -j ACCEPT
          iptables -A FORWARD -i wlp62s0 -o ve-+ -m state --state RELATED,ESTABLISHED -j ACCEPT

          # OPCIONAL: Roteamento via VPN
          # iptables -A FORWARD -i ve-+ -o wgnord -j ACCEPT
          # iptables -A FORWARD -i wgnord -o ve-+ -m state --state RELATED,ESTABLISHED -j ACCEPT
        '';
      };
    };

    # ═══════════════════════════════════════════════════════════
    # LAYER 2: Container Definitions
    # ═══════════════════════════════════════════════════════════

    containers.teste-preprod = {
      autoStart = true;
      privateNetwork = true;

      # Par de IPs do "cabo virtual" veth
      hostAddress = "192.168.100.10"; # ← IP do lado do host
      localAddress = "192.168.100.11"; # ← IP do lado do container

      # GPU passthrough
      bindMounts = {
        "/dev/nvidia0" = {
          hostPath = "/dev/nvidia0";
          isReadOnly = false;
        };
        "/dev/nvidiactl" = {
          hostPath = "/dev/nvidiactl";
          isReadOnly = false;
        };
        "/dev/nvidia-uvm" = {
          hostPath = "/dev/nvidia-uvm";
          isReadOnly = false;
        };
      };

      allowedDevices = [
        {
          node = "/dev/nvidia0";
          modifier = "rw";
        }
        {
          node = "/dev/nvidiactl";
          modifier = "rw";
        }
        {
          node = "/dev/nvidia-uvm";
          modifier = "rw";
        }
      ];

      config =
        { config, pkgs, ... }:
        {
          # ─────────────────────────────────────────────────────
          # LAYER 3: Guest Network Configuration
          # ─────────────────────────────────────────────────────

          # Fix NIX_PATH warning by using flake-based nixpkgs instead of channels
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];

          networking = {
            # Default gateway: o IP do host na veth
            defaultGateway = {
              address = "192.168.100.10";
              interface = "eth0";
            };

            # DNS: usa servidores públicos
            nameservers = [
              "1.1.1.1"
              "8.8.8.8"
            ];

            # Se precisar de resolução de nomes local
            # useHostResolvConf = true;  # ← usa /etc/resolv.conf do host
          };

          networking.firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              443
              22
              8888
              53
            ]; # ← nginx, ssh, jupyter
          };

          # Hardware
          hardware.graphics.enable = true;

          # Services
          services.nginx.enable = true;

          # Packages
          environment.systemPackages = with pkgs; [
            python313
            python313Packages.uv
            cudaPackages.cudatoolkit
            jupyter-all
            python313Packages.jupyter-sphinx
            python313Packages.jupyter-core
            neovim
            curl
            wget
            git
            htop
            iftop
            tcpdump # ← debug de rede
            #gemini-cli
            #google-cloud-sdk
          ];

          nixpkgs.config.allowUnfree = true;
          system.stateVersion = "25.05";
        };
    };

    # ═══════════════════════════════════════════════════════════
    # BONUS: Debugging & Tooling
    # ═══════════════════════════════════════════════════════════

    environment.systemPackages = with pkgs; [
      nixos-container
      poetry
      nginx
      cmake
      ninja
      iptables
      iproute2
      tcpdump
      wireshark
    ];
  };
}
