# modules/edr/server.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.opensearch = {
    enable = true;
    settings = {
      "network.host" = "127.0.0.1";
      "plugins.security.ssl.http.enabled" = true;
    };
  };

  services.grafana = {
    enable = true;
    settings.server.http_port = 3000;
  };

  # Detection Engine (custom service)
  systemd.services.edr-detection = {
    description = "EDR Detection Engine";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.edr-engine}/bin/edr-detect";
      DynamicUser = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
    };
  };
}
