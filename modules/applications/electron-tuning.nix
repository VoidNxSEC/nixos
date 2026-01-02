{
  config,
  lib,
  pkgs,
  ...
}:

{
  # =================================================================
  # ELECTRON/CHROMIUM PERFORMANCE TUNING (SANITIZED)
  # =================================================================

  environment.sessionVariables = {
    # MANTIDO: Otimização de processos, mas com limite seguro (8 vs 4)
    # 4 era muito pouco e causava engasgos em apps pesados.
    ELECTRON_MAX_RENDERER_PROCESSES = "8";

    # MANTIDO: Silencia logs inúteis
    ELECTRON_ENABLE_LOGGING = "0";
    ELECTRON_NO_ATTACH_CONSOLE = "1";

    # ADICIONADO: O jeito certo de ativar Wayland sem flags quebradas
    # Isso instrui o Electron a negociar com o compositor automaticamente.
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  nixpkgs.overlays = [
    (final: prev: {
      antigravity =
        if prev ? antigravity then
          prev.antigravity.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/antigravity \

                # --- O QUE MUDOU: Use --set (Env Vars) ao invés de flags ---

                # Garante que o Electron saiba que pode usar Wayland
                --set ELECTRON_OZONE_PLATFORM_HINT "auto" \

                # Habilita decorações de janela (barras de título) no Wayland
                --set ELECTRON_ENABLE_WAYLAND_IME "1" \

                # --- CHROMIUM FLAGS: Apenas o que funciona ---
                # Removemos --disable-dev-shm-usage para manter a performance do Kernel
                # Removemos flags que o wrapper do Antigravity não reconhece

                --add-flags "--process-per-site" \
                --add-flags "--disk-cache-size=104857600" \
                --add-flags "--ignore-gpu-blocklist" \
                --add-flags "--enable-zero-copy"
            '';
          })
        else
          prev.antigravity;

      # Brave (Mantido igual pois já estava funcionando bem)
      brave =
        if prev ? brave then
          prev.brave.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/brave \
                --add-flags "--process-per-site --disk-cache-size=104857600 --ignore-gpu-blocklist"
            '';
          })
        else
          prev.brave;
    })
  ];
}
