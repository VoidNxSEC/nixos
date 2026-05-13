{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Garante que os pacotes necessários estão instalados
  environment.systemPackages = with pkgs; [
    jq
    watch
  ];

  # Injeta os scripts no perfil do sistema
  #environment.etc = {
  #"profile.d/void.sh" = {
  #  source = ./bash/void.sh;
  #  mode = "0755";
  #};
  #"profile.d/ai-ml-stack.sh" = {
  #  source = ./bash/ai-ml-stack.sh;
  #  mode = "0755";
  #};
  #"profile.d/ai-compose-stack.sh" = {
  #  source = ./bash/ai-compose-stack.sh;
  #  mode = "0755";
  #};
  #};

  users.users.kernelcore.extraGroups = [ "docker" ];
}
