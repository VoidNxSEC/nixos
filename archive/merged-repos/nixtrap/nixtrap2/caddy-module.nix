{
  config,
  pkgs,
  lib,
  ...
}:
{

  # Caddy module configuration
  services.caddy = {
    enable = true;
    # Caddy configuration options
    json = {
      "http" = {
        "servers" = {
          "cache.local" = {
            "listen" = [ ":443" ];
            "routes" = [
              {
                "match" = [ { "host" = [ "cache.local" ]; } ];
                "handle" = [
                  {
                    "handler" = "reverse_proxy";
                    "upstreams" = [ { "dial" = "localhost:5000"; } ];
                  }
                ];
              }
            ];
          };
        };
      };
      "tls" = {
        "certificates" = {
          "automate" = [ "cache.local" ];
        };
      };
    };
  };

  # Scripts for managing Caddy
  environment.systemPackages = with pkgs; [
    caddy
  ];

}
