{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.kernelcore.swissknife = {
    enable = lib.mkEnableOption "Swissknife Debug Tools";
  };

  config = lib.mkIf config.kernelcore.swissknife.enable {
    environment.systemPackages = with pkgs.swissknife-tools; [
      swiss-rebuild
      swiss-doctor
      swiss-monitor
    ];

    # Handy aliases
    environment.shellAliases = {
      doctor = "sudo swiss-doctor";
      rebuild-monitor = "sudo swiss-rebuild";
      monitor = "sudo swiss-monitor";
    };
  };
}
