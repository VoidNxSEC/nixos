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
  # preBuild removido, vars movidas para buildPhase para garantir persistência

  buildPhase = ''
    export HOME=$TMPDIR
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-cache
    
    mkdir -p $ZIG_GLOBAL_CACHE_DIR
    mkdir -p $ZIG_LOCAL_CACHE_DIR

    echo "DEBUG: HOME=$HOME"
    echo "DEBUG: ZIG_GLOBAL_CACHE_DIR=$ZIG_GLOBAL_CACHE_DIR"
    
    zig build -Doptimize=ReleaseSafe --prefix $out --verbose
  '';

  meta = with lib; {
    description = "Userspace governor for Intel iGPU memory management";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ "marcosfpina" ];
  };
}
