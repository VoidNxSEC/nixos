{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.hostName = "nx";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      3389 # RDP
      22 # SSH
      873 # Rsync
      8888 # Jupyter
      8000 # ST
      8080 # Misc.
      6006 # TensorBoard
      7860 # Gradio (Stable Diffusion WebUI)
      8000 # FastAPI/dev servers
      9000 # AI Audio
      9090
      9100
      9400
      9999
      5000 # Flask
      5002 # AI TTS
      5432 # PostGresql Docker Hardened
      6379 # Redis Docker
      16686 # Jaeger Observatility Trace
      14268 # Jaeger UI
      3000 # React dev server
      11434 # Ollama API
      443
      80
      53
    ];

    # Trusted interfaces (Docker bridges)
    # docker0: default bridge
    # br-+: custom Docker Compose networks
    trustedInterfaces = [
      "docker0"
      "br-+"
    ];
    # Comandos adicionais para limpar as regras do iptables antes de aplicar novas
    extraCommands = '''';
  };
}
