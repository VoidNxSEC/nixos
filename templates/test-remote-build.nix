{
  pkgs ? import <nixpkgs> { },
}:

pkgs.runCommand "test-remote-build-$(builtins.currentTime)" { } ''
  echo "Building on: $(hostname)"
  echo "CPU info: $(cat /proc/cpuinfo | grep 'model name' | head -1)"
  echo "Build completed at: $(date)"
  mkdir -p $out
  echo "Remote build successful!" > $out/result.txt
''
