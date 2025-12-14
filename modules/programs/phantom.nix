# Phantom AI Toolkit - NixOS Module
# Integrates Phantom as a flake input for document intelligence
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.phantom;

  # Build phantom from local source
  phantomPkg = pkgs.python3Packages.buildPythonApplication {
    pname = "phantom";
    version = "2.0.0";
    format = "pyproject";

    src = /home/kernelcore/dev/Projects/phantom;

    nativeBuildInputs = with pkgs.python3Packages; [ hatchling ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      pydantic
      rich
      typer
      pandas
      numpy
      requests
      httpx
      fastapi
      uvicorn
      psutil
      pyyaml
      aiofiles
    ];

    # Skip tests for now
    doCheck = false;
  };

  # GTK4 desktop application
  phantomDesktop = pkgs.python3Packages.buildPythonApplication {
    pname = "phantom-desktop";
    version = "2.0.0";
    format = "other";

    src = /home/kernelcore/dev/Projects/phantom;

    nativeBuildInputs = [
      pkgs.wrapGAppsHook4
      pkgs.gobject-introspection
    ];

    buildInputs = [
      pkgs.gtk4
      pkgs.libadwaita
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      pygobject3
      pycairo
      pydantic
      rich
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin $out/share/applications $out/share/phantom
      cp apps/desktop/main.py $out/share/phantom/phantom-desktop.py

      cat > $out/bin/phantom-desktop << EOF
      #!/usr/bin/env bash
      exec ${pkgs.python3}/bin/python3 $out/share/phantom/phantom-desktop.py "\$@"
      EOF
      chmod +x $out/bin/phantom-desktop

      cat > $out/share/applications/phantom-desktop.desktop << EOF
      [Desktop Entry]
      Name=Phantom Desktop
      Comment=AI-Powered Document Intelligence
      Exec=$out/bin/phantom-desktop
      Icon=utilities-system-monitor
      Type=Application
      Categories=Utility;Development;
      Terminal=false
      EOF
    '';
  };
in
{
  options.programs.phantom = {
    enable = lib.mkEnableOption "Phantom AI toolkit";

    desktop.enable = lib.mkEnableOption "Phantom GTK4 desktop application";

    aliases.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Phantom shell aliases";
    };

    providers = {
      llamacpp.url = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:8080";
        description = "LlamaCPP server URL";
      };

      ollama.url = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:11434";
        description = "Ollama server URL";
      };
    };

    vectorDb.path = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/phantom/vectors";
      description = "Path for vector database storage";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install packages
    environment.systemPackages = [
      phantomPkg
    ]
    ++ lib.optionals cfg.desktop.enable [
      phantomDesktop
    ];

    # Create state directory
    systemd.tmpfiles.rules = [
      "d /var/lib/phantom 0755 root root -"
      "d ${cfg.vectorDb.path} 0755 root root -"
    ];

    # Environment variables
    environment.sessionVariables = {
      LLAMACPP_URL = cfg.providers.llamacpp.url;
      OLLAMA_URL = cfg.providers.ollama.url;
      PHANTOM_VECTOR_PATH = cfg.vectorDb.path;
    };

    # Shell aliases
    environment.shellAliases = lib.mkIf cfg.aliases.enable {
      # Core commands
      phantom = "python3 -m phantom.cli.main";
      px = "phantom extract";
      pa = "phantom analyze";
      pc = "phantom classify";

      # RAG commands
      prag = "phantom rag query";
      pingest = "phantom rag ingest";
      psearch = "phantom rag search";

      # Tools
      pvram = "phantom tools vram";
      pprompt = "phantom tools prompt";
      paudit = "phantom tools audit";

      # API
      papi = "phantom api serve";
    };
  };
}
