# ML Offload API - Flake Package

Independent flake for the ML Offload Manager REST API.

## Quick Start

### Development

```bash
# Enter dev shell
nix develop

# Build
cargo build --release

# Run locally
cargo run
```

### Testing the Flake

```bash
# Build the package
nix build

# Run the API
nix run

# Enter dev shell
nix develop
```

## NixOS Integration

### As Flake Input

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    ml-offload-api = {
      url = "git+file:///etc/nixos/modules/ml/orchestration/api";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ml-offload-api }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ml-offload-api.nixosModules.default
        {
          services.ml-offload-api = {
            enable = true;
            host = "127.0.0.1";
            port = 9000;
          };
        }
      ];
    };
  };
}
```

### Configuration Options

```nix
services.ml-offload-api = {
  enable = true;              # Enable the service
  
  # Network
  host = "127.0.0.1";         # Bind address
  port = 9000;                # API port
  corsEnabled = false;        # Enable CORS
  openFirewall = false;       # Open firewall port
  
  # Paths
  dataDir = "/var/lib/ml-offload";          # Data directory
  modelsPath = "/var/lib/ml-models";        # Models directory
  dbPath = "/var/lib/ml-offload/registry.db"; # SQLite database
  
  # Logging
  logLevel = "info";          # error, warn, info, debug, trace
  
  # Package
  package = inputs.ml-offload-api.packages.${system}.default;
};
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Simple health check |
| `/api/health` | GET | Detailed backend health |
| `/backends` | GET | List available backends |
| `/models` | GET | List models from registry |
| `/vram` | GET | VRAM status |
| `/load` | POST | Load model on backend |
| `/unload` | POST | Unload model from backend |
| `/switch` | POST | Switch model (hot-reload) |
| `/v1/chat/completions` | POST | OpenAI-compatible chat |
| `/v1/embeddings` | POST | OpenAI-compatible embeddings |
| `/ws` | GET | WebSocket for real-time updates |

## Building

### With Nix

```bash
nix build
```

### With Cargo

```bash
# Requires: openssl, sqlite, pkg-config
cargo build --release
```

## Development

```bash
# Enter dev shell
nix develop

# Run tests
cargo test

# Format code
cargo fmt

# Lint
cargo clippy

# Run locally
cargo run
```

## Service Management

```bash
# Status
systemctl status ml-offload-api

# Logs
journalctl -xeu ml-offload-api

# Restart
systemctl restart ml-offload-api
```

## License

MIT
