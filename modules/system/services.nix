{
  config,
  lib,
  pkgs,
  ...
}:

{

  systemd.services.docker-pull-images = {
    description = "Pre-pull Docker images";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker pull nvcr.io/nvidia/pytorch:25.09-py3
      #${pkgs.docker}/bin/docker pull ghcr.io/huggingface/text-generation-inference:latest
    '';
  };

  # Configure ollama service for GPU access and centralized storage
  systemd.services.ollama = {
    environment = lib.mkIf config.kernelcore.ml.models-storage.enable {
      # Override default ollama models path with centralized storage
      OLLAMA_MODELS = lib.mkForce "${config.kernelcore.ml.models-storage.baseDirectory}/ollama/models";
    };

    serviceConfig = {
      # Use declaratively created user instead of DynamicUser
      DynamicUser = lib.mkForce false;
      User = "ollama";
      Group = "ollama";

      # GPU device access
      DeviceAllow = [
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-uvm rw"
      ];
      # SupplementaryGroups moved to user definition in modules/system/ml-gpu-users.nix
      # to avoid duplication and centralize group management

      # ReadWritePaths for centralized ML models storage
      # Required because ProtectSystem=strict makes /var read-only by default
      ReadWritePaths = lib.mkIf config.kernelcore.ml.models-storage.enable [
        "${config.kernelcore.ml.models-storage.baseDirectory}/ollama"
      ];

      # Graceful shutdown for GPU memory release
      TimeoutStopSec = "30s";
    };
  };

}
