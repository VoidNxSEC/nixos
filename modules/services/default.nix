{ ... }:

# ============================================================
# Services Module Aggregator
# ============================================================
# Purpose: Import all service configurations
# Categories: Users, Offload, GPU, Mobile, MCP, Monitoring
# ============================================================

{
  imports = [
    # User Management

    # Offload & Build Services
    ./offload-server.nix
    ./laptop-offload-client.nix
    ./laptop-builder-client.nix

    # GPU & ML Services
    ./gpu-orchestration.nix

    # Remote Access
    ./mosh.nix
    ./mobile-workspace.nix

    # Development & AI
    ./mcp-server.nix

    # Utilities
    ./config-auditor.nix
    ./scripts.nix
  ];

  # Monitoring Services (Prometheus + Grafana)
  config = {
    services.prometheus = {
      enable = true;
      port = 9090;
      exporters = {
        node = {
          enable = true;
          port = 9100;
        };
      };
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [ { targets = [ "localhost:9100" ]; } ];
        }
      ];
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          domain = "localhost";
          http_port = 4000;
        };
      };
    };
  };
}
