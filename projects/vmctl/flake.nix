{
  description = "vmctl - Lightweight VM Manager for QEMU";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        vmctl = pkgs.buildGoModule {
          pname = "vmctl";
          version = "0.1.0";
          src = ./.;
          
          vendorHash = null; # Will be updated after go mod tidy
          
          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook4
          ];
          
          buildInputs = with pkgs; [
            gtk4
            glib
            gobject-introspection
          ];
          
          ldflags = [ "-s" "-w" ];
          
          meta = with pkgs.lib; {
            description = "Lightweight VM manager with optional GTK4 GUI";
            homepage = "https://github.com/VoidNxSEC/vmctl";
            license = licenses.mit;
            maintainers = [ ];
            mainProgram = "vmctl";
          };
        };
      in
      {
        packages.default = vmctl;
        packages.vmctl = vmctl;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Go Toolchain
            go
            gopls
            gotools
            go-tools
            delve
            
            # GTK4 Development
            gtk4
            glib
            gobject-introspection
            pkg-config
            
            # QEMU for testing
            qemu
            qemu_kvm
            
            # Utilities
            jq
          ];
          
          shellHook = ''
            export CGO_ENABLED=1
            export GOFLAGS="-mod=mod"
            echo "🖥️  vmctl Development Environment"
            echo "   Go: $(go version | cut -d' ' -f3)"
            echo "   GTK4: $(pkg-config --modversion gtk4 2>/dev/null || echo 'not found')"
            echo ""
            echo "Commands:"
            echo "   go run ./cmd/vmctl     - Run vmctl"
            echo "   go build ./cmd/vmctl   - Build vmctl"
            echo "   go test ./...          - Run tests"
          '';
        };
      }
    );
}
