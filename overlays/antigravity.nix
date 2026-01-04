{
  pkgs ? import <nixpkgs> { },
}:

{
  antigravity = super.antigravity.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      # Wrap the antigravity executable so Electron/Chromium gets proper --flags
      # and to ensure a consistent runtime environment (PATH, XDG, LANG).
      wrapProgram $out/bin/antigravity \
        --set ELECTRON_EXTRA_LAUNCH_ARGS "--ozone-platform-hint=auto --enable-features=UseOzonePlatform --enable-wayland-ime --wayland-text-input-version=1" \
        --set XDG_SESSION_TYPE "wayland" \
        --set XDG_RUNTIME_DIR "/run/user/$(id -u)" \
        --set LANG "en_US.UTF-8" \
        --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
        --set PATH '$HOME/.nix-profile/bin:$HOME/.local/bin:/run/wrappers/bin:/nix/profile/bin:$PATH'
    '';
  });
}
