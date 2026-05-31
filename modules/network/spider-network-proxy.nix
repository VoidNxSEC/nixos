# DEACTIVATED: Spider Network Proxy module
# Reason: the upstream package (github:VoidNxSEC/spider-network) is broken at
# the build level — no real `vendorHash` was ever derived because the Go build
# itself never produced one. `vendorHash = lib.fakeHash` below is a leftover
# placeholder that exists *because* the pkg can't build, not the other way
# around. Fixing this requires fixing the upstream repo's Go module / vendor
# setup so the build succeeds, then deriving and pinning the real vendorHash.
# To re-enable after upstream is fixed: replace `vendorHash = lib.fakeHash;`
# with the real hash, uncomment the body below, re-add this file to
# modules/network/default.nix imports, and restore the host config block in
# hosts/kernelcore/configuration.nix.

{ ... }:
{ }

# {
#   config,
#   lib,
#   pkgs,
#   inputs,
#   ...
# }:
#
# with lib;
#
# let
#   cfg = config.kernelcore.network.spider-network-proxy;
#
#   spider-proxy = pkgs.buildGoModule {
#     pname = "spider-network-proxy";
#     version = "0.1.0";
#     src = inputs.spider-nix-network;
#     subPackages = [ "cmd/spider-network-proxy" ];
#     vendorHash = lib.fakeHash;
#   };
#
#   configFile = pkgs.writeText "spider-network-proxy.toml" ''
#     [proxy]
#     http_listen = "${cfg.httpListen}"
#     socks5_listen = "${cfg.socks5Listen}"
#
#     [tls]
#     fingerprint_rotation = ${if cfg.fingerprintRotation then "true" else "false"}
#     profile_cache_ttl_hours = ${toString cfg.profileCacheTTL}
#     browser_pool = [${concatMapStringsSep ", " (b: ''"${b}"'') cfg.browserPool}]
#
#     [http2]
#     randomize_settings = ${if cfg.http2.randomizeSettings then "true" else "false"}
#     priority_frames_enabled = ${if cfg.http2.priorityFrames then "true" else "false"}
#
#     [metrics]
#     enabled = ${if cfg.metrics.enable then "true" else "false"}
#     listen = "${cfg.metrics.listen}"
#   '';
#
# in
# {
#   options.kernelcore.network.spider-network-proxy = {
#     enable = mkEnableOption "Spider Network Proxy (uTLS anti-detection HTTP/SOCKS5)";
#
#     httpListen = mkOption {
#       type = types.str;
#       default = "127.0.0.1:8080";
#       description = "HTTP proxy bind address:port";
#     };
#
#     socks5Listen = mkOption {
#       type = types.str;
#       default = "127.0.0.1:1080";
#       description = "SOCKS5 proxy bind address:port";
#     };
#
#     fingerprintRotation = mkOption {
#       type = types.bool;
#       default = true;
#       description = "Rotate TLS fingerprints per domain";
#     };
#
#     profileCacheTTL = mkOption {
#       type = types.int;
#       default = 24;
#       description = "Hours to cache fingerprint profile per domain";
#     };
#
#     browserPool = mkOption {
#       type = types.listOf types.str;
#       default = [
#         "chrome"
#         "firefox"
#         "safari"
#         "edge"
#       ];
#       description = "Browser TLS profiles to rotate through";
#     };
#
#     http2 = {
#       randomizeSettings = mkOption {
#         type = types.bool;
#         default = true;
#         description = "Randomize HTTP/2 SETTINGS frame";
#       };
#       priorityFrames = mkOption {
#         type = types.bool;
#         default = true;
#         description = "Enable HTTP/2 PRIORITY frame randomization";
#       };
#     };
#
#     metrics = {
#       enable = mkOption {
#         type = types.bool;
#         default = false;
#         description = "Expose Prometheus metrics";
#       };
#       listen = mkOption {
#         type = types.str;
#         default = "127.0.0.1:9090";
#         description = "Metrics server bind address:port";
#       };
#     };
#
#     setSystemProxy = mkOption {
#       type = types.bool;
#       default = false;
#       description = "Set http_proxy/https_proxy/ALL_PROXY env vars system-wide";
#     };
#   };
#
#   config = mkIf cfg.enable {
#     environment.systemPackages = [ spider-proxy ];
#
#     systemd.services.spider-network-proxy = {
#       description = "Spider Network Proxy — uTLS anti-detection HTTP/SOCKS5";
#       wantedBy = [ "multi-user.target" ];
#       after = [ "network.target" ];
#
#       serviceConfig = {
#         Type = "simple";
#         ExecStart = "${spider-proxy}/bin/spider-network-proxy --config ${configFile}";
#         Restart = "on-failure";
#         RestartSec = "5s";
#
#         DynamicUser = true;
#         NoNewPrivileges = true;
#         PrivateTmp = true;
#         ProtectSystem = "strict";
#         ProtectHome = true;
#         ProtectKernelTunables = true;
#         ProtectControlGroups = true;
#         RestrictAddressFamilies = [
#           "AF_INET"
#           "AF_INET6"
#         ];
#         RestrictNamespaces = true;
#         LockPersonality = true;
#         MemoryDenyWriteExecute = true;
#         RestrictRealtime = true;
#         RestrictSUIDSGID = true;
#         PrivateDevices = true;
#       };
#     };
#
#     environment.sessionVariables = mkIf cfg.setSystemProxy {
#       http_proxy = "http://${cfg.httpListen}";
#       https_proxy = "http://${cfg.httpListen}";
#       HTTP_PROXY = "http://${cfg.httpListen}";
#       HTTPS_PROXY = "http://${cfg.httpListen}";
#       ALL_PROXY = "socks5://${cfg.socks5Listen}";
#       all_proxy = "socks5://${cfg.socks5Listen}";
#     };
#   };
# }
