{ lib, stdenv, zig_0_13, libdrm, pkg-config }:

stdenv.mkDerivation {
  pname = "i915-governor";
  version = "0.1.0";

  src = ../.;

  nativeBuildInputs = [
    zig_0_13
    pkg-config
  ];

  buildInputs = [
    libdrm # Essencial para ioctl da GPU
  ];

  # O Zig Cache precisa ser tratado com cuidado no Nix
  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-cache
  '';

  buildPhase = ''
    zig build -Doptimize=ReleaseSafe --prefix $out
  '';

  meta = with lib; {
    description = "Userspace governor for Intel iGPU memory management";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ "marcosfpina" ];
  };
}
