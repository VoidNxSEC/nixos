{ pkgs ? import <nixpkgs> { } }:

let
  pythonEnv = pkgs.python311.withPackages (ps: with ps; [
    # Core crawling
    httpx
    aiohttp
    aiosqlite
    pydantic
    
    # CLI
    typer
    rich
    
    # Utils
    fake-useragent
    
    # Dev
    pytest
    pytest-asyncio
    ruff
    pip
  ]);
in
pkgs.mkShell {
  name = "spider-nix-dev";
  
  buildInputs = with pkgs; [
    pythonEnv
    playwright-driver.browsers
    
    # Build tools
    nodePackages.npm
  ];
  
  shellHook = ''
    export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    
    echo "🕷️  SpiderNix Development Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Python: $(python --version)"
    echo "Playwright browsers: $PLAYWRIGHT_BROWSERS_PATH"
    echo ""
    echo "Commands:"
    echo "  pip install -e .        Install spider-nix"
    echo "  pip install crawlee[playwright]  Install crawlee"
    echo "  pytest tests/           Run tests"
    echo "  spider-nix --help       CLI help"
  '';
}
