{ ... }:

# ============================================================
# Security Operations Center (SOC) Module Aggregator
# ============================================================
# Purpose: NSA-level integrated security monitoring and management
#
# Profiles:
#   - minimal: Log aggregation + basic alerting
#   - standard: + IDS/IPS + SIEM
#   - enterprise: + Threat intel + Full EDR + Dashboards
#
# Usage:
#   kernelcore.soc.enable = true;
#   kernelcore.soc.profile = "standard";
# ============================================================

{
  imports = [
    # Core configuration
    ./options.nix
    ./tools.nix

    # SIEM components
    ./siem/wazuh.nix
    ./siem/opensearch.nix
    ./siem/log-aggregator.nix

    # Intrusion Detection
    ./ids/suricata.nix
    ./ids/threat-intel.nix

    # Endpoint Detection & Response
    ./edr/edr.nix
    ./edr/fim.nix
    # TODO: Future integration, template in Notion ./edr/agent.nix, ./edr/server.nix, ./edr/endpoint-protection.nix

    # Network security
    ./network/netflow.nix
    ./network/dns-monitor.nix

    # Visualization & Alerting
    ./dashboards/grafana.nix
    ./alerting/alerting.nix
  ];
}
