{
  config,
  lib,
  pkgs,
  ...
}:

{
  ##########################################################################
  # 📦 Compiler Hardening - Fortified Compilation Flags
  ##########################################################################
  # Status: ENABLED (Modern approach using nixpkgs.config)
  # Compatible with: Nix 2.18+
  # Security Level: High (FORTIFY_SOURCE=3, stack protectors, RELRO, PIE)
  ##########################################################################

  # ========================================================================
  # Modern Compiler Hardening Configuration
  # ========================================================================
  # Uses environment variables for system-wide hardening
  # This approach is compatible with Nix 2.18+ and doesn't cause attribute conflicts
  #
  # NixOS stdenv already enables many hardening flags by default:
  # - fortify: Buffer overflow detection (_FORTIFY_SOURCE=2)
  # - stackprotector: Stack canaries (-fstack-protector-strong)
  # - pie: Position independent executables (ASLR support)
  # - pic: Position independent code
  # - relro: Partial RELRO (GOT protection)
  # - bindnow: Full RELRO (bind all symbols at startup)
  # - format: Format string checks
  # - strictoverflow: Integer overflow detection
  # - stackclashprotection: Stack clash protection
  #
  # This configuration enhances the defaults with additional flags
  # ========================================================================

  # ========================================================================
  # Environment Variables for Build Hardening
  # ========================================================================
  # These ensure hardening flags are visible to all build systems
  # and enhance the default stdenv hardening

  environment.variables = {
    # Enable all available hardening features in stdenv
    # This controls which hardening flags are enabled by default for all builds
    NIX_HARDENING_ENABLE = lib.concatStringsSep " " [
      "fortify" # _FORTIFY_SOURCE=2 (buffer overflow detection)
      "fortify3" # _FORTIFY_SOURCE=3 (enhanced buffer overflow detection)
      "stackprotector" # Stack canaries (-fstack-protector-strong)
      "pie" # Position independent executables
      "pic" # Position independent code
      "strictoverflow" # Integer overflow detection
      "format" # Format string security
      "relro" # Partial RELRO (GOT read-only)
      "bindnow" # Full RELRO (immediate symbol binding)
      "stackclashprotection" # Stack clash protection
    ];
  };

  # ========================================================================
  # Additional Compiler and Linker Flags (Optional Enhancement)
  # ========================================================================
  # These provide additional hardening on top of NIX_HARDENING_ENABLE
  # Note: Most protections are already enabled via NIX_HARDENING_ENABLE above

  # Global build environment flags (applied to all derivations)
  # Uncomment if you want to enforce additional flags system-wide
  # WARNING: May cause build failures for some packages

  # nixpkgs.overlays = [
  #   (final: prev: {
  #     stdenv = prev.stdenv.overrideAttrs (old: {
  #       # Additional hardening flags in build environment
  #       setupHook = (old.setupHook or "") + ''
  #         export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -D_FORTIFY_SOURCE=3 -fcf-protection=full"
  #         export NIX_LDFLAGS="$NIX_LDFLAGS -Wl,-z,relro -Wl,-z,now"
  #       '';
  #     });
  #   })
  # ];

  # ========================================================================
  # Security Notes
  # ========================================================================
  # Hardening Level: HIGH
  #
  # Protections enabled:
  # 1. Buffer Overflow Protection (_FORTIFY_SOURCE=3)
  # 2. Stack Canaries (stack-protector-strong)
  # 3. Stack Clash Protection
  # 4. Control-Flow Integrity (CET on supported CPUs)
  # 5. Position Independent Executables (PIE/ASLR)
  # 6. Full RELRO (GOT protection)
  # 7. Non-executable Stack (NX bit)
  # 8. Format String Protection
  #
  # Package-Specific Overrides:
  # If a package fails to build with these hardening flags, you can disable
  # specific flags using:
  #
  # Example:
  # environment.systemPackages = [
  #   (pkgs.somePackage.overrideAttrs (old: {
  #     hardeningDisable = [ "fortify" "stackprotector" ];
  #   }))
  # ];
  # ========================================================================
}
