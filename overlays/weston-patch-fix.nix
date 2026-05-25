# overlays/weston-patch-fix.nix
# Fix para build failure do weston no nixpkgs 26.05
#
# Histórico:
#   weston-14.0.1: patch b4386289 tinha hash errado no nixpkgs → override com hash correto
#   weston-15.0.0: patch b4386289 já incluído no source → remover do patches list
#
# Patch: vnc: Allow neatvnc 0.9.0 (weston MR#1649)
# Atualizado: 2026-03-05

final: prev: {
  weston = prev.weston.overrideAttrs (old: {
    # Remover patch que já está incorporado no weston 15.0.0
    patches = builtins.filter (
      p:
      !(
        builtins.isAttrs p
        &&
          (p.url or "")
          == "https://gitlab.freedesktop.org/wayland/weston/-/commit/b4386289d614f26e89e1c6eb17e048826e925ed1.patch"
      )
    ) (old.patches or [ ]);
  });
}
