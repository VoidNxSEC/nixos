# Intel i915 Memory Governor Module (DISABLED - project moved externally)
# Re-enable when i915-governor is available as flake input
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.i915-governor;
in
{
  options.services.i915-governor = {
    enable = mkEnableOption "Intel i915 Memory Governor";
    thresholds = {
      gpuCritical = mkOption {
        type = types.int;
        default = 90;
        description = "Porcentagem de uso da iGPU para iniciar throttling";
      };
      memoryPressure = mkOption {
        type = types.int;
        default = 80;
        description = "Pressão de memória (PSI) para disparar compactação";
      };
    };
  };

  config = mkIf cfg.enable {
    # Placeholder - re-enable when package available via flake input
    warnings = [ "i915-governor: Package not available - project moved to external repository" ];
  };
}
