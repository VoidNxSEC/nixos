{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.system.ml-gpu-users;
in
{
  options.kernelcore.system.ml-gpu-users = {
    enable = mkEnableOption "Enable centralized ML/GPU user and group management";
  };

  config = mkIf cfg.enable {
    # Centralized ML service user definitions with GPU access
    # This module consolidates all ML service users to avoid duplication

    #  isSystemUser = true;
    #  extraGroups = [
    #    "video" # GPU video device access
    #    "render" # GPU render device access
    #    "nvidia" # NVIDIA GPU access
    #  ];
    #};

    users.users.llamacpp = {
      isSystemUser = true;
      group = "llamacpp";
      description = "Llama.cpp ML service user";
      extraGroups = [
        "video" # GPU video device access
        "render" # GPU render device access
        "nvidia" # NVIDIA GPU access
      ];
    };

    users.groups.llamacpp = { };

    users.users.ml-offload = {
      isSystemUser = true;
      group = "ml-offload";
      description = "ML Offload Manager service user";
      extraGroups = [
        "video" # GPU video device access
        "render" # GPU render device access
        "nvidia" # NVIDIA GPU access
      ];
    };

    users.groups.ml-offload = { };
  };
}
