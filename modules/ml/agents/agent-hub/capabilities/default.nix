# Agent Hub - Capabilities Aggregator
#
# Importa todas as capabilities disponíveis para o Agent Hub
#
{ ... }:
{
  imports = [
    ./speech.nix
    # Adicione novas capabilities aqui:
    # ./vision.nix
    # ./code-execution.nix
    # ./web-scraping.nix
  ];
}
