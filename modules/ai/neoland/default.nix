{ ... }:
{
  imports = [
    ./control-plane.nix
    ./dspy-pipeline.nix
    ./agent-config.nix
    ./checkpoint-storage.nix
  ];
}
