{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.vpn.nordvpn;
in
{
  options.kernelcore.network.vpn.nordvpn = {
    enable = mkEnableOption "Enable NordVPN with NordLynx (WireGuard) integration";

    credentialsFile = mkOption {
      type = types.str;
      default = "/etc/nixos/secrets/vpn/nordvpn-credentials";
      description = "Path to NordVPN credentials file (SOPS encrypted)";
    };

    autoConnect = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically connect to NordVPN on boot";
    };

    preferredCountry = mkOption {
      type = types.str;
      default = "United_States";
      description = "Preferred NordVPN server country";
    };

    protocol = mkOption {
      type = types.enum [
        "nordlynx"
        "wireguard"
        "openvpn"
      ];
      default = "nordlynx";
      description = "VPN protocol to use";
    };

    # NOVO: opção para controlar DNS da VPN
    overrideDNS = mkOption {
      type = types.bool;
      default = false;
      description = "Override system DNS with NordVPN DNS servers (may conflict with systemd-resolved)";
    };
  };

  config = mkIf cfg.enable {
    # WireGuard kernel module para NordLynx
    boot.kernelModules = [ "wireguard" ];

    # Instalar NordVPN e ferramentas relacionadas
    environment.systemPackages = with pkgs; [
      wireguard-tools
      openresolv
      curl
      jq
    ];

    # Criar diretórios de configuração do NordVPN
    systemd.tmpfiles.rules = [
      "d /etc/nordvpn 0750 root root -"
      "d /var/lib/nordvpn 0750 root root -"
      "d /etc/nixos/secrets/vpn 0750 root root -"
    ];

    # NordVPN API helper script
    environment.etc."nordvpn/api-helper.sh" = {
      mode = "0750";
      text = ''
        #!/usr/bin/env bash
        # NordVPN API Helper para configuração NordLynx

        API_BASE="https://api.nordvpn.com/v1"
        CRED_FILE="${cfg.credentialsFile}"

        # Obter servidor recomendado por país
        get_recommended_server() {
          local country="$1"
          ${pkgs.curl}/bin/curl -s "''${API_BASE}/servers/recommendations?filters\\[country_id\\]=$(get_country_id $country)&filters\\[servers_technologies\\]\\[identifier\\]=wireguard_udp&limit=1" | \
            ${pkgs.jq}/bin/jq -r '.[0].hostname'
        }

        # Obter ID do país pelo nome
        get_country_id() {
          local country="$1"
          ${pkgs.curl}/bin/curl -s "''${API_BASE}/servers/countries" | \
            ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$country\") | .id"
        }

        # Obter informações do servidor
        get_server_info() {
          local hostname="$1"
          ${pkgs.curl}/bin/curl -s "''${API_BASE}/servers?filters\\[hostname\\]=$hostname"
        }

        # Dispatcher de comandos principal
        case "$1" in
          recommend)
            get_recommended_server "${cfg.preferredCountry}"
            ;;
          server-info)
            get_server_info "$2"
            ;;
          *)
            echo "Usage: $0 {recommend|server-info <hostname>}"
            exit 1
            ;;
        esac
      '';
    };

    # Configuração WireGuard NordLynx
    networking.wg-quick.interfaces = mkIf (cfg.protocol == "nordlynx") {
      wgnord = {
        autostart = cfg.autoConnect;

        # Endereço atribuído pelo NordVPN (usuário deve obter da conta NordVPN)
        address = [ "10.5.0.2/16" ];

        # Chave privada (armazenada em secrets SOPS)
        privateKeyFile = "${cfg.credentialsFile}/private-key";

        # Servidores DNS - APENAS se usuário quiser sobrescrever DNS do sistema
        dns = mkIf cfg.overrideDNS [
          "103.86.96.100"
          "103.86.99.100"
        ];

        peers = [
          {
            # Chave pública do servidor NordVPN (deve ser atualizada por servidor)
            # Usuário precisa obter da API NordVPN ou conta
            publicKey = "SERVER_PUBLIC_KEY_HERE";

            # Endpoint do servidor NordVPN
            endpoint = "xx.nordvpn.com:51820";

            # Rotear todo tráfego através da VPN
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];

            # Keep alive
            persistentKeepalive = 25;
          }
        ];
      };
    };

    # Regras de firewall para VPN
    networking.firewall = {
      # Permitir WireGuard
      allowedUDPPorts = [ 51820 ];

      # Kill switch: prevenir vazamentos - apenas permitir tráfego pela interface VPN quando conectado
      extraCommands = mkIf cfg.autoConnect ''
        # Kill switch: drop non-VPN traffic quando VPN deveria estar ativa
        iptables -I OUTPUT ! -o wgnord -m mark ! --mark $(wg show wgnord fwmark 2>/dev/null || echo 0) -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
      '';

      extraStopCommands = ''
        # Limpar regras do kill switch ao parar
        iptables -D OUTPUT ! -o wgnord -m mark ! --mark $(wg show wgnord fwmark 2>/dev/null || echo 0) -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
      '';
    };

    # Serviço de gerenciamento de conexão NordVPN
    systemd.services.nordvpn-manager = {
      description = "NordVPN Connection Manager";

      # Ordenação de inicialização
      after = [
        "network-online.target"
        "systemd-resolved.service"
      ];
      wants = [ "network-online.target" ];

      wantedBy = mkIf cfg.autoConnect [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = pkgs.writeShellScript "nordvpn-connect" ''
          #!/usr/bin/env bash
          set -euo pipefail

          # Obter servidor recomendado
          echo "Fetching recommended NordVPN server..."
          SERVER=$(/etc/nordvpn/api-helper.sh recommend 2>/dev/null || echo "")

          if [ -n "$SERVER" ]; then
            echo "Connecting to NordVPN server: $SERVER"
            logger -t nordvpn "Connecting to $SERVER"
          else
            echo "Using configured server from wg-quick"
            logger -t nordvpn "Using pre-configured server"
          fi

          # Iniciar interface WireGuard
          ${pkgs.wireguard-tools}/bin/wg-quick up wgnord || {
            echo "Failed to start VPN interface"
            logger -t nordvpn "Failed to start wgnord interface"
            exit 1
          }

          # Aguardar interface estar UP
          sleep 2

          # Verificar se interface está ativa
          if ${pkgs.wireguard-tools}/bin/wg show wgnord > /dev/null 2>&1; then
            echo "✅ VPN connected successfully"
            logger -t nordvpn "VPN connection established"
          else
            echo "❌ VPN connection failed"
            logger -t nordvpn "VPN connection failed"
            exit 1
          fi
        '';

        ExecStop = pkgs.writeShellScript "nordvpn-disconnect" ''
          #!/usr/bin/env bash
          ${pkgs.wireguard-tools}/bin/wg-quick down wgnord 2>/dev/null || true
          logger -t nordvpn "VPN disconnected"
        '';

        Restart = "on-failure";
        RestartSec = 30;
      };
    };

    # Aliases de shell para gerenciamento da VPN
    environment.shellAliases = {
      vpn-connect = "sudo systemctl start nordvpn-manager";
      vpn-disconnect = "sudo systemctl stop nordvpn-manager";
      vpn-restart = "sudo systemctl restart nordvpn-manager";
      vpn-status = "${pkgs.wireguard-tools}/bin/wg show wgnord";
      vpn-logs = "journalctl -u nordvpn-manager -f";
      vpn-check = "/etc/nordvpn/check-connection.sh";
    };

    # Script de verificação de status da VPN
    environment.etc."nordvpn/check-connection.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Verificar se VPN está conectada e funcionando

        echo "==================================="
        echo "   NordVPN STATUS CHECK"
        echo "==================================="
        echo ""

        # 1. Verificar se interface existe
        if ${pkgs.wireguard-tools}/bin/wg show wgnord 2>/dev/null | grep -q "interface: wgnord"; then
          echo "✅ VPN Interface: Connected"

          # Mostrar estatísticas
          echo ""
          echo "Interface Statistics:"
          ${pkgs.wireguard-tools}/bin/wg show wgnord
          echo ""

          # 2. Verificar IP público
          echo "Checking public IP..."
          PUBLIC_IP=$(${pkgs.curl}/bin/curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "Unable to fetch")
          echo "📍 Public IP: $PUBLIC_IP"
          echo ""

          # 3. Verificar se é IP da NordVPN
          echo "Verifying NordVPN connection..."
          NORD_CHECK=$(${pkgs.curl}/bin/curl -s --max-time 5 "https://nordvpn.com/wp-admin/admin-ajax.php?action=get_user_info_data" 2>/dev/null | \
            ${pkgs.jq}/bin/jq -r '.status' 2>/dev/null || echo "unknown")

          if [ "$NORD_CHECK" = "Protected" ]; then
            echo "✅ NordVPN Status: Protected"
          else
            echo "⚠️  NordVPN Status: $NORD_CHECK"
          fi

        else
          echo "❌ VPN Interface: Disconnected"
          echo ""
          echo "To connect: vpn-connect"
          exit 1
        fi

        echo ""
        echo "==================================="
      '';
    };

    # Aviso sobre configuração DNS
    warnings = mkIf (cfg.overrideDNS && config.kernelcore.network.dns-resolver.enable or false) [
      ''
        NordVPN está configurado para sobrescrever DNS do sistema (overrideDNS=true).
        Isso pode conflitar com systemd-resolved.
        Considere desabilitar overrideDNS e deixar systemd-resolved gerenciar DNS.
      ''
    ];
  };
}
