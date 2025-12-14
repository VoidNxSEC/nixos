{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
  tiCfg = cfg.threatIntel;
in
{
  options.kernelcore.soc.ids.threatIntel = {
    # Enable already defined in options.nix

    # Feed-specific configurations
    abuseipdb = {
      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to AbuseIPDB API key file (SOPS)";
      };

      confidenceThreshold = mkOption {
        type = types.int;
        default = 75;
        description = "Minimum confidence score (0-100) to block";
      };
    };

    misp = {
      url = mkOption {
        type = types.str;
        default = "";
        description = "MISP instance URL";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to MISP API key file";
      };
    };

    # IOC types to collect
    iocTypes = mkOption {
      type = types.listOf (
        types.enum [
          "ip"
          "domain"
          "url"
          "hash"
          "email"
        ]
      );
      default = [
        "ip"
        "domain"
        "hash"
      ];
      description = "Types of IOCs to collect and monitor";
    };

    # Local blocklists
    customBlocklists = {
      ips = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Custom IP addresses to block";
      };

      domains = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Custom domains to block";
      };
    };
  };

  config = mkIf (cfg.enable && tiCfg.enable) {
    # Threat Intel aggregation script
    environment.etc."soc/scripts/update-threat-intel.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        IOC_DIR="/var/lib/soc/threat-intel"
        mkdir -p "$IOC_DIR"

        echo "[$(date -Iseconds)] Starting threat intelligence update..."

        # Emerging Threats blocklists
        ${optionalString (elem "emergingthreats" tiCfg.feeds) ''
          echo "  Fetching Emerging Threats blocklists..."
          ${pkgs.curl}/bin/curl -sfL "https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt" \
            -o "$IOC_DIR/et-blocklist-ips.txt" || echo "  Warning: ET IPs fetch failed"
          ${pkgs.curl}/bin/curl -sfL "https://rules.emergingthreats.net/blockrules/emerging-botcc.rules" \
            -o "$IOC_DIR/et-botcc.rules" || echo "  Warning: ET botcc fetch failed"
        ''}

        # AlienVault OTX
        ${optionalString (elem "otx" tiCfg.feeds) ''
          echo "  Fetching AlienVault OTX indicators..."
          ${pkgs.curl}/bin/curl -sfL "https://otx.alienvault.com/api/v1/indicators/export" \
            -o "$IOC_DIR/otx-indicators.json" || echo "  Warning: OTX fetch failed"
        ''}

        # Abuse.ch URLhaus
        echo "  Fetching URLhaus malware URLs..."
        ${pkgs.curl}/bin/curl -sfL "https://urlhaus.abuse.ch/downloads/text_online/" \
          -o "$IOC_DIR/urlhaus-online.txt" || echo "  Warning: URLhaus fetch failed"

        # Abuse.ch Feodo Tracker (banking trojans)
        echo "  Fetching Feodo Tracker IPs..."
        ${pkgs.curl}/bin/curl -sfL "https://feodotracker.abuse.ch/downloads/ipblocklist.txt" \
          -o "$IOC_DIR/feodo-ips.txt" || echo "  Warning: Feodo fetch failed"

        # Abuse.ch SSL Blacklist
        echo "  Fetching SSL Blacklist..."
        ${pkgs.curl}/bin/curl -sfL "https://sslbl.abuse.ch/blacklist/sslblacklist.csv" \
          -o "$IOC_DIR/ssl-blacklist.csv" || echo "  Warning: SSL blacklist fetch failed"

        # Spamhaus DROP lists
        echo "  Fetching Spamhaus DROP list..."
        ${pkgs.curl}/bin/curl -sfL "https://www.spamhaus.org/drop/drop.txt" \
          -o "$IOC_DIR/spamhaus-drop.txt" || echo "  Warning: Spamhaus DROP fetch failed"
        ${pkgs.curl}/bin/curl -sfL "https://www.spamhaus.org/drop/edrop.txt" \
          -o "$IOC_DIR/spamhaus-edrop.txt" || echo "  Warning: Spamhaus EDROP fetch failed"

        # Create consolidated blocklist
        echo "  Creating consolidated blocklist..."
        cat "$IOC_DIR"/*-ips.txt 2>/dev/null | \
          grep -v "^#" | grep -v "^$" | \
          sort -u > "$IOC_DIR/consolidated-ips.txt" || true

        # Generate nftables set if firewall integration enabled
        if command -v nft &>/dev/null; then
          echo "  Generating nftables blocklist..."
          cat > "$IOC_DIR/nft-blocklist.nft" << NFTEOF
        # Auto-generated threat intel blocklist
        # Updated: $(date -Iseconds)
        define threat_ips = {
        $(head -1000 "$IOC_DIR/consolidated-ips.txt" | sed 's/$/,/' | head -c -2)
        }
        NFTEOF
        fi

        # Statistics
        IP_COUNT=$(wc -l < "$IOC_DIR/consolidated-ips.txt" 2>/dev/null || echo "0")
        echo "[$(date -Iseconds)] Threat intel update complete: $IP_COUNT IPs"
      '';
    };

    # Scheduled threat intel updates
    systemd.services.threat-intel-update = {
      description = "Update threat intelligence feeds";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/etc/soc/scripts/update-threat-intel.sh";
        User = "root";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

    systemd.timers.threat-intel-update = {
      description = "Threat intel update timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = tiCfg.updateInterval;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    # YARA rules management
    environment.etc."soc/yara/malware.yar" = {
      mode = "0644";
      text = ''
        /*
          SOC YARA Rules
          Custom malware detection rules
        */

        rule SuspiciousShellScript
        {
            meta:
                description = "Detects suspicious shell script patterns"
                severity = "medium"

            strings:
                $s1 = "curl" nocase
                $s2 = "wget" nocase
                $s3 = "base64" nocase
                $s4 = "/dev/null" nocase
                $s5 = "chmod +x" nocase
                $s6 = "2>&1" nocase

            condition:
                4 of them
        }

        rule CryptoMiner
        {
            meta:
                description = "Potential cryptocurrency miner"
                severity = "high"

            strings:
                $s1 = "stratum+tcp://" nocase
                $s2 = "xmrig" nocase
                $s3 = "minerd" nocase
                $s4 = "cpuminer" nocase
                $s5 = "cryptonight" nocase
                $wallet = /[13][a-km-zA-HJ-NP-Z1-9]{25,34}/

            condition:
                any of ($s*) or $wallet
        }

        rule ReverseShell
        {
            meta:
                description = "Potential reverse shell"
                severity = "critical"

            strings:
                $s1 = "/bin/sh -i" nocase
                $s2 = "/bin/bash -i" nocase
                $s3 = "python -c 'import socket" nocase
                $s4 = "nc -e /bin" nocase
                $s5 = "0<&196;exec 196<>/dev/tcp" nocase

            condition:
                any of them
        }
      '';
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/soc/threat-intel 0750 root root -"
      "d /etc/soc/yara 0755 root root -"
    ];

    # Packages
    environment.systemPackages = with pkgs; [
      yara # For file scanning
    ];

    # CLI aliases
    environment.shellAliases = {
      ti-update = "sudo systemctl start threat-intel-update && journalctl -u threat-intel-update -f";
      ti-stats = "wc -l /var/lib/soc/threat-intel/*.txt 2>/dev/null || echo 'No feeds downloaded'";
      ti-check-ip = "grep -r $1 /var/lib/soc/threat-intel/*.txt 2>/dev/null | head -10";
    };
  };
}
