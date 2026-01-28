{
  description = "Agent Hub Nexus Core - Rust/gRPC Control Plane";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      system = "x86_64-linux";
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs { inherit system overlays; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (rust-bin.stable.latest.default.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
            ];
            targets = [ "wasm32-wasi" ];
          })
          protobuf
          grpc-tools
          pkg-config
          openssl
          kafka-console-tools
          # System dependencies for Hyprland IPC
          libcommon
          wayland
        ];

        shellHook = ''
          echo "󱘗 Agent Hub Development Environment"
          echo "Kafka/Redpanda: localhost:9092"
          echo "gRPC: localhost:50051"
        '';
      };
    };
}
