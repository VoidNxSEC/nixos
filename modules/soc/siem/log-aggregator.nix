{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
in
{
  options.kernelcore.soc.siem.logAggregator = {
    enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable centralized log aggregation";
    };

    # Sources to collect
    sources = {
      journald = mkOption {
        type = types.bool;
        default = true;
        description = "Collect from systemd journal";
      };

      auditd = mkOption {
        type = types.bool;
        default = true;
        description = "Collect from auditd";
      };

      suricata = mkOption {
        type = types.bool;
        default = cfg.ids.suricata.enable or false;
        description = "Collect Suricata IDS alerts";
      };

      syslog = mkOption {
        type = types.bool;
        default = true;
        description = "Collect syslog messages";
      };
    };

    # Output destinations
    outputs = {
      opensearch = mkOption {
        type = types.bool;
        default = cfg.siem.opensearch.enable or false;
        description = "Send logs to OpenSearch";
      };

      file = mkOption {
        type = types.bool;
        default = true;
        description = "Write logs to local files";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.siem.logAggregator.enable) {
    # Use Vector for high-performance log aggregation
    # Vector is faster and more resource-efficient than Filebeat/Logstash

    services.vector = {
      enable = true;

      settings = {
        # Data directory
        data_dir = "/var/lib/vector";

        # API for monitoring
        api = {
          enabled = true;
          address = "127.0.0.1:8686";
        };

        # ===================
        # SOURCES
        # ===================
        sources = {
          # Systemd journal
          journald_logs = mkIf cfg.siem.logAggregator.sources.journald {
            type = "journald";
            current_boot_only = true;
          };

          # Audit logs
          audit_logs = mkIf cfg.siem.logAggregator.sources.auditd {
            type = "file";
            include = [ "/var/log/audit/audit.log" ];
            read_from = "end";
          };

          # Suricata EVE JSON
          suricata_eve = mkIf cfg.siem.logAggregator.sources.suricata {
            type = "file";
            include = [ "/var/log/suricata/eve.json" ];
            read_from = "end";
          };

          # Syslog listener
          syslog_listener = mkIf cfg.siem.logAggregator.sources.syslog {
            type = "syslog";
            address = "127.0.0.1:1514";
            mode = "udp";
          };
        };

        # ===================
        # TRANSFORMS
        # ===================
        transforms = {
          # Parse and enrich journal logs
          parse_journald = {
            type = "remap";
            inputs = [ "journald_logs" ];
            source = ''
              .event.category = "system"
              .event.source = "journald"
              .host.hostname = get_hostname!()

              # Severity mapping
              .event.severity = if .PRIORITY == "0" || .PRIORITY == "1" || .PRIORITY == "2" {
                "critical"
              } else if .PRIORITY == "3" {
                "high"
              } else if .PRIORITY == "4" {
                "medium"
              } else {
                "low"
              }
            '';
          };

          # Parse audit logs
          parse_audit = mkIf cfg.siem.logAggregator.sources.auditd {
            type = "remap";
            inputs = [ "audit_logs" ];
            source = ''
              .event.category = "audit"
              .event.source = "auditd"
              .host.hostname = get_hostname!()

              # Extract audit type
              .audit.type = parse_regex!(.message, r'type=(?P<type>\w+)').type

              # High severity for certain audit types
              .event.severity = if includes(["EXECVE", "AVC", "USER_AUTH"], .audit.type) {
                "medium"
              } else if includes(["ANOM_PROMISCUOUS", "MAC_POLICY_LOAD"], .audit.type) {
                "high"
              } else {
                "low"
              }
            '';
          };

          # Parse Suricata EVE JSON
          parse_suricata = mkIf cfg.siem.logAggregator.sources.suricata {
            type = "remap";
            inputs = [ "suricata_eve" ];
            source = ''
              # Parse EVE JSON
              . = parse_json!(.message)
              .event.category = "ids"
              .event.source = "suricata"
              .host.hostname = get_hostname!()

              # Map Suricata severity
              .event.severity = if .alert.severity == 1 {
                "critical"
              } else if .alert.severity == 2 {
                "high"
              } else if .alert.severity == 3 {
                "medium"
              } else {
                "low"
              }
            '';
          };

          # Filter for alerts only (high+ severity)
          filter_alerts = {
            type = "filter";
            inputs = [
              "parse_journald"
              "parse_audit"
            ]
            ++ (optionals cfg.siem.logAggregator.sources.suricata [ "parse_suricata" ]);
            condition = ''
              includes(["critical", "high", "medium"], .event.severity)
            '';
          };
        };

        # ===================
        # SINKS
        # ===================
        sinks = {
          # OpenSearch output
          opensearch_sink = mkIf cfg.siem.logAggregator.outputs.opensearch {
            type = "elasticsearch";
            inputs = [ "filter_alerts" ];
            endpoints = [ "https://localhost:9200" ];
            mode = "bulk";
            bulk = {
              index = "soc-security-%Y.%m.%d";
            };
            tls = {
              verify_certificate = false;
            };
            healthcheck = {
              enabled = false;
            };
          };

          # Local file output for all logs
          file_sink = mkIf cfg.siem.logAggregator.outputs.file {
            type = "file";
            inputs = [
              "parse_journald"
              "parse_audit"
            ]
            ++ (optionals cfg.siem.logAggregator.sources.suricata [ "parse_suricata" ]);
            path = "/var/log/soc/aggregated-%Y-%m-%d.json";
            encoding = {
              codec = "json";
            };
          };

          # Alert-specific file
          alerts_file = {
            type = "file";
            inputs = [ "filter_alerts" ];
            path = "/var/log/soc/alerts-%Y-%m-%d.json";
            encoding = {
              codec = "json";
            };
          };

          # Console output for debugging (disabled in prod)
          console_debug = {
            type = "console";
            inputs = [ "filter_alerts" ];
            encoding = {
              codec = "json";
            };
            target = "stdout";
          };
        };
      };
    };

    # Create log directories
    systemd.tmpfiles.rules = [
      "d /var/log/soc 0750 vector vector -"
      "d /var/lib/vector 0750 vector vector -"
    ];

    # Vector user/group
    users.users.vector = {
      isSystemUser = true;
      group = "vector";
      extraGroups = [
        "systemd-journal"
        "adm"
      ];
    };
    users.groups.vector = { };

    # CLI aliases
    environment.shellAliases = {
      vector-health = "curl -s http://localhost:8686/health | jq";
      vector-metrics = "curl -s http://localhost:8686/metrics";
      soc-logs = "tail -f /var/log/soc/alerts-$(date +%Y-%m-%d).json | jq";
    };
  };
}
