{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;
  wazuhCfg = cfg.siem.wazuh;
in
{
  options.kernelcore.soc.siem.wazuh = {
    enable = mkOption {
      type = types.bool;
      default = cfg.profile != "minimal";
      description = "Enable Wazuh SIEM Manager";
    };

    version = mkOption {
      type = types.str;
      default = "4.7.2";
      description = "Wazuh version to deploy";
    };

    # Agent configuration
    agents = {
      enableLocal = mkOption {
        type = types.bool;
        default = true;
        description = "Enable local Wazuh agent on this host";
      };

      autoEnroll = mkOption {
        type = types.bool;
        default = true;
        description = "Auto-enroll local agent";
      };
    };

    # Integration settings
    integrations = {
      slack = mkOption {
        type = types.bool;
        default = cfg.alerting.slack.enable;
        description = "Enable Slack integration for Wazuh alerts";
      };

      virustotal = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VirusTotal integration for file analysis";
      };
    };

    # Resource limits
    resources = {
      javaHeapSize = mkOption {
        type = types.str;
        default = "1g";
        description = "Java heap size for Wazuh manager";
      };
    };
  };

  config = mkIf (cfg.enable && wazuhCfg.enable) {
    # Wazuh Manager Container deployment
    # Using containers for isolation and easier updates
    virtualisation.oci-containers.containers.wazuh-manager = {
      image = "wazuh/wazuh-manager:${wazuhCfg.version}";
      autoStart = true;

      environment = {
        INDEXER_URL = "https://127.0.0.1:9200";
        FILEBEAT_SSL_VERIFICATION_MODE = "none";
        SSL_CERTIFICATE_AUTHORITIES = "";
        SSL_CERTIFICATE = "";
        SSL_KEY = "";
        API_USERNAME = "wazuh-wui";
      };

      volumes = [
        "/var/lib/wazuh/manager/etc:/var/ossec/etc:rw"
        "/var/lib/wazuh/manager/logs:/var/ossec/logs:rw"
        "/var/lib/wazuh/manager/queue:/var/ossec/queue:rw"
        "/var/lib/wazuh/manager/var:/var/ossec/var:rw"
        "/var/lib/wazuh/manager/active-response:/var/ossec/active-response:rw"
        "/var/lib/wazuh/manager/integrations:/var/ossec/integrations:rw"
      ];

      ports = [
        "1514:1514/udp" # Agent connection
        "1515:1515" # Agent enrollment
        "514:514/udp" # Syslog collection
        "55000:55000" # Wazuh API
      ];

      extraOptions = [
        "--hostname=wazuh-manager"
        "--network=host"
      ];
    };

    # Create Wazuh directories
    systemd.tmpfiles.rules = [
      "d /var/lib/wazuh 0750 root root -"
      "d /var/lib/wazuh/manager 0750 root root -"
      "d /var/lib/wazuh/manager/etc 0750 root root -"
      "d /var/lib/wazuh/manager/logs 0750 root root -"
      "d /var/lib/wazuh/manager/queue 0750 root root -"
      "d /var/lib/wazuh/manager/var 0750 root root -"
      "d /var/lib/wazuh/manager/active-response 0750 root root -"
      "d /var/lib/wazuh/manager/integrations 0750 root root -"
    ];

    # Wazuh custom rules for NixOS
    environment.etc."wazuh/local_rules.xml" = {
      mode = "0644";
      text = ''
        <group name="nixos,sysmon,">
          <!-- NixOS specific rules -->
          
          <!-- Nix store tampering detection -->
          <rule id="100001" level="15">
            <if_sid>550</if_sid>
            <match>/nix/store</match>
            <description>Critical: Nix store modification detected</description>
            <group>nixos,file_integrity,</group>
          </rule>
          
          <!-- NixOS rebuild detection -->
          <rule id="100002" level="5">
            <program_name>nixos-rebuild</program_name>
            <description>NixOS system rebuild initiated</description>
            <group>nixos,system_update,</group>
          </rule>
          
          <!-- Nix daemon security events -->
          <rule id="100003" level="10">
            <program_name>nix-daemon</program_name>
            <match>unauthorized</match>
            <description>Unauthorized Nix daemon access attempt</description>
            <group>nixos,authentication_failed,</group>
          </rule>
          
          <!-- Sudo abuse detection -->
          <rule id="100010" level="12">
            <if_sid>5401</if_sid>
            <regex>COMMAND=.*(rm -rf|mkfs|dd if=)</regex>
            <description>High-risk sudo command execution</description>
            <group>sysmon,sudo_abuse,</group>
          </rule>
          
          <!-- SSH brute force enhanced -->
          <rule id="100020" level="10" frequency="5" timeframe="60">
            <if_matched_sid>5710</if_matched_sid>
            <description>SSH brute force attack detected (5+ failures in 60s)</description>
            <group>authentication_failures,ssh_brute_force,</group>
          </rule>
          
          <!-- Container escape attempt -->
          <rule id="100030" level="15">
            <match>container_escape|nsenter|unshare</match>
            <description>Potential container escape attempt</description>
            <group>container_security,</group>
          </rule>
        </group>
      '';
    };

    # Note: Wazuh agent runs as container or connects to Wazuh Manager container
    # Local monitoring is handled via the Wazuh Manager container's API
    # For standalone agent, consider using the wazuh-agent container instead

    # Firewall rules for Wazuh
    networking.firewall = {
      allowedTCPPorts = [
        55000
        1515
      ];
      allowedUDPPorts = [
        1514
        514
      ];
    };

    # Wazuh CLI aliases
    environment.shellAliases = {
      wazuh-status = "docker exec wazuh-manager /var/ossec/bin/agent_control -l";
      wazuh-alerts = "docker exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json | jq";
      wazuh-logs = "docker logs -f wazuh-manager";
    };
  };
}
