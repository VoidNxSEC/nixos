# NVIDIA Brev CLI
#
# Local source build so we can pin, patch, and wrap Brev independently of
# nixpkgs lag.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kernelcore.packages."brev-cli";

  package = pkgs.buildGoModule rec {
    pname = "brev-cli";
    version = cfg.version;

    src = pkgs.fetchFromGitHub {
      owner = "brevdev";
      repo = "brev-cli";
      rev = "v${version}";
      hash = cfg.srcHash;
    };

    vendorHash = cfg.vendorHash;
    subPackages = [ "." ];

    postPatch = ''
      substituteInPlace pkg/cmd/register/gpu_nvml.go \
        --replace-fail '//go:build linux || windows' '//go:build (linux || windows) && cgo'

      cat > pkg/cmd/register/gpu_nvml_stub.go <<'EOF'
      //go:build (linux || windows) && !cgo

      package register

      func probeGPUsNVML() ([]GPU, []Interconnect) {
      	return nil, nil
      }
      EOF
    '';

    env.CGO_ENABLED = "0";

    ldflags = [
      "-s"
      "-w"
      "-X github.com/brevdev/brev-cli/pkg/cmd/version.Version=v${version}"
    ];

    doCheck = false;

    postInstall = ''
      if [ -x "$out/bin/brev-cli" ]; then
        mv "$out/bin/brev-cli" "$out/bin/brev"
      elif [ ! -x "$out/bin/brev" ]; then
        first_bin="$(find "$out/bin" -maxdepth 1 -type f -executable | head -n 1)"
        if [ -n "$first_bin" ]; then
          mv "$first_bin" "$out/bin/brev"
        fi
      fi
    '';

    meta = {
      description = "NVIDIA Brev CLI for managing remote GPU instances";
      homepage = "https://brev.nvidia.com";
      license = lib.licenses.asl20;
      mainProgram = "brev";
      platforms = lib.platforms.linux;
    };
  };
in
{
  options.kernelcore.packages."brev-cli" = {
    enable = lib.mkEnableOption "locally packaged NVIDIA Brev CLI";

    version = lib.mkOption {
      type = lib.types.str;
      default = "0.6.324";
      description = "Brev CLI release tag to build from source.";
    };

    srcHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-Gy7pL4GYO2a7Q3z3xarhXB2EGSzojYEmD4ynHBwQ/9Y=";
      description = "Hash for the Brev CLI source archive.";
    };

    vendorHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-rB6uqkpnc+SlbzNvtTOnDCIJIpxoiyPb/lsiRYkDltg=";
      description = "Hash for vendored Go module dependencies.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Locally built Brev CLI package.";
    };
  };

  config = lib.mkMerge [
    {
      kernelcore.packages."brev-cli".package = package;
    }

    (lib.mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];
    })
  ];
}
