{
  config,
  lib,
  pkgs,
  ...
}:

# LLaMA Model Router
#
# Thin HTTP proxy that:
#  1. Exposes GET /v1/models returning ALL profiles from profiles.json
#  2. Intercepts POST /v1/* – reads the "model" field, triggers llama-swap
#     if the requested model differs from the active one, then forwards.
#
# Any OpenAI-compatible client (Continue.dev, Open-WebUI, SillyTavern…)
# can list and switch models by selecting from /v1/models without manual shell
# commands.  The router sits at :8080; llamacpp-swap stays on :8081.

with lib;

let
  cfg = config.services.llamacpp-model-router;

  routerPy = pkgs.writeText "llama-model-router.py" ''
    #!/usr/bin/env python3
    """Minimal OpenAI-compatible model router for llamacpp-swap."""
    import http.server
    import json
    import os
    import subprocess
    import threading
    import urllib.request
    import urllib.error
    import sys

    PROFILES_JSON = "/var/lib/llamacpp-swap/profiles.json"
    CURRENT_PROFILE_FILE = "/var/lib/llamacpp-swap/current-profile"
    BACKEND_URL = f"http://127.0.0.1:${toString cfg.backendPort}"

    swap_lock = threading.Lock()

    def read_profiles():
        try:
            with open(PROFILES_JSON) as f:
                return json.load(f)
        except Exception:
            return {}

    def current_profile():
        try:
            with open(CURRENT_PROFILE_FILE) as f:
                return f.read().strip()
        except Exception:
            return ""

    def do_swap(target_profile, profiles):
        """Low-level swap: update symlink + profile file + restart service."""
        profile_data = profiles.get(target_profile, {})
        model_path = profile_data.get("modelPath", "")
        if not model_path:
            print(f"[router] no modelPath for profile {target_profile}", flush=True)
            return False
        symlink = "/var/lib/llamacpp-swap/current-model"
        profile_file = CURRENT_PROFILE_FILE
        try:
            # Update symlink atomically
            tmp = symlink + ".new"
            if os.path.exists(tmp) or os.path.islink(tmp):
                os.unlink(tmp)
            os.symlink(model_path, tmp)
            os.rename(tmp, symlink)
            # Update current-profile
            with open(profile_file, "w") as f:
                f.write(target_profile)
            # Restart the inference service
            subprocess.run(
                ["${pkgs.systemd}/bin/systemctl", "restart", "llamacpp-swap.service"],
                timeout=60, check=False, capture_output=True
            )
            return True
        except Exception as e:
            print(f"[router] swap error: {e}", flush=True)
            return False

    def maybe_swap(requested):
        if not requested or requested in ("default", ""):
            return
        with swap_lock:
            if current_profile() == requested:
                return
            profiles = read_profiles()
            if requested not in profiles:
                print(f"[router] unknown profile: {requested}", flush=True)
                return
            print(f"[router] switching to model: {requested}", flush=True)
            do_swap(requested, profiles)

    class RouterHandler(http.server.BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            print(f"[router] {self.address_string()} {fmt % args}", flush=True)

        def send_json(self, body, code=200):
            data = json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self):
            if self.path == "/v1/models":
                profiles = read_profiles()
                active = current_profile()
                models = [
                    {
                        "id": name,
                        "object": "model",
                        "created": 0,
                        "owned_by": "llamacpp-swap",
                        "display_name": p.get("displayName", name),
                        "active": name == active,
                    }
                    for name, p in profiles.items()
                ]
                self.send_json({"object": "list", "data": models})
                return
            if self.path == "/health":
                try:
                    urllib.request.urlopen(BACKEND_URL + "/health", timeout=3)
                    self.send_json({"status": "ok", "backend": "ready"})
                except Exception:
                    self.send_json({"status": "loading", "backend": "not ready"}, code=503)
                return
            self._proxy(timeout=10)

        def do_POST(self):
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length) if length > 0 else b""
            try:
                payload = json.loads(body) if body else {}
                maybe_swap(payload.get("model", ""))
            except Exception:
                pass
            self._proxy(body, timeout=300)

        def _proxy(self, body=b"", timeout=30):
            url = BACKEND_URL + self.path
            headers = {
                k: v for k, v in self.headers.items()
                if k.lower() not in ("host", "content-length")
            }
            if body:
                headers["Content-Length"] = str(len(body))
            try:
                req = urllib.request.Request(url, data=body or None,
                                             headers=headers, method=self.command)
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    resp_body = resp.read()
                    self.send_response(resp.status)
                    for k, v in resp.headers.items():
                        if k.lower() not in ("transfer-encoding",):
                            self.send_header(k, v)
                    self.send_header("Content-Length", str(len(resp_body)))
                    self.end_headers()
                    self.wfile.write(resp_body)
            except urllib.error.HTTPError as e:
                resp_body = e.read()
                self.send_response(e.code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(resp_body)))
                self.end_headers()
                self.wfile.write(resp_body)
            except (BrokenPipeError, ConnectionResetError):
                print(f"[router] client disconnected before response for {self.path}", flush=True)
            except Exception as e:
                err = json.dumps({"error": str(e)}).encode()
                try:
                    self.send_response(503 if "timed out" in str(e) or "refused" in str(e) else 502)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Content-Length", str(len(err)))
                    self.end_headers()
                    self.wfile.write(err)
                except (BrokenPipeError, ConnectionResetError):
                    print(f"[router] client disconnected during error response for {self.path}", flush=True)

    if __name__ == "__main__":
        host = "${cfg.host}"
        port = ${toString cfg.port}
        server = http.server.ThreadingHTTPServer((host, port), RouterHandler)
        print(f"[router] listening on {host}:{port}, backend={BACKEND_URL}", flush=True)
        server.serve_forever()
  '';
in
{
  options.services.llamacpp-model-router = {
    enable = lib.mkEnableOption "LLaMA model-router proxy (multi-model /v1/models selector)";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address for the router.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port clients connect to (the router port).";
    };

    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Port llamacpp-swap listens on (forwarded to).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.llamacpp-model-router = {
      description = "LLaMA Model Router – multi-model proxy for llamacpp-swap";
      after = [
        "network.target"
        "llamacpp-swap.service"
      ];
      wants = [ "llamacpp-swap.service" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        (python313.withPackages (_: [ ]))
        bash
        coreutils
        jq
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.python3}/bin/python3 ${routerPy}";
        Restart = "always";
        RestartSec = 3;
        RuntimeDirectory = "llamacpp-model-router";

        User = "llamacpp-swap";
        Group = "llamacpp-swap";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          "/run/llamacpp-model-router"
          "/var/lib/llamacpp-swap"
        ];
      };
    };

    networking.firewall = lib.mkIf (cfg.host == "0.0.0.0") {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
