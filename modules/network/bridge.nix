{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.bridge;
in
{
  options.kernelcore.network.bridge = {
    enable = mkEnableOption "Create and manage a NetworkManager bridge (br0)";

    name = mkOption {
      type = types.str;
      default = "br0";
      description = "Bridge interface name.";
    };

    uplinkInterface = mkOption {
      type = types.str;
      default = "";
      description = "Physical interface to attach as bridge slave (empty = auto-detect first active ethernet).";
    };

    ipv6.enable = mkEnableOption "Enable IPv6 on the bridge (NetworkManager)" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.networkmanager.enable or false;
        message = "kernelcore.network.bridge requires networking.networkmanager.enable = true.";
      }
    ];

    systemd.services.ensure-br0 = {
      description = "Ensure NetworkManager bridge ${cfg.name} exists";
      after = [ "NetworkManager.service" ];
      wants = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      path = [
        pkgs.networkmanager
        pkgs.gawk
        pkgs.coreutils
        pkgs.util-linux
      ];
      script = ''
        set -euo pipefail
        BR="${cfg.name}"
        UPL="${cfg.uplinkInterface}"

        # Auto-detect uplink if empty: first active ethernet device managed by NM
        if [ -z "$UPL" ]; then
          UPL=$(nmcli -t -f DEVICE,TYPE,STATE dev | awk -F: '$2=="ethernet" && $3~/(connected|connecting)/ {print $1; exit}') || true
        fi

        if [ -z "$UPL" ]; then
          echo "[ensure-br0] no uplink detected; skipping bridge creation" >&2
          exit 0
        fi

        if nmcli -t -f NAME con show | grep -Fxq "$BR"; then
          echo "[ensure-br0] bridge $BR already exists"
        else
          echo "[ensure-br0] creating bridge $BR with uplink $UPL"
          nmcli con add type bridge ifname "$BR" con-name "$BR" \
            ipv4.method auto ipv6.method ${if cfg.ipv6.enable then "auto" else "ignore"}
          nmcli con add type bridge-slave ifname "$UPL" master "$BR"
        fi

        nmcli con up "$BR" || true
      '';
    };
  };
}
