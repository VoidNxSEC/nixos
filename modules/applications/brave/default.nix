{
  config,
  lib,
  ...
}:

# ─────────────────────────────────────────────────────────────────────────────
# Brave Browser — seletor de perfil
#
# Uso:
#   kernelcore.applications.brave = {
#     enable  = true;
#     profile = "secure";   # "secure" | "hardened"
#   };
#
# Perfis:
#   secure   — Firejail + limite de memória GPU (./secure.nix)
#   hardened — enterprise policies + DoH forçado + netfilter (./hardened.nix)
#
# As options específicas de cada perfil continuam disponíveis em
# kernelcore.applications.brave-secure.* e kernelcore.applications.brave-hardened.*
# ─────────────────────────────────────────────────────────────────────────────

with lib;

let
  cfg = config.kernelcore.applications.brave;
in
{
  imports = [
    ./secure.nix
    ./hardened.nix
  ];

  options.kernelcore.applications.brave = {
    enable = mkEnableOption "Brave browser (profile-based)";

    profile = mkOption {
      type = types.enum [
        "secure"
        "hardened"
      ];
      default = "secure";
      description = "Perfil de sandbox/hardening do Brave a ativar.";
    };
  };

  config = mkIf cfg.enable {
    kernelcore.applications.brave-secure.enable = mkDefault (cfg.profile == "secure");
    kernelcore.applications.brave-hardened.enable = mkDefault (cfg.profile == "hardened");
  };
}
