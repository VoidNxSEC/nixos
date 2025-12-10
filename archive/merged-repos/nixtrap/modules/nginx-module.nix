{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NGINX module configuration
  # Open firewall for nginx
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Nginx is configured in cache-server.nix - this file only provides firewall rules
  # services.nginx configuration moved to cache-server.nix to avoid duplication

  # Scripts for managing NGINX and SSL
  environment.systemPackages = with pkgs; [
    openssl
    nginx
  ];

  # Certificate management
}
