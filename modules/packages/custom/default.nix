{ ... }:

# ═══════════════════════════════════════════════════════════════
# CUSTOM PACKAGES - User-Defined Builds
# ═══════════════════════════════════════════════════════════════
# Purpose: Custom builds of Gemini CLI and Antigravity
# Features: Individual sandboxing, performance tuning, FHS support
# ═══════════════════════════════════════════════════════════════

{
  imports = [
    ./gemini-antigravity.nix
  ];
}
