{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
  suricataCfg = cfg.ids.suricata;
in
{
  options.kernelcore.soc.ids.suricata = {
    enable = mkOption {
      type = types.bool;
      default = cfg.profile != "minimal";
      description = "Enable Suricata IDS/IPS";
    };

    # Operation mode
    mode = mkOption {
      type = types.enum [
        "ids"
        "ips"
      ];
      default = "ids";
      description = "Intrusion Detection (ids) or Prevention (ips) mode";
    };

    # Network interfaces
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ "wlp62s0" ]; # Use actual interface - 'any' doesn't work with af-packet
      description = "Network interfaces to monitor";
    };

    # Rule management
    rules = {
      enableETOpen = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Emerging Threats Open ruleset";
      };

      enableETBotcc = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ET Botnet C&C rules";
      };

      customRules = mkOption {
        type = types.lines;
        default = "";
        description = "Custom Suricata rules";
      };

      updateInterval = mkOption {
        type = types.str;
        default = "daily";
        description = "Rule update interval";
      };
    };

    # Performance tuning
    performance = {
      threads = mkOption {
        type = types.int;
        default = 2;
        description = "Number of detection threads";
      };

      memcap = mkOption {
        type = types.str;
        default = "512mb";
        description = "Memory cap for flow tracking";
      };

      afPacket = mkOption {
        type = types.bool;
        default = true;
        description = "Use AF_PACKET for high performance capture";
      };
    };

    # Logging
    logging = {
      eveJson = mkOption {
        type = types.bool;
        default = true;
        description = "Enable EVE JSON logging for SIEM integration";
      };

      fastLog = mkOption {
        type = types.bool;
        default = true;
        description = "Enable fast.log for quick alert review";
      };

      pcapLog = mkOption {
        type = types.bool;
        default = false;
        description = "Enable PCAP logging (disk intensive)";
      };
    };
  };

  config = mkIf (cfg.enable && suricataCfg.enable) {
    # Suricata service
    services.suricata = {
      enable = true;
      # Ensure config files exist
      package = pkgs.suricata;

      settings = {
        # Capture method
        af-packet = mkIf suricataCfg.performance.afPacket (
          map (iface: {
            interface = iface;
            cluster-id = 99;
            cluster-type = "cluster_flow";
            defrag = true;
            use-mmap = true;
            tpacket-v3 = true;
          }) suricataCfg.interfaces
        );

        # Detection engine settings
        detect-engine = [
          {
            profile = "high";
            sgh-mpm-context = "auto";
            inspection-recursion-limit = 3000;
          }
        ];

        # Memory limits
        flow = {
          memcap = suricataCfg.performance.memcap;
          hash-size = 65536;
          prealloc = 10000;
          emergency-recovery = 30;
        };

        # Threading
        threading = {
          detect-thread-ratio = 1.0;
        };

        # Outputs
        outputs = [
          # EVE JSON log for SIEM
          (mkIf suricataCfg.logging.eveJson {
            eve-log = {
              enabled = true;
              filetype = "regular";
              filename = "eve.json";
              pcap-file = false;
              community-id = true;
              types = [
                { alert = { }; }
                {
                  anomaly = {
                    enabled = true;
                  };
                }
                {
                  http = {
                    extended = true;
                  };
                }
                { dns = { }; }
                {
                  tls = {
                    extended = true;
                  };
                }
                {
                  files = {
                    force-magic = true;
                  };
                }
                { smtp = { }; }
                { flow = { }; }
                { netflow = { }; }
                {
                  stats = {
                    interval = 60;
                  };
                }
              ];
            };
          })

          # Fast log for quick review
          (mkIf suricataCfg.logging.fastLog {
            fast = {
              enabled = true;
              filename = "fast.log";
              append = true;
            };
          })

          # PCAP logging
          (mkIf suricataCfg.logging.pcapLog {
            pcap-log = {
              enabled = true;
              filename = "log.pcap";
              limit = "100mb";
              max-files = 10;
            };
          })

          # Stats for monitoring
          {
            stats = {
              enabled = true;
              filename = "stats.log";
              append = true;
              interval = 60;
            };
          }
        ];

        # Default action for IDS vs IPS
        default-rule-path = "/var/lib/suricata/rules";
        rule-files = [ "*.rules" ];

        # Classification and reference configs
        classification-file = "/var/lib/suricata/rules/classification.config";
        reference-config-file = "/var/lib/suricata/rules/reference.config";

        # Protocol detection
        app-layer = {
          protocols = {
            http = {
              enabled = "yes";
              libhtp = {
                default-config = {
                  personality = "IDS";
                  request-body-limit = 102400;
                  response-body-limit = 102400;
                };
              };
            };
            tls = {
              enabled = "yes";
              detection-ports = {
                dp = "443";
              };
            };
            dns = {
              tcp = {
                enabled = "yes";
              };
              udp = {
                enabled = "yes";
              };
            };
            ssh = {
              enabled = "yes";
            };
          };
        };
      };
    };

    # Custom rules file
    environment.etc."suricata/rules/local.rules" = mkIf (suricataCfg.rules.customRules != "") {
      mode = "0644";
      text = ''
        # Custom SOC rules for NixOS environment

        # Detect NixOS-related suspicious activity
        alert tcp any any -> any 22 (msg:"SOC: SSH brute force attempt"; flow:to_server; \
          threshold:type threshold, track by_src, count 5, seconds 60; \
          classtype:attempted-admin; sid:1000001; rev:1;)

        # Detect potential malware C2 activity
        alert dns any any -> any 53 (msg:"SOC: Suspicious DNS query length"; \
          dns.query; content:"|00|"; offset:0; depth:1; \
          pcre:"/^.{50,}/"; classtype:bad-unknown; sid:1000002; rev:1;)

        # Detect unauthorized Nix daemon access
        alert tcp any any -> any 5432 (msg:"SOC: PostgreSQL unauthorized access attempt"; \
          flow:to_server,established; content:"FATAL"; nocase; \
          classtype:attempted-admin; sid:1000003; rev:1;)

        # Custom rules from configuration
        ${suricataCfg.rules.customRules}
      '';
    };

    systemd.services.suricata.preStart = lib.mkAfter ''
      # Create directories manually (PermissionsStartOnly ensures this runs as root)
      mkdir -p /var/lib/suricata/rules
      mkdir -p /var/log/suricata

      # Ensure suricata user owns everything
      chown -R suricata:suricata /var/lib/suricata /var/log/suricata
      chmod 755 /var/lib/suricata
      chmod 755 /var/lib/suricata/rules
      chmod 755 /var/log/suricata

      # Create config files with correct ownership atomically
      install -D -m 640 -o suricata -g suricata /dev/null /var/lib/suricata/rules/classification.config 2>/dev/null || true
      install -D -m 640 -o suricata -g suricata /dev/null /var/lib/suricata/rules/reference.config 2>/dev/null || true

      # Ensure suricata.rules exists
      if [ ! -s /var/lib/suricata/rules/suricata.rules ]; then
         # Create empty rules file if suricata-update fails
         install -D -m 640 -o suricata -g suricata /dev/null /var/lib/suricata/rules/suricata.rules 2>/dev/null || true
      fi

      # Final permission fix
      chown -R suricata:suricata /var/lib/suricata 2>/dev/null || true
      chmod -R 750 /var/lib/suricata 2>/dev/null || true
      chmod 640 /var/lib/suricata/rules/*.config 2>/dev/null || true
    '';

    # Note: NixOS provides suricata-update service built-in
    # To update rules manually: sudo suricata-update && sudo systemctl reload suricata

    # Fix for suricata-update - add pyyaml dependency
    systemd.services.suricata-update = {
      path = [ pkgs.python313Packages.pyyaml ];
      environment = {
        PYTHONPATH = "${pkgs.python313Packages.pyyaml}/lib/python3.13/site-packages";
      };
      serviceConfig = {
        User = lib.mkForce "root"; # suricata-update needs to write rules
      };
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/suricata 0750 suricata suricata -"
      "d /var/lib/suricata/rules 0750 suricata suricata -"
      "d /var/log/suricata 0750 suricata suricata -"
    ];

    # Make preStart run as root before dropping to suricata user
    systemd.services.suricata.serviceConfig.PermissionsStartOnly = true;

    # CLI aliases
    environment.shellAliases = {
      ids-alerts = "tail -f /var/log/suricata/fast.log";
      ids-eve = "tail -f /var/log/suricata/eve.json | jq";
      ids-stats = "cat /var/log/suricata/stats.log | tail -50";
      ids-reload = "sudo systemctl reload suricata && echo 'Rules reloaded'";
      ids-test = "curl -s http://testmynids.org/uid/index.html && echo 'Test alert generated'";
    };

    # Additional packages
    environment.systemPackages = with pkgs; [
      suricata # Main package
      jq # For EVE JSON parsing
    ];
  };
}
