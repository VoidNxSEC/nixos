# ═══════════════════════════════════════════════════════════════
# GEMINI CLI - FHS ENVIRONMENT (npm ENOTCACHED workaround)
# ═══════════════════════════════════════════════════════════════
# Switched from buildNpmPackage to buildFHSEnv to resolve npm
# cache issues. Gemini CLI has built-in bubblewrap sandboxing.
# ═══════════════════════════════════════════════════════════════

{ ... }:

{
  imports = [
    #./fhs.nix # FHS environment implementation --.Deprecated
    ./gemini-cli.nix
  ];
}
