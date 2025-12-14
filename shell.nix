{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    gcc
    pkg-config # Essencial para achar as libs do C
    gtk4 # A biblioteca gráfica
    glib # A biblioteca base de tipos do GNOME
  ];

  shellHook = ''
    echo "Ambiente de Desenvolvimento GTK4 + C carregado."
    # Dica: Compila com:
    # gcc main.c -o meu_app $(pkg-config --cflags --libs gtk4)
  '';
}
