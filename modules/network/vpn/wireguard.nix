{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.vpn.wireguard;
in
{
  options.kernelcore.network.vpn.wireguard = {
    enable = mkEnableOption "WireGuard VPN client";

    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard network interface name.";
    };

    address = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "10.0.0.2/24" ];
      description = "IP address(es) assigned to this peer on the VPN network.";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "10.0.0.1" ];
      description = "DNS servers to use when the tunnel is active.";
    };

    privateKeyFile = mkOption {
      type = types.path;
      description = ''
        Path to the WireGuard private key file (SOPS-managed).
        Generate with: wg genkey | tee private.key | wg pubkey > public.key
      '';
    };

    peers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            publicKey = mkOption {
              type = types.str;
              description = "Base64 WireGuard public key of the peer.";
            };

            presharedKeyFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Optional SOPS-managed preshared key for post-quantum resistance.";
            };

            endpoint = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "vpn.example.com:51820";
              description = "Peer endpoint (host:port). Null for server peers without fixed IP.";
            };

            allowedIPs = mkOption {
              type = types.listOf types.str;
              default = [
                "0.0.0.0/0"
                "::/0"
              ];
              description = "IP ranges routed through this peer. Use 0.0.0.0/0 for full-tunnel.";
            };

            persistentKeepalive = mkOption {
              type = types.nullOr types.int;
              default = 25;
              description = "Send keepalive packet every N seconds. Required behind NAT.";
            };
          };
        }
      );
      default = [ ];
      description = "List of WireGuard peers (servers/gateways).";
    };

    killSwitch = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Drop all non-VPN traffic if the tunnel goes down.
        Adds firewall rules to block non-wg0 traffic.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open WireGuard UDP port in the firewall (needed for server mode).";
    };

    listenPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = "Local UDP port to listen on. Null = OS-assigned (client mode).";
    };
  };

  config = mkIf cfg.enable {
    networking.wireguard.interfaces.${cfg.interface} = {
      ips = cfg.address;
      privateKeyFile = cfg.privateKeyFile;
      listenPort = cfg.listenPort;

      peers = map (p: {
        inherit (p) publicKey allowedIPs;
        endpoint = p.endpoint;
        presharedKeyFile = p.presharedKeyFile;
        persistentKeepalive = p.persistentKeepalive;
      }) cfg.peers;

      # Bring up DNS when tunnel activates
      postUp = lib.optionalString (cfg.dns != [ ]) ''
        ${pkgs.resolvconf}/bin/resolvconf -a ${cfg.interface} -m 0 -x <<EOF
        nameserver ${builtins.concatStringsSep "\nnameserver " cfg.dns}
        EOF
      '';
      postDown = lib.optionalString (cfg.dns != [ ]) ''
        ${pkgs.resolvconf}/bin/resolvconf -d ${cfg.interface}
      '';
    };

    networking.firewall = {
      # Kill switch: block non-VPN traffic when enabled
      extraCommands = mkIf cfg.killSwitch ''
        iptables -I OUTPUT ! -o ${cfg.interface} -m mark ! --mark $(wg show ${cfg.interface} fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
        ip6tables -I OUTPUT ! -o ${cfg.interface} -m mark ! --mark $(wg show ${cfg.interface} fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
      '';
      extraStopCommands = mkIf cfg.killSwitch ''
        iptables -D OUTPUT ! -o ${cfg.interface} -m mark ! --mark $(wg show ${cfg.interface} fwmark) -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
        ip6tables -D OUTPUT ! -o ${cfg.interface} -m mark ! --mark $(wg show ${cfg.interface} fwmark) -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
      '';
      allowedUDPPorts = mkIf (cfg.openFirewall && cfg.listenPort != null) [
        cfg.listenPort
      ];
    };

    environment.systemPackages = with pkgs; [
      wireguard-tools
      (writeShellScriptBin "wg-status" ''
        #!/usr/bin/env bash
        echo "=== WireGuard Status ==="
        sudo wg show
        echo ""
        echo "=== Interface ${cfg.interface} ==="
        ip addr show ${cfg.interface} 2>/dev/null || echo "Interface not up"
      '')
      (writeShellScriptBin "wg-up" ''
        #!/usr/bin/env bash
        sudo systemctl start wg-quick-${cfg.interface}.service 2>/dev/null || \
        sudo wg-quick up ${cfg.interface}
        wg-status
      '')
      (writeShellScriptBin "wg-down" ''
        #!/usr/bin/env bash
        sudo systemctl stop wg-quick-${cfg.interface}.service 2>/dev/null || \
        sudo wg-quick down ${cfg.interface}
        echo "WireGuard tunnel down."
      '')
    ];
  };
}
