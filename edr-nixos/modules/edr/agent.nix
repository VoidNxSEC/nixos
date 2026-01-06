# modules/edr/agent.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.osquery = {
    enable = true;
    settings = {
      options = {
        logger_plugin = "tls";
        tls_hostname = "edr-server.internal";
        tls_server_certs = "/etc/edr/ca.crt";
      };
    };
  };

  security.auditd.enable = true;
  security.audit.rules = [
    "-w /etc/nixos -p wa -k nixos_config"
    "-w /nix/store -p x -k nix_exec"
    "-a always,exit -F arch=b64 -S execve -k process_exec"
  ];

  services.vector = {
    enable = true;
    settings = {
      sources.journald = {
        type = "journald";
      };
      sources.audit = {
        type = "file";
        include = [ "/var/log/audit/audit.log" ];
      };
      sinks.edr_server = {
        type = "http";
        inputs = [
          "journald"
          "audit"
        ];
        uri = "https://edr-server.internal:8443/ingest";
      };
    };
  };
}
