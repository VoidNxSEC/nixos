{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.containers.docker.enable = mkEnableOption "Enable Docker container support";
  };

  config = mkIf config.kernelcore.containers.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };

      daemon.settings = {
        data-root = "/var/lib/docker";
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
        max-concurrent-downloads = 10;
        max-concurrent-uploads = 5;
        storage-driver = "overlay2";
        dns = [
          "8.8.8.8"
          "1.1.1.1"
        ];
      };
    };
  };
}
