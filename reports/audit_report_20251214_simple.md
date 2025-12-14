# NixOS Configuration Overview (Heuristic Scan)

Generated on: Sun Dec 14 06:52:19 -02 2025
Repository Path: /etc/nixos

## Detected Configurations
| File | Option Path | Value |
| :--- | :--- | :--- |

| flake.nix | `description` | `"home sweet home"` |
| flake.nix | `inputs` | `{` |
| flake.nix | `sops-nix.url` | `"github:Mic92/sops-nix"` |
| flake.nix | `flake-utils.url` | `"github:numtide/flake-utils"` |
| flake.nix | `flake-parts.url` | `"github:hercules-ci/flake-parts"` |
| flake.nix | `home-manager` | `{` |
| flake.nix | `url` | `"github:nix-community/home-manager"` |
| flake.nix | `nixos-hardware.url` | `"github:NixOS/nixos-hardware/master"` |
| flake.nix | `nix-colors.url` | `"github:misterio77/nix-colors"` |
| flake.nix | `securellm-mcp` | `{` |
| flake.nix | `url` | `"git+file:///home/kernelcore/dev/projects/securellm-mcp"` |
| flake.nix | `securellm-bridge` | `{` |
| flake.nix | `url` | `"git+file:///home/kernelcore/dev/projects/securellm-bridge"` |
| flake.nix | `cognitive-vault` | `{` |
| flake.nix | `url` | `"github:VoidNxSEC/cognitive-vault"` |
| flake.nix | `vmctl` | `{` |
| flake.nix | `url` | `"github:VoidNxSEC/vmctl"` |
| flake.nix | `spider-nix` | `{` |
| flake.nix | `url` | `"github:VoidNxSEC/spider-nix"` |
| flake.nix | `i915-governor` | `{` |
| flake.nix | `url` | `"github:VoidNxSEC/i915-governor"` |
| flake.nix | `system` | `"x86_64-linux"` |
| flake.nix | `overlays` | `import ./overlays` |
| flake.nix | `overlays` | `overlays ++ [` |
| flake.nix | `securellm-mcp` | `inputs.securellm-mcp.packages.${system}.default` |
| flake.nix | `securellm-bridge` | `inputs.securellm-bridge.packages.${system}.default` |
| flake.nix | `securellm-mcp` | `{` |
| flake.nix | `type` | `"app"` |
| flake.nix | `program` | `"${self.packages.${system}.securellm-mcp}/bin/securellm-mcp"` |
| flake.nix | `securellm-bridge` | `{` |
| flake.nix | `type` | `"app"` |
| flake.nix | `program` | `"${self.packages.${system}.securellm-bridge}/bin/securellm-bridge"` |
| flake.nix | `iso` | `self.packages.${system}.iso` |
| flake.nix | `vm` | `self.packages.${system}.vm-image` |
| flake.nix | `docker-app` | `self.packages.${system}.image-app` |
| flake.nix | `mcp-server` | `self.packages.${system}.securellm-mcp` |
| flake.nix | `llm-bridge` | `self.packages.${system}.securellm-bridge` |
| flake.nix | `specialArgs` | `{` |
| flake.nix | `colors` | `inputs.nix-colors` |
| flake.nix | `modules` | `[` |
| flake.nix | `securellm-mcp` | `inputs.securellm-mcp.packages.${system}.default` |
| flake.nix | `securellm-bridge` | `inputs.securellm-bridge.packages.${system}.default` |
| flake.nix | `sops.age.sshKeyPaths` | `[ "/etc/ssh/ssh_host_ed25519_key" ]` |
| flake.nix | `home-manager.useGlobalPkgs` | `true` |
| flake.nix | `home-manager.useUserPackages` | `true` |
| flake.nix | `home-manager.extraSpecialArgs` | `{` |
| flake.nix | `nix-colors` | `inputs.nix-colors` |
| flake.nix | `home-manager.users.kernelcore` | `import ./hosts/kernelcore/home/home.nix` |
| flake.nix | `home-manager.backupFileExtension` | `null` |
| flake.nix | `modules` | `[` |
| modules/secrets/api-keys.nix | `sops.secrets` | `{` |
| modules/secrets/api-keys.nix | `"anthropic_api_key"` | `{` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `key` | `"openai_admin_key"` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/api.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `sopsFile` | `../../secrets/github.yaml` |
| modules/secrets/api-keys.nix | `mode` | `"0440"` |
| modules/secrets/api-keys.nix | `group` | `"users"` |
| modules/secrets/api-keys.nix | `text` | `''` |
| modules/secrets/api-keys.nix | `export ANTHROPIC_API_KEY` | `"$(cat /run/secrets/anthropic_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export OPENAI_API_KEY` | `"$(cat /run/secrets/openai_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export OPENAI_PROJECT_ID` | `"$(cat /run/secrets/openai_project_id 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export DEEPSEEK_API_KEY` | `"$(cat /run/secrets/deepseek_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export GEMINI_API_KEY` | `"$(cat /run/secrets/gemini_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export OPENROUTER_API_KEY` | `"$(cat /run/secrets/openrouter_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export REPLICATE_API_TOKEN` | `"$(cat /run/secrets/replicate_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export MISTRAL_API_KEY` | `"$(cat /run/secrets/mistral_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export GROQ_API_KEY` | `"$(cat /run/secrets/groq_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export GROQ_PROJECT_ID` | `"$(cat /run/secrets/groq_project_id 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export NVIDIA_API_KEY` | `"$(cat /run/secrets/nvidia_api_key 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `export GITHUB_TOKEN` | `"$(cat /run/secrets/github_token 2>/dev/null || echo "")"` |
| modules/secrets/api-keys.nix | `mode` | `"0755"` |
| modules/secrets/tailscale.nix | `default` | `"/etc/nixos/secrets/tailscale.yaml"` |
| modules/secrets/tailscale.nix | `description` | `"Path to SOPS-encrypted Tailscale secrets file"` |
| modules/secrets/tailscale.nix | `sops.secrets` | `mkIf (pathExists cfg.secretsFile) {` |
| modules/secrets/tailscale.nix | `"tailscale-authkey"` | `{` |
| modules/secrets/tailscale.nix | `sopsFile` | `cfg.secretsFile` |
| modules/secrets/tailscale.nix | `key` | `"authkey"` |
| modules/secrets/tailscale.nix | `mode` | `"0400"` |
| modules/secrets/tailscale.nix | `owner` | `"root"` |
| modules/secrets/tailscale.nix | `group` | `"root"` |
| modules/secrets/tailscale.nix | `restartUnits` | `[ "tailscaled.service" ]` |
| modules/secrets/tailscale.nix | `sopsFile` | `cfg.secretsFile` |
| modules/secrets/tailscale.nix | `key` | `"preauthkey"` |
| modules/secrets/tailscale.nix | `mode` | `"0400"` |
| modules/secrets/tailscale.nix | `owner` | `"root"` |
| modules/secrets/tailscale.nix | `group` | `"root"` |
| modules/secrets/tailscale.nix | `sopsFile` | `cfg.secretsFile` |
| modules/secrets/tailscale.nix | `key` | `"api_token"` |
| modules/secrets/tailscale.nix | `mode` | `"0400"` |
| modules/secrets/tailscale.nix | `owner` | `"root"` |
| modules/secrets/tailscale.nix | `group` | `"root"` |
| modules/secrets/tailscale.nix | `systemd.tmpfiles.rules` | `[` |
| modules/secrets/aws-bedrock.nix | `sops.secrets` | `{` |
| modules/secrets/aws-bedrock.nix | `"aws_access_key_id"` | `{` |
| modules/secrets/aws-bedrock.nix | `sopsFile` | `../../secrets/aws.yaml` |
| modules/secrets/aws-bedrock.nix | `mode` | `"0440"` |
| modules/secrets/aws-bedrock.nix | `group` | `"users"` |
| modules/secrets/aws-bedrock.nix | `sopsFile` | `../../secrets/aws.yaml` |
| modules/secrets/aws-bedrock.nix | `mode` | `"0440"` |
| modules/secrets/aws-bedrock.nix | `group` | `"users"` |
| modules/secrets/aws-bedrock.nix | `sopsFile` | `../../secrets/aws.yaml` |
| modules/secrets/aws-bedrock.nix | `mode` | `"0440"` |
| modules/secrets/aws-bedrock.nix | `group` | `"users"` |
| modules/secrets/aws-bedrock.nix | `text` | `''` |
| modules/secrets/aws-bedrock.nix | `export AWS_ACCESS_KEY_ID` | `"$(cat /run/secrets/aws_access_key_id 2>/dev/null || echo "")"` |
| modules/secrets/aws-bedrock.nix | `export AWS_SECRET_ACCESS_KEY` | `"$(cat /run/secrets/aws_secret_access_key 2>/dev/null || echo "")"` |
| modules/secrets/aws-bedrock.nix | `export AWS_REGION` | `"$(cat /run/secrets/aws_region 2>/dev/null || echo "")"` |
| modules/secrets/aws-bedrock.nix | `export AWS_DEFAULT_REGION` | `"$AWS_REGION"` |
| modules/secrets/aws-bedrock.nix | `export BEDROCK_MODEL_ID` | `"anthropic.claude-3-sonnet-20240229-v1:0"` |
| modules/secrets/aws-bedrock.nix | `export BEDROCK_ENDPOINT` | `"https://bedrock-runtime.us-east-1.amazonaws.com"` |
| modules/secrets/aws-bedrock.nix | `export ANTHROPIC_BEDROCK_AWS_ACCESS_KEY_ID` | `"$AWS_ACCESS_KEY_ID"` |
| modules/secrets/aws-bedrock.nix | `export ANTHROPIC_BEDROCK_AWS_SECRET_ACCESS_KEY` | `"$AWS_SECRET_ACCESS_KEY"` |
| modules/secrets/aws-bedrock.nix | `export ANTHROPIC_BEDROCK_AWS_REGION` | `"$AWS_REGION"` |
| modules/secrets/aws-bedrock.nix | `mode` | `"0755"` |
| modules/secrets/aws-bedrock.nix | `text` | `''` |
| modules/secrets/aws-bedrock.nix | `aws_access_key_id` | `$(cat /run/secrets/aws_access_key_id)` |
| modules/secrets/aws-bedrock.nix | `aws_secret_access_key` | `$(cat /run/secrets/aws_secret_access_key)` |
| modules/secrets/aws-bedrock.nix | `region` | `$(cat /run/secrets/aws_region)` |
| modules/secrets/aws-bedrock.nix | `mode` | `"0600"` |
| modules/secrets/aws-bedrock.nix | `text` | `''` |
| modules/secrets/aws-bedrock.nix | `region` | `$(cat /run/secrets/aws_region)` |
| modules/secrets/aws-bedrock.nix | `output` | `json` |
| modules/secrets/aws-bedrock.nix | `mode` | `"0644"` |
| modules/audio/production.nix | `default` | `false` |
| modules/audio/production.nix | `description` | `"Habilitar JACK Audio Connection Kit"` |
| modules/audio/production.nix | `default` | `true` |
| modules/audio/production.nix | `description` | `"Instalar plugins de áudio (LV2, LADSPA, VST)"` |
| modules/audio/production.nix | `default` | `true` |
| modules/audio/production.nix | `description` | `"Instalar sintetizadores"` |
| modules/audio/production.nix | `default` | `true` |
| modules/audio/production.nix | `description` | `"Ferramentas de download e conversão de áudio"` |
| modules/audio/production.nix | `environment.shellAliases` | `{` |
| modules/audio/production.nix | `"ardour"` | `"ardour"` |
| modules/audio/production.nix | `environment.etc` | `{` |
| modules/audio/production.nix | `"wireplumber/main.lua.d/51-force-intel-profile.lua".text` | `''` |
| modules/audio/production.nix | `rule` | `{` |
| modules/audio/production.nix | `matches` | `{` |
| modules/audio/production.nix | `apply_properties` | `{` |
| modules/audio/production.nix | `["api.alsa.use-acp"]` | `true,` |
| modules/audio/production.nix | `["api.alsa.soft-mixer"]` | `true,` |
| modules/audio/production.nix | `text` | `''` |
| modules/audio/production.nix | `youtube-to-flac 'https://www.youtube.com/watch?v` | `...'` |
| modules/audio/production.nix | `youtube-to-flac 'https://www.youtube.com/watch?v` | `...' ~/Music` |
| modules/audio/production.nix | `URL` | `"$1"` |
| modules/audio/production.nix | `OUTPUT_DIR` | `"''${2:-.}"` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `mode` | `"0755"` |
| modules/audio/production.nix | `text` | `''` |
| modules/audio/production.nix | `FORMAT` | `"$1"` |
| modules/audio/production.nix | `DIR` | `"$2"` |
| modules/audio/production.nix | `flac) EXT` | `"flac"; OPTS="-c:a flac -compression_level 12" ;` |
| modules/audio/production.nix | `OUTPUT_DIR` | `"$DIR/converted_$FORMAT"` |
| modules/audio/production.nix | `count` | `0` |
| modules/audio/production.nix | `basename` | `"$(basename "$file")"` |
| modules/audio/production.nix | `filename` | `"''${basename%.*}"` |
| modules/audio/production.nix | `output` | `"$OUTPUT_DIR/$filename.$EXT"` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `mode` | `"0755"` |
| modules/audio/production.nix | `text` | `''` |
| modules/audio/production.nix | `FILE` | `"$1"` |
| modules/audio/production.nix | `mode` | `"0755"` |
| modules/audio/production.nix | `text` | `''` |
| modules/audio/production.nix | `FILE` | `"$1"` |
| modules/audio/production.nix | `TARGET_LUFS` | `"''${2:--16}"` |
| modules/audio/production.nix | `BASENAME` | `"$(basename "$FILE")"` |
| modules/audio/production.nix | `FILENAME` | `"''${BASENAME%.*}"` |
| modules/audio/production.nix | `EXT` | `"''${BASENAME##*.}"` |
| modules/audio/production.nix | `OUTPUT` | `"''${FILENAME}_normalized.$EXT"` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `-af "loudnorm` | `I=$TARGET_LUFS:TP=-1.5:LRA=11:print_format=summary" \` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `mode` | `"0755"` |
| modules/audio/production.nix | `text` | `''` |
| modules/audio/production.nix | `FILE` | `"$1"` |
| modules/audio/production.nix | `DURATION` | `"$2"` |
| modules/audio/production.nix | `BASENAME` | `"$(basename "$FILE")"` |
| modules/audio/production.nix | `FILENAME` | `"''${BASENAME%.*}"` |
| modules/audio/production.nix | `EXT` | `"''${BASENAME##*.}"` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `echo "` | `========================================="` |
| modules/audio/production.nix | `mode` | `"0755"` |
| modules/audio/production.nix | `text` | `''` |
| modules/audio/production.nix | `modules.audio.production.enable` | `true` |
| modules/audio/production.nix | `modules.audio.production` | `{` |
| modules/audio/production.nix | `enable` | `true` |
| modules/audio/production.nix | `jackAudio` | `true;        # JACK Audio Connection Kit` |
| modules/audio/production.nix | `plugins` | `true;          # Plugins LV2/LADSPA/VST` |
| modules/audio/production.nix | `synthesizers` | `true;     # Sintetizadores` |
| modules/audio/production.nix | `downloaders` | `true;      # yt-dlp, ffmpeg` |
| modules/audio/production.nix | `mode` | `"0644"` |
| modules/audio/production.nix | `services.jack` | `mkIf cfg.jackAudio {` |
| modules/audio/production.nix | `jackd` | `{` |
| modules/audio/production.nix | `enable` | `false; # Geralmente iniciado manualmente ou via qjackctl` |
| modules/audio/production.nix | `security.pam.loginLimits` | `[` |
| modules/audio/production.nix | `item` | `"memlock"` |
| modules/audio/production.nix | `type` | `"-"` |
| modules/audio/production.nix | `value` | `"unlimited"` |
| modules/audio/production.nix | `item` | `"rtprio"` |
| modules/audio/production.nix | `type` | `"-"` |
| modules/audio/production.nix | `value` | `"99"` |
| modules/audio/production.nix | `item` | `"nofile"` |
| modules/audio/production.nix | `type` | `"soft"` |
| modules/audio/production.nix | `value` | `"99999"` |
| modules/audio/production.nix | `item` | `"nofile"` |
| modules/audio/production.nix | `type` | `"hard"` |
| modules/audio/production.nix | `value` | `"99999"` |
| modules/audio/production.nix | `environment.variables` | `{` |
| modules/audio/production.nix | `LADSPA_PATH` | `"$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa"` |
| modules/audio/production.nix | `LV2_PATH` | `"$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2"` |
| modules/audio/production.nix | `VST_PATH` | `"$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst"` |
| modules/audio/production.nix | `DSSI_PATH` | `"$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi"` |
| hosts/kernelcore/default.nix | `programs.sway.enable` | `true` |
| hosts/kernelcore/home/git.nix | `programs.git` | `{` |
| hosts/kernelcore/home/git.nix | `enable` | `true` |
| hosts/kernelcore/home/git.nix | `settings` | `{` |
| hosts/kernelcore/home/git.nix | `user.name` | `"marcosfpina"` |
| hosts/kernelcore/home/git.nix | `user.email` | `"sec@voidnxlabs.com"` |
| hosts/kernelcore/home/git.nix | `init.defaultBranch` | `"main"` |
| hosts/kernelcore/home/git.nix | `core.editor` | `"nvim"` |
| hosts/kernelcore/home/git.nix | `pull.rebase` | `false` |
| hosts/kernelcore/home/git.nix | `user.signingkey` | `"5606AB430E95F5AD"` |
| hosts/kernelcore/home/git.nix | `commit.gpgsign` | `true` |
| hosts/kernelcore/home/git.nix | `core.preloadindex` | `true` |
| hosts/kernelcore/home/git.nix | `core.fscache` | `true` |
| hosts/kernelcore/home/git.nix | `gc.auto` | `256` |
| hosts/kernelcore/home/git.nix | `diff.algorithm` | `"histogram"` |
| hosts/kernelcore/home/git.nix | `color.ui` | `true` |
| hosts/kernelcore/home/git.nix | `core.hooksPath` | `".githooks"` |
| hosts/kernelcore/home/git.nix | `alias` | `{` |
| hosts/kernelcore/home/git.nix | `st` | `"status"` |
| hosts/kernelcore/home/git.nix | `co` | `"checkout"` |
| hosts/kernelcore/home/git.nix | `br` | `"branch"` |
| hosts/kernelcore/home/git.nix | `ci` | `"commit"` |
| hosts/kernelcore/home/git.nix | `df` | `"diff"` |
| hosts/kernelcore/home/git.nix | `lg` | `"log --oneline --graph --decorate --all"` |
| hosts/kernelcore/home/git.nix | `lol` | `"log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"` |
| hosts/kernelcore/home/git.nix | `unstage` | `"reset HEAD --"` |
| hosts/kernelcore/home/git.nix | `last` | `"log -1 HEAD"` |
| hosts/kernelcore/home/git.nix | `amend` | `"commit --amend --no-edit"` |
| hosts/kernelcore/home/git.nix | `undo` | `"reset --soft HEAD^"` |
| hosts/kernelcore/home/git.nix | `lfs.enable` | `true` |
| modules/security/pam.nix | `security.pam` | `{` |
| modules/security/pam.nix | `sshAgentAuth.enable` | `true` |
| modules/security/pam.nix | `loginLimits` | `[` |
| modules/security/pam.nix | `item` | `"core"` |
| modules/security/pam.nix | `type` | `"hard"` |
| modules/security/pam.nix | `value` | `"0"` |
| modules/security/pam.nix | `item` | `"maxlogins"` |
| modules/security/pam.nix | `type` | `"hard"` |
| modules/security/pam.nix | `value` | `"3"` |
| modules/security/pam.nix | `item` | `"nofile"` |
| modules/security/pam.nix | `type` | `"soft"` |
| modules/security/pam.nix | `value` | `"65536"` |
| modules/security/pam.nix | `item` | `"nofile"` |
| modules/security/pam.nix | `type` | `"hard"` |
| modules/security/pam.nix | `value` | `"65536"` |
| modules/security/pam.nix | `services` | `{` |
| modules/security/pam.nix | `sshd.showMotd` | `true` |
| modules/security/pam.nix | `password required pam_pwquality.so retry` | `3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1` |
| modules/security/pam.nix | `security.loginDefs.settings` | `{` |
| modules/security/pam.nix | `PASS_MAX_DAYS` | `90` |
| modules/security/pam.nix | `PASS_MIN_DAYS` | `1` |
| modules/security/pam.nix | `PASS_WARN_AGE` | `14` |
| modules/security/pam.nix | `UMASK` | `"077"` |
| modules/security/pam.nix | `ENCRYPT_METHOD` | `"SHA512"` |
| modules/security/pam.nix | `SHA_CRYPT_MIN_ROUNDS` | `5000` |
| modules/security/pam.nix | `programs.gnupg.agent` | `{` |
| modules/security/pam.nix | `enable` | `true` |
| modules/security/pam.nix | `enableSSHSupport` | `true` |
| modules/security/pam.nix | `users.mutableUsers` | `false` |
| hosts/kernelcore/home/aliases/aliases.sh | `DOCKER_ORCH_PATH` | `"$HOME/Documents/nx/docker/main.py"` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias dstack` | `'python3 "$DOCKER_ORCH_PATH"'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias dstack-list` | `'python3 "$DOCKER_ORCH_PATH" list'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias ai-up` | `'python3 "$DOCKER_ORCH_PATH" up multimodal'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias ai-down` | `'python3 "$DOCKER_ORCH_PATH" down multimodal'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias ai-status` | `'python3 "$DOCKER_ORCH_PATH" status multimodal'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias ai-logs` | `'python3 "$DOCKER_ORCH_PATH" logs multimodal -f'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias ai-health` | `'python3 "$DOCKER_ORCH_PATH" health multimodal'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias ai-restart` | `'python3 "$DOCKER_ORCH_PATH" restart multimodal'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias gpu-up` | `'python3 "$DOCKER_ORCH_PATH" up gpu'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias gpu-down` | `'python3 "$DOCKER_ORCH_PATH" down gpu'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias gpu-status` | `'python3 "$DOCKER_ORCH_PATH" status gpu'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias gpu-logs` | `'python3 "$DOCKER_ORCH_PATH" logs gpu -f'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias gpu-health` | `'python3 "$DOCKER_ORCH_PATH" health gpu'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias gpu-restart` | `'python3 "$DOCKER_ORCH_PATH" restart gpu'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias all-up` | `'python3 "$DOCKER_ORCH_PATH" up-all'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias all-down` | `'python3 "$DOCKER_ORCH_PATH" down-all'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias all-status` | `'python3 "$DOCKER_ORCH_PATH" status'` |
| hosts/kernelcore/home/aliases/aliases.sh | `alias all-health` | `'python3 "$DOCKER_ORCH_PATH" health'` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `programs.waybar` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `settings` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `mainBar` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `layer` | `"top"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `position` | `"top"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `height` | `42` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `spacing` | `8` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `margin-top` | `8` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `margin-left` | `16` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `margin-right` | `16` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `margin-bottom` | `0` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `modules-left` | `[` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `modules-center` | `[` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `modules-right` | `[` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{icon}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-icons` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `"1"` | `"󰲠"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `urgent` | `"󰀨"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `active` | `"󰮯"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `default` | `"󰊠"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"activate"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll-up` | `"hyprctl dispatch workspace e+1"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll-down` | `"hyprctl dispatch workspace e-1"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `all-outputs` | `false` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `active-only` | `false` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `show-special` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `persistent-workspaces` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `"*"` | `5` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{class}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `max-length` | `40` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `separate-outputs` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `rewrite` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `"Alacritty"` | `"󰆍 Alacritty"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"󰥔 {:%H:%M}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-alt` | `"󰃭 {:%A, %B %d, %Y}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format` | `"<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `calendar` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `mode` | `"month"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `mode-mon-col` | `3` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `weeks-pos` | `"right"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll` | `1` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `months` | `"<span color='#00d4ff'><b>{}</b></span>"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `days` | `"<span color='#e4e4e7'>{}</span>"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `weeks` | `"<span color='#7c3aed'><b>W{}</b></span>"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `weekdays` | `"<span color='#a1a1aa'>{}</span>"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `today` | `"<span color='#ff00aa'><b><u>{}</u></b></span>"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `actions` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click-right` | `"mode"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click-forward` | `"tz_up"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click-backward` | `"tz_down"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll-up` | `"shift_up"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll-down` | `"shift_down"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `exec` | `gpuMonitor` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `return-type` | `"json"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `interval` | `3` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"nvidia-settings"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `exec` | `diskMonitor` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `return-type` | `"json"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `interval` | `30` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"gparted"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `exec` | `sshSessions` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `return-type` | `"json"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `interval` | `5` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"alacritty -e htop -p $(pgrep -d, ssh)"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-wifi` | `"󰤨 {signalStrength}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-ethernet` | `"󰈀 {ipaddr}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-linked` | `"󰈀 {ifname}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-disconnected` | `"󰤭"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-alt` | `"{ifname}: {ipaddr}/{cidr}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format` | `"󰩟 {ifname}\n󰩠 {ipaddr}/{cidr}\n󰁝 {bandwidthUpBytes}\n󰁅 {bandwidthDownBytes}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click-right` | `"nm-connection-editor"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"󰂯"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-disabled` | `"󰂲"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-connected` | `"󰂱 {num_connections}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-connected-battery` | `"󰂱 {device_battery_percentage}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format` | `"{controller_alias}\t{controller_address}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format-connected` | `"{controller_alias}\t{controller_address}\n\n{device_enumerate}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format-enumerate-connected` | `"{device_alias}\t{device_address}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format-enumerate-connected-battery` | `"{device_alias}\t{device_battery_percentage}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"blueman-manager"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{icon} {volume}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-bluetooth` | `"󰂰 {volume}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-bluetooth-muted` | `"󰂲"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-muted` | `"󰝟"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-icons` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `headphone` | `"󰋋"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `hands-free` | `"󰋎"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `headset` | `"󰋎"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `phone` | `"󰏲"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `portable` | `"󰏲"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `car` | `"󰄋"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `default` | `[` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"pavucontrol"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click-right` | `"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll-up` | `"wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-scroll-down` | `"wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `states` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `good` | `95` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `warning` | `30` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `critical` | `15` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"{icon} {capacity}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-charging` | `"󰂄 {capacity}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-plugged` | `"󰚥 {capacity}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-alt` | `"{icon} {time}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format-icons` | `[` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format` | `"{timeTo}\n{capacity}% - {health}% health"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `format` | `"󰚩"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `tooltip-format` | `"AI Agent Hub\nClick to launch agent selector"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `on-click` | `"notify-send 'Agent Hub' 'Coming soon: AI agent integration'"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `icon-size` | `18` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `spacing` | `8` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `show-passive-items` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `style` | `''` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `/*` | `===========================================` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `*` | `=========================================== */` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `if ! DF_OUTPUT` | `$(df -h / 2>/dev/null | tail -1); then` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `PERCENT_NUM` | `''${PERCENT%\%}` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `if [[ ! "$PERCENT_NUM"` | `~ ^[0-9]+$ ]]; then` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `PERCENT_NUM` | `0` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local CLASS` | `"normal"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `CLASS` | `"critical"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `CLASS` | `"warning"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local TEXT` | `"󰋊 ''${USED}/''${SIZE} (''${PERCENT})"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local TOOLTIP` | `"Disk Usage (Root)\n━━━━━━━━━━━━━━━━━━━━━━\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰋊 Filesystem: ''${FILESYSTEM}\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰆼 Total: ''${SIZE}\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰆴 Used: ''${USED} (''${PERCENT})\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰆣 Available: ''${AVAIL}\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰉖 Mounted: ''${MOUNTED}"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local NVIDIA_SMI` | `""` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `NVIDIA_SMI` | `"$path"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `IFS` | `',' read -r TEMP VRAM_USED VRAM_TOTAL UTIL CLOCK <<< "$GPU_OUTPUT"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TEMP` | `''${TEMP:-0}` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `VRAM_USED` | `''${VRAM_USED:-0}` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `VRAM_TOTAL` | `''${VRAM_TOTAL:-1}` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `UTIL` | `''${UTIL:-0}` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `CLOCK` | `''${CLOCK:-0}` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local VRAM_PERCENT` | `0` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `VRAM_PERCENT` | `$(( (VRAM_USED * 100) / VRAM_TOTAL ))` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local CLASS` | `"normal"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `CLASS` | `"critical"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `CLASS` | `"warning"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local TEXT` | `"󰢮 ''${TEMP}°C  ''${VRAM_PERCENT}%  ''${UTIL}%"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `local TOOLTIP` | `"NVIDIA GPU Status\n━━━━━━━━━━━━━━━━━━━━━━\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰔏 Temperature: ''${TEMP}°C\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰍛 VRAM: ''${VRAM_USED}MiB / ''${VRAM_TOTAL}MiB (''${VRAM_PERCENT}%)\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰓅 Utilization: ''${UTIL}%\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP+` | `"󰑮 Clock: ''${CLOCK} MHz"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `SSH_PIDS` | `$(pgrep -x ssh 2>/dev/null)` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `SESSION_COUNT` | `$(echo "$SSH_PIDS" | wc -l)` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `HOSTS` | `""` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `CMDLINE` | `$(ps -p "$PID" -o args= 2>/dev/null | head -1)` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `HOST` | `$(echo "$CMDLINE" | grep -oP '(?:^ssh\s+|\s+)([a-zA-Z0-9@._-]+)(?:\s|$)' | tail -1 | tr -d ' ')` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `if [[ -n "$HOST" && "$HOST" !` | `"ssh" ]]; then` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `HOSTS` | `"$HOSTS\n"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `HOSTS+` | `"  󰣀 $HOST"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TEXT` | `"󰣀 $SESSION_COUNT"` |
| hosts/kernelcore/home/glassmorphism/waybar.nix | `TOOLTIP` | `"SSH Sessions: $SESSION_COUNT\n━━━━━━━━━━━━━━━━━━━━━━"` |
| modules/desktop/hyprland.nix | `description` | `"Enable NVIDIA-specific Wayland optimizations"` |
| modules/desktop/hyprland.nix | `programs.hyprland` | `{` |
| modules/desktop/hyprland.nix | `enable` | `true` |
| modules/desktop/hyprland.nix | `xwayland.enable` | `true` |
| modules/desktop/hyprland.nix | `xdg.portal` | `{` |
| modules/desktop/hyprland.nix | `enable` | `true` |
| modules/desktop/hyprland.nix | `common` | `{` |
| modules/desktop/hyprland.nix | `default` | `[ "gtk" ]` |
| modules/desktop/hyprland.nix | `hyprland` | `{` |
| modules/desktop/hyprland.nix | `default` | `[` |
| modules/desktop/hyprland.nix | `wlr.enable` | `false; # Disabled - we use hyprland portal instead` |
| modules/desktop/hyprland.nix | `security.polkit.enable` | `true` |
| modules/desktop/hyprland.nix | `systemd.user.services.polkit-gnome-authentication-agent-1` | `{` |
| modules/desktop/hyprland.nix | `description` | `"polkit-gnome-authentication-agent-1"` |
| modules/desktop/hyprland.nix | `wantedBy` | `[ "graphical-session.target" ]` |
| modules/desktop/hyprland.nix | `wants` | `[ "graphical-session.target" ]` |
| modules/desktop/hyprland.nix | `after` | `[ "graphical-session.target" ]` |
| modules/desktop/hyprland.nix | `serviceConfig` | `{` |
| modules/desktop/hyprland.nix | `Type` | `"simple"` |
| modules/desktop/hyprland.nix | `Restart` | `"on-failure"` |
| modules/desktop/hyprland.nix | `RestartSec` | `1` |
| modules/desktop/hyprland.nix | `TimeoutStopSec` | `10` |
| modules/desktop/hyprland.nix | `environment.sessionVariables` | `mkMerge [` |
| modules/desktop/hyprland.nix | `XDG_SESSION_TYPE` | `"wayland"` |
| modules/desktop/hyprland.nix | `XDG_CURRENT_DESKTOP` | `"Hyprland"` |
| modules/desktop/hyprland.nix | `XDG_SESSION_DESKTOP` | `"Hyprland"` |
| modules/desktop/hyprland.nix | `QT_QPA_PLATFORM` | `"wayland;xcb"` |
| modules/desktop/hyprland.nix | `QT_WAYLAND_DISABLE_WINDOWDECORATION` | `"1"` |
| modules/desktop/hyprland.nix | `QT_AUTO_SCREEN_SCALE_FACTOR` | `"1"` |
| modules/desktop/hyprland.nix | `GDK_BACKEND` | `"wayland,x11"` |
| modules/desktop/hyprland.nix | `NIXOS_OZONE_WL` | `"1"` |
| modules/desktop/hyprland.nix | `ELECTRON_OZONE_PLATFORM_HINT` | `"auto"` |
| modules/desktop/hyprland.nix | `SDL_VIDEODRIVER` | `"wayland"` |
| modules/desktop/hyprland.nix | `CLUTTER_BACKEND` | `"wayland"` |
| modules/desktop/hyprland.nix | `MOZ_ENABLE_WAYLAND` | `"1"` |
| modules/desktop/hyprland.nix | `XCURSOR_SIZE` | `"24"` |
| modules/desktop/hyprland.nix | `XCURSOR_THEME` | `"catppuccin-macchiato-blue-cursors"` |
| modules/desktop/hyprland.nix | `LIBVA_DRIVER_NAME` | `"nvidia"` |
| modules/desktop/hyprland.nix | `GBM_BACKEND` | `"nvidia-drm"` |
| modules/desktop/hyprland.nix | `__GLX_VENDOR_LIBRARY_NAME` | `"nvidia"` |
| modules/desktop/hyprland.nix | `WLR_NO_HARDWARE_CURSORS` | `"1"` |
| modules/desktop/hyprland.nix | `__GL_GSYNC_ALLOWED` | `"1"` |
| modules/desktop/hyprland.nix | `__GL_VRR_ALLOWED` | `"1"` |
| modules/desktop/hyprland.nix | `WLR_DRM_NO_ATOMIC` | `"1"` |
| modules/desktop/hyprland.nix | `services.dbus.enable` | `true` |
| modules/desktop/hyprland.nix | `services.gvfs.enable` | `true` |
| modules/desktop/hyprland.nix | `services.udisks2.enable` | `true` |
| modules/desktop/hyprland.nix | `assertions` | `[` |
| modules/services/laptop-builder-client.nix | `services.laptop-builder-client` | `{` |
| modules/services/laptop-builder-client.nix | `default` | `"192.168.15.9"` |
| modules/services/laptop-builder-client.nix | `description` | `"IP address of the desktop build server"` |
| modules/services/laptop-builder-client.nix | `default` | `"/etc/nix/builder_key"` |
| modules/services/laptop-builder-client.nix | `description` | `"Path to SSH private key for builder authentication"` |
| modules/services/laptop-builder-client.nix | `default` | `0` |
| modules/services/laptop-builder-client.nix | `description` | `"Maximum local build jobs (0 = offload only)"` |
| modules/services/laptop-builder-client.nix | `nix.settings` | `{` |
| modules/services/laptop-builder-client.nix | `builders-use-substitutes` | `true` |
| modules/services/laptop-builder-client.nix | `fallback` | `true` |
| modules/services/laptop-builder-client.nix | `substituters` | `[` |
| modules/services/laptop-builder-client.nix | `trusted-public-keys` | `[` |
| modules/services/laptop-builder-client.nix | `"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY` | `"` |
| modules/services/laptop-builder-client.nix | `"cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE` | `"` |
| modules/services/laptop-builder-client.nix | `connect-timeout` | `5` |
| modules/services/laptop-builder-client.nix | `stalled-download-timeout` | `30` |
| modules/services/laptop-builder-client.nix | `programs.ssh.extraConfig` | `''` |
| modules/network/vpn/nordvpn.nix | `default` | `"/etc/nixos/secrets/vpn/nordvpn-credentials"` |
| modules/network/vpn/nordvpn.nix | `description` | `"Path to NordVPN credentials file (SOPS encrypted)"` |
| modules/network/vpn/nordvpn.nix | `default` | `false` |
| modules/network/vpn/nordvpn.nix | `description` | `"Automatically connect to NordVPN on boot"` |
| modules/network/vpn/nordvpn.nix | `default` | `"United_States"` |
| modules/network/vpn/nordvpn.nix | `description` | `"Preferred NordVPN server country"` |
| modules/network/vpn/nordvpn.nix | `default` | `"nordlynx"` |
| modules/network/vpn/nordvpn.nix | `description` | `"VPN protocol to use"` |
| modules/network/vpn/nordvpn.nix | `default` | `false` |
| modules/network/vpn/nordvpn.nix | `boot.kernelModules` | `[ "wireguard" ]` |
| modules/network/vpn/nordvpn.nix | `systemd.tmpfiles.rules` | `[` |
| modules/network/vpn/nordvpn.nix | `mode` | `"0750"` |
| modules/network/vpn/nordvpn.nix | `text` | `''` |
| modules/network/vpn/nordvpn.nix | `API_BASE` | `"https://api.nordvpn.com/v1"` |
| modules/network/vpn/nordvpn.nix | `CRED_FILE` | `"${cfg.credentialsFile}"` |
| modules/network/vpn/nordvpn.nix | `local country` | `"$1"` |
| modules/network/vpn/nordvpn.nix | `local country` | `"$1"` |
| modules/network/vpn/nordvpn.nix | `local hostname` | `"$1"` |
| modules/network/vpn/nordvpn.nix | `networking.wg-quick.interfaces` | `mkIf (cfg.protocol == "nordlynx") {` |
| modules/network/vpn/nordvpn.nix | `wgnord` | `{` |
| modules/network/vpn/nordvpn.nix | `autostart` | `cfg.autoConnect` |
| modules/network/vpn/nordvpn.nix | `address` | `[ "10.5.0.2/16" ]` |
| modules/network/vpn/nordvpn.nix | `privateKeyFile` | `"${cfg.credentialsFile}/private-key"` |
| modules/network/vpn/nordvpn.nix | `dns` | `mkIf cfg.overrideDNS [` |
| modules/network/vpn/nordvpn.nix | `peers` | `[` |
| modules/network/vpn/nordvpn.nix | `publicKey` | `"SERVER_PUBLIC_KEY_HERE"` |
| modules/network/vpn/nordvpn.nix | `endpoint` | `"xx.nordvpn.com:51820"` |
| modules/network/vpn/nordvpn.nix | `allowedIPs` | `[` |
| modules/network/vpn/nordvpn.nix | `persistentKeepalive` | `25` |
| modules/network/vpn/nordvpn.nix | `networking.firewall` | `{` |
| modules/network/vpn/nordvpn.nix | `allowedUDPPorts` | `[ 51820 ]` |
| modules/network/vpn/nordvpn.nix | `extraCommands` | `mkIf cfg.autoConnect ''` |
| modules/network/vpn/nordvpn.nix | `extraStopCommands` | `''` |
| modules/network/vpn/nordvpn.nix | `systemd.services.nordvpn-manager` | `{` |
| modules/network/vpn/nordvpn.nix | `description` | `"NordVPN Connection Manager"` |
| modules/network/vpn/nordvpn.nix | `after` | `[` |
| modules/network/vpn/nordvpn.nix | `wants` | `[ "network-online.target" ]` |
| modules/network/vpn/nordvpn.nix | `wantedBy` | `mkIf cfg.autoConnect [ "multi-user.target" ]` |
| modules/network/vpn/nordvpn.nix | `serviceConfig` | `{` |
| modules/network/vpn/nordvpn.nix | `Type` | `"oneshot"` |
| modules/network/vpn/nordvpn.nix | `RemainAfterExit` | `true` |
| modules/network/vpn/nordvpn.nix | `SERVER` | `$(/etc/nordvpn/api-helper.sh recommend 2>/dev/null || echo "")` |
| modules/network/vpn/nordvpn.nix | `Restart` | `"on-failure"` |
| modules/network/vpn/nordvpn.nix | `RestartSec` | `30` |
| modules/network/vpn/nordvpn.nix | `environment.shellAliases` | `{` |
| modules/network/vpn/nordvpn.nix | `vpn-connect` | `"sudo systemctl start nordvpn-manager"` |
| modules/network/vpn/nordvpn.nix | `vpn-disconnect` | `"sudo systemctl stop nordvpn-manager"` |
| modules/network/vpn/nordvpn.nix | `vpn-restart` | `"sudo systemctl restart nordvpn-manager"` |
| modules/network/vpn/nordvpn.nix | `vpn-logs` | `"journalctl -u nordvpn-manager -f"` |
| modules/network/vpn/nordvpn.nix | `vpn-check` | `"/etc/nordvpn/check-connection.sh"` |
| modules/network/vpn/nordvpn.nix | `mode` | `"0755"` |
| modules/network/vpn/nordvpn.nix | `text` | `''` |
| modules/network/vpn/nordvpn.nix | `echo "` | `=================================="` |
| modules/network/vpn/nordvpn.nix | `echo "` | `=================================="` |
| modules/network/vpn/nordvpn.nix | `if [ "$NORD_CHECK"` | `"Protected" ]; then` |
| modules/audio/video-production.nix | `default` | `true` |
| modules/audio/video-production.nix | `description` | `"Habilitar encoding NVENC (requer NVIDIA GPU)"` |
| modules/audio/video-production.nix | `default` | `true` |
| modules/audio/video-production.nix | `description` | `"Corrigir problema de mute quando microfone P2 é plugado"` |
| modules/audio/video-production.nix | `default` | `true` |
| modules/audio/video-production.nix | `description` | `"Configuração de baixa latência para streaming"` |
| modules/audio/video-production.nix | `OBS_EXIT` | `$?` |
| modules/audio/video-production.nix | `nvidia-smi --query-gpu` | `name,driver_version --format=csv,noheader` |
| modules/audio/video-production.nix | `programs.obs-studio` | `{` |
| modules/audio/video-production.nix | `enable` | `true` |
| modules/audio/video-production.nix | `enableVirtualCamera` | `true` |
| modules/audio/video-production.nix | `environment.etc` | `mkIf cfg.fixHeadphoneMute {` |
| modules/audio/video-production.nix | `"wireplumber/main.lua.d/51-disable-auto-switch-profile.lua".text` | `''` |
| modules/audio/video-production.nix | `rule` | `{` |
| modules/audio/video-production.nix | `matches` | `{` |
| modules/audio/video-production.nix | `apply_properties` | `{` |
| modules/audio/video-production.nix | `["api.alsa.ignore-dB"]` | `false,` |
| modules/audio/video-production.nix | `["api.acp.auto-port"]` | `false,` |
| modules/audio/video-production.nix | `["api.acp.auto-profile"]` | `false,` |
| modules/audio/video-production.nix | `["api.alsa.soft-mixer"]` | `true,` |
| modules/audio/video-production.nix | `["api.alsa.soft-dB"]` | `true,` |
| modules/audio/video-production.nix | `rule` | `{` |
| modules/audio/video-production.nix | `matches` | `{` |
| modules/audio/video-production.nix | `apply_properties` | `{` |
| modules/audio/video-production.nix | `["priority.driver"]` | `0,` |
| modules/audio/video-production.nix | `["priority.session"]` | `0,` |
| modules/audio/video-production.nix | `["node.plugged"]` | `-1,` |
| modules/audio/video-production.nix | `rule` | `{` |
| modules/audio/video-production.nix | `matches` | `{` |
| modules/audio/video-production.nix | `apply_properties` | `{` |
| modules/audio/video-production.nix | `["priority.driver"]` | `2000,` |
| modules/audio/video-production.nix | `["priority.session"]` | `2000,` |
| modules/audio/video-production.nix | `["node.pause-on-idle"]` | `false,` |
| modules/audio/video-production.nix | `wireplumber.settings` | `{` |
| modules/audio/video-production.nix | `bluetooth.autoswitch-to-headset-profile` | `false` |
| modules/audio/video-production.nix | `stream.restore-default-targets` | `true` |
| modules/audio/video-production.nix | `device.restore-default-target` | `true` |
| modules/audio/video-production.nix | `services.pipewire` | `mkIf cfg.lowLatency {` |
| modules/audio/video-production.nix | `extraConfig.pipewire` | `{` |
| modules/audio/video-production.nix | `"10-video-production"` | `{` |
| modules/audio/video-production.nix | `"context.properties"` | `{` |
| modules/audio/video-production.nix | `"default.clock.rate"` | `48000` |
| modules/audio/video-production.nix | `environment.shellAliases` | `{` |
| modules/audio/video-production.nix | `"rec-screen"` | `"wf-recorder -f ~/Videos/$(date +%Y%m%d_%H%M%S).mp4"` |
| modules/audio/video-production.nix | `environment.variables` | `mkIf cfg.enableNVENC {` |
| modules/audio/video-production.nix | `OBS_USE_EGL` | `"1"` |
| modules/audio/video-production.nix | `security.pam.loginLimits` | `[` |
| modules/audio/video-production.nix | `item` | `"rtprio"` |
| modules/audio/video-production.nix | `type` | `"-"` |
| modules/audio/video-production.nix | `value` | `"95"` |
| modules/audio/video-production.nix | `item` | `"memlock"` |
| modules/audio/video-production.nix | `type` | `"-"` |
| modules/audio/video-production.nix | `value` | `"unlimited"` |
| modules/audio/video-production.nix | `item` | `"rtprio"` |
| modules/audio/video-production.nix | `type` | `"-"` |
| modules/audio/video-production.nix | `value` | `"99"` |
| modules/audio/video-production.nix | `item` | `"memlock"` |
| modules/audio/video-production.nix | `type` | `"-"` |
| modules/audio/video-production.nix | `value` | `"unlimited"` |
| modules/audio/video-production.nix | `users.groups.video.members` | `[ "kernelcore" ]` |
| modules/security/hardening-template.nix | `nix.settings` | `{` |
| modules/security/hardening-template.nix | `sandbox` | `true` |
| modules/security/hardening-template.nix | `sandbox-fallback` | `false` |
| modules/security/hardening-template.nix | `allowed-uris` | `[` |
| modules/security/hardening-template.nix | `trusted-users` | `[ "@wheel" ]` |
| modules/security/hardening-template.nix | `allowed-users` | `[ "@users" ]` |
| modules/security/hardening-template.nix | `build-users-group` | `"nixbld"` |
| modules/security/hardening-template.nix | `max-jobs` | `"auto"` |
| modules/security/hardening-template.nix | `cores` | `0` |
| modules/security/hardening-template.nix | `require-sigs` | `true` |
| modules/security/hardening-template.nix | `trusted-public-keys` | `[` |
| modules/security/hardening-template.nix | `"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY` | `"` |
| modules/security/hardening-template.nix | `allowUnfree` | `false` |
| modules/security/hardening-template.nix | `allowBroken` | `false` |
| modules/security/hardening-template.nix | `allowInsecure` | `false` |
| modules/security/hardening-template.nix | `"-D_FORTIFY_SOURCE` | `3"` |
| modules/security/hardening-template.nix | `"-Werror` | `format-security"` |
| modules/security/hardening-template.nix | `"-fcf-protection` | `full"` |
| modules/security/hardening-template.nix | `environment.variables` | `{` |
| modules/security/hardening-template.nix | `HARDENING_ENABLE` | `"fortify stackprotector pic strictoverflow format relro bindnow"` |
| modules/security/hardening-template.nix | `security.pam` | `{` |
| modules/security/hardening-template.nix | `enableSSHAgentAuth` | `true` |
| modules/security/hardening-template.nix | `loginLimits` | `[` |
| modules/security/hardening-template.nix | `item` | `"core"` |
| modules/security/hardening-template.nix | `type` | `"hard"` |
| modules/security/hardening-template.nix | `value` | `"0"` |
| modules/security/hardening-template.nix | `item` | `"maxlogins"` |
| modules/security/hardening-template.nix | `type` | `"hard"` |
| modules/security/hardening-template.nix | `value` | `"10"` |
| modules/security/hardening-template.nix | `item` | `"maxsyslogins"` |
| modules/security/hardening-template.nix | `type` | `"hard"` |
| modules/security/hardening-template.nix | `value` | `"3"` |
| modules/security/hardening-template.nix | `item` | `"nofile"` |
| modules/security/hardening-template.nix | `type` | `"soft"` |
| modules/security/hardening-template.nix | `value` | `"65536"` |
| modules/security/hardening-template.nix | `item` | `"nofile"` |
| modules/security/hardening-template.nix | `type` | `"hard"` |
| modules/security/hardening-template.nix | `value` | `"65536"` |
| modules/security/hardening-template.nix | `boot.kernelParams` | `[` |
| modules/security/hardening-template.nix | `"init_on_alloc` | `1"` |
| modules/security/hardening-template.nix | `"init_on_free` | `1"` |
| modules/security/hardening-template.nix | `"page_alloc.shuffle` | `1"` |
| modules/security/hardening-template.nix | `"pti` | `on"` |
| modules/security/hardening-template.nix | `"vsyscall` | `none"` |
| modules/security/hardening-template.nix | `"debugfs` | `off"` |
| modules/security/hardening-template.nix | `"oops` | `panic"` |
| modules/security/hardening-template.nix | `"module.sig_enforce` | `1"` |
| modules/security/hardening-template.nix | `"lockdown` | `confidentiality"` |
| modules/security/hardening-template.nix | `boot.kernel.sysctl` | `{` |
| modules/security/hardening-template.nix | `"net.ipv4.conf.all.rp_filter"` | `1` |
| modules/security/hardening-template.nix | `security` | `{` |
| modules/security/hardening-template.nix | `lockKernelModules` | `true` |
| modules/security/hardening-template.nix | `protectKernelImage` | `true` |
| modules/security/hardening-template.nix | `apparmor` | `{` |
| modules/security/hardening-template.nix | `enable` | `true` |
| modules/security/hardening-template.nix | `killUnconfinedConfinables` | `true` |
| modules/security/hardening-template.nix | `audit` | `{` |
| modules/security/hardening-template.nix | `enable` | `true` |
| modules/security/hardening-template.nix | `rules` | `[` |
| modules/security/hardening-template.nix | `"-a exit,always -F arch` | `b64 -S execve"` |
| modules/security/hardening-template.nix | `sudo` | `{` |
| modules/security/hardening-template.nix | `enable` | `true` |
| modules/security/hardening-template.nix | `execWheelOnly` | `true` |
| modules/security/hardening-template.nix | `extraConfig` | `''` |
| modules/security/hardening-template.nix | `Defaults timestamp_timeout` | `5` |
| modules/security/hardening-template.nix | `Defaults lecture` | `"always"` |
| modules/security/hardening-template.nix | `Defaults logfile` | `/var/log/sudo.log` |
| modules/security/hardening-template.nix | `security.wrappers` | `{ }` |
| modules/security/hardening-template.nix | `systemd.coredump.enable` | `false` |
| modules/security/hardening-template.nix | `networking.firewall` | `{` |
| modules/security/hardening-template.nix | `enable` | `true` |
| modules/security/hardening-template.nix | `allowPing` | `false` |
| modules/security/hardening-template.nix | `logRefusedConnections` | `true` |
| modules/security/hardening-template.nix | `logRefusedPackets` | `true` |
| modules/security/hardening-template.nix | `services.journald.extraConfig` | `''` |
| modules/security/hardening-template.nix | `SystemMaxUse` | `1G` |
| modules/security/hardening-template.nix | `RuntimeMaxUse` | `100M` |
| modules/security/hardening-template.nix | `ForwardToSyslog` | `yes` |
| modules/security/hardening-template.nix | `Storage` | `persistent` |
| modules/security/hardening-template.nix | `withKerberos` | `false` |
| modules/security/hardening-template.nix | `withLdap` | `false` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `agents` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `roo` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `name` | `"Roo (Claude)"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `icon` | `"󰚩"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `color` | `"#00d4ff"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `command` | `"code --goto"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `description` | `"VSCode AI assistant powered by Claude"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `codex` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `name` | `"Codex"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `icon` | `"󰧑"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `color` | `"#7c3aed"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `command` | `"codex"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `description` | `"OpenAI Codex CLI agent"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `gemini` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `name` | `"Gemini"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `icon` | `"󰊤"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `color` | `"#4285f4"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `command` | `"gemini-cli"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `description` | `"Google Gemini CLI agent"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `ollama` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `name` | `"Ollama"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `icon` | `"󰊠"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `color` | `"#22c55e"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `command` | `"ollama run"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `description` | `"Local LLM via Ollama"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `declare -A AGENTS` | `(` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `["󰚩 Roo (Claude) - VSCode AI Assistant"]` | `"code"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `["󰧑 Codex - CLI Agent"]` | `"alacritty -e codex"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `["󰊤 Gemini - Google AI"]` | `"alacritty -e gemini-cli"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `["󰊠 Ollama - Local LLM"]` | `"alacritty -e ollama run llama3"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `["󰋼 Quick Question"]` | `"agent-quick-prompt"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `MENU` | `""` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `SELECTED` | `$(echo -e "$MENU" | wofi --dmenu --prompt="Agent Hub 󰚩" --width=450 --height=280 --cache-file=/dev/null)` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `CMD` | `"''${AGENTS[$SELECTED]}"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `PROMPT` | `$(wofi --dmenu --prompt="Ask AI 󰋼" --width=600 --height=50 --lines=1)` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `AGENTS` | `"󰚩 Claude (via API)\n󰊤 Gemini\n󰊠 Ollama (Local)"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `AGENT` | `$(echo -e "$AGENTS" | wofi --dmenu --prompt="Select Agent" --width=300 --height=150 --cache-file=/dev/null)` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `RESPONSE` | `$(echo "$PROMPT" | gemini-cli 2>/dev/null)` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `RESPONSE` | `$(ollama run llama3 "$PROMPT" 2>/dev/null)` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `MODELS` | `$(ollama list 2>/dev/null | tail -n +2 | wc -l)` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `ACTIVE` | `0` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `TOOLTIP` | `"AI Agent Hub\n━━━━━━━━━━━━━━━━━━━━━━"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `xdg.desktopEntries.agent-hub` | `{` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `name` | `"Agent Hub"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `genericName` | `"AI Agent Launcher"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `comment` | `"Launch and manage AI coding assistants"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `icon` | `"utilities-terminal"; # Using standard icon` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `terminal` | `false` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `type` | `"Application"` |
| hosts/kernelcore/home/glassmorphism/agent-hub.nix | `categories` | `[` |
| hosts/kernelcore/home/aliases/ai-compose-stack.sh | `AI_COMPOSE_FILE` | `"${AI_COMPOSE_FILE:-$HOME/Base/docker-compose-multimodal.yml}"` |
| hosts/kernelcore/home/aliases/ai-compose-stack.sh | `alias dc-ai` | `"docker-compose -f $AI_COMPOSE_FILE"` |
| hosts/kernelcore/home/aliases/ai-compose-stack.sh | `alias ai-up` | `'docker-compose -f $AI_COMPOSE_FILE up -d'` |
| hosts/kernelcore/home/aliases/ai-compose-stack.sh | `alias ai-down` | `'docker-compose -f $AI_COMPOSE_FILE down'` |
| hosts/kernelcore/home/aliases/ai-compose-stack.sh | `if [ "$confirm"` | `"yes" ]; then` |
| modules/TEMPLATE.nix | `default` | `true` |
| modules/TEMPLATE.nix | `description` | `"Enable specific feature X"` |
| modules/TEMPLATE.nix | `default` | `""` |
| modules/TEMPLATE.nix | `description` | `"Package to use for this module"` |
| modules/TEMPLATE.nix | `environment.systemPackages` | `[` |
| modules/TEMPLATE.nix | `environment.sessionVariables` | `{` |
| modules/TEMPLATE.nix | `assertions` | `[` |
| modules/TEMPLATE.nix | `assertion` | `cfg.enableFeature -> (cfg.package != null)` |
| modules/TEMPLATE.nix | `message` | `"Package must be defined if feature is enabled"` |
| modules/desktop/i3-lightweight.nix | `default` | `"alacritty"` |
| modules/desktop/i3-lightweight.nix | `description` | `"Default terminal emulator"` |
| modules/desktop/i3-lightweight.nix | `default` | `"rofi"` |
| modules/desktop/i3-lightweight.nix | `description` | `"Application launcher (rofi or dmenu)"` |
| modules/desktop/i3-lightweight.nix | `default` | `"i3status"` |
| modules/desktop/i3-lightweight.nix | `description` | `"Status bar (i3status, i3blocks, or polybar)"` |
| modules/desktop/i3-lightweight.nix | `default` | `true` |
| modules/desktop/i3-lightweight.nix | `description` | `"Enable picom compositor for transparency/shadows"` |
| modules/desktop/i3-lightweight.nix | `default` | `"i3lock -c 000000"` |
| modules/desktop/i3-lightweight.nix | `description` | `"Screen lock command"` |
| modules/desktop/i3-lightweight.nix | `services.xserver` | `{` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `displayManager` | `{` |
| modules/desktop/i3-lightweight.nix | `lightdm` | `{` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `greeters.gtk` | `{` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `theme.name` | `"Arc-Dark"` |
| modules/desktop/i3-lightweight.nix | `iconTheme.name` | `"Papirus-Dark"` |
| modules/desktop/i3-lightweight.nix | `defaultSession` | `"none+i3"` |
| modules/desktop/i3-lightweight.nix | `windowManager.i3` | `{` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `xkb` | `{` |
| modules/desktop/i3-lightweight.nix | `layout` | `"br"` |
| modules/desktop/i3-lightweight.nix | `variant` | `""` |
| modules/desktop/i3-lightweight.nix | `sound.enable` | `true` |
| modules/desktop/i3-lightweight.nix | `hardware.pulseaudio` | `{` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `fade` | `true` |
| modules/desktop/i3-lightweight.nix | `shadow` | `true` |
| modules/desktop/i3-lightweight.nix | `fadeDelta` | `4` |
| modules/desktop/i3-lightweight.nix | `vSync` | `true` |
| modules/desktop/i3-lightweight.nix | `backend` | `"glx"; # GPU-accelerated` |
| modules/desktop/i3-lightweight.nix | `settings` | `{` |
| modules/desktop/i3-lightweight.nix | `inactive-opacity` | `0.95` |
| modules/desktop/i3-lightweight.nix | `active-opacity` | `1.0` |
| modules/desktop/i3-lightweight.nix | `shadow-radius` | `12` |
| modules/desktop/i3-lightweight.nix | `shadow-offset-x` | `-7` |
| modules/desktop/i3-lightweight.nix | `shadow-offset-y` | `-7` |
| modules/desktop/i3-lightweight.nix | `shadow-opacity` | `0.5` |
| modules/desktop/i3-lightweight.nix | `fade-in-step` | `0.03` |
| modules/desktop/i3-lightweight.nix | `fade-out-step` | `0.03` |
| modules/desktop/i3-lightweight.nix | `fonts` | `[` |
| modules/desktop/i3-lightweight.nix | `services.redshift` | `{` |
| modules/desktop/i3-lightweight.nix | `enable` | `true` |
| modules/desktop/i3-lightweight.nix | `temperature` | `{` |
| modules/desktop/i3-lightweight.nix | `day` | `5500` |
| modules/desktop/i3-lightweight.nix | `night` | `3700` |
| modules/desktop/i3-lightweight.nix | `location` | `{` |
| modules/desktop/i3-lightweight.nix | `provider` | `"manual"` |
| modules/desktop/i3-lightweight.nix | `latitude` | `-23.5505; # São Paulo (ajuste para sua localização)` |
| modules/desktop/i3-lightweight.nix | `longitude` | `-46.6333` |
| modules/services/laptop-offload-client.nix | `desktopIP` | `"192.168.15.9"; # Desktop server IP (CORRIGIDO - IP real confirmado)` |
| modules/services/laptop-offload-client.nix | `laptopIP` | `"192.168.15.9"; # Laptop IP (mesma máquina que desktop)` |
| modules/services/laptop-offload-client.nix | `builderKeyPath` | `"/etc/nix/builder_key"` |
| modules/services/laptop-offload-client.nix | `nix.settings` | `{` |
| modules/services/laptop-offload-client.nix | `builders-use-substitutes` | `true` |
| modules/services/laptop-offload-client.nix | `substituters` | `[` |
| modules/services/laptop-offload-client.nix | `trusted-public-keys` | `[` |
| modules/services/laptop-offload-client.nix | `"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY` | `"` |
| modules/services/laptop-offload-client.nix | `"cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE` | `" # Desktop cache key` |
| modules/services/laptop-offload-client.nix | `max-jobs` | `4; # Allow local builds as fallback` |
| modules/services/laptop-offload-client.nix | `connect-timeout` | `5` |
| modules/services/laptop-offload-client.nix | `stalled-download-timeout` | `30` |
| modules/services/laptop-offload-client.nix | `fallback` | `true; # Allow local builds if remote fails` |
| modules/services/laptop-offload-client.nix | `fileSystems` | `{` |
| modules/services/laptop-offload-client.nix | `"/nix/store-remote"` | `{` |
| modules/services/laptop-offload-client.nix | `device` | `"${desktopIP}:/nix/store"` |
| modules/services/laptop-offload-client.nix | `fsType` | `"nfs"` |
| modules/services/laptop-offload-client.nix | `"rsize` | `8192"` |
| modules/services/laptop-offload-client.nix | `"wsize` | `8192"` |
| modules/services/laptop-offload-client.nix | `"timeo` | `14"` |
| modules/services/laptop-offload-client.nix | `"retry` | `2"` |
| modules/services/laptop-offload-client.nix | `device` | `"${desktopIP}:/var/lib/nix-offload"` |
| modules/services/laptop-offload-client.nix | `fsType` | `"nfs"` |
| modules/services/laptop-offload-client.nix | `"rsize` | `8192"` |
| modules/services/laptop-offload-client.nix | `"wsize` | `8192"` |
| modules/services/laptop-offload-client.nix | `"timeo` | `14"` |
| modules/services/laptop-offload-client.nix | `"retry` | `2"` |
| modules/services/laptop-offload-client.nix | `programs.ssh.extraConfig` | `''` |
| modules/services/laptop-offload-client.nix | `services.rpcbind.enable` | `true` |
| modules/services/laptop-offload-client.nix | `boot.kernel.sysctl` | `{` |
| modules/services/laptop-offload-client.nix | `"net.core.rmem_default"` | `262144` |
| modules/services/laptop-offload-client.nix | `systemd.services.offload-automount` | `{` |
| modules/services/laptop-offload-client.nix | `description` | `"Auto-mount offload NFS shares"` |
| modules/services/laptop-offload-client.nix | `after` | `[ "network-online.target" ]` |
| modules/services/laptop-offload-client.nix | `wants` | `[ "network-online.target" ]` |
| modules/services/laptop-offload-client.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/services/laptop-offload-client.nix | `script` | `''` |
| modules/services/laptop-offload-client.nix | `serviceConfig` | `{` |
| modules/services/laptop-offload-client.nix | `Type` | `"oneshot"` |
| modules/services/laptop-offload-client.nix | `RemainAfterExit` | `true` |
| modules/services/laptop-offload-client.nix | `Restart` | `"on-failure"` |
| modules/services/laptop-offload-client.nix | `RestartSec` | `"30s"` |
| modules/services/laptop-offload-client.nix | `systemd.services.offload-cleanup` | `{` |
| modules/services/laptop-offload-client.nix | `description` | `"Cleanup offload mounts on shutdown"` |
| modules/services/laptop-offload-client.nix | `before` | `[` |
| modules/services/laptop-offload-client.nix | `wantedBy` | `[` |
| modules/services/laptop-offload-client.nix | `script` | `''` |
| modules/services/laptop-offload-client.nix | `serviceConfig` | `{` |
| modules/services/laptop-offload-client.nix | `Type` | `"oneshot"` |
| modules/services/laptop-offload-client.nix | `RemainAfterExit` | `true` |
| modules/services/laptop-offload-client.nix | `TimeoutStopSec` | `"30s"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `"127.0.0.1"` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Upstream service host"` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Upstream service port"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `"http"` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Upstream protocol"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `false` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `false` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Enable basic authentication"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `null` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Path to htpasswd file for authentication"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `null` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Rate limit (e.g., '10r/s' for 10 requests per second)"` |
| modules/network/proxy/nginx-tailscale.nix | `example` | `"10r/s"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `"100M"` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Maximum client body size"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `300` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `false` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Enable WebSocket support"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `""` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Base hostname for Tailscale (will be hostname.tailnet.ts.net)"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `"tail-scale.ts.net"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Enable upstream connection pooling for better performance"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `32` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Number of keepalive connections to upstream"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Enable security headers (HSTS, CSP, etc.)"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Enable access logging"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Enable error logging"` |
| modules/network/proxy/nginx-tailscale.nix | `default` | `{ }` |
| modules/network/proxy/nginx-tailscale.nix | `description` | `"Services to expose via reverse proxy"` |
| modules/network/proxy/nginx-tailscale.nix | `example` | `literalExpression ''` |
| modules/network/proxy/nginx-tailscale.nix | `ollama` | `{` |
| modules/network/proxy/nginx-tailscale.nix | `enable` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `upstreamPort` | `11434` |
| modules/network/proxy/nginx-tailscale.nix | `rateLimit` | `"10r/s"` |
| modules/network/proxy/nginx-tailscale.nix | `services.nginx` | `{` |
| modules/network/proxy/nginx-tailscale.nix | `enable` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `recommendedGzipSettings` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `recommendedOptimisation` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `recommendedProxySettings` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `recommendedTlsSettings` | `true` |
| modules/network/proxy/nginx-tailscale.nix | `appendHttpConfig` | `''` |
| modules/network/proxy/nginx-tailscale.nix | `virtualHosts` | `mapAttrs' (` |
| modules/network/proxy/nginx-tailscale.nix | `enableACME` | `false` |
| modules/network/proxy/nginx-tailscale.nix | `http3` | `mkIf cfg.enableHTTP3 true` |
| modules/network/proxy/nginx-tailscale.nix | `quic` | `mkIf cfg.enableHTTP3 true` |
| modules/network/proxy/nginx-tailscale.nix | `basicAuth` | `mkIf service.enableAuth service.authFile` |
| modules/network/proxy/nginx-tailscale.nix | `extraConfig` | `''` |
| modules/network/proxy/nginx-tailscale.nix | `proxyPass` | `"${service.protocol}://${service.upstreamHost}:${toString service.upstreamPort}"` |
| modules/network/proxy/nginx-tailscale.nix | `extraConfig` | `''` |
| modules/network/proxy/nginx-tailscale.nix | `networking.firewall.allowedTCPPorts` | `[` |
| modules/network/proxy/nginx-tailscale.nix | `networking.firewall.allowedUDPPorts` | `mkIf cfg.enableHTTP3 [ 443 ]; # QUIC uses UDP` |
| modules/network/proxy/nginx-tailscale.nix | `systemd.tmpfiles.rules` | `[` |
| modules/network/proxy/nginx-tailscale.nix | `systemd.services.nginx` | `{` |
| modules/network/proxy/nginx-tailscale.nix | `after` | `[ "tailscaled.service" ]` |
| modules/network/proxy/nginx-tailscale.nix | `wants` | `[ "tailscaled.service" ]` |
| modules/network/proxy/nginx-tailscale.nix | `environment.shellAliases` | `{` |
| modules/network/proxy/nginx-tailscale.nix | `nginx-reload` | `"sudo systemctl reload nginx"` |
| modules/network/proxy/nginx-tailscale.nix | `nginx-test` | `"sudo nginx -t"` |
| modules/network/proxy/nginx-tailscale.nix | `nginx-logs` | `"sudo tail -f /var/log/nginx/*.log"` |
| modules/network/proxy/nginx-tailscale.nix | `nginx-access` | `"sudo tail -f /var/log/nginx/*_access.log"` |
| modules/network/proxy/nginx-tailscale.nix | `nginx-error` | `"sudo tail -f /var/log/nginx/*_error.log"` |
| modules/network/proxy/nginx-tailscale.nix | `warnings` | `(` |
| modules/network/vpn/tailscale.nix | `default` | `null` |
| modules/network/vpn/tailscale.nix | `description` | `"Path to file containing Tailscale auth key (SOPS encrypted)"` |
| modules/network/vpn/tailscale.nix | `example` | `"/run/secrets/tailscale-authkey"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Use auth key file for automatic authentication"` |
| modules/network/vpn/tailscale.nix | `default` | `[ ]` |
| modules/network/vpn/tailscale.nix | `description` | `"Subnets to advertise to the Tailscale network"` |
| modules/network/vpn/tailscale.nix | `example` | `[` |
| modules/network/vpn/tailscale.nix | `default` | `false` |
| modules/network/vpn/tailscale.nix | `description` | `"Enable subnet routing (advertise local networks)"` |
| modules/network/vpn/tailscale.nix | `default` | `false` |
| modules/network/vpn/tailscale.nix | `description` | `"Advertise this device as an exit node"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Allow LAN access when using this as an exit node"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Enable Tailscale MagicDNS for automatic hostname resolution"` |
| modules/network/vpn/tailscale.nix | `default` | `[ ]` |
| modules/network/vpn/tailscale.nix | `description` | `"Additional DNS servers to use alongside MagicDNS"` |
| modules/network/vpn/tailscale.nix | `example` | `[` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Accept routes advertised by other devices"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Enable SSH over Tailscale (Tailscale SSH)"` |
| modules/network/vpn/tailscale.nix | `default` | `false` |
| modules/network/vpn/tailscale.nix | `description` | `"Block incoming connections from other Tailscale devices"` |
| modules/network/vpn/tailscale.nix | `default` | `41641` |
| modules/network/vpn/tailscale.nix | `description` | `"UDP port for Tailscale to listen on"` |
| modules/network/vpn/tailscale.nix | `default` | `"tailscale0"` |
| modules/network/vpn/tailscale.nix | `description` | `"Name of the Tailscale network interface"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Enable connection persistence and automatic reconnection"` |
| modules/network/vpn/tailscale.nix | `default` | `30` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Open firewall ports for Tailscale"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `default` | `[ ]` |
| modules/network/vpn/tailscale.nix | `description` | `"Tailscale ACL tags for this device"` |
| modules/network/vpn/tailscale.nix | `example` | `[` |
| modules/network/vpn/tailscale.nix | `default` | `[ ]` |
| modules/network/vpn/tailscale.nix | `description` | `"Additional flags to pass to tailscale up"` |
| modules/network/vpn/tailscale.nix | `example` | `[ "--accept-risk=lose-ssh" ]` |
| modules/network/vpn/tailscale.nix | `default` | `[ ]` |
| modules/network/vpn/tailscale.nix | `description` | `"Additional flags for tailscaled daemon"` |
| modules/network/vpn/tailscale.nix | `default` | `true` |
| modules/network/vpn/tailscale.nix | `description` | `"Automatically start Tailscale on boot"` |
| modules/network/vpn/tailscale.nix | `default` | `"/var/lib/tailscale"` |
| modules/network/vpn/tailscale.nix | `description` | `"Directory for Tailscale state files"` |
| modules/network/vpn/tailscale.nix | `boot.kernel.sysctl` | `mkIf (cfg.enableSubnetRouter || cfg.exitNode) {` |
| modules/network/vpn/tailscale.nix | `services.tailscale` | `{` |
| modules/network/vpn/tailscale.nix | `enable` | `true` |
| modules/network/vpn/tailscale.nix | `port` | `cfg.port` |
| modules/network/vpn/tailscale.nix | `interfaceName` | `cfg.interfaceName` |
| modules/network/vpn/tailscale.nix | `routeFlags` | `optionals (cfg.enableSubnetRouter && cfg.advertiseRoutes != [ ]) [` |
| modules/network/vpn/tailscale.nix | `"--advertise-routes` | `${concatStringsSep "," cfg.advertiseRoutes}"` |
| modules/network/vpn/tailscale.nix | `"--accept-dns` | `true"` |
| modules/network/vpn/tailscale.nix | `"--accept-dns` | `false"` |
| modules/network/vpn/tailscale.nix | `"--accept-routes` | `true"` |
| modules/network/vpn/tailscale.nix | `"--accept-routes` | `false"` |
| modules/network/vpn/tailscale.nix | `sshFlags` | `optionals cfg.enableSSH [` |
| modules/network/vpn/tailscale.nix | `shieldsFlags` | `optionals cfg.shieldsUp [` |
| modules/network/vpn/tailscale.nix | `hostnameFlags` | `optional (cfg.hostname != "") "--hostname=${cfg.hostname}"` |
| modules/network/vpn/tailscale.nix | `tagFlags` | `optionals (cfg.tags != [ ]) [` |
| modules/network/vpn/tailscale.nix | `"--advertise-tags` | `${concatStringsSep "," cfg.tags}"` |
| modules/network/vpn/tailscale.nix | `authKeyFile` | `mkIf (cfg.useAuthKeyFile && cfg.authKeyFile != null) cfg.authKeyFile` |
| modules/network/vpn/tailscale.nix | `systemd.services.tailscaled` | `{` |
| modules/network/vpn/tailscale.nix | `after` | `[ "network-pre.target" ]` |
| modules/network/vpn/tailscale.nix | `wants` | `[ "network-pre.target" ]` |
| modules/network/vpn/tailscale.nix | `wantedBy` | `mkIf cfg.autoStart [ "multi-user.target" ]` |
| modules/network/vpn/tailscale.nix | `serviceConfig` | `{` |
| modules/network/vpn/tailscale.nix | `PrivateTmp` | `true` |
| modules/network/vpn/tailscale.nix | `ProtectSystem` | `"strict"` |
| modules/network/vpn/tailscale.nix | `ProtectHome` | `true` |
| modules/network/vpn/tailscale.nix | `ReadWritePaths` | `[ cfg.stateDir ]` |
| modules/network/vpn/tailscale.nix | `MemoryMax` | `"512M"` |
| modules/network/vpn/tailscale.nix | `TasksMax` | `256` |
| modules/network/vpn/tailscale.nix | `Restart` | `mkIf cfg.enableConnectionPersistence "on-failure"` |
| modules/network/vpn/tailscale.nix | `RestartSec` | `mkIf cfg.enableConnectionPersistence cfg.reconnectTimeout` |
| modules/network/vpn/tailscale.nix | `StateDirectory` | `"tailscale"` |
| modules/network/vpn/tailscale.nix | `networking.firewall` | `mkMerge [` |
| modules/network/vpn/tailscale.nix | `allowedUDPPorts` | `[ cfg.port ]` |
| modules/network/vpn/tailscale.nix | `trustedInterfaces` | `mkIf cfg.trustedInterface [ cfg.interfaceName ]` |
| modules/network/vpn/tailscale.nix | `checkReversePath` | `mkIf (cfg.enableSubnetRouter || cfg.exitNode) "loose"` |
| modules/network/vpn/tailscale.nix | `extraCommands` | `mkIf (cfg.enableSubnetRouter || cfg.exitNode) ''` |
| modules/network/vpn/tailscale.nix | `extraStopCommands` | `mkIf (cfg.enableSubnetRouter || cfg.exitNode) ''` |
| modules/network/vpn/tailscale.nix | `extraConfig` | `''` |
| modules/network/vpn/tailscale.nix | `DNSStubListener` | `no` |
| modules/network/vpn/tailscale.nix | `systemd.tmpfiles.rules` | `[` |
| modules/network/vpn/tailscale.nix | `environment.shellAliases` | `{` |
| modules/network/vpn/tailscale.nix | `ts-logs` | `"journalctl -u tailscaled -f"` |
| modules/network/vpn/tailscale.nix | `docker-ts-urls` | `''` |
| modules/network/vpn/tailscale.nix | `echo "` | `== Docker Containers via Tailscale ===" && \` |
| modules/network/vpn/tailscale.nix | `docker ps --format "{{.Names}}\t{{.Ports}}" | grep -v "PORTS" | while IFS` | `$'\t' read name ports; do` |
| modules/network/vpn/tailscale.nix | `port` | `$(echo "$ports" | grep -oP '0.0.0.0:\K\d+' | head -1)` |
| modules/network/vpn/tailscale.nix | `my-ips` | `''` |
| modules/network/vpn/tailscale.nix | `mode` | `"0755"` |
| modules/network/vpn/tailscale.nix | `text` | `''` |
| modules/network/vpn/tailscale.nix | `RED` | `'\033[0;31m'` |
| modules/network/vpn/tailscale.nix | `GREEN` | `'\033[0;32m'` |
| modules/network/vpn/tailscale.nix | `YELLOW` | `'\033[1;33m'` |
| modules/network/vpn/tailscale.nix | `BLUE` | `'\033[0;34m'` |
| modules/network/vpn/tailscale.nix | `NC` | `'\033[0m'` |
| modules/network/vpn/tailscale.nix | `echo -e "''${BLUE}` | `=================================="` |
| modules/network/vpn/tailscale.nix | `echo -e "` | `==================================''${NC}"` |
| modules/network/vpn/tailscale.nix | `cfg.exitNode && !cfg.enableSubnetRouter && cfg.advertiseRoutes !` | `[ ]` |
| modules/network/vpn/tailscale.nix | `cfg.enableSubnetRouter && cfg.advertiseRoutes` | `= [ ]` |
| modules/virtualization/vms.nix | `default` | `[ "kernelcore" ]` |
| modules/virtualization/vms.nix | `description` | `"Users to add to the libvirtd group for VM management"` |
| modules/virtualization/vms.nix | `default` | `"/srv/vms/images"` |
| modules/virtualization/vms.nix | `description` | `"Directory where VM disk images are stored (qcow2)."` |
| modules/virtualization/vms.nix | `default` | `"/var/lib/vm-images"` |
| modules/virtualization/vms.nix | `description` | `"Directory for original/source VM images (e.g., OVA/VMDK/QCOW2) kept outside the repo."` |
| modules/virtualization/vms.nix | `description` | `"Declarative VM registry for libvirt (qcow2 imports)."` |
| modules/virtualization/vms.nix | `default` | `{ }` |
| modules/virtualization/vms.nix | `default` | `null` |
| modules/virtualization/vms.nix | `default` | `null` |
| modules/virtualization/vms.nix | `description` | `"Target qcow2 file path. Defaults to vmBaseDir/<name>.qcow2 if null."` |
| modules/virtualization/vms.nix | `default` | `4096` |
| modules/virtualization/vms.nix | `default` | `2` |
| modules/virtualization/vms.nix | `description` | `"Number of virtual CPUs."` |
| modules/virtualization/vms.nix | `default` | `"nat"` |
| modules/virtualization/vms.nix | `description` | `"Network mode: NAT (default) or bridge."` |
| modules/virtualization/vms.nix | `default` | `"br0"` |
| modules/virtualization/vms.nix | `description` | `"Bridge name when network=bridge."` |
| modules/virtualization/vms.nix | `default` | `null` |
| modules/virtualization/vms.nix | `description` | `"Optional fixed MAC address."` |
| modules/virtualization/vms.nix | `default` | `false` |
| modules/virtualization/vms.nix | `description` | `"Mark VM to autostart under libvirt."` |
| modules/virtualization/vms.nix | `description` | `"Host directory to share"` |
| modules/virtualization/vms.nix | `default` | `"hostshare"` |
| modules/virtualization/vms.nix | `description` | `"Guest mount tag"` |
| modules/virtualization/vms.nix | `default` | `"virtiofs"` |
| modules/virtualization/vms.nix | `description` | `"Share driver"` |
| modules/virtualization/vms.nix | `default` | `false` |
| modules/virtualization/vms.nix | `description` | `"Mount read-only"` |
| modules/virtualization/vms.nix | `default` | `true` |
| modules/virtualization/vms.nix | `description` | `"Create host dir if missing"` |
| modules/virtualization/vms.nix | `default` | `[ ]` |
| modules/virtualization/vms.nix | `description` | `"Host directories exposed to the guest via virtiofs or 9p."` |
| modules/virtualization/vms.nix | `default` | `true` |
| modules/virtualization/vms.nix | `description` | `"Enable clipboard sharing between host and guest via SPICE"` |
| modules/virtualization/vms.nix | `description` | `"Path to the additional disk image"` |
| modules/virtualization/vms.nix | `default` | `null` |
| modules/virtualization/vms.nix | `description` | `"Size of the disk (e.g., '20G', '50G'). If null, assumes disk already exists."` |
| modules/virtualization/vms.nix | `default` | `"qcow2"` |
| modules/virtualization/vms.nix | `description` | `"Disk format"` |
| modules/virtualization/vms.nix | `default` | `"virtio"` |
| modules/virtualization/vms.nix | `description` | `"Disk bus type"` |
| modules/virtualization/vms.nix | `default` | `[ ]` |
| modules/virtualization/vms.nix | `description` | `"Additional disk images to attach to the VM"` |
| modules/virtualization/vms.nix | `default` | `[ ]` |
| modules/virtualization/vms.nix | `description` | `"Extra arguments to pass to virt-install (e.g., graphics settings)."` |
| modules/virtualization/vms.nix | `virtualisation` | `{` |
| modules/virtualization/vms.nix | `libvirtd` | `{` |
| modules/virtualization/vms.nix | `enable` | `true` |
| modules/virtualization/vms.nix | `onBoot` | `"ignore"` |
| modules/virtualization/vms.nix | `onShutdown` | `"shutdown"` |
| modules/virtualization/vms.nix | `qemu` | `{` |
| modules/virtualization/vms.nix | `runAsRoot` | `false` |
| modules/virtualization/vms.nix | `swtpm.enable` | `true` |
| modules/virtualization/vms.nix | `verbatimConfig` | `''` |
| modules/virtualization/vms.nix | `memory_backing_dir` | `"/dev/shm"` |
| modules/virtualization/vms.nix | `max_core` | `"unlimited"` |
| modules/virtualization/vms.nix | `allowedBridges` | `[` |
| modules/virtualization/vms.nix | `spiceUSBRedirection.enable` | `true` |
| modules/virtualization/vms.nix | `systemd.services.libvirtd.serviceConfig` | `{` |
| modules/virtualization/vms.nix | `LimitNOFILE` | `"infinity"` |
| modules/virtualization/vms.nix | `LimitCORE` | `"infinity"` |
| modules/virtualization/vms.nix | `LimitMEMLOCK` | `"infinity"` |
| modules/virtualization/vms.nix | `security.polkit.enable` | `true` |
| modules/virtualization/vms.nix | `security.polkit.extraConfig` | `''` |
| modules/virtualization/vms.nix | `if (action.id` | `= "org.libvirt.unix.manage" &&` |
| modules/virtualization/vms.nix | `environment.systemPackages` | `(` |
| modules/virtualization/vms.nix | `systemd.tmpfiles.rules` | `[` |
| modules/virtualization/vms.nix | `systemd.services.libvirtd-setup` | `{` |
| modules/virtualization/vms.nix | `description` | `"Initialize libvirt default resources (network, storage pool)"` |
| modules/virtualization/vms.nix | `after` | `[ "libvirtd.service" ]` |
| modules/virtualization/vms.nix | `wants` | `[ "libvirtd.service" ]` |
| modules/virtualization/vms.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/virtualization/vms.nix | `serviceConfig` | `{` |
| modules/virtualization/vms.nix | `Type` | `"oneshot"` |
| modules/virtualization/vms.nix | `RemainAfterExit` | `true` |
| modules/virtualization/vms.nix | `script` | `''` |
| modules/virtualization/vms.nix | `vms` | `mapAttrs (n: v: {` |
| modules/virtualization/vms.nix | `name` | `n` |
| modules/virtualization/vms.nix | `enable` | `v.enable or true` |
| modules/virtualization/vms.nix | `sourceImage` | `v.sourceImage` |
| modules/virtualization/vms.nix | `imageFile` | `if v.imageFile != null then v.imageFile else "${baseDir}/" + n + ".qcow2"` |
| modules/virtualization/vms.nix | `memoryMiB` | `v.memoryMiB` |
| modules/virtualization/vms.nix | `vcpus` | `v.vcpus` |
| modules/virtualization/vms.nix | `network` | `v.network` |
| modules/virtualization/vms.nix | `bridgeName` | `v.bridgeName` |
| modules/virtualization/vms.nix | `macAddress` | `v.macAddress` |
| modules/virtualization/vms.nix | `autostart` | `v.autostart` |
| modules/virtualization/vms.nix | `sharedDirs` | `v.sharedDirs` |
| modules/virtualization/vms.nix | `enableClipboard` | `v.enableClipboard` |
| modules/virtualization/vms.nix | `additionalDisks` | `v.additionalDisks` |
| modules/virtualization/vms.nix | `extraVirtInstallArgs` | `v.extraVirtInstallArgs` |
| modules/virtualization/vms.nix | `system.activationScripts.vmCenter` | `{` |
| modules/virtualization/vms.nix | `text` | `''` |
| modules/virtualization/vms.nix | `REG` | `"/etc/vm-registry.json"` |
| modules/virtualization/vms.nix | `[ "$ENABLE"` | `"true" ] || continue` |
| modules/virtualization/vms.nix | `CANDIDATE` | `"$SRC"` |
| modules/virtualization/vms.nix | `REAL_IMG` | `$(readlink -f "$IMG")` |
| modules/virtualization/vms.nix | `REAL_IMG` | `$(readlink -f "$IMG" 2>/dev/null || echo "$IMG")` |
| modules/virtualization/vms.nix | `EXTRA` | `()` |
| modules/virtualization/vms.nix | `FS_ARGS` | `()` |
| modules/virtualization/vms.nix | `[ "$SH_CREATE"` | `"true" ] && mkdir -p "$SH_PATH"` |
| modules/virtualization/vms.nix | `if [ "$SH_DRV"` | `"virtiofs" ]; then` |
| modules/virtualization/vms.nix | `NETARG_VALUE` | `"network=default"` |
| modules/virtualization/vms.nix | `if [ "$NET"` | `"bridge" ]; then` |
| modules/virtualization/vms.nix | `NETARG_VALUE` | `"bridge=$BR"` |
| modules/virtualization/vms.nix | `NETARG_VALUE` | `"$NETARG_VALUE,mac=$MAC"` |
| modules/virtualization/vms.nix | `GRAPHICS_ARGS` | `()` |
| modules/virtualization/vms.nix | `if [ "$ENABLE_CLIP"` | `"true" ]; then` |
| modules/virtualization/vms.nix | `MEM_BACKING` | `()` |
| modules/virtualization/vms.nix | `MEM_BACKING` | `("--memorybacking" "source.type=memfd,access.mode=shared")` |
| modules/virtualization/vms.nix | `--disk path` | `"$REAL_IMG",format=qcow2,bus=virtio \` |
| modules/virtualization/vms.nix | `--os-variant detect` | `on,require=off \` |
| modules/virtualization/vms.nix | `if [ "$AUT"` | `"true" ]; then` |
| modules/programs/cognitive-vault.nix | `description` | `"The cognitive-vault package to install."` |
| modules/programs/cognitive-vault.nix | `environment.systemPackages` | `[ cfg.package ]` |
| modules/programs/cognitive-vault.nix | `environment.variables` | `{` |
| modules/programs/cognitive-vault.nix | `CV_VAULT_PATH` | `"$HOME/.vault.dat"` |
| modules/security/compiler-hardening.nix | `environment.variables` | `{` |
| modules/security/compiler-hardening.nix | `HARDENING_ENABLE` | `"fortify stackprotector pic strictoverflow format relro bindnow"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `services.mako` | `{` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `settings` | `{` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `font` | `"JetBrainsMono Nerd Font 11"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `anchor` | `"top-right"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `layer` | `"overlay"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `padding` | `"16,20,16,20"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `width` | `380` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `height` | `150` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `background-color` | `"#12121aE6"; # 90% opacity` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text-color` | `"#e4e4e7"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-size` | `2` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `"#7c3aed"; # Default: violet` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-radius` | `12` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `icons` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `max-icon-size` | `48` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `max-visible` | `5` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `default-timeout` | `5000` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ignore-timeout` | `false` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `group-by` | `"app-name,summary"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `actions` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `markup` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `format` | `"<b>%s</b>\\n%b"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `extraConfig` | `''` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[urgency` | `low]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#00d4ff` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `background-color` | `#12121aCC` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text-color` | `#a1a1aa` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `default-timeout` | `3000` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[urgency` | `normal]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#7c3aed` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `background-color` | `#12121aE6` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text-color` | `#e4e4e7` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `default-timeout` | `5000` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[urgency` | `critical]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#ff00aa` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `background-color` | `#1a0a12E6` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text-color` | `#ffffff` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `default-timeout` | `0` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ignore-timeout` | `1` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Discord"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#5865F2` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Spotify"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#1DB954` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Firefox"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#FF7139` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Brave"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#FB542B` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Code"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#007ACC` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"VSCodium"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#2F80ED` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Alacritty"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#00d4ff` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"kitty"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#67e8f9` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"zellij"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#00d4ff` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"notify-send"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#7c3aed` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Swappy"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#00d4ff` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"grim"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#00d4ff` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"pamixer"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#7c3aed` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `max-visible` | `1` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `default-timeout` | `1500` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"brightnessctl"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#7c3aed` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `max-visible` | `1` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `default-timeout` | `1500` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"NetworkManager"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#22c55e` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"nm-applet"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#22c55e` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"blueman"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#3b82f6` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"KeePassXC"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#22c55e` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[app-name` | `"Agent Hub"]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `border-color` | `#ff00aa` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `background-color` | `#1a0a18E6` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `format` | `<b>%s</b> (%g)\n%b` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `[mode` | `do-not-disturb]` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `invisible` | `1` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `VOLUME` | `$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `MUTED` | `$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰝟"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `TEXT` | `"Muted"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰕾"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `TEXT` | `"$VOLUME%"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰖀"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `TEXT` | `"$VOLUME%"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰕿"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `TEXT` | `"$VOLUME%"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `BRIGHTNESS` | `$(brightnessctl get)` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `MAX` | `$(brightnessctl max)` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `PERCENT` | `$((BRIGHTNESS * 100 / MAX))` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰃠"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰃟"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `ICON` | `"󰃞"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `FILE` | `"$1"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `TYPE` | `"$2"  # "area", "screen", "clipboard"` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/mako.nix | `text` | `''` |
| hosts/kernelcore/home/aliases/gpu.sh | `tokenizer` | `AutoTokenizer.from_pretrained("gpt2")` |
| hosts/kernelcore/home/aliases/gpu.sh | `model` | `AutoModelForCausalLM.from_pretrained("gpt2")` |
| hosts/kernelcore/home/aliases/gpu.sh | `model` | `model.to("cuda")` |
| hosts/kernelcore/home/aliases/gpu.sh | `input_text` | `"The future of AI is"` |
| hosts/kernelcore/home/aliases/gpu.sh | `inputs` | `tokenizer(input_text, return_tensors="pt").to("cuda")` |
| hosts/kernelcore/home/aliases/gpu.sh | `outputs` | `model.generate(` |
| hosts/kernelcore/home/aliases/gpu.sh | `max_new_tokens` | `20,` |
| hosts/kernelcore/home/aliases/gpu.sh | `temperature` | `0.7,` |
| hosts/kernelcore/home/aliases/gpu.sh | `do_sample` | `True` |
| hosts/kernelcore/home/aliases/gpu.sh | `result` | `tokenizer.decode(outputs[0], skip_special_tokens=True)` |
| hosts/kernelcore/home/aliases/gpu.sh | `print(f"\n" + "` | `" * 60)` |
| hosts/kernelcore/home/aliases/gpu.sh | `print("` | `" * 60)` |
| hosts/kernelcore/home/aliases/gpu.sh | `alias gpu-shell` | `'docker run --rm -it \` |
| hosts/kernelcore/home/aliases/gpu.sh | `--device` | `nvidia.com/gpu=all \` |
| hosts/kernelcore/home/aliases/gpu.sh | `alias gpu-dev` | `'docker run --rm -it \` |
| hosts/kernelcore/home/aliases/gpu.sh | `--device` | `nvidia.com/gpu=all \` |
| hosts/kernelcore/home/aliases/gpu.sh | `alias gpu-net` | `'docker run --rm -it \` |
| hosts/kernelcore/home/aliases/gpu.sh | `--device` | `nvidia.com/gpu=all \` |
| hosts/kernelcore/home/aliases/gpu.sh | `alias gpu-test` | `'docker run --rm -it \` |
| hosts/kernelcore/home/aliases/gpu.sh | `--device` | `nvidia.com/gpu=all \` |
| hosts/kernelcore/home/aliases/gpu.sh | `alias gpu-quick` | `'docker run --rm \` |
| hosts/kernelcore/home/aliases/gpu.sh | `--device` | `nvidia.com/gpu=all \` |
| modules/programs/vmctl.nix | `description` | `"The vmctl package to install."` |
| modules/programs/vmctl.nix | `default` | `true` |
| modules/programs/vmctl.nix | `description` | `"Path to VM disk image."` |
| modules/programs/vmctl.nix | `default` | `"4G"` |
| modules/programs/vmctl.nix | `default` | `2` |
| modules/programs/vmctl.nix | `default` | `"user"` |
| modules/programs/vmctl.nix | `default` | `"gtk"` |
| modules/programs/vmctl.nix | `default` | `{ }` |
| modules/programs/vmctl.nix | `environment.systemPackages` | `[` |
| modules/programs/vmctl.nix | `vmToToml` | `name: vm: ''` |
| modules/programs/vmctl.nix | `enabled` | `${boolToString vm.enabled}` |
| modules/programs/vmctl.nix | `image` | `"${vm.image}"` |
| modules/programs/vmctl.nix | `memory` | `"${vm.memory}"` |
| modules/programs/vmctl.nix | `cpus` | `${toString vm.cpus}` |
| modules/programs/vmctl.nix | `network` | `"${vm.network}"` |
| modules/programs/vmctl.nix | `display` | `"${vm.display}"` |
| modules/programs/vmctl.nix | `systemd.tmpfiles.rules` | `[ "d /run/vmctl 0755 root root -" ]` |
| modules/services/scripts.nix | `environment.shellAliases` | `{` |
| modules/services/scripts.nix | `tgi` | `"docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g ghcr.io/huggingface/text-generation-inference: [... omitted end of long line]` |
| modules/services/scripts.nix | `pytorch` | `"docker run --rm -it --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g nvcr.io/nvidia/pytorch:25.09-py3"` |
| modules/services/scripts.nix | `jup-ml` | `"docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g"` |
| modules/services/scripts.nix | `nx` | `"cd /etc/nixos"; # Quick jump to NixOS config` |
| modules/network/bridge.nix | `default` | `"br0"` |
| modules/network/bridge.nix | `description` | `"Bridge interface name."` |
| modules/network/bridge.nix | `default` | `""` |
| modules/network/bridge.nix | `description` | `"Physical interface to attach as bridge slave (empty = auto-detect first active ethernet)."` |
| modules/network/bridge.nix | `default` | `false` |
| modules/network/bridge.nix | `assertions` | `[` |
| modules/network/bridge.nix | `message` | `"kernelcore.network.bridge requires networking.networkmanager.enable = true."` |
| modules/network/bridge.nix | `systemd.services.ensure-br0` | `{` |
| modules/network/bridge.nix | `description` | `"Ensure NetworkManager bridge ${cfg.name} exists"` |
| modules/network/bridge.nix | `after` | `[ "NetworkManager.service" ]` |
| modules/network/bridge.nix | `wants` | `[ "NetworkManager.service" ]` |
| modules/network/bridge.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/network/bridge.nix | `serviceConfig` | `{` |
| modules/network/bridge.nix | `Type` | `"oneshot"` |
| modules/network/bridge.nix | `path` | `[` |
| modules/network/bridge.nix | `script` | `''` |
| modules/network/bridge.nix | `BR` | `"${cfg.name}"` |
| modules/network/bridge.nix | `UPL` | `"${cfg.uplinkInterface}"` |
| modules/network/bridge.nix | `UPL` | `$(nmcli -t -f DEVICE,TYPE,STATE dev | awk -F: '$2=="ethernet" && $3~/(connected|connecting)/ {print $1; exit}') || true` |
| modules/network/proxy/tailscale-services.nix | `default` | `"tail-scale.ts.net"` |
| modules/network/proxy/tailscale-services.nix | `description` | `"Your Tailscale tailnet domain"` |
| modules/network/proxy/tailscale-services.nix | `kernelcore.network.vpn.tailscale.enable` | `true` |
| modules/network/proxy/tailscale-services.nix | `kernelcore.network.proxy.nginx-tailscale.enable` | `true` |
| modules/network/proxy/tailscale-services.nix | `kernelcore.secrets.tailscale.enable` | `true` |
| modules/network/proxy/tailscale-services.nix | `kernelcore.network.vpn.tailscale` | `{` |
| modules/network/proxy/tailscale-services.nix | `useAuthKeyFile` | `pathExists "/etc/nixos/secrets/tailscale.yaml"` |
| modules/network/proxy/tailscale-services.nix | `enableSubnetRouter` | `true` |
| modules/network/proxy/tailscale-services.nix | `advertiseRoutes` | `[ "192.168.15.0/24" ]` |
| modules/network/proxy/tailscale-services.nix | `exitNode` | `true` |
| modules/network/proxy/tailscale-services.nix | `exitNodeAllowLANAccess` | `true` |
| modules/network/proxy/tailscale-services.nix | `acceptDNS` | `true` |
| modules/network/proxy/tailscale-services.nix | `enableMagicDNS` | `true` |
| modules/network/proxy/tailscale-services.nix | `acceptRoutes` | `true` |
| modules/network/proxy/tailscale-services.nix | `openFirewall` | `true` |
| modules/network/proxy/tailscale-services.nix | `trustedInterface` | `true` |
| modules/network/proxy/tailscale-services.nix | `tags` | `[` |
| modules/network/proxy/tailscale-services.nix | `enableConnectionPersistence` | `true` |
| modules/network/proxy/tailscale-services.nix | `reconnectTimeout` | `30` |
| modules/network/proxy/tailscale-services.nix | `kernelcore.network.proxy.nginx-tailscale` | `{` |
| modules/network/proxy/tailscale-services.nix | `enableHTTP3` | `true` |
| modules/network/proxy/tailscale-services.nix | `enableConnectionPooling` | `true` |
| modules/network/proxy/tailscale-services.nix | `enableSecurityHeaders` | `true` |
| modules/network/proxy/tailscale-services.nix | `services` | `{` |
| modules/network/proxy/tailscale-services.nix | `ollama` | `{` |
| modules/network/proxy/tailscale-services.nix | `upstreamPort` | `11434` |
| modules/network/proxy/tailscale-services.nix | `rateLimit` | `"20r/s"` |
| modules/network/proxy/tailscale-services.nix | `maxBodySize` | `"500M"; # Large for model uploads` |
| modules/network/proxy/tailscale-services.nix | `timeout` | `600; # 10 minutes for long inference` |
| modules/network/proxy/tailscale-services.nix | `enableWebSocket` | `false` |
| modules/network/proxy/tailscale-services.nix | `llamacpp` | `{` |
| modules/network/proxy/tailscale-services.nix | `upstreamPort` | `8080` |
| modules/network/proxy/tailscale-services.nix | `rateLimit` | `"10r/s"` |
| modules/network/proxy/tailscale-services.nix | `maxBodySize` | `"100M"` |
| modules/network/proxy/tailscale-services.nix | `timeout` | `300` |
| modules/network/proxy/tailscale-services.nix | `postgresql` | `{` |
| modules/network/proxy/tailscale-services.nix | `upstreamPort` | `5432` |
| modules/network/proxy/tailscale-services.nix | `rateLimit` | `"50r/s"` |
| modules/network/proxy/tailscale-services.nix | `maxBodySize` | `"10M"` |
| modules/network/proxy/tailscale-services.nix | `timeout` | `60` |
| modules/network/proxy/tailscale-services.nix | `enableAuth` | `true; # Require authentication` |
| modules/network/proxy/tailscale-services.nix | `gitea` | `{` |
| modules/network/proxy/tailscale-services.nix | `upstreamPort` | `3000` |
| modules/network/proxy/tailscale-services.nix | `rateLimit` | `"30r/s"` |
| modules/network/proxy/tailscale-services.nix | `maxBodySize` | `"200M"; # Large for repository pushes` |
| modules/network/proxy/tailscale-services.nix | `timeout` | `180` |
| modules/network/proxy/tailscale-services.nix | `docker-api` | `{` |
| modules/network/proxy/tailscale-services.nix | `upstreamHost` | `"unix:/var/run/docker.sock"` |
| modules/network/proxy/tailscale-services.nix | `upstreamPort` | `2375` |
| modules/network/proxy/tailscale-services.nix | `rateLimit` | `"10r/s"` |
| modules/network/proxy/tailscale-services.nix | `enableAuth` | `true; # Critical: require authentication` |
| modules/network/proxy/tailscale-services.nix | `extraConfig` | `''` |
| modules/network/vpn/tailscale-laptop.nix | `kernelcore.network.vpn.tailscale` | `{` |
| modules/network/vpn/tailscale-laptop.nix | `enable` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `hostname` | `"laptop-kernelcore"; # Nome bonito no Tailscale` |
| modules/network/vpn/tailscale-laptop.nix | `acceptDNS` | `true; # MagicDNS (usar hostnames)` |
| modules/network/vpn/tailscale-laptop.nix | `enableMagicDNS` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `enableSSH` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `shieldsUp` | `false; # Allow connections from other devices` |
| modules/network/vpn/tailscale-laptop.nix | `enableConnectionPersistence` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `reconnectTimeout` | `30` |
| modules/network/vpn/tailscale-laptop.nix | `openFirewall` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `trustedInterface` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `autoStart` | `true` |
| modules/network/vpn/tailscale-laptop.nix | `tags` | `[` |
| modules/network/vpn/tailscale-laptop.nix | `extraUpFlags` | `[` |
| modules/network/vpn/tailscale-laptop.nix | `environment.shellAliases` | `{` |
| modules/network/vpn/tailscale-laptop.nix | `ts-check` | `''` |
| modules/network/vpn/tailscale-laptop.nix | `environment.interactiveShellInit` | `''` |
| modules/security/boot.nix | `boot.loader.systemd-boot.enable` | `true` |
| modules/security/boot.nix | `boot.loader.efi.canTouchEfiVariables` | `true` |
| modules/security/boot.nix | `boot.kernelParams` | `[` |
| modules/security/boot.nix | `"acpi_backlight` | `native"` |
| modules/security/boot.nix | `"pcie_aspm` | `force"` |
| modules/programs/default.nix | `programs.sway.xwayland.enable` | `true` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `save_dir` | `$HOME/Pictures/Screenshots` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `save_filename_format` | `screenshot-%Y%m%d-%H%M%S.png` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `show_panel` | `true` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `line_size` | `5` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `text_size` | `20` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `text_font` | `JetBrainsMono Nerd Font` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `paint_mode` | `brush` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `early_exit` | `false` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `SCREENSHOT_DIR` | `"$HOME/Pictures/Screenshots"` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `MODE` | `"''${1:-region}"  # region, screen, or window` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `GEOMETRY` | `$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `FILENAME` | `"$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `FILENAME` | `"$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `TEMP_FILE` | `$(mktemp /tmp/screenshot-ocr-XXXXXX.png)` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `TEXT` | `$(tesseract "$TEMP_FILE" stdout 2>/dev/null)` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `COLOR` | `$(hyprpicker -a -f hex)` |
| hosts/kernelcore/home/glassmorphism/swappy.nix | `home.activation.createScreenshotsDir` | `lib.hm.dag.entryAfter [ "writeBoundary" ] ''` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `dockerOrchPath` | `"/home/kernelcore/Documents/nx/docker/main.py"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `orch` | `"python3 ${dockerOrchPath}"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `dstack` | `orch` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `dstack-list` | `"${orch} list"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ai-up` | `"${orch} up multimodal"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ai-down` | `"${orch} down multimodal"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ai-status` | `"${orch} status multimodal"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ai-logs` | `"${orch} logs multimodal -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ai-health` | `"${orch} health multimodal"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ai-restart` | `"${orch} restart multimodal"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `gpu-up` | `"${orch} up gpu"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `gpu-down` | `"${orch} down gpu"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `gpu-status` | `"${orch} status gpu"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `gpu-logs` | `"${orch} logs gpu -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `gpu-health` | `"${orch} health gpu"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `gpu-restart` | `"${orch} restart gpu"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `all-up` | `"${orch} up-all"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `all-down` | `"${orch} down-all"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `all-status` | `"${orch} status"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `all-health` | `"${orch} health"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `api-logs` | `"${orch} logs gpu api -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `db-logs` | `"${orch} logs gpu db -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `jupyter-logs-gpu` | `"${orch} logs gpu jupyter -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `jupyter-logs-ai` | `"${orch} logs multimodal jupyter -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `nginx-logs-gpu` | `"${orch} logs gpu nginx -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `nginx-logs-ai` | `"${orch} logs multimodal nginx -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ollama-logs` | `"${orch} logs multimodal ollama -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `vllm-logs` | `"${orch} logs multimodal vllm -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `whisper-logs` | `"${orch} logs multimodal whisper-api -f"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `api-restart` | `"${orch} restart gpu api"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `db-restart` | `"${orch} restart gpu db"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `ollama-list` | `"docker exec ollama-gpu ollama list 2>/dev/null || echo 'Ollama não está rodando'"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `dps` | `"docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | head -20"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `dlogs-help` | `"echo 'Use: ${orch} logs <stack> <service> -f'"` |
| hosts/kernelcore/home/aliases/nixos-aliases.nix | `drestart-help` | `"echo 'Use: ${orch} restart <stack> <service>'"` |
| modules/services/mcp-server.nix | `mcpConfig` | `{` |
| modules/services/mcp-server.nix | `mcpServers` | `{` |
| modules/services/mcp-server.nix | `securellm-bridge` | `{` |
| modules/services/mcp-server.nix | `command` | `"nix"` |
| modules/services/mcp-server.nix | `args` | `[` |
| modules/services/mcp-server.nix | `env` | `{` |
| modules/services/mcp-server.nix | `KNOWLEDGE_DB_PATH` | `"${cfg.dataDir}/knowledge.db"` |
| modules/services/mcp-server.nix | `ENABLE_KNOWLEDGE` | `"true"` |
| modules/services/mcp-server.nix | `default` | `"kernelcore"` |
| modules/services/mcp-server.nix | `description` | `"User to run the MCP server as"` |
| modules/services/mcp-server.nix | `default` | `"/var/lib/mcp-knowledge"` |
| modules/services/mcp-server.nix | `description` | `"Directory for MCP knowledge database"` |
| modules/services/mcp-server.nix | `description` | `"The SecureLLM MCP package to use"` |
| modules/services/mcp-server.nix | `default` | `true` |
| modules/services/mcp-server.nix | `environment.systemPackages` | `[` |
| modules/services/mcp-server.nix | `CYAN` | `'\033[0;36m'` |
| modules/services/mcp-server.nix | `GREEN` | `'\033[0;32m'` |
| modules/services/mcp-server.nix | `YELLOW` | `'\033[1;33m'` |
| modules/services/mcp-server.nix | `RED` | `'\033[0;31m'` |
| modules/services/mcp-server.nix | `BOLD` | `'\033[1m'` |
| modules/services/mcp-server.nix | `NC` | `'\033[0m'` |
| modules/services/mcp-server.nix | `BACKUP_FILE` | `"${cfg.dataDir}/knowledge-backup-$(date +%Y%m%d-%H%M%S).db"` |
| modules/services/mcp-server.nix | `systemd.tmpfiles.rules` | `[` |
| modules/services/mcp-server.nix | `environment.etc` | `mkIf cfg.autoConfigureClaudeDesktop {` |
| modules/services/mcp-server.nix | `mode` | `"0644"` |
| modules/services/mcp-server.nix | `environment.shellAliases` | `{` |
| modules/services/mcp-server.nix | `mcp` | `"mcp-server"` |
| modules/services/mcp-server.nix | `mcp-status` | `"mcp-server status"` |
| modules/services/mcp-server.nix | `mcp-test` | `"mcp-server test"` |
| modules/services/mcp-server.nix | `environment.interactiveShellInit` | `''` |
| modules/network/dns-resolver.nix | `dnscryptPort` | `if cfg.enableDNSCrypt then "127.0.0.2:53" else "127.0.0.1:53"` |
| modules/network/dns-resolver.nix | `default` | `[` |
| modules/network/dns-resolver.nix | `default` | `true` |
| modules/network/dns-resolver.nix | `description` | `"Enable DNSSEC validation for enhanced security"` |
| modules/network/dns-resolver.nix | `default` | `false` |
| modules/network/dns-resolver.nix | `description` | `"Enable DNSCrypt for encrypted DNS queries"` |
| modules/network/dns-resolver.nix | `default` | `3600` |
| modules/network/dns-resolver.nix | `assertions` | `[` |
| modules/network/dns-resolver.nix | `assertion` | `!(cfg.enableDNSCrypt && vpnEnabled)` |
| modules/network/dns-resolver.nix | `message` | `''` |
| modules/network/dns-resolver.nix | `services.resolved` | `{` |
| modules/network/dns-resolver.nix | `enable` | `true` |
| modules/network/dns-resolver.nix | `dnssec` | `if cfg.enableDNSSEC then "true" else "false"` |
| modules/network/dns-resolver.nix | `dnsovertls` | `"opportunistic"` |
| modules/network/dns-resolver.nix | `extraConfig` | `''` |
| modules/network/dns-resolver.nix | `DNSStubListener` | `yes` |
| modules/network/dns-resolver.nix | `DNSStubListenerExtra` | `127.0.0.1:5353` |
| modules/network/dns-resolver.nix | `Cache` | `yes` |
| modules/network/dns-resolver.nix | `CacheFromLocalhost` | `yes` |
| modules/network/dns-resolver.nix | `ReadEtcHosts` | `yes` |
| modules/network/dns-resolver.nix | `MulticastDNS` | `yes` |
| modules/network/dns-resolver.nix | `LLMNR` | `yes` |
| modules/network/dns-resolver.nix | `services.dnscrypt-proxy2` | `mkIf cfg.enableDNSCrypt {` |
| modules/network/dns-resolver.nix | `enable` | `true` |
| modules/network/dns-resolver.nix | `settings` | `{` |
| modules/network/dns-resolver.nix | `listen_addresses` | `[ "127.0.0.2:53" ]` |
| modules/network/dns-resolver.nix | `server_names` | `[` |
| modules/network/dns-resolver.nix | `ipv4_servers` | `true` |
| modules/network/dns-resolver.nix | `ipv6_servers` | `true` |
| modules/network/dns-resolver.nix | `dnscrypt_servers` | `true` |
| modules/network/dns-resolver.nix | `doh_servers` | `true` |
| modules/network/dns-resolver.nix | `require_dnssec` | `cfg.enableDNSSEC` |
| modules/network/dns-resolver.nix | `require_nolog` | `true` |
| modules/network/dns-resolver.nix | `require_nofilter` | `true` |
| modules/network/dns-resolver.nix | `timeout` | `5000` |
| modules/network/dns-resolver.nix | `keepalive` | `30` |
| modules/network/dns-resolver.nix | `cache` | `true` |
| modules/network/dns-resolver.nix | `cache_size` | `4096` |
| modules/network/dns-resolver.nix | `cache_min_ttl` | `2400` |
| modules/network/dns-resolver.nix | `cache_max_ttl` | `cfg.cacheTTL` |
| modules/network/dns-resolver.nix | `cache_neg_ttl` | `60` |
| modules/network/dns-resolver.nix | `fallback_resolvers` | `cfg.preferredServers` |
| modules/network/dns-resolver.nix | `networking` | `{` |
| modules/network/dns-resolver.nix | `firewall.allowedUDPPorts` | `mkIf cfg.enableDNSCrypt [ 53 ]` |
| modules/network/dns-resolver.nix | `dhcpcd.extraConfig` | `''` |
| modules/network/dns-resolver.nix | `systemd.services.systemd-resolved` | `{` |
| modules/network/dns-resolver.nix | `serviceConfig` | `{` |
| modules/network/dns-resolver.nix | `PrivateTmp` | `true` |
| modules/network/dns-resolver.nix | `ProtectSystem` | `"strict"` |
| modules/network/dns-resolver.nix | `ProtectHome` | `true` |
| modules/network/dns-resolver.nix | `NoNewPrivileges` | `true` |
| modules/network/dns-resolver.nix | `ProtectKernelTunables` | `true` |
| modules/network/dns-resolver.nix | `ProtectKernelModules` | `true` |
| modules/network/dns-resolver.nix | `ProtectControlGroups` | `true` |
| modules/network/dns-resolver.nix | `RestrictAddressFamilies` | `"AF_UNIX AF_INET AF_INET6 AF_NETLINK"` |
| modules/network/dns-resolver.nix | `RestrictNamespaces` | `true` |
| modules/network/dns-resolver.nix | `RestrictRealtime` | `true` |
| modules/network/dns-resolver.nix | `RestrictSUIDSGID` | `true` |
| modules/network/dns-resolver.nix | `SystemCallFilter` | `"@system-service @network-io"` |
| modules/network/dns-resolver.nix | `SystemCallErrorNumber` | `"EPERM"` |
| modules/network/dns-resolver.nix | `environment.shellAliases` | `{` |
| modules/network/dns-resolver.nix | `dns-flush` | `"sudo systemctl restart systemd-resolved"` |
| modules/network/dns-resolver.nix | `dns-diag` | `"/etc/dns-diagnostics.sh"` |
| modules/network/dns-resolver.nix | `mode` | `"0755"` |
| modules/network/dns-resolver.nix | `text` | `''` |
| modules/network/dns-resolver.nix | `echo "` | `=================================="` |
| modules/network/dns-resolver.nix | `echo "` | `=================================="` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `EP_B` | `(^MC.EPBR << 0x0C)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((MH_B` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MH_B` | `(^MC.MHBR << 0x0F)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PC_B` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PC_B` | `(^MC.PXBR << 0x1A)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GPCB ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `((Arg0 & 0x001F0000) >> One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `((Arg0 & 0x07) << 0x0C)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PC_L` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PC_L` | `(0x10000000 >> ^MC.PXSZ) /* \_SB_.PC00.MC__.PXSZ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PC_L` | `0x10000000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DM_B` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DM_B` | `(^MC.DIBR << 0x0C)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GPCL ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PBMX` | `((Local0 >> 0x14) - 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PBLN` | `((Local0 >> 0x14) - One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && (PBMX > 0xE0)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PBMX` | `0xE0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PBLN` | `0xE1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `C0LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM1L` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `C0RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `C4LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM1H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `C4RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `C8LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM2L` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `C8RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CCLN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM2H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CCRW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `D0LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM3L` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `D0RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `D4LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM3H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `D4RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `D8LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM4L` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `D8RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCLN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM4H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCRW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `E0LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM5L` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `E0RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `E4LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM5H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `E4RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `E8LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM6L` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `E8RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECLN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM6H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECRW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `F0LN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^MC.PM0H` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `F0RW` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `M1LN` | `M32L /* External reference */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `M1MN` | `M32B /* External reference */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `M1MX` | `((M1MN + M1LN) - One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((M64L` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MSLN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `M2LN` | `M64L /* External reference */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `M2MN` | `M64B /* External reference */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `M2MX` | `((M2MN + M2LN) - One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Arg3` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= GUID))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SUPP` | `CDW2 /* \_SB_.PC00._OSC.CDW2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CTRL` | `CDW3 /* \_SB_.PC00._OSC.CDW3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CTRL &` | `0xFFFFFFF8` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CTRL &` | `0xFFFFFFF7` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCC` | `CTRL /* \_SB_.PC00.CTRL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CDW1 |` | `0x08` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CDW3 !` | `CTRL))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CDW1 |` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CDW3` | `CTRL /* \_SB_.PC00.CTRL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCC` | `CTRL /* \_SB_.PC00.CTRL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CDW1 |` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x00060000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CPRA ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x00010000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CPRA ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x00010001` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CPRA ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((MPGN >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x00010002` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CPRA ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STAS` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TOUT /` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 +` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1 >` | `TOUT))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Y` | `((Local6 * 0x64) + Local5)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TZ` | `0x07FF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DL` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `V` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TOUT /` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 +` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1 >` | `TOUT))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((ACWA` | `= 0xFFFFFFFF) && (One & WTTR)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WTTR ^` | `One /* \_SB_.AWAC.WTTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((DCWA` | `= 0xFFFFFFFF) && (0x02 & WTTR)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WTTR ^` | `0x02 /* \_SB_.AWAC.WTTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WAST` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ACET` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCET` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ACWA` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WTTR |` | `One /* \_SB_.AWAC.WTTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCWA` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WTTR |` | `0x02 /* \_SB_.AWAC.WTTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 & 0xFF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x09` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `0x2710` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MDG0` | `MBUF /* \MBUF */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 >> 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 &` | `0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 &` | `0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 >> 0x10)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 &` | `0xFFFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 &` | `0xFFFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `SizeOf (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUFS` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MDG0` | `MBUF /* \MBUF */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LCR` | `0x83` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TXBF` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DLM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FCR` | `0xE1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LCR` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DLM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `SizeOf (Local3)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local5` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TXBF` | `0x0D` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TXBF` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2LC` | `0x83` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2TX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2DH` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2FC` | `0xE1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2LC` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2DH` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `SizeOf (Local3)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local5` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2TX` | `0x0D` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `U2TX` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `SizeOf (Local1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUFS` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MDG0` | `MBUF /* \MBUF */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `BUFN /* \BUFN */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 &` | `0x0F` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 &` | `0x0F` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MBUF [BUFN]` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUFN +` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUFN &` | `0x0FFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2 <<` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `(0x1000 - Local2)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MBUF [Local3]` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUFN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local5` | `(0x1000 - Local4)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MBUF [BUFN]` | `DerefOf (MBUF [Local4])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(Arg0 & 0x0F)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `0x30` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `0x37` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= PCIG))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x09))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= PCIG))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD1` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD2` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD3` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD4` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD5` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD6` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAD7` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CUPN` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAQ0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((CUPN` | `= 0x07))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAR0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((CUPN` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAS0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((CUPN` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAT0` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CUPN` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAQ1` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((CUPN` | `= 0x07))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAR1` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((CUPN` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAS1` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((CUPN` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAT1` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NUMI` | `INUM (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LEVI` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ACTI` | `Arg2` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SIME` | `= One) || !IMPS ()))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA0` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA1` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA1` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA2` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA3` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA3` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB0` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB1` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB1` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB2` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB3` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB3` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC0` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC1` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC1` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC2` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC3` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC3` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD0` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD1` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD1` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD2` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD3` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD3` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE0` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE1` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE1` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE2` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE3` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE3` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0 >` | `0x2710))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SIME` | `= One) || !IMPS ()))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA0` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA1` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA2` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RAA3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APA3` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB0` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB1` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB2` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPB3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APB3` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC0` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC1` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC2` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPC3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APC3` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD0` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD1` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD2` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPD3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APD3` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE0` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE1` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE2` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPE3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((APE3` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0 >` | `0x2710))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SIME` | `= One) || !IMPS ()))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSAT` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((ASAT` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RGBE` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AGBE` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RXHC` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AXHC` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RXDC` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AXDC` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RUFS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AUFS` | `= Zero) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0 >` | `0x2710))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SIME` | `= One) || !IMPS ()))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSAT` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((ASAT` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RGBE` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AGBE` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RXHC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AXHC` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RXDC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AXDC` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RUFS` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((AUFS` | `= One) && (Local0 < 0x2710)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0 >` | `0x2710))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0xFE200000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(0x40 * (CNPM * (Arg0 - FMSN)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(0x40 * Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `DerefOf (Local3 [(Arg1 + Local1)])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(Local2 << (0x08 * Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PTHM` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((PTHM` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((PTHM` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `SizeOf (Local2)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `THDA (THMN, THCN)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DO10` | `0x01000242` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WO00` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local6` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local7` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((Local7 >` | `0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `QO00` | `STRD (Local2, Local6, 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local6 +` | `0x08` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local7 -` | `0x08` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local7 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DO00` | `STRD (Local2, Local6, 0x04)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local6 +` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local7 -` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local7 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WO00` | `STRD (Local2, Local6, 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local6 +` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local7 -` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local7 >` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BO00` | `STRD (Local2, Local6, One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local6 +` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local7 -` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DO30` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HDAA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DISA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CIWF` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CIBT` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMIN` | `PMBS /* \PMBS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMAX` | `PMBS /* \PMBS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BAS0` | `SBRG /* \SBRG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCHS` | `= PCHH) || (PCHS == 0x04)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BAS1` | `(SBRG + 0x006C0000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LEN1` | `0x00010000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BAS2` | `(SBRG + 0x006B0000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LEN2` | `0x00020000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BAS3` | `(SBRG + 0x006F0000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PCHS` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LEN3` | `((SBRG + 0x10000000) - BAS3)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LEN3` | `((SBRG + 0x01000000) - BAS3)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ITS0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMI0` | `ITA0 /* \ITA0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMA0` | `ITA0 /* \ITA0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `BUF0 /* \_SB_.IOTR._CRS.BUF0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ITS1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMI1` | `ITA1 /* \ITA1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMA1` | `ITA1 /* \ITA1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `BUF1 /* \_SB_.IOTR._CRS.BUF1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ITS2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMI2` | `ITA2 /* \ITA2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMA2` | `ITA2 /* \ITA2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `BUF2 /* \_SB_.IOTR._CRS.BUF2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ITS3` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMI3` | `ITA3 /* \ITA3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AMA3` | `ITA3 /* \ITA3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `BUF3 /* \_SB_.IOTR._CRS.BUF3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TMOV` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TMOV` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [Zero]` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IWB0` | `Arg3` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IWB1` | `Arg4` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IWB2` | `Arg5` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IWB3` | `Arg6` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(Arg0 << Zero)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(Arg1 << 0x0C)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(Arg2 << 0x10)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CMDR` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `TMOV /* \TMOV */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((!IBSY || (IERR` | `= One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [Zero]` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IERR` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [Zero]` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [One]` | `IRB0 /* \IRB0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [0x02]` | `IRB1 /* \IRB1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [0x03]` | `IRB2 /* \IRB2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPKG [0x04]` | `IRB3 /* \IRB3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRU` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CECE` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CECE` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CPPM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CPPM` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PCHS` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GBES !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PMES` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((USW4` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PMES` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("7c9512a9-1705-4cb4-af7d-506a2423ab71") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((One <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x02 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x03 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x04 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x05 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x06 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x07 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x08 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x09 <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x0A <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x0B <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x0C <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x0D <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x0E <` | `PU2C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((One <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x02 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x03 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x04 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x05 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x06 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x07 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x08 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x09 <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((0x0A <` | `PU3C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("732b85d5-b7a7-4a1b-9ba0-4bbd00ffd511") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UXPE` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PUPS` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((U2CP` | `= Zero) && (U3CP == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U2CP !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U3CP !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U2CP !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U3CP !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PUPS` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((U2CP` | `= 0x03) && (U3CP == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U2CP !` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U3CP !` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UXPE` | `Local2` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `DerefOf (Arg3 [Zero])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `P2PS /* \_SB_.PC00.XDCI._DSM.P2PS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(PPDS & 0xFFF80000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 >>` | `0x13` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("PCH XDCI: Func9 Return Val` | `", ToHexString (Local1)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PMES` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PMES` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NBAS` | `NHLA /* \NHLA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NMAS` | `(NHLA + (NHLL - One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NLEN` | `NHLL /* \NHLL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("a69f886e-6ceb-4594-a41f-7b5dce24c553") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= 0x016E3600))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x016E3600` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `0x005B8D80` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `0x7D` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((Arg1` | `= 0x0249F000))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x0249F000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `0x00493E00` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `0x32` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((Arg1` | `= 0x0124F800))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x0124F800` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `0x00493E00` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `0x32` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `) [One]) [Zero]` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UAOE !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("2e60aefc-1ba8-467a-b8cc-5727b98cecb7") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMEC` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMEC |` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BAR0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR0` | `(BAR0 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR1` | `(BAR1 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM00` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM00` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM00` | `= One) || (IM00 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM01` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM01` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM01` | `= One) || (IM01 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM02` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM02` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM02` | `= One) || (IM02 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM03` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM03` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM03` | `= One) || (IM03 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM04` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM04` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM04` | `= One) || (IM04 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM05` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM05` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM05` | `= One) || (IM05 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM06` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM06` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM06` | `= One) || (IM06 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM07` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IM07` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((IM07` | `= One) || (IM07 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR0` | `(BAR0 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR1` | `(BAR1 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM00` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM00` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM00` | `= One) || (SM00 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM01` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM01` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM01` | `= One) || (SM01 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM02` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM02` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM02` | `= One) || (SM02 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM03` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM03` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM03` | `= One) || (SM03 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM04` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM04` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM04` | `= One) || (SM04 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM05` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM05` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM05` | `= One) || (SM05 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM06` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SM06` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((SM06` | `= One) || (SM06 == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("f7af8347-a966-49fe-9022-7a9deeebdb27") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg0` | `= 0x02) || (Arg0 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(BAR0 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR1` | `(Local1 + 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR2` | `(BAR1 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(BAR0 & 0xFFFFFFFFFFFFF000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADR0` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IRQN` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 !` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `LCR /* \_SB_.UAPG.LCR_ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PPRR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMEC` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMEC |` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMEC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMEC |` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PPRR` | `0x07` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `UARB (UM00, UC00)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM00` | `= 0x02) || (UM00 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM00` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP00` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP00` | `UAPG (UM00, UP00, UC00)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM00` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM01` | `= 0x02) || (UM01 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM01` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP01` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP01` | `UAPG (UM01, UP01, UC01)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM01` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM02` | `= 0x02) || (UM02 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM02` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP02` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP02` | `UAPG (UM02, UP02, UC02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM02` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM03` | `= 0x02) || (UM03 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM03` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP03` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP03` | `UAPG (UM03, UP03, UC03)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM03` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM04` | `= 0x02) || (UM04 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM04` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP04` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP04` | `UAPG (UM04, UP04, UC04)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM04` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM05` | `= 0x02) || (UM05 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM05` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP05` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP05` | `UAPG (UM05, UP05, UC05)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM05` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((UM06` | `= 0x02) || (UM06 == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM06` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UP06` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UP06` | `UAPG (UM06, UP06, UC06)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UM06` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GPHD` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `INTL` | `SGIR /* \SGIR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CML0` | `(SBRG + 0x006E0000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CML1` | `(SBRG + 0x006D0000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CML4` | `(SBRG + 0x006A0000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CML5` | `(SBRG + 0x00690000)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GPHD` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(GINF (Arg0, Zero) + SBRG)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GINF (Arg0, Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `((Arg0 & 0x00FF0000) >> 0x10)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(Local1 >> 0x05)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (!((((GEI0` | `= Local0) && (GED0 == Local2)) | (` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `(GEI1` | `= Local0) && (GED1 == Local2))) | ((GEI2 == Local0) && (GED2 ==` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((GEI0` | `= Local0) && (GED0 == Local2)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((GEI1` | `= Local0) && (GED1 == Local2)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((GEI2` | `= Local0) && (GED2 == Local2)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `((GADR (Local0, 0x02) + (Local1 * 0x10)) +` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `((GADR (Local0, 0x02) + (Local1 * 0x10)) +` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `(GADR (Local0, 0x03) + ((Local1 >> 0x05) * 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `(Local1 & 0x1F)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `(GADR (Local0, 0x03) + ((Local1 >> 0x05) * 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `(Local1 & 0x1F)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP |` | `(One << Local4)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP &` | `~(One << Local4)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x04) + ((Local1 >> 0x03) * 0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `((GADR (Local0, 0x02) + (Local1 * 0x10)) +` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `(Local1 >> 0x05)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (!((((GEI0` | `= Local0) && (GED0 == Local4)) | (` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `(GEI1` | `= Local0) && (GED1 == Local4))) | ((GEI2 == Local0) && (GED2 ==` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `GADR (Local0, 0x05)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Local3 & 0xFFFF) !` | `0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(One << (Local1 % 0x20))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STSX` | `Local2` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local4` | `(Local1 >> 0x05)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (!!((((GEI0` | `= Local0) && (GED0 == Local4)) |` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `((GEI1` | `= Local0) && (GED1 == Local4))) | ((GEI2 == Local0) && (` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `GED2` | `= Local4))))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((GADR (Local0, 0x05) & 0xFFFF)` | `= 0xFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x05) + (Local4 * 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `(Local1 & 0x1F)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RCFG !` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (RXEV [Local0]) [Local1]` | `RCFG /* \_SB_.DIPI.RCFG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RCFG` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RDIS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `DerefOf (DerefOf (RXEV [Local0]) [Local1])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local3 !` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RDIS` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RCFG` | `Local3` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(GADR (Local0, 0x02) + (Local1 * 0x10))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RCFG` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `GADR (Local0, 0x06)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GGRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `GNMB (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `GADR (Local0, 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UF0E` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PGEN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSTA &` | `0xFFFFFFFC` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `PSTA /* \_SB_.PC00.PUF0.PSTA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PGEN` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((UF1E` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PGEN` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSTA &` | `0xFFFFFFFC` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TEMP` | `PSTA /* \_SB_.PC00.PUF1.PSTA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PGEN` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PMES` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `PCRR (PCNV, 0x8100)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Local0 & 0x7F)` | `= 0x4C))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((^CNVW.VDID !` | `0xFFFFFFFF) || (CRFP == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GBTP () !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GBTP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GBTP () !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `GBTP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CBTA` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CNIP ()` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AODS [0x02]` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `AODS [0x02]` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCHS` | `= 0x05) || (PCHS == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((PCHS` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCHS` | `= 0x02) || ((PCHS == 0x05) || (PCHS == 0x03))))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((PCHS` | `= One) || (PCHS == 0x04)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Acquire (CNMT, 0x03E8)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRRS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CondRefOf (\_SB.PC00.CNVW.RSTT) && (RSTT` | `= One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PCHS` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PLRB` | `0x44` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PLRB` | `0x80` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCRR (PCNV, PLRB) & 0x02)` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GBTR ()` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `PCRR (PCNV, PLRB)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((((Local1 & 0x02)` | `= Zero) && (Local1 & 0x04)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRRS` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRRS` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRRS` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WFLR` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `WIFR` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCHS` | `= 0x05) || (PCHS == 0x03)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA1 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR1 /* \LTR1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML1 /* \PML1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL1 /* \PNL1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & One) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA2 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR2 /* \LTR2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML2 /* \PML2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL2 /* \PNL2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x02) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR3 /* \LTR3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML3 /* \PML3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL3 /* \PNL3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x04) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA4 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR4 /* \LTR4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML4 /* \PML4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL4 /* \PNL4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x08) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA5 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR5 /* \LTR5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML5 /* \PML5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL5 /* \PNL5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x10) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA6 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR6 /* \LTR6 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML6 /* \PML6 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL6 /* \PNL6 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x20) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA7 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR7 /* \LTR7 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML7 /* \PML7 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL7 /* \PNL7 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x40) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA8 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR8 /* \LTR8 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML8 /* \PML8 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL8 /* \PNL8 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR1 & 0x80) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPA9 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTR9 /* \LTR9 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PML9 /* \PML9 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNL9 /* \PNL9 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & One) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAA !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRA /* \LTRA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLA /* \PMLA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLA /* \PNLA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x02) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAB !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRB /* \LTRB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLB /* \PMLB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLB /* \PNLB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x04) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAC !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRC /* \LTRC */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLC /* \PMLC */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLC /* \PNLC */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x08) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAD !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRD /* \LTRD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLD /* \PMLD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLD /* \PNLD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x10) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAE !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRE /* \LTRE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLE /* \PMLE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLE /* \PNLE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x20) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAF !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRF /* \LTRF */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLF /* \PMLF */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLF /* \PNLF */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x40) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAG !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRG /* \LTRG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLG /* \PMLG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLG /* \PNLG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR2 & 0x80) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAH !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRH /* \LTRH */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLH /* \PMLH */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLH /* \PNLH */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & One) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAI !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRI /* \LTRI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLI /* \PMLI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLI /* \PNLI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x02) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAJ !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRJ /* \LTRJ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLJ /* \PMLJ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLJ /* \PNLJ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x04) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAK !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRK /* \LTRK */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLK /* \PMLK */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLK /* \PNLK */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x08) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAL !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRL /* \LTRL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLL /* \PMLL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLL /* \PNLL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x10) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAM !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRM /* \LTRM */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLM /* \PMLM */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLM /* \PNLM */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x20) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRN /* \LTRN */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLN /* \PMLN */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLN /* \PNLN */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x40) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAO !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRO /* \LTRO */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLO /* \PMLO */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLO /* \PNLO */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR3 & 0x80) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PCHS` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAP !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRP /* \LTRP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLP /* \PMLP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLP /* \PNLP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR4 & One) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAQ !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRQ /* \LTRQ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLQ /* \PMLQ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLQ /* \PNLQ */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR4 & 0x02) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAR !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRR /* \LTRR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLR /* \PMLR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLR /* \PNLR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR4 & 0x04) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RPAS !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTEN` | `LTRS /* \LTRS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LMSL` | `PMLS /* \PMLS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LNSL` | `PNLS /* \PNLS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBCS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VMDE` | `= One) && ((VMR4 & 0x08) != Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRMV` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRMV` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RD3C` | `STD3 /* \STD3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SIPV` | `GSIP ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((NCB7 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((SCB0 !` | `One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23R` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L23E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `NCB7` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SCB0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("e5c937d0-3553-4d7a-9117-ea4d19c3434d") /* Device Labeling Interface */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN0` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((LTEN !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN6` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN8` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUN9` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNA` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FUNB` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [Zero]` | `((LMSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [One]` | `(LMSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x02]` | `((LNSL >> 0x0A) & 0x07)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LTRV [0x03]` | `(LNSL & 0x03FF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((ECR1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1 >` | `0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((SCCX` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PIXX` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DVID` | `= 0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BCCX` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((VDID !` | `0xFFFFFFFF) && (PMSX == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PMSX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PSPX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PCHS` | `= PCHP))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((PCHS` | `= PCHN))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg0 < NCLK ()) && (PCHS` | `= PCHP)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK0 /* \_SB_.ICLK.CLK0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK0` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK1 /* \_SB_.ICLK.CLK1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK1` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK2 /* \_SB_.ICLK.CLK2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK2` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK3 /* \_SB_.ICLK.CLK3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK3` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK4 /* \_SB_.ICLK.CLK4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK4` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK5 /* \_SB_.ICLK.CLK5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK5` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((Arg0 < NCLK ()) && (PCHS` | `= PCHN)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK0 /* \_SB_.ICLK.CLK0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK0` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK1 /* \_SB_.ICLK.CLK1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK1` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK2 /* \_SB_.ICLK.CLK2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK2` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK3 /* \_SB_.ICLK.CLK3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK3` | `((Local0 & 0xFFFFFFFFFFFFFFFD) | (Arg1 << One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg0 < NCLK ()) && (PCHS` | `= PCHP)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK0 /* \_SB_.ICLK.CLK0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK0` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK1 /* \_SB_.ICLK.CLK1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK1` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK2 /* \_SB_.ICLK.CLK2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK2` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK3 /* \_SB_.ICLK.CLK3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK3` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK4 /* \_SB_.ICLK.CLK4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK4` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK5 /* \_SB_.ICLK.CLK5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK5` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((Arg0 < NCLK ()) && (PCHS` | `= PCHN)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK0 /* \_SB_.ICLK.CLK0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK0` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK1 /* \_SB_.ICLK.CLK1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK1` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK2 /* \_SB_.ICLK.CLK2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK2` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `CLK3 /* \_SB_.ICLK.CLK3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLK3` | `((Local0 & 0xFFFFFFFFFFFFFFFE) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(One << Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg1 << Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRPI` | `CTRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(One << PRPI) /* \MCUI.PRPI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `(Arg1 << PRPI) /* \MCUI.PRPI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(One << PRPI) /* \MCUI.PRPI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3` | `(Arg1 << PRPI) /* \MCUI.PRPI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2 <<` | `0x18` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local3 <<` | `0x18` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Local0` | `", Local0))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Local1` | `", Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Local2` | `", Local2))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Local3` | `", Local3))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IPCC !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLKU` | `CTRP (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 + One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 -` | `0x07` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 + 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 + One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 -` | `0x07` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg0 + 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((IPCC !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HPRI` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(One << HPRI) /* \HBCM.HPRI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg1 << HPRI) /* \HBCM.HPRI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Port number of Hybrid Partner` | `", HPRI))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Local0 of Hybrid Partner` | `", Local0))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Local1 of Hybrid Partner` | `", Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCHS` | `= PCHP) || (PCHS == PCHN)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ISAT` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ISAT` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((PCHS` | `= PCHP) || (PCHS == PCHN)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STD3 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `INT1` | `GNUM (Arg0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TMD0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("6e2ac436-0fcf-41af-a265-b32a220dcfab") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `ToBuffer (T070)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUF4 [Zero]` | `DerefOf (Local0 [Zero])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `ToBuffer (T080)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUF5 [Zero]` | `DerefOf (Local1 [Zero])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("300d35b7-ac20-413e-8e9c-92e4dafd0afe") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("84005682-5b71-41a4-8d66-8130f787a138") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TIN0 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TIN0 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TMD0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((RSTL` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSTL` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSTL` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VDID !` | `0xFFFFFFFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TMD1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("6e2ac436-0fcf-41af-a265-b32a220dcfab") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `ToBuffer (T071)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUF4 [Zero]` | `DerefOf (Local0 [Zero])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `ToBuffer (T081)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BUF5 [Zero]` | `DerefOf (Local1 [Zero])` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("300d35b7-ac20-413e-8e9c-92e4dafd0afe") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("84005682-5b71-41a4-8d66-8130f787a138") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TIN1 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TIN1 !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TMD1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((RSTL` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSTL` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSTL` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg1 & 0xFFFF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `((Arg1 & 0x000F0000) << 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `((Arg0 << 0x10) + Local1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `((Local2 + Local0) + SBRG) /* \SBRG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg1 & 0xFFFF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `((Arg1 & 0x000F0000) << 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `((Arg0 << 0x10) + Local1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `((Local2 + Local0) + SBRG) /* \SBRG */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DAT0` | `Arg2` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `PCRR (Arg0, Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Local0 | Arg2)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `PCRR (Arg0, Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Local0 & Arg2)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `PCRR (Arg0, Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `((Local0 & Arg2) | Arg3)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PTHM` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BTTH` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PTHM` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BHTH` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HPT0` | `HPTB /* \HPTB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PCHS` | `= PCHH))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((STAS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((CPID & 0x0FFF0FF0)` | `= 0x000B0670))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((CPID & 0x0FFF0FF0)` | `= 0x000B06F0))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((CPID & 0x0FFF0FF0)` | `= 0x000B06A0))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OMIN` | `(PMBS + 0x54)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OMAX` | `(PMBS + 0x54)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0x6E` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECOK` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECOK` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PTPS` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TOHP` | `TPDS /* \_SB_.TPDS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TPRD` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CPLE` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECME` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `EDTA` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((ECTM & 0x08)` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LIDS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^GFX0.CLID` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((BPXE` | `= 0x45))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LIDS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^GFX0.CLID` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LIDS` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^GFX0.CLID` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LIDS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^GFX0.CLID` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q02, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q05, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TPDS` | `TOHP /* \_SB_.PC00.LPCB.EC0_.TOHP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q06, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TPDS` | `TOHP /* \_SB_.PC00.LPCB.EC0_.TOHP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q12, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q20, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `SMAA /* \_SB_.PC00.LPCB.EC0_.SMAA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0` | `= 0x14))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^^BAT1.RCAP` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BATO` | `BATD /* \_SB_.PC00.LPCB.EC0_.BATD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SMST &` | `0xBF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q29, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q57, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q58, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q5B, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q62, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q80, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q81, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q85, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q8E, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DPLM` | `= One)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q8F, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DPLM` | `= One)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q9B, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q9C, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q9D, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_Q9E, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QC0, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QC5, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QC6, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QC8, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DGPV` | `= 0x10DE))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VRDY` | `= 0xAA))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DGDX !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Local0 = DGDX /* \_SB_.PC00.LPCB.EC0_.DGDX */ + 0xD0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QC9, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DGPV` | `= 0x10DE))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VRDY` | `= 0xAA))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DGDX !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Local0 = DGDX /* \_SB_.PC00.LPCB.EC0_.DGDX */ + 0xD0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QCA, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QD2, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QE5, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QE6, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BCUS` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QE7, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BCUS` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QF0, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QF1, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_QFA, 0, NotSerialized)  // _Qxx: EC Query, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BATN` | `BATD /* \_SB_.PC00.LPCB.EC0_.BATD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(BATN & One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(BATO & One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x0100` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV &` | `0xFEFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (~(Local0` | `= Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x40` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(BATN & 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(BATO & 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x0200` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV &` | `0xFDFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (~(Local0` | `= Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x80` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(BATN & 0xC0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(BATO & 0xC0)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (~(Local0` | `= Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ECEV |` | `0x20` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^WMID.FEBC [Zero]` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^WMID.FEBC [One]` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^WMID.FEBC [0x02]` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^WMID.FEBC [0x03]` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TPVD` | `= 0x53))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((TPVD` | `= 0x45))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((TPID` | `= 0x11))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((TPID` | `= 0x12))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((TPID` | `= 0x21))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PTPS` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((KBID` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `P80T` | `((P80T & 0xFF00) | Arg1)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `P80T` | `((P80T & 0xFF) | (Arg1 << 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `P80B` | `P80T /* \P80T */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `GPIC` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PICM` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTRT` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TOFF` | `TVCF (Local0, Zero, 0x04, TOFF)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CWEF` | `CPWE /* \CPWE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((Arg0` | `= 0x04) || (Arg0 == 0x05))){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.FLS4` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.APS4` | `\_SB.PC00.LPCB.EC0.APBF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PPOE !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((\_SB.PC00.LPCB.EC0.WOWL` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.IETM.RDPF` | `\_SB.IDPF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.TPDS` | `\_SB.PC00.LPCB.EC0.TOHP` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg0` | `= 0x04) || (Arg0 == 0x05)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.TOHP` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((\_SB.KBID` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.OSS4` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((\_SB.WUSB` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.WUSB` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((\_SB.WRTC` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.WRTC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.APBF` | `\_SB.APS4` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.TDG4` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DSTS` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPWM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RPWM` | `0x0180` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Zero` | `= ACTT)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg0` | `= 0x03) || (Arg0 == 0x04)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.CPLE` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.EDTA` | `0x05` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.TOHP` | `\_SB.TPDS` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.FANT` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.FANT` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.FANT` | `0x03` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.PC00.LPCB.EC0.FANT` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.IDPF` | `\_SB.IETM.RDPF /* External reference */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(Arg0 * 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Arg1 * 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DPTF` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CSEM` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CSEM` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PLSV` | `PPL1 /* \PPL1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PLEN` | `PL1E /* \PL1E */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLMP` | `CLP1 /* \CLP1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PWRU` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PPUU` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PPUU` | `(PWRU-- << 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(PLVL * PPUU) /* \SPL1.PPUU */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(Local0 / 0x03E8)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PPL1` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PL1E` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLP1` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PPL1` | `PLSV /* \PLSV */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PL1E` | `PLEN /* \PLEN */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CLP1` | `CLMP /* \CLMP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CSEM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GLCK` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `GLCK` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.CPPC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GLCK` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `GLCK` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `UAMS` | `(Arg0 && !PWRS)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((OSYS` | `= 0x07DC))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `SMIF` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.TRPF` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `TBPE` | `TVCF (Local0, One, 0x04, TBPE)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x03E8` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DGBA !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((^PEG0.PEGP.NPCS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^NPCF.DBAC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^NPCF.AMAT` | `(M2DB * 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^NPCF.ATPP` | `(M2CP * 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^NPCF.ACBT` | `(M2CT * 0x08)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^NPCF.NVWM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x03E8` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `LINX` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07D1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07D1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07D2` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07D3` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07D6` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07D9` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07DC` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07DD` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSYS` | `0x07DF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DTFS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRWP [Zero]` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(SS1 << One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `(SS2 << 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `(SS3 << 0x03)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `(SS4 << 0x04)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PRWP [One]` | `Arg1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 >>` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U4SE` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IO72` | `0x37` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `IO73` | `Arg0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U4SE` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("DOCM: Enabled host router mask on platform` | `", ToHexString (CMSK)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `^PC00.TDM0.STCM (OSU4, U4CM)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1 !` | `0xFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("DOCM: Apply CM mode to iTBT0 successfully, CM mode` | `", Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCM` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("DOCM: Fail to apply CM mode to iTBT0, CM mode` | `", OSU4))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `^PC00.TDM1.STCM (OSU4, U4CM)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1 !` | `0xFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("DOCM: Apply CM mode to iTBT1 successfully, CM mode` | `", Local1))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCM` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("DOCM: Fail to apply CM mode to iTBT1, CM mode` | `", OSU4))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `DTCM (OSU4, U4CM)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1 !` | `0xFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("DOCM: Apply CM mode to dTBT successfully, CM mode` | `", ToHexString (Local1)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCM` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0` | `= 0xFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((U4CM & 0x70)` | `= 0x20))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("U4FN: _OSC STS` | `", ToHexString (Arg0)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("U4FN: _OSC CAP` | `", ToHexString (Arg1)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U4SE` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((U4CM & 0x07)` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCM` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DSCE` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCM` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSU4` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSU4` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((U4CM & 0x70)` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((OSU4` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg0 & One)` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `DOCM ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((OSU4` | `= One) && (Local1 == 0xFF)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf (((OSU4` | `= One) && (OSCM == Zero)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("0811b06e-4a27-44f9-8d60-3cbbc22e7b48") /* Platform-wide Capabilities */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCP` | `CAP0 /* \_SB_._OSC.CAP0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `OSCO` | `0x04` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((HGMD & 0x0F) !` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((RTD3` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CAP0 &` | `0xFFFFFFFB` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((U4FN (STS0, CAP0)` | `= 0xFF))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CAP0 &` | `0xFFFBFFFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 &` | `0xFFFFFF00` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((Arg0` | `= ToUUID ("23a0d13a-26ab-486c-9c5f-0ffa525a575a") /* USB4 Capabilities */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((OSCM` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `CTRL /* \_SB_._OSC.CTRL */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CTRL &` | `0x0F` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((EPTU` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `CTRL &` | `0x0B` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local1 !` | `CTRL))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 &` | `0xFFFFFF00` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x0A` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 &` | `0xFFFFFF00` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x06` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 &` | `0xFFFFFF00` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `STS0 |` | `0x06` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x17` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x18` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x14` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x18` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x10` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x1E` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x15` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x1E` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x11` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x12` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x11` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x12` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x11` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x12` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x11` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x15` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x11` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x15` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x13` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x13` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x13` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x13` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x15` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x17` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `0x14` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BADR` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0 !` | `ToUUID ("033771e0-1705-47b4-9535-d1bbe14d9a09") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((COEM` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2 <` | `0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((Arg2` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MBR0` | `GMHB ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DBR0` | `GDMB ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `EBR0` | `GEPB ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `XBR0` | `GPCB ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `XSZ0` | `GPCL ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HBAS` | `HPTB /* \HPTB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `HLEN` | `0x0400` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L73, 0, Serialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((AL6D` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L6D, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L69, 0, Serialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L61, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L01C +` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L62, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `GPEC` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L66, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L6F, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L72, 0, Serialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `\_SB.AWAC.WAST` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L11, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_L23, 0, NotSerialized)  // _Lxx: Level-Triggered GPE, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `\_SB.PC00.GPCB ()` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `((Arg1 & 0x001F0000) >> One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `((Arg1 & 0x07) << 0x0C)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 +` | `(SBUS << 0x14)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((VNID` | `= 0x8086))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WGAS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WGAS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((RSTY` | `= One) && (WGAS == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Acquire (CNMT, 0x03E8)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((FLRC` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `DCTR /* \_SB_.PC00.RP04.PXSX.DCTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `0x8000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCTR` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DPRS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BOFC` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BRMT` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((WVHO !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BTIE` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PDRC` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BOFC` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((BRMT` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((WVHO !` | `Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BTIE` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DPRS` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `DCTR /* \_SB_.PC00.RP04.PXSX.DCTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `0x8000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCTR` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DPRS` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `MSNL` | `DR01 /* \DR01 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L1C1` | `DR02 /* \DR02 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `L1C2` | `DR03 /* \DR03 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PTMR` | `DR04 /* \DR04 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (SPLX [One]) [Zero]` | `DOM1 /* \DOM1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (SPLX [One]) [One]` | `LIM1 /* \LIM1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (SPLX [One]) [0x02]` | `TIM1 /* \TIM1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WANX [One]) [Zero]` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WANX [One]) [One]` | `TRD0 /* \TRD0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WANX [One]) [0x02]` | `TRL0 /* \TRL0 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WANX [0x02]) [Zero]` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WANX [0x02]) [One]` | `TRD1 /* \TRD1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WANX [0x02]) [0x02]` | `TRL1 /* \TRL1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDX [One]) [Zero]` | `WDM1 /* \WDM1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDX [One]) [One]` | `CID1 /* \CID1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [One]` | `STXE /* \STXE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x02]` | `ST10 /* \ST10 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x03]` | `ST11 /* \ST11 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x04]` | `ST12 /* \ST12 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x05]` | `ST13 /* \ST13 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x06]` | `ST14 /* \ST14 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x07]` | `ST15 /* \ST15 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x08]` | `ST16 /* \ST16 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x09]` | `ST17 /* \ST17 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x0A]` | `ST18 /* \ST18 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x0B]` | `ST19 /* \ST19 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x0C]` | `ST50 /* \ST50 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x0D]` | `ST51 /* \ST51 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x0E]` | `ST52 /* \ST52 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x0F]` | `ST53 /* \ST53 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x10]` | `ST54 /* \ST54 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x11]` | `ST55 /* \ST55 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x12]` | `ST56 /* \ST56 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x13]` | `ST57 /* \ST57 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x14]` | `ST58 /* \ST58 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x15]` | `ST59 /* \ST59 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x16]` | `ST5A /* \ST5A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x17]` | `ST5B /* \ST5B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x18]` | `CD10 /* \CD10 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x19]` | `CD11 /* \CD11 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x1A]` | `CD12 /* \CD12 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x1B]` | `CD13 /* \CD13 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x1C]` | `CD14 /* \CD14 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x1D]` | `CD15 /* \CD15 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x1E]` | `CD16 /* \CD16 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x1F]` | `CD17 /* \CD17 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x20]` | `CD18 /* \CD18 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x21]` | `CD19 /* \CD19 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x22]` | `CD1A /* \CD1A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x23]` | `CD20 /* \CD20 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x24]` | `CD21 /* \CD21 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x25]` | `CD22 /* \CD22 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x26]` | `CD23 /* \CD23 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x27]` | `CD24 /* \CD24 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x28]` | `CD25 /* \CD25 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x29]` | `CD26 /* \CD26 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x2A]` | `CD27 /* \CD27 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x2B]` | `CD28 /* \CD28 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x2C]` | `CD29 /* \CD29 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WRDY [One]) [0x2D]` | `CD2A /* \CD2A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [One]` | `STDE /* \STDE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x02]` | `STRS /* \STRS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x03]` | `ST20 /* \ST20 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x04]` | `ST21 /* \ST21 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x05]` | `ST22 /* \ST22 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x06]` | `ST23 /* \ST23 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x07]` | `ST24 /* \ST24 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x08]` | `ST25 /* \ST25 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x09]` | `ST26 /* \ST26 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x0A]` | `ST27 /* \ST27 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x0B]` | `ST28 /* \ST28 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x0C]` | `ST29 /* \ST29 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x0D]` | `ST60 /* \ST60 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x0E]` | `ST61 /* \ST61 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x0F]` | `ST62 /* \ST62 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x10]` | `ST63 /* \ST63 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x11]` | `ST64 /* \ST64 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x12]` | `ST65 /* \ST65 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x13]` | `ST66 /* \ST66 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x14]` | `ST67 /* \ST67 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x15]` | `ST68 /* \ST68 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x16]` | `ST69 /* \ST69 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x17]` | `ST6A /* \ST6A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x18]` | `ST6B /* \ST6B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x19]` | `ST30 /* \ST30 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x1A]` | `ST31 /* \ST31 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x1B]` | `ST32 /* \ST32 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x1C]` | `ST33 /* \ST33 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x1D]` | `ST34 /* \ST34 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x1E]` | `ST35 /* \ST35 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x1F]` | `ST36 /* \ST36 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x20]` | `ST37 /* \ST37 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x21]` | `ST38 /* \ST38 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x22]` | `ST39 /* \ST39 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x23]` | `ST70 /* \ST70 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x24]` | `ST71 /* \ST71 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x25]` | `ST72 /* \ST72 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x26]` | `ST73 /* \ST73 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x27]` | `ST74 /* \ST74 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x28]` | `ST75 /* \ST75 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x29]` | `ST76 /* \ST76 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x2A]` | `ST77 /* \ST77 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x2B]` | `ST78 /* \ST78 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x2C]` | `ST79 /* \ST79 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x2D]` | `ST7A /* \ST7A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x2E]` | `ST7B /* \ST7B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x2F]` | `ST40 /* \ST40 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x30]` | `ST41 /* \ST41 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x31]` | `ST42 /* \ST42 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x32]` | `ST43 /* \ST43 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x33]` | `ST44 /* \ST44 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x34]` | `ST45 /* \ST45 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x35]` | `ST46 /* \ST46 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x36]` | `ST47 /* \ST47 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x37]` | `ST48 /* \ST48 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x38]` | `ST49 /* \ST49 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x39]` | `ST80 /* \ST80 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x3A]` | `ST81 /* \ST81 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x3B]` | `ST82 /* \ST82 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x3C]` | `ST83 /* \ST83 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x3D]` | `ST84 /* \ST84 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x3E]` | `ST85 /* \ST85 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x3F]` | `ST86 /* \ST86 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x40]` | `ST87 /* \ST87 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x41]` | `ST88 /* \ST88 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x42]` | `ST89 /* \ST89 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x43]` | `ST8A /* \ST8A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x44]` | `ST8B /* \ST8B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x45]` | `CD30 /* \CD30 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x46]` | `CD31 /* \CD31 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x47]` | `CD32 /* \CD32 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x48]` | `CD33 /* \CD33 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x49]` | `CD34 /* \CD34 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x4A]` | `CD35 /* \CD35 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x4B]` | `CD36 /* \CD36 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x4C]` | `CD37 /* \CD37 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x4D]` | `CD38 /* \CD38 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x4E]` | `CD39 /* \CD39 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x4F]` | `CD3A /* \CD3A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x50]` | `CD3B /* \CD3B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x51]` | `CD3C /* \CD3C */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x52]` | `CD3D /* \CD3D */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x53]` | `CD3E /* \CD3E */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x54]` | `CD3F /* \CD3F */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x55]` | `CD40 /* \CD40 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x56]` | `CD41 /* \CD41 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x57]` | `CD42 /* \CD42 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x58]` | `CD43 /* \CD43 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x59]` | `CD44 /* \CD44 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x5A]` | `CD45 /* \CD45 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x5B]` | `CD46 /* \CD46 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x5C]` | `CD47 /* \CD47 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x5D]` | `CD48 /* \CD48 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x5E]` | `CD49 /* \CD49 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x5F]` | `CD4A /* \CD4A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x60]` | `CD4B /* \CD4B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x61]` | `CD4C /* \CD4C */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x62]` | `CD4D /* \CD4D */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x63]` | `CD4E /* \CD4E */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x64]` | `CD4F /* \CD4F */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x65]` | `CD50 /* \CD50 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x66]` | `CD51 /* \CD51 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x67]` | `CD52 /* \CD52 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x68]` | `CD53 /* \CD53 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x69]` | `CD54 /* \CD54 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x6A]` | `CD55 /* \CD55 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x6B]` | `CD56 /* \CD56 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x6C]` | `CD57 /* \CD57 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x6D]` | `CD58 /* \CD58 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x6E]` | `CD59 /* \CD59 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x6F]` | `CD5A /* \CD5A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x70]` | `CD5B /* \CD5B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x71]` | `CD5C /* \CD5C */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x72]` | `CD5D /* \CD5D */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x73]` | `CD5E /* \CD5E */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x74]` | `CD5F /* \CD5F */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x75]` | `CD60 /* \CD60 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x76]` | `CD61 /* \CD61 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x77]` | `CD62 /* \CD62 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x78]` | `CD63 /* \CD63 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x79]` | `CD64 /* \CD64 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x7A]` | `CD65 /* \CD65 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x7B]` | `CD66 /* \CD66 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x7C]` | `CD67 /* \CD67 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x7D]` | `CD68 /* \CD68 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x7E]` | `CD69 /* \CD69 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x7F]` | `CD6A /* \CD6A */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x80]` | `CD6B /* \CD6B */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x81]` | `CD6C /* \CD6C */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x82]` | `CD6D /* \CD6D */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x83]` | `CD6E /* \CD6E */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x84]` | `CD6F /* \CD6F */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x85]` | `CD70 /* \CD70 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (EWRY [One]) [0x86]` | `CD71 /* \CD71 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [One]` | `SDGN /* \SDGN */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x02]` | `SD11 /* \SD11 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x03]` | `SD12 /* \SD12 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x04]` | `SD13 /* \SD13 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x05]` | `SD14 /* \SD14 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x06]` | `SD15 /* \SD15 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x07]` | `SD16 /* \SD16 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x08]` | `SD17 /* \SD17 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x09]` | `SD18 /* \SD18 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x0A]` | `SD19 /* \SD19 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x0B]` | `SD21 /* \SD21 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x0C]` | `SD22 /* \SD22 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x0D]` | `SD23 /* \SD23 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x0E]` | `SD24 /* \SD24 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x0F]` | `SD25 /* \SD25 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x10]` | `SD26 /* \SD26 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x11]` | `SD27 /* \SD27 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x12]` | `SD28 /* \SD28 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x13]` | `SD29 /* \SD29 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x14]` | `SD31 /* \SD31 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x15]` | `SD32 /* \SD32 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x16]` | `SD33 /* \SD33 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x17]` | `SD34 /* \SD34 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x18]` | `SD35 /* \SD35 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x19]` | `SD36 /* \SD36 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x1A]` | `SD37 /* \SD37 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x1B]` | `SD38 /* \SD38 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x1C]` | `SD39 /* \SD39 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x1D]` | `SD41 /* \SD41 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x1E]` | `SD42 /* \SD42 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x1F]` | `SD43 /* \SD43 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x20]` | `SD44 /* \SD44 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x21]` | `SD45 /* \SD45 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x22]` | `SD46 /* \SD46 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x23]` | `SD47 /* \SD47 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x24]` | `SD48 /* \SD48 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x25]` | `SD49 /* \SD49 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x26]` | `SD51 /* \SD51 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x27]` | `SD52 /* \SD52 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x28]` | `SD53 /* \SD53 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x29]` | `SD54 /* \SD54 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x2A]` | `SD55 /* \SD55 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x2B]` | `SD56 /* \SD56 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x2C]` | `SD57 /* \SD57 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x2D]` | `SD58 /* \SD58 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x2E]` | `SD59 /* \SD59 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x2F]` | `SD61 /* \SD61 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x30]` | `SD62 /* \SD62 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x31]` | `SD63 /* \SD63 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x32]` | `SD64 /* \SD64 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x33]` | `SD65 /* \SD65 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x34]` | `SD66 /* \SD66 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x35]` | `SD67 /* \SD67 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x36]` | `SD68 /* \SD68 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x37]` | `SD69 /* \SD69 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x38]` | `SD71 /* \SD71 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x39]` | `SD72 /* \SD72 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x3A]` | `SD73 /* \SD73 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x3B]` | `SD74 /* \SD74 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x3C]` | `SD75 /* \SD75 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x3D]` | `SD76 /* \SD76 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x3E]` | `SD77 /* \SD77 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x3F]` | `SD78 /* \SD78 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x40]` | `SD79 /* \SD79 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x41]` | `SD81 /* \SD81 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x42]` | `SD82 /* \SD82 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x43]` | `SD83 /* \SD83 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x44]` | `SD84 /* \SD84 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x45]` | `SD85 /* \SD85 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x46]` | `SD86 /* \SD86 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x47]` | `SD87 /* \SD87 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x48]` | `SD88 /* \SD88 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WGDY [One]) [0x49]` | `SD89 /* \SD89 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (ECKY [One]) [One]` | `CECV /* \CECV */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [One]` | `WAGE /* \WAGE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x02]` | `AGA1 /* \AGA1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x03]` | `AGA2 /* \AGA2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x04]` | `AGA3 /* \AGA3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x05]` | `AGA4 /* \AGA4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x06]` | `AGA5 /* \AGA5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x07]` | `AGA6 /* \AGA6 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x08]` | `AGA7 /* \AGA7 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x09]` | `AGA8 /* \AGA8 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x0A]` | `AGA9 /* \AGA9 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x0B]` | `AGAA /* \AGAA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x0C]` | `AGAB /* \AGAB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x0D]` | `AGB1 /* \AGB1 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x0E]` | `AGB2 /* \AGB2 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x0F]` | `AGB3 /* \AGB3 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x10]` | `AGB4 /* \AGB4 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x11]` | `AGB5 /* \AGB5 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x12]` | `AGB6 /* \AGB6 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x13]` | `AGB7 /* \AGB7 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x14]` | `AGB8 /* \AGB8 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x15]` | `AGB9 /* \AGB9 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x16]` | `AGBA /* \AGBA */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (PPAY [One]) [0x17]` | `AGBB /* \AGBB */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [One]` | `WTSV /* \WTSV */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x02]` | `WTLE /* \WTLE */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x03]` | `BL01 /* \BL01 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x04]` | `BL02 /* \BL02 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x05]` | `BL03 /* \BL03 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x06]` | `BL04 /* \BL04 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x07]` | `BL05 /* \BL05 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x08]` | `BL06 /* \BL06 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x09]` | `BL07 /* \BL07 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x0A]` | `BL08 /* \BL08 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x0B]` | `BL09 /* \BL09 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x0C]` | `BL10 /* \BL10 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x0D]` | `BL11 /* \BL11 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x0E]` | `BL12 /* \BL12 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x0F]` | `BL13 /* \BL13 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x10]` | `BL14 /* \BL14 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x11]` | `BL15 /* \BL15 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WTSY [One]) [0x12]` | `BL16 /* \BL16 */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WAIY [One]) [One]` | `WLBI /* \WLBI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (WAIY [One]) [0x02]` | `WHBI /* \WHBI */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (SADX [One]) [One]` | `ATDV /* \ATDV */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (SADX [0x02]) [One]` | `ATDV /* \ATDV */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("AR: GLAI method. CGLS` | `", ToHexString (CGLS)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (GLAX [One]) [One]` | `CGLS /* \CGLS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DerefOf (GLAX [0x02]) [One]` | `CGLS /* \CGLS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((WWEN !` | `Zero) && (WWRP == SLOT)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((GGOV (PRST) !` | `WPRP))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((Arg0` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While (((SVID !` | `WSID) && (Local0 < WSTO)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WWEN` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Acquire (WWMT, 0x03E8)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Zero` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `While ((LASX` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `Acquire (WWMT, 0x03E8)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Local0` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((MTST () || (WIST () || ((WWEN !` | `Zero) && (WWRP ==` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `DCTR /* \_SB_.PC00.RP04.PXSX.DCTR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `0x8000` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DCTR` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((WWEN !` | `Zero) && (WWRP == SLOT)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WGAS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(CVPR << Zero)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CMDT` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((WGAS` | `= One) && WIST ()))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CMDT` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WIST ()` | `= (WGAS == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `(CMDP & One)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `RSTY` | `Local0` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `(CMDP & 0x02)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 >>` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FLRC` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2` | `(CMDP & 0x04)` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local2 >>` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `BOFC` | `Local2` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `^^^CNVW.RSTT` | `CMDP /* \_SB_.PC00.RP04.PXSX.IFUN.CMDP */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CMDT` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ADBG (Concatenate ("Get Last_PRR status DPRS` | `", ToHexString (DPRS)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CRFI` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WGAS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((PRTT` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `FDEL` | `PRTD /* \_SB_.PC00.RP04.PXSX.IFUN.PRTD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((PRTT` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PDEL` | `PRTD /* \_SB_.PC00.RP04.PXSX.IFUN.PRTD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((PRTT` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `VDEL` | `PRTD /* \_SB_.PC00.RP04.PXSX.IFUN.PRTD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("7266172c-220b-4b29-814f-75e4dd26b5fd") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WGAS` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `ACSD /* \ACSD */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `I5BS /* \I5BS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `UHBS /* \UHBS */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x06))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0` | `AXMU /* \AXMU */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 <<` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `AXSU /* \AXSU */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1` | `AXMR /* \AXMR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 <<` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 |` | `AXSR /* \AXSR */` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local1 <<` | `0x02` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Local0 |` | `Local1` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x04))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x05))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x07))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x08))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg2` | `= 0x09) && (WGAS == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg2` | `= 0x0A) && (WGAS == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg2` | `= 0x0B) && (WGAS == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((CDRM` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((Arg2` | `= 0x0C) && (WGAS == One)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("f21202bf-8f78-4dc6-a5b3-1f738e285ade") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If (((WWEN !` | `Zero) && (WWRP == SLOT)))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= ToUUID ("bad01b75-22a8-4f48-8792-bdde9467747d") /* Unknown UUID */))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= One)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x02)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg2` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((WRTO` | `= One)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `ElseIf ((WRTO` | `= 0x03)){}` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= One))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= 0x02))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((DSSI` | `= Zero))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PDAT` | `0x00010001` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `DSSI` | `One` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg1` | `= 0x03))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `Method (_WED, 1, NotSerialized)  // _Wxx: Wake Event, xx` | `0x00-0xFF` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `If ((Arg0` | `= 0xD0))` |
| hosts/kernelcore/acpi-fix/dsdt.dsl | `PDAT` | `Arg2` |
| modules/security/clamav.nix | `services.clamav` | `{` |
| modules/security/clamav.nix | `daemon.enable` | `true` |
| modules/security/clamav.nix | `updater.enable` | `true` |
| modules/security/clamav.nix | `updater.interval` | `"hourly"` |
| modules/security/clamav.nix | `updater.frequency` | `24` |
| modules/security/clamav.nix | `systemd.tmpfiles.rules` | `[` |
| modules/security/clamav.nix | `security.sudo.extraRules` | `[` |
| modules/security/clamav.nix | `groups` | `[ "wheel" ]` |
| modules/security/clamav.nix | `commands` | `[` |
| modules/security/clamav.nix | `systemd.services.clamav-scan` | `{` |
| modules/security/clamav.nix | `description` | `"ClamAV system scan"` |
| modules/security/clamav.nix | `serviceConfig` | `{` |
| modules/security/clamav.nix | `Type` | `"oneshot"` |
| modules/security/clamav.nix | `Nice` | `19` |
| modules/security/clamav.nix | `IOSchedulingClass` | `"idle"` |
| modules/security/clamav.nix | `ExecStart` | `''` |
| modules/security/clamav.nix | `--log` | `/var/log/clamav/scan.log \` |
| modules/security/clamav.nix | `--exclude-dir` | `"^/sys" \` |
| modules/security/clamav.nix | `--exclude-dir` | `"^/proc" \` |
| modules/security/clamav.nix | `--exclude-dir` | `"^/dev" \` |
| modules/security/clamav.nix | `--exclude-dir` | `"^/run" \` |
| modules/security/clamav.nix | `--exclude-dir` | `"^/nix/store" \` |
| modules/security/clamav.nix | `--max-filesize` | `100M \` |
| modules/security/clamav.nix | `--max-scansize` | `300M \` |
| modules/security/clamav.nix | `systemd.timers.clamav-scan` | `{` |
| modules/security/clamav.nix | `description` | `"Weekly ClamAV scan"` |
| modules/security/clamav.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/security/clamav.nix | `timerConfig` | `{` |
| modules/security/clamav.nix | `OnCalendar` | `"weekly"` |
| modules/security/clamav.nix | `RandomizedDelaySec` | `"2h"` |
| modules/security/clamav.nix | `Persistent` | `true` |
| modules/security/clamav.nix | `ProtectSystem` | `"strict"` |
| modules/security/clamav.nix | `ProtectHome` | `"read-only"` |
| modules/security/clamav.nix | `ReadWritePaths` | `[` |
| modules/network/vpn/tailscale-desktop.nix | `kernelcore.network.vpn.tailscale` | `{` |
| modules/network/vpn/tailscale-desktop.nix | `enable` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `hostname` | `"desktop-home"; # Nome bonito no Tailscale` |
| modules/network/vpn/tailscale-desktop.nix | `enableSubnetRouter` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `advertiseRoutes` | `[` |
| modules/network/vpn/tailscale-desktop.nix | `acceptRoutes` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `acceptDNS` | `true; # MagicDNS (usar hostnames)` |
| modules/network/vpn/tailscale-desktop.nix | `enableMagicDNS` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `enableSSH` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `shieldsUp` | `false; # Allow connections from laptop` |
| modules/network/vpn/tailscale-desktop.nix | `enableConnectionPersistence` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `reconnectTimeout` | `30` |
| modules/network/vpn/tailscale-desktop.nix | `openFirewall` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `trustedInterface` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `autoStart` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `tags` | `[` |
| modules/network/vpn/tailscale-desktop.nix | `extraUpFlags` | `[` |
| modules/network/vpn/tailscale-desktop.nix | `boot.kernel.sysctl` | `{` |
| modules/network/vpn/tailscale-desktop.nix | `"net.core.netdev_max_backlog"` | `5000` |
| modules/network/vpn/tailscale-desktop.nix | `environment.shellAliases` | `{` |
| modules/network/vpn/tailscale-desktop.nix | `ts-router-status` | `''` |
| modules/network/vpn/tailscale-desktop.nix | `local-devices` | `''` |
| modules/network/vpn/tailscale-desktop.nix | `test-offload` | `''` |
| modules/network/vpn/tailscale-desktop.nix | `systemd.services.tailscale-subnet-check` | `{` |
| modules/network/vpn/tailscale-desktop.nix | `description` | `"Check Tailscale subnet router status on boot"` |
| modules/network/vpn/tailscale-desktop.nix | `after` | `[` |
| modules/network/vpn/tailscale-desktop.nix | `wants` | `[ "network-online.target" ]` |
| modules/network/vpn/tailscale-desktop.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/network/vpn/tailscale-desktop.nix | `serviceConfig` | `{` |
| modules/network/vpn/tailscale-desktop.nix | `Type` | `"oneshot"` |
| modules/network/vpn/tailscale-desktop.nix | `RemainAfterExit` | `true` |
| modules/network/vpn/tailscale-desktop.nix | `environment.interactiveShellInit` | `''` |
| modules/network/security/firewall-zones.nix | `zones` | `{` |
| modules/network/security/firewall-zones.nix | `dmz` | `{` |
| modules/network/security/firewall-zones.nix | `default` | `false` |
| modules/network/security/firewall-zones.nix | `description` | `"Enable DMZ zone for exposed services"` |
| modules/network/security/firewall-zones.nix | `default` | `[ ]` |
| modules/network/security/firewall-zones.nix | `example` | `[ "eth0" ]` |
| modules/network/security/firewall-zones.nix | `default` | `[` |
| modules/network/security/firewall-zones.nix | `description` | `"TCP ports allowed from DMZ"` |
| modules/network/security/firewall-zones.nix | `default` | `[ 443 ]; # QUIC/HTTP3` |
| modules/network/security/firewall-zones.nix | `description` | `"UDP ports allowed from DMZ"` |
| modules/network/security/firewall-zones.nix | `internal` | `{` |
| modules/network/security/firewall-zones.nix | `default` | `true` |
| modules/network/security/firewall-zones.nix | `description` | `"Enable internal zone for private workloads"` |
| modules/network/security/firewall-zones.nix | `default` | `[ "tailscale0" ]` |
| modules/network/security/firewall-zones.nix | `default` | `[` |
| modules/network/security/firewall-zones.nix | `description` | `"Services allowed from internal zone"` |
| modules/network/security/firewall-zones.nix | `default` | `true` |
| modules/network/security/firewall-zones.nix | `default` | `[ "100.64.0.0/10" ]; # Tailscale CGNAT range` |
| modules/network/security/firewall-zones.nix | `default` | `true` |
| modules/network/security/firewall-zones.nix | `isolated` | `{` |
| modules/network/security/firewall-zones.nix | `default` | `false` |
| modules/network/security/firewall-zones.nix | `description` | `"Enable isolated zone for untrusted workloads"` |
| modules/network/security/firewall-zones.nix | `default` | `[ ]` |
| modules/network/security/firewall-zones.nix | `default` | `true` |
| modules/network/security/firewall-zones.nix | `description` | `"Deny traffic to other zones from isolated"` |
| modules/network/security/firewall-zones.nix | `default` | `"drop"` |
| modules/network/security/firewall-zones.nix | `description` | `"Default policy for unmatched traffic"` |
| modules/network/security/firewall-zones.nix | `default` | `true` |
| modules/network/security/firewall-zones.nix | `description` | `"Enable logging of dropped packets"` |
| modules/network/security/firewall-zones.nix | `default` | `"[FW-ZONE]"` |
| modules/network/security/firewall-zones.nix | `description` | `"Prefix for firewall logs"` |
| modules/network/security/firewall-zones.nix | `default` | `true` |
| modules/network/security/firewall-zones.nix | `description` | `"Enable rate limiting for connection attempts"` |
| modules/network/security/firewall-zones.nix | `default` | `10` |
| modules/network/security/firewall-zones.nix | `description` | `"Burst size for rate limiting"` |
| modules/network/security/firewall-zones.nix | `networking.nftables` | `{` |
| modules/network/security/firewall-zones.nix | `enable` | `true` |
| modules/network/security/firewall-zones.nix | `ruleset` | `''` |
| modules/network/security/firewall-zones.nix | `${optionalString (cfg.zones.dmz.interfaces !` | `[ ]) ''` |
| modules/network/security/firewall-zones.nix | `elements` | `{ ${concatStringsSep ", " (map (x: ''"${x}"'') cfg.zones.dmz.interfaces)} }` |
| modules/network/security/firewall-zones.nix | `${optionalString (cfg.zones.internal.interfaces !` | `[ ]) ''` |
| modules/network/security/firewall-zones.nix | `elements` | `{ ${concatStringsSep ", " (map (x: ''"${x}"'') cfg.zones.internal.interfaces)} }` |
| modules/network/security/firewall-zones.nix | `${optionalString (cfg.zones.admin.allowedIPs !` | `[ ]) ''` |
| modules/network/security/firewall-zones.nix | `elements` | `{ ${concatStringsSep ", " cfg.zones.admin.allowedIPs} }` |
| modules/network/security/firewall-zones.nix | `networking.firewall` | `{` |
| modules/network/security/firewall-zones.nix | `environment.shellAliases` | `{` |
| modules/network/security/firewall-zones.nix | `fw-status` | `"sudo nft list ruleset"` |
| modules/network/security/firewall-zones.nix | `fw-zones` | `"sudo nft list sets"` |
| modules/network/security/firewall-zones.nix | `fw-stats` | `"sudo nft list table inet filter"` |
| modules/network/security/firewall-zones.nix | `fw-reload` | `"sudo systemctl reload nftables"` |
| modules/network/security/firewall-zones.nix | `fw-logs` | `"journalctl -k | grep '${cfg.logPrefix}'"` |
| modules/network/security/firewall-zones.nix | `mode` | `"0755"` |
| modules/network/security/firewall-zones.nix | `text` | `''` |
| modules/network/security/firewall-zones.nix | `echo "` | `====================================="` |
| modules/network/security/firewall-zones.nix | `echo "` | `====================================="` |
| modules/network/security/firewall-zones.nix | `cfg.zones.dmz.enable && cfg.zones.dmz.interfaces` | `= [ ]` |
| modules/network/security/firewall-zones.nix | `cfg.zones.isolated.enable && cfg.zones.isolated.interfaces` | `= [ ]` |
| hosts/kernelcore/home/yazi.nix | `dirDocs` | `"~/Documentos/Processados"` |
| hosts/kernelcore/home/yazi.nix | `dirImages` | `"~/Imagens/Processadas"` |
| hosts/kernelcore/home/yazi.nix | `dirTrash` | `"~/Lixo_Temporario"` |
| hosts/kernelcore/home/yazi.nix | `mkMoveCmd` | `dir: "shell 'mkdir -p ${dir} && mv \"$0\" ${dir}/' --confirm"` |
| hosts/kernelcore/home/yazi.nix | `programs.yazi` | `{` |
| hosts/kernelcore/home/yazi.nix | `enable` | `true` |
| hosts/kernelcore/home/yazi.nix | `enableBashIntegration` | `true` |
| hosts/kernelcore/home/yazi.nix | `enableZshIntegration` | `true` |
| hosts/kernelcore/home/yazi.nix | `settings` | `{` |
| hosts/kernelcore/home/yazi.nix | `manager` | `{` |
| hosts/kernelcore/home/yazi.nix | `show_hidden` | `false` |
| hosts/kernelcore/home/yazi.nix | `sort_by` | `"mtime"; # Ordenar por data de modificação (útil para ver o que chegou por último)` |
| hosts/kernelcore/home/yazi.nix | `sort_reverse` | `true; # Mais recentes primeiro` |
| hosts/kernelcore/home/yazi.nix | `sort_sensitive` | `false` |
| hosts/kernelcore/home/yazi.nix | `preview` | `{` |
| hosts/kernelcore/home/yazi.nix | `tab_size` | `2` |
| hosts/kernelcore/home/yazi.nix | `max_width` | `1000` |
| hosts/kernelcore/home/yazi.nix | `max_height` | `1000` |
| hosts/kernelcore/home/yazi.nix | `keymap` | `{` |
| hosts/kernelcore/home/yazi.nix | `manager.prepend_keymap` | `[` |
| hosts/kernelcore/home/yazi.nix | `on` | `[ "1" ]` |
| hosts/kernelcore/home/yazi.nix | `run` | `mkMoveCmd dirDocs` |
| hosts/kernelcore/home/yazi.nix | `desc` | `"Mover para Docs (Processados)"` |
| hosts/kernelcore/home/yazi.nix | `on` | `[ "2" ]` |
| hosts/kernelcore/home/yazi.nix | `run` | `mkMoveCmd dirImages` |
| hosts/kernelcore/home/yazi.nix | `desc` | `"Mover para Imagens"` |
| hosts/kernelcore/home/yazi.nix | `on` | `[ "3" ]` |
| hosts/kernelcore/home/yazi.nix | `run` | `mkMoveCmd dirTrash` |
| hosts/kernelcore/home/yazi.nix | `desc` | `"Mover para Lixo Temp"` |
| hosts/kernelcore/home/yazi.nix | `on` | `[ "<Space>" ]` |
| hosts/kernelcore/home/yazi.nix | `run` | `"peek"` |
| hosts/kernelcore/home/yazi.nix | `desc` | `"Espiar arquivo"` |
| hosts/kernelcore/home/yazi.nix | `on` | `[ "<Leader>s" ]` |
| hosts/kernelcore/home/yazi.nix | `run` | `"shell 'scp -p \"$YAZI_SELECTED\" cypher@192.168.15.9:~/ ' --confirm"` |
| hosts/kernelcore/home/yazi.nix | `desc` | `"Enviar arquivo para Laptop via SSH"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `programs.hyprlock` | `{` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `settings` | `{` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `general` | `{` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `disable_loading_bar` | `false` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `hide_cursor` | `true` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `grace` | `0` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `no_fade_out` | `false` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `ignore_empty_input` | `true` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `background` | `[` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `path` | `"screenshot"; # Use screenshot of current screen` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `blur_passes` | `4` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `blur_size` | `8` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `noise` | `0.02` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `contrast` | `0.85` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `brightness` | `0.6` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `vibrancy` | `0.2` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `vibrancy_darkness` | `0.5` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(10, 10, 15, 0.3)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `input-field` | `[` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `size` | `"350, 55"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, -150"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `outline_thickness` | `2` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `outer_color` | `"rgba(0, 212, 255, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `inner_color` | `"rgba(18, 18, 26, 0.85)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_color` | `"rgb(228, 228, 231)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `fade_on_empty` | `true` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `fade_timeout` | `2000` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `placeholder_text` | `"<span foreground='##71717a'>󰌾 Enter Password...</span>"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `hide_input` | `false` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `dots_size` | `0.3` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `dots_spacing` | `0.2` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `dots_center` | `true` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `dots_rounding` | `-1` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `rounding` | `12` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `check_color` | `"rgba(0, 212, 255, 0.8)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `fail_color` | `"rgba(255, 0, 170, 0.8)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `fail_text` | `"<span foreground='##ff00aa'>󰀦 Authentication Failed</span>"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `fail_transition` | `300` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `capslock_color` | `"rgba(234, 179, 8, 0.8)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `numlock_color` | `"rgba(124, 58, 237, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `bothlock_color` | `"rgba(234, 179, 8, 0.8)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `swap_font_color` | `true` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_passes` | `3` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_size` | `8` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_color` | `"rgba(0, 0, 0, 0.4)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_boost` | `1.2` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `label` | `[` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"cmd[update:1000] date +%H:%M"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(255, 255, 255, 1)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `95` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, 200"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_passes` | `3` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_size` | `5` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_color` | `"rgba(0, 0, 0, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_boost` | `1.5` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"cmd[update:60000] date '+%A, %B %d'"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(161, 161, 170, 1)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `24` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, 100"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_passes` | `2` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_size` | `3` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_color` | `"rgba(0, 0, 0, 0.4)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"Hi, $USER"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(0, 212, 255, 0.9)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `18` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, -80"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"󰌾"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(124, 58, 237, 0.8)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `28` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, -220"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"cmd[update:5000] echo '󰍛 '$(free -h | awk '/^Mem:/ {print $3}')' / '$(free -h | awk '/^Mem:/ {print $2}')"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(113, 113, 122, 0.7)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `12` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, 50"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"bottom"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"cmd[update:0] hostname"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(0, 212, 255, 0.6)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `11` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"20, 20"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"left"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"bottom"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `text` | `"cmd[update:10000] cat /sys/class/power_supply/BAT0/capacity 2>/dev/null && echo '%' || echo ''"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `color` | `"rgba(34, 197, 94, 0.7)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_size` | `11` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `font_family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"-20, 20"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"right"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"bottom"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `image` | `[` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `monitor` | `""` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `path` | `"$HOME/.face"; # Standard location for user avatar` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `size` | `120` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `border_size` | `3` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `border_color` | `"rgba(0, 212, 255, 0.6)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `rounding` | `-1; # Full circle` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `position` | `"0, 0"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `halign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `valign` | `"center"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_passes` | `3` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_size` | `6` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_color` | `"rgba(0, 0, 0, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/hyprlock.nix | `shadow_boost` | `1.2` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `LITELLM_CONTAINER` | `"litellm-manager"` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `LITELLM_IMAGE` | `"voidnxlabs/dhi-llmrouter:1"` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `LITELLM_NETWORK` | `"llm-control-plane"` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `WORKSPACE_DIR` | `"${LITELLM_WORKSPACE:-$HOME/litellm-workspace}"` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `SSH_PORT` | `"${LITELLM_SSH_PORT:-2222}"` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `RED` | `'\033[0;31m'` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `GREEN` | `'\033[0;32m'` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `YELLOW` | `'\033[1;33m'` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `BLUE` | `'\033[0;34m'` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `NC` | `'\033[0m' # No Color` |
| hosts/kernelcore/home/aliases/litellm_runtime_manager.sh | `cmd` | `"llm_${1//-/_}"` |
| modules/virtualization/vmctl.nix | `default` | `false` |
| modules/virtualization/vmctl.nix | `default` | `false` |
| modules/virtualization/vmctl.nix | `description` | `"Enable verbose logging for vmctl operations"` |
| modules/virtualization/vmctl.nix | `default` | `false` |
| modules/virtualization/vmctl.nix | `description` | `"Print commands without executing (for debugging)"` |
| modules/virtualization/vmctl.nix | `environment.etc."bash_completion.d/vmctl".text` | `''` |
| modules/virtualization/vmctl.nix | `cur` | `"''${COMP_WORDS[COMP_CWORD]}"` |
| modules/virtualization/vmctl.nix | `prev` | `"''${COMP_WORDS[COMP_CWORD-1]}"` |
| modules/virtualization/vmctl.nix | `commands` | `"list ensure start stop restart console destroy convert-ova import-image create-disk wizard scan auto-import status snapshot"` |
| modules/virtualization/vmctl.nix | `vms` | `$(jq -r 'to_entries[] | select(.value.enable==true) | .key' /etc/vm-registry.json 2>/dev/null)` |
| modules/virtualization/vmctl.nix | `COMPREPLY` | `( $(compgen -W "$commands" -- "$cur") )` |
| modules/virtualization/vmctl.nix | `COMPREPLY` | `( $(compgen -W "$vms" -- "$cur") )` |
| modules/virtualization/vmctl.nix | `COMPREPLY` | `( $(compgen -f -- "$cur") )` |
| modules/virtualization/vmctl.nix | `COMPREPLY` | `( $(compgen -W "10 20 50 100 200" -- "$cur") )` |
| modules/virtualization/vmctl.nix | `name` | `"vmctl"` |
| modules/virtualization/vmctl.nix | `runtimeInputs` | `[` |
| modules/virtualization/vmctl.nix | `text` | `''` |
| modules/virtualization/vmctl.nix | `readonly REG` | `"/etc/vm-registry.json"` |
| modules/virtualization/vmctl.nix | `readonly VERBOSE` | `"${toString cfg.verbose}"` |
| modules/virtualization/vmctl.nix | `readonly DRY_RUN` | `"${toString cfg.dryRun}"` |
| modules/virtualization/vmctl.nix | `readonly C_RESET` | `'\033[0m'` |
| modules/virtualization/vmctl.nix | `readonly C_RED` | `'\033[0;31m'` |
| modules/virtualization/vmctl.nix | `found_path` | `"$img_path"` |
| modules/virtualization/vmctl.nix | `found_path` | `"$SRC_DIR/$img_path"` |
| modules/virtualization/vmctl.nix | `found_path` | `"/var/lib/libvirt/images/$img_path"` |
| modules/virtualization/vmctl.nix | `found_path` | `"$VM_BASE_DIR/$img_path"` |
| modules/virtualization/vmctl.nix | `basename` | `"$(basename "$img_path")"` |
| modules/virtualization/vmctl.nix | `found_path` | `"$dir/$basename"` |
| modules/virtualization/vmctl.nix | `state` | `$(virsh domstate "$v" 2>/dev/null || echo "undefined")` |
| modules/virtualization/vmctl.nix | `autostart` | `$(virsh dominfo "$v" 2>/dev/null | awk '/Autostart:/{print $2}' || echo "-")` |
| modules/virtualization/vmctl.nix | `local SCAN_DIRS` | `(` |
| modules/virtualization/vmctl.nix | `local found` | `0` |
| modules/virtualization/vmctl.nix | `found` | `1` |
| modules/virtualization/vmctl.nix | `size` | `$(du -h "$img" 2>/dev/null | cut -f1)` |
| modules/virtualization/vmctl.nix | `name` | `$(basename "$img" | sed 's/\.[^.]*$//')` |
| modules/virtualization/vmctl.nix | `NAME` | `"''${NAME:-$(basename "$SRC_PATH" | sed 's/\.[^.]*$//')}"` |
| modules/virtualization/vmctl.nix | `NAME` | `$(sanitize_name "$NAME")` |
| modules/virtualization/vmctl.nix | `kernelcore.virtualization.vms` | `{` |
| modules/virtualization/vmctl.nix | `$NAME` | `{` |
| modules/virtualization/vmctl.nix | `enable` | `true` |
| modules/virtualization/vmctl.nix | `sourceImage` | `"$NAME.qcow2"` |
| modules/virtualization/vmctl.nix | `memoryMiB` | `4096` |
| modules/virtualization/vmctl.nix | `vcpus` | `2` |
| modules/virtualization/vmctl.nix | `network` | `"nat"` |
| modules/virtualization/vmctl.nix | `enableClipboard` | `true` |
| modules/virtualization/vmctl.nix | `NAME` | `$(sanitize_name "$NAME")` |
| modules/virtualization/vmctl.nix | `JSON` | `$(jq -c --arg n "$NAME" 'to_entries[] | select(.key==$n) | .value' "$REG")` |
| modules/virtualization/vmctl.nix | `IMG` | `$(jq -r '.imageFile' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `SRC_IMG` | `$(jq -r '.sourceImage // empty' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `MEM` | `$(jq -r '.memoryMiB' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `VCPUS` | `$(jq -r '.vcpus' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `NET` | `$(jq -r '.network' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `BR` | `$(jq -r '.bridgeName' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `MAC` | `$(jq -r '.macAddress // empty' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `local -a NETARG` | `()` |
| modules/virtualization/vmctl.nix | `if [[ "$NET"` | `= "bridge" ]]; then` |
| modules/virtualization/vmctl.nix | `NETARG` | `("--network" "bridge=$BR,mac=$MAC")` |
| modules/virtualization/vmctl.nix | `NETARG` | `("--network" "bridge=$BR")` |
| modules/virtualization/vmctl.nix | `NETARG` | `("--network" "network=default,mac=$MAC")` |
| modules/virtualization/vmctl.nix | `NETARG` | `("--network" "default")` |
| modules/virtualization/vmctl.nix | `local -a FS_ARGS` | `()` |
| modules/virtualization/vmctl.nix | `local -a EXTRA_ARGS` | `()` |
| modules/virtualization/vmctl.nix | `SH_PATH` | `$(jq -r '.path' <<<"$SHARE")` |
| modules/virtualization/vmctl.nix | `SH_TAG` | `$(jq -r '.tag' <<<"$SHARE")` |
| modules/virtualization/vmctl.nix | `SH_DRV` | `$(jq -r '.driver' <<<"$SHARE")` |
| modules/virtualization/vmctl.nix | `SH_RO` | `$(jq -r '.readonly' <<<"$SHARE")` |
| modules/virtualization/vmctl.nix | `if [[ "$SH_DRV"` | `= "virtiofs" ]]; then` |
| modules/virtualization/vmctl.nix | `DISK_PATH` | `$(jq -r '.path' <<<"$DISK")` |
| modules/virtualization/vmctl.nix | `DISK_SIZE` | `$(jq -r '.size // empty' <<<"$DISK")` |
| modules/virtualization/vmctl.nix | `DISK_FORMAT` | `$(jq -r '.format // "qcow2"' <<<"$DISK")` |
| modules/virtualization/vmctl.nix | `DISK_BUS` | `$(jq -r '.bus // "virtio"' <<<"$DISK")` |
| modules/virtualization/vmctl.nix | `FOUND_IMG` | `"$IMG"` |
| modules/virtualization/vmctl.nix | `IMG` | `"$FOUND_IMG"` |
| modules/virtualization/vmctl.nix | `MEM_ARGS` | `("--memorybacking" "source.type=memfd,access.mode=shared")` |
| modules/virtualization/vmctl.nix | `CLIP_ENABLED` | `$(jq -r '.enableClipboard' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `local -a GRAPHICS_ARGS` | `()` |
| modules/virtualization/vmctl.nix | `if [[ "$CLIP_ENABLED"` | `= "true" ]]; then` |
| modules/virtualization/vmctl.nix | `GRAPHICS_ARGS` | `("--graphics" "spice,listen=none" "--video" "qxl" "--channel" "spicevmc")` |
| modules/virtualization/vmctl.nix | `GRAPHICS_ARGS` | `("--graphics" "spice,listen=none" "--video" "qxl")` |
| modules/virtualization/vmctl.nix | `--disk "path` | `$IMG,format=qcow2,bus=virtio" \` |
| modules/virtualization/vmctl.nix | `--console "pty,target.type` | `serial" \` |
| modules/virtualization/vmctl.nix | `--os-variant detect` | `on,require=off \` |
| modules/virtualization/vmctl.nix | `AUT` | `$(jq -r '.autostart' <<<"$JSON")` |
| modules/virtualization/vmctl.nix | `[[ "$AUT"` | `= "true" ]] && virsh autostart "$NAME" >/dev/null 2>&1 || true` |
| modules/virtualization/vmctl.nix | `local vm` | `"$1" snap_name="''${2:-snap-$(date +%Y%m%d-%H%M%S)}"` |
| modules/virtualization/vmctl.nix | `vm` | `$(sanitize_name "$vm")` |
| modules/virtualization/vmctl.nix | `cmd` | `"''${1:-list}"` |
| modules/virtualization/vmctl.nix | `vm` | `"''${2:-}"` |
| modules/virtualization/vmctl.nix | `if [[ ! "$cmd"` | `~ ^(scan|wizard|create-disk)$ ]]; then` |
| modules/virtualization/vmctl.nix | `vm` | `$(sanitize_name "$vm")` |
| modules/virtualization/vmctl.nix | `vm` | `$(sanitize_name "$vm")` |
| modules/virtualization/vmctl.nix | `vm` | `$(sanitize_name "$vm")` |
| modules/virtualization/vmctl.nix | `vm` | `$(sanitize_name "$vm")` |
| modules/virtualization/vmctl.nix | `vm` | `$(sanitize_name "$vm")` |
| modules/virtualization/vmctl.nix | `OVA` | `"''${2:-}"` |
| modules/virtualization/vmctl.nix | `NAME` | `"''${3:-}"` |
| modules/virtualization/vmctl.nix | `tmp` | `$(mktemp -d)` |
| modules/virtualization/vmctl.nix | `VMDK` | `$(bsdtar -tf "$OVA" | awk -F/ '/\.vmdk$/ {print $NF; exit}')` |
| modules/virtualization/vmctl.nix | `base` | `"''${NAME:-$(basename "''${OVA%.ova}")}"` |
| modules/virtualization/vmctl.nix | `base` | `$(sanitize_name "$base")` |
| modules/virtualization/vmctl.nix | `OUT` | `"$SRC_DIR/''${base}.qcow2"` |
| modules/virtualization/vmctl.nix | `SRC_PATH` | `"''${2:-}"` |
| modules/virtualization/vmctl.nix | `NAME` | `"''${3:-}"` |
| modules/virtualization/vmctl.nix | `base` | `"''${NAME:-$(basename "$SRC_PATH")}"` |
| modules/virtualization/vmctl.nix | `base` | `$(sanitize_name "''${base%.qcow2}")` |
| modules/virtualization/vmctl.nix | `OUT` | `"$SRC_DIR/''${base}.qcow2"` |
| modules/virtualization/vmctl.nix | `base` | `$(sanitize_name "''${base%.*}")` |
| modules/virtualization/vmctl.nix | `OUT` | `"$SRC_DIR/''${base}.qcow2"` |
| modules/virtualization/vmctl.nix | `NAME_ARG` | `"''${2:-}"` |
| modules/virtualization/vmctl.nix | `SIZE_GIB` | `"''${3:-}"` |
| modules/virtualization/vmctl.nix | `NAME_ARG` | `$(sanitize_name "$NAME_ARG")` |
| modules/virtualization/vmctl.nix | `[[ "$SIZE_GIB"` | `~ ^[0-9]+$ ]] || die "Size must be a number (GiB)"` |
| modules/virtualization/vmctl.nix | `OUT` | `"$VM_BASE_DIR/''${NAME_ARG}.qcow2"` |
| modules/virtualization/vmctl.nix | `DIALOG` | `dialog` |
| modules/virtualization/vmctl.nix | `tmp` | `$(mktemp)` |
| modules/virtualization/vmctl.nix | `MODE` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `NAME` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `NAME` | `$(sanitize_name "$NAME")` |
| modules/virtualization/vmctl.nix | `MEM` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `if [[ "$MEM"` | `= "custom" ]]; then` |
| modules/virtualization/vmctl.nix | `MEM` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `VCPUS` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `if [[ "$VCPUS"` | `= "custom" ]]; then` |
| modules/virtualization/vmctl.nix | `VCPUS` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `DEFAULT_SRC` | `"$SRC_DIR/$NAME.qcow2"` |
| modules/virtualization/vmctl.nix | `SRC` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `NET` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `BR` | `"br0"` |
| modules/virtualization/vmctl.nix | `MAC` | `""` |
| modules/virtualization/vmctl.nix | `if [[ "$NET"` | `= "bridge" ]]; then` |
| modules/virtualization/vmctl.nix | `BR` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `if [[ "$MODE"` | `= "advanced" ]]; then` |
| modules/virtualization/vmctl.nix | `MAC` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `IMG_FILE` | `""` |
| modules/virtualization/vmctl.nix | `AUTOSTART` | `"false"` |
| modules/virtualization/vmctl.nix | `CLIPBOARD` | `"true"` |
| modules/virtualization/vmctl.nix | `SHARED_DIRS_CONFIG` | `""` |
| modules/virtualization/vmctl.nix | `ADDITIONAL_DISKS_CONFIG` | `""` |
| modules/virtualization/vmctl.nix | `if [[ "$MODE"` | `= "basic" ]]; then` |
| modules/virtualization/vmctl.nix | `SHARE` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `SHARED_DIRS_CONFIG` | `"  sharedDirs = [{` |
| modules/virtualization/vmctl.nix | `path` | `\"$SHARE\"` |
| modules/virtualization/vmctl.nix | `tag` | `\"hostshare\"` |
| modules/virtualization/vmctl.nix | `driver` | `\"virtiofs\"` |
| modules/virtualization/vmctl.nix | `readonly` | `false` |
| modules/virtualization/vmctl.nix | `create` | `true` |
| modules/virtualization/vmctl.nix | `IMG_FILE` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `$DIALOG --yesno "Enable autostart?" 8 50 && AUTOSTART` | `"true"` |
| modules/virtualization/vmctl.nix | `$DIALOG --yesno "Enable clipboard sharing?" 8 50 || CLIPBOARD` | `"false"` |
| modules/virtualization/vmctl.nix | `SHARE_LIST` | `""` |
| modules/virtualization/vmctl.nix | `SHARE_PATH` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `SHARE_TAG` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `SHARE_DRV` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `$DIALOG --yesno "Read-only?" 8 50 && SHARE_RO` | `"true" || SHARE_RO="false"` |
| modules/virtualization/vmctl.nix | `SHARE_LIST` | `"''${SHARE_LIST}  {` |
| modules/virtualization/vmctl.nix | `path` | `\"$SHARE_PATH\"` |
| modules/virtualization/vmctl.nix | `tag` | `\"$SHARE_TAG\"` |
| modules/virtualization/vmctl.nix | `driver` | `\"$SHARE_DRV\"` |
| modules/virtualization/vmctl.nix | `readonly` | `$SHARE_RO` |
| modules/virtualization/vmctl.nix | `create` | `true` |
| modules/virtualization/vmctl.nix | `SHARED_DIRS_CONFIG` | `"  sharedDirs = [` |
| modules/virtualization/vmctl.nix | `DISK_LIST` | `""` |
| modules/virtualization/vmctl.nix | `DISK_PATH` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `DISK_SIZE` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `DISK_FMT` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `DISK_BUS` | `$(cat "$tmp")` |
| modules/virtualization/vmctl.nix | `DISK_SIZE_FIELD` | `""` |
| modules/virtualization/vmctl.nix | `[[ -n "$DISK_SIZE" ]] && DISK_SIZE_FIELD` | `"` |
| modules/virtualization/vmctl.nix | `size` | `\"$DISK_SIZE\";"` |
| modules/virtualization/vmctl.nix | `DISK_LIST` | `"''${DISK_LIST}  {` |
| modules/virtualization/vmctl.nix | `path` | `\"$DISK_PATH\";$DISK_SIZE_FIELD` |
| modules/virtualization/vmctl.nix | `format` | `\"$DISK_FMT\"` |
| modules/virtualization/vmctl.nix | `bus` | `\"$DISK_BUS\"` |
| modules/virtualization/vmctl.nix | `ADDITIONAL_DISKS_CONFIG` | `"  additionalDisks = [` |
| modules/virtualization/vmctl.nix | `enable` | `true` |
| modules/virtualization/vmctl.nix | `sourceImage` | `"$SRC"` |
| modules/virtualization/vmctl.nix | `memoryMiB` | `$MEM` |
| modules/virtualization/vmctl.nix | `vcpus` | `$VCPUS` |
| modules/virtualization/vmctl.nix | `network` | `"$NET"` |
| modules/virtualization/vmctl.nix | `bridgeName` | `"$BR"` |
| modules/virtualization/vmctl.nix | `enableClipboard` | `$CLIPBOARD` |
| modules/system/emergency-monitor.nix | `default` | `85` |
| modules/system/emergency-monitor.nix | `description` | `"SWAP usage % that triggers emergency intervention"` |
| modules/system/emergency-monitor.nix | `default` | `85` |
| modules/system/emergency-monitor.nix | `description` | `"CPU temperature (°C) that triggers cooldown"` |
| modules/system/emergency-monitor.nix | `default` | `32` |
| modules/system/emergency-monitor.nix | `description` | `"Load average that triggers build abort"` |
| modules/system/emergency-monitor.nix | `default` | `false` |
| modules/system/emergency-monitor.nix | `description` | `"Enable automatic intervention (abort builds when critical)"` |
| modules/system/emergency-monitor.nix | `systemd.services.emergency-monitor` | `{` |
| modules/system/emergency-monitor.nix | `description` | `"System Emergency Monitor"` |
| modules/system/emergency-monitor.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/system/emergency-monitor.nix | `after` | `[ "network.target" ]` |
| modules/system/emergency-monitor.nix | `serviceConfig` | `{` |
| modules/system/emergency-monitor.nix | `Type` | `"simple"` |
| modules/system/emergency-monitor.nix | `Restart` | `"always"` |
| modules/system/emergency-monitor.nix | `RestartSec` | `"30s"` |
| modules/system/emergency-monitor.nix | `User` | `"root"` |
| modules/system/emergency-monitor.nix | `local swap_total` | `$(free | grep Swap | awk '{print $2}')` |
| modules/system/emergency-monitor.nix | `temp` | `$(sensors 2>/dev/null | grep -i "Package id 0" | awk '{print $4}' | tr -d '+°C' | cut -d'.' -f1 || echo 0)` |
| modules/system/emergency-monitor.nix | `temp` | `$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))` |
| modules/system/emergency-monitor.nix | `swap_usage` | `$(get_swap_usage)` |
| modules/system/emergency-monitor.nix | `cpu_temp` | `$(get_cpu_temp)` |
| modules/system/emergency-monitor.nix | `load_avg` | `$(get_load_avg)` |
| modules/system/emergency-monitor.nix | `services.logrotate.settings.emergency-monitor` | `{` |
| modules/system/emergency-monitor.nix | `files` | `"/var/log/emergency-monitor.log"` |
| modules/system/emergency-monitor.nix | `rotate` | `7` |
| modules/system/emergency-monitor.nix | `frequency` | `"daily"` |
| modules/system/emergency-monitor.nix | `compress` | `true` |
| modules/system/emergency-monitor.nix | `delaycompress` | `true` |
| modules/system/emergency-monitor.nix | `missingok` | `true` |
| modules/system/emergency-monitor.nix | `notifempty` | `true` |
| modules/system/emergency-monitor.nix | `environment.systemPackages` | `[` |
| modules/system/emergency-monitor.nix | `security.sudo.extraRules` | `[` |
| modules/system/emergency-monitor.nix | `users` | `[ "kernelcore" ]` |
| modules/system/emergency-monitor.nix | `commands` | `[` |
| modules/system/emergency-monitor.nix | `command` | `"/etc/nixos/scripts/nix-emergency.sh"` |
| modules/services/offload-server.nix | `default` | `5000` |
| modules/services/offload-server.nix | `description` | `"Port for nix-serve binary cache"` |
| modules/services/offload-server.nix | `default` | `"nix-builder"` |
| modules/services/offload-server.nix | `description` | `"Username for remote build SSH access"` |
| modules/services/offload-server.nix | `default` | `"/var/cache-priv-key.pem"` |
| modules/services/offload-server.nix | `description` | `"Path to cache signing private key"` |
| modules/services/offload-server.nix | `default` | `false` |
| modules/services/offload-server.nix | `description` | `"Enable NFS exports for /nix/store sharing"` |
| modules/services/offload-server.nix | `services.nix-serve` | `{` |
| modules/services/offload-server.nix | `enable` | `true` |
| modules/services/offload-server.nix | `bindAddress` | `"0.0.0.0"; # Listen on all interfaces` |
| modules/services/offload-server.nix | `isSystemUser` | `true` |
| modules/services/offload-server.nix | `createHome` | `true` |
| modules/services/offload-server.nix | `description` | `"Nix remote build user"` |
| modules/services/offload-server.nix | `openssh.authorizedKeys.keys` | `[` |
| modules/services/offload-server.nix | `services.openssh` | `{` |
| modules/services/offload-server.nix | `enable` | `true` |
| modules/services/offload-server.nix | `settings` | `{` |
| modules/services/offload-server.nix | `PubkeyAuthentication` | `true` |
| modules/services/offload-server.nix | `extraConfig` | `''` |
| modules/services/offload-server.nix | `nix.settings` | `{` |
| modules/services/offload-server.nix | `keep-outputs` | `true` |
| modules/services/offload-server.nix | `keep-derivations` | `true` |
| modules/services/offload-server.nix | `connect-timeout` | `5` |
| modules/services/offload-server.nix | `stalled-download-timeout` | `30` |
| modules/services/offload-server.nix | `enable` | `true` |
| modules/services/offload-server.nix | `exports` | `''` |
| modules/services/offload-server.nix | `networking.firewall` | `{` |
| modules/services/offload-server.nix | `allowedTCPPorts` | `[` |
| modules/services/offload-server.nix | `PUB_KEY_PATH` | `"${` |
| modules/services/offload-server.nix | `IP` | `$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)` |
| modules/services/offload-server.nix | `KEY_COUNT` | `$(wc -l < "$AUTH_KEYS")` |
| modules/services/offload-server.nix | `echo "` | `==================================="` |
| modules/services/offload-server.nix | `PUB_KEY` | `"${` |
| modules/services/offload-server.nix | `system.activationScripts.offload-server-setup` | `''` |
| modules/packages/tar-packages/packages/appflowy.nix | `appflowy` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/appflowy.nix | `method` | `"fhs"` |
| modules/packages/tar-packages/packages/appflowy.nix | `source` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `path` | `../storage/AppFlowy-0.10.6-linux-x86_64.tar.gz` |
| modules/packages/tar-packages/packages/appflowy.nix | `sha256` | `"sha256-87mauW50ccOaPyK04O4I7+0bsvxVrdFxhi/Muc53wDY="` |
| modules/packages/tar-packages/packages/appflowy.nix | `wrapper` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `executable` | `"AppFlowy/AppFlowy"` |
| modules/packages/tar-packages/packages/appflowy.nix | `environmentVariables` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `"APPFLOWY_DATA_DIR"` | `"$HOME/.appflowy"` |
| modules/packages/tar-packages/packages/appflowy.nix | `sandbox` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/appflowy.nix | `audit` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/appflowy.nix | `desktopEntry` | `{` |
| modules/packages/tar-packages/packages/appflowy.nix | `name` | `"AppFlowy"` |
| modules/packages/tar-packages/packages/appflowy.nix | `comment` | `"Open-source Notion alternative"` |
| modules/packages/tar-packages/packages/appflowy.nix | `categories` | `[` |
| modules/packages/tar-packages/packages/appflowy.nix | `icon` | `null` |
| modules/network/dns/default.nix | `pname` | `"dns-proxy"` |
| modules/network/dns/default.nix | `version` | `"1.0.0"` |
| modules/network/dns/default.nix | `src` | `./.` |
| modules/network/dns/default.nix | `vendorHash` | `"sha256-IfjC6xc3q9nQpsMB6ccqqBKZnU4rTL+8oeqbUN9U/tg="` |
| modules/network/dns/default.nix | `homepage` | `"https://github.com/kernelcore/nixos"` |
| modules/network/dns/default.nix | `license` | `licenses.mit` |
| modules/network/dns/default.nix | `maintainers` | `[ "kernelcore" ]` |
| modules/network/dns/default.nix | `listen_addr` | `cfg.listenAddress` |
| modules/network/dns/default.nix | `upstreams` | `cfg.upstreams` |
| modules/network/dns/default.nix | `cache_size` | `cfg.cacheSize` |
| modules/network/dns/default.nix | `cache_ttl` | `cfg.cacheTTL` |
| modules/network/dns/default.nix | `timeout` | `cfg.timeout` |
| modules/network/dns/default.nix | `enable_stats` | `cfg.enableStats` |
| modules/network/dns/default.nix | `default` | `"127.0.0.1:53"` |
| modules/network/dns/default.nix | `description` | `"Address and port to listen on"` |
| modules/network/dns/default.nix | `default` | `[` |
| modules/network/dns/default.nix | `default` | `10000` |
| modules/network/dns/default.nix | `description` | `"Maximum number of cached DNS responses"` |
| modules/network/dns/default.nix | `default` | `300` |
| modules/network/dns/default.nix | `default` | `5` |
| modules/network/dns/default.nix | `default` | `true` |
| modules/network/dns/default.nix | `description` | `"Enable periodic statistics logging"` |
| modules/network/dns/default.nix | `default` | `true` |
| modules/network/dns/default.nix | `description` | `"Set this proxy as the system DNS resolver"` |
| modules/network/dns/default.nix | `environment.systemPackages` | `[ dns-proxy ]` |
| modules/network/dns/default.nix | `systemd.services.dns-proxy` | `{` |
| modules/network/dns/default.nix | `after` | `[ "network.target" ]` |
| modules/network/dns/default.nix | `before` | `mkIf cfg.setAsSystemResolver [ "systemd-resolved.service" ]` |
| modules/network/dns/default.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/network/dns/default.nix | `serviceConfig` | `{` |
| modules/network/dns/default.nix | `Type` | `"simple"` |
| modules/network/dns/default.nix | `Restart` | `"on-failure"` |
| modules/network/dns/default.nix | `RestartSec` | `"5s"` |
| modules/network/dns/default.nix | `DynamicUser` | `true` |
| modules/network/dns/default.nix | `NoNewPrivileges` | `true` |
| modules/network/dns/default.nix | `PrivateTmp` | `true` |
| modules/network/dns/default.nix | `ProtectSystem` | `"strict"` |
| modules/network/dns/default.nix | `ProtectHome` | `true` |
| modules/network/dns/default.nix | `ProtectKernelTunables` | `true` |
| modules/network/dns/default.nix | `ProtectKernelModules` | `true` |
| modules/network/dns/default.nix | `ProtectControlGroups` | `true` |
| modules/network/dns/default.nix | `RestrictAddressFamilies` | `[` |
| modules/network/dns/default.nix | `RestrictNamespaces` | `true` |
| modules/network/dns/default.nix | `LockPersonality` | `true` |
| modules/network/dns/default.nix | `MemoryDenyWriteExecute` | `true` |
| modules/network/dns/default.nix | `RestrictRealtime` | `true` |
| modules/network/dns/default.nix | `RestrictSUIDSGID` | `true` |
| modules/network/dns/default.nix | `PrivateDevices` | `true` |
| modules/network/dns/default.nix | `ProtectClock` | `true` |
| modules/network/dns/default.nix | `AmbientCapabilities` | `[ "CAP_NET_BIND_SERVICE" ]` |
| modules/network/dns/default.nix | `CapabilityBoundingSet` | `[ "CAP_NET_BIND_SERVICE" ]` |
| modules/network/dns/default.nix | `networking.nameservers` | `mkIf cfg.setAsSystemResolver (mkBefore [ "127.0.0.1" ])` |
| hosts/kernelcore/home/flameshot.nix | `services.flameshot` | `{` |
| hosts/kernelcore/home/flameshot.nix | `enable` | `true` |
| hosts/kernelcore/home/flameshot.nix | `settings` | `{` |
| hosts/kernelcore/home/flameshot.nix | `General` | `{` |
| hosts/kernelcore/home/flameshot.nix | `disabledTrayIcon` | `false` |
| hosts/kernelcore/home/flameshot.nix | `showStartupLaunchMessage` | `false` |
| modules/security/aide.nix | `kernelcore.security.aide` | `{` |
| modules/security/aide.nix | `default` | `"/var/lib/aide/aide.db"` |
| modules/security/aide.nix | `description` | `"Path to AIDE database"` |
| modules/security/aide.nix | `default` | `''` |
| modules/security/aide.nix | `database_in` | `/var/lib/aide/aide.db` |
| modules/security/aide.nix | `database_out` | `/var/lib/aide/aide.db.new` |
| modules/security/aide.nix | `database_new` | `/var/lib/aide/aide.db.new` |
| modules/security/aide.nix | `report_url` | `/var/log/aide/aide.log` |
| modules/security/aide.nix | `report_url` | `stdout` |
| modules/security/aide.nix | `verbose` | `5` |
| modules/security/aide.nix | `FIPSR` | `p+i+n+u+g+s+m+c+md5+sha256` |
| modules/security/aide.nix | `NORMAL` | `p+i+n+u+g+s+m+c+md5+sha256` |
| modules/security/aide.nix | `DIR` | `p+i+n+u+g` |
| modules/security/aide.nix | `PERMS` | `p+i+u+g` |
| modules/security/aide.nix | `LOG` | `>` |
| modules/security/aide.nix | `default` | `"daily"` |
| modules/security/aide.nix | `description` | `"Schedule for AIDE integrity checks (systemd timer format)"` |
| modules/security/aide.nix | `default` | `null` |
| modules/security/aide.nix | `example` | `"admin@example.com"` |
| modules/security/aide.nix | `mode` | `"0600"` |
| modules/security/aide.nix | `systemd.tmpfiles.rules` | `[` |
| modules/security/aide.nix | `systemd.services.aide-init` | `{` |
| modules/security/aide.nix | `description` | `"Initialize AIDE database"` |
| modules/security/aide.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/security/aide.nix | `after` | `[ "local-fs.target" ]` |
| modules/security/aide.nix | `serviceConfig` | `{` |
| modules/security/aide.nix | `Type` | `"oneshot"` |
| modules/security/aide.nix | `RemainAfterExit` | `true` |
| modules/security/aide.nix | `Nice` | `19` |
| modules/security/aide.nix | `IOSchedulingClass` | `"idle"` |
| modules/security/aide.nix | `systemd.services.aide-check` | `{` |
| modules/security/aide.nix | `description` | `"AIDE integrity check"` |
| modules/security/aide.nix | `requires` | `[ "aide-init.service" ]` |
| modules/security/aide.nix | `after` | `[ "aide-init.service" ]` |
| modules/security/aide.nix | `serviceConfig` | `{` |
| modules/security/aide.nix | `Type` | `"oneshot"` |
| modules/security/aide.nix | `Nice` | `19` |
| modules/security/aide.nix | `IOSchedulingClass` | `"idle"` |
| modules/security/aide.nix | `systemd.timers.aide-check` | `{` |
| modules/security/aide.nix | `description` | `"AIDE integrity check timer"` |
| modules/security/aide.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/security/aide.nix | `timerConfig` | `{` |
| modules/security/aide.nix | `RandomizedDelaySec` | `"1h"` |
| modules/security/aide.nix | `Persistent` | `true` |
| modules/security/aide.nix | `systemd.services.aide-update` | `{` |
| modules/security/aide.nix | `description` | `"Update AIDE database"` |
| modules/security/aide.nix | `requires` | `[ "aide-init.service" ]` |
| modules/security/aide.nix | `after` | `[ "aide-init.service" ]` |
| modules/security/aide.nix | `serviceConfig` | `{` |
| modules/security/aide.nix | `Type` | `"oneshot"` |
| modules/security/aide.nix | `Nice` | `19` |
| modules/security/aide.nix | `IOSchedulingClass` | `"idle"` |
| modules/security/aide.nix | `environment.shellAliases` | `{` |
| modules/security/aide.nix | `aide-check` | `"sudo systemctl start aide-check.service && sudo journalctl -u aide-check.service -n 50"` |
| modules/security/aide.nix | `aide-update` | `"sudo systemctl start aide-update.service && sudo journalctl -u aide-update.service -n 50"` |
| modules/security/aide.nix | `aide-status` | `"sudo systemctl status aide-check.timer aide-init.service"` |
| modules/security/aide.nix | `aide-logs` | `"sudo ls -lah /var/log/aide/ && echo '---' && sudo tail -n 50 /var/log/aide/*.log"` |
| modules/security/aide.nix | `text` | `''` |
| modules/security/aide.nix | `- No output` | `No changes detected (good!)` |
| modules/security/aide.nix | `- "Added entries"` | `New files created` |
| modules/security/aide.nix | `- "Removed entries"` | `Files deleted` |
| modules/security/aide.nix | `- "Changed entries"` | `Files modified` |
| modules/security/aide.nix | `mode` | `"0644"` |
| modules/services/users/codex-agent.nix | `codexBinary` | `"${cfg.package}/bin/${cfg.binaryName}"` |
| modules/services/users/codex-agent.nix | `defaultCommand` | `[` |
| modules/services/users/codex-agent.nix | `fallbackCommand` | `[` |
| modules/services/users/codex-agent.nix | `commandString` | `cmds: concatStringsSep " " (map escapeShellArg cmds)` |
| modules/services/users/codex-agent.nix | `export CODEX_AGENT_HOME` | `${escapeShellArg cfg.homeDirectory}` |
| modules/services/users/codex-agent.nix | `export CODEX_AGENT_WORKDIR` | `${escapeShellArg cfg.workDirectory}` |
| modules/services/users/codex-agent.nix | `if [ "${boolToString (cfg.execCommand !` | `[ ])}" = "true" ]; then` |
| modules/services/users/codex-agent.nix | `default` | `"codex"` |
| modules/services/users/codex-agent.nix | `description` | `"System user that owns the Codex agent service."` |
| modules/services/users/codex-agent.nix | `default` | `"/var/lib/codex"` |
| modules/services/users/codex-agent.nix | `description` | `"Home directory managed for the Codex agent user."` |
| modules/services/users/codex-agent.nix | `default` | `"/var/lib/codex/agents"` |
| modules/services/users/codex-agent.nix | `description` | `"Working directory used by the Codex agent service."` |
| modules/services/users/codex-agent.nix | `default` | `"/etc/codex/agents.toml"` |
| modules/services/users/codex-agent.nix | `description` | `"Configuration file passed to the Codex agent command."` |
| modules/services/users/codex-agent.nix | `default` | `null` |
| modules/services/users/codex-agent.nix | `description` | `"Optional EnvironmentFile consumed by systemd for secrets."` |
| modules/services/users/codex-agent.nix | `default` | `packageDefault` |
| modules/services/users/codex-agent.nix | `description` | `"Derivation that provides the Codex CLI binary executed by the agent."` |
| modules/services/users/codex-agent.nix | `default` | `"codex"` |
| modules/services/users/codex-agent.nix | `default` | `{ }` |
| modules/services/users/codex-agent.nix | `description` | `"Extra environment variables injected into the service."` |
| modules/services/users/codex-agent.nix | `default` | `[ ]` |
| modules/services/users/codex-agent.nix | `description` | `''` |
| modules/services/users/codex-agent.nix | `default` | `[ "multi-user.target" ]` |
| modules/services/users/codex-agent.nix | `description` | `"Targets that want the Codex agent service."` |
| modules/services/users/codex-agent.nix | `users.groups.${cfg.userName}` | `{ }` |
| modules/services/users/codex-agent.nix | `isSystemUser` | `true` |
| modules/services/users/codex-agent.nix | `group` | `cfg.userName` |
| modules/services/users/codex-agent.nix | `home` | `cfg.homeDirectory` |
| modules/services/users/codex-agent.nix | `createHome` | `true` |
| modules/services/users/codex-agent.nix | `description` | `"Codex CLI automation user"` |
| modules/services/users/codex-agent.nix | `extraGroups` | `[ "mcp-shared" ]; # For shared knowledge DB access` |
| modules/services/users/codex-agent.nix | `systemd.tmpfiles.rules` | `[` |
| modules/services/users/codex-agent.nix | `systemd.services.codex-agent` | `{` |
| modules/services/users/codex-agent.nix | `description` | `"Codex Agents Service"` |
| modules/services/users/codex-agent.nix | `after` | `[ "network-online.target" ]` |
| modules/services/users/codex-agent.nix | `wants` | `[ "network-online.target" ]` |
| modules/services/users/codex-agent.nix | `wantedBy` | `cfg.wantedBy` |
| modules/services/users/codex-agent.nix | `environment` | `{` |
| modules/services/users/codex-agent.nix | `CODEX_AGENT_USER` | `cfg.userName` |
| modules/services/users/codex-agent.nix | `CODEX_AGENT_HOME` | `cfg.homeDirectory` |
| modules/services/users/codex-agent.nix | `CODEX_AGENT_WORKDIR` | `cfg.workDirectory` |
| modules/services/users/codex-agent.nix | `MCP_CONFIG_PATH` | `"${cfg.homeDirectory}/.codex/mcp.json"` |
| modules/services/users/codex-agent.nix | `path` | `[` |
| modules/services/users/codex-agent.nix | `serviceConfig` | `{` |
| modules/services/users/codex-agent.nix | `Type` | `"simple"` |
| modules/services/users/codex-agent.nix | `User` | `cfg.userName` |
| modules/services/users/codex-agent.nix | `Group` | `cfg.userName` |
| modules/services/users/codex-agent.nix | `WorkingDirectory` | `cfg.workDirectory` |
| modules/services/users/codex-agent.nix | `ExecStart` | `runScript` |
| modules/services/users/codex-agent.nix | `Restart` | `"on-failure"` |
| modules/services/users/codex-agent.nix | `RestartSec` | `5` |
| modules/services/users/codex-agent.nix | `StandardOutput` | `"journal"` |
| modules/services/users/codex-agent.nix | `StandardError` | `"journal"` |
| modules/services/users/codex-agent.nix | `EnvironmentFile` | `cfg.environmentFile` |
| modules/network/monitoring/tailscale-monitor.nix | `CHECK_INTERVAL` | `''${CHECK_INTERVAL:-30}` |
| modules/network/monitoring/tailscale-monitor.nix | `MAX_LATENCY` | `''${MAX_LATENCY:-200}  # milliseconds` |
| modules/network/monitoring/tailscale-monitor.nix | `MAX_PACKET_LOSS` | `''${MAX_PACKET_LOSS:-5}  # percent` |
| modules/network/monitoring/tailscale-monitor.nix | `ALERT_EMAIL` | `''${ALERT_EMAIL:-""}` |
| modules/network/monitoring/tailscale-monitor.nix | `LOG_FILE` | `"''${LOGS_DIRECTORY:-/var/log}/tailscale-monitor.log"` |
| modules/network/monitoring/tailscale-monitor.nix | `RED` | `'\033[0;31m'` |
| modules/network/monitoring/tailscale-monitor.nix | `GREEN` | `'\033[0;32m'` |
| modules/network/monitoring/tailscale-monitor.nix | `YELLOW` | `'\033[1;33m'` |
| modules/network/monitoring/tailscale-monitor.nix | `BLUE` | `'\033[0;34m'` |
| modules/network/monitoring/tailscale-monitor.nix | `NC` | `'\033[0m'` |
| modules/network/monitoring/tailscale-monitor.nix | `local level` | `"$1"` |
| modules/network/monitoring/tailscale-monitor.nix | `waited` | `$((waited + 30))` |
| modules/network/monitoring/tailscale-monitor.nix | `local peer` | `"$1"` |
| modules/network/monitoring/tailscale-monitor.nix | `latency` | `$(echo "$netcheck_output" | grep -oP 'latency: \K[0-9.]+' | head -1 || echo "0")` |
| modules/network/monitoring/tailscale-monitor.nix | `packet_loss` | `$(echo "$ping_output" | grep -oP '\K[0-9.]+(?=% packet loss)' || echo "100")` |
| modules/network/monitoring/tailscale-monitor.nix | `local service` | `"$1"` |
| modules/network/monitoring/tailscale-monitor.nix | `local port` | `"$2"` |
| modules/network/monitoring/tailscale-monitor.nix | `consecutive_failures` | `$((consecutive_failures + 1))` |
| modules/network/monitoring/tailscale-monitor.nix | `if [ $consecutive_failures -ge 3 ] && [ "$failover_active"` | `false ]; then` |
| modules/network/monitoring/tailscale-monitor.nix | `failover_active` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `quality` | `$(measure_quality "" || echo "0:100")` |
| modules/network/monitoring/tailscale-monitor.nix | `latency` | `$(echo "$quality" | cut -d: -f1)` |
| modules/network/monitoring/tailscale-monitor.nix | `packet_loss` | `$(echo "$quality" | cut -d: -f2)` |
| modules/network/monitoring/tailscale-monitor.nix | `log "INFO" "Connection quality: Latency` | `''${latency}ms, Packet Loss=''${packet_loss}%"` |
| modules/network/monitoring/tailscale-monitor.nix | `consecutive_failures` | `$((consecutive_failures + 1))` |
| modules/network/monitoring/tailscale-monitor.nix | `if [ $consecutive_failures -ge 3 ] && [ "$failover_active"` | `false ]; then` |
| modules/network/monitoring/tailscale-monitor.nix | `failover_active` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `if [ "$failover_active"` | `true ]; then` |
| modules/network/monitoring/tailscale-monitor.nix | `failover_active` | `false` |
| modules/network/monitoring/tailscale-monitor.nix | `consecutive_failures` | `0` |
| modules/network/monitoring/tailscale-monitor.nix | `consecutive_failures` | `0` |
| modules/network/monitoring/tailscale-monitor.nix | `BLUE` | `'\033[0;34m'` |
| modules/network/monitoring/tailscale-monitor.nix | `GREEN` | `'\033[0;32m'` |
| modules/network/monitoring/tailscale-monitor.nix | `YELLOW` | `'\033[1;33m'` |
| modules/network/monitoring/tailscale-monitor.nix | `NC` | `'\033[0m'` |
| modules/network/monitoring/tailscale-monitor.nix | `echo -e "''${BLUE}` | `======================================"` |
| modules/network/monitoring/tailscale-monitor.nix | `echo -e "` | `======================================''${NC}"` |
| modules/network/monitoring/tailscale-monitor.nix | `default` | `30` |
| modules/network/monitoring/tailscale-monitor.nix | `default` | `200` |
| modules/network/monitoring/tailscale-monitor.nix | `default` | `5` |
| modules/network/monitoring/tailscale-monitor.nix | `description` | `"Maximum acceptable packet loss percentage"` |
| modules/network/monitoring/tailscale-monitor.nix | `default` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `description` | `"Enable automatic failover to local network on poor connectivity"` |
| modules/network/monitoring/tailscale-monitor.nix | `default` | `null` |
| modules/network/monitoring/tailscale-monitor.nix | `description` | `"Email address for failover alerts"` |
| modules/network/monitoring/tailscale-monitor.nix | `default` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `description` | `"Enable performance benchmarking tools"` |
| modules/network/monitoring/tailscale-monitor.nix | `systemd.services.tailscale-monitor` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `description` | `"Tailscale Connection Quality Monitor"` |
| modules/network/monitoring/tailscale-monitor.nix | `after` | `[` |
| modules/network/monitoring/tailscale-monitor.nix | `wants` | `[ "network-online.target" ]` |
| modules/network/monitoring/tailscale-monitor.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/network/monitoring/tailscale-monitor.nix | `environment` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `CHECK_INTERVAL` | `toString cfg.checkInterval` |
| modules/network/monitoring/tailscale-monitor.nix | `MAX_LATENCY` | `toString cfg.maxLatency` |
| modules/network/monitoring/tailscale-monitor.nix | `MAX_PACKET_LOSS` | `toString cfg.maxPacketLoss` |
| modules/network/monitoring/tailscale-monitor.nix | `ALERT_EMAIL` | `cfg.alertEmail or ""` |
| modules/network/monitoring/tailscale-monitor.nix | `LOGS_DIRECTORY` | `"/var/log/tailscale-monitor"` |
| modules/network/monitoring/tailscale-monitor.nix | `serviceConfig` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `Type` | `"simple"` |
| modules/network/monitoring/tailscale-monitor.nix | `ExecStart` | `"${monitorScript}"` |
| modules/network/monitoring/tailscale-monitor.nix | `Restart` | `"always"` |
| modules/network/monitoring/tailscale-monitor.nix | `RestartSec` | `"10s"` |
| modules/network/monitoring/tailscale-monitor.nix | `LogsDirectory` | `"tailscale-monitor"` |
| modules/network/monitoring/tailscale-monitor.nix | `DynamicUser` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `PrivateTmp` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `ProtectSystem` | `"strict"` |
| modules/network/monitoring/tailscale-monitor.nix | `ProtectHome` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `MemoryMax` | `"128M"` |
| modules/network/monitoring/tailscale-monitor.nix | `CPUQuota` | `"10%"` |
| modules/network/monitoring/tailscale-monitor.nix | `services.logrotate` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `enable` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `settings` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `"/var/log/tailscale-monitor/tailscale-monitor.log"` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `frequency` | `"daily"` |
| modules/network/monitoring/tailscale-monitor.nix | `rotate` | `7` |
| modules/network/monitoring/tailscale-monitor.nix | `compress` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `delaycompress` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `missingok` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `notifempty` | `true` |
| modules/network/monitoring/tailscale-monitor.nix | `environment.shellAliases` | `{` |
| modules/network/monitoring/tailscale-monitor.nix | `ts-monitor-status` | `"systemctl status tailscale-monitor"` |
| modules/network/monitoring/tailscale-monitor.nix | `ts-monitor-logs` | `"journalctl -u tailscale-monitor -f"` |
| modules/network/monitoring/tailscale-monitor.nix | `ts-monitor-logs-file` | `"tail -f /var/log/tailscale-monitor/tailscale-monitor.log"` |
| modules/network/monitoring/tailscale-monitor.nix | `ts-monitor-restart` | `"sudo systemctl restart tailscale-monitor"` |
| modules/network/monitoring/tailscale-monitor.nix | `mode` | `"0755"` |
| modules/network/monitoring/tailscale-monitor.nix | `text` | `''` |
| modules/network/monitoring/tailscale-monitor.nix | `echo "` | `======================================"` |
| modules/network/monitoring/tailscale-monitor.nix | `echo "` | `======================================"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `colors` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `bg0` | `"#0a0a0f"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `bg1` | `"#12121a"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `bg2` | `"#1a1a24"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `bg3` | `"#22222e"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `fg0` | `"#ffffff"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `fg1` | `"#e4e4e7"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `fg2` | `"#a1a1aa"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `fg3` | `"#71717a"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `cyan` | `"#00d4ff"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `magenta` | `"#ff00aa"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `blue` | `"#3b82f6"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `green` | `"#22c55e"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `yellow` | `"#eab308"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `orange` | `"#f97316"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `red` | `"#ef4444"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `programs.zellij` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `enableBashIntegration` | `false; # Don't auto-start, we launch explicitly` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `enableZshIntegration` | `false` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `settings` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `default_shell` | `"zsh"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `default_layout` | `"default"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `default_mode` | `"normal"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `on_force_close` | `"detach"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `session_serialization` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `pane_viewport_serialization` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `scrollback_lines_to_serialize` | `10000` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `mouse_mode` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `scroll_buffer_size` | `50000` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `copy_command` | `"wl-copy"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `copy_clipboard` | `"primary"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `copy_on_select` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `scrollback_editor` | `"nvim"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `mirror_session` | `false` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `auto_layout` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `styled_underlines` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `serialization_interval` | `1; # Seconds between saves` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `disable_session_metadata` | `false` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `simplified_ui` | `false` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `pane_frames` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `theme` | `"glassmorphism"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `keybinds` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `unbind` | `[ "Ctrl g" ]` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `normal` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"Alt h\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Left"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Left"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `1` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `2` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `3` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `4` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `5` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `6` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `7` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `8` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `9` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `NewPane` | `"Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `NewPane` | `"Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `NewTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `CloseFocus` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ToggleFocusFullscreen` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `TogglePaneFrames` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ToggleFloatingPanes` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ToggleActiveSyncTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `locked` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"Ctrl g\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `SwitchToMode` | `"Normal"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `pane` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"h\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Left"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MoveFocus` | `"Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `NewPane` | `"Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `NewPane` | `"Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `CloseFocus` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ToggleFocusFullscreen` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `TogglePaneFrames` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ToggleFloatingPanes` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `TogglePaneEmbedOrFloating` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `SwitchToMode` | `"RenamePane"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `PaneNameInput` | `[ 0 ]` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `tab` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"h\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToPreviousTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToNextTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `NewTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `CloseTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ToggleActiveSyncTab` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `SwitchToMode` | `"RenameTab"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `TabNameInput` | `[ 0 ]` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `1` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `2` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `3` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `4` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `GoToTab` | `5` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `resize` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"h\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Left"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Decrease Left"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Decrease Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Decrease Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Decrease Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Increase"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Resize` | `"Decrease"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `move` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"h\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MovePane` | `"Left"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MovePane` | `"Right"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MovePane` | `"Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MovePane` | `"Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MovePane` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `MovePane` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `search` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"n\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Search` | `"Down"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Search` | `"Up"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `SearchToggleOption` | `"CaseSensitivity"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `SearchToggleOption` | `"Wrap"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `SearchToggleOption` | `"WholeWord"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `session` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `"bind \"d\""` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `Detach` | `{ }` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `themes` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `glassmorphism` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `fg` | `colors.fg1` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `bg` | `colors.bg0; # Use darkest background instead of transparent` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `black` | `colors.bg3` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `white` | `colors.fg0` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `red` | `colors.magenta; # Using magenta for red` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `green` | `colors.green` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `yellow` | `colors.yellow` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `blue` | `colors.blue` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `cyan` | `colors.cyan; # Primary accent` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `orange` | `colors.orange` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `ui` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `pane_frames` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `rounded_corners` | `true` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `hide_session_name` | `false` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `plugins` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `tab-bar` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `path` | `"tab-bar"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `status-bar` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `path` | `"status-bar"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `strider` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `path` | `"strider"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `compact-bar` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `path` | `"compact-bar"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `session-manager` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `path` | `"session-manager"` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `//` | `===========================================` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `//` | `===========================================` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `pane size` | `1 borderless=true {` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `pane size` | `2 borderless=true {` |
| hosts/kernelcore/home/glassmorphism/zellij.nix | `tab name` | `"main" focus=true {` |
| hosts/kernelcore/home/tmux.nix | `programs.tmux` | `{` |
| hosts/kernelcore/home/tmux.nix | `enable` | `false` |
| hosts/kernelcore/home/tmux.nix | `terminal` | `"screen-256color"` |
| hosts/kernelcore/home/tmux.nix | `keyMode` | `"vi"` |
| hosts/kernelcore/home/tmux.nix | `mouse` | `true` |
| hosts/kernelcore/home/tmux.nix | `extraConfig` | `''` |
| modules/virtualization/macos-kvm.nix | `export PATH` | `"${` |
| modules/virtualization/macos-kvm.nix | `WORK_DIR` | `"${cfg.workDir}"` |
| modules/virtualization/macos-kvm.nix | `export PATH` | `"${` |
| modules/virtualization/macos-kvm.nix | `WORK_DIR` | `"${cfg.workDir}"` |
| modules/virtualization/macos-kvm.nix | `TOTAL_CORES` | `$(nproc)` |
| modules/virtualization/macos-kvm.nix | `VM_CORES` | `$((TOTAL_CORES / 2))` |
| modules/virtualization/macos-kvm.nix | `[ $VM_CORES -lt 4 ] && VM_CORES` | `4` |
| modules/virtualization/macos-kvm.nix | `[ $VM_CORES -gt ${toString cfg.maxCores} ] && VM_CORES` | `${toString cfg.maxCores}` |
| modules/virtualization/macos-kvm.nix | `VM_THREADS` | `2` |
| modules/virtualization/macos-kvm.nix | `VM_SMP` | `$((VM_CORES * VM_THREADS))` |
| modules/virtualization/macos-kvm.nix | `TOTAL_RAM_KB` | `$(grep MemTotal /proc/meminfo | awk '{print $2}')` |
| modules/virtualization/macos-kvm.nix | `VM_RAM_GB` | `$((TOTAL_RAM_KB / 1024 / 1024 / 2))` |
| modules/virtualization/macos-kvm.nix | `[ $VM_RAM_GB -lt 8 ] && VM_RAM_GB` | `8` |
| modules/virtualization/macos-kvm.nix | `[ $VM_RAM_GB -gt ${toString cfg.maxMemoryGB} ] && VM_RAM_GB` | `${toString cfg.maxMemoryGB}` |
| modules/virtualization/macos-kvm.nix | `VM_CORES` | `${toString cfg.cores}` |
| modules/virtualization/macos-kvm.nix | `VM_THREADS` | `2` |
| modules/virtualization/macos-kvm.nix | `VM_SMP` | `$((VM_CORES * VM_THREADS))` |
| modules/virtualization/macos-kvm.nix | `VM_RAM_GB` | `${toString cfg.memoryGB}` |
| modules/virtualization/macos-kvm.nix | `QEMU_ARGS` | `(` |
| modules/virtualization/macos-kvm.nix | `-cpu "${cfg.cpuModel},kvm` | `on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,+ssse3,+sse4.2,+popcnt,+avx,+avx2,+aes,+xsave,+xsaveopt,+fma,+bmi1 [... omitted end of long line]` |
| modules/virtualization/macos-kvm.nix | `-machine "q35,accel` | `kvm,kernel-irqchip=on"` |
| modules/virtualization/macos-kvm.nix | `-smp "$VM_SMP,sockets` | `1,cores=$VM_CORES,threads=$VM_THREADS"` |
| modules/virtualization/macos-kvm.nix | `-device qemu-xhci,id` | `xhci` |
| modules/virtualization/macos-kvm.nix | `-device "isa-applesmc,osk` | `ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"` |
| modules/virtualization/macos-kvm.nix | `-smbios type` | `2` |
| modules/virtualization/macos-kvm.nix | `-device ich9-ahci,id` | `sata` |
| modules/virtualization/macos-kvm.nix | `-drive "id` | `OpenCoreBoot,if=none,snapshot=on,format=qcow2,file=$WORK_DIR/OpenCore/OpenCore.qcow2"` |
| modules/virtualization/macos-kvm.nix | `-device ide-hd,bus` | `sata.2,drive=OpenCoreBoot` |
| modules/virtualization/macos-kvm.nix | `-drive "id` | `InstallMedia,if=none,file=$WORK_DIR/BaseSystem.img,format=raw"` |
| modules/virtualization/macos-kvm.nix | `-device ide-hd,bus` | `sata.3,drive=InstallMedia` |
| modules/virtualization/macos-kvm.nix | `-drive "id` | `MacHDD,if=none,file=$WORK_DIR/mac_hdd_ng.img,format=qcow2,cache=${cfg.diskCache},aio=${cfg.diskAio},discard=unmap"` |
| modules/virtualization/macos-kvm.nix | `-device ide-hd,bus` | `sata.4,drive=MacHDD` |
| modules/virtualization/macos-kvm.nix | `-netdev "user,id` | `net0,hostfwd=tcp::${toString cfg.sshPort}-:22,hostfwd=tcp::${toString cfg.vncPort}-:5900"` |
| modules/virtualization/macos-kvm.nix | `-device "virtio-net-pci,netdev` | `net0,id=net0,mac=${cfg.macAddress}"` |
| modules/virtualization/macos-kvm.nix | `-display sdl,gl` | `on` |
| modules/virtualization/macos-kvm.nix | `SSH_OPTS` | `"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"` |
| modules/virtualization/macos-kvm.nix | `SSH_OPTS` | `"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"` |
| modules/virtualization/macos-kvm.nix | `DISK` | `"${cfg.workDir}/mac_hdd_ng.img"` |
| modules/virtualization/macos-kvm.nix | `NAME` | `"''${2:-snapshot-$(date +%Y%m%d-%H%M%S)}"` |
| modules/virtualization/macos-kvm.nix | `NAME` | `"''${2:?Uso: macos-snapshot apply <nome>}"` |
| modules/virtualization/macos-kvm.nix | `NAME` | `"''${2:?Uso: macos-snapshot delete <nome>}"` |
| modules/virtualization/macos-kvm.nix | `echo "` | `== macOS VM Performance Benchmark ==="` |
| modules/virtualization/macos-kvm.nix | `SSH` | `"${macosSSHScript}/bin/macos-ssh"` |
| modules/virtualization/macos-kvm.nix | `TIMEOUT` | `''${1:-300}` |
| modules/virtualization/macos-kvm.nix | `start_time` | `$(date +%s)` |
| modules/virtualization/macos-kvm.nix | `elapsed` | `$(($(date +%s) - start_time))` |
| modules/virtualization/macos-kvm.nix | `default` | `"/home/kernelcore/.macos-kvm"` |
| modules/virtualization/macos-kvm.nix | `description` | `"Directory for macOS VM files (disk, installer, OpenCore)"` |
| modules/virtualization/macos-kvm.nix | `default` | `true` |
| modules/virtualization/macos-kvm.nix | `description` | `"Automatically detect CPU cores and RAM (uses 50% of host resources)"` |
| modules/virtualization/macos-kvm.nix | `default` | `4` |
| modules/virtualization/macos-kvm.nix | `description` | `"Number of CPU cores (when autoDetect is disabled)"` |
| modules/virtualization/macos-kvm.nix | `default` | `8` |
| modules/virtualization/macos-kvm.nix | `description` | `"Maximum CPU cores to use (when autoDetect is enabled)"` |
| modules/virtualization/macos-kvm.nix | `default` | `8` |
| modules/virtualization/macos-kvm.nix | `default` | `32` |
| modules/virtualization/macos-kvm.nix | `default` | `true` |
| modules/virtualization/macos-kvm.nix | `description` | `"Preallocate memory for faster boot"` |
| modules/virtualization/macos-kvm.nix | `default` | `256` |
| modules/virtualization/macos-kvm.nix | `default` | `"Cascadelake-Server"` |
| modules/virtualization/macos-kvm.nix | `description` | `"CPU model to emulate (Penryn for compatibility, Cascadelake-Server for performance)"` |
| modules/virtualization/macos-kvm.nix | `default` | `"writeback"` |
| modules/virtualization/macos-kvm.nix | `description` | `"Disk cache mode"` |
| modules/virtualization/macos-kvm.nix | `default` | `"threads"` |
| modules/virtualization/macos-kvm.nix | `description` | `"Disk async I/O mode"` |
| modules/virtualization/macos-kvm.nix | `default` | `10022` |
| modules/virtualization/macos-kvm.nix | `description` | `"Host port forwarded to guest SSH (22)"` |
| modules/virtualization/macos-kvm.nix | `default` | `5900` |
| modules/virtualization/macos-kvm.nix | `description` | `"Host port forwarded to guest VNC/Screen Sharing"` |
| modules/virtualization/macos-kvm.nix | `default` | `"52:54:00:c9:18:27"` |
| modules/virtualization/macos-kvm.nix | `description` | `"MAC address for the VM network interface"` |
| modules/virtualization/macos-kvm.nix | `default` | `"admin"` |
| modules/virtualization/macos-kvm.nix | `description` | `"Default SSH username for macOS VM"` |
| modules/virtualization/macos-kvm.nix | `display` | `{` |
| modules/virtualization/macos-kvm.nix | `default` | `true` |
| modules/virtualization/macos-kvm.nix | `default` | `true` |
| modules/virtualization/macos-kvm.nix | `description` | `"Enable QMP control socket at /tmp/macos-qmp.sock"` |
| modules/virtualization/macos-kvm.nix | `default` | `true` |
| modules/virtualization/macos-kvm.nix | `description` | `"Enable QEMU monitor socket at /tmp/macos-monitor.sock"` |
| modules/virtualization/macos-kvm.nix | `passthrough` | `{` |
| modules/virtualization/macos-kvm.nix | `default` | `[ ]` |
| modules/virtualization/macos-kvm.nix | `example` | `[` |
| modules/virtualization/macos-kvm.nix | `description` | `"PCI IDs for GPU passthrough (vendor:device format)"` |
| modules/virtualization/macos-kvm.nix | `default` | `[ ]` |
| modules/virtualization/macos-kvm.nix | `example` | `[` |
| modules/virtualization/macos-kvm.nix | `description` | `"PCI addresses for GPU passthrough"` |
| modules/virtualization/macos-kvm.nix | `kernelcore.virtualization.enable` | `true` |
| modules/virtualization/macos-kvm.nix | `boot.kernelParams` | `lib.optionals cfg.passthrough.enable (` |
| modules/virtualization/macos-kvm.nix | `"intel_iommu` | `on"` |
| modules/virtualization/macos-kvm.nix | `"iommu` | `pt"` |
| modules/virtualization/macos-kvm.nix | `++ (map (id: "vfio-pci.ids` | `${id}") cfg.passthrough.gpuIds)` |
| modules/virtualization/macos-kvm.nix | `boot.kernelModules` | `lib.optionals cfg.passthrough.enable [` |
| modules/virtualization/macos-kvm.nix | `systemd.tmpfiles.rules` | `[` |
| modules/virtualization/macos-kvm.nix | `environment.systemPackages` | `[` |
| modules/virtualization/macos-kvm.nix | `users.users.kernelcore.extraGroups` | `[` |
| modules/system/nix.nix | `kernelcore.system.nix` | `{` |
| modules/system/nix.nix | `default` | `true` |
| modules/system/nix.nix | `description` | `"Enable experimental Nix features (flakes, nix-command)"` |
| modules/system/nix.nix | `nix` | `{` |
| modules/system/nix.nix | `settings` | `mkMerge [` |
| modules/system/nix.nix | `experimental-features` | `[` |
| modules/system/nix.nix | `trusted-users` | `[` |
| modules/system/nix.nix | `auto-optimise-store` | `true` |
| modules/system/nix.nix | `substitute` | `true` |
| modules/system/nix.nix | `builders-use-substitutes` | `true` |
| modules/system/nix.nix | `extra-allowed-uris` | `[` |
| modules/system/nix.nix | `gc` | `{` |
| modules/system/nix.nix | `automatic` | `true` |
| modules/system/nix.nix | `randomizedDelaySec` | `"45min"` |
| modules/system/nix.nix | `optimise` | `{` |
| modules/system/nix.nix | `automatic` | `true` |
| modules/system/nix.nix | `dates` | `[ "03:45" ]` |
| modules/packages/tar-packages/packages/antigravity.nix | `antigravity` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/antigravity.nix | `method` | `"fhs"` |
| modules/packages/tar-packages/packages/antigravity.nix | `source` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `path` | `../storage/Antigravity.tar.gz` |
| modules/packages/tar-packages/packages/antigravity.nix | `sha256` | `"4548789f5e30ad13ef341ef112f3a399b2d6b0e0cc95e7bf5a0625b08a5a7120"` |
| modules/packages/tar-packages/packages/antigravity.nix | `wrapper` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `executable` | `"Antigravity/antigravity"` |
| modules/packages/tar-packages/packages/antigravity.nix | `environmentVariables` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `sandbox` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/antigravity.nix | `audit` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/antigravity.nix | `desktopEntry` | `{` |
| modules/packages/tar-packages/packages/antigravity.nix | `name` | `"Antigravity"` |
| modules/packages/tar-packages/packages/antigravity.nix | `categories` | `[` |
| modules/packages/tar-packages/packages/antigravity.nix | `icon` | `null; # Could extract icon from app if needed` |
| modules/services/mobile-workspace.nix | `kernelcore.services.mobile-workspace` | `{` |
| modules/services/mobile-workspace.nix | `default` | `"mobile"` |
| modules/services/mobile-workspace.nix | `description` | `"Username for mobile access"` |
| modules/services/mobile-workspace.nix | `default` | `"/srv/mobile-workspace"` |
| modules/services/mobile-workspace.nix | `description` | `"Isolated workspace directory for mobile user"` |
| modules/services/mobile-workspace.nix | `default` | `[` |
| modules/services/mobile-workspace.nix | `description` | `"List of allowed commands for mobile user"` |
| modules/services/mobile-workspace.nix | `default` | `[ ]` |
| modules/services/mobile-workspace.nix | `description` | `"SSH public keys for mobile user authentication"` |
| modules/services/mobile-workspace.nix | `default` | `[ ]` |
| modules/services/mobile-workspace.nix | `description` | `"Additional directories to make accessible (read-only) via bind mounts"` |
| modules/services/mobile-workspace.nix | `default` | `true` |
| modules/services/mobile-workspace.nix | `description` | `"Allow git operations (requires SSH agent forwarding)"` |
| modules/services/mobile-workspace.nix | `isNormalUser` | `true` |
| modules/services/mobile-workspace.nix | `description` | `"Mobile Workspace User (iPhone/Tablet)"` |
| modules/services/mobile-workspace.nix | `createHome` | `true` |
| modules/services/mobile-workspace.nix | `extraGroups` | `[ ]` |
| modules/services/mobile-workspace.nix | `systemd.tmpfiles.rules` | `[` |
| modules/services/mobile-workspace.nix | `text` | `''` |
| modules/services/mobile-workspace.nix | `mode` | `"0644"` |
| modules/services/mobile-workspace.nix | `text` | `''` |
| modules/services/mobile-workspace.nix | `PROMPT` | `'%F{cyan}📱 mobile%f:%F{blue}%~%f$ '` |
| modules/services/mobile-workspace.nix | `alias ls` | `'eza --icons'` |
| modules/services/mobile-workspace.nix | `alias ll` | `'eza --icons -lh'` |
| modules/services/mobile-workspace.nix | `alias la` | `'eza --icons -lah'` |
| modules/services/mobile-workspace.nix | `alias tree` | `'eza --tree --icons'` |
| modules/services/mobile-workspace.nix | `alias cat` | `'bat --paging=never'` |
| modules/services/mobile-workspace.nix | `alias grep` | `'rg'` |
| modules/services/mobile-workspace.nix | `alias find` | `'fd'` |
| modules/services/mobile-workspace.nix | `alias gs` | `'git status'` |
| modules/services/mobile-workspace.nix | `alias gp` | `'git pull'` |
| modules/services/mobile-workspace.nix | `alias gc` | `'git commit'` |
| modules/services/mobile-workspace.nix | `alias gd` | `'git diff'` |
| modules/services/mobile-workspace.nix | `alias gl` | `'git log --oneline --graph'` |
| modules/services/mobile-workspace.nix | `alias rm` | `'rm -i'` |
| modules/services/mobile-workspace.nix | `alias cp` | `'cp -i'` |
| modules/services/mobile-workspace.nix | `alias mv` | `'mv -i'` |
| modules/services/mobile-workspace.nix | `export EDITOR` | `vim` |
| modules/services/mobile-workspace.nix | `export VISUAL` | `vim` |
| modules/services/mobile-workspace.nix | `export PAGER` | `less` |
| modules/services/mobile-workspace.nix | `mode` | `"0644"` |
| modules/services/mobile-workspace.nix | `system.activationScripts.mobileWorkspaceConfig` | `''` |
| modules/services/mobile-workspace.nix | `services.openssh.extraConfig` | `mkBefore ''` |
| modules/services/mobile-workspace.nix | `systemd.services.mobile-workspace-maintenance` | `{` |
| modules/services/mobile-workspace.nix | `description` | `"Mobile Workspace Maintenance"` |
| modules/services/mobile-workspace.nix | `serviceConfig` | `{` |
| modules/services/mobile-workspace.nix | `Type` | `"oneshot"` |
| modules/services/mobile-workspace.nix | `User` | `"root"` |
| modules/services/mobile-workspace.nix | `systemd.timers.mobile-workspace-maintenance` | `{` |
| modules/services/mobile-workspace.nix | `description` | `"Weekly Mobile Workspace Maintenance"` |
| modules/services/mobile-workspace.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/services/mobile-workspace.nix | `timerConfig` | `{` |
| modules/services/mobile-workspace.nix | `OnCalendar` | `"weekly"` |
| modules/services/mobile-workspace.nix | `Persistent` | `true` |
| modules/services/mobile-workspace.nix | `services.journald.extraConfig` | `''` |
| modules/services/mobile-workspace.nix | `Storage` | `persistent` |
| modules/services/mobile-workspace.nix | `assertions` | `[` |
| modules/services/mobile-workspace.nix | `message` | `"Mobile workspace requires SSH to be enabled"` |
| modules/services/mobile-workspace.nix | `message` | `"Mobile workspace requires at least one SSH key"` |
| modules/network/dns/main.go | `defaultCacheSize` | `10000` |
| modules/network/dns/main.go | `defaultCacheTTL` | `300 // 5 minutes` |
| modules/network/dns/main.go | `defaultListenAddr` | `"127.0.0.1:53"` |
| modules/network/dns/main.go | `defaultUpstream` | `"1.1.1.1:53"` |
| modules/network/dns/main.go | `defaultTimeout` | `5 * time.Second` |
| modules/network/dns/main.go | `entry, exists :` | `c.entries[key]` |
| modules/network/dns/main.go | `if len(c.entries) >` | `c.maxSize {` |
| modules/network/dns/main.go | `for k :` | `range c.entries {` |
| modules/network/dns/main.go | `c.entries[key]` | `&CacheEntry{` |
| modules/network/dns/main.go | `c.entries` | `make(map[string]*CacheEntry)` |
| modules/network/dns/main.go | `if err !` | `nil {` |
| modules/network/dns/main.go | `s.queryTimes` | `append(s.queryTimes, duration)` |
| modules/network/dns/main.go | `s.queryTimes` | `s.queryTimes[1:]` |
| modules/network/dns/main.go | `total :` | `time.Duration(0)` |
| modules/network/dns/main.go | `for _, t :` | `range s.queryTimes {` |
| modules/network/dns/main.go | `total +` | `t` |
| modules/network/dns/main.go | `s.avgQueryTime` | `total / time.Duration(len(s.queryTimes))` |
| modules/network/dns/main.go | `hitRate :` | `float64(0)` |
| modules/network/dns/main.go | `hitRate` | `float64(s.cacheHits) / float64(s.queries) * 100` |
| modules/network/dns/main.go | `upstreams[i]` | `&dns.Client{` |
| modules/network/dns/main.go | `client :` | `p.upstreams[i]` |
| modules/network/dns/main.go | `response, _, err :` | `client.Exchange(msg, upstream)` |
| modules/network/dns/main.go | `if err` | `= nil && response != nil {` |
| modules/network/dns/main.go | `lastErr` | `err` |
| modules/network/dns/main.go | `start :` | `time.Now()` |
| modules/network/dns/main.go | `msg :` | `new(dns.Msg)` |
| modules/network/dns/main.go | `msg.RecursionAvailable` | `true` |
| modules/network/dns/main.go | `if len(r.Question)` | `= 0 {` |
| modules/network/dns/main.go | `msg.Rcode` | `dns.RcodeFormatError` |
| modules/network/dns/main.go | `question :` | `r.Question[0]` |
| modules/network/dns/main.go | `cacheKey :` | `p.makeKey(question)` |
| modules/network/dns/main.go | `if cachedResponse, found :` | `p.cache.Get(cacheKey); found {` |
| modules/network/dns/main.go | `cachedResponse.Id` | `r.Id` |
| modules/network/dns/main.go | `cached` | `true` |
| modules/network/dns/main.go | `if err :` | `w.WriteMsg(cachedResponse); err != nil {` |
| modules/network/dns/main.go | `msg.Rcode` | `dns.RcodeServerFailure` |
| modules/network/dns/main.go | `if response.Rcode` | `= dns.RcodeSuccess && len(response.Answer) > 0 {` |
| modules/network/dns/main.go | `response.Id` | `r.Id` |
| modules/network/dns/main.go | `if err :` | `w.WriteMsg(response); err != nil {` |
| hosts/kernelcore/home/shell/p10k.zsh | `where` | `${(V)VCS_STATUS_LOCAL_BRANCH}` |
| hosts/kernelcore/home/shell/p10k.zsh | `where` | `${(V)VCS_STATUS_TAG}` |
| hosts/kernelcore/home/shell/p10k.zsh | `(( $#where > 32 )) && where[13,-13]` | `"…"` |
| hosts/kernelcore/home/shell/p10k.zsh | `res+` | `"${clean}${where//\%/%%}"` |
| hosts/kernelcore/home/shell/p10k.zsh | `[[ -z $where ]] && res+` | `"${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"` |
| modules/security/nix-daemon.nix | `default` | `false` |
| modules/security/nix-daemon.nix | `description` | `"Allow Nix sandbox fallback (less secure but more compatible)"` |
| modules/security/nix-daemon.nix | `default` | `null` |
| modules/security/nix-daemon.nix | `description` | `''` |
| modules/security/nix-daemon.nix | `default` | `null` |
| modules/security/nix-daemon.nix | `description` | `''` |
| modules/security/nix-daemon.nix | `Example: "cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE` | `".` |
| modules/security/nix-daemon.nix | `default` | `[ ]` |
| modules/security/nix-daemon.nix | `description` | `"Additional substituters appended after the default cache list."` |
| modules/security/nix-daemon.nix | `default` | `[ ]` |
| modules/security/nix-daemon.nix | `default` | `30` |
| modules/security/nix-daemon.nix | `description` | `"Seconds to wait before falling back to the next substituter."` |
| modules/security/nix-daemon.nix | `default` | `300` |
| modules/security/nix-daemon.nix | `description` | `"Seconds before a stalled download is abandoned."` |
| modules/security/nix-daemon.nix | `defaultSubstituters` | `[` |
| modules/security/nix-daemon.nix | `defaultTrustedKeys` | `[` |
| modules/security/nix-daemon.nix | `"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY` | `"` |
| modules/security/nix-daemon.nix | `"cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgBv/esm1uaNOQx3cUeBiPApBCNGLQ` | `"` |
| modules/security/nix-daemon.nix | `"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs` | `"` |
| modules/security/nix-daemon.nix | `"devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw` | `"` |
| modules/security/nix-daemon.nix | `"pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc` | `"` |
| modules/security/nix-daemon.nix | `nix.settings` | `{` |
| modules/security/nix-daemon.nix | `trusted-users` | `[ "@wheel" ]` |
| modules/security/nix-daemon.nix | `allowed-users` | `[ "@users" ]` |
| modules/security/nix-daemon.nix | `build-users-group` | `"nixbld"` |
| modules/security/nix-daemon.nix | `require-sigs` | `true` |
| modules/security/nix-daemon.nix | `allowed-uris` | `[` |
| modules/security/nix-daemon.nix | `auto-optimise-store` | `true` |
| modules/security/nix-daemon.nix | `warn-dirty` | `true` |
| modules/security/nix-daemon.nix | `allowUnfree` | `true` |
| modules/security/nix-daemon.nix | `allowBroken` | `false` |
| modules/security/nix-daemon.nix | `allowInsecure` | `false` |
| modules/security/nix-daemon.nix | `permittedInsecurePackages` | `[` |
| modules/security/auto-upgrade.nix | `system.autoUpgrade` | `{` |
| modules/security/auto-upgrade.nix | `enable` | `true` |
| modules/security/auto-upgrade.nix | `allowReboot` | `false` |
| modules/security/auto-upgrade.nix | `dates` | `"04:00"` |
| modules/security/auto-upgrade.nix | `flake` | `"/etc/nixos#kernelcore"` |
| modules/security/auto-upgrade.nix | `flags` | `[` |
| modules/services/users/gitlab-runner.nix | `default` | `true` |
| modules/services/users/gitlab-runner.nix | `description` | `"Use SOPS for secret management (recommended)"` |
| modules/services/users/gitlab-runner.nix | `default` | `""` |
| modules/services/users/gitlab-runner.nix | `description` | `"GitLab Runner registration token (if not using SOPS)"` |
| modules/services/users/gitlab-runner.nix | `default` | `"https://gitlab.com"` |
| modules/services/users/gitlab-runner.nix | `description` | `"GitLab instance URL"` |
| modules/services/users/gitlab-runner.nix | `default` | `"nixos-gitlab-runner"` |
| modules/services/users/gitlab-runner.nix | `description` | `"Name for the GitLab Runner"` |
| modules/services/users/gitlab-runner.nix | `default` | `"shell"` |
| modules/services/users/gitlab-runner.nix | `description` | `"GitLab Runner executor type"` |
| modules/services/users/gitlab-runner.nix | `default` | `[` |
| modules/services/users/gitlab-runner.nix | `description` | `"Tags for the GitLab Runner"` |
| modules/services/users/gitlab-runner.nix | `default` | `4` |
| modules/services/users/gitlab-runner.nix | `description` | `"Maximum number of concurrent jobs"` |
| modules/services/users/gitlab-runner.nix | `default` | `"nixos/nix:latest"` |
| modules/services/users/gitlab-runner.nix | `description` | `"Default Docker image for Docker executor"` |
| modules/services/users/gitlab-runner.nix | `services.gitlab-runner` | `{` |
| modules/services/users/gitlab-runner.nix | `enable` | `true` |
| modules/services/users/gitlab-runner.nix | `settings` | `{` |
| modules/services/users/gitlab-runner.nix | `concurrent` | `cfg.concurrent` |
| modules/services/users/gitlab-runner.nix | `check_interval` | `3` |
| modules/services/users/gitlab-runner.nix | `runners` | `[` |
| modules/services/users/gitlab-runner.nix | `name` | `cfg.runnerName` |
| modules/services/users/gitlab-runner.nix | `url` | `cfg.url` |
| modules/services/users/gitlab-runner.nix | `token` | `if cfg.useSops then "$GITLAB_RUNNER_TOKEN" else cfg.registrationToken` |
| modules/services/users/gitlab-runner.nix | `executor` | `cfg.executor` |
| modules/services/users/gitlab-runner.nix | `tag_list` | `cfg.tags` |
| modules/services/users/gitlab-runner.nix | `run_untagged` | `false` |
| modules/services/users/gitlab-runner.nix | `docker` | `mkIf (cfg.executor == "docker" || cfg.executor == "docker+machine") {` |
| modules/services/users/gitlab-runner.nix | `image` | `cfg.dockerImage` |
| modules/services/users/gitlab-runner.nix | `privileged` | `false` |
| modules/services/users/gitlab-runner.nix | `disable_cache` | `false` |
| modules/services/users/gitlab-runner.nix | `volumes` | `[ "/cache" ]` |
| modules/services/users/gitlab-runner.nix | `shm_size` | `0` |
| modules/services/users/gitlab-runner.nix | `shell` | `mkIf (cfg.executor == "shell") "bash"` |
| modules/services/users/gitlab-runner.nix | `sops.secrets` | `mkIf cfg.useSops {` |
| modules/services/users/gitlab-runner.nix | `"gitlab/runner/token"` | `{` |
| modules/services/users/gitlab-runner.nix | `sopsFile` | `../../../secrets/gitlab.yaml` |
| modules/services/users/gitlab-runner.nix | `owner` | `"gitlab-runner"` |
| modules/services/users/gitlab-runner.nix | `group` | `"gitlab-runner"` |
| modules/services/users/gitlab-runner.nix | `mode` | `"0400"` |
| modules/services/users/gitlab-runner.nix | `restartUnits` | `[ "gitlab-runner.service" ]` |
| modules/services/users/gitlab-runner.nix | `systemd.services.gitlab-runner` | `{` |
| modules/services/users/gitlab-runner.nix | `serviceConfig` | `{` |
| modules/services/users/gitlab-runner.nix | `EnvironmentFile` | `mkIf cfg.useSops [` |
| modules/services/users/gitlab-runner.nix | `GITLAB_RUNNER_TOKEN` | `$(cat ${` |
| modules/services/users/gitlab-runner.nix | `users.users.gitlab-runner` | `mkIf (cfg.executor == "docker" || cfg.executor == "docker+machine") {` |
| modules/services/users/gitlab-runner.nix | `extraGroups` | `[ "docker" ]` |
| modules/hardware/wifi-optimization.nix | `boot.extraModprobeConfig` | `''` |
| modules/hardware/wifi-optimization.nix | `boot.kernelParams` | `[` |
| modules/hardware/wifi-optimization.nix | `"iwlwifi.power_save` | `0"` |
| modules/hardware/wifi-optimization.nix | `networking.networkmanager.wifi` | `{` |
| modules/hardware/wifi-optimization.nix | `macAddress` | `"preserve"` |
| modules/hardware/wifi-optimization.nix | `powersave` | `false` |
| modules/hardware/wifi-optimization.nix | `scanRandMacAddress` | `false` |
| modules/hardware/wifi-optimization.nix | `networking.networkmanager.settings` | `{` |
| modules/hardware/wifi-optimization.nix | `connection` | `{` |
| modules/hardware/wifi-optimization.nix | `"ipv4.dhcp-timeout"` | `"20"` |
| modules/hardware/wifi-optimization.nix | `device` | `{` |
| modules/hardware/wifi-optimization.nix | `"wifi.backend"` | `"wpa_supplicant"` |
| modules/hardware/wifi-optimization.nix | `networking.networkmanager.insertNameservers` | `[` |
| modules/hardware/wifi-optimization.nix | `services.resolved` | `{` |
| modules/hardware/wifi-optimization.nix | `enable` | `true` |
| modules/hardware/wifi-optimization.nix | `dnssec` | `"false"; # DNSSEC can add latency` |
| modules/hardware/wifi-optimization.nix | `dnsovertls` | `"opportunistic"` |
| modules/hardware/wifi-optimization.nix | `fallbackDns` | `[` |
| modules/hardware/wifi-optimization.nix | `extraConfig` | `''` |
| modules/hardware/wifi-optimization.nix | `CacheFromLocalhost` | `yes` |
| modules/hardware/wifi-optimization.nix | `DNSStubListener` | `yes` |
| modules/hardware/wifi-optimization.nix | `Timeout` | `2s` |
| modules/hardware/wifi-optimization.nix | `MulticastDNS` | `no` |
| modules/hardware/wifi-optimization.nix | `LLMNR` | `no` |
| modules/hardware/wifi-optimization.nix | `boot.kernel.sysctl` | `{` |
| modules/hardware/wifi-optimization.nix | `"net.core.rmem_max"` | `16777216` |
| modules/hardware/wifi-optimization.nix | `systemd.services.wifi-monitor` | `{` |
| modules/hardware/wifi-optimization.nix | `description` | `"WiFi Signal Quality Monitor"` |
| modules/hardware/wifi-optimization.nix | `after` | `[ "network.target" ]` |
| modules/hardware/wifi-optimization.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/wifi-optimization.nix | `serviceConfig` | `{` |
| modules/hardware/wifi-optimization.nix | `Type` | `"oneshot"` |
| modules/hardware/wifi-optimization.nix | `RemainAfterExit` | `true` |
| modules/hardware/wifi-optimization.nix | `text` | `''` |
| modules/hardware/wifi-optimization.nix | `echo "` | `== WiFi Diagnostics ==="` |
| modules/hardware/wifi-optimization.nix | `mode` | `"0755"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `base` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `bg0` | `"#0a0a0f"; # Deepest background` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `bg1` | `"#12121a"; # Primary surface` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `bg2` | `"#1a1a24"; # Elevated surface` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `bg3` | `"#22222e"; # Highest elevation` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `fg0` | `"#ffffff"; # Primary text` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `fg1` | `"#e4e4e7"; # Secondary text` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `fg2` | `"#a1a1aa"; # Muted text` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `fg3` | `"#71717a"; # Disabled/placeholder` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `surface` | `"#16161e"; # Card backgrounds` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `overlay` | `"#1e1e28"; # Modal/popup backgrounds` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `accent` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `cyan` | `"#00d4ff"; # Electric cyan - primary` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `magenta` | `"#ff00aa"; # Neon magenta - critical/danger` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `blue` | `"#3b82f6"; # Info` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `green` | `"#22c55e"; # Success` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `yellow` | `"#eab308"; # Warning` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `orange` | `"#f97316"; # Attention` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `red` | `"#ef4444"; # Error` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `cyanLight` | `"#67e8f9"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `cyanDark` | `"#0891b2"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `magentaLight` | `"#f472b6"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `magentaDark` | `"#be185d"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `violetLight` | `"#a78bfa"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `violetDark` | `"#5b21b6"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `alpha` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `solid` | `"ff"; # 100% - fully opaque` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `high` | `"e6"; # 90%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `medium` | `"cc"; # 80%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `mediumLow` | `"99"; # 60%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `low` | `"66"; # 40%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `veryLow` | `"33"; # 20%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `subtle` | `"1a"; # 10%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `minimal` | `"0d"; # 5%` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `dec` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `solid` | `"1.0"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `high` | `"0.9"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `medium` | `"0.8"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `mediumLow` | `"0.6"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `low` | `"0.4"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `veryLow` | `"0.2"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `subtle` | `"0.1"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `minimal` | `"0.05"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `border` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `light` | `"rgba(255, 255, 255, 0.1)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `lighter` | `"rgba(255, 255, 255, 0.05)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `accent` | `"rgba(0, 212, 255, 0.3)"; # Cyan glow` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `accentStrong` | `"rgba(0, 212, 255, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `gradientStart` | `"rgba(255, 255, 255, 0.1)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `gradientEnd` | `"rgba(255, 255, 255, 0.05)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `shadow` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `dark` | `"rgba(0, 0, 0, 0.4)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `medium` | `"rgba(0, 0, 0, 0.25)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `light` | `"rgba(0, 0, 0, 0.1)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `cyan` | `"rgba(0, 212, 255, 0.3)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `cyanStrong` | `"rgba(0, 212, 255, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `magenta` | `"rgba(255, 0, 170, 0.3)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `magentaStrong` | `"rgba(255, 0, 170, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `violetStrong` | `"rgba(124, 58, 237, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `blur` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `size` | `10; # pixels` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `passes` | `3; # render passes for quality` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `xray` | `true; # see through floating windows` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `noise` | `0.02; # subtle noise texture` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `contrast` | `0.9; # slight contrast boost` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `brightness` | `0.8; # slight dimming for depth` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `radius` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `small` | `8; # buttons, tags` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `medium` | `12; # cards, inputs` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `large` | `16; # modals, panels` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `pill` | `20; # waybar modules` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `full` | `9999; # circular elements` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `spacing` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `xs` | `4` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `sm` | `8` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `md` | `16` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `lg` | `24` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `xl` | `32` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `xxl` | `48` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `animation` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `fast` | `150` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `normal` | `250` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `slow` | `400` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `bezier` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `smooth` | `"0.4, 0, 0.2, 1"; # ease-out` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `bounce` | `"0.68, -0.55, 0.265, 1.55"; # overshoot` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `snappy` | `"0.2, 0.8, 0.2, 1"; # quick start` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `gentle` | `"0.4, 0.14, 0.3, 1"; # soft movement` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `urgency` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `low` | `accent.cyan; # Informational` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `normal` | `accent.violet; # Standard` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `critical` | `accent.magenta; # Important/Alert` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `semantic` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `success` | `accent.green` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `warning` | `accent.yellow` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `error` | `accent.red` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `info` | `accent.blue` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `active` | `accent.cyan` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `inactive` | `base.fg3` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `hover` | `accent.cyanLight` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `focus` | `accent.cyan` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `hyprland` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `activeBorder1` | `"${accent.cyan}ff"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `activeBorder2` | `"${accent.violet}ff"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `inactiveBorder` | `"${base.bg3}aa"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `shadowColor` | `"rgba(0, 0, 0, 0.5)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `shadowColorActive` | `shadow.cyan` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `dimInactive` | `0.85` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `waybar` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `background` | `"rgba(10, 10, 15, 0.75)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `moduleBackground` | `"rgba(18, 18, 26, 0.8)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `text` | `base.fg0` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `textSecondary` | `base.fg2` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `border` | `border.light` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `hover` | `"rgba(0, 212, 255, 0.15)"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `active` | `accent.cyan` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `gtk` | `{` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `background` | `base.bg1` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `foreground` | `base.fg0` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `accent` | `accent.cyan` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `selection` | `"${accent.cyan}33"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `border` | `base.bg3` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `default` | `{ }` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `description` | `"Glassmorphism color palette"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `withAlpha` | `color: alphaHex: "${color}${alphaHex}"` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `primary` | `accent.cyan` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `secondary` | `accent.violet` |
| hosts/kernelcore/home/glassmorphism/colors.nix | `danger` | `accent.magenta` |
| hosts/kernelcore/home/hyprland.nix | `wayland.windowManager.hyprland` | `{` |
| hosts/kernelcore/home/hyprland.nix | `enable` | `true` |
| hosts/kernelcore/home/hyprland.nix | `xwayland.enable` | `true` |
| hosts/kernelcore/home/hyprland.nix | `systemd.enable` | `true` |
| hosts/kernelcore/home/hyprland.nix | `settings` | `{` |
| hosts/kernelcore/home/hyprland.nix | `monitor` | `[` |
| hosts/kernelcore/home/hyprland.nix | `exec-once` | `[` |
| hosts/kernelcore/home/hyprland.nix | `env` | `[` |
| hosts/kernelcore/home/hyprland.nix | `input` | `{` |
| hosts/kernelcore/home/hyprland.nix | `kb_layout` | `"br"` |
| hosts/kernelcore/home/hyprland.nix | `follow_mouse` | `1` |
| hosts/kernelcore/home/hyprland.nix | `sensitivity` | `1.0` |
| hosts/kernelcore/home/hyprland.nix | `accel_profile` | `"flat"` |
| hosts/kernelcore/home/hyprland.nix | `touchpad` | `{` |
| hosts/kernelcore/home/hyprland.nix | `natural_scroll` | `false` |
| hosts/kernelcore/home/hyprland.nix | `disable_while_typing` | `true` |
| hosts/kernelcore/home/hyprland.nix | `tap-to-click` | `true` |
| hosts/kernelcore/home/hyprland.nix | `general` | `{` |
| hosts/kernelcore/home/hyprland.nix | `gaps_out` | `16` |
| hosts/kernelcore/home/hyprland.nix | `border_size` | `1` |
| hosts/kernelcore/home/hyprland.nix | `layout` | `"dwindle"` |
| hosts/kernelcore/home/hyprland.nix | `allow_tearing` | `false` |
| hosts/kernelcore/home/hyprland.nix | `resize_on_border` | `true` |
| hosts/kernelcore/home/hyprland.nix | `decoration` | `{` |
| hosts/kernelcore/home/hyprland.nix | `rounding` | `12` |
| hosts/kernelcore/home/hyprland.nix | `blur` | `{` |
| hosts/kernelcore/home/hyprland.nix | `enabled` | `true` |
| hosts/kernelcore/home/hyprland.nix | `size` | `10` |
| hosts/kernelcore/home/hyprland.nix | `passes` | `3` |
| hosts/kernelcore/home/hyprland.nix | `new_optimizations` | `true` |
| hosts/kernelcore/home/hyprland.nix | `xray` | `true` |
| hosts/kernelcore/home/hyprland.nix | `ignore_opacity` | `false` |
| hosts/kernelcore/home/hyprland.nix | `noise` | `0.02` |
| hosts/kernelcore/home/hyprland.nix | `contrast` | `0.9` |
| hosts/kernelcore/home/hyprland.nix | `brightness` | `0.8` |
| hosts/kernelcore/home/hyprland.nix | `vibrancy` | `0.2` |
| hosts/kernelcore/home/hyprland.nix | `vibrancy_darkness` | `0.5` |
| hosts/kernelcore/home/hyprland.nix | `special` | `true` |
| hosts/kernelcore/home/hyprland.nix | `popups` | `true` |
| hosts/kernelcore/home/hyprland.nix | `active_opacity` | `0.92` |
| hosts/kernelcore/home/hyprland.nix | `inactive_opacity` | `0.88` |
| hosts/kernelcore/home/hyprland.nix | `fullscreen_opacity` | `1.0` |
| hosts/kernelcore/home/hyprland.nix | `shadow` | `{` |
| hosts/kernelcore/home/hyprland.nix | `enabled` | `true` |
| hosts/kernelcore/home/hyprland.nix | `range` | `20` |
| hosts/kernelcore/home/hyprland.nix | `render_power` | `3` |
| hosts/kernelcore/home/hyprland.nix | `offset` | `"0 4"` |
| hosts/kernelcore/home/hyprland.nix | `color` | `"rgba(00000066)"` |
| hosts/kernelcore/home/hyprland.nix | `color_inactive` | `"rgba(00000044)"` |
| hosts/kernelcore/home/hyprland.nix | `dim_inactive` | `true` |
| hosts/kernelcore/home/hyprland.nix | `dim_strength` | `0.15` |
| hosts/kernelcore/home/hyprland.nix | `animations` | `{` |
| hosts/kernelcore/home/hyprland.nix | `enabled` | `true` |
| hosts/kernelcore/home/hyprland.nix | `bezier` | `[` |
| hosts/kernelcore/home/hyprland.nix | `animation` | `[` |
| hosts/kernelcore/home/hyprland.nix | `dwindle` | `{` |
| hosts/kernelcore/home/hyprland.nix | `pseudotile` | `true` |
| hosts/kernelcore/home/hyprland.nix | `preserve_split` | `true` |
| hosts/kernelcore/home/hyprland.nix | `force_split` | `2` |
| hosts/kernelcore/home/hyprland.nix | `smart_split` | `true` |
| hosts/kernelcore/home/hyprland.nix | `smart_resizing` | `true` |
| hosts/kernelcore/home/hyprland.nix | `master` | `{` |
| hosts/kernelcore/home/hyprland.nix | `new_status` | `"master"` |
| hosts/kernelcore/home/hyprland.nix | `mfact` | `0.55` |
| hosts/kernelcore/home/hyprland.nix | `layerrule` | `[` |
| hosts/kernelcore/home/hyprland.nix | `windowrulev2` | `[` |
| hosts/kernelcore/home/hyprland.nix | `misc` | `{` |
| hosts/kernelcore/home/hyprland.nix | `force_default_wallpaper` | `0` |
| hosts/kernelcore/home/hyprland.nix | `disable_hyprland_logo` | `true` |
| hosts/kernelcore/home/hyprland.nix | `disable_splash_rendering` | `true` |
| hosts/kernelcore/home/hyprland.nix | `mouse_move_enables_dpms` | `true` |
| hosts/kernelcore/home/hyprland.nix | `key_press_enables_dpms` | `true` |
| hosts/kernelcore/home/hyprland.nix | `vrr` | `1` |
| hosts/kernelcore/home/hyprland.nix | `vfr` | `true` |
| hosts/kernelcore/home/hyprland.nix | `focus_on_activate` | `true` |
| hosts/kernelcore/home/hyprland.nix | `animate_manual_resizes` | `true` |
| hosts/kernelcore/home/hyprland.nix | `animate_mouse_windowdragging` | `true` |
| hosts/kernelcore/home/hyprland.nix | `new_window_takes_over_fullscreen` | `2` |
| hosts/kernelcore/home/hyprland.nix | `cursor` | `{` |
| hosts/kernelcore/home/hyprland.nix | `no_hardware_cursors` | `true` |
| hosts/kernelcore/home/hyprland.nix | `enable_hyprcursor` | `true` |
| hosts/kernelcore/home/hyprland.nix | `hide_on_key_press` | `true` |
| hosts/kernelcore/home/hyprland.nix | `inactive_timeout` | `5` |
| hosts/kernelcore/home/hyprland.nix | `debug` | `{` |
| hosts/kernelcore/home/hyprland.nix | `disable_logs` | `true` |
| hosts/kernelcore/home/hyprland.nix | `disable_time` | `true` |
| hosts/kernelcore/home/hyprland.nix | `bind` | `[` |
| hosts/kernelcore/home/hyprland.nix | `binde` | `[` |
| hosts/kernelcore/home/hyprland.nix | `bindm` | `[` |
| modules/packages/js-packages/gemini-cli.nix | `environment.systemPackages` | `[` |
| modules/packages/js-packages/gemini-cli.nix | `pname` | `"gemini-cli"` |
| modules/packages/js-packages/gemini-cli.nix | `version` | `sources.gemini-cli.version` |
| modules/packages/js-packages/gemini-cli.nix | `src` | `sources.gemini-cli.src` |
| modules/packages/js-packages/gemini-cli.nix | `npmDepsHash` | `"sha256-OCSYOxMyBkb4ygeys4GhNwVKOWRGhgmao4QBrpFpt74="` |
| modules/packages/js-packages/gemini-cli.nix | `nodeLinker` | `"pnpm"` |
| modules/packages/js-packages/gemini-cli.nix | `npmFlags` | `[ "--legacy-peer-deps" ]` |
| modules/packages/js-packages/gemini-cli.nix | `dontCheckNoBrokenSymlinks` | `true` |
| modules/packages/js-packages/gemini-cli.nix | `postInstall` | `''` |
| modules/packages/js-packages/gemini-cli.nix | `description` | `"CLI tool for Google's Gemini Generative AI API"` |
| modules/packages/js-packages/gemini-cli.nix | `homepage` | `"https://github.com/google-gemini/gemini-cli"` |
| modules/packages/js-packages/gemini-cli.nix | `license` | `licenses.asl20` |
| modules/packages/js-packages/gemini-cli.nix | `maintainers` | `[ marcosfpina ]` |
| modules/packages/js-packages/gemini-cli.nix | `platforms` | `platforms.all` |
| modules/system/memory.nix | `kernelcore.system.memory` | `{` |
| modules/system/memory.nix | `default` | `true` |
| modules/system/memory.nix | `description` | `"Enable ZRAM compressed swap"` |
| modules/system/memory.nix | `boot.kernel.sysctl` | `{` |
| modules/system/memory.nix | `"vm.panic_on_oom"` | `0` |
| modules/system/memory.nix | `services.earlyoom` | `{` |
| modules/system/memory.nix | `enable` | `true` |
| modules/system/memory.nix | `freeMemThreshold` | `5; # Kill processes when <5% RAM free (was 8%)` |
| modules/system/memory.nix | `freeSwapThreshold` | `10; # Kill when <10% swap free (was 20%)` |
| modules/system/memory.nix | `enableNotifications` | `true` |
| modules/system/memory.nix | `extraArgs` | `[` |
| modules/system/memory.nix | `enable` | `true` |
| modules/system/memory.nix | `algorithm` | `"zstd"; # Best compression/speed balance` |
| modules/system/memory.nix | `memoryPercent` | `50; # Use 50% of RAM for compressed swap (was 25%)` |
| modules/system/memory.nix | `priority` | `10; # Higher priority than disk swap` |
| modules/system/memory.nix | `swapDevices` | `[` |
| modules/system/memory.nix | `device` | `"/swapfile"` |
| modules/system/memory.nix | `size` | `16096` |
| modules/system/memory.nix | `priority` | `5` |
| modules/system/memory.nix | `services.journald.extraConfig` | `''` |
| modules/system/memory.nix | `SystemMaxUse` | `2G` |
| modules/system/memory.nix | `SystemMaxFileSize` | `200M` |
| modules/system/memory.nix | `MaxRetentionSec` | `1month` |
| modules/system/memory.nix | `MaxFileSec` | `1week` |
| modules/system/memory.nix | `systemd.services.memory-pressure-relief` | `{` |
| modules/system/memory.nix | `description` | `"Automatic Memory Pressure Relief"` |
| modules/system/memory.nix | `serviceConfig` | `{` |
| modules/system/memory.nix | `Type` | `"oneshot"` |
| modules/system/memory.nix | `systemd.timers.memory-pressure-relief` | `{` |
| modules/system/memory.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/system/memory.nix | `timerConfig` | `{` |
| modules/system/memory.nix | `OnBootSec` | `"5min"` |
| modules/system/memory.nix | `OnUnitActiveSec` | `"5min"` |
| modules/system/memory.nix | `Unit` | `"memory-pressure-relief.service"` |
| modules/system/memory.nix | `systemd.services.log-cleanup` | `{` |
| modules/system/memory.nix | `description` | `"Aggressive Log Cleanup"` |
| modules/system/memory.nix | `serviceConfig` | `{` |
| modules/system/memory.nix | `Type` | `"oneshot"` |
| modules/system/memory.nix | `systemd.timers.log-cleanup` | `{` |
| modules/system/memory.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/system/memory.nix | `timerConfig` | `{` |
| modules/system/memory.nix | `OnCalendar` | `"daily"` |
| modules/system/memory.nix | `OnBootSec` | `"10min"` |
| modules/system/memory.nix | `Persistent` | `true` |
| modules/system/memory.nix | `Unit` | `"log-cleanup.service"` |
| modules/system/aliases.nix | `environment.etc` | `{` |
| modules/system/aliases.nix | `"profile.d/void.sh"` | `{` |
| modules/system/aliases.nix | `source` | `./bash/void.sh` |
| modules/system/aliases.nix | `mode` | `"0755"` |
| modules/system/aliases.nix | `users.users.kernelcore.extraGroups` | `[ "docker" ]` |
| modules/packages/js-packages/js-packages.nix | `description` | `"Package version"` |
| modules/packages/js-packages/js-packages.nix | `type` | `sharedTypes.sourceType` |
| modules/packages/js-packages/js-packages.nix | `description` | `"Hash of npm dependencies (run 'prefetch-npm-deps package-lock.json')"` |
| modules/packages/js-packages/js-packages.nix | `default` | `[ ]` |
| modules/packages/js-packages/js-packages.nix | `description` | `"Extra flags for npm install"` |
| modules/packages/js-packages/js-packages.nix | `default` | `[ ]` |
| modules/packages/js-packages/js-packages.nix | `default` | `[ ]` |
| modules/packages/js-packages/js-packages.nix | `type` | `sharedTypes.sandboxType` |
| modules/packages/js-packages/js-packages.nix | `default` | `{` |
| modules/packages/js-packages/js-packages.nix | `enable` | `true` |
| modules/packages/js-packages/js-packages.nix | `type` | `sharedTypes.wrapperType name` |
| modules/packages/js-packages/js-packages.nix | `default` | `{ }` |
| modules/packages/js-packages/js-packages.nix | `default` | `{ }` |
| modules/packages/js-packages/js-packages.nix | `description` | `"Js packages to install and manage"` |
| modules/packages/js-packages/js-packages.nix | `enabledPackages` | `filterAttrs (_: pkg: pkg.enable) cfg.packages` |
| modules/packages/js-packages/js-packages.nix | `builtPackages` | `mapAttrs (name: pkg: builder.buildNpm name pkg) enabledPackages` |
| modules/packages/js-packages/js-packages.nix | `environment.systemPackages` | `attrValues builtPackages` |
| modules/services/default.nix | `services.prometheus` | `{` |
| modules/services/default.nix | `enable` | `true` |
| modules/services/default.nix | `port` | `9090` |
| modules/services/default.nix | `exporters` | `{` |
| modules/services/default.nix | `node` | `{` |
| modules/services/default.nix | `enable` | `true` |
| modules/services/default.nix | `port` | `9100` |
| modules/services/default.nix | `scrapeConfigs` | `[` |
| modules/services/default.nix | `job_name` | `"node"` |
| modules/services/default.nix | `services.grafana` | `{` |
| modules/services/default.nix | `enable` | `true` |
| modules/services/default.nix | `settings` | `{` |
| modules/services/default.nix | `server` | `{` |
| modules/services/default.nix | `http_port` | `4000` |
| modules/applications/firefox-privacy.nix | `default` | `true` |
| modules/applications/firefox-privacy.nix | `description` | `"Integração PAM com Google Authenticator para autenticação local reforçada."` |
| modules/applications/firefox-privacy.nix | `default` | `true` |
| modules/applications/firefox-privacy.nix | `description` | `"Ativa scripts de hardening user.js e isolamento via Firejail."` |
| modules/applications/firefox-privacy.nix | `hardware.graphics` | `{` |
| modules/applications/firefox-privacy.nix | `enable` | `true` |
| modules/applications/firefox-privacy.nix | `environment.sessionVariables` | `{` |
| modules/applications/firefox-privacy.nix | `MOZ_DISABLE_RDD_SANDBOX` | `"1"; # Necessário para VA-API funcionar corretamente em alguns contextos` |
| modules/applications/firefox-privacy.nix | `LIBVA_DRIVER_NAME` | `"iHD";     # Força o driver Intel Media (evita fallback para i965 antigo)` |
| modules/applications/firefox-privacy.nix | `programs.firefox` | `{` |
| modules/applications/firefox-privacy.nix | `enable` | `true` |
| modules/applications/firefox-privacy.nix | `policies` | `{` |
| modules/applications/firefox-privacy.nix | `DisableTelemetry` | `true` |
| modules/applications/firefox-privacy.nix | `DisableFirefoxStudies` | `true` |
| modules/applications/firefox-privacy.nix | `DisablePocket` | `true` |
| modules/applications/firefox-privacy.nix | `DisableFirefoxAccounts` | `true; # Remove Sync totalmente (Self-hosted mindset)` |
| modules/applications/firefox-privacy.nix | `DisableFormHistory` | `true` |
| modules/applications/firefox-privacy.nix | `DisplayBookmarksToolbar` | `"never"` |
| modules/applications/firefox-privacy.nix | `DisplayMenuBar` | `"never"` |
| modules/applications/firefox-privacy.nix | `DontCheckDefaultBrowser` | `true` |
| modules/applications/firefox-privacy.nix | `DNSOverHTTPS` | `{` |
| modules/applications/firefox-privacy.nix | `Enabled` | `true` |
| modules/applications/firefox-privacy.nix | `ProviderURL` | `"https://dns.quad9.net/dns-query"; # Quad9 (Privacidade e Segurança)` |
| modules/applications/firefox-privacy.nix | `Locked` | `true` |
| modules/applications/firefox-privacy.nix | `ExtensionSettings` | `{` |
| modules/applications/firefox-privacy.nix | `"uBlock0@raymondhill.net"` | `{` |
| modules/applications/firefox-privacy.nix | `installation_mode` | `"force_installed"` |
| modules/applications/firefox-privacy.nix | `install_url` | `"https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"` |
| modules/applications/firefox-privacy.nix | `installation_mode` | `"force_installed"` |
| modules/applications/firefox-privacy.nix | `install_url` | `"https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi"` |
| modules/applications/firefox-privacy.nix | `installation_mode` | `"force_installed"` |
| modules/applications/firefox-privacy.nix | `install_url` | `"https://addons.mozilla.org/firefox/downloads/latest/skip-redirect/latest.xpi"` |
| modules/applications/firefox-privacy.nix | `preferences` | `{` |
| modules/applications/firefox-privacy.nix | `"gfx.webrender.all"` | `true;                # Força WebRender (Compositor GPU Rust)` |
| modules/applications/firefox-privacy.nix | `security.pam.oath` | `mkIf cfg.enableGoogleAuthenticator {` |
| modules/applications/firefox-privacy.nix | `enable` | `true` |
| modules/applications/firefox-privacy.nix | `digits` | `6` |
| modules/applications/firefox-privacy.nix | `window` | `30` |
| modules/applications/firefox-privacy.nix | `mode` | `"0755"` |
| modules/applications/firefox-privacy.nix | `text` | `''` |
| modules/applications/firefox-privacy.nix | `PROFILE_DIR` | `"$HOME/.mozilla/firefox"` |
| modules/applications/firefox-privacy.nix | `DEFAULT_PROFILE` | `$(grep -oP "(?<=Path=).*" "$PROFILE_DIR/profiles.ini" | head -1)` |
| modules/applications/firefox-privacy.nix | `text` | `''` |
| hosts/kernelcore/home/brave.nix | `programs.chromium` | `{` |
| hosts/kernelcore/home/brave.nix | `enable` | `true` |
| hosts/kernelcore/home/brave.nix | `commandLineArgs` | `[` |
| hosts/kernelcore/home/brave.nix | `"--enable-features` | `VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,ParallelDownloading"` |
| hosts/kernelcore/home/brave.nix | `"--ozone-platform-hint` | `auto"` |
| hosts/kernelcore/home/brave.nix | `"--password-store` | `gnome-libsecret"` |
| hosts/kernelcore/home/brave.nix | `extensions` | `[` |
| hosts/kernelcore/home/brave.nix | `xdg.mimeApps.defaultApplications` | `{` |
| hosts/kernelcore/home/brave.nix | `"text/html"` | `"brave-browser.desktop"` |
| modules/services/users/claude-code.nix | `default` | `"claude-code"` |
| modules/services/users/claude-code.nix | `description` | `"Username for Claude Code service"` |
| modules/services/users/claude-code.nix | `default` | `"/var/lib/claude-code"` |
| modules/services/users/claude-code.nix | `description` | `"Home directory for Claude Code user"` |
| modules/services/users/claude-code.nix | `default` | `[` |
| modules/services/users/claude-code.nix | `description` | `"Groups to add Claude Code user to"` |
| modules/services/users/claude-code.nix | `default` | `true` |
| modules/services/users/claude-code.nix | `description` | `"Allow passwordless sudo for system operations"` |
| modules/services/users/claude-code.nix | `default` | `true` |
| modules/services/users/claude-code.nix | `description` | `"Add user to Nix trusted users for builds"` |
| modules/services/users/claude-code.nix | `users.users.${cfg.userName}` | `{` |
| modules/services/users/claude-code.nix | `isSystemUser` | `true` |
| modules/services/users/claude-code.nix | `description` | `"Claude Code AI Assistant - System Operations User"` |
| modules/services/users/claude-code.nix | `home` | `cfg.homeDirectory` |
| modules/services/users/claude-code.nix | `createHome` | `true` |
| modules/services/users/claude-code.nix | `group` | `cfg.userName` |
| modules/services/users/claude-code.nix | `extraGroups` | `cfg.allowedGroups` |
| modules/services/users/claude-code.nix | `openssh.authorizedKeys.keys` | `[` |
| modules/services/users/claude-code.nix | `security.sudo.extraRules` | `mkIf cfg.sudoNoPasswd [` |
| modules/services/users/claude-code.nix | `users` | `[ cfg.userName ]` |
| modules/services/users/claude-code.nix | `commands` | `[` |
| modules/services/users/claude-code.nix | `nix.settings.trusted-users` | `mkIf cfg.nixTrusted [ cfg.userName ]` |
| modules/services/users/claude-code.nix | `systemd.tmpfiles.rules` | `[` |
| modules/services/users/claude-code.nix | `environment.variables` | `{` |
| modules/services/users/claude-code.nix | `CLAUDE_CODE_USER` | `cfg.userName` |
| modules/services/users/claude-code.nix | `CLAUDE_CODE_HOME` | `cfg.homeDirectory` |
| modules/services/users/claude-code.nix | `ANTHROPIC_MODEL` | `"claude-sonnet-4-5-20250929"` |
| modules/hardware/i915-governor/default.nix | `thresholds` | `{` |
| modules/hardware/i915-governor/default.nix | `default` | `90` |
| modules/hardware/i915-governor/default.nix | `description` | `"Porcentagem de uso da iGPU para iniciar throttling"` |
| modules/hardware/i915-governor/default.nix | `default` | `80` |
| modules/hardware/i915-governor/default.nix | `description` | `"Pressão de memória (PSI) para disparar compactação"` |
| modules/hardware/i915-governor/default.nix | `warnings` | `[ "i915-governor: Package not available - project moved to external repository" ]` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `programs.kitty` | `{` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `font` | `{` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `name` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `size` | `13.5` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `settings` | `{` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `background_opacity` | `"0.92"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `background_blur` | `10` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `dynamic_background_opacity` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `dim_opacity` | `"0.85"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `inactive_text_alpha` | `"0.9"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `window_padding_width` | `14` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `hide_window_decorations` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `window_border_width` | `"1pt"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `draw_minimal_borders` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `confirm_os_window_close` | `0` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `cursor` | `"#00d4ff"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `cursor_text_color` | `"#0a0a0f"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `cursor_shape` | `"beam"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `cursor_beam_thickness` | `"1.5"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `cursor_blink_interval` | `"0.75"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `cursor_stop_blinking_after` | `0` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `scrollback_lines` | `50000` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `scrollback_pager_history_size` | `100` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `wheel_scroll_multiplier` | `3` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `wheel_scroll_min_lines` | `1` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `touch_scroll_multiplier` | `3` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `mouse_hide_wait` | `3` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `url_color` | `"#00d4ff"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `url_style` | `"curly"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `url_prefixes` | `"file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `detect_urls` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `show_hyperlink_targets` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `copy_on_select` | `"clipboard"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `paste_actions` | `"quote-urls-at-prompt"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `strip_trailing_spaces` | `"smart"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `select_by_word_characters` | `"@-./_~?&=%+#"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `repaint_delay` | `6; # ~166fps cap (slightly above 144Hz)` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `input_delay` | `2` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `sync_to_monitor` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `enable_audio_bell` | `false` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `visual_bell_duration` | `"0.15"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `visual_bell_color` | `"#ff00aa"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `window_alert_on_bell` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `bell_on_tab` | `"🔔 "` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `remember_window_size` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `initial_window_width` | `1200` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `initial_window_height` | `800` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `enabled_layouts` | `"splits,stack,tall,fat,grid,horizontal,vertical"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `window_resize_step_cells` | `2` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `window_resize_step_lines` | `2` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `active_border_color` | `"#00d4ff"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `inactive_border_color` | `"#22222e"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `bell_border_color` | `"#ff00aa"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_bar_edge` | `"bottom"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_bar_style` | `"powerline"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_powerline_style` | `"slanted"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_bar_align` | `"left"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_bar_min_tabs` | `2` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_switch_strategy` | `"previous"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_fade` | `"0.25 0.5 0.75 1"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_separator` | `" ┇ "` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_activity_symbol` | `"󰖲 "` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_title_max_length` | `25` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_title_template` | `"{fmt.fg.tab}{bell_symbol}{activity_symbol}{index}: {title}"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `active_tab_title_template` | `"{fmt.fg._00d4ff}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index}: {title}"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `active_tab_foreground` | `"#ffffff"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `active_tab_background` | `"#12121a"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `active_tab_font_style` | `"bold"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `inactive_tab_foreground` | `"#71717a"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `inactive_tab_background` | `"#0a0a0f"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `inactive_tab_font_style` | `"normal"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_bar_background` | `"#0a0a0f"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `tab_bar_margin_color` | `"#0a0a0f"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `shell_integration` | `"enabled"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `allow_hyperlinks` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `term` | `"xterm-kitty"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `wayland_titlebar_color` | `"background"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `linux_display_server` | `"wayland"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `allow_remote_control` | `"socket-only"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `listen_on` | `"unix:/tmp/kitty-socket"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `clipboard_control` | `"write-clipboard write-primary read-clipboard-ask read-primary-ask"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `clipboard_max_size` | `512` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `notify_on_cmd_finish` | `"unfocused 30.0"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `macos_option_as_alt` | `"both"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `macos_quit_when_last_window_closed` | `false` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `extraConfig` | `''` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `keybindings` | `{` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `"ctrl+shift+c"` | `"copy_to_clipboard"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `shellIntegration` | `{` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `enableBashIntegration` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `enableZshIntegration` | `true` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `mode` | `"enabled"` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `xdg.mimeApps.defaultApplications` | `{` |
| hosts/kernelcore/home/glassmorphism/kitty.nix | `"x-scheme-handler/kitty"` | `"kitty.desktop"` |
| modules/packages/tar-packages/packages/protonpass.nix | `protonpass` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/protonpass.nix | `method` | `"native"` |
| modules/packages/tar-packages/packages/protonpass.nix | `source` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `url` | `"https://proton.me/download/PassDesktop/linux/x64/ProtonPass.tar.gz"` |
| modules/packages/tar-packages/packages/protonpass.nix | `sha256` | `""; # Run rebuild once to get hash, then add it here` |
| modules/packages/tar-packages/packages/protonpass.nix | `wrapper` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `executable` | `"proton-pass"; # Binary name inside tarball` |
| modules/packages/tar-packages/packages/protonpass.nix | `environmentVariables` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `sandbox` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/protonpass.nix | `audit` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/protonpass.nix | `desktopEntry` | `null` |
| modules/packages/tar-packages/packages/protonpass.nix | `meta` | `{` |
| modules/packages/tar-packages/packages/protonpass.nix | `description` | `"Desktop application for Proton Pass"` |
| modules/packages/tar-packages/packages/protonpass.nix | `homepage` | `"https://proton.me/pass"` |
| modules/packages/tar-packages/packages/protonpass.nix | `license` | `lib.licenses.gpl3Plus` |
| modules/packages/tar-packages/packages/protonpass.nix | `platforms` | `[ "x86_64-linux" ]` |
| modules/packages/tar-packages/packages/protonpass.nix | `mainProgram` | `"proton-pass"` |
| hosts/kernelcore/home/alacritty.nix | `programs.alacritty` | `{` |
| hosts/kernelcore/home/alacritty.nix | `enable` | `true` |
| hosts/kernelcore/home/alacritty.nix | `settings` | `{` |
| hosts/kernelcore/home/alacritty.nix | `general` | `{` |
| hosts/kernelcore/home/alacritty.nix | `import` | `[ ]` |
| hosts/kernelcore/home/alacritty.nix | `env` | `{` |
| hosts/kernelcore/home/alacritty.nix | `TERM` | `"alacritty"` |
| hosts/kernelcore/home/alacritty.nix | `COLORTERM` | `"truecolor"` |
| hosts/kernelcore/home/alacritty.nix | `window` | `{` |
| hosts/kernelcore/home/alacritty.nix | `padding` | `{` |
| hosts/kernelcore/home/alacritty.nix | `x` | `14` |
| hosts/kernelcore/home/alacritty.nix | `y` | `16` |
| hosts/kernelcore/home/alacritty.nix | `dynamic_padding` | `true` |
| hosts/kernelcore/home/alacritty.nix | `decorations` | `"None"` |
| hosts/kernelcore/home/alacritty.nix | `opacity` | `0.94` |
| hosts/kernelcore/home/alacritty.nix | `blur` | `true; # Enable background blur (Wayland/compositor dependent)` |
| hosts/kernelcore/home/alacritty.nix | `startup_mode` | `"Maximized"` |
| hosts/kernelcore/home/alacritty.nix | `title` | `"Alacritty + Zellij"` |
| hosts/kernelcore/home/alacritty.nix | `dynamic_title` | `true` |
| hosts/kernelcore/home/alacritty.nix | `class` | `{` |
| hosts/kernelcore/home/alacritty.nix | `instance` | `"Alacritty"` |
| hosts/kernelcore/home/alacritty.nix | `general` | `"alacritty-main"` |
| hosts/kernelcore/home/alacritty.nix | `resize_increments` | `true` |
| hosts/kernelcore/home/alacritty.nix | `scrolling` | `{` |
| hosts/kernelcore/home/alacritty.nix | `history` | `50000; # Large history for Zellij scrollback` |
| hosts/kernelcore/home/alacritty.nix | `multiplier` | `3` |
| hosts/kernelcore/home/alacritty.nix | `font` | `{` |
| hosts/kernelcore/home/alacritty.nix | `size` | `13.5` |
| hosts/kernelcore/home/alacritty.nix | `normal` | `{` |
| hosts/kernelcore/home/alacritty.nix | `family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/alacritty.nix | `style` | `"Medium"` |
| hosts/kernelcore/home/alacritty.nix | `bold` | `{` |
| hosts/kernelcore/home/alacritty.nix | `family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/alacritty.nix | `style` | `"Bold"` |
| hosts/kernelcore/home/alacritty.nix | `italic` | `{` |
| hosts/kernelcore/home/alacritty.nix | `family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/alacritty.nix | `style` | `"Medium Italic"` |
| hosts/kernelcore/home/alacritty.nix | `bold_italic` | `{` |
| hosts/kernelcore/home/alacritty.nix | `family` | `"JetBrainsMono Nerd Font"` |
| hosts/kernelcore/home/alacritty.nix | `style` | `"Bold Italic"` |
| hosts/kernelcore/home/alacritty.nix | `glyph_offset` | `{` |
| hosts/kernelcore/home/alacritty.nix | `x` | `0` |
| hosts/kernelcore/home/alacritty.nix | `y` | `1` |
| hosts/kernelcore/home/alacritty.nix | `offset` | `{` |
| hosts/kernelcore/home/alacritty.nix | `x` | `0` |
| hosts/kernelcore/home/alacritty.nix | `y` | `2` |
| hosts/kernelcore/home/alacritty.nix | `builtin_box_drawing` | `true` |
| hosts/kernelcore/home/alacritty.nix | `cursor` | `{` |
| hosts/kernelcore/home/alacritty.nix | `style` | `{` |
| hosts/kernelcore/home/alacritty.nix | `shape` | `"Beam"` |
| hosts/kernelcore/home/alacritty.nix | `blinking` | `"Always"` |
| hosts/kernelcore/home/alacritty.nix | `vi_mode_style` | `{` |
| hosts/kernelcore/home/alacritty.nix | `shape` | `"Block"` |
| hosts/kernelcore/home/alacritty.nix | `blinking` | `"Off"` |
| hosts/kernelcore/home/alacritty.nix | `thickness` | `0.14` |
| hosts/kernelcore/home/alacritty.nix | `unfocused_hollow` | `false` |
| hosts/kernelcore/home/alacritty.nix | `blink_interval` | `750` |
| hosts/kernelcore/home/alacritty.nix | `blink_timeout` | `0; # Never stop blinking` |
| hosts/kernelcore/home/alacritty.nix | `selection` | `{` |
| hosts/kernelcore/home/alacritty.nix | `save_to_clipboard` | `true` |
| hosts/kernelcore/home/alacritty.nix | `semantic_escape_chars` | `",│`|:\"' ()[]{}<>\\t"` |
| hosts/kernelcore/home/alacritty.nix | `bell` | `{` |
| hosts/kernelcore/home/alacritty.nix | `animation` | `"EaseOutSine"` |
| hosts/kernelcore/home/alacritty.nix | `duration` | `120` |
| hosts/kernelcore/home/alacritty.nix | `color` | `"#ff00aa"; # Glassmorphism magenta` |
| hosts/kernelcore/home/alacritty.nix | `colors` | `{` |
| hosts/kernelcore/home/alacritty.nix | `primary` | `{` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"#e4e4e7"` |
| hosts/kernelcore/home/alacritty.nix | `bright_foreground` | `"#ffffff"` |
| hosts/kernelcore/home/alacritty.nix | `dim_foreground` | `"#a1a1aa"` |
| hosts/kernelcore/home/alacritty.nix | `cursor` | `{` |
| hosts/kernelcore/home/alacritty.nix | `text` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `cursor` | `"#00d4ff"` |
| hosts/kernelcore/home/alacritty.nix | `vi_mode_cursor` | `{` |
| hosts/kernelcore/home/alacritty.nix | `text` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `cursor` | `"#7c3aed"` |
| hosts/kernelcore/home/alacritty.nix | `selection` | `{` |
| hosts/kernelcore/home/alacritty.nix | `text` | `"#ffffff"` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#7c3aed"` |
| hosts/kernelcore/home/alacritty.nix | `search` | `{` |
| hosts/kernelcore/home/alacritty.nix | `matches` | `{` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#00d4ff"` |
| hosts/kernelcore/home/alacritty.nix | `focused_match` | `{` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#ff00aa"` |
| hosts/kernelcore/home/alacritty.nix | `footer_bar` | `{` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#12121a"` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"#e4e4e7"` |
| hosts/kernelcore/home/alacritty.nix | `line_indicator` | `{` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"None"` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"None"` |
| hosts/kernelcore/home/alacritty.nix | `hints` | `{` |
| hosts/kernelcore/home/alacritty.nix | `start` | `{` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#00d4ff"` |
| hosts/kernelcore/home/alacritty.nix | `end` | `{` |
| hosts/kernelcore/home/alacritty.nix | `foreground` | `"#0a0a0f"` |
| hosts/kernelcore/home/alacritty.nix | `background` | `"#7c3aed"` |
| hosts/kernelcore/home/alacritty.nix | `normal` | `{` |
| hosts/kernelcore/home/alacritty.nix | `black` | `"#1a1a24"; # Dark surface` |
| hosts/kernelcore/home/alacritty.nix | `red` | `"#ff00aa"; # Magenta (error/danger)` |
| hosts/kernelcore/home/alacritty.nix | `green` | `"#22c55e"; # Success green` |
| hosts/kernelcore/home/alacritty.nix | `yellow` | `"#eab308"; # Warning yellow` |
| hosts/kernelcore/home/alacritty.nix | `blue` | `"#3b82f6"; # Info blue` |
| hosts/kernelcore/home/alacritty.nix | `cyan` | `"#00d4ff"; # Electric cyan (primary)` |
| hosts/kernelcore/home/alacritty.nix | `white` | `"#a1a1aa"; # Muted text` |
| hosts/kernelcore/home/alacritty.nix | `bright` | `{` |
| hosts/kernelcore/home/alacritty.nix | `black` | `"#22222e"; # Elevated surface` |
| hosts/kernelcore/home/alacritty.nix | `red` | `"#f472b6"; # Light magenta` |
| hosts/kernelcore/home/alacritty.nix | `green` | `"#4ade80"; # Bright green` |
| hosts/kernelcore/home/alacritty.nix | `yellow` | `"#facc15"; # Bright yellow` |
| hosts/kernelcore/home/alacritty.nix | `blue` | `"#60a5fa"; # Bright blue` |
| hosts/kernelcore/home/alacritty.nix | `magenta` | `"#a78bfa"; # Light violet` |
| hosts/kernelcore/home/alacritty.nix | `cyan` | `"#67e8f9"; # Light cyan` |
| hosts/kernelcore/home/alacritty.nix | `white` | `"#ffffff"; # Pure white` |
| hosts/kernelcore/home/alacritty.nix | `dim` | `{` |
| hosts/kernelcore/home/alacritty.nix | `black` | `"#0a0a0f"; # Deepest background` |
| hosts/kernelcore/home/alacritty.nix | `red` | `"#be185d"; # Dark magenta` |
| hosts/kernelcore/home/alacritty.nix | `green` | `"#166534"; # Dark green` |
| hosts/kernelcore/home/alacritty.nix | `yellow` | `"#a16207"; # Dark yellow` |
| hosts/kernelcore/home/alacritty.nix | `blue` | `"#1e40af"; # Dark blue` |
| hosts/kernelcore/home/alacritty.nix | `magenta` | `"#5b21b6"; # Dark violet` |
| hosts/kernelcore/home/alacritty.nix | `cyan` | `"#0891b2"; # Dark cyan` |
| hosts/kernelcore/home/alacritty.nix | `white` | `"#71717a"; # Disabled text` |
| hosts/kernelcore/home/alacritty.nix | `terminal` | `{` |
| hosts/kernelcore/home/alacritty.nix | `osc52` | `"CopyPaste"` |
| hosts/kernelcore/home/alacritty.nix | `mouse` | `{` |
| hosts/kernelcore/home/alacritty.nix | `hide_when_typing` | `true` |
| hosts/kernelcore/home/alacritty.nix | `bindings` | `[` |
| hosts/kernelcore/home/alacritty.nix | `mouse` | `"Middle"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"PasteSelection"` |
| hosts/kernelcore/home/alacritty.nix | `mouse` | `"Right"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"Paste"` |
| hosts/kernelcore/home/alacritty.nix | `debug` | `{` |
| hosts/kernelcore/home/alacritty.nix | `render_timer` | `false` |
| hosts/kernelcore/home/alacritty.nix | `persistent_logging` | `false` |
| hosts/kernelcore/home/alacritty.nix | `log_level` | `"Warn"` |
| hosts/kernelcore/home/alacritty.nix | `print_events` | `false` |
| hosts/kernelcore/home/alacritty.nix | `highlight_damage` | `false` |
| hosts/kernelcore/home/alacritty.nix | `keyboard.bindings` | `[` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Return"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"SpawnNewInstance"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Space"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"ToggleViMode"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Plus"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"IncreaseFontSize"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Minus"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"DecreaseFontSize"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Key0"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"ResetFontSize"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"F11"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"ToggleFullscreen"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"V"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"Paste"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"C"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"Copy"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Insert"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"PasteSelection"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"F"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"SearchForward"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"B"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"SearchBackward"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"L"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control"` |
| hosts/kernelcore/home/alacritty.nix | `chars` | `"\\u000c"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"N"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"CreateNewWindow"` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"Q"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `action` | `"Quit"` |
| hosts/kernelcore/home/alacritty.nix | `hints` | `{` |
| hosts/kernelcore/home/alacritty.nix | `enabled` | `[` |
| hosts/kernelcore/home/alacritty.nix | `regex` | `"(ipfs:|ipns:|magnet:|mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^\\\\s<>\"{}|\\\\\\\\^`]+"` |
| hosts/kernelcore/home/alacritty.nix | `hyperlinks` | `true` |
| hosts/kernelcore/home/alacritty.nix | `post_processing` | `true` |
| hosts/kernelcore/home/alacritty.nix | `command` | `"Copy"` |
| hosts/kernelcore/home/alacritty.nix | `mouse` | `{` |
| hosts/kernelcore/home/alacritty.nix | `enabled` | `true` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"None"` |
| hosts/kernelcore/home/alacritty.nix | `binding` | `{` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"U"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `regex` | `"(?:[0-9]{1,3}\\\\.){3}[0-9]{1,3}"` |
| hosts/kernelcore/home/alacritty.nix | `command` | `"Copy"` |
| hosts/kernelcore/home/alacritty.nix | `mouse` | `{` |
| hosts/kernelcore/home/alacritty.nix | `enabled` | `true` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control"` |
| hosts/kernelcore/home/alacritty.nix | `binding` | `{` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"I"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `regex` | `"(/?[a-zA-Z0-9_.-]+)+"` |
| hosts/kernelcore/home/alacritty.nix | `command` | `"Copy"` |
| hosts/kernelcore/home/alacritty.nix | `mouse` | `{` |
| hosts/kernelcore/home/alacritty.nix | `enabled` | `true` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Shift"` |
| hosts/kernelcore/home/alacritty.nix | `binding` | `{` |
| hosts/kernelcore/home/alacritty.nix | `key` | `"P"` |
| hosts/kernelcore/home/alacritty.nix | `mods` | `"Control|Shift"` |
| hosts/kernelcore/home/alacritty.nix | `xdg.mimeApps` | `{` |
| hosts/kernelcore/home/alacritty.nix | `enable` | `true` |
| hosts/kernelcore/home/alacritty.nix | `defaultApplications` | `{` |
| hosts/kernelcore/home/alacritty.nix | `"x-scheme-handler/terminal"` | `"Alacritty.desktop"` |
| modules/packages/js-packages/builder.nix | `if pkg.source.path !` | `null then` |
| modules/packages/js-packages/builder.nix | `else if pkg.source.url !` | `null then` |
| modules/packages/js-packages/builder.nix | `url` | `pkg.source.url` |
| modules/packages/js-packages/builder.nix | `sha256` | `pkg.source.sha256` |
| modules/packages/js-packages/builder.nix | `pname` | `name` |
| modules/packages/js-packages/builder.nix | `version` | `pkg.version` |
| modules/packages/js-packages/builder.nix | `src` | `src` |
| modules/packages/js-packages/builder.nix | `npmDepsHash` | `pkg.npmDepsHash` |
| modules/packages/js-packages/builder.nix | `npmFlags` | `pkg.npmFlags` |
| modules/packages/js-packages/builder.nix | `dontCheckNoBrokenSymlinks` | `true; # Common fix for some packages` |
| modules/packages/js-packages/builder.nix | `executable` | `if pkg.wrapper.executable != null then pkg.wrapper.executable else "bin/${name}"` |
| modules/packages/js-packages/builder.nix | `relExecutable` | `removePrefix "/" executable` |
| modules/packages/js-packages/builder.nix | `blockArgs` | `sandboxLib.mkHardwareBlockArgs pkg.sandbox.blockHardware` |
| modules/packages/js-packages/builder.nix | `allowArgs` | `sandboxLib.mkPathAllowArgs pkg.sandbox.allowedPaths` |
| modules/packages/js-packages/builder.nix | `envVars` | `concatStringsSep "\n" (` |
| modules/packages/js-packages/builder.nix | `mapAttrsToList (name: value: "export ${name}` | `'${value}'") pkg.wrapper.environmentVariables` |
| modules/packages/js-packages/builder.nix | `name` | `name` |
| modules/packages/js-packages/builder.nix | `paths` | `[ npmPackage ]` |
| modules/services/gpu-orchestration.nix | `kernelcore.services.gpu-orchestration` | `{` |
| modules/services/gpu-orchestration.nix | `default` | `"docker"` |
| modules/services/gpu-orchestration.nix | `description` | `''` |
| modules/services/gpu-orchestration.nix | `systemd.targets.gpu-local-mode` | `{` |
| modules/services/gpu-orchestration.nix | `description` | `"GPU Local Mode - Systemd services active"` |
| modules/services/gpu-orchestration.nix | `wants` | `[` |
| modules/services/gpu-orchestration.nix | `conflicts` | `[ "gpu-docker-mode.target" ]` |
| modules/services/gpu-orchestration.nix | `systemd.targets.gpu-docker-mode` | `{` |
| modules/services/gpu-orchestration.nix | `description` | `"GPU Docker Mode - Docker containers get GPU priority"` |
| modules/services/gpu-orchestration.nix | `conflicts` | `[` |
| modules/services/gpu-orchestration.nix | `conflicts` | `[ "gpu-docker-mode.target" ]` |
| modules/services/gpu-orchestration.nix | `partOf` | `[ "gpu-local-mode.target" ]` |
| modules/services/gpu-orchestration.nix | `serviceConfig` | `{` |
| modules/services/gpu-orchestration.nix | `TimeoutStopSec` | `"30s"` |
| modules/services/gpu-orchestration.nix | `KillMode` | `"mixed"` |
| modules/services/gpu-orchestration.nix | `conflicts` | `[ "gpu-docker-mode.target" ]` |
| modules/services/gpu-orchestration.nix | `partOf` | `[ "gpu-local-mode.target" ]` |
| modules/services/gpu-orchestration.nix | `serviceConfig` | `{` |
| modules/services/gpu-orchestration.nix | `TimeoutStopSec` | `"30s"` |
| modules/services/gpu-orchestration.nix | `KillMode` | `"mixed"` |
| modules/services/gpu-orchestration.nix | `systemd.services.gpu-orchestration-init` | `{` |
| modules/services/gpu-orchestration.nix | `description` | `"Initialize GPU orchestration mode on boot"` |
| modules/services/gpu-orchestration.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/services/gpu-orchestration.nix | `after` | `[ "network.target" ]` |
| modules/services/gpu-orchestration.nix | `serviceConfig` | `{` |
| modules/services/gpu-orchestration.nix | `Type` | `"oneshot"` |
| modules/services/gpu-orchestration.nix | `RemainAfterExit` | `true` |
| modules/services/gpu-orchestration.nix | `script` | `''` |
| hosts/kernelcore/home/shell/zsh.nix | `programs.zsh` | `{` |
| hosts/kernelcore/home/shell/zsh.nix | `enable` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `autosuggestion.enable` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `syntaxHighlighting.enable` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `enableCompletion` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `history` | `{` |
| hosts/kernelcore/home/shell/zsh.nix | `size` | `10000` |
| hosts/kernelcore/home/shell/zsh.nix | `save` | `20000` |
| hosts/kernelcore/home/shell/zsh.nix | `ignoreDups` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `ignoreSpace` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `extended` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `share` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `defaultKeymap` | `"emacs"` |
| hosts/kernelcore/home/shell/zsh.nix | `completionInit` | `''` |
| hosts/kernelcore/home/shell/zsh.nix | `zstyle ':completion:*' matcher-list 'm:{a-zA-Z}` | `{A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'` |
| hosts/kernelcore/home/shell/zsh.nix | `zstyle ':completion:*:*:kill:*:processes' list-colors '` | `(#b) #([0-9]#)*=0=01;31'` |
| hosts/kernelcore/home/shell/zsh.nix | `oh-my-zsh` | `{` |
| hosts/kernelcore/home/shell/zsh.nix | `enable` | `true` |
| hosts/kernelcore/home/shell/zsh.nix | `plugins` | `[` |
| hosts/kernelcore/home/shell/zsh.nix | `shellAliases` | `{` |
| hosts/kernelcore/home/shell/zsh.nix | `ll` | `"eza -la --icons --git"` |
| hosts/kernelcore/home/shell/zsh.nix | `la` | `"eza -la --icons --git"` |
| hosts/kernelcore/home/shell/zsh.nix | `lt` | `"eza --tree --icons --git"` |
| hosts/kernelcore/home/shell/zsh.nix | `ls` | `"eza --icons"` |
| hosts/kernelcore/home/shell/zsh.nix | `ps` | `"ps auxf"` |
| hosts/kernelcore/home/shell/zsh.nix | `psg` | `"ps aux | grep -v grep | grep -i -e VSZ -e"` |
| hosts/kernelcore/home/shell/zsh.nix | `mkdir` | `"mkdir -p"` |
| hosts/kernelcore/home/shell/zsh.nix | `meminfo` | `"free -m -l -t"` |
| hosts/kernelcore/home/shell/zsh.nix | `cpuinfo` | `"lscpu"` |
| hosts/kernelcore/home/shell/zsh.nix | `ports` | `"netstat -tulanp"` |
| hosts/kernelcore/home/shell/zsh.nix | `listening` | `"lsof -i -P | grep LISTEN"` |
| hosts/kernelcore/home/shell/zsh.nix | `gs` | `"git status"` |
| hosts/kernelcore/home/shell/zsh.nix | `ga` | `"git add"` |
| hosts/kernelcore/home/shell/zsh.nix | `gaa` | `"git add --all"` |
| hosts/kernelcore/home/shell/zsh.nix | `gc` | `"git commit -m"` |
| hosts/kernelcore/home/shell/zsh.nix | `gl` | `"git log --oneline --graph --decorate --all -10"` |
| hosts/kernelcore/home/shell/zsh.nix | `gd` | `"git diff"` |
| hosts/kernelcore/home/shell/zsh.nix | `gco` | `"git checkout"` |
| hosts/kernelcore/home/shell/zsh.nix | `clean` | `"sudo nix-collect-garbage -d && sudo nix-store --gc"` |
| hosts/kernelcore/home/shell/zsh.nix | `cleanold` | `"sudo nix-collect-garbage --delete-older-than 7d"` |
| hosts/kernelcore/home/shell/zsh.nix | `dps` | `"docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"` |
| hosts/kernelcore/home/shell/zsh.nix | `dimg` | `"docker images"` |
| hosts/kernelcore/home/shell/zsh.nix | `dstop` | `"docker stop $(docker ps -q)"` |
| hosts/kernelcore/home/shell/zsh.nix | `dclean` | `"docker system prune -af"` |
| hosts/kernelcore/home/shell/zsh.nix | `dev` | `"cd ~/dev"` |
| hosts/kernelcore/home/shell/zsh.nix | `nx` | `"cd /etc/nixos/"` |
| hosts/kernelcore/home/shell/zsh.nix | `nxbd` | `"sudo nixos-rebuild switch --flake /etc/nixos\#kernelcore --cores 8 --max-jobs 8 --verbose --show-trace --upgrade"` |
| hosts/kernelcore/home/shell/zsh.nix | `tobash` | `"chsh -s $(which bash) && exec bash"` |
| hosts/kernelcore/home/shell/zsh.nix | `tozsh` | `"chsh -s $(which zsh) && exec zsh"` |
| hosts/kernelcore/home/shell/zsh.nix | `reload` | `"source ~/.zshrc"` |
| hosts/kernelcore/home/shell/zsh.nix | `reland` | `"hyprctl reload"` |
| hosts/kernelcore/home/shell/zsh.nix | `t` | `"tree -a -L 2 -C --dirsfirst \` |
| hosts/kernelcore/home/shell/zsh.nix | `git-commit-ai` | `"/etc/nixos/scripts/auto-commit.sh"` |
| hosts/kernelcore/home/shell/zsh.nix | `wayreload` | `"killall waybar && waybar &"` |
| hosts/kernelcore/home/shell/zsh.nix | `aliases` | `"cd /etc/nixos/modules/shell/aliases && ls -la"` |
| hosts/kernelcore/home/shell/zsh.nix | `weather` | `"curl wttr.in"` |
| hosts/kernelcore/home/shell/zsh.nix | `cat` | `"bat"` |
| hosts/kernelcore/home/shell/zsh.nix | `grep` | `"rg"` |
| hosts/kernelcore/home/shell/zsh.nix | `initContent` | `''` |
| hosts/kernelcore/home/shell/zsh.nix | `d` | `"../$d"` |
| hosts/kernelcore/home/shell/zsh.nix | `localVariables` | `{` |
| hosts/kernelcore/home/shell/zsh.nix | `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` | `"fg=#666666"` |
| hosts/kernelcore/home/shell/zsh.nix | `ZSH_AUTOSUGGEST_STRATEGY` | `[` |
| hosts/kernelcore/home/shell/zsh.nix | `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND` | `"bg=green,fg=white,bold"` |
| hosts/kernelcore/home/shell/zsh.nix | `HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND` | `"bg=red,fg=white,bold"` |
| hosts/kernelcore/home/shell/zsh.nix | `source` | `./p10k.zsh` |
| modules/applications/nemo-full.nix | `description` | `"The Nemo package to use"` |
| modules/applications/nemo-full.nix | `description` | `"List of Nemo extensions to install"` |
| modules/applications/nemo-full.nix | `description` | `"Additional packages to support Nemo features"` |
| modules/applications/nemo-full.nix | `default` | `true` |
| modules/applications/nemo-full.nix | `description` | `"Set Nemo as the default file manager"` |
| modules/applications/nemo-full.nix | `plugins` | `{` |
| modules/applications/nemo-full.nix | `default` | `true` |
| modules/applications/nemo-full.nix | `default` | `true` |
| modules/applications/nemo-full.nix | `default` | `true` |
| modules/applications/nemo-full.nix | `default` | `true` |
| modules/applications/nemo-full.nix | `environment.systemPackages` | `[` |
| modules/applications/nemo-full.nix | `services.gvfs` | `{` |
| modules/applications/nemo-full.nix | `xdg.mime` | `mkIf cfg.setDefaultFileManager {` |
| modules/applications/nemo-full.nix | `enable` | `true` |
| modules/applications/nemo-full.nix | `defaultApplications` | `{` |
| modules/applications/nemo-full.nix | `"inode/directory"` | `"nemo.desktop"` |
| modules/applications/nemo-full.nix | `services.dbus.packages` | `[ cfg.package ]` |
| modules/applications/nemo-full.nix | `environment.sessionVariables` | `{` |
| modules/applications/nemo-full.nix | `NEMO_ACTION_VERBOSE` | `"1"` |
| modules/applications/nemo-full.nix | `xdg.portal` | `{` |
| modules/applications/nemo-full.nix | `environment.pathsToLink` | `[` |
| modules/applications/nemo-full.nix | `meta` | `{` |
| modules/security/audit.nix | `boot.kernelParams` | `[` |
| modules/security/audit.nix | `"audit` | `1"` |
| modules/security/audit.nix | `"audit_backlog_limit` | `8192" # Increased from default 1024 to handle boot-time events` |
| modules/security/audit.nix | `security.auditd.enable` | `true` |
| modules/security/audit.nix | `security.audit` | `{` |
| modules/security/audit.nix | `enable` | `true` |
| modules/security/audit.nix | `rules` | `[` |
| modules/security/audit.nix | `"-a always,exit -F arch` | `b64 -S open -F dir=/etc -F success=0 -k unauthed_access"` |
| modules/security/audit.nix | `"-a always,exit -F arch` | `b64 -S init_module -S delete_module -k modules"` |
| modules/security/audit.nix | `security.apparmor` | `{` |
| modules/security/audit.nix | `enable` | `true` |
| modules/security/audit.nix | `killUnconfinedConfinables` | `true` |
| modules/security/audit.nix | `services.journald` | `{` |
| modules/security/audit.nix | `extraConfig` | `''` |
| modules/security/audit.nix | `Storage` | `persistent` |
| modules/security/audit.nix | `Compress` | `yes` |
| modules/security/audit.nix | `SplitMode` | `uid` |
| modules/security/audit.nix | `RateLimitInterval` | `30s` |
| modules/security/audit.nix | `RateLimitBurst` | `1000` |
| modules/security/audit.nix | `SystemMaxUse` | `1G` |
| modules/security/audit.nix | `MaxRetentionSec` | `1month` |
| modules/security/audit.nix | `ForwardToSyslog` | `yes` |
| modules/security/audit.nix | `description` | `"Setup system credential storage"` |
| modules/security/audit.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/security/audit.nix | `serviceConfig` | `{` |
| modules/security/audit.nix | `Type` | `"oneshot"` |
| modules/security/audit.nix | `RemainAfterExit` | `true` |
| hosts/kernelcore/home/home.nix | `myShell` | `{` |
| hosts/kernelcore/home/home.nix | `enable` | `true` |
| hosts/kernelcore/home/home.nix | `defaultShell` | `"zsh"; # Options: "zsh" or "bash"` |
| hosts/kernelcore/home/home.nix | `enablePowerlevel10k` | `true` |
| hosts/kernelcore/home/home.nix | `enableNerdFonts` | `true` |
| hosts/kernelcore/home/home.nix | `home` | `{` |
| hosts/kernelcore/home/home.nix | `username` | `"kernelcore"` |
| hosts/kernelcore/home/home.nix | `homeDirectory` | `"/home/kernelcore"` |
| hosts/kernelcore/home/home.nix | `stateVersion` | `"26.05"` |
| hosts/kernelcore/home/home.nix | `programs` | `{` |
| hosts/kernelcore/home/home.nix | `home-manager.enable` | `true` |
| hosts/kernelcore/home/home.nix | `ripgrep` | `{` |
| hosts/kernelcore/home/home.nix | `enable` | `true` |
| hosts/kernelcore/home/home.nix | `arguments` | `[` |
| hosts/kernelcore/home/home.nix | `"--max-columns` | `150"` |
| hosts/kernelcore/home/home.nix | `"--glob` | `!.git/*"` |
| hosts/kernelcore/home/home.nix | `services` | `{` |
| hosts/kernelcore/home/home.nix | `gpg-agent` | `{` |
| hosts/kernelcore/home/home.nix | `enable` | `true` |
| hosts/kernelcore/home/home.nix | `defaultCacheTtl` | `1800` |
| hosts/kernelcore/home/home.nix | `maxCacheTtl` | `7200` |
| hosts/kernelcore/home/home.nix | `enableSshSupport` | `true` |
| hosts/kernelcore/home/home.nix | `xdg` | `{` |
| hosts/kernelcore/home/home.nix | `enable` | `true` |
| hosts/kernelcore/home/home.nix | `userDirs` | `{` |
| hosts/kernelcore/home/home.nix | `enable` | `true` |
| hosts/kernelcore/home/home.nix | `createDirectories` | `true` |
| hosts/kernelcore/home/home.nix | `mimeApps` | `{` |
| hosts/kernelcore/home/home.nix | `enable` | `true` |
| hosts/kernelcore/home/home.nix | `defaultApplications` | `{` |
| hosts/kernelcore/home/home.nix | `"text/html"` | `"brave-browser.desktop"` |
| hosts/kernelcore/home/home.nix | `home.file` | `{` |
| hosts/kernelcore/home/home.nix | `".vimrc".text` | `''` |
| hosts/kernelcore/home/home.nix | `set tabstop` | `2` |
| hosts/kernelcore/home/home.nix | `set shiftwidth` | `2` |
| hosts/kernelcore/home/home.nix | `set mouse` | `a` |
| hosts/kernelcore/home/home.nix | `set clipboard` | `unnamedplus` |
| hosts/kernelcore/home/home.nix | `Name` | `htop` |
| hosts/kernelcore/home/home.nix | `Comment` | `Interactive process viewer` |
| hosts/kernelcore/home/home.nix | `Exec` | `gnome-terminal -- htop` |
| hosts/kernelcore/home/home.nix | `Icon` | `utilities-system-monitor` |
| hosts/kernelcore/home/home.nix | `Type` | `Application` |
| hosts/kernelcore/home/home.nix | `Categories` | `System;Monitor` |
| hosts/kernelcore/home/home.nix | `format` | `"""` |
| hosts/kernelcore/home/home.nix | `style` | `"blue"` |
| hosts/kernelcore/home/home.nix | `symbol` | `" "` |
| hosts/kernelcore/home/home.nix | `style` | `"red"` |
| hosts/kernelcore/home/home.nix | `style` | `"red"` |
| hosts/kernelcore/home/home.nix | `home.sessionVariables` | `{` |
| hosts/kernelcore/home/home.nix | `EDITOR` | `"nvim"` |
| hosts/kernelcore/home/home.nix | `VISUAL` | `"nvim"` |
| hosts/kernelcore/home/home.nix | `BROWSER` | `"firefox"` |
| hosts/kernelcore/home/home.nix | `TERMINAL` | `"alacritty"` |
| hosts/kernelcore/home/home.nix | `ANTHROPIC_MODEL` | `"claude-sonnet-4-5-20250929"` |
| hosts/kernelcore/home/home.nix | `home.sessionPath` | `[` |
| modules/services/users/actions.nix | `default` | `true` |
| modules/services/users/actions.nix | `description` | `"Use SOPS for secret management (recommended)"` |
| modules/services/users/actions.nix | `default` | `"repository"` |
| modules/services/users/actions.nix | `description` | `''` |
| modules/services/users/actions.nix | `default` | `"nixos-self-hosted"` |
| modules/services/users/actions.nix | `description` | `"Name for the GitHub Actions runner"` |
| modules/services/users/actions.nix | `default` | `"https://github.com/VoidNxSEC/nixos"` |
| modules/services/users/actions.nix | `description` | `''` |
| modules/services/users/actions.nix | `default` | `[` |
| modules/services/users/actions.nix | `description` | `"Additional labels for the runner"` |
| modules/services/users/actions.nix | `default` | `false` |
| modules/services/users/actions.nix | `description` | `''` |
| modules/services/users/actions.nix | `default` | `false` |
| modules/services/users/actions.nix | `description` | `''` |
| modules/services/users/actions.nix | `services.github-runners."${cfg.runnerName}"` | `{` |
| modules/services/users/actions.nix | `enable` | `true` |
| modules/services/users/actions.nix | `url` | `cfg.repoUrl` |
| modules/services/users/actions.nix | `name` | `cfg.runnerName` |
| modules/services/users/actions.nix | `extraLabels` | `cfg.extraLabels` |
| modules/services/users/actions.nix | `ephemeral` | `cfg.ephemeral` |
| modules/services/users/actions.nix | `serviceOverrides` | `{` |
| modules/services/users/actions.nix | `PrivateUsers` | `false` |
| modules/services/users/actions.nix | `ReadWritePaths` | `[` |
| modules/services/users/actions.nix | `BindReadOnlyPaths` | `[` |
| modules/services/users/actions.nix | `sops.secrets` | `mkIf cfg.useSops {` |
| modules/services/users/actions.nix | `"github_runner_token"` | `{` |
| modules/services/users/actions.nix | `sopsFile` | `../../../secrets/github.yaml` |
| modules/services/users/actions.nix | `mode` | `"0400"` |
| modules/services/users/actions.nix | `restartUnits` | `[ "github-runner-${cfg.runnerName}.service" ]` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `thermalCheck` | `{` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `default` | `true` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Enable thermal checks before rebuild"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `default` | `75` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Maximum temperature to allow rebuild to start"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `default` | `90` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Maximum temperature during rebuild (abort if exceeded)"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `default` | `5` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Seconds between temperature checks during rebuild"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `evidenceCollection` | `{` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `default` | `false` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Collect forensic evidence on rebuild failures"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `default` | `"/var/log/rebuild-evidence"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Path to store rebuild evidence"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `text` | `''` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `description` | `"Monitor temperature during nixos-rebuild"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `wantedBy` | `[ ]` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `serviceConfig` | `{` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `Type` | `"oneshot"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `RemainAfterExit` | `false` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `REBUILD_PID` | `"''${1:?Usage: rebuild-monitor <rebuild-pid>}"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `LOG_FILE` | `"/var/log/rebuild-thermal.log"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `ABORT_FLAG` | `"/tmp/rebuild-thermal-abort"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `TIMESTAMP` | `$(date +"%Y-%m-%d %H:%M:%S")` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `environment.systemPackages` | `[` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `echo "` | `==================="` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `REBUILD_PID` | `$!` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `--unit` | `rebuild-thermal-monitor-$REBUILD_PID \` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `--description` | `"Thermal monitor for rebuild $REBUILD_PID" \` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `MONITOR_PID` | `$!` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `REBUILD_EXIT` | `$?` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `mode` | `"0755"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `text` | `''` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `REASON` | `"''${1:-unknown}"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `TIMESTAMP` | `$(date +%Y%m%d-%H%M%S)` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `services.logrotate.settings.rebuild-thermal` | `{` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `files` | `"/var/log/rebuild-thermal.log"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `rotate` | `10` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `frequency` | `"daily"` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `compress` | `true` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `missingok` | `true` |
| modules/hardware/laptop-defense/rebuild-hooks.nix | `notifempty` | `true` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `programs.wlogout` | `{` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `layout` | `[` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `label` | `"lock"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `action` | `"hyprlock"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `text` | `"Lock"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `keybind` | `"l"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `label` | `"logout"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `action` | `"hyprctl dispatch exit"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `text` | `"Logout"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `keybind` | `"e"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `label` | `"suspend"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `action` | `"systemctl suspend"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `text` | `"Suspend"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `keybind` | `"u"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `label` | `"hibernate"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `action` | `"systemctl hibernate"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `text` | `"Hibernate"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `keybind` | `"h"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `label` | `"reboot"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `action` | `"systemctl reboot"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `text` | `"Reboot"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `keybind` | `"r"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `label` | `"shutdown"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `action` | `"systemctl poweroff"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `text` | `"Shutdown"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `keybind` | `"s"` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `style` | `''` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `/*` | `===========================================` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `*` | `=========================================== */` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `<?xml version` | `"1.0" encoding="UTF-8"?>` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `<rect x` | `"3" y="11" width="18" height="11" rx="2" ry="2"></rect>` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `<path d` | `"m7 11v-4a5 5 0 0 1 10 0v4"></path>` |
| hosts/kernelcore/home/glassmorphism/wlogout.nix | `<circle cx` | `"12" cy="16" r="1"></circle>` |
| modules/packages/tar-packages/packages/lynis.nix | `kernelcore.packages.tar.packages.lynis` | `{` |
| modules/packages/tar-packages/packages/lynis.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/lynis.nix | `method` | `"native"` |
| modules/packages/tar-packages/packages/lynis.nix | `source` | `{` |
| modules/packages/tar-packages/packages/lynis.nix | `path` | `sources.lynis.src` |
| modules/packages/tar-packages/packages/lynis.nix | `sha256` | `""; # Managed by sources.lynis.src` |
| modules/packages/tar-packages/packages/lynis.nix | `wrapper` | `{` |
| modules/packages/tar-packages/packages/lynis.nix | `executable` | `"lynis/lynis"` |
| modules/packages/tar-packages/packages/lynis.nix | `environmentVariables` | `{` |
| modules/packages/tar-packages/packages/lynis.nix | `PATH` | `lib.makeBinPath [` |
| modules/packages/tar-packages/packages/lynis.nix | `sandbox` | `{` |
| modules/packages/tar-packages/packages/lynis.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/lynis.nix | `audit` | `{` |
| modules/packages/tar-packages/packages/lynis.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/lynis.nix | `logLevel` | `"verbose"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/default.nix | `theme` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `name` | `"Adwaita-dark"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `iconTheme` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `name` | `"Papirus-Dark"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `cursorTheme` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `name` | `"Bibata-Modern-Classic"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `size` | `24` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk2.extraConfig` | `''` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-application-prefer-dark-theme` | `1` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk3.extraConfig` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-application-prefer-dark-theme` | `1` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-decoration-layout` | `"appmenu:none"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-enable-animations` | `true` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk4.extraConfig` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-application-prefer-dark-theme` | `1` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-decoration-layout` | `"appmenu:none"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-enable-animations` | `true` |
| hosts/kernelcore/home/glassmorphism/default.nix | `qt` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/default.nix | `platformTheme.name` | `"gtk"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `style` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `name` | `"kvantum"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `theme` | `KvGnomeDark` |
| hosts/kernelcore/home/glassmorphism/default.nix | `home.sessionVariables` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `GTK_THEME` | `"Adwaita:dark"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `QT_QPA_PLATFORMTHEME` | `"gtk2"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `QT_STYLE_OVERRIDE` | `"kvantum"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `XCURSOR_THEME` | `"Bibata-Modern-Classic"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `XCURSOR_SIZE` | `"24"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `home.pointerCursor` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `name` | `"Bibata-Modern-Classic"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `size` | `24` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk.enable` | `true` |
| hosts/kernelcore/home/glassmorphism/default.nix | `x11.enable` | `true` |
| hosts/kernelcore/home/glassmorphism/default.nix | `dconf.settings` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `"org/gnome/desktop/interface"` | `{` |
| hosts/kernelcore/home/glassmorphism/default.nix | `color-scheme` | `"prefer-dark"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `gtk-theme` | `"Adwaita-dark"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `icon-theme` | `"Papirus-Dark"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `cursor-theme` | `"Bibata-Modern-Classic"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `cursor-size` | `24` |
| hosts/kernelcore/home/glassmorphism/default.nix | `font-name` | `"Inter 11"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `monospace-font-name` | `"JetBrainsMono Nerd Font 11"` |
| hosts/kernelcore/home/glassmorphism/default.nix | `enable-animations` | `true` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `defaultWallpaper` | `"${wallpaperDir}/glassmorphism-default.png"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `colors` | `{` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `bg` | `"#0a0a0f"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `cyan` | `"#00d4ff"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `magenta` | `"#ff00aa"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `OUTPUT_DIR` | `"${wallpaperDir}"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `OUTPUT_FILE` | `"$OUTPUT_DIR/glassmorphism-default.png"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `WIDTH` | `"''${1:-1920}"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `HEIGHT` | `"''${2:-1080}"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `W4` | `$((WIDTH/4))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H3` | `$((HEIGHT/3))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `W34` | `$((WIDTH*3/4))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H23` | `$((HEIGHT*2/3))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `W2` | `$((WIDTH/2))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H5` | `$((HEIGHT/5))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `W45` | `$((WIDTH*4/5))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H4` | `$((HEIGHT/4))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `W6` | `$((WIDTH/6))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H45` | `$((HEIGHT*4/5))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `W5` | `$((WIDTH/5))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H25` | `$((HEIGHT*2/5))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H2` | `$((HEIGHT/2))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `H34` | `$((HEIGHT*3/4))` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `OUTPUT_DIR` | `"${wallpaperDir}"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `OUTPUT_FILE` | `"$OUTPUT_DIR/glassmorphism-default.png"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `WALLPAPERS` | `(` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `"https://images.unsplash.com/photo-1557682250-33bd709cbe85?w` | `1920&h=1080&fit=crop"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `"https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w` | `1920&h=1080&fit=crop"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `"https://images.unsplash.com/photo-1557683316-973673baf926?w` | `1920&h=1080&fit=crop"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `WALLPAPER` | `"''${1:-${defaultWallpaper}}"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `home.activation.createWallpaperDir` | `lib.hm.dag.entryAfter [ "writeBoundary" ] ''` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `systemd.user.services.swaybg` | `{` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `Unit` | `{` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `Description` | `"Wayland wallpaper daemon (swaybg)"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `PartOf` | `[ "graphical-session.target" ]` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `After` | `[ "graphical-session.target" ]` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `Service` | `{` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `Type` | `"simple"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `Restart` | `"on-failure"` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `RestartSec` | `1` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `Install` | `{` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `WantedBy` | `[ "graphical-session.target" ]` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `<?xml version` | `"1.0" encoding="UTF-8"?>` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `<svg xmlns` | `"http://www.w3.org/2000/svg" viewBox="0 0 1920 1080">` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `<linearGradient id` | `"bg" x1="0%" y1="0%" x2="100%" y2="100%">` |
| hosts/kernelcore/home/glassmorphism/wallpaper.nix | `<stop offset` | `"0%" style="stop-color:#0a0a0f;stop-opacity:1" />` |
| modules/system/services.nix | `systemd.services.docker-pull-images` | `{` |
| modules/system/services.nix | `description` | `"Pre-pull Docker images"` |
| modules/system/services.nix | `after` | `[ "docker.service" ]` |
| modules/system/services.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/system/services.nix | `serviceConfig` | `{` |
| modules/system/services.nix | `Type` | `"oneshot"` |
| modules/system/services.nix | `RemainAfterExit` | `true` |
| modules/system/services.nix | `script` | `''` |
| modules/system/services.nix | `systemd.services.ollama` | `{` |
| modules/system/services.nix | `serviceConfig` | `{` |
| modules/system/services.nix | `User` | `"ollama"` |
| modules/system/services.nix | `Group` | `"ollama"` |
| modules/system/services.nix | `DeviceAllow` | `[` |
| modules/system/services.nix | `TimeoutStopSec` | `"30s"` |
| modules/system/ml-gpu-users.nix | `users.users.ollama` | `{` |
| modules/system/ml-gpu-users.nix | `isSystemUser` | `true` |
| modules/system/ml-gpu-users.nix | `group` | `"ollama"` |
| modules/system/ml-gpu-users.nix | `description` | `"Ollama ML service user"` |
| modules/system/ml-gpu-users.nix | `extraGroups` | `[` |
| modules/system/ml-gpu-users.nix | `users.groups.ollama` | `{ }` |
| modules/system/ml-gpu-users.nix | `users.users.llamacpp` | `{` |
| modules/system/ml-gpu-users.nix | `isSystemUser` | `true` |
| modules/system/ml-gpu-users.nix | `group` | `"llamacpp"` |
| modules/system/ml-gpu-users.nix | `description` | `"Llama.cpp ML service user"` |
| modules/system/ml-gpu-users.nix | `extraGroups` | `[` |
| modules/system/ml-gpu-users.nix | `users.groups.llamacpp` | `{ }` |
| modules/system/ml-gpu-users.nix | `users.users.ml-offload` | `{` |
| modules/system/ml-gpu-users.nix | `isSystemUser` | `true` |
| modules/system/ml-gpu-users.nix | `group` | `"ml-offload"` |
| modules/system/ml-gpu-users.nix | `description` | `"ML Offload Manager service user"` |
| modules/system/ml-gpu-users.nix | `extraGroups` | `[` |
| modules/system/ml-gpu-users.nix | `users.groups.ml-offload` | `{ }` |
| hosts/kernelcore/home/shell/default.nix | `home.sessionVariables` | `{` |
| modules/applications/vscodium-secure.nix | `default` | `true` |
| modules/applications/vscodium-secure.nix | `description` | `"Enable additional security hardening via Firejail"` |
| modules/applications/vscodium-secure.nix | `default` | `true` |
| modules/applications/vscodium-secure.nix | `description` | `"Allow network access (required for extensions and remote development)"` |
| modules/applications/vscodium-secure.nix | `default` | `10` |
| modules/applications/vscodium-secure.nix | `description` | `"Nice level for VSCodium process (0-19, higher = lower priority)"` |
| modules/applications/vscodium-secure.nix | `default` | `"best-effort"` |
| modules/applications/vscodium-secure.nix | `description` | `"IO scheduling class for VSCodium"` |
| modules/applications/vscodium-secure.nix | `default` | `4` |
| modules/applications/vscodium-secure.nix | `description` | `"IO scheduling priority (0-7, lower = higher priority)"` |
| modules/applications/vscodium-secure.nix | `default` | `"8G"` |
| modules/applications/vscodium-secure.nix | `description` | `"Memory limit for VSCodium process"` |
| modules/applications/vscodium-secure.nix | `default` | `"80%"` |
| modules/applications/vscodium-secure.nix | `description` | `"CPU quota for VSCodium (percentage or absolute value)"` |
| modules/applications/vscodium-secure.nix | `default` | `[` |
| modules/applications/vscodium-secure.nix | `description` | `"List of paths that VSCodium can access"` |
| modules/applications/vscodium-secure.nix | `default` | `[ ]` |
| modules/applications/vscodium-secure.nix | `description` | `"List of VSCodium extensions to install"` |
| modules/applications/vscodium-secure.nix | `example` | `literalExpression ''` |
| modules/applications/vscodium-secure.nix | `commandLineArgs` | `[` |
| modules/applications/vscodium-secure.nix | `mode` | `"0755"` |
| modules/applications/vscodium-secure.nix | `text` | `''` |
| modules/applications/vscodium-secure.nix | `SCOPE_NAME` | `"vscodium-$$"` |
| modules/applications/vscodium-secure.nix | `--unit` | `"$SCOPE_NAME" \` |
| modules/applications/vscodium-secure.nix | `--property` | `"MemoryMax=${cfg.memoryLimit}" \` |
| modules/applications/vscodium-secure.nix | `--property` | `"CPUQuota=${cfg.cpuQuota}" \` |
| modules/applications/vscodium-secure.nix | `--property` | `"Nice=${toString cfg.niceLevel}" \` |
| modules/applications/vscodium-secure.nix | `--property` | `"IOSchedulingClass=${cfg.ioSchedulingClass}" \` |
| modules/applications/vscodium-secure.nix | `--property` | `"IOSchedulingPriority=${toString cfg.ioSchedulingPriority}" \` |
| modules/applications/vscodium-secure.nix | `--profile` | `/etc/firejail/vscodium.local \` |
| modules/applications/vscodium-secure.nix | `--private-etc` | `alternatives,fonts,ssl,pki,crypto-policies,resolv.conf,hostname,localtime \` |
| modules/applications/vscodium-secure.nix | `Version` | `1.0` |
| modules/applications/vscodium-secure.nix | `Name` | `VSCodium (Secure/Sandboxed)` |
| modules/applications/vscodium-secure.nix | `GenericName` | `Text Editor` |
| modules/applications/vscodium-secure.nix | `Exec` | `/etc/vscodium-wrapper.sh %F` |
| modules/applications/vscodium-secure.nix | `Icon` | `vscodium` |
| modules/applications/vscodium-secure.nix | `Terminal` | `false` |
| modules/applications/vscodium-secure.nix | `Type` | `Application` |
| modules/applications/vscodium-secure.nix | `MimeType` | `text/plain;inode/directory` |
| modules/applications/vscodium-secure.nix | `Categories` | `Development;IDE;TextEditor` |
| modules/applications/vscodium-secure.nix | `Keywords` | `vscode;editor;ide;development` |
| modules/applications/vscodium-secure.nix | `StartupNotify` | `true` |
| modules/applications/vscodium-secure.nix | `StartupWMClass` | `VSCodium` |
| modules/applications/vscodium-secure.nix | `Actions` | `new-empty-window` |
| modules/applications/vscodium-secure.nix | `Name` | `New Empty Window` |
| modules/applications/vscodium-secure.nix | `Exec` | `/etc/vscodium-wrapper.sh --new-window %F` |
| modules/applications/vscodium-secure.nix | `Icon` | `vscodium` |
| modules/applications/vscodium-secure.nix | `environment.sessionVariables` | `{` |
| modules/applications/vscodium-secure.nix | `VSCODE_TELEMETRY_OPTOUT` | `"1"` |
| modules/applications/vscodium-secure.nix | `DISABLE_UPDATE_CHECK` | `"1"` |
| modules/applications/vscodium-secure.nix | `home-manager.users` | `mkIf (cfg.extensions != [ ]) {` |
| modules/applications/vscodium-secure.nix | `kernelcore` | `{` |
| modules/applications/vscodium-secure.nix | `programs.vscode` | `{` |
| modules/applications/vscodium-secure.nix | `profiles` | `{` |
| modules/applications/vscodium-secure.nix | `extensions` | `cfg.extensions` |
| modules/security/packages.nix | `security.sudo.extraRules` | `[` |
| modules/security/packages.nix | `groups` | `[ "wheel" ]` |
| modules/security/packages.nix | `commands` | `[` |
| modules/security/packages.nix | `command` | `"/run/current-system/sw/bin/lynis"` |
| hosts/kernelcore/home/theme.nix | `colorScheme` | `nix-colors.colorSchemes.catppuccin-macchiato` |
| hosts/kernelcore/home/theme.nix | `gtk` | `{` |
| hosts/kernelcore/home/theme.nix | `enable` | `true` |
| hosts/kernelcore/home/theme.nix | `theme` | `{` |
| hosts/kernelcore/home/theme.nix | `name` | `"Catppuccin-Macchiato-Standard-Blue-dark"` |
| hosts/kernelcore/home/theme.nix | `accents` | `[ "blue" ]` |
| hosts/kernelcore/home/theme.nix | `size` | `"standard"` |
| hosts/kernelcore/home/theme.nix | `variant` | `"macchiato"` |
| hosts/kernelcore/home/theme.nix | `iconTheme` | `{` |
| hosts/kernelcore/home/theme.nix | `name` | `"Papirus-Dark"` |
| hosts/kernelcore/home/theme.nix | `cursorTheme` | `{` |
| hosts/kernelcore/home/theme.nix | `name` | `"Catppuccin-Macchiato-Blue"` |
| hosts/kernelcore/home/theme.nix | `size` | `24` |
| hosts/kernelcore/home/theme.nix | `qt` | `{` |
| hosts/kernelcore/home/theme.nix | `enable` | `true` |
| hosts/kernelcore/home/theme.nix | `platformTheme.name` | `"gtk"` |
| hosts/kernelcore/home/theme.nix | `style` | `{` |
| hosts/kernelcore/home/theme.nix | `name` | `"kvantum"` |
| modules/services/users/gemini-agent.nix | `default` | `"gemini-agent"` |
| modules/services/users/gemini-agent.nix | `description` | `"Username for Gemini Agent service"` |
| modules/services/users/gemini-agent.nix | `default` | `"/var/lib/gemini-agent"` |
| modules/services/users/gemini-agent.nix | `description` | `"Home directory for Gemini Agent user"` |
| modules/services/users/gemini-agent.nix | `default` | `[` |
| modules/services/users/gemini-agent.nix | `description` | `"Groups to add Gemini Agent user to"` |
| modules/services/users/gemini-agent.nix | `default` | `true` |
| modules/services/users/gemini-agent.nix | `description` | `"Allow passwordless sudo for system operations"` |
| modules/services/users/gemini-agent.nix | `users.users."${cfg.userName}"` | `{` |
| modules/services/users/gemini-agent.nix | `isSystemUser` | `true` |
| modules/services/users/gemini-agent.nix | `description` | `"Gemini Agent AI Assistant"` |
| modules/services/users/gemini-agent.nix | `home` | `cfg.homeDirectory` |
| modules/services/users/gemini-agent.nix | `createHome` | `true` |
| modules/services/users/gemini-agent.nix | `group` | `cfg.userName` |
| modules/services/users/gemini-agent.nix | `extraGroups` | `cfg.allowedGroups ++ [ "mcp-shared" ]; # Add shared knowledge DB access` |
| modules/services/users/gemini-agent.nix | `security.sudo.extraRules` | `mkIf cfg.sudoNoPasswd [` |
| modules/services/users/gemini-agent.nix | `users` | `[ cfg.userName ]` |
| modules/services/users/gemini-agent.nix | `commands` | `[` |
| modules/services/users/gemini-agent.nix | `systemd.tmpfiles.rules` | `[` |
| modules/packages/tar-packages/packages/codex.nix | `codex` | `{` |
| modules/packages/tar-packages/packages/codex.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/codex.nix | `method` | `"native"` |
| modules/packages/tar-packages/packages/codex.nix | `source` | `{` |
| modules/packages/tar-packages/packages/codex.nix | `path` | `../storage/codex-x86_64-unknown-linux-musl.tar.gz` |
| modules/packages/tar-packages/packages/codex.nix | `sha256` | `"ebbeb9b5fb391fdb6300ea02b8ca9ac70e8681e13e5e6c73ad3766be28e58db1"` |
| modules/packages/tar-packages/packages/codex.nix | `wrapper` | `{` |
| modules/packages/tar-packages/packages/codex.nix | `executable` | `"codex-x86_64-unknown-linux-musl"` |
| modules/packages/tar-packages/packages/codex.nix | `environmentVariables` | `{ }` |
| modules/packages/tar-packages/packages/codex.nix | `sandbox` | `{` |
| modules/packages/tar-packages/packages/codex.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/codex.nix | `audit` | `{` |
| modules/packages/tar-packages/packages/codex.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/codex.nix | `desktopEntry` | `null` |
| modules/hardware/nvidia.nix | `default` | `"PCI:0:2:0"` |
| modules/hardware/nvidia.nix | `description` | `"PCI Bus ID do chip Intel/AMD (ex: PCI:0:2:0)"` |
| modules/hardware/nvidia.nix | `default` | `"PCI:1:0:0"` |
| modules/hardware/nvidia.nix | `description` | `"PCI Bus ID do chip NVIDIA (ex: PCI:1:0:0)"` |
| modules/hardware/nvidia.nix | `virtualisation.vmVariant` | `{` |
| modules/hardware/nvidia.nix | `hardware.nvidia` | `{` |
| modules/hardware/nvidia.nix | `modesetting.enable` | `true` |
| modules/hardware/nvidia.nix | `powerManagement.enable` | `true` |
| modules/hardware/nvidia.nix | `powerManagement.finegrained` | `false` |
| modules/hardware/nvidia.nix | `open` | `false` |
| modules/hardware/nvidia.nix | `nvidiaSettings` | `true` |
| modules/hardware/nvidia.nix | `forceFullCompositionPipeline` | `true` |
| modules/hardware/nvidia.nix | `enable` | `true` |
| modules/hardware/nvidia.nix | `enableOffloadCmd` | `true` |
| modules/hardware/nvidia.nix | `intelBusId` | `mkIf (` |
| modules/hardware/nvidia.nix | `nvidiaBusId` | `mkIf (` |
| modules/hardware/nvidia.nix | `boot.kernelParams` | `[` |
| modules/hardware/nvidia.nix | `"nvidia.NVreg_DynamicPowerManagement` | `0x02"` |
| modules/hardware/nvidia.nix | `"nvidia.NVreg_PreserveVideoMemoryAllocations` | `1"` |
| modules/hardware/nvidia.nix | `"nvidia.NVreg_EnableGpuFirmware` | `1"` |
| modules/hardware/nvidia.nix | `description` | `"NVIDIA RTX 3050 6GB Power Management"` |
| modules/hardware/nvidia.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/nvidia.nix | `after` | `[ "nvidia-persistenced.service" ]` |
| modules/hardware/nvidia.nix | `serviceConfig` | `{` |
| modules/hardware/nvidia.nix | `Type` | `"oneshot"` |
| modules/hardware/nvidia.nix | `RemainAfterExit` | `true` |
| modules/hardware/nvidia.nix | `script` | `''` |
| modules/hardware/nvidia.nix | `PROFILE` | `$(cat /var/lib/thermal-profile/current)` |
| modules/hardware/nvidia.nix | `description` | `"NVIDIA GPU monitoring and optimization"` |
| modules/hardware/nvidia.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/nvidia.nix | `after` | `[ "nvidia-rtx3050-power-management.service" ]` |
| modules/hardware/nvidia.nix | `serviceConfig` | `{` |
| modules/hardware/nvidia.nix | `Type` | `"simple"` |
| modules/hardware/nvidia.nix | `Restart` | `"always"` |
| modules/hardware/nvidia.nix | `RestartSec` | `"30s"` |
| modules/hardware/nvidia.nix | `script` | `''` |
| modules/hardware/nvidia.nix | `LOG_FILE` | `"/var/log/nvidia-monitor.log"` |
| modules/hardware/nvidia.nix | `KERNEL` | `="nvidia[0-9]*", GROUP="nvidia", MODE="0660"` |
| modules/hardware/nvidia.nix | `KERNEL` | `="nvidiactl", GROUP="nvidia", MODE="0660"` |
| modules/hardware/nvidia.nix | `KERNEL` | `="nvidia-uvm", GROUP="nvidia", MODE="0660"` |
| modules/hardware/nvidia.nix | `KERNEL` | `="nvidia-uvm-tools", GROUP="nvidia", MODE="0660"` |
| modules/hardware/nvidia.nix | `KERNEL` | `="nvidia-modeset", GROUP="nvidia", MODE="0660"` |
| modules/hardware/laptop-defense/flake.nix | `description` | `"Laptop Defense Framework - Hardware Forensics Suite"` |
| modules/hardware/laptop-defense/flake.nix | `inputs` | `{` |
| modules/hardware/laptop-defense/flake.nix | `system` | `"x86_64-linux"` |
| modules/hardware/laptop-defense/flake.nix | `name` | `"thermal-forensics"` |
| modules/hardware/laptop-defense/flake.nix | `text` | `''` |
| modules/hardware/laptop-defense/flake.nix | `REPORT_DIR` | `"/tmp/thermal-evidence-$(date +%Y%m%d-%H%M%S)"` |
| modules/hardware/laptop-defense/flake.nix | `echo "` | `========================="` |
| modules/hardware/laptop-defense/flake.nix | `TIMESTAMP` | `$(date +%s)` |
| modules/hardware/laptop-defense/flake.nix | `TEMPS` | `$(sensors -j 2>/dev/null || echo '{}')` |
| modules/hardware/laptop-defense/flake.nix | `FREQ` | `$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')` |
| modules/hardware/laptop-defense/flake.nix | `LOAD` | `$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)` |
| modules/hardware/laptop-defense/flake.nix | `THROTTLE` | `$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -1)` |
| modules/hardware/laptop-defense/flake.nix | `TIMESTAMP` | `$(date +%s)` |
| modules/hardware/laptop-defense/flake.nix | `TEMPS` | `$(sensors -j 2>/dev/null || echo '{}')` |
| modules/hardware/laptop-defense/flake.nix | `FREQ` | `$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')` |
| modules/hardware/laptop-defense/flake.nix | `LOAD` | `$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)` |
| modules/hardware/laptop-defense/flake.nix | `THROTTLE` | `$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -1)` |
| modules/hardware/laptop-defense/flake.nix | `MONITOR_PID` | `$!` |
| modules/hardware/laptop-defense/flake.nix | `TIMESTAMP` | `$(date +%s)` |
| modules/hardware/laptop-defense/flake.nix | `TEMPS` | `$(sensors -j 2>/dev/null || echo '{}')` |
| modules/hardware/laptop-defense/flake.nix | `FREQ` | `$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')` |
| modules/hardware/laptop-defense/flake.nix | `LOAD` | `$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)` |
| modules/hardware/laptop-defense/flake.nix | `THROTTLE` | `$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -1)` |
| modules/hardware/laptop-defense/flake.nix | `MONITOR_PID` | `$!` |
| modules/hardware/laptop-defense/flake.nix | `data` | `{'baseline': [], 'stress': [], 'rebuild': []}` |
| modules/hardware/laptop-defense/flake.nix | `parts` | `line.strip().split(',')` |
| modules/hardware/laptop-defense/flake.nix | `if len(parts) >` | `3:` |
| modules/hardware/laptop-defense/flake.nix | `timestamp` | `int(parts[0])` |
| modules/hardware/laptop-defense/flake.nix | `phase` | `parts[1]` |
| modules/hardware/laptop-defense/flake.nix | `temps_str` | `','.join(parts[2:-3])` |
| modules/hardware/laptop-defense/flake.nix | `analysis` | `{` |
| modules/hardware/laptop-defense/flake.nix | `print(json.dumps(analysis, indent` | `2))` |
| modules/hardware/laptop-defense/flake.nix | `name` | `"mcp-log-extract"` |
| modules/hardware/laptop-defense/flake.nix | `text` | `''` |
| modules/hardware/laptop-defense/flake.nix | `OUTPUT_DIR` | `"/tmp/mcp-evidence-$(date +%Y%m%d-%H%M%S)"` |
| modules/hardware/laptop-defense/flake.nix | `name` | `"thermal-warroom"` |
| modules/hardware/laptop-defense/flake.nix | `text` | `''` |
| modules/hardware/laptop-defense/flake.nix | `RED` | `'\033[0;31m'` |
| modules/hardware/laptop-defense/flake.nix | `YELLOW` | `'\033[1;33m'` |
| modules/hardware/laptop-defense/flake.nix | `GREEN` | `'\033[0;32m'` |
| modules/hardware/laptop-defense/flake.nix | `NC` | `'\033[0m'` |
| modules/hardware/laptop-defense/flake.nix | `TEMPS` | `$(sensors 2>/dev/null | grep -E "Core|Package|temp" | head -10 || echo "No sensors found")` |
| modules/hardware/laptop-defense/flake.nix | `echo "$TEMPS" | while IFS` | `read -r line; do` |
| modules/hardware/laptop-defense/flake.nix | `TEMP` | `$(echo "$line" | grep -oP '\+\K[0-9]+' | head -1 || echo "0")` |
| modules/hardware/laptop-defense/flake.nix | `if [ -n "$TEMP" ] && [ "$TEMP" !` | `"0" ]; then` |
| modules/hardware/laptop-defense/flake.nix | `TURBO` | `$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)` |
| modules/hardware/laptop-defense/flake.nix | `if [ "$TURBO"` | `"1" ]; then` |
| modules/hardware/laptop-defense/flake.nix | `name` | `"laptop-verdict"` |
| modules/hardware/laptop-defense/flake.nix | `text` | `''` |
| modules/hardware/laptop-defense/flake.nix | `EVIDENCE_DIR` | `"''${1:?Usage: laptop-verdict <evidence-dir>}"` |
| modules/hardware/laptop-defense/flake.nix | `echo "` | `================================================="` |
| modules/hardware/laptop-defense/flake.nix | `SCORE` | `0` |
| modules/hardware/laptop-defense/flake.nix | `CRITICAL` | `0` |
| modules/hardware/laptop-defense/flake.nix | `CRITICAL` | `$((CRITICAL + 1))` |
| modules/hardware/laptop-defense/flake.nix | `SCORE` | `$((SCORE + 50))` |
| modules/hardware/laptop-defense/flake.nix | `YEAR` | `$(grep "Release Date" "$EVIDENCE_DIR/raw/dmi-system.txt" | grep -oP '\d{4}' | head -1 || echo "2020")` |
| modules/hardware/laptop-defense/flake.nix | `AGE` | `$(($(date +%Y) - YEAR))` |
| modules/hardware/laptop-defense/flake.nix | `SCORE` | `$((SCORE + 20))` |
| modules/hardware/laptop-defense/flake.nix | `if [ "$WARRANTY"` | `"n" ]; then` |
| modules/hardware/laptop-defense/flake.nix | `SCORE` | `$((SCORE + 15))` |
| modules/hardware/laptop-defense/flake.nix | `if [ "$RECURRING"` | `"y" ]; then` |
| modules/hardware/laptop-defense/flake.nix | `CRITICAL` | `$((CRITICAL + 1))` |
| modules/hardware/laptop-defense/flake.nix | `SCORE` | `$((SCORE + 30))` |
| modules/hardware/laptop-defense/flake.nix | `SCORE` | `$((SCORE - 20))  # Lower replacement score` |
| modules/hardware/laptop-defense/flake.nix | `name` | `"laptop-investigation"` |
| modules/hardware/laptop-defense/flake.nix | `runtimeInputs` | `[` |
| modules/hardware/laptop-defense/flake.nix | `text` | `''` |
| modules/hardware/laptop-defense/flake.nix | `echo "` | `================================="` |
| modules/hardware/laptop-defense/flake.nix | `LATEST_THERMAL` | `$(ls -td /tmp/thermal-evidence-* 2>/dev/null | head -1 || echo "")` |
| modules/hardware/laptop-defense/flake.nix | `thermal-forensics` | `{` |
| modules/hardware/laptop-defense/flake.nix | `type` | `"app"` |
| modules/hardware/laptop-defense/flake.nix | `program` | `"${thermalForensics}/bin/thermal-forensics"` |
| modules/hardware/laptop-defense/flake.nix | `thermal-warroom` | `{` |
| modules/hardware/laptop-defense/flake.nix | `type` | `"app"` |
| modules/hardware/laptop-defense/flake.nix | `program` | `"${thermalMonitor}/bin/thermal-warroom"` |
| modules/hardware/laptop-defense/flake.nix | `mcp-extract` | `{` |
| modules/hardware/laptop-defense/flake.nix | `type` | `"app"` |
| modules/hardware/laptop-defense/flake.nix | `program` | `"${mcpLogExtractor}/bin/mcp-log-extract"` |
| modules/hardware/laptop-defense/flake.nix | `verdict` | `{` |
| modules/hardware/laptop-defense/flake.nix | `type` | `"app"` |
| modules/hardware/laptop-defense/flake.nix | `program` | `"${decisionFramework}/bin/laptop-verdict"` |
| modules/hardware/laptop-defense/flake.nix | `full-investigation` | `{` |
| modules/hardware/laptop-defense/flake.nix | `type` | `"app"` |
| modules/hardware/laptop-defense/flake.nix | `program` | `"${self.packages.${system}.fullInvestigation}/bin/laptop-investigation"` |
| modules/hardware/laptop-defense/flake.nix | `default` | `95` |
| modules/hardware/laptop-defense/flake.nix | `description` | `"Maximum temperature (°C) before emergency brake"` |
| modules/hardware/laptop-defense/flake.nix | `Nice` | `19; # Baixa prioridade` |
| modules/hardware/laptop-defense/flake.nix | `CPUQuota` | `"25%"; # Limita CPU` |
| modules/hardware/laptop-defense/flake.nix | `systemd.services.thermal-emergency` | `{` |
| modules/hardware/laptop-defense/flake.nix | `description` | `"Emergency thermal protection"` |
| modules/hardware/laptop-defense/flake.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/laptop-defense/flake.nix | `serviceConfig` | `{` |
| modules/hardware/laptop-defense/flake.nix | `Type` | `"simple"` |
| modules/hardware/laptop-defense/flake.nix | `Restart` | `"always"` |
| modules/hardware/laptop-defense/flake.nix | `RestartSec` | `"30s"` |
| modules/services/mosh.nix | `kernelcore.services.mosh` | `{` |
| modules/services/mosh.nix | `default` | `true` |
| modules/services/mosh.nix | `description` | `"Automatically open firewall ports for Mosh (UDP 60000-61000)"` |
| modules/services/mosh.nix | `default` | `60000` |
| modules/services/mosh.nix | `description` | `"Starting port for Mosh server"` |
| modules/services/mosh.nix | `default` | `61000` |
| modules/services/mosh.nix | `description` | `"Ending port for Mosh server"` |
| modules/services/mosh.nix | `default` | `{` |
| modules/services/mosh.nix | `from` | `60000` |
| modules/services/mosh.nix | `to` | `61000` |
| modules/services/mosh.nix | `description` | `"UDP port range for Mosh connections"` |
| modules/services/mosh.nix | `default` | `true` |
| modules/services/mosh.nix | `description` | `"Display message of the day on Mosh connections"` |
| modules/services/mosh.nix | `programs.mosh` | `{` |
| modules/services/mosh.nix | `enable` | `true` |
| modules/services/mosh.nix | `allowedUDPPortRanges` | `[` |
| modules/services/mosh.nix | `text` | `''` |
| modules/services/mosh.nix | `mode` | `"0644"` |
| modules/services/mosh.nix | `text` | `''` |
| modules/services/mosh.nix | `mosh --server` | `/custom/path/to/mosh-server user@host` |
| modules/services/mosh.nix | `- Try: mosh --server` | `/run/current-system/sw/bin/mosh-server user@host` |
| modules/services/mosh.nix | `mosh --ssh` | `"ssh -v" kernelcore@YOUR_SERVER_IP` |
| modules/services/mosh.nix | `mode` | `"0644"` |
| modules/services/mosh.nix | `environment.shellAliases` | `{` |
| modules/services/mosh.nix | `mosh-sessions` | `"ps aux | grep mosh-server"` |
| modules/services/mosh.nix | `mosh-kill` | `"pkill -u $USER mosh-server"` |
| modules/services/mosh.nix | `mosh-test` | `"echo 'Testing Mosh installation:' && mosh-server --version && echo 'Mosh is working!'"` |
| modules/services/mosh.nix | `assertions` | `[` |
| modules/services/mosh.nix | `message` | `"Mosh requires SSH to be enabled. Enable kernelcore.security.ssh or services.openssh"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `programs.wofi` | `{` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `enable` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `settings` | `{` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `mode` | `"drun"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `allow_images` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `image_size` | `32` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `prompt` | `"Search"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `width` | `600` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `height` | `400` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `location` | `"center"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `orientation` | `"vertical"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `halign` | `"fill"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `allow_markup` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `insensitive` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `no_actions` | `false` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `hide_scroll` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `matching` | `"fuzzy"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `sort_order` | `"default"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `gtk_dark` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `dynamic_lines` | `false` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `layer` | `"overlay"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `exec_search` | `false` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `search` | `""` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `key_expand` | `"Tab"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `key_exit` | `"Escape"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `style` | `''` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `/*` | `===========================================` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `*` | `=========================================== */` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `home.file` | `{` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `OPTIONS` | `"󰌾 Lock\n󰗽 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `SELECTED` | `$(echo -e "$OPTIONS" | wofi --dmenu --prompt="Power" --width=250 --height=220 --cache-file=/dev/null)` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `SELECTED` | `$(cat "$EMOJI_FILE" | wofi --dmenu --prompt="Emoji" --width=400 --height=300)` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `EMOJI` | `$(echo "$SELECTED" | cut -d' ' -f1)` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `SELECTED` | `$(cliphist list | wofi --dmenu --prompt="Clipboard" --width=600 --height=400)` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `executable` | `true` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `text` | `''` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `WINDOWS` | `$(hyprctl clients -j | jq -r '.[] | "\(.address) \(.class) - \(.title)"')` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `SELECTED` | `$(echo "$WINDOWS" | wofi --dmenu --prompt="Windows" --width=700 --height=400)` |
| hosts/kernelcore/home/glassmorphism/wofi.nix | `ADDRESS` | `$(echo "$SELECTED" | awk '{print $1}')` |
| modules/packages/js-packages/build-gemini.nix | `pname` | `"gemini-cli"` |
| modules/packages/js-packages/build-gemini.nix | `version` | `"0.21.0-nightly.20251211.8c83e1ea9}"` |
| modules/packages/js-packages/build-gemini.nix | `url` | `"file://${./storage/gemini-cli-0.21.0-nightly.20251211.8c83e1ea9.tar.gz}"` |
| modules/packages/js-packages/build-gemini.nix | `sha256` | `"f2e2e90635b0fd0ba1b933a27f6c23e107d33e7f48062de3e52e8060df367005"` |
| modules/packages/js-packages/build-gemini.nix | `npmDepsHash` | `""` |
| modules/packages/js-packages/build-gemini.nix | `nodeLinker` | `"pnpm"` |
| modules/packages/js-packages/build-gemini.nix | `npmFlags` | `[ "--legacy-peer-deps" ]` |
| modules/packages/js-packages/build-gemini.nix | `dontCheckNoBrokenSymlinks` | `true` |
| modules/system/binary-cache.nix | `local` | `{` |
| modules/system/binary-cache.nix | `default` | `"http://192.168.15.9:5000"` |
| modules/system/binary-cache.nix | `description` | `"URL of the local binary cache server"` |
| modules/system/binary-cache.nix | `default` | `40` |
| modules/system/binary-cache.nix | `description` | `"Priority of the local cache (lower = higher priority)"` |
| modules/system/binary-cache.nix | `default` | `false` |
| modules/system/binary-cache.nix | `description` | `"Only enable cache if server is reachable (useful for optional LAN cache)"` |
| modules/system/binary-cache.nix | `remote` | `{` |
| modules/system/binary-cache.nix | `default` | `[ ]` |
| modules/system/binary-cache.nix | `description` | `"Additional binary cache URLs"` |
| modules/system/binary-cache.nix | `example` | `[` |
| modules/system/binary-cache.nix | `default` | `[ ]` |
| modules/system/binary-cache.nix | `description` | `"Public keys for verifying binary cache signatures"` |
| modules/system/binary-cache.nix | `example` | `[ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ]` |
| modules/system/binary-cache.nix | `nix.settings` | `{` |
| modules/system/binary-cache.nix | `substituters` | `mkMerge [` |
| modules/system/binary-cache.nix | `trusted-substituters` | `mkMerge [` |
| modules/system/binary-cache.nix | `port` | `5000` |
| modules/system/binary-cache.nix | `bindAddress` | `"0.0.0.0"` |
| modules/system/binary-cache.nix | `secretKeyFile` | `"/var/cache-priv-key.pem"` |
| modules/system/binary-cache.nix | `echo "` | `======================"` |
| modules/system/binary-cache.nix | `CACHE_HOST` | `$(echo "$CACHE_URL" | sed -E 's|^https?://([^:/]+).*|\1|')` |
| modules/system/binary-cache.nix | `CACHE_PORT` | `$(echo "$CACHE_URL" | sed -E 's|^https?://[^:]+:([0-9]+).*|\1|')` |
| hosts/kernelcore/home/shell/bash.nix | `programs.bash` | `{` |
| hosts/kernelcore/home/shell/bash.nix | `enable` | `true` |
| hosts/kernelcore/home/shell/bash.nix | `enableCompletion` | `true` |
| hosts/kernelcore/home/shell/bash.nix | `historySize` | `10000` |
| hosts/kernelcore/home/shell/bash.nix | `historyFileSize` | `20000` |
| hosts/kernelcore/home/shell/bash.nix | `historyControl` | `[` |
| hosts/kernelcore/home/shell/bash.nix | `shellAliases` | `{` |
| hosts/kernelcore/home/shell/bash.nix | `ll` | `"eza -la --icons --git"` |
| hosts/kernelcore/home/shell/bash.nix | `la` | `"eza -la --icons --git"` |
| hosts/kernelcore/home/shell/bash.nix | `lt` | `"eza --tree --icons --git"` |
| hosts/kernelcore/home/shell/bash.nix | `ls` | `"eza --icons"` |
| hosts/kernelcore/home/shell/bash.nix | `gs` | `"git status"` |
| hosts/kernelcore/home/shell/bash.nix | `ga` | `"git add"` |
| hosts/kernelcore/home/shell/bash.nix | `gaa` | `"git add --all"` |
| hosts/kernelcore/home/shell/bash.nix | `gc` | `"git commit -m"` |
| hosts/kernelcore/home/shell/bash.nix | `gp` | `"git push"` |
| hosts/kernelcore/home/shell/bash.nix | `gl` | `"git log --oneline --graph --decorate --all -10"` |
| hosts/kernelcore/home/shell/bash.nix | `gd` | `"git diff"` |
| hosts/kernelcore/home/shell/bash.nix | `gco` | `"git checkout"` |
| hosts/kernelcore/home/shell/bash.nix | `dps` | `"docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"` |
| hosts/kernelcore/home/shell/bash.nix | `dimg` | `"docker images"` |
| hosts/kernelcore/home/shell/bash.nix | `dstop` | `"docker stop $(docker ps -q)"` |
| hosts/kernelcore/home/shell/bash.nix | `dclean` | `"docker system prune -af"` |
| hosts/kernelcore/home/shell/bash.nix | `dev` | `"cd ~/dev"` |
| hosts/kernelcore/home/shell/bash.nix | `nx` | `"cd /etc/nixos/"` |
| hosts/kernelcore/home/shell/bash.nix | `reload` | `"source ~/.bashrc"` |
| hosts/kernelcore/home/shell/bash.nix | `reland` | `"hyprctl reload"` |
| hosts/kernelcore/home/shell/bash.nix | `wayreload` | `"killall waybar && waybar &"` |
| hosts/kernelcore/home/shell/bash.nix | `cat` | `"bat"` |
| hosts/kernelcore/home/shell/bash.nix | `grep` | `"rg"` |
| hosts/kernelcore/home/shell/bash.nix | `weather` | `"curl wttr.in"` |
| hosts/kernelcore/home/shell/bash.nix | `bashrcExtra` | `''` |
| hosts/kernelcore/home/shell/bash.nix | `export HISTSIZE` | `10000` |
| hosts/kernelcore/home/shell/bash.nix | `export HISTFILESIZE` | `20000` |
| hosts/kernelcore/home/shell/bash.nix | `export HISTCONTROL` | `ignoredups:erasedups` |
| hosts/kernelcore/home/shell/bash.nix | `export HISTTIMEFORMAT` | `"%F %T "` |
| hosts/kernelcore/home/shell/bash.nix | `export EDITOR` | `"nvim"` |
| hosts/kernelcore/home/shell/bash.nix | `export VISUAL` | `"nvim"` |
| hosts/kernelcore/home/shell/bash.nix | `export BROWSER` | `"brave"` |
| hosts/kernelcore/home/shell/bash.nix | `programs.starship` | `{` |
| hosts/kernelcore/home/shell/bash.nix | `enable` | `true` |
| hosts/kernelcore/home/shell/bash.nix | `enableBashIntegration` | `true` |
| modules/security/kernel.nix | `boot.kernelParams` | `[` |
| modules/security/kernel.nix | `"lockdown` | `confidentiality"` |
| modules/security/kernel.nix | `"init_on_alloc` | `1"` |
| modules/security/kernel.nix | `"init_on_free` | `1"` |
| modules/security/kernel.nix | `"page_alloc.shuffle` | `1"` |
| modules/security/kernel.nix | `"randomize_kstack_offset` | `on"` |
| modules/security/kernel.nix | `"vsyscall` | `none"` |
| modules/security/kernel.nix | `"debugfs` | `off"` |
| modules/security/kernel.nix | `"pti` | `on"` |
| modules/security/kernel.nix | `"oops` | `panic"` |
| modules/security/kernel.nix | `"module.sig_enforce` | `1"` |
| modules/security/kernel.nix | `boot.blacklistedKernelModules` | `[` |
| modules/security/kernel.nix | `boot.kernel.sysctl` | `{` |
| modules/applications/zellij.nix | `zellijConfig` | `''` |
| modules/applications/zellij.nix | `CACHE_DIR` | `"$HOME/.cache/zellij"` |
| modules/applications/zellij.nix | `MAX_CACHE_SIZE_MB` | `50` |
| modules/applications/zellij.nix | `CURRENT_SIZE` | `$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)` |
| modules/applications/zellij.nix | `NEW_SIZE` | `$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)` |
| modules/applications/zellij.nix | `FREED` | `$((CURRENT_SIZE - NEW_SIZE))` |
| modules/applications/zellij.nix | `export ZELLIJ_SESSION_SERIALIZATION` | `false` |
| modules/applications/zellij.nix | `CACHE_SIZE` | `$(du -sm "$HOME/.cache/zellij" 2>/dev/null | cut -f1)` |
| modules/applications/zellij.nix | `default` | `true` |
| modules/applications/zellij.nix | `description` | `"Enable automatic cache cleanup via systemd timer"` |
| modules/applications/zellij.nix | `default` | `"daily"` |
| modules/applications/zellij.nix | `description` | `"Interval for cache cleanup (daily, weekly, monthly)"` |
| modules/applications/zellij.nix | `default` | `50` |
| modules/applications/zellij.nix | `text` | `zellijConfig` |
| modules/applications/zellij.nix | `mode` | `"0644"` |
| modules/applications/zellij.nix | `system.userActivationScripts.zellijConfig` | `''` |
| modules/applications/zellij.nix | `systemd.user.services.zellij-cleanup` | `mkIf cfg.autoCleanup {` |
| modules/applications/zellij.nix | `description` | `"Zellij cache cleanup service"` |
| modules/applications/zellij.nix | `serviceConfig` | `{` |
| modules/applications/zellij.nix | `Type` | `"oneshot"` |
| modules/applications/zellij.nix | `ExecStart` | `"${cleanupScript}/bin/zellij-cleanup"` |
| modules/applications/zellij.nix | `systemd.user.timers.zellij-cleanup` | `mkIf cfg.autoCleanup {` |
| modules/applications/zellij.nix | `description` | `"Zellij cache cleanup timer"` |
| modules/applications/zellij.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/applications/zellij.nix | `timerConfig` | `{` |
| modules/applications/zellij.nix | `OnCalendar` | `cfg.cleanupInterval` |
| modules/applications/zellij.nix | `Persistent` | `true` |
| modules/applications/zellij.nix | `environment.sessionVariables` | `{` |
| modules/security/network.nix | `networking.hostName` | `"nx"` |
| modules/security/network.nix | `networking.networkmanager.enable` | `true` |
| modules/security/network.nix | `networking.firewall` | `{` |
| modules/security/network.nix | `enable` | `true` |
| modules/security/network.nix | `allowedTCPPorts` | `[` |
| modules/security/network.nix | `trustedInterfaces` | `[` |
| modules/security/network.nix | `extraCommands` | `''''` |
| modules/shell/aliases/nix/analytics.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/analytics.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/analytics.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/analytics.nix | `RED` | `'\033[0;31m'` |
| modules/shell/aliases/nix/analytics.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/analytics.nix | `GRAY` | `'\033[0;90m'` |
| modules/shell/aliases/nix/analytics.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/analytics.nix | `METRICS_DIR` | `"$HOME/.cache/nixos-rebuild"` |
| modules/shell/aliases/nix/analytics.nix | `LOG_DIR` | `"/var/log/nixos-rebuild"` |
| modules/shell/aliases/nix/analytics.nix | `TOTAL_BUILDS` | `$(find "$METRICS_DIR" -name "metrics_*.json" 2>/dev/null | wc -l)` |
| modules/shell/aliases/nix/analytics.nix | `SUCCESS_BUILDS` | `$(grep -l '"exit_code": 0' "$METRICS_DIR"/metrics_*.json 2>/dev/null | wc -l)` |
| modules/shell/aliases/nix/analytics.nix | `FAILED_BUILDS` | `$((TOTAL_BUILDS - SUCCESS_BUILDS))` |
| modules/shell/aliases/nix/analytics.nix | `SUCCESS_RATE` | `$((SUCCESS_BUILDS * 100 / TOTAL_BUILDS))` |
| modules/shell/aliases/nix/analytics.nix | `DURATIONS` | `$(grep -h '"duration_seconds"' "$METRICS_DIR"/metrics_*.json 2>/dev/null | \` |
| modules/shell/aliases/nix/analytics.nix | `if [ -n "$DURATIONS" ] && [ "$DURATIONS" !` | `"0" ]; then` |
| modules/shell/aliases/nix/analytics.nix | `TOTAL_TIME` | `0` |
| modules/shell/aliases/nix/analytics.nix | `COUNT` | `0` |
| modules/shell/aliases/nix/analytics.nix | `MIN_TIME` | `999999` |
| modules/shell/aliases/nix/analytics.nix | `MAX_TIME` | `0` |
| modules/shell/aliases/nix/analytics.nix | `TOTAL_TIME` | `$((TOTAL_TIME + duration))` |
| modules/shell/aliases/nix/analytics.nix | `COUNT` | `$((COUNT + 1))` |
| modules/shell/aliases/nix/analytics.nix | `[ $duration -lt $MIN_TIME ] && MIN_TIME` | `$duration` |
| modules/shell/aliases/nix/analytics.nix | `[ $duration -gt $MAX_TIME ] && MAX_TIME` | `$duration` |
| modules/shell/aliases/nix/analytics.nix | `AVG_TIME` | `$((TOTAL_TIME / COUNT))` |
| modules/shell/aliases/nix/analytics.nix | `local seconds` | `$1` |
| modules/shell/aliases/nix/analytics.nix | `local minutes` | `$((seconds / 60))` |
| modules/shell/aliases/nix/analytics.nix | `local hours` | `$((minutes / 60))` |
| modules/shell/aliases/nix/analytics.nix | `minutes` | `$((minutes % 60))` |
| modules/shell/aliases/nix/analytics.nix | `seconds` | `$((seconds % 60))` |
| modules/shell/aliases/nix/analytics.nix | `TIMESTAMP` | `$(basename "$file" | sed 's/metrics_\(.*\)\.json/\1/')` |
| modules/shell/aliases/nix/analytics.nix | `EXIT_CODE` | `$(grep '"exit_code"' "$file" | awk -F': ' '{print $2}' | tr -d ',' || echo "?")` |
| modules/shell/aliases/nix/analytics.nix | `DURATION` | `$(grep '"duration_seconds"' "$file" | awk -F': ' '{print $2}' | tr -d ',' || echo "0")` |
| modules/shell/aliases/nix/analytics.nix | `COMMAND` | `$(grep '"command"' "$file" | awk -F': ' '{print $2}' | tr -d ',"' || echo "unknown")` |
| modules/shell/aliases/nix/analytics.nix | `TS_FORMATTED` | `$(echo "$TIMESTAMP" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5 [... omitted end of long line]` |
| modules/shell/aliases/nix/analytics.nix | `if [ "$EXIT_CODE"` | `= "0" ]; then` |
| modules/shell/aliases/nix/analytics.nix | `STATUS` | `"''${GREEN}✓''${NC}"` |
| modules/shell/aliases/nix/analytics.nix | `STATUS` | `"''${RED}✗''${NC}"` |
| modules/shell/aliases/nix/analytics.nix | `DUR_MIN` | `$((DURATION / 60))` |
| modules/shell/aliases/nix/analytics.nix | `DUR_SEC` | `$((DURATION % 60))` |
| modules/shell/aliases/nix/analytics.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/analytics.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/analytics.nix | `GRAY` | `'\033[0;90m'` |
| modules/shell/aliases/nix/analytics.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/analytics.nix | `LOG_DIR` | `"/var/log/nixos-rebuild"` |
| modules/shell/aliases/nix/analytics.nix | `LOGS` | `$(find "$LOG_DIR" -name "rebuild_*.log" 2>/dev/null | sort -r)` |
| modules/shell/aliases/nix/analytics.nix | `LOG_COUNT` | `$(echo "$LOGS" | wc -l)` |
| modules/shell/aliases/nix/analytics.nix | `i` | `1` |
| modules/shell/aliases/nix/analytics.nix | `FILENAME` | `$(basename "$log")` |
| modules/shell/aliases/nix/analytics.nix | `SIZE` | `$(du -h "$log" 2>/dev/null | cut -f1)` |
| modules/shell/aliases/nix/analytics.nix | `TIMESTAMP` | `$(echo "$FILENAME" | sed 's/rebuild_\(.*\)\.log/\1/' | \` |
| modules/shell/aliases/nix/analytics.nix | `i` | `$((i + 1))` |
| modules/shell/aliases/nix/analytics.nix | `NUM` | `''${2:-1}` |
| modules/shell/aliases/nix/analytics.nix | `LOG` | `$(echo "$LOGS" | sed -n "''${NUM}p")` |
| modules/shell/aliases/nix/analytics.nix | `NUM` | `''${2:-1}` |
| modules/shell/aliases/nix/analytics.nix | `LOG` | `$(echo "$LOGS" | sed -n "''${NUM}p")` |
| modules/shell/aliases/nix/analytics.nix | `LOG` | `$(echo "$LOGS" | head -1)` |
| modules/shell/aliases/nix/analytics.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/analytics.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/analytics.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/analytics.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/analytics.nix | `RED` | `'\033[0;31m'` |
| modules/shell/aliases/nix/analytics.nix | `GRAY` | `'\033[0;90m'` |
| modules/shell/aliases/nix/analytics.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/analytics.nix | `INTERVAL` | `''${1:-2}` |
| modules/shell/aliases/nix/analytics.nix | `CPU_LOAD` | `$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')` |
| modules/shell/aliases/nix/analytics.nix | `CPU_CORES` | `$(nproc)` |
| modules/shell/aliases/nix/analytics.nix | `free -h | awk 'NR` | `=2 {printf "  Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'` |
| modules/shell/aliases/nix/analytics.nix | `df -h /nix | awk 'NR` | `=2 {printf "  Used: %s / %s (%s)\n", $3, $2, $5}'` |
| modules/shell/aliases/nix/analytics.nix | `STORE_SIZE` | `$(du -sh /nix/store 2>/dev/null | cut -f1)` |
| modules/shell/aliases/nix/analytics.nix | `NIXOS_REBUILD` | `$(pgrep -f "nixos-rebuild" | wc -l)` |
| modules/shell/aliases/nix/analytics.nix | `NIX_BUILD` | `$(pgrep -f "nix-build\|nix build" | wc -l)` |
| modules/shell/aliases/nix/analytics.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/analytics.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/analytics.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/analytics.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/analytics.nix | `GRAY` | `'\033[0;90m'` |
| modules/shell/aliases/nix/analytics.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/analytics.nix | `CURRENT` | `$(readlink /nix/var/nix/profiles/system | sed 's/.*-\([0-9]*\)$/\1/')` |
| modules/shell/aliases/nix/analytics.nix | `GEN` | `$(echo "$line" | awk '{print $1}')` |
| modules/shell/aliases/nix/analytics.nix | `if [ "$GEN"` | `= "$CURRENT" ]; then` |
| modules/shell/aliases/nix/analytics.nix | `TOTAL_SIZE` | `$(du -sh /nix/var/nix/profiles/system-* 2>/dev/null | awk '{s+=$1}END{print s}')` |
| modules/shell/aliases/nix/analytics.nix | `environment.systemPackages` | `[` |
| modules/shell/aliases/nix/analytics.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/nix/analytics.nix | `"build-history"` | `"build-history"` |
| modules/packages/tar-packages/packages/zellij.nix | `kernelcore.packages.tar.packages.zellij` | `{` |
| modules/packages/tar-packages/packages/zellij.nix | `enable` | `true` |
| modules/packages/tar-packages/packages/zellij.nix | `method` | `"native"` |
| modules/packages/tar-packages/packages/zellij.nix | `source` | `{` |
| modules/packages/tar-packages/packages/zellij.nix | `path` | `sources.zellij.src` |
| modules/packages/tar-packages/packages/zellij.nix | `sha256` | `""` |
| modules/packages/tar-packages/packages/zellij.nix | `wrapper` | `{` |
| modules/packages/tar-packages/packages/zellij.nix | `executable` | `"zellij"` |
| modules/packages/tar-packages/packages/zellij.nix | `environmentVariables` | `{` |
| modules/packages/tar-packages/packages/zellij.nix | `sandbox` | `{` |
| modules/packages/tar-packages/packages/zellij.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/zellij.nix | `audit` | `{` |
| modules/packages/tar-packages/packages/zellij.nix | `enable` | `false` |
| modules/packages/tar-packages/packages/zellij.nix | `desktopEntry` | `null` |
| modules/hardware/laptop-defense/mcp-integration.nix | `environment.etc."mcp/tools/laptop-defense.json"` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `tools` | `[` |
| modules/hardware/laptop-defense/mcp-integration.nix | `name` | `"thermal_forensics"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Run complete thermal forensics analysis"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `inputSchema` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"object"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `properties` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `duration` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"integer"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `default` | `180` |
| modules/hardware/laptop-defense/mcp-integration.nix | `args` | `[` |
| modules/hardware/laptop-defense/mcp-integration.nix | `name` | `"thermal_warroom"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Real-time thermal monitoring war room"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `inputSchema` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"object"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `properties` | `{ }` |
| modules/hardware/laptop-defense/mcp-integration.nix | `args` | `[` |
| modules/hardware/laptop-defense/mcp-integration.nix | `name` | `"thermal_check"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Quick thermal check before operation"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `inputSchema` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"object"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `properties` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `max_temp` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"integer"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Maximum acceptable temperature (°C)"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `default` | `75` |
| modules/hardware/laptop-defense/mcp-integration.nix | `MAX_ACCEPTABLE` | `"''${1:-75}"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `args` | `[ ]` |
| modules/hardware/laptop-defense/mcp-integration.nix | `name` | `"laptop_verdict"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Generate laptop replacement verdict from evidence"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `inputSchema` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"object"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `properties` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `evidence_dir` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"string"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Path to evidence directory"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `required` | `[ "evidence_dir" ]` |
| modules/hardware/laptop-defense/mcp-integration.nix | `args` | `[` |
| modules/hardware/laptop-defense/mcp-integration.nix | `name` | `"mcp_knowledge_extract"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Extract MCP knowledge related to thermal/rebuild issues"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `inputSchema` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"object"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `properties` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `days_back` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"integer"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Days to look back (default: 7)"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `default` | `7` |
| modules/hardware/laptop-defense/mcp-integration.nix | `args` | `[` |
| modules/hardware/laptop-defense/mcp-integration.nix | `name` | `"rebuild_safety_check"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `description` | `"Pre-rebuild safety check (thermal + resources)"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `inputSchema` | `{` |
| modules/hardware/laptop-defense/mcp-integration.nix | `type` | `"object"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `properties` | `{ }` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"{"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"$RESULT\"thermal_temp\": $TEMP, \"thermal_safe\": $([ $TEMP -le 75 ] && echo true || echo false),"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `MEM_AVAIL` | `$(free -m | grep Mem | awk '{print $7}')` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"$RESULT\"memory_available_mb\": $MEM_AVAIL, \"memory_safe\": $([ $MEM_AVAIL -ge 2000 ] && echo true || echo false),"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `LOAD` | `$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs | cut -d'.' -f1)` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"$RESULT\"load_average\": $LOAD, \"load_safe\": $([ $LOAD -le 10 ] && echo true || echo false),"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"$RESULT\"verdict\": \"SAFE\""` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"$RESULT\"verdict\": \"UNSAFE\""` |
| modules/hardware/laptop-defense/mcp-integration.nix | `RESULT` | `"$RESULT}"` |
| modules/hardware/laptop-defense/mcp-integration.nix | `args` | `[ ]` |
| modules/hardware/laptop-defense/mcp-integration.nix | `environment.systemPackages` | `[` |
| modules/security/ssh.nix | `kernelcore.security.ssh` | `{` |
| modules/security/ssh.nix | `default` | `false` |
| modules/security/ssh.nix | `description` | `"Enable Google Authenticator 2FA for SSH (requires manual setup per user)"` |
| modules/security/ssh.nix | `services.openssh` | `{` |
| modules/security/ssh.nix | `enable` | `true` |
| modules/security/ssh.nix | `hostKeys` | `[` |
| modules/security/ssh.nix | `path` | `"/etc/ssh/ssh_host_ed25519_key"` |
| modules/security/ssh.nix | `type` | `"ed25519"` |
| modules/security/ssh.nix | `path` | `"/etc/ssh/ssh_host_rsa_key"` |
| modules/security/ssh.nix | `type` | `"rsa"` |
| modules/security/ssh.nix | `bits` | `4096` |
| modules/security/ssh.nix | `path` | `"/etc/ssh/ssh_host_ecdsa_key"` |
| modules/security/ssh.nix | `type` | `"ecdsa"` |
| modules/security/ssh.nix | `bits` | `256` |
| modules/security/ssh.nix | `settings` | `{` |
| modules/security/ssh.nix | `PasswordAuthentication` | `false` |
| modules/security/ssh.nix | `PubkeyAuthentication` | `true` |
| modules/security/ssh.nix | `PermitEmptyPasswords` | `false` |
| modules/security/ssh.nix | `UsePAM` | `true` |
| modules/security/ssh.nix | `StrictModes` | `true` |
| modules/security/ssh.nix | `IgnoreRhosts` | `true` |
| modules/security/ssh.nix | `MaxAuthTries` | `3` |
| modules/security/ssh.nix | `MaxSessions` | `2` |
| modules/security/ssh.nix | `ClientAliveInterval` | `300` |
| modules/security/ssh.nix | `ClientAliveCountMax` | `2` |
| modules/security/ssh.nix | `X11Forwarding` | `false` |
| modules/security/ssh.nix | `extraConfig` | `''` |
| modules/security/ssh.nix | `systemd.services.sshd.serviceConfig` | `{` |
| modules/security/ssh.nix | `PrivateTmp` | `true` |
| modules/security/ssh.nix | `ProtectSystem` | `"strict"` |
| modules/security/ssh.nix | `ProtectHome` | `true` |
| modules/security/ssh.nix | `NoNewPrivileges` | `true` |
| modules/security/ssh.nix | `ProtectKernelTunables` | `true` |
| modules/security/ssh.nix | `ProtectKernelModules` | `true` |
| modules/security/ssh.nix | `ProtectControlGroups` | `true` |
| modules/security/ssh.nix | `RestrictNamespaces` | `true` |
| modules/security/ssh.nix | `RestrictRealtime` | `true` |
| modules/security/ssh.nix | `RestrictSUIDSGID` | `true` |
| modules/security/ssh.nix | `RemoveIPC` | `true` |
| modules/security/ssh.nix | `PrivateMounts` | `true` |
| modules/security/ssh.nix | `SystemCallFilter` | `"@system-service"` |
| modules/security/ssh.nix | `SystemCallErrorNumber` | `"EPERM"` |
| modules/security/ssh.nix | `CapabilityBoundingSet` | `"CAP_NET_BIND_SERVICE CAP_DAC_READ_SEARCH"` |
| modules/security/ssh.nix | `AmbientCapabilities` | `""` |
| modules/security/ssh.nix | `googleAuthenticator` | `{` |
| modules/security/ssh.nix | `enable` | `true` |
| modules/security/ssh.nix | `auth required pam_google_authenticator.so nullok secret` | `/home/\''${USER}/.google_authenticator` |
| modules/security/ssh.nix | `text` | `''` |
| modules/security/ssh.nix | `mode` | `"0644"` |
| modules/hardware/bluetooth.nix | `hardware.bluetooth` | `{` |
| modules/hardware/bluetooth.nix | `enable` | `true` |
| modules/hardware/bluetooth.nix | `powerOnBoot` | `true; # Power on Bluetooth adapter on boot` |
| modules/hardware/bluetooth.nix | `settings` | `{` |
| modules/hardware/bluetooth.nix | `General` | `{` |
| modules/hardware/bluetooth.nix | `Enable` | `"Source,Sink,Media,Socket"` |
| modules/hardware/bluetooth.nix | `Experimental` | `true; # Enable experimental features` |
| modules/hardware/bluetooth.nix | `services.blueman.enable` | `true` |
| modules/hardware/bluetooth.nix | `hardware.bluetooth.settings.Policy` | `{` |
| modules/hardware/bluetooth.nix | `AutoEnable` | `true` |
| modules/packages/lib/builders.nix | `enable` | `false` |
| modules/packages/lib/builders.nix | `blockHardware` | `[ ]` |
| modules/packages/lib/builders.nix | `allowedPaths` | `[ ]` |
| modules/packages/lib/builders.nix | `wrapper` | `{` |
| modules/packages/lib/builders.nix | `name` | `name` |
| modules/packages/lib/builders.nix | `environmentVariables` | `{ }` |
| modules/packages/lib/builders.nix | `extraArgs` | `[ ]` |
| modules/packages/lib/builders.nix | `executable` | `null` |
| modules/packages/lib/builders.nix | `blockDevices` | `sandboxLib.mkHardwareBlockArgs sandbox.blockHardware` |
| modules/packages/lib/builders.nix | `allowedPathsArgs` | `sandboxLib.mkPathAllowArgs sandbox.allowedPaths` |
| modules/packages/lib/builders.nix | `binPath` | `if wrapper.executable != null then wrapper.executable else "bin/${name}"` |
| modules/packages/lib/builders.nix | `relBinPath` | `removePrefix "/" binPath` |
| modules/packages/lib/builders.nix | `finalMeta` | `meta // {` |
| modules/packages/lib/builders.nix | `platforms` | `meta.platforms or [ "x86_64-linux" ]` |
| modules/packages/lib/builders.nix | `if (meta.license or null)` | `= "Proprietary" || (meta.license or null) == null then` |
| modules/packages/lib/builders.nix | `name` | `"${name}-fhs"` |
| modules/packages/lib/builders.nix | `targetPkgs` | `targetPkgs` |
| modules/packages/lib/builders.nix | `profile` | `''` |
| modules/packages/lib/builders.nix | `export PATH` | `"${extracted}/bin:${extracted}/usr/bin:${extracted}/usr/local/bin:$PATH"` |
| modules/packages/lib/builders.nix | `export LD_LIBRARY_PATH` | `"${extracted}/lib:${extracted}/usr/lib:${extracted}/usr/local/lib:$LD_LIBRARY_PATH"` |
| modules/packages/lib/builders.nix | `${concatStringsSep "\n" (mapAttrsToList (n: v: "export ${n}` | `'${v}'") wrapper.environmentVariables)}` |
| modules/packages/lib/builders.nix | `if runScript !` | `null then` |
| modules/packages/lib/builders.nix | `else if wrapper.extraArgs !` | `[ ] then` |
| modules/packages/lib/builders.nix | `meta` | `finalMeta` |
| modules/packages/lib/builders.nix | `enable` | `false` |
| modules/packages/lib/builders.nix | `blockHardware` | `[ ]` |
| modules/packages/lib/builders.nix | `allowedPaths` | `[ ]` |
| modules/packages/lib/builders.nix | `wrapper` | `{` |
| modules/packages/lib/builders.nix | `name` | `name` |
| modules/packages/lib/builders.nix | `environmentVariables` | `{ }` |
| modules/packages/lib/builders.nix | `extraArgs` | `[ ]` |
| modules/packages/lib/builders.nix | `executable` | `null` |
| modules/packages/lib/builders.nix | `buildInputs` | `[` |
| modules/packages/lib/builders.nix | `binPath` | `if wrapper.executable != null then wrapper.executable else "bin/${name}"` |
| modules/packages/lib/builders.nix | `relBinPath` | `removePrefix "/" binPath` |
| modules/packages/lib/builders.nix | `blockArgs` | `sandboxLib.mkHardwareBlockArgs sandbox.blockHardware` |
| modules/packages/lib/builders.nix | `allowArgs` | `sandboxLib.mkPathAllowArgs sandbox.allowedPaths` |
| modules/packages/lib/builders.nix | `lib_count` | `$(find ${extracted}/usr/lib -type f 2>/dev/null | wc -l || echo 0)` |
| modules/security/dev-directory-hardening.nix | `userName` | `"kernelcore"` |
| modules/security/dev-directory-hardening.nix | `devPath` | `"/home/${userName}/dev"` |
| modules/security/dev-directory-hardening.nix | `default` | `userName` |
| modules/security/dev-directory-hardening.nix | `description` | `"User that owns the dev directory"` |
| modules/security/dev-directory-hardening.nix | `default` | `devPath` |
| modules/security/dev-directory-hardening.nix | `description` | `"Path to development directory"` |
| modules/security/dev-directory-hardening.nix | `default` | `false` |
| modules/security/dev-directory-hardening.nix | `description` | `''` |
| modules/security/dev-directory-hardening.nix | `default` | `true` |
| modules/security/dev-directory-hardening.nix | `description` | `"Enable audit logging for dev directory access"` |
| modules/security/dev-directory-hardening.nix | `default` | `true` |
| modules/security/dev-directory-hardening.nix | `description` | `"Enable automated encrypted backups"` |
| modules/security/dev-directory-hardening.nix | `default` | `"daily"` |
| modules/security/dev-directory-hardening.nix | `description` | `"Backup frequency (daily, weekly, hourly)"` |
| modules/security/dev-directory-hardening.nix | `default` | `[` |
| modules/security/dev-directory-hardening.nix | `description` | `"Processes allowed to access dev directory (for AppArmor)"` |
| modules/security/dev-directory-hardening.nix | `systemd.tmpfiles.rules` | `[` |
| modules/security/dev-directory-hardening.nix | `environment.systemPackages` | `mkIf cfg.enableEncryption [` |
| modules/security/dev-directory-hardening.nix | `security.auditd.enable` | `mkIf cfg.enableAudit true` |
| modules/security/dev-directory-hardening.nix | `security.audit.rules` | `mkIf cfg.enableAudit [` |
| modules/security/dev-directory-hardening.nix | `"-w ${cfg.path} -p wa -k dev-cargo-build -F exe` | `/usr/bin/cargo"` |
| modules/security/dev-directory-hardening.nix | `environment.systemPackages` | `[` |
| modules/security/dev-directory-hardening.nix | `database` | `file:/var/lib/aide/aide.db` |
| modules/security/dev-directory-hardening.nix | `database_out` | `file:/var/lib/aide/aide.db.new` |
| modules/security/dev-directory-hardening.nix | `systemd.services.aide-check` | `{` |
| modules/security/dev-directory-hardening.nix | `description` | `"AIDE File Integrity Check for ~/dev"` |
| modules/security/dev-directory-hardening.nix | `serviceConfig` | `{` |
| modules/security/dev-directory-hardening.nix | `Type` | `"oneshot"` |
| modules/security/dev-directory-hardening.nix | `User` | `"root"` |
| modules/security/dev-directory-hardening.nix | `systemd.timers.aide-check` | `{` |
| modules/security/dev-directory-hardening.nix | `description` | `"Daily AIDE Check Timer"` |
| modules/security/dev-directory-hardening.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/security/dev-directory-hardening.nix | `timerConfig` | `{` |
| modules/security/dev-directory-hardening.nix | `OnCalendar` | `"daily"` |
| modules/security/dev-directory-hardening.nix | `Persistent` | `true` |
| modules/security/dev-directory-hardening.nix | `systemd.services.dev-backup` | `mkIf cfg.enableBackup {` |
| modules/security/dev-directory-hardening.nix | `description` | `"Encrypted backup of ~/dev directory"` |
| modules/security/dev-directory-hardening.nix | `serviceConfig` | `{` |
| modules/security/dev-directory-hardening.nix | `Type` | `"oneshot"` |
| modules/security/dev-directory-hardening.nix | `User` | `cfg.user` |
| modules/security/dev-directory-hardening.nix | `Group` | `cfg.user` |
| modules/security/dev-directory-hardening.nix | `PrivateTmp` | `true` |
| modules/security/dev-directory-hardening.nix | `ProtectSystem` | `"strict"` |
| modules/security/dev-directory-hardening.nix | `ProtectHome` | `"read-only"` |
| modules/security/dev-directory-hardening.nix | `ReadWritePaths` | `[` |
| modules/security/dev-directory-hardening.nix | `NoNewPrivileges` | `true` |
| modules/security/dev-directory-hardening.nix | `script` | `''` |
| modules/security/dev-directory-hardening.nix | `BACKUP_DATE` | `$(date +%Y%m%d-%H%M%S)` |
| modules/security/dev-directory-hardening.nix | `BACKUP_STAGING` | `"${cfg.path}/.backup-staging"` |
| modules/security/dev-directory-hardening.nix | `BACKUP_DEST` | `"/backup/dev-backups"` |
| modules/security/dev-directory-hardening.nix | `--exclude` | `'*/target' \` |
| modules/security/dev-directory-hardening.nix | `--exclude` | `'*/node_modules' \` |
| modules/security/dev-directory-hardening.nix | `--exclude` | `'*/build' \` |
| modules/security/dev-directory-hardening.nix | `--exclude` | `'*/.git/objects' \` |
| modules/security/dev-directory-hardening.nix | `--exclude` | `'*.db' \` |
| modules/security/dev-directory-hardening.nix | `--exclude` | `'*.db-*' \` |
| modules/security/dev-directory-hardening.nix | `SIZE` | `$(du -h "$BACKUP_DEST/dev-backup-$BACKUP_DATE.tar.gz.gpg" | cut -f1)` |
| modules/security/dev-directory-hardening.nix | `systemd.timers.dev-backup` | `mkIf cfg.enableBackup {` |
| modules/security/dev-directory-hardening.nix | `description` | `"Dev Directory Backup Timer"` |
| modules/security/dev-directory-hardening.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/security/dev-directory-hardening.nix | `timerConfig` | `{` |
| modules/security/dev-directory-hardening.nix | `OnCalendar` | `cfg.backupInterval` |
| modules/security/dev-directory-hardening.nix | `Persistent` | `true` |
| modules/security/dev-directory-hardening.nix | `RandomizedDelaySec` | `"30min"` |
| modules/security/dev-directory-hardening.nix | `systemd.services.dev-access-monitor` | `{` |
| modules/security/dev-directory-hardening.nix | `description` | `"Monitor unusual access to ~/dev"` |
| modules/security/dev-directory-hardening.nix | `serviceConfig` | `{` |
| modules/security/dev-directory-hardening.nix | `Type` | `"simple"` |
| modules/security/dev-directory-hardening.nix | `Restart` | `"always"` |
| modules/security/dev-directory-hardening.nix | `RestartSec` | `10` |
| modules/security/dev-directory-hardening.nix | `User` | `"root"` |
| modules/security/dev-directory-hardening.nix | `PrivateTmp` | `true` |
| modules/security/dev-directory-hardening.nix | `ProtectSystem` | `"strict"` |
| modules/security/dev-directory-hardening.nix | `ProtectHome` | `true` |
| modules/security/dev-directory-hardening.nix | `NoNewPrivileges` | `true` |
| modules/security/dev-directory-hardening.nix | `RestrictNamespaces` | `true` |
| modules/security/dev-directory-hardening.nix | `RestrictRealtime` | `true` |
| modules/security/dev-directory-hardening.nix | `RestrictSUIDSGID` | `true` |
| modules/security/dev-directory-hardening.nix | `script` | `''` |
| modules/security/dev-directory-hardening.nix | `systemd.services.dev-access-monitor.wantedBy` | `[ "multi-user.target" ]` |
| modules/security/dev-directory-hardening.nix | `environment.variables` | `{` |
| modules/security/dev-directory-hardening.nix | `GIT_CREDENTIAL_HELPER` | `"cache --timeout=3600"` |
| modules/security/dev-directory-hardening.nix | `environment.shellAliases` | `{` |
| modules/security/dev-directory-hardening.nix | `git-commit-safe` | `''` |
| modules/security/dev-directory-hardening.nix | `environment.systemPackages` | `[` |
| modules/security/dev-directory-hardening.nix | `EMERGENCY_BACKUP` | `"/backup/emergency-dev-$(date +%Y%m%d-%H%M%S).tar.gz.gpg"` |
| modules/packages/appflowy.nix | `pname` | `"appflowy"` |
| modules/packages/appflowy.nix | `version` | `"0.10.6"` |
| modules/packages/appflowy.nix | `url` | `"https://github.com/AppFlowy-IO/appflowy/releases/download/${finalAttrs.version}/AppFlowy-${finalAttrs.version}-linux-x86_64.tar.gz"` |
| modules/packages/appflowy.nix | `hash` | `"sha256-87mauW50ccOaPyK04O4I7+0bsvxVrdFxhi/Muc53wDY="` |
| modules/packages/appflowy.nix | `stripRoot` | `false` |
| modules/packages/appflowy.nix | `nativeBuildInputs` | `[` |
| modules/packages/appflowy.nix | `buildInputs` | `[` |
| modules/packages/appflowy.nix | `dontBuild` | `true` |
| modules/packages/appflowy.nix | `dontConfigure` | `true` |
| modules/packages/appflowy.nix | `installPhase` | `''` |
| modules/packages/appflowy.nix | `preFixup` | `''` |
| modules/packages/appflowy.nix | `desktopItems` | `[` |
| modules/packages/appflowy.nix | `name` | `"appflowy"` |
| modules/packages/appflowy.nix | `desktopName` | `"AppFlowy"` |
| modules/packages/appflowy.nix | `comment` | `finalAttrs.meta.description` |
| modules/packages/appflowy.nix | `exec` | `"appflowy %U"` |
| modules/packages/appflowy.nix | `icon` | `"appflowy"` |
| modules/packages/appflowy.nix | `categories` | `[ "Office" ]` |
| modules/packages/appflowy.nix | `mimeTypes` | `[ "x-scheme-handler/appflowy-flutter" ]` |
| modules/packages/appflowy.nix | `description` | `"Open-source alternative to Notion"` |
| modules/packages/appflowy.nix | `homepage` | `"https://www.appflowy.io/"` |
| modules/packages/appflowy.nix | `license` | `licenses.agpl3Only` |
| modules/packages/appflowy.nix | `platforms` | `[ "x86_64-linux" ]` |
| modules/packages/appflowy.nix | `mainProgram` | `"appflowy"` |
| modules/packages/appflowy.nix | `environment.systemPackages` | `[ appflowy ]` |
| modules/applications/brave-secure.nix | `default` | `"2G"` |
| modules/applications/brave-secure.nix | `description` | `"GPU memory limit for Brave (e.g., '2G', '1024M')"` |
| modules/applications/brave-secure.nix | `default` | `true` |
| modules/applications/brave-secure.nix | `description` | `"Enable additional security hardening via Firejail"` |
| modules/applications/brave-secure.nix | `default` | `[` |
| modules/applications/brave-secure.nix | `"--enable-features` | `VaapiVideoDecoder"` |
| modules/applications/brave-secure.nix | `"--disable-features` | `UseChromeOSDirectVideoDecoder"` |
| modules/applications/brave-secure.nix | `description` | `"Custom Chromium flags for Brave"` |
| modules/applications/brave-secure.nix | `mode` | `"0755"` |
| modules/applications/brave-secure.nix | `text` | `''` |
| modules/applications/brave-secure.nix | `GPU_MEM_LIMIT` | `"${cfg.gpuMemoryLimit}"` |
| modules/applications/brave-secure.nix | `CGROUP_NAME` | `"brave-gpu-limited"` |
| modules/applications/brave-secure.nix | `Version` | `1.0` |
| modules/applications/brave-secure.nix | `Name` | `Brave Browser (Secure/GPU Limited)` |
| modules/applications/brave-secure.nix | `GenericName` | `Web Browser` |
| modules/applications/brave-secure.nix | `Exec` | `/etc/brave-wrapper.sh %U` |
| modules/applications/brave-secure.nix | `Icon` | `brave-browser` |
| modules/applications/brave-secure.nix | `Terminal` | `false` |
| modules/applications/brave-secure.nix | `Type` | `Application` |
| modules/applications/brave-secure.nix | `MimeType` | `text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https` |
| modules/applications/brave-secure.nix | `Categories` | `Network;WebBrowser` |
| modules/applications/brave-secure.nix | `Keywords` | `browser;web;internet` |
| modules/applications/brave-secure.nix | `StartupNotify` | `true` |
| modules/applications/brave-secure.nix | `StartupWMClass` | `Brave-browser` |
| modules/applications/brave-secure.nix | `systemd.user.services.brave-gpu-monitor` | `{` |
| modules/applications/brave-secure.nix | `description` | `"Monitor Brave GPU Memory Usage"` |
| modules/applications/brave-secure.nix | `after` | `[ "graphical-session.target" ]` |
| modules/applications/brave-secure.nix | `serviceConfig` | `{` |
| modules/applications/brave-secure.nix | `Type` | `"simple"` |
| modules/applications/brave-secure.nix | `Restart` | `"on-failure"` |
| modules/applications/brave-secure.nix | `RestartSec` | `30` |
| modules/applications/brave-secure.nix | `security.sudo.extraRules` | `[` |
| modules/applications/brave-secure.nix | `users` | `[ "kernelcore" ]` |
| modules/applications/brave-secure.nix | `commands` | `[` |
| modules/applications/brave-secure.nix | `environment.sessionVariables` | `{` |
| modules/applications/brave-secure.nix | `BRAVE_GPU_MEMORY_BUFFER_SIZE` | `"256"` |
| modules/applications/brave-secure.nix | `BRAVE_DISABLE_GPU_DRIVER_BUG_WORKAROUNDS` | `"1"` |
| modules/security/keyring.nix | `default` | `true` |
| modules/security/keyring.nix | `description` | `"Enable Seahorse GUI for keyring management"` |
| modules/security/keyring.nix | `default` | `true` |
| modules/security/keyring.nix | `description` | `"Enable KeePassXC Secret Service API integration"` |
| modules/security/keyring.nix | `default` | `true` |
| modules/security/keyring.nix | `services.gnome.gnome-keyring.enable` | `true` |
| modules/security/keyring.nix | `security.pam.services` | `mkIf cfg.autoUnlock {` |
| modules/security/keyring.nix | `login.enableGnomeKeyring` | `true` |
| modules/security/keyring.nix | `gdm.enableGnomeKeyring` | `true` |
| modules/security/keyring.nix | `lightdm.enableGnomeKeyring` | `true` |
| modules/security/keyring.nix | `greetd.enableGnomeKeyring` | `true` |
| modules/security/keyring.nix | `systemd.user.services.gnome-keyring` | `{` |
| modules/security/keyring.nix | `description` | `"GNOME Keyring daemon"` |
| modules/security/keyring.nix | `documentation` | `[ "man:gnome-keyring-daemon(1)" ]` |
| modules/security/keyring.nix | `wantedBy` | `[ "graphical-session.target" ]` |
| modules/security/keyring.nix | `wants` | `[ "graphical-session.target" ]` |
| modules/security/keyring.nix | `after` | `[ "graphical-session.target" ]` |
| modules/security/keyring.nix | `before` | `[ "graphical-session-pre.target" ]` |
| modules/security/keyring.nix | `partOf` | `[ "graphical-session.target" ]` |
| modules/security/keyring.nix | `serviceConfig` | `{` |
| modules/security/keyring.nix | `Type` | `"simple"` |
| modules/security/keyring.nix | `Restart` | `"on-failure"` |
| modules/security/keyring.nix | `RestartSec` | `1` |
| modules/security/keyring.nix | `TimeoutStopSec` | `10` |
| modules/security/keyring.nix | `Environment` | `[` |
| modules/security/keyring.nix | `"SSH_AUTH_SOCK` | `%t/keyring/ssh"` |
| modules/security/keyring.nix | `environment.sessionVariables` | `{` |
| modules/security/keyring.nix | `GNOME_KEYRING_CONTROL` | `"/run/user/$UID/keyring"` |
| modules/security/keyring.nix | `SSH_AUTH_SOCK` | `"/run/user/$UID/keyring/ssh"` |
| modules/security/keyring.nix | `Type` | `Application` |
| modules/security/keyring.nix | `Name` | `GNOME Keyring: Secret Service` |
| modules/security/keyring.nix | `OnlyShowIn` | `GNOME;Unity;MATE;Hyprland` |
| modules/security/keyring.nix | `NoDisplay` | `true` |
| modules/security/keyring.nix | `X-GNOME-Autostart-Phase` | `Initialization` |
| modules/security/keyring.nix | `X-GNOME-AutoRestart` | `true` |
| modules/security/keyring.nix | `X-GNOME-Autostart-Notify` | `true` |
| modules/security/keyring.nix | `Type` | `Application` |
| modules/security/keyring.nix | `Name` | `GNOME Keyring: SSH Agent` |
| modules/security/keyring.nix | `OnlyShowIn` | `GNOME;Unity;MATE;Hyprland` |
| modules/security/keyring.nix | `NoDisplay` | `true` |
| modules/security/keyring.nix | `X-GNOME-Autostart-Phase` | `PreDisplayServer` |
| modules/security/keyring.nix | `X-GNOME-AutoRestart` | `true` |
| modules/security/keyring.nix | `X-GNOME-Autostart-Notify` | `true` |
| modules/shell/aliases/nix/system.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/nix/system.nix | `"nx-rebuild"` | `"sudo nixos-rebuild switch --flake '/etc/nixos#kernelcore'"` |
| modules/packages/tar-packages/builder.nix | `executable` | `"${extracted}/${pkg.wrapper.executable or name}"` |
| modules/packages/tar-packages/builder.nix | `targetTriple` | `fetchers.detectTargetTriple (pkg.wrapper.executable or name)` |
| modules/packages/tar-packages/builder.nix | `if targetTriple` | `= "musl" then` |
| modules/packages/tar-packages/builder.nix | `method` | `"native"` |
| modules/packages/tar-packages/builder.nix | `reason` | `"MUSL binaries are statically linked"` |
| modules/packages/tar-packages/builder.nix | `method` | `"fhs"` |
| modules/packages/tar-packages/builder.nix | `reason` | `"GNU dynamically linked"` |
| modules/packages/tar-packages/builder.nix | `method` | `"fhs"` |
| modules/packages/tar-packages/builder.nix | `reason` | `"Package includes dynamic libraries"` |
| modules/packages/tar-packages/builder.nix | `method` | `"native"` |
| modules/packages/tar-packages/builder.nix | `reason` | `"Statically linked binary"` |
| modules/packages/tar-packages/builder.nix | `method` | `"native"` |
| modules/packages/tar-packages/builder.nix | `reason` | `"Default fallback"` |
| modules/packages/tar-packages/builder.nix | `tarFile` | `fetchers.fetchSource name pkg.source "tar.gz"` |
| modules/packages/tar-packages/builder.nix | `extracted` | `fetchers.extractTarball name tarFile` |
| modules/packages/tar-packages/builder.nix | `method` | `if pkg.method == "auto" then autoDetectMethod name pkg extracted else pkg.method` |
| modules/packages/tar-packages/builder.nix | `commonArgs` | `{` |
| modules/packages/tar-packages/builder.nix | `sandbox` | `pkg.sandbox` |
| modules/packages/tar-packages/builder.nix | `wrapper_raw` | `pkg.wrapper` |
| modules/packages/tar-packages/builder.nix | `if pkg.meta !` | `{ } then` |
| modules/packages/tar-packages/builder.nix | `description` | `"${name} package"` |
| modules/packages/tar-packages/builder.nix | `license` | `lib.licenses.unfree` |
| modules/packages/tar-packages/builder.nix | `platforms` | `[ "x86_64-linux" ]` |
| modules/packages/tar-packages/builder.nix | `package` | `if method == "fhs" then builders.buildFHS commonArgs else builders.buildNative commonArgs` |
| modules/hardware/thermal-profiles.nix | `profiles` | `{` |
| modules/hardware/thermal-profiles.nix | `silent` | `{` |
| modules/hardware/thermal-profiles.nix | `description` | `"Silent mode - 35W sustained, minimal noise"` |
| modules/hardware/thermal-profiles.nix | `intel` | `{` |
| modules/hardware/thermal-profiles.nix | `powerProfile` | `"silent"` |
| modules/hardware/thermal-profiles.nix | `governor` | `"powersave"` |
| modules/hardware/thermal-profiles.nix | `minFreq` | `20` |
| modules/hardware/thermal-profiles.nix | `maxFreq` | `70` |
| modules/hardware/thermal-profiles.nix | `turboBoost` | `false` |
| modules/hardware/thermal-profiles.nix | `epp` | `"power"` |
| modules/hardware/thermal-profiles.nix | `throttled` | `{` |
| modules/hardware/thermal-profiles.nix | `profile` | `"silent"` |
| modules/hardware/thermal-profiles.nix | `nvidia` | `{` |
| modules/hardware/thermal-profiles.nix | `powerLimit` | `35` |
| modules/hardware/thermal-profiles.nix | `balanced` | `{` |
| modules/hardware/thermal-profiles.nix | `description` | `"Balanced mode - 45W sustained, good balance"` |
| modules/hardware/thermal-profiles.nix | `intel` | `{` |
| modules/hardware/thermal-profiles.nix | `powerProfile` | `"balanced"` |
| modules/hardware/thermal-profiles.nix | `governor` | `"schedutil"` |
| modules/hardware/thermal-profiles.nix | `minFreq` | `20` |
| modules/hardware/thermal-profiles.nix | `maxFreq` | `100` |
| modules/hardware/thermal-profiles.nix | `turboBoost` | `true` |
| modules/hardware/thermal-profiles.nix | `epp` | `"balance_performance"` |
| modules/hardware/thermal-profiles.nix | `throttled` | `{` |
| modules/hardware/thermal-profiles.nix | `profile` | `"balanced"` |
| modules/hardware/thermal-profiles.nix | `nvidia` | `{` |
| modules/hardware/thermal-profiles.nix | `powerLimit` | `60` |
| modules/hardware/thermal-profiles.nix | `performance` | `{` |
| modules/hardware/thermal-profiles.nix | `description` | `"Performance mode - 55W sustained, maximum performance"` |
| modules/hardware/thermal-profiles.nix | `intel` | `{` |
| modules/hardware/thermal-profiles.nix | `powerProfile` | `"performance"` |
| modules/hardware/thermal-profiles.nix | `governor` | `"performance"` |
| modules/hardware/thermal-profiles.nix | `minFreq` | `50` |
| modules/hardware/thermal-profiles.nix | `maxFreq` | `100` |
| modules/hardware/thermal-profiles.nix | `turboBoost` | `true` |
| modules/hardware/thermal-profiles.nix | `epp` | `"performance"` |
| modules/hardware/thermal-profiles.nix | `throttled` | `{` |
| modules/hardware/thermal-profiles.nix | `profile` | `"performance"` |
| modules/hardware/thermal-profiles.nix | `nvidia` | `{` |
| modules/hardware/thermal-profiles.nix | `powerLimit` | `95` |
| modules/hardware/thermal-profiles.nix | `default` | `"balanced"` |
| modules/hardware/thermal-profiles.nix | `description` | `"Current active thermal profile"` |
| modules/hardware/thermal-profiles.nix | `autoSwitch` | `{` |
| modules/hardware/thermal-profiles.nix | `default` | `20` |
| modules/hardware/thermal-profiles.nix | `description` | `"CPU usage below this switches to silent (%)"` |
| modules/hardware/thermal-profiles.nix | `default` | `70` |
| modules/hardware/thermal-profiles.nix | `description` | `"CPU usage above this switches to performance (%)"` |
| modules/hardware/thermal-profiles.nix | `default` | `30` |
| modules/hardware/thermal-profiles.nix | `temperatureMonitoring` | `{` |
| modules/hardware/thermal-profiles.nix | `default` | `true` |
| modules/hardware/thermal-profiles.nix | `default` | `80` |
| modules/hardware/thermal-profiles.nix | `description` | `"Temperature warning threshold (°C)"` |
| modules/hardware/thermal-profiles.nix | `default` | `90` |
| modules/hardware/thermal-profiles.nix | `description` | `"Temperature critical threshold - force silent mode (°C)"` |
| modules/hardware/thermal-profiles.nix | `kernelcore.hardware.intel` | `{` |
| modules/hardware/thermal-profiles.nix | `enable` | `true` |
| modules/hardware/thermal-profiles.nix | `powerProfile` | `profiles.${cfg.currentProfile}.intel.powerProfile` |
| modules/hardware/thermal-profiles.nix | `governor.default` | `profiles.${cfg.currentProfile}.intel.governor` |
| modules/hardware/thermal-profiles.nix | `pstate` | `{` |
| modules/hardware/thermal-profiles.nix | `minFreqPercent` | `profiles.${cfg.currentProfile}.intel.minFreq` |
| modules/hardware/thermal-profiles.nix | `maxFreqPercent` | `profiles.${cfg.currentProfile}.intel.maxFreq` |
| modules/hardware/thermal-profiles.nix | `energyPerformancePreference` | `profiles.${cfg.currentProfile}.intel.epp` |
| modules/hardware/thermal-profiles.nix | `turboBoost.enable` | `profiles.${cfg.currentProfile}.intel.turboBoost` |
| modules/hardware/thermal-profiles.nix | `kernelcore.hardware.lenovoThrottled` | `{` |
| modules/hardware/thermal-profiles.nix | `enable` | `true` |
| modules/hardware/thermal-profiles.nix | `profile` | `profiles.${cfg.currentProfile}.throttled.profile` |
| modules/hardware/thermal-profiles.nix | `systemd.services.thermal-profile-manager` | `{` |
| modules/hardware/thermal-profiles.nix | `description` | `"Thermal Profile Manager - Unified control for i5-13420H + RTX 3050"` |
| modules/hardware/thermal-profiles.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/thermal-profiles.nix | `after` | `[` |
| modules/hardware/thermal-profiles.nix | `serviceConfig` | `{` |
| modules/hardware/thermal-profiles.nix | `Type` | `"simple"` |
| modules/hardware/thermal-profiles.nix | `Restart` | `"always"` |
| modules/hardware/thermal-profiles.nix | `RestartSec` | `"10s"` |
| modules/hardware/thermal-profiles.nix | `script` | `''` |
| modules/hardware/thermal-profiles.nix | `PROFILE_FILE` | `"/var/lib/thermal-profile/current"` |
| modules/hardware/thermal-profiles.nix | `STATS_FILE` | `"/var/lib/thermal-profile/stats.log"` |
| modules/hardware/thermal-profiles.nix | `local profile` | `$1` |
| modules/hardware/thermal-profiles.nix | `local temp` | `$2` |
| modules/hardware/thermal-profiles.nix | `local cpu_usage` | `$3` |
| modules/hardware/thermal-profiles.nix | `local reason` | `$4` |
| modules/hardware/thermal-profiles.nix | `temp` | `$(get_cpu_temp)` |
| modules/hardware/thermal-profiles.nix | `cpu_usage` | `$(get_cpu_usage)` |
| modules/hardware/thermal-profiles.nix | `current_profile` | `$(cat "$PROFILE_FILE" 2>/dev/null || echo "${cfg.currentProfile}")` |
| modules/hardware/thermal-profiles.nix | `temp` | `$(get_cpu_temp)` |
| modules/hardware/thermal-profiles.nix | `cpu_usage` | `$(get_cpu_usage)` |
| modules/hardware/thermal-profiles.nix | `current_profile` | `$(cat "$PROFILE_FILE" 2>/dev/null || echo "${cfg.currentProfile}")` |
| modules/hardware/thermal-profiles.nix | `systemd.services.thermal-profile-info` | `{` |
| modules/hardware/thermal-profiles.nix | `description` | `"Display current thermal profile information"` |
| modules/hardware/thermal-profiles.nix | `serviceConfig` | `{` |
| modules/hardware/thermal-profiles.nix | `Type` | `"oneshot"` |
| modules/hardware/thermal-profiles.nix | `RemainAfterExit` | `true` |
| modules/hardware/thermal-profiles.nix | `script` | `''` |
| modules/hardware/thermal-profiles.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/thermal-profiles.nix | `systemd.tmpfiles.rules` | `[` |
| modules/hardware/thermal-profiles.nix | `environment.systemPackages` | `[` |
| modules/hardware/thermal-profiles.nix | `PROFILE_FILE` | `"/var/lib/thermal-profile/current"` |
| modules/hardware/thermal-profiles.nix | `STATS_FILE` | `"/var/lib/thermal-profile/stats.log"` |
| modules/hardware/trezor.nix | `default` | `false` |
| modules/hardware/trezor.nix | `description` | `"Enable Trezor as SSH authentication agent"` |
| modules/hardware/trezor.nix | `users.groups.plugdev` | `{ }` |
| modules/hardware/trezor.nix | `environment.variables` | `mkIf cfg.enableSSHAgent {` |
| modules/hardware/trezor.nix | `SSH_AUTH_SOCK` | `"\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"` |
| modules/hardware/trezor.nix | `text` | `''` |
| modules/hardware/trezor.nix | `alias tssh` | `'trezor-agent user@hostname -- ssh'` |
| modules/hardware/trezor.nix | `alias tgit` | `'trezor-agent git@github.com -- git'` |
| modules/hardware/trezor.nix | `mode` | `"0644"` |
| modules/hardware/lenovo-throttled.nix | `powerLimits` | `{` |
| modules/hardware/lenovo-throttled.nix | `silent` | `{` |
| modules/hardware/lenovo-throttled.nix | `pl1` | `35` |
| modules/hardware/lenovo-throttled.nix | `pl2` | `55` |
| modules/hardware/lenovo-throttled.nix | `duration` | `28` |
| modules/hardware/lenovo-throttled.nix | `balanced` | `{` |
| modules/hardware/lenovo-throttled.nix | `pl1` | `45` |
| modules/hardware/lenovo-throttled.nix | `pl2` | `65` |
| modules/hardware/lenovo-throttled.nix | `duration` | `28` |
| modules/hardware/lenovo-throttled.nix | `performance` | `{` |
| modules/hardware/lenovo-throttled.nix | `pl1` | `55` |
| modules/hardware/lenovo-throttled.nix | `pl2` | `80` |
| modules/hardware/lenovo-throttled.nix | `duration` | `28` |
| modules/hardware/lenovo-throttled.nix | `currentProfile` | `cfg.profile` |
| modules/hardware/lenovo-throttled.nix | `pl` | `powerLimits.${currentProfile}` |
| modules/hardware/lenovo-throttled.nix | `default` | `"balanced"` |
| modules/hardware/lenovo-throttled.nix | `description` | `''` |
| modules/hardware/lenovo-throttled.nix | `default` | `85` |
| modules/hardware/lenovo-throttled.nix | `description` | `"Temperature threshold for thermal throttling (°C)"` |
| modules/hardware/lenovo-throttled.nix | `default` | `true` |
| modules/hardware/lenovo-throttled.nix | `default` | `5` |
| modules/hardware/lenovo-throttled.nix | `services.throttled` | `{` |
| modules/hardware/lenovo-throttled.nix | `enable` | `true` |
| modules/hardware/lenovo-throttled.nix | `extraConfig` | `''` |
| modules/hardware/lenovo-throttled.nix | `systemd.services.throttled-monitor` | `{` |
| modules/hardware/lenovo-throttled.nix | `description` | `"Monitor Lenovo throttled power limits"` |
| modules/hardware/lenovo-throttled.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/lenovo-throttled.nix | `after` | `[ "throttled.service" ]` |
| modules/hardware/lenovo-throttled.nix | `serviceConfig` | `{` |
| modules/hardware/lenovo-throttled.nix | `Type` | `"simple"` |
| modules/hardware/lenovo-throttled.nix | `Restart` | `"always"` |
| modules/hardware/lenovo-throttled.nix | `RestartSec` | `"30s"` |
| modules/hardware/lenovo-throttled.nix | `script` | `''` |
| modules/hardware/lenovo-throttled.nix | `LOG_DIR` | `"/var/log/throttled"` |
| modules/hardware/lenovo-throttled.nix | `temp` | `$(cat /sys/class/thermal/thermal_zone0/temp)` |
| modules/hardware/lenovo-throttled.nix | `temp_c` | `$((temp / 1000))` |
| modules/hardware/lenovo-throttled.nix | `systemd.services.throttled-profile-switcher` | `{` |
| modules/hardware/lenovo-throttled.nix | `description` | `"Switch throttled power profile dynamically"` |
| modules/hardware/lenovo-throttled.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/lenovo-throttled.nix | `after` | `[ "throttled.service" ]` |
| modules/hardware/lenovo-throttled.nix | `serviceConfig` | `{` |
| modules/hardware/lenovo-throttled.nix | `Type` | `"oneshot"` |
| modules/hardware/lenovo-throttled.nix | `RemainAfterExit` | `true` |
| modules/hardware/lenovo-throttled.nix | `script` | `''` |
| modules/hardware/lenovo-throttled.nix | `systemd.tmpfiles.rules` | `[` |
| modules/hardware/lenovo-throttled.nix | `boot.kernelModules` | `[` |
| modules/packages/_sources/generated.nix | `gemini-cli` | `{` |
| modules/packages/_sources/generated.nix | `pname` | `"gemini-cli"` |
| modules/packages/_sources/generated.nix | `version` | `"54de67536da3af801bba8ab4657769d54dd30c2a"` |
| modules/packages/_sources/generated.nix | `src` | `fetchgit {` |
| modules/packages/_sources/generated.nix | `url` | `"https://github.com/google-gemini/gemini-cli"` |
| modules/packages/_sources/generated.nix | `rev` | `"54de67536da3af801bba8ab4657769d54dd30c2a"` |
| modules/packages/_sources/generated.nix | `fetchSubmodules` | `false` |
| modules/packages/_sources/generated.nix | `deepClone` | `false` |
| modules/packages/_sources/generated.nix | `leaveDotGit` | `false` |
| modules/packages/_sources/generated.nix | `sparseCheckout` | `[ ]` |
| modules/packages/_sources/generated.nix | `sha256` | `"sha256-53IAAiJSEK/GkUbmB1kIGiaU5bZTojG5sUBdGoEUUAc="` |
| modules/packages/_sources/generated.nix | `date` | `"2025-12-11"` |
| modules/packages/_sources/generated.nix | `lynis` | `{` |
| modules/packages/_sources/generated.nix | `pname` | `"lynis"` |
| modules/packages/_sources/generated.nix | `version` | `"3.1.6"` |
| modules/packages/_sources/generated.nix | `src` | `fetchurl {` |
| modules/packages/_sources/generated.nix | `url` | `"https://github.com/CISOfy/lynis/archive/3.1.6.tar.gz"` |
| modules/packages/_sources/generated.nix | `sha256` | `"sha256-KjHj4CjWufDo9QJAKtZ1KwafkIKJNRTIwCOWL1eGs7Y="` |
| modules/packages/_sources/generated.nix | `zellij` | `{` |
| modules/packages/_sources/generated.nix | `pname` | `"zellij"` |
| modules/packages/_sources/generated.nix | `version` | `"v0.43.1"` |
| modules/packages/_sources/generated.nix | `src` | `fetchurl {` |
| modules/packages/_sources/generated.nix | `url` | `"https://github.com/zellij-org/zellij/releases/download/v0.43.1/zellij-x86_64-unknown-linux-musl.tar.gz"` |
| modules/packages/_sources/generated.nix | `sha256` | `"sha256-VB2Y7+9VWCk++FrZrNKeTZILbogVE7nnclXYIHAg11o="` |
| modules/packages/lib/sandbox.nix | `hardwareDevices` | `{` |
| modules/packages/lib/sandbox.nix | `gpu` | `[` |
| modules/packages/lib/sandbox.nix | `audio` | `[` |
| modules/packages/lib/sandbox.nix | `usb` | `[ "/dev/bus/usb" ]` |
| modules/packages/lib/sandbox.nix | `camera` | `[` |
| modules/packages/lib/sandbox.nix | `bluetooth` | `[` |
| modules/packages/lib/sandbox.nix | `mkPathAllowArgs` | `paths: concatStringsSep " " (map (path: "--bind ${path} ${path}") paths)` |
| modules/packages/lib/sandbox.nix | `baseSandboxProfile` | `{` |
| modules/packages/lib/sandbox.nix | `ro-bind` | `[` |
| modules/packages/lib/sandbox.nix | `tmpfs` | `[` |
| modules/packages/lib/sandbox.nix | `essential` | `[` |
| modules/packages/lib/sandbox.nix | `unshare` | `[` |
| modules/packages/lib/sandbox.nix | `network` | `"--share-net"` |
| modules/packages/lib/sandbox.nix | `security` | `[` |
| modules/packages/lib/sandbox.nix | `strictSandboxProfile` | `baseSandboxProfile // {` |
| modules/packages/lib/sandbox.nix | `network` | `"--unshare-net"; # No network access` |
| modules/packages/lib/sandbox.nix | `security` | `baseSandboxProfile.security ++ [` |
| modules/packages/lib/sandbox.nix | `devSandboxProfile` | `baseSandboxProfile // {` |
| modules/packages/lib/sandbox.nix | `ro-bind` | `baseSandboxProfile.ro-bind ++ [` |
| modules/packages/lib/sandbox.nix | `blockArgs` | `mkHardwareBlockArgs blockHardware` |
| modules/packages/lib/sandbox.nix | `allowArgs` | `mkPathAllowArgs allowedPaths` |
| modules/packages/deb-packages/sandbox.nix | `default` | `{` |
| modules/packages/deb-packages/sandbox.nix | `description` | `"Pre-defined sandbox profiles"` |
| modules/packages/deb-packages/sandbox.nix | `boot.kernel.sysctl` | `{` |
| modules/packages/deb-packages/sandbox.nix | `systemd.services` | `mkMerge (` |
| modules/packages/deb-packages/sandbox.nix | `serviceName` | `"deb-package-${name}"` |
| modules/packages/deb-packages/sandbox.nix | `resourceLimits` | `pkg.sandbox.resourceLimits` |
| modules/packages/deb-packages/sandbox.nix | `description` | `"Sandboxed .deb package: ${name}"` |
| modules/packages/deb-packages/sandbox.nix | `after` | `[ "network.target" ]` |
| modules/packages/deb-packages/sandbox.nix | `serviceConfig` | `mkMerge [` |
| modules/packages/deb-packages/sandbox.nix | `Type` | `"simple"` |
| modules/packages/deb-packages/sandbox.nix | `User` | `"nobody"` |
| modules/packages/deb-packages/sandbox.nix | `Group` | `"nogroup"` |
| modules/packages/deb-packages/sandbox.nix | `NoNewPrivileges` | `true` |
| modules/packages/deb-packages/sandbox.nix | `PrivateTmp` | `true` |
| modules/packages/deb-packages/sandbox.nix | `ProtectSystem` | `"strict"` |
| modules/packages/deb-packages/sandbox.nix | `ProtectHome` | `true` |
| modules/packages/deb-packages/sandbox.nix | `ReadOnlyPaths` | `[ "/nix/store" ]` |
| modules/packages/deb-packages/sandbox.nix | `DeviceAllow` | `[ "/dev/null rw" ]; # Only allow /dev/null` |
| modules/packages/deb-packages/sandbox.nix | `CapabilityBoundingSet` | `[ "" ]; # Drop all capabilities` |
| modules/packages/deb-packages/sandbox.nix | `AmbientCapabilities` | `[ "" ]` |
| modules/packages/deb-packages/sandbox.nix | `SecureBits` | `[` |
| modules/packages/deb-packages/sandbox.nix | `SystemCallFilter` | `[` |
| modules/packages/deb-packages/sandbox.nix | `SystemCallArchitectures` | `"native"` |
| modules/packages/deb-packages/sandbox.nix | `ProtectKernelTunables` | `true` |
| modules/packages/deb-packages/sandbox.nix | `ProtectKernelModules` | `true` |
| modules/packages/deb-packages/sandbox.nix | `ProtectKernelLogs` | `true` |
| modules/packages/deb-packages/sandbox.nix | `ProtectControlGroups` | `true` |
| modules/packages/deb-packages/sandbox.nix | `ProtectClock` | `true` |
| modules/packages/deb-packages/sandbox.nix | `RestrictNamespaces` | `true` |
| modules/packages/deb-packages/sandbox.nix | `LockPersonality` | `true` |
| modules/packages/deb-packages/sandbox.nix | `RestrictRealtime` | `true` |
| modules/packages/deb-packages/sandbox.nix | `RestrictSUIDSGID` | `true` |
| modules/packages/deb-packages/sandbox.nix | `RemoveIPC` | `true` |
| modules/packages/deb-packages/sandbox.nix | `wantedBy` | `mkIf (pkg.audit.enable) [ "multi-user.target" ]` |
| modules/packages/deb-packages/sandbox.nix | `enabledPackages` | `filterAttrs (_: pkg: pkg.enable && pkg.audit.enable) cfg.packages` |
| modules/packages/lib/fetchers.nix | `if source.path !` | `null then` |
| modules/packages/lib/fetchers.nix | `else if source.url !` | `null then` |
| modules/packages/lib/fetchers.nix | `url` | `source.url` |
| modules/packages/lib/fetchers.nix | `sha256` | `source.sha256` |
| modules/packages/lib/fetchers.nix | `name` | `"${name}.${ext}"` |
| modules/packages/lib/fetchers.nix | `buildInputs` | `[` |
| modules/packages/lib/fetchers.nix | `buildInputs` | `[` |
| modules/packages/lib/fetchers.nix | `buildInputs` | `[` |
| modules/shell/aliases/laptop-defense.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/laptop-defense.nix | `"thermal-forensics"` | `"nix run /etc/nixos/modules/hardware/laptop-defense#thermal-forensics"` |
| modules/shell/aliases/laptop-defense.nix | `TEMP` | `$(sensors 2>/dev/null | grep -oP '+\K[0-9]+' | sort -rn | head -1 || echo "0") && \` |
| modules/shell/aliases/laptop-defense.nix | `environment.interactiveShellInit` | `''` |
| modules/shell/training-logger.nix | `default` | `"/var/log/training-sessions"` |
| modules/shell/training-logger.nix | `description` | `"Directory to store training session logs"` |
| modules/shell/training-logger.nix | `default` | `"\${HOME}/.training-logs"` |
| modules/shell/training-logger.nix | `description` | `"User-specific log directory (expandable)"` |
| modules/shell/training-logger.nix | `default` | `true` |
| modules/shell/training-logger.nix | `description` | `"Automatically add timestamps to log filenames"` |
| modules/shell/training-logger.nix | `default` | `"1G"` |
| modules/shell/training-logger.nix | `description` | `"Maximum log file size before rotation"` |
| modules/shell/training-logger.nix | `text` | `''` |
| modules/shell/training-logger.nix | `TRAINING_LOG_DIR` | `"''${TRAINING_LOG_DIR//\$\{HOME\}/$HOME}"  # Expande $HOME` |
| modules/shell/training-logger.nix | `log_file` | `"$TRAINING_LOG_DIR/$log_file"` |
| modules/shell/training-logger.nix | `log_file` | `"$TRAINING_LOG_DIR/$log_file"` |
| modules/shell/training-logger.nix | `log_file` | `"$TRAINING_LOG_DIR/$log_file"` |
| modules/shell/training-logger.nix | `mode` | `"0644"` |
| modules/shell/training-logger.nix | `services.logrotate` | `{` |
| modules/shell/training-logger.nix | `enable` | `true` |
| modules/shell/training-logger.nix | `settings` | `{` |
| modules/shell/training-logger.nix | `rotate` | `5` |
| modules/shell/training-logger.nix | `compress` | `true` |
| modules/shell/training-logger.nix | `delaycompress` | `true` |
| modules/shell/training-logger.nix | `missingok` | `true` |
| modules/shell/training-logger.nix | `notifempty` | `true` |
| modules/shell/training-logger.nix | `systemd.tmpfiles.rules` | `[` |
| modules/shell/training-logger.nix | `text` | `''` |
| modules/shell/training-logger.nix | `shell.trainingLogger` | `{` |
| modules/shell/training-logger.nix | `enable` | `true` |
| modules/shell/training-logger.nix | `userLogDirectory` | `"''${HOME}/.training-logs";  # Customizável` |
| modules/shell/training-logger.nix | `maxLogSize` | `"1G";  # Rotação automática` |
| modules/shell/training-logger.nix | `mode` | `"0644"` |
| modules/ml/orchestration/api/dev-ui.html | `entry.className` | ``log-entry ${type}`` |
| modules/ml/orchestration/api/dev-ui.html | `entry.textContent` | ``[${new Date().toLocaleTimeString()}] ${message}`` |
| modules/ml/orchestration/api/dev-ui.html | `wsLog.scrollTop` | `wsLog.scrollHeight` |
| modules/ml/orchestration/api/dev-ui.html | `ws` | `new WebSocket(url)` |
| modules/ml/orchestration/api/dev-ui.html | `ws.onopen` | `() => {` |
| modules/ml/orchestration/api/dev-ui.html | `wsStatus.className` | `'status-indicator status-connected'` |
| modules/ml/orchestration/api/dev-ui.html | `wsConnectBtn.disabled` | `true` |
| modules/ml/orchestration/api/dev-ui.html | `wsDisconnectBtn.disabled` | `false` |
| modules/ml/orchestration/api/dev-ui.html | `ws.onmessage` | `(event) => {` |
| modules/ml/orchestration/api/dev-ui.html | `const data` | `JSON.parse(event.data)` |
| modules/ml/orchestration/api/dev-ui.html | `ws.onerror` | `(error) => {` |
| modules/ml/orchestration/api/dev-ui.html | `ws.onclose` | `() => {` |
| modules/ml/orchestration/api/dev-ui.html | `wsStatus.className` | `'status-indicator status-disconnected'` |
| modules/ml/orchestration/api/dev-ui.html | `wsConnectBtn.disabled` | `false` |
| modules/ml/orchestration/api/dev-ui.html | `wsDisconnectBtn.disabled` | `true` |
| modules/ml/orchestration/api/dev-ui.html | `wsLog.innerHTML` | `''` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.innerHTML` | `'<div class="log-entry info">Sending request...</div>'` |
| modules/ml/orchestration/api/dev-ui.html | `entry.className` | `'log-entry'` |
| modules/ml/orchestration/api/dev-ui.html | `entry.textContent` | `chunk` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.scrollTop` | `responseDiv.scrollHeight` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.innerHTML` | ``<div class="log-entry">${JSON.stringify(data, null, 2)}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.innerHTML` | ``<div class="log-entry error">Error: ${error.message}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.innerHTML` | `'<div class="log-entry info">Sending request...</div>'` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.innerHTML` | ``<div class="log-entry">${JSON.stringify(data, null, 2)}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `responseDiv.innerHTML` | ``<div class="log-entry error">Error: ${error.message}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | `'<div class="log-entry info">Fetching status...</div>'` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | ``<div class="log-entry">${JSON.stringify(data, null, 2)}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | ``<div class="log-entry error">Error: ${error.message}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | `'<div class="log-entry info">Fetching models...</div>'` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | ``<div class="log-entry">${JSON.stringify(data, null, 2)}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | ``<div class="log-entry error">Error: ${error.message}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | `'<div class="log-entry info">Fetching backends...</div>'` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | ``<div class="log-entry">${JSON.stringify(data, null, 2)}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `logDiv.innerHTML` | ``<div class="log-entry error">Error: ${error.message}</div>`` |
| modules/ml/orchestration/api/dev-ui.html | `wsStatus.className` | `'status-indicator status-disconnected'` |
| modules/packages/tar-packages/default.nix | `default` | `true` |
| modules/packages/tar-packages/default.nix | `type` | `sharedTypes.methodType` |
| modules/packages/tar-packages/default.nix | `default` | `"auto"` |
| modules/packages/tar-packages/default.nix | `description` | `"Integration method: fhs, native, or auto"` |
| modules/packages/tar-packages/default.nix | `type` | `sharedTypes.sourceType` |
| modules/packages/tar-packages/default.nix | `type` | `sharedTypes.wrapperType name` |
| modules/packages/tar-packages/default.nix | `default` | `{ }` |
| modules/packages/tar-packages/default.nix | `type` | `sharedTypes.sandboxType` |
| modules/packages/tar-packages/default.nix | `default` | `{ }` |
| modules/packages/tar-packages/default.nix | `type` | `sharedTypes.auditType cfg.auditByDefault` |
| modules/packages/tar-packages/default.nix | `default` | `{ }` |
| modules/packages/tar-packages/default.nix | `type` | `sharedTypes.desktopEntryType name` |
| modules/packages/tar-packages/default.nix | `default` | `null` |
| modules/packages/tar-packages/default.nix | `default` | `{ }` |
| modules/packages/tar-packages/default.nix | `description` | `"Package metadata"` |
| modules/packages/tar-packages/default.nix | `storageDir` | `./storage` |
| modules/packages/tar-packages/default.nix | `cacheDir` | `"/var/cache/tar-packages"` |
| modules/packages/tar-packages/default.nix | `builder` | `import ./builder.nix {` |
| modules/packages/tar-packages/default.nix | `packages` | `cfg.packages` |
| modules/packages/tar-packages/default.nix | `enabledPackages` | `filterAttrs (_: pkg: pkg.enable) cfg.packages` |
| modules/packages/tar-packages/default.nix | `builtPackages` | `mapAttrs (name: pkg: builder.buildPackage name pkg) enabledPackages` |
| modules/packages/tar-packages/default.nix | `default` | `true` |
| modules/packages/tar-packages/default.nix | `default` | `{ }` |
| modules/packages/tar-packages/default.nix | `description` | `"Tar.gz packages to install and manage"` |
| modules/packages/tar-packages/default.nix | `default` | `false` |
| modules/packages/tar-packages/default.nix | `description` | `"Enable sandboxing for all packages by default"` |
| modules/packages/tar-packages/default.nix | `default` | `false` |
| modules/packages/tar-packages/default.nix | `description` | `"Enable audit logging for all packages by default"` |
| modules/packages/tar-packages/default.nix | `default` | `builtPackages` |
| modules/packages/tar-packages/default.nix | `readOnly` | `true` |
| modules/packages/tar-packages/default.nix | `environment.systemPackages` | `attrValues builtPackages` |
| modules/packages/tar-packages/default.nix | `systemd.tmpfiles.rules` | `[` |
| modules/packages/tar-packages/default.nix | `security.wrappers` | `mkIf (any (pkg: pkg.sandbox.enable) (attrValues cfg.packages)) {` |
| modules/packages/tar-packages/default.nix | `bubblewrap` | `{` |
| modules/packages/tar-packages/default.nix | `capabilities` | `"cap_sys_admin,cap_net_admin=ep"` |
| modules/packages/tar-packages/default.nix | `owner` | `"root"` |
| modules/packages/tar-packages/default.nix | `group` | `"root"` |
| modules/packages/tar-packages/default.nix | `permissions` | `"u+rx,g+rx,o+rx"` |
| modules/packages/tar-packages/default.nix | `security.auditd.enable` | `mkIf (any (pkg: pkg.audit.enable) (attrValues cfg.packages)) true` |
| modules/packages/tar-packages/default.nix | `environment.etc` | `mkMerge (` |
| modules/packages/tar-packages/default.nix | `mkIf (pkg.desktopEntry !` | `null) {` |
| modules/packages/tar-packages/default.nix | `"xdg/applications/${name}.desktop".text` | `''` |
| modules/packages/tar-packages/default.nix | `Type` | `Application` |
| modules/packages/tar-packages/default.nix | `Name` | `${pkg.desktopEntry.name}` |
| modules/packages/tar-packages/default.nix | `Comment` | `${pkg.desktopEntry.comment}` |
| modules/packages/tar-packages/default.nix | `Exec` | `${name}` |
| modules/packages/tar-packages/default.nix | `Terminal` | `${` |
| modules/packages/tar-packages/default.nix | `if (pkg.desktopEntry.categories or [ ])` | `= [ "TerminalEmulator" ] then "true" else "false"` |
| modules/packages/tar-packages/default.nix | `Categories` | `${concatStringsSep ";" pkg.desktopEntry.categories}` |
| modules/hardware/intel.nix | `default` | `"balanced"` |
| modules/hardware/intel.nix | `description` | `''` |
| modules/hardware/intel.nix | `pstate` | `{` |
| modules/hardware/intel.nix | `default` | `true` |
| modules/hardware/intel.nix | `default` | `true` |
| modules/hardware/intel.nix | `default` | `20` |
| modules/hardware/intel.nix | `default` | `100` |
| modules/hardware/intel.nix | `default` | `"balance_performance"` |
| modules/hardware/intel.nix | `description` | `"EPP hint for HWP."` |
| modules/hardware/intel.nix | `governor` | `{` |
| modules/hardware/intel.nix | `default` | `"powersave"; # Intel P-state ativa prefere 'powersave' como base, o HWP gerencia o clock real.` |
| modules/hardware/intel.nix | `description` | `"Default CPU frequency governor. With intel_pstate, 'powersave' implies HWP management."` |
| modules/hardware/intel.nix | `turboBoost` | `{` |
| modules/hardware/intel.nix | `graphics` | `{` |
| modules/hardware/intel.nix | `default` | `false` |
| modules/hardware/intel.nix | `default` | `true; # FBC geralmente é seguro, mas se houver glitches visuais, desative.` |
| modules/hardware/intel.nix | `default` | `true` |
| modules/hardware/intel.nix | `boot.kernelParams` | `[` |
| modules/hardware/intel.nix | `"intel_pstate` | `active"` |
| modules/hardware/intel.nix | `++ optionals cfg.pstate.hwpDynamic [ "intel_pstate` | `hwp_dynamic_boost" ]` |
| modules/hardware/intel.nix | `"i915.enable_fbc` | `${if cfg.graphics.frameBufferCompression then "1" else "0"}"` |
| modules/hardware/intel.nix | `"i915.enable_psr` | `${if cfg.graphics.panelSelfRefresh then "2" else "0"}"` |
| modules/hardware/intel.nix | `"i915.enable_guc` | `3"` |
| modules/hardware/intel.nix | `"intel_idle.max_cstate` | `2" # Cuidado: Isso limita a economia de energia drasticamente. Útil se houver freezes totais do sistema.` |
| modules/hardware/intel.nix | `"processor.max_cstate` | `2"` |
| modules/hardware/intel.nix | `boot.kernelModules` | `[ "kvm-intel" "intel_powerclamp" "coretemp" ]` |
| modules/hardware/intel.nix | `hardware.graphics` | `{ # (NixOS 24.05+) - Antigo hardware.opengl` |
| modules/hardware/intel.nix | `enable` | `true` |
| modules/hardware/intel.nix | `powerManagement` | `{` |
| modules/hardware/intel.nix | `enable` | `true` |
| modules/hardware/intel.nix | `cpuFreqGovernor` | `cfg.governor.default` |
| modules/hardware/intel.nix | `description` | `"Configure Intel P-State parameters"` |
| modules/hardware/intel.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/intel.nix | `after` | `[ "systemd-modules-load.service" ]` |
| modules/hardware/intel.nix | `serviceConfig` | `{ Type = "oneshot"; RemainAfterExit = true; }` |
| modules/hardware/intel.nix | `script` | `''` |
| modules/hardware/intel.nix | `PSTATE_DIR` | `"/sys/devices/system/cpu/intel_pstate"` |
| modules/hardware/intel.nix | `systemd.services.intel-thermal-monitor` | `mkIf cfg.turboBoost.enable {` |
| modules/hardware/intel.nix | `description` | `"Intel thermal monitoring logic"` |
| modules/hardware/intel.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/hardware/intel.nix | `serviceConfig` | `{ Type = "simple"; Restart = "always"; RestartSec = "10s"; }` |
| modules/hardware/intel.nix | `script` | `''` |
| modules/hardware/intel.nix | `current_temp` | `$(cat /sys/class/hwmon/hwmon*/temp*_input /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)` |
| modules/hardware/intel.nix | `temp` | `''${current_temp:-0}` |
| modules/hardware/intel.nix | `temp_c` | `$((temp / 1000))` |
| modules/hardware/intel.nix | `boot.kernel.sysctl` | `mkIf cfg.memory.enableTuning {` |
| modules/debug/test-init.nix | `TIMESTAMP` | `$(date +%Y%m%d_%H%M%S)` |
| modules/containers/docker.nix | `virtualisation.docker` | `{` |
| modules/containers/docker.nix | `enable` | `true` |
| modules/containers/docker.nix | `enableOnBoot` | `true` |
| modules/containers/docker.nix | `autoPrune` | `{` |
| modules/containers/docker.nix | `enable` | `true` |
| modules/containers/docker.nix | `dates` | `"weekly"` |
| modules/containers/docker.nix | `flags` | `[ "--all" ]` |
| modules/containers/docker.nix | `daemon.settings` | `{` |
| modules/containers/docker.nix | `data-root` | `"/var/lib/docker"` |
| modules/containers/docker.nix | `log-driver` | `"json-file"` |
| modules/containers/docker.nix | `log-opts` | `{` |
| modules/containers/docker.nix | `max-size` | `"10m"` |
| modules/containers/docker.nix | `max-file` | `"3"` |
| modules/containers/docker.nix | `max-concurrent-downloads` | `10` |
| modules/containers/docker.nix | `max-concurrent-uploads` | `5` |
| modules/containers/docker.nix | `storage-driver` | `"overlay2"` |
| modules/containers/docker.nix | `dns` | `[` |
| modules/packages/deb-packages/packages/cursor.nix | `cursor` | `{` |
| modules/packages/deb-packages/packages/cursor.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/cursor.nix | `method` | `"fhs"` |
| modules/packages/deb-packages/packages/cursor.nix | `source` | `{` |
| modules/packages/deb-packages/packages/cursor.nix | `path` | `../storage/cursor_2.0.34_amd64.deb` |
| modules/packages/deb-packages/packages/cursor.nix | `sha256` | `"eb0e7ba183084da0e81b13a18d4be90823c82c5d3e69f16e07262207aaea61a6"` |
| modules/packages/deb-packages/packages/cursor.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/cursor.nix | `executable` | `"usr/bin/cursor"` |
| modules/packages/deb-packages/packages/cursor.nix | `environmentVariables` | `{` |
| modules/packages/deb-packages/packages/cursor.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/cursor.nix | `enable` | `false` |
| modules/packages/deb-packages/packages/cursor.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/cursor.nix | `enable` | `false` |
| modules/packages/deb-packages/packages/cursor.nix | `logLevel` | `"minimal"` |
| modules/shell/aliases/docker/build.nix | `or "--device` | `nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g"` |
| modules/shell/aliases/docker/build.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/docker/build.nix | `"d-build"` | `"docker build -t"` |
| modules/packages/deb-packages/packages/protonpass.nix | `kernelcore.packages.deb.packages.protonpass` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/protonpass.nix | `method` | `"fhs"` |
| modules/packages/deb-packages/packages/protonpass.nix | `source` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `path` | `../storage/ProtonPass.deb` |
| modules/packages/deb-packages/packages/protonpass.nix | `sha256` | `"10b03e615f9a6e341685bd447067b839fd3a770e9bb1110ca04d0418d6beaca8"` |
| modules/packages/deb-packages/packages/protonpass.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `executable` | `"usr/bin/proton-pass"` |
| modules/packages/deb-packages/packages/protonpass.nix | `name` | `"proton-pass"` |
| modules/packages/deb-packages/packages/protonpass.nix | `extraArgs` | `[ ]` |
| modules/packages/deb-packages/packages/protonpass.nix | `environmentVariables` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/protonpass.nix | `allowedPaths` | `[` |
| modules/packages/deb-packages/packages/protonpass.nix | `blockHardware` | `[ ]; # Allow all hardware for proper functionality` |
| modules/packages/deb-packages/packages/protonpass.nix | `resourceLimits` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `memory` | `"2G"` |
| modules/packages/deb-packages/packages/protonpass.nix | `cpu` | `null` |
| modules/packages/deb-packages/packages/protonpass.nix | `tasks` | `null` |
| modules/packages/deb-packages/packages/protonpass.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/protonpass.nix | `logLevel` | `"standard"` |
| modules/packages/deb-packages/packages/protonpass.nix | `meta` | `{` |
| modules/packages/deb-packages/packages/protonpass.nix | `description` | `"Proton Pass - End-to-end encrypted password manager"` |
| modules/packages/deb-packages/packages/protonpass.nix | `homepage` | `"https://proton.me/pass"` |
| modules/packages/deb-packages/packages/protonpass.nix | `license` | `"Proprietary"` |
| modules/applications/chromium.nix | `update` | `if e.updateUrl != null then e.updateUrl else "https://clients2.google.com/service/update2/crx"` |
| modules/applications/chromium.nix | `extBlocklist` | `cfg.extensions.blocklist` |
| modules/applications/chromium.nix | `extAllowlist` | `cfg.extensions.allowlist` |
| modules/applications/chromium.nix | `rulePolicies` | `lib.filterAttrs (n: v: v != null) {` |
| modules/applications/chromium.nix | `HomepageLocation` | `if (cfg.rules.homepage != null) then cfg.rules.homepage else null` |
| modules/applications/chromium.nix | `HomepageIsNewTabPage` | `if (cfg.rules.homepageIsNewTabPage != null) then cfg.rules.homepageIsNewTabPage else null` |
| modules/applications/chromium.nix | `RestoreOnStartup` | `if (cfg.rules.restoreOnStartup != null) then cfg.rules.restoreOnStartup else null; # 1 = HOMEPAGE, 4 = URLS` |
| modules/applications/chromium.nix | `RestoreOnStartupURLs` | `if (cfg.rules.startupUrls != [ ]) then cfg.rules.startupUrls else null` |
| modules/applications/chromium.nix | `DefaultSearchProviderEnabled` | `if (cfg.rules.defaultSearch != null) then true else null` |
| modules/applications/chromium.nix | `DefaultSearchProviderName` | `if (cfg.rules.defaultSearch != null) then cfg.rules.defaultSearch.name else null` |
| modules/applications/chromium.nix | `DefaultSearchProviderSearchURL` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.defaultSearch !` | `null` |
| modules/applications/chromium.nix | `DefaultSearchProviderSuggestURL` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.defaultSearch !` | `null && cfg.rules.defaultSearch.suggestUrl != null` |
| modules/applications/chromium.nix | `DefaultSearchProviderIconURL` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.defaultSearch !` | `null && cfg.rules.defaultSearch.iconUrl != null` |
| modules/applications/chromium.nix | `SafeBrowsingProtectionLevel` | `if (cfg.rules.safeBrowsing != null) then cfg.rules.safeBrowsing else null; # 0=off,1=standard,2=enhanced` |
| modules/applications/chromium.nix | `PasswordManagerEnabled` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.passwordManagerEnabled !` | `null` |
| modules/applications/chromium.nix | `IncognitoModeAvailability` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.incognitoModeAvailability !` | `null` |
| modules/applications/chromium.nix | `) then cfg.rules.incognitoModeAvailability else null; # 0` | `enabled,1=disabled,2=forced` |
| modules/applications/chromium.nix | `SyncDisabled` | `if (cfg.rules.syncDisabled != null) then cfg.rules.syncDisabled else null` |
| modules/applications/chromium.nix | `UrlBlocklist` | `if (cfg.rules.urlBlocklist != [ ]) then cfg.rules.urlBlocklist else null` |
| modules/applications/chromium.nix | `UrlAllowlist` | `if (cfg.rules.urlAllowlist != [ ]) then cfg.rules.urlAllowlist else null` |
| modules/applications/chromium.nix | `PopupsAllowedForUrls` | `if (cfg.rules.popupsAllowedForUrls != [ ]) then cfg.rules.popupsAllowedForUrls else null` |
| modules/applications/chromium.nix | `AutoSelectCertificateForUrls` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.autoSelectCertForUrls !` | `[ ]` |
| modules/applications/chromium.nix | `DownloadDirectory` | `if (cfg.rules.downloadDirectory != null) then cfg.rules.downloadDirectory else null` |
| modules/applications/chromium.nix | `PromptForDownload` | `if (cfg.rules.promptForDownload != null) then cfg.rules.promptForDownload else null` |
| modules/applications/chromium.nix | `ExtensionInstallForcelist` | `if (extForceList != [ ]) then extForceList else null` |
| modules/applications/chromium.nix | `ExtensionInstallBlocklist` | `if (extBlocklist != [ ]) then extBlocklist else null` |
| modules/applications/chromium.nix | `ExtensionInstallAllowlist` | `if (extAllowlist != [ ]) then extAllowlist else null` |
| modules/applications/chromium.nix | `ShowHomeButton` | `if (cfg.rules.showHomeButton != null) then cfg.rules.showHomeButton else null` |
| modules/applications/chromium.nix | `DefaultBrowserSettingEnabled` | `if (` |
| modules/applications/chromium.nix | `cfg.rules.defaultBrowserSettingEnabled !` | `null` |
| modules/applications/chromium.nix | `ProxyMode` | `if (cfg.rules.proxyMode != null) then cfg.rules.proxyMode else null; # "direct"|"auto_detect"|"pac_script"|"fixed_servers"|"system [... omitted end of long line]` |
| modules/applications/chromium.nix | `ProxyServer` | `if (cfg.rules.proxyServer != null) then cfg.rules.proxyServer else null` |
| modules/applications/chromium.nix | `ProxyPacUrl` | `if (cfg.rules.proxyPacUrl != null) then cfg.rules.proxyPacUrl else null` |
| modules/applications/chromium.nix | `PrintingEnabled` | `if (cfg.rules.printingEnabled != null) then cfg.rules.printingEnabled else null` |
| modules/applications/chromium.nix | `v` | `cfg.env.${n}` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `example` | `[` |
| modules/applications/chromium.nix | `description` | `"Extra command line flags appended to Chromium invocations."` |
| modules/applications/chromium.nix | `default` | `{ }` |
| modules/applications/chromium.nix | `example` | `{` |
| modules/applications/chromium.nix | `HTTP_PROXY` | `"http://proxy.local:3128"` |
| modules/applications/chromium.nix | `description` | `"Environment variables set for Chromium via wrapper."` |
| modules/applications/chromium.nix | `rules` | `{` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `description` | `"1=Homepage, 4=Open specific URLs"` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `default` | `{ }` |
| modules/applications/chromium.nix | `extensions` | `{` |
| modules/applications/chromium.nix | `description` | `"Chrome Web Store extension ID"` |
| modules/applications/chromium.nix | `default` | `null` |
| modules/applications/chromium.nix | `description` | `"Update URL; default is Chrome Web Store"` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `description` | `"Extensions to force-install via policy."` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `[ ]` |
| modules/applications/chromium.nix | `default` | `"/etc/chromium/policies/managed"` |
| modules/applications/chromium.nix | `description` | `"Directory for managed policies JSON files."` |
| modules/applications/chromium.nix | `default` | `"policies.json"` |
| modules/applications/chromium.nix | `default` | `true` |
| modules/applications/chromium.nix | `assertions` | `[` |
| modules/applications/chromium.nix | `assertion` | `cfg.package != null` |
| modules/applications/chromium.nix | `message` | `"services.chromiumOrg.package must be set."` |
| modules/applications/chromium.nix | `environment.systemPackages` | `[` |
| modules/applications/chromium.nix | `systemd.tmpfiles.rules` | `[ "d ${cfg.policiesPath} 0755 root root -" ]` |
| modules/shell/gpu-flags.nix | `default` | `"--device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g"` |
| modules/shell/gpu-flags.nix | `description` | `"Flags Docker testadas para acesso GPU NVIDIA"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `default` | `[` |
| modules/shell/gpu-flags.nix | `"--device` | `nvidia.com/gpu=all" # Acesso a todas GPUs NVIDIA` |
| modules/shell/gpu-flags.nix | `"--ipc` | `host" # IPC shared memory` |
| modules/shell/gpu-flags.nix | `"stack` | `67108864" # Stack size limit (64MB)` |
| modules/shell/gpu-flags.nix | `"--shm-size` | `8g" # Shared memory 8GB` |
| modules/shell/gpu-flags.nix | `description` | `"Flags Docker como lista para manipulação programática"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `flags` | `{` |
| modules/shell/gpu-flags.nix | `default` | `"--device=nvidia.com/gpu=all"` |
| modules/shell/gpu-flags.nix | `description` | `"Device flag para acesso GPU"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `default` | `"--ipc=host"` |
| modules/shell/gpu-flags.nix | `description` | `"IPC mode flag"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `default` | `"--ulimit stack=67108864"` |
| modules/shell/gpu-flags.nix | `description` | `"Stack size ulimit"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `default` | `"--shm-size=8g"` |
| modules/shell/gpu-flags.nix | `description` | `"Shared memory size"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `baseCommands` | `{` |
| modules/shell/gpu-flags.nix | `default` | `"docker run --rm"` |
| modules/shell/gpu-flags.nix | `description` | `"Comando base docker run"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `default` | `"docker run --rm -it"` |
| modules/shell/gpu-flags.nix | `description` | `"Comando base docker run interativo"` |
| modules/shell/gpu-flags.nix | `readOnly` | `true` |
| modules/shell/gpu-flags.nix | `default` | `{ }` |
| modules/shell/gpu-flags.nix | `description` | `"Container images testadas com GPU"` |
| modules/shell/gpu-flags.nix | `default` | `{ }` |
| modules/shell/gpu-flags.nix | `description` | `"Aliases originais de scripts.nix para referência"` |
| modules/shell/gpu-flags.nix | `default` | `{ }` |
| modules/shell/gpu-flags.nix | `description` | `"Documentação sobre GPU flags e troubleshooting"` |
| modules/shell/gpu-flags.nix | `pytorch` | `"nvcr.io/nvidia/pytorch:25.09-py3"` |
| modules/shell/gpu-flags.nix | `tgi` | `"ghcr.io/huggingface/text-generation-inference:latest"` |
| modules/shell/gpu-flags.nix | `tensorflow` | `"nvcr.io/nvidia/tensorflow:25.09-tf2-py3"` |
| modules/shell/gpu-flags.nix | `tgi` | `"docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g ghcr.io/huggingface/text-generation-inference: [... omitted end of long line]` |
| modules/shell/gpu-flags.nix | `pytorch` | `"docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g nvcr.io/nvidia/pytorch:25.09-py3"` |
| modules/shell/gpu-flags.nix | `jupMl` | `''` |
| modules/shell/gpu-flags.nix | `--device` | `nvidia.com/gpu=all \` |
| modules/shell/gpu-flags.nix | `--ipc` | `host \` |
| modules/shell/gpu-flags.nix | `--ulimit stack` | `67108864 \` |
| modules/shell/gpu-flags.nix | `--shm-size` | `8g` |
| modules/shell/gpu-flags.nix | `flagsExplanation` | `''` |
| modules/shell/gpu-flags.nix | `--device` | `nvidia.com/gpu=all` |
| modules/shell/gpu-flags.nix | `--ipc` | `host` |
| modules/shell/gpu-flags.nix | `--ulimit stack` | `67108864` |
| modules/shell/gpu-flags.nix | `--shm-size` | `8g` |
| modules/shell/gpu-flags.nix | `commonIssues` | `''` |
| modules/shell/gpu-flags.nix | `→ Adicionar --ipc` | `host` |
| modules/shell/gpu-flags.nix | `→ Ou usar num_workers` | `0` |
| modules/shell/gpu-flags.nix | `→ Flags --ulimit stack` | `67108864 obrigatória` |
| modules/shell/gpu-flags.nix | `testingProcedure` | `''` |
| modules/shell/gpu-flags.nix | `docker run --rm --device` | `nvidia.com/gpu=all \\` |
| modules/ml/orchestration/api/src/websocket.rs | `subscription_opts` | `new_opts` |
| modules/ml/orchestration/api/src/websocket.rs | `vram_task` | `tokio::spawn(async move {` |
| modules/ml/orchestration/api/src/websocket.rs | `_` | `> {}` |
| modules/debug/debug-init.nix | `echo "` | `== Recent systemd failures ==="` |
| modules/debug/debug-init.nix | `journalctl --failed --since` | `"24 hours ago" --no-pager || true` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Configuration warnings ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Disk usage ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Nix store verification ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Recent system generations ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Checking for broken symlinks ==="` |
| modules/debug/debug-init.nix | `echo "` | `== Memory usage ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Failed services ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Boot time analysis ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Network status ==="` |
| modules/debug/debug-init.nix | `echo -e "\n` | `== Common issue checks ==="` |
| modules/debug/debug-init.nix | `TMPFULL` | `$(df /tmp | awk 'NR==2 {print $5}' | sed 's/%//')` |
| modules/debug/debug-init.nix | `BOOTFULL` | `$(df /boot | awk 'NR==2 {print $5}' | sed 's/%//')` |
| modules/debug/debug-init.nix | `DEBUG_DIR` | `"/tmp/nixos-debug-$(date +%Y%m%d_%H%M%S)"` |
| modules/debug/debug-init.nix | `journalctl --since` | `"24 hours ago" --no-pager > "$DEBUG_DIR/journalctl.log" 2>/dev/null || true` |
| modules/debug/debug-init.nix | `systemctl list-units --type` | `service > "$DEBUG_DIR/all-services.txt" 2>/dev/null || true` |
| modules/shell/aliases/system/utils.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/system/utils.nix | `"grep"` | `"grep --color=auto"` |
| modules/applications/vscode-secure.nix | `default` | `true` |
| modules/applications/vscode-secure.nix | `description` | `"Enable additional security hardening via Firejail"` |
| modules/applications/vscode-secure.nix | `default` | `true` |
| modules/applications/vscode-secure.nix | `description` | `"Allow network access (required for extensions and remote development)"` |
| modules/applications/vscode-secure.nix | `default` | `10` |
| modules/applications/vscode-secure.nix | `description` | `"Nice level for VSCode process (0-19, higher = lower priority)"` |
| modules/applications/vscode-secure.nix | `default` | `"best-effort"` |
| modules/applications/vscode-secure.nix | `description` | `"IO scheduling class for VSCode"` |
| modules/applications/vscode-secure.nix | `default` | `4` |
| modules/applications/vscode-secure.nix | `description` | `"IO scheduling priority (0-7, lower = higher priority)"` |
| modules/applications/vscode-secure.nix | `default` | `"8G"` |
| modules/applications/vscode-secure.nix | `description` | `"Memory limit for VSCode process"` |
| modules/applications/vscode-secure.nix | `default` | `"80%"` |
| modules/applications/vscode-secure.nix | `description` | `"CPU quota for VSCode (percentage or absolute value)"` |
| modules/applications/vscode-secure.nix | `default` | `[` |
| modules/applications/vscode-secure.nix | `description` | `"List of paths that VSCode can access"` |
| modules/applications/vscode-secure.nix | `default` | `false` |
| modules/applications/vscode-secure.nix | `description` | `"Enable Microsoft telemetry (disabled by default for privacy)"` |
| modules/applications/vscode-secure.nix | `default` | `[ ]` |
| modules/applications/vscode-secure.nix | `description` | `"List of VSCode extensions to install"` |
| modules/applications/vscode-secure.nix | `example` | `literalExpression ''` |
| modules/applications/vscode-secure.nix | `commandLineArgs` | `[` |
| modules/applications/vscode-secure.nix | `mode` | `"0755"` |
| modules/applications/vscode-secure.nix | `text` | `''` |
| modules/applications/vscode-secure.nix | `SCOPE_NAME` | `"vscode-$$"` |
| modules/applications/vscode-secure.nix | `--unit` | `"$SCOPE_NAME" \` |
| modules/applications/vscode-secure.nix | `--property` | `"MemoryMax=${cfg.memoryLimit}" \` |
| modules/applications/vscode-secure.nix | `--property` | `"CPUQuota=${cfg.cpuQuota}" \` |
| modules/applications/vscode-secure.nix | `--property` | `"Nice=${toString cfg.niceLevel}" \` |
| modules/applications/vscode-secure.nix | `--property` | `"IOSchedulingClass=${cfg.ioSchedulingClass}" \` |
| modules/applications/vscode-secure.nix | `--property` | `"IOSchedulingPriority=${toString cfg.ioSchedulingPriority}" \` |
| modules/applications/vscode-secure.nix | `--profile` | `/etc/firejail/vscode.local \` |
| modules/applications/vscode-secure.nix | `--private-etc` | `alternatives,fonts,ssl,pki,crypto-policies,resolv.conf,hostname,localtime \` |
| modules/applications/vscode-secure.nix | `Version` | `1.0` |
| modules/applications/vscode-secure.nix | `Name` | `Visual Studio Code (Secure/Sandboxed)` |
| modules/applications/vscode-secure.nix | `GenericName` | `Text Editor` |
| modules/applications/vscode-secure.nix | `Exec` | `/etc/vscode-wrapper.sh %F` |
| modules/applications/vscode-secure.nix | `Icon` | `vscode` |
| modules/applications/vscode-secure.nix | `Terminal` | `false` |
| modules/applications/vscode-secure.nix | `Type` | `Application` |
| modules/applications/vscode-secure.nix | `MimeType` | `text/plain;inode/directory` |
| modules/applications/vscode-secure.nix | `Categories` | `Development;IDE;TextEditor` |
| modules/applications/vscode-secure.nix | `Keywords` | `vscode;editor;ide;development` |
| modules/applications/vscode-secure.nix | `StartupNotify` | `true` |
| modules/applications/vscode-secure.nix | `StartupWMClass` | `Code` |
| modules/applications/vscode-secure.nix | `Actions` | `new-empty-window` |
| modules/applications/vscode-secure.nix | `Name` | `New Empty Window` |
| modules/applications/vscode-secure.nix | `Exec` | `/etc/vscode-wrapper.sh --new-window %F` |
| modules/applications/vscode-secure.nix | `Icon` | `vscode` |
| modules/applications/vscode-secure.nix | `environment.sessionVariables` | `mkMerge [` |
| modules/applications/vscode-secure.nix | `DISABLE_UPDATE_CHECK` | `"1"` |
| modules/applications/vscode-secure.nix | `VSCODE_TELEMETRY_OPTOUT` | `"1"` |
| modules/applications/vscode-secure.nix | `home-manager.users` | `mkIf (cfg.extensions != [ ]) {` |
| modules/applications/vscode-secure.nix | `kernelcore` | `{` |
| modules/applications/vscode-secure.nix | `programs.vscode` | `{` |
| modules/applications/vscode-secure.nix | `extensions` | `cfg.extensions` |
| modules/applications/vscode-secure.nix | `warnings` | `mkIf cfg.enableMicrosoftTelemetry [` |
| modules/containers/podman.nix | `default` | `false` |
| modules/containers/podman.nix | `description` | `"Enable Docker compatibility (creates docker alias to podman)"` |
| modules/containers/podman.nix | `default` | `true` |
| modules/containers/podman.nix | `description` | `"Enable NVIDIA GPU support via nvidia-container-toolkit"` |
| modules/containers/podman.nix | `virtualisation.podman` | `{` |
| modules/containers/podman.nix | `enable` | `true` |
| modules/containers/podman.nix | `defaultNetwork.settings.dns_enabled` | `true` |
| modules/containers/podman.nix | `autoPrune` | `{` |
| modules/containers/podman.nix | `enable` | `true` |
| modules/containers/podman.nix | `dates` | `"weekly"` |
| modules/containers/podman.nix | `flags` | `[ "--all" ]` |
| modules/containers/podman.nix | `virtualisation.containers.storage.settings` | `{` |
| modules/containers/podman.nix | `storage` | `{` |
| modules/containers/podman.nix | `driver` | `"overlay"` |
| modules/containers/podman.nix | `runroot` | `"/run/containers/storage"` |
| modules/containers/podman.nix | `graphroot` | `"/var/lib/containers/storage"` |
| modules/containers/podman.nix | `rootless_storage_path` | `"$HOME/.local/share/containers/storage"` |
| modules/containers/podman.nix | `overlay` | `{` |
| modules/containers/podman.nix | `mountopt` | `"nodev,metacopy=on"` |
| modules/containers/podman.nix | `virtualisation.containers.registries` | `{` |
| modules/containers/podman.nix | `search` | `[` |
| modules/containers/podman.nix | `insecure` | `[ ]; # Add insecure registries here if needed` |
| modules/containers/podman.nix | `block` | `[ ]; # Block specific registries if needed` |
| modules/packages/deb-packages/packages/protonvpn.nix | `protonvpn` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/protonvpn.nix | `method` | `"fhs"` |
| modules/packages/deb-packages/packages/protonvpn.nix | `source` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `path` | `../storage/protonvpn-stable-release_1.0.8_all.deb` |
| modules/packages/deb-packages/packages/protonvpn.nix | `sha256` | `"0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180"` |
| modules/packages/deb-packages/packages/protonvpn.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `executable` | `"usr/bin/protonvpn"` |
| modules/packages/deb-packages/packages/protonvpn.nix | `environmentVariables` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `enable` | `false` |
| modules/packages/deb-packages/packages/protonvpn.nix | `allowedPaths` | `[ ]` |
| modules/packages/deb-packages/packages/protonvpn.nix | `blockHardware` | `[ ]` |
| modules/packages/deb-packages/packages/protonvpn.nix | `resourceLimits` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `memory` | `null` |
| modules/packages/deb-packages/packages/protonvpn.nix | `cpu` | `null` |
| modules/packages/deb-packages/packages/protonvpn.nix | `tasks` | `null` |
| modules/packages/deb-packages/packages/protonvpn.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/protonvpn.nix | `logLevel` | `"standard"` |
| modules/packages/deb-packages/packages/protonvpn.nix | `meta` | `{` |
| modules/packages/deb-packages/packages/protonvpn.nix | `description` | `"ProtonVPN - Secure VPN Client"` |
| modules/packages/deb-packages/packages/protonvpn.nix | `homepage` | `"https://protonvpn.com"` |
| modules/packages/deb-packages/packages/protonvpn.nix | `license` | `"Proprietary"` |
| modules/shell/aliases/macos-kvm.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/macos-kvm.nix | `mvm` | `"macos-vm"; # Launch macOS VM` |
| modules/shell/aliases/macos-kvm.nix | `mfetch` | `"macos-fetch"; # Download macOS installer` |
| modules/shell/aliases/macos-kvm.nix | `mref` | `"macos-reference"; # Launch reference VM (ngi-nix)` |
| modules/shell/aliases/macos-kvm.nix | `mssh` | `"macos-ssh"; # SSH into macOS VM` |
| modules/shell/aliases/macos-kvm.nix | `mscp` | `"macos-scp"; # SCP to/from macOS VM` |
| modules/shell/aliases/macos-kvm.nix | `mwait` | `"macos-wait"; # Wait for VM boot` |
| modules/shell/aliases/macos-kvm.nix | `mwait5` | `"macos-wait 300"; # Wait 5 minutes` |
| modules/shell/aliases/macos-kvm.nix | `mwait10` | `"macos-wait 600"; # Wait 10 minutes` |
| modules/shell/aliases/macos-kvm.nix | `msnap` | `"macos-snapshot"; # Snapshot management` |
| modules/shell/aliases/macos-kvm.nix | `msnap-list` | `"macos-snapshot list"; # List snapshots` |
| modules/shell/aliases/macos-kvm.nix | `msnap-create` | `"macos-snapshot create"; # Create snapshot` |
| modules/shell/aliases/macos-kvm.nix | `msnap-restore` | `"macos-snapshot apply"; # Restore snapshot` |
| modules/shell/aliases/macos-kvm.nix | `msnap-clean` | `"macos-snapshot create clean && macos-snapshot delete old"` |
| modules/shell/aliases/macos-kvm.nix | `mbench` | `"macos-benchmark"; # Run performance benchmark` |
| modules/shell/aliases/macos-kvm.nix | `minfo` | `"mssh 'sw_vers; sysctl -n machdep.cpu.brand_string; sysctl hw.memsize'"` |
| modules/shell/aliases/macos-kvm.nix | `mcpu` | `"mssh 'sysctl -n machdep.cpu.brand_string'"` |
| modules/shell/aliases/macos-kvm.nix | `mmem` | `"mssh 'sysctl hw.memsize | awk \"{print \\$2/1024/1024/1024 \\\" GB\\\"}\"'"` |
| modules/shell/aliases/macos-kvm.nix | `mdisk` | `"mssh 'df -h /'"` |
| modules/shell/aliases/macos-kvm.nix | `mxcode` | `"mssh 'xcode-select --version'"; # Check Xcode CLI tools` |
| modules/shell/aliases/macos-kvm.nix | `mxcode-install` | `"mssh 'xcode-select --install'"` |
| modules/shell/aliases/macos-kvm.nix | `mbrew` | `"mssh 'brew --version 2>/dev/null || echo \"Homebrew not installed\"'"` |
| modules/shell/aliases/macos-kvm.nix | `mbrew-install` | `"mssh '/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"'"` |
| modules/shell/aliases/macos-kvm.nix | `msim` | `"mssh 'xcrun simctl list devices available'"` |
| modules/shell/aliases/macos-kvm.nix | `msim-boot` | `"mssh 'xcrun simctl boot'"; # + device ID` |
| modules/shell/aliases/macos-kvm.nix | `msim-shutdown` | `"mssh 'xcrun simctl shutdown all'"` |
| modules/shell/aliases/macos-kvm.nix | `mqmp` | `"socat - UNIX-CONNECT:/tmp/macos-qmp.sock"` |
| modules/shell/aliases/macos-kvm.nix | `mmonitor` | `"socat - UNIX-CONNECT:/tmp/macos-monitor.sock"` |
| modules/shell/aliases/macos-kvm.nix | `mpause` | `"echo '{\"execute\":\"stop\"}' | socat - UNIX-CONNECT:/tmp/macos-qmp.sock"` |
| modules/shell/aliases/macos-kvm.nix | `mresume` | `"echo '{\"execute\":\"cont\"}' | socat - UNIX-CONNECT:/tmp/macos-qmp.sock"` |
| modules/shell/aliases/macos-kvm.nix | `mstatus` | `"echo '{\"execute\":\"query-status\"}' | socat - UNIX-CONNECT:/tmp/macos-qmp.sock"` |
| modules/shell/aliases/macos-kvm.nix | `mpush` | `"macos-scp"; # Push files: mpush local remote` |
| modules/shell/aliases/macos-kvm.nix | `mpull` | `"macos-scp admin@localhost:"; # Pull files: mpull remote local` |
| modules/shell/aliases/macos-kvm.nix | `mlog` | `"journalctl -f | grep -i qemu"; # QEMU logs` |
| modules/shell/aliases/macos-kvm.nix | `mps` | `"ps aux | grep qemu-system"; # QEMU processes` |
| modules/shell/aliases/macos-kvm.nix | `mkill` | `"pkill -9 qemu-system-x86_64"; # Force kill VM` |
| modules/shell/aliases/macos-kvm.nix | `mport` | `"echo 'SSH: ${toString cfg.sshPort}, VNC: ${toString cfg.vncPort}'"` |
| modules/shell/aliases/macos-kvm.nix | `mvnc` | `"echo 'Connect via: vnc://localhost:${toString cfg.vncPort}'"` |
| modules/shell/aliases/macos-kvm.nix | `mcd` | `"cd ${cfg.workDir}"; # Go to macOS KVM dir` |
| modules/shell/aliases/macos-kvm.nix | `mls` | `"ls -la ${cfg.workDir}"; # List macOS KVM files` |
| modules/shell/aliases/macos-kvm.nix | `msize` | `"du -sh ${cfg.workDir}/*"; # Disk usage` |
| modules/shell/aliases/macos-kvm.nix | `mci-boot` | `"macos-vm & macos-wait 300"; # Boot VM and wait` |
| modules/shell/aliases/macos-kvm.nix | `mci-snapshot` | `"msnap-create ci-baseline && echo 'CI baseline created'"` |
| modules/shell/aliases/macos-kvm.nix | `mci-reset` | `"macos-snapshot apply ci-baseline"` |
| modules/shell/aliases/macos-kvm.nix | `mci-test` | `"mssh 'xcodebuild test -scheme MyApp -destination \"platform=iOS Simulator,name=iPhone 15\"'"` |
| modules/shell/aliases/docker/run.nix | `or "--device` | `nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g"` |
| modules/shell/aliases/docker/run.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/docker/run.nix | `"d-run"` | `"docker run --rm -it"` |
| modules/containers/nixos-containers.nix | `boot.enableContainers` | `true` |
| modules/containers/nixos-containers.nix | `networking` | `{` |
| modules/containers/nixos-containers.nix | `nat` | `{` |
| modules/containers/nixos-containers.nix | `enable` | `true` |
| modules/containers/nixos-containers.nix | `internalInterfaces` | `[ "ve-+" ]; # ← wildcard pra todos ve-*` |
| modules/containers/nixos-containers.nix | `externalInterface` | `"wlp62s0"; # ← tua WiFi` |
| modules/containers/nixos-containers.nix | `firewall` | `{` |
| modules/containers/nixos-containers.nix | `enable` | `true` |
| modules/containers/nixos-containers.nix | `trustedInterfaces` | `[ "ve-+" ]` |
| modules/containers/nixos-containers.nix | `allowedTCPPorts` | `[` |
| modules/containers/nixos-containers.nix | `extraCommands` | `''` |
| modules/containers/nixos-containers.nix | `containers.teste-preprod` | `{` |
| modules/containers/nixos-containers.nix | `autoStart` | `true` |
| modules/containers/nixos-containers.nix | `privateNetwork` | `true` |
| modules/containers/nixos-containers.nix | `hostAddress` | `"192.168.100.10"; # ← IP do lado do host` |
| modules/containers/nixos-containers.nix | `localAddress` | `"192.168.100.11"; # ← IP do lado do container` |
| modules/containers/nixos-containers.nix | `bindMounts` | `{` |
| modules/containers/nixos-containers.nix | `"/dev/nvidia0"` | `{` |
| modules/containers/nixos-containers.nix | `hostPath` | `"/dev/nvidia0"` |
| modules/containers/nixos-containers.nix | `isReadOnly` | `false` |
| modules/containers/nixos-containers.nix | `hostPath` | `"/dev/nvidiactl"` |
| modules/containers/nixos-containers.nix | `isReadOnly` | `false` |
| modules/containers/nixos-containers.nix | `hostPath` | `"/dev/nvidia-uvm"` |
| modules/containers/nixos-containers.nix | `isReadOnly` | `false` |
| modules/containers/nixos-containers.nix | `allowedDevices` | `[` |
| modules/containers/nixos-containers.nix | `node` | `"/dev/nvidia0"` |
| modules/containers/nixos-containers.nix | `modifier` | `"rw"` |
| modules/containers/nixos-containers.nix | `node` | `"/dev/nvidiactl"` |
| modules/containers/nixos-containers.nix | `modifier` | `"rw"` |
| modules/containers/nixos-containers.nix | `node` | `"/dev/nvidia-uvm"` |
| modules/containers/nixos-containers.nix | `modifier` | `"rw"` |
| modules/containers/nixos-containers.nix | `networking` | `{` |
| modules/containers/nixos-containers.nix | `defaultGateway` | `{` |
| modules/containers/nixos-containers.nix | `address` | `"192.168.100.10"` |
| modules/containers/nixos-containers.nix | `interface` | `"eth0"` |
| modules/containers/nixos-containers.nix | `nameservers` | `[` |
| modules/containers/nixos-containers.nix | `networking.firewall` | `{` |
| modules/containers/nixos-containers.nix | `enable` | `true` |
| modules/containers/nixos-containers.nix | `allowedTCPPorts` | `[` |
| modules/containers/nixos-containers.nix | `hardware.graphics.enable` | `true` |
| modules/containers/nixos-containers.nix | `services.nginx.enable` | `true` |
| modules/containers/nixos-containers.nix | `system.stateVersion` | `"25.05"` |
| modules/packages/deb-packages/packages/example.nix | `example-tool` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `method` | `"auto"; # auto, fhs, or native` |
| modules/packages/deb-packages/packages/example.nix | `source` | `{` |
| modules/packages/deb-packages/packages/example.nix | `url` | `"https://example.com/releases/example-tool_1.0.0_amd64.deb"` |
| modules/packages/deb-packages/packages/example.nix | `sha256` | `"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="` |
| modules/packages/deb-packages/packages/example.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `allowedPaths` | `[ "/tmp" ]` |
| modules/packages/deb-packages/packages/example.nix | `blockHardware` | `[ ]` |
| modules/packages/deb-packages/packages/example.nix | `resourceLimits` | `{ }` |
| modules/packages/deb-packages/packages/example.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `logLevel` | `"standard"; # minimal, standard, or verbose` |
| modules/packages/deb-packages/packages/example.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/example.nix | `name` | `"example-tool"` |
| modules/packages/deb-packages/packages/example.nix | `extraArgs` | `[ ]` |
| modules/packages/deb-packages/packages/example.nix | `environmentVariables` | `{ }` |
| modules/packages/deb-packages/packages/example.nix | `meta` | `{` |
| modules/packages/deb-packages/packages/example.nix | `description` | `"Example tool from .deb package"` |
| modules/packages/deb-packages/packages/example.nix | `homepage` | `"https://example.com"` |
| modules/packages/deb-packages/packages/example.nix | `license` | `"MIT"` |
| modules/packages/deb-packages/packages/example.nix | `local-tool` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `false; # Disabled by default` |
| modules/packages/deb-packages/packages/example.nix | `method` | `"fhs"` |
| modules/packages/deb-packages/packages/example.nix | `source` | `{` |
| modules/packages/deb-packages/packages/example.nix | `path` | `../storage/local-tool.deb` |
| modules/packages/deb-packages/packages/example.nix | `sha256` | `"sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="` |
| modules/packages/deb-packages/packages/example.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `allowedPaths` | `[` |
| modules/packages/deb-packages/packages/example.nix | `blockHardware` | `[ "gpu" ]; # Block GPU access` |
| modules/packages/deb-packages/packages/example.nix | `resourceLimits` | `{` |
| modules/packages/deb-packages/packages/example.nix | `memory` | `"4G"` |
| modules/packages/deb-packages/packages/example.nix | `cpu` | `75` |
| modules/packages/deb-packages/packages/example.nix | `tasks` | `1024` |
| modules/packages/deb-packages/packages/example.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `logLevel` | `"verbose"; # Full logging` |
| modules/packages/deb-packages/packages/example.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/example.nix | `name` | `"local-tool"` |
| modules/packages/deb-packages/packages/example.nix | `extraArgs` | `[ "--verbose" ]` |
| modules/packages/deb-packages/packages/example.nix | `environmentVariables` | `{` |
| modules/packages/deb-packages/packages/example.nix | `meta` | `{` |
| modules/packages/deb-packages/packages/example.nix | `homepage` | `"https://internal.example.com"` |
| modules/packages/deb-packages/packages/example.nix | `license` | `"Proprietary"` |
| modules/packages/deb-packages/packages/example.nix | `untrusted-app` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `false` |
| modules/packages/deb-packages/packages/example.nix | `method` | `"fhs"` |
| modules/packages/deb-packages/packages/example.nix | `source` | `{` |
| modules/packages/deb-packages/packages/example.nix | `url` | `"https://untrusted-source.com/app.deb"` |
| modules/packages/deb-packages/packages/example.nix | `sha256` | `"sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC="` |
| modules/packages/deb-packages/packages/example.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `allowedPaths` | `[ ]; # No host filesystem access` |
| modules/packages/deb-packages/packages/example.nix | `blockHardware` | `[` |
| modules/packages/deb-packages/packages/example.nix | `resourceLimits` | `{` |
| modules/packages/deb-packages/packages/example.nix | `memory` | `"1G"; # Strict memory limit` |
| modules/packages/deb-packages/packages/example.nix | `cpu` | `25; # Limited CPU` |
| modules/packages/deb-packages/packages/example.nix | `tasks` | `256; # Limited processes` |
| modules/packages/deb-packages/packages/example.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `logLevel` | `"verbose"; # Maximum logging` |
| modules/packages/deb-packages/packages/example.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/example.nix | `name` | `"untrusted-app"` |
| modules/packages/deb-packages/packages/example.nix | `extraArgs` | `[ ]` |
| modules/packages/deb-packages/packages/example.nix | `environmentVariables` | `{` |
| modules/packages/deb-packages/packages/example.nix | `HOME` | `"/tmp/app-home"` |
| modules/packages/deb-packages/packages/example.nix | `meta` | `{` |
| modules/packages/deb-packages/packages/example.nix | `homepage` | `"https://untrusted-source.com"` |
| modules/packages/deb-packages/packages/example.nix | `license` | `"Unknown"` |
| modules/packages/deb-packages/packages/example.nix | `dev-tool` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `false` |
| modules/packages/deb-packages/packages/example.nix | `method` | `"native"` |
| modules/packages/deb-packages/packages/example.nix | `source` | `{` |
| modules/packages/deb-packages/packages/example.nix | `url` | `"https://dev-tools.example.com/tool.deb"` |
| modules/packages/deb-packages/packages/example.nix | `sha256` | `"sha256-DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD="` |
| modules/packages/deb-packages/packages/example.nix | `sandbox` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `allowedPaths` | `[` |
| modules/packages/deb-packages/packages/example.nix | `blockHardware` | `[ ]; # Allow all hardware` |
| modules/packages/deb-packages/packages/example.nix | `resourceLimits` | `{` |
| modules/packages/deb-packages/packages/example.nix | `memory` | `"8G"` |
| modules/packages/deb-packages/packages/example.nix | `cpu` | `100; # No CPU limit` |
| modules/packages/deb-packages/packages/example.nix | `audit` | `{` |
| modules/packages/deb-packages/packages/example.nix | `enable` | `true` |
| modules/packages/deb-packages/packages/example.nix | `logLevel` | `"minimal"; # Minimal logging for dev tools` |
| modules/packages/deb-packages/packages/example.nix | `wrapper` | `{` |
| modules/packages/deb-packages/packages/example.nix | `name` | `"dev-tool"` |
| modules/packages/deb-packages/packages/example.nix | `extraArgs` | `[ ]` |
| modules/packages/deb-packages/packages/example.nix | `environmentVariables` | `{` |
| modules/packages/deb-packages/packages/example.nix | `PATH` | `"/usr/local/bin:$PATH"` |
| modules/packages/deb-packages/packages/example.nix | `LANG` | `"en_US.UTF-8"` |
| modules/packages/deb-packages/packages/example.nix | `meta` | `{` |
| modules/packages/deb-packages/packages/example.nix | `homepage` | `"https://dev-tools.example.com"` |
| modules/packages/deb-packages/packages/example.nix | `license` | `"Apache-2.0"` |
| modules/shell/aliases/system/navigation.nix | `ignorePatterns` | `[` |
| modules/shell/aliases/system/navigation.nix | `treeIgnore` | `lib.concatMapStringsSep "|" (p: p) ignorePatterns` |
| modules/shell/aliases/system/navigation.nix | `ezaIgnore` | `lib.concatMapStringsSep " " (p: "--ignore-glob '${p}'") ignorePatterns` |
| modules/shell/aliases/system/navigation.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/system/navigation.nix | `"ls"` | `"eza --group-directories-first --color=always ${ezaIgnore}"` |
| modules/shell/default.nix | `default` | `false` |
| modules/shell/default.nix | `description` | `"Enable GPU monitor daemon (systemd service)"` |
| modules/shell/default.nix | `default` | `"/etc/nixos-shell/scripts"` |
| modules/shell/default.nix | `description` | `"Path to Python automation scripts"` |
| modules/shell/default.nix | `readOnly` | `true` |
| modules/shell/default.nix | `programs.zsh` | `{` |
| modules/shell/default.nix | `enableCompletion` | `true` |
| modules/shell/default.nix | `autosuggestions.enable` | `true` |
| modules/shell/default.nix | `syntaxHighlighting.enable` | `true` |
| modules/shell/default.nix | `ohMyZsh` | `{` |
| modules/shell/default.nix | `enable` | `true` |
| modules/shell/default.nix | `plugins` | `[` |
| modules/shell/default.nix | `theme` | `"robbyrussell"` |
| modules/shell/default.nix | `environment.etc` | `{` |
| modules/shell/default.nix | `"nixos-shell/scripts/gpu_monitor.py"` | `{` |
| modules/shell/default.nix | `source` | `./scripts/python/gpu_monitor.py` |
| modules/shell/default.nix | `mode` | `"0755"` |
| modules/shell/default.nix | `source` | `./scripts/python/model_manager.py` |
| modules/shell/default.nix | `mode` | `"0755"` |
| modules/shell/default.nix | `environment.shellAliases` | `{` |
| modules/shell/default.nix | `gpu-monitor` | `"python3 /etc/nixos-shell/scripts/gpu_monitor.py"` |
| modules/shell/default.nix | `gpu-monitor-json` | `"python3 /etc/nixos-shell/scripts/gpu_monitor.py json"` |
| modules/shell/default.nix | `gpu-monitor-summary` | `"python3 /etc/nixos-shell/scripts/gpu_monitor.py summary"` |
| modules/shell/default.nix | `model-search` | `"python3 /etc/nixos-shell/scripts/model_manager.py search"` |
| modules/shell/default.nix | `model-install` | `"python3 /etc/nixos-shell/scripts/model_manager.py install"` |
| modules/shell/default.nix | `model-list` | `"python3 /etc/nixos-shell/scripts/model_manager.py list"` |
| modules/shell/default.nix | `model-remove` | `"python3 /etc/nixos-shell/scripts/model_manager.py remove"` |
| modules/shell/default.nix | `model-cache-info` | `"python3 /etc/nixos-shell/scripts/model_manager.py cache-info"` |
| modules/shell/default.nix | `model-cache-clean` | `"python3 /etc/nixos-shell/scripts/model_manager.py cache-clean"` |
| modules/shell/default.nix | `users.users.kernelcore` | `{` |
| modules/shell/default.nix | `extraGroups` | `[` |
| modules/shell/default.nix | `text` | `''` |
| modules/shell/default.nix | `export NIXOS_SHELL_SCRIPTS` | `"/etc/nixos-shell/scripts"` |
| modules/shell/default.nix | `nvidia-smi --query-gpu` | `name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "  No GPU detected"` |
| modules/shell/default.nix | `mode` | `"0644"` |
| modules/shell/default.nix | `text` | `''` |
| modules/shell/default.nix | `--device` | `nvidia.com/gpu=all` |
| modules/shell/default.nix | `--ipc` | `host` |
| modules/shell/default.nix | `--ulimit stack` | `67108864` |
| modules/shell/default.nix | `--shm-size` | `8g` |
| modules/shell/default.nix | `- DataLoader crashes → Adicionar `--ipc` | `host`` |
| modules/shell/default.nix | `- Stack overflow → `--ulimit stack` | `67108864` obrigatório` |
| modules/shell/default.nix | `mode` | `"0644"` |
| modules/ml/orchestration/api/registry.py | `SCHEMA` | `"""` |
| modules/ml/orchestration/api/registry.py | `self.db_path` | `db_path` |
| modules/ml/orchestration/api/registry.py | `self.conn: Optional[sqlite3.Connection]` | `None` |
| modules/ml/orchestration/api/registry.py | `self.conn` | `sqlite3.connect(self.db_path)` |
| modules/ml/orchestration/api/registry.py | `self.conn.row_factory` | `sqlite3.Row` |
| modules/ml/orchestration/api/registry.py | `cursor` | `self.conn.cursor()` |
| modules/ml/orchestration/api/registry.py | `name` | `excluded.name,` |
| modules/ml/orchestration/api/registry.py | `format` | `excluded.format,` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `excluded.size_gb,` |
| modules/ml/orchestration/api/registry.py | `vram_estimate_gb` | `excluded.vram_estimate_gb,` |
| modules/ml/orchestration/api/registry.py | `architecture` | `excluded.architecture,` |
| modules/ml/orchestration/api/registry.py | `quantization` | `excluded.quantization,` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `excluded.parameter_count,` |
| modules/ml/orchestration/api/registry.py | `context_length` | `excluded.context_length,` |
| modules/ml/orchestration/api/registry.py | `compatible_backends` | `excluded.compatible_backends,` |
| modules/ml/orchestration/api/registry.py | `last_scanned` | `excluded.last_scanned,` |
| modules/ml/orchestration/api/registry.py | `tags` | `excluded.tags,` |
| modules/ml/orchestration/api/registry.py | `notes` | `excluded.notes` |
| modules/ml/orchestration/api/registry.py | `cursor` | `self.conn.cursor()` |
| modules/ml/orchestration/api/registry.py | `rows` | `cursor.execute("SELECT * FROM models ORDER BY name").fetchall()` |
| modules/ml/orchestration/api/registry.py | `cursor` | `self.conn.cursor()` |
| modules/ml/orchestration/api/registry.py | `row` | `cursor.execute("SELECT * FROM models WHERE id = ?", (model_id,)).fetchone()` |
| modules/ml/orchestration/api/registry.py | `cursor` | `self.conn.cursor()` |
| modules/ml/orchestration/api/registry.py | `row` | `cursor.execute("SELECT * FROM models WHERE path = ?", (path,)).fetchone()` |
| modules/ml/orchestration/api/registry.py | `cursor` | `self.conn.cursor()` |
| modules/ml/orchestration/api/registry.py | `all_models` | `self.get_all_models()` |
| modules/ml/orchestration/api/registry.py | `deleted_count` | `0` |
| modules/ml/orchestration/api/registry.py | `cursor.execute("DELETE FROM models WHERE id` | `?", (model.id,))` |
| modules/ml/orchestration/api/registry.py | `deleted_count +` | `1` |
| modules/ml/orchestration/api/registry.py | `GGUF_EXTENSIONS` | `{".gguf", ".ggml"}` |
| modules/ml/orchestration/api/registry.py | `SAFETENSORS_EXTENSIONS` | `{".safetensors"}` |
| modules/ml/orchestration/api/registry.py | `PYTORCH_EXTENSIONS` | `{".pt", ".pth", ".bin"}` |
| modules/ml/orchestration/api/registry.py | `ONNX_EXTENSIONS` | `{".onnx"}` |
| modules/ml/orchestration/api/registry.py | `GGUF_QUANT_PATTERN` | `re.compile(r"(Q\d+_[KMS](?:_[LMS])?|F16|F32)", re.IGNORECASE)` |
| modules/ml/orchestration/api/registry.py | `PARAM_PATTERN` | `re.compile(r"(\d+\.?\d*[BMK])", re.IGNORECASE)` |
| modules/ml/orchestration/api/registry.py | `ARCH_PATTERNS` | `{` |
| modules/ml/orchestration/api/registry.py | `self.models_path` | `Path(models_path)` |
| modules/ml/orchestration/api/registry.py | `models` | `[]` |
| modules/ml/orchestration/api/registry.py | `file_path` | `Path(root) / file` |
| modules/ml/orchestration/api/registry.py | `ext` | `file_path.suffix.lower()` |
| modules/ml/orchestration/api/registry.py | `metadata` | `self._scan_gguf(file_path)` |
| modules/ml/orchestration/api/registry.py | `metadata` | `self._scan_safetensors(file_path)` |
| modules/ml/orchestration/api/registry.py | `metadata` | `self._scan_pytorch(file_path)` |
| modules/ml/orchestration/api/registry.py | `metadata` | `self._scan_onnx(file_path)` |
| modules/ml/orchestration/api/registry.py | `elif file` | `= "Modelfile":  # Ollama model` |
| modules/ml/orchestration/api/registry.py | `metadata` | `self._scan_ollama(file_path)` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `file_path.stat().st_size / (1024 ** 3)` |
| modules/ml/orchestration/api/registry.py | `filename` | `file_path.stem` |
| modules/ml/orchestration/api/registry.py | `quant_match` | `self.GGUF_QUANT_PATTERN.search(filename)` |
| modules/ml/orchestration/api/registry.py | `quantization` | `quant_match.group(1).upper() if quant_match else "Unknown"` |
| modules/ml/orchestration/api/registry.py | `param_match` | `self.PARAM_PATTERN.search(filename)` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `param_match.group(1).upper() if param_match else ""` |
| modules/ml/orchestration/api/registry.py | `architecture` | `"unknown"` |
| modules/ml/orchestration/api/registry.py | `architecture` | `arch` |
| modules/ml/orchestration/api/registry.py | `vram_estimate` | `size_gb + 0.5` |
| modules/ml/orchestration/api/registry.py | `backends` | `["llamacpp", "ollama"]` |
| modules/ml/orchestration/api/registry.py | `name` | `filename,` |
| modules/ml/orchestration/api/registry.py | `path` | `str(file_path.absolute()),` |
| modules/ml/orchestration/api/registry.py | `format` | `"GGUF",` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `round(size_gb, 2),` |
| modules/ml/orchestration/api/registry.py | `vram_estimate_gb` | `round(vram_estimate, 2),` |
| modules/ml/orchestration/api/registry.py | `architecture` | `architecture,` |
| modules/ml/orchestration/api/registry.py | `quantization` | `quantization,` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `parameter_count,` |
| modules/ml/orchestration/api/registry.py | `context_length` | `0,  # Would need to parse GGUF header` |
| modules/ml/orchestration/api/registry.py | `compatible_backends` | `json.dumps(backends),` |
| modules/ml/orchestration/api/registry.py | `last_scanned` | `datetime.now().isoformat(),` |
| modules/ml/orchestration/api/registry.py | `priority` | `"medium",` |
| modules/ml/orchestration/api/registry.py | `tags` | `json.dumps([]),` |
| modules/ml/orchestration/api/registry.py | `notes` | `""` |
| modules/ml/orchestration/api/registry.py | `print(f"  Error scanning GGUF {file_path}: {e}", file` | `sys.stderr)` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `file_path.stat().st_size / (1024 ** 3)` |
| modules/ml/orchestration/api/registry.py | `filename` | `file_path.stem` |
| modules/ml/orchestration/api/registry.py | `param_match` | `self.PARAM_PATTERN.search(filename)` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `param_match.group(1).upper() if param_match else ""` |
| modules/ml/orchestration/api/registry.py | `architecture` | `"unknown"` |
| modules/ml/orchestration/api/registry.py | `architecture` | `arch` |
| modules/ml/orchestration/api/registry.py | `vram_estimate` | `size_gb * 1.2` |
| modules/ml/orchestration/api/registry.py | `backends` | `["vllm", "tgi"]` |
| modules/ml/orchestration/api/registry.py | `name` | `filename,` |
| modules/ml/orchestration/api/registry.py | `path` | `str(file_path.absolute()),` |
| modules/ml/orchestration/api/registry.py | `format` | `"SafeTensors",` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `round(size_gb, 2),` |
| modules/ml/orchestration/api/registry.py | `vram_estimate_gb` | `round(vram_estimate, 2),` |
| modules/ml/orchestration/api/registry.py | `architecture` | `architecture,` |
| modules/ml/orchestration/api/registry.py | `quantization` | `"fp16",  # Assume fp16` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `parameter_count,` |
| modules/ml/orchestration/api/registry.py | `context_length` | `0,` |
| modules/ml/orchestration/api/registry.py | `compatible_backends` | `json.dumps(backends),` |
| modules/ml/orchestration/api/registry.py | `last_scanned` | `datetime.now().isoformat(),` |
| modules/ml/orchestration/api/registry.py | `priority` | `"medium",` |
| modules/ml/orchestration/api/registry.py | `tags` | `json.dumps([]),` |
| modules/ml/orchestration/api/registry.py | `notes` | `""` |
| modules/ml/orchestration/api/registry.py | `print(f"  Error scanning SafeTensors {file_path}: {e}", file` | `sys.stderr)` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `file_path.stat().st_size / (1024 ** 3)` |
| modules/ml/orchestration/api/registry.py | `filename` | `file_path.stem` |
| modules/ml/orchestration/api/registry.py | `param_match` | `self.PARAM_PATTERN.search(filename)` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `param_match.group(1).upper() if param_match else ""` |
| modules/ml/orchestration/api/registry.py | `architecture` | `"unknown"` |
| modules/ml/orchestration/api/registry.py | `architecture` | `arch` |
| modules/ml/orchestration/api/registry.py | `vram_estimate` | `size_gb * 1.2` |
| modules/ml/orchestration/api/registry.py | `backends` | `["pytorch"]` |
| modules/ml/orchestration/api/registry.py | `name` | `filename,` |
| modules/ml/orchestration/api/registry.py | `path` | `str(file_path.absolute()),` |
| modules/ml/orchestration/api/registry.py | `format` | `"PyTorch",` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `round(size_gb, 2),` |
| modules/ml/orchestration/api/registry.py | `vram_estimate_gb` | `round(vram_estimate, 2),` |
| modules/ml/orchestration/api/registry.py | `architecture` | `architecture,` |
| modules/ml/orchestration/api/registry.py | `quantization` | `"fp32",` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `parameter_count,` |
| modules/ml/orchestration/api/registry.py | `context_length` | `0,` |
| modules/ml/orchestration/api/registry.py | `compatible_backends` | `json.dumps(backends),` |
| modules/ml/orchestration/api/registry.py | `last_scanned` | `datetime.now().isoformat(),` |
| modules/ml/orchestration/api/registry.py | `priority` | `"medium",` |
| modules/ml/orchestration/api/registry.py | `tags` | `json.dumps([]),` |
| modules/ml/orchestration/api/registry.py | `notes` | `""` |
| modules/ml/orchestration/api/registry.py | `print(f"  Error scanning PyTorch {file_path}: {e}", file` | `sys.stderr)` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `file_path.stat().st_size / (1024 ** 3)` |
| modules/ml/orchestration/api/registry.py | `filename` | `file_path.stem` |
| modules/ml/orchestration/api/registry.py | `param_match` | `self.PARAM_PATTERN.search(filename)` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `param_match.group(1).upper() if param_match else ""` |
| modules/ml/orchestration/api/registry.py | `vram_estimate` | `size_gb * 1.1` |
| modules/ml/orchestration/api/registry.py | `backends` | `["onnx"]` |
| modules/ml/orchestration/api/registry.py | `name` | `filename,` |
| modules/ml/orchestration/api/registry.py | `path` | `str(file_path.absolute()),` |
| modules/ml/orchestration/api/registry.py | `format` | `"ONNX",` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `round(size_gb, 2),` |
| modules/ml/orchestration/api/registry.py | `vram_estimate_gb` | `round(vram_estimate, 2),` |
| modules/ml/orchestration/api/registry.py | `architecture` | `"unknown",` |
| modules/ml/orchestration/api/registry.py | `quantization` | `"",` |
| modules/ml/orchestration/api/registry.py | `parameter_count` | `parameter_count,` |
| modules/ml/orchestration/api/registry.py | `context_length` | `0,` |
| modules/ml/orchestration/api/registry.py | `compatible_backends` | `json.dumps(backends),` |
| modules/ml/orchestration/api/registry.py | `last_scanned` | `datetime.now().isoformat(),` |
| modules/ml/orchestration/api/registry.py | `priority` | `"medium",` |
| modules/ml/orchestration/api/registry.py | `tags` | `json.dumps([]),` |
| modules/ml/orchestration/api/registry.py | `notes` | `""` |
| modules/ml/orchestration/api/registry.py | `print(f"  Error scanning ONNX {file_path}: {e}", file` | `sys.stderr)` |
| modules/ml/orchestration/api/registry.py | `model_dir` | `file_path.parent` |
| modules/ml/orchestration/api/registry.py | `model_name` | `model_dir.name` |
| modules/ml/orchestration/api/registry.py | `size_gb` | `total_size / (1024 ** 3)` |
| modules/ml/orchestration/backends/default.nix | `default` | `[ ]` |
| modules/ml/orchestration/backends/default.nix | `description` | `"List of enabled backend names (populated by individual drivers)"` |
| modules/ml/orchestration/backends/default.nix | `readOnly` | `true` |
| modules/packages/deb-packages/builder.nix | `debFile` | `fetchers.fetchSource name pkg.source "deb"` |
| modules/packages/deb-packages/builder.nix | `extracted` | `fetchers.extractDeb name debFile` |
| modules/packages/deb-packages/builder.nix | `commonArgs` | `{` |
| modules/packages/deb-packages/builder.nix | `sandbox` | `pkg.sandbox` |
| modules/packages/deb-packages/builder.nix | `wrapper_raw` | `pkg.wrapper` |
| modules/packages/deb-packages/builder.nix | `meta` | `pkg.meta` |
| modules/packages/deb-packages/builder.nix | `if pkg.method` | `= "auto" then` |
| modules/packages/deb-packages/builder.nix | `package` | `if method == "fhs" then builders.buildFHS commonArgs else builders.buildNative commonArgs` |
| modules/packages/deb-packages/builder.nix | `auditResult` | `import ./audit.nix {` |
| modules/packages/deb-packages/builder.nix | `fetchDeb` | `name: source: fetchers.fetchSource name source "deb"` |
| modules/packages/deb-packages/builder.nix | `extractDeb` | `fetchers.extractDeb` |
| modules/shell/aliases/docker/compose.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/docker/compose.nix | `"dc"` | `"docker compose"` |
| modules/ml/infrastructure/storage.nix | `default` | `"/var/lib/ml-models"` |
| modules/ml/infrastructure/storage.nix | `description` | `"Base directory for all ML models"` |
| modules/ml/infrastructure/storage.nix | `systemd.tmpfiles.rules` | `[` |
| modules/ml/infrastructure/storage.nix | `environment.variables` | `{` |
| modules/ml/infrastructure/storage.nix | `ML_MODELS_BASE` | `cfg.baseDirectory` |
| modules/ml/infrastructure/storage.nix | `LLAMACPP_MODELS_PATH` | `"${cfg.baseDirectory}/llamacpp"` |
| modules/ml/infrastructure/storage.nix | `OLLAMA_MODELS_PATH` | `"${cfg.baseDirectory}/ollama/models"` |
| modules/ml/infrastructure/storage.nix | `HF_HOME` | `"${cfg.baseDirectory}/huggingface"` |
| modules/ml/infrastructure/storage.nix | `HF_HUB_CACHE` | `"${cfg.baseDirectory}/huggingface/hub"` |
| modules/ml/infrastructure/storage.nix | `HF_DATASETS_CACHE` | `"${cfg.baseDirectory}/huggingface/datasets"` |
| modules/ml/infrastructure/storage.nix | `TRANSFORMERS_CACHE` | `"${cfg.baseDirectory}/huggingface/hub"` |
| modules/ml/infrastructure/storage.nix | `environment.shellAliases` | `{` |
| modules/ml/infrastructure/storage.nix | `ml-models` | `"cd ${cfg.baseDirectory}"` |
| modules/ml/infrastructure/storage.nix | `ml-clean-cache` | `"rm -rf ${cfg.baseDirectory}/cache/*"` |
| modules/ml/infrastructure/storage.nix | `systemd.services.ml-storage-monitor` | `{` |
| modules/ml/infrastructure/storage.nix | `description` | `"ML Models Storage Monitor"` |
| modules/ml/infrastructure/storage.nix | `after` | `[ "local-fs.target" ]` |
| modules/ml/infrastructure/storage.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/ml/infrastructure/storage.nix | `serviceConfig` | `{` |
| modules/ml/infrastructure/storage.nix | `Type` | `"oneshot"` |
| modules/ml/infrastructure/storage.nix | `User` | `"root"` |
| modules/ml/infrastructure/storage.nix | `BASE_DIR` | `"${cfg.baseDirectory}"` |
| modules/ml/infrastructure/storage.nix | `AVAIL` | `$(df -BG "$BASE_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')` |
| modules/ml/infrastructure/storage.nix | `systemd.timers.ml-storage-monitor` | `{` |
| modules/ml/infrastructure/storage.nix | `description` | `"ML Storage Monitor Timer"` |
| modules/ml/infrastructure/storage.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/ml/infrastructure/storage.nix | `timerConfig` | `{` |
| modules/ml/infrastructure/storage.nix | `OnCalendar` | `"weekly"` |
| modules/ml/infrastructure/storage.nix | `Persistent` | `true` |
| modules/shell/aliases/kubernetes/kubectl.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/kubernetes/kubectl.nix | `"k"` | `"kubectl"` |
| modules/ml/orchestration/registry/database.nix | `MODELS_PATH` | `"${offloadCfg.modelsPath}"` |
| modules/ml/orchestration/registry/database.nix | `DB_PATH` | `"${offloadCfg.dataDir}/registry.db"` |
| modules/ml/orchestration/registry/database.nix | `LOG_FILE` | `"${offloadCfg.dataDir}/logs/registry-scan.log"` |
| modules/ml/orchestration/registry/database.nix | `EXIT_CODE` | `$?` |
| modules/ml/orchestration/registry/database.nix | `default` | `"1h"` |
| modules/ml/orchestration/registry/database.nix | `example` | `"30m"` |
| modules/ml/orchestration/registry/database.nix | `description` | `''` |
| modules/ml/orchestration/registry/database.nix | `default` | `true` |
| modules/ml/orchestration/registry/database.nix | `description` | `"Run initial model scan on system boot"` |
| modules/ml/orchestration/registry/database.nix | `default` | `[` |
| modules/ml/orchestration/registry/database.nix | `description` | `"List of paths to scan for models"` |
| modules/ml/orchestration/registry/database.nix | `default` | `[` |
| modules/ml/orchestration/registry/database.nix | `description` | `"Glob patterns to exclude from scanning"` |
| modules/ml/orchestration/registry/database.nix | `systemd.tmpfiles.rules` | `[` |
| modules/ml/orchestration/registry/database.nix | `systemd.services.ml-registry-scan` | `{` |
| modules/ml/orchestration/registry/database.nix | `description` | `"ML Model Registry Scanner"` |
| modules/ml/orchestration/registry/database.nix | `documentation` | `[ "file:///etc/nixos/modules/ml/offload/model-registry.nix" ]` |
| modules/ml/orchestration/registry/database.nix | `serviceConfig` | `{` |
| modules/ml/orchestration/registry/database.nix | `Type` | `"oneshot"` |
| modules/ml/orchestration/registry/database.nix | `User` | `"ml-offload"` |
| modules/ml/orchestration/registry/database.nix | `Group` | `"ml-offload"` |
| modules/ml/orchestration/registry/database.nix | `ExecStart` | `"${registryScript}"` |
| modules/ml/orchestration/registry/database.nix | `PrivateTmp` | `true` |
| modules/ml/orchestration/registry/database.nix | `NoNewPrivileges` | `true` |
| modules/ml/orchestration/registry/database.nix | `ProtectSystem` | `"strict"` |
| modules/ml/orchestration/registry/database.nix | `ProtectHome` | `true` |
| modules/ml/orchestration/registry/database.nix | `ReadWritePaths` | `[` |
| modules/ml/orchestration/registry/database.nix | `ReadOnlyPaths` | `[` |
| modules/ml/orchestration/registry/database.nix | `CPUQuota` | `"50%"` |
| modules/ml/orchestration/registry/database.nix | `MemoryMax` | `"512M"` |
| modules/ml/orchestration/registry/database.nix | `TasksMax` | `10` |
| modules/ml/orchestration/registry/database.nix | `after` | `[ "local-fs.target" ]` |
| modules/ml/orchestration/registry/database.nix | `wants` | `[ "local-fs.target" ]` |
| modules/ml/orchestration/registry/database.nix | `systemd.timers.ml-registry-scan` | `mkIf (cfg.autoScanInterval != "") {` |
| modules/ml/orchestration/registry/database.nix | `description` | `"ML Model Registry Auto-Scan Timer"` |
| modules/ml/orchestration/registry/database.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/ml/orchestration/registry/database.nix | `timerConfig` | `{` |
| modules/ml/orchestration/registry/database.nix | `OnBootSec` | `if cfg.scanOnBoot then "5min" else null` |
| modules/ml/orchestration/registry/database.nix | `OnUnitActiveSec` | `cfg.autoScanInterval` |
| modules/ml/orchestration/registry/database.nix | `Unit` | `"ml-registry-scan.service"` |
| modules/ml/orchestration/registry/database.nix | `Persistent` | `true` |
| modules/ml/orchestration/registry/database.nix | `programs.bash.shellAliases` | `{` |
| modules/ml/orchestration/registry/database.nix | `ml-registry-scan` | `"sudo systemctl start ml-registry-scan.service"` |
| modules/ml/orchestration/registry/database.nix | `ml-registry-status` | `"sudo systemctl status ml-registry-scan.service"` |
| modules/ml/orchestration/registry/database.nix | `ml-registry-log` | `"sudo journalctl -u ml-registry-scan.service -n 50"` |
| modules/ml/services/llama-cpp.nix | `cudaSupport` | `true` |
| modules/ml/services/llama-cpp.nix | `defaultText` | `lib.literalExpression ''` |
| modules/ml/services/llama-cpp.nix | `cudaSupport` | `true` |
| modules/ml/services/llama-cpp.nix | `description` | `"The llama-cpp package to use."` |
| modules/ml/services/llama-cpp.nix | `example` | `"/var/lib/llama-cpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf"` |
| modules/ml/services/llama-cpp.nix | `description` | `"Path to the model file."` |
| modules/ml/services/llama-cpp.nix | `default` | `"127.0.0.1"` |
| modules/ml/services/llama-cpp.nix | `example` | `"0.0.0.0"` |
| modules/ml/services/llama-cpp.nix | `description` | `"IP address the LLaMA C++ server listens on."` |
| modules/ml/services/llama-cpp.nix | `default` | `8080` |
| modules/ml/services/llama-cpp.nix | `description` | `"Listen port for LLaMA C++ server."` |
| modules/ml/services/llama-cpp.nix | `default` | `6` |
| modules/ml/services/llama-cpp.nix | `description` | `"Number of threads to use for generation."` |
| modules/ml/services/llama-cpp.nix | `default` | `22` |
| modules/ml/services/llama-cpp.nix | `description` | `''` |
| modules/ml/services/llama-cpp.nix | `default` | `1` |
| modules/ml/services/llama-cpp.nix | `description` | `"Number of parallel sequences to process."` |
| modules/ml/services/llama-cpp.nix | `default` | `4096` |
| modules/ml/services/llama-cpp.nix | `default` | `2048` |
| modules/ml/services/llama-cpp.nix | `description` | `"Batch size for prompt processing."` |
| modules/ml/services/llama-cpp.nix | `default` | `[ ]` |
| modules/ml/services/llama-cpp.nix | `example` | `[` |
| modules/ml/services/llama-cpp.nix | `description` | `''` |
| modules/ml/services/llama-cpp.nix | `default` | `false` |
| modules/ml/services/llama-cpp.nix | `description` | `''` |
| modules/ml/services/llama-cpp.nix | `systemd.services.llamacpp` | `{` |
| modules/ml/services/llama-cpp.nix | `after` | `[ "network.target" ]` |
| modules/ml/services/llama-cpp.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/ml/services/llama-cpp.nix | `environment` | `{` |
| modules/ml/services/llama-cpp.nix | `CUDA_VISIBLE_DEVICES` | `"-0"` |
| modules/ml/services/llama-cpp.nix | `GGML_CUDA_NO_PEER_COPY` | `"1"` |
| modules/ml/services/llama-cpp.nix | `CUDA_LAUNCH_BLOCKING` | `"1"` |
| modules/ml/services/llama-cpp.nix | `serviceConfig` | `{` |
| modules/ml/services/llama-cpp.nix | `Type` | `"idle"` |
| modules/ml/services/llama-cpp.nix | `ExecStart` | `lib.concatStringsSep " " (` |
| modules/ml/services/llama-cpp.nix | `Restart` | `"always"` |
| modules/ml/services/llama-cpp.nix | `RestartSec` | `10` |
| modules/ml/services/llama-cpp.nix | `User` | `"llamacpp"` |
| modules/ml/services/llama-cpp.nix | `Group` | `"llamacpp"` |
| modules/ml/services/llama-cpp.nix | `TimeoutStopSec` | `"30s"` |
| modules/ml/services/llama-cpp.nix | `KillMode` | `"mixed"` |
| modules/ml/services/llama-cpp.nix | `KillSignal` | `"SIGTERM"` |
| modules/ml/services/llama-cpp.nix | `DeviceAllow` | `[` |
| modules/ml/services/llama-cpp.nix | `PrivateDevices` | `false` |
| modules/ml/services/llama-cpp.nix | `CapabilityBoundingSet` | `""` |
| modules/ml/services/llama-cpp.nix | `RestrictAddressFamilies` | `[` |
| modules/ml/services/llama-cpp.nix | `NoNewPrivileges` | `true` |
| modules/ml/services/llama-cpp.nix | `PrivateMounts` | `true` |
| modules/ml/services/llama-cpp.nix | `PrivateTmp` | `true` |
| modules/ml/services/llama-cpp.nix | `PrivateUsers` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectClock` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectControlGroups` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectHome` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectKernelLogs` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectKernelModules` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectKernelTunables` | `true` |
| modules/ml/services/llama-cpp.nix | `ProtectSystem` | `"strict"` |
| modules/ml/services/llama-cpp.nix | `MemoryDenyWriteExecute` | `true` |
| modules/ml/services/llama-cpp.nix | `LockPersonality` | `true` |
| modules/ml/services/llama-cpp.nix | `RemoveIPC` | `true` |
| modules/ml/services/llama-cpp.nix | `RestrictNamespaces` | `true` |
| modules/ml/services/llama-cpp.nix | `RestrictRealtime` | `true` |
| modules/ml/services/llama-cpp.nix | `RestrictSUIDSGID` | `true` |
| modules/ml/services/llama-cpp.nix | `SystemCallArchitectures` | `"native"` |
| modules/ml/services/llama-cpp.nix | `SystemCallFilter` | `[` |
| modules/ml/services/llama-cpp.nix | `SystemCallErrorNumber` | `"EPERM"` |
| modules/ml/services/llama-cpp.nix | `ProtectProc` | `"invisible"` |
| modules/ml/services/llama-cpp.nix | `ProtectHostname` | `true` |
| modules/ml/services/llama-cpp.nix | `ProcSubset` | `"pid"` |
| modules/ml/services/llama-cpp.nix | `allowedTCPPorts` | `[ cfg.port ]` |
| modules/development/environments.nix | `kernelcore.development` | `{` |
| modules/ml/orchestration/flake.nix | `inputs` | `{` |
| modules/ml/orchestration/flake.nix | `rust-overlay.url` | `"github:oxalica/rust-overlay"` |
| modules/ml/orchestration/flake.nix | `flake-utils.url` | `"github:numtide/flake-utils"` |
| modules/ml/orchestration/flake.nix | `overlays` | `[ (import rust-overlay) ]` |
| modules/ml/orchestration/flake.nix | `extensions` | `[` |
| modules/ml/orchestration/flake.nix | `enableGpu` | `true` |
| modules/ml/orchestration/flake.nix | `if system` | `= "x86_64-linux" then` |
| modules/ml/orchestration/flake.nix | `pname` | `"ml-offload-api"` |
| modules/ml/orchestration/flake.nix | `version` | `"0.1.0"` |
| modules/ml/orchestration/flake.nix | `src` | `./api` |
| modules/ml/orchestration/flake.nix | `cargoLock` | `{` |
| modules/ml/orchestration/flake.nix | `lockFile` | `./api/Cargo.lock` |
| modules/ml/orchestration/flake.nix | `buildPhase` | `''` |
| modules/ml/orchestration/flake.nix | `installPhase` | `''` |
| modules/ml/orchestration/flake.nix | `description` | `"ML model orchestration API server"` |
| modules/ml/orchestration/flake.nix | `license` | `licenses.mit` |
| modules/ml/orchestration/flake.nix | `maintainers` | `[ "kernelcore" ]` |
| modules/ml/orchestration/flake.nix | `pname` | `"ml-offload-python-scripts"` |
| modules/ml/orchestration/flake.nix | `version` | `"0.1.0"` |
| modules/ml/orchestration/flake.nix | `src` | `./api` |
| modules/ml/orchestration/flake.nix | `buildInputs` | `[ pythonEnv ]` |
| modules/ml/orchestration/flake.nix | `installPhase` | `''` |
| modules/ml/orchestration/flake.nix | `name` | `"ml-offload-all"` |
| modules/ml/orchestration/flake.nix | `paths` | `[` |
| modules/ml/orchestration/flake.nix | `packages` | `{` |
| modules/ml/orchestration/flake.nix | `default` | `mlOffloadAll` |
| modules/ml/orchestration/flake.nix | `rust` | `rustApi` |
| modules/ml/orchestration/flake.nix | `python` | `pythonScripts` |
| modules/ml/orchestration/flake.nix | `all` | `mlOffloadAll` |
| modules/ml/orchestration/flake.nix | `apps` | `{` |
| modules/ml/orchestration/flake.nix | `default` | `{` |
| modules/ml/orchestration/flake.nix | `type` | `"app"` |
| modules/ml/orchestration/flake.nix | `program` | `"${rustApi}/bin/ml-offload-api"` |
| modules/ml/orchestration/flake.nix | `rust-api` | `{` |
| modules/ml/orchestration/flake.nix | `type` | `"app"` |
| modules/ml/orchestration/flake.nix | `program` | `"${rustApi}/bin/ml-offload-api"` |
| modules/ml/orchestration/flake.nix | `python-api` | `{` |
| modules/ml/orchestration/flake.nix | `type` | `"app"` |
| modules/ml/orchestration/flake.nix | `program` | `"${pythonScripts}/bin/ml-offload-api-python"` |
| modules/ml/orchestration/flake.nix | `registry` | `{` |
| modules/ml/orchestration/flake.nix | `type` | `"app"` |
| modules/ml/orchestration/flake.nix | `program` | `"${pythonScripts}/bin/ml-offload-registry"` |
| modules/ml/orchestration/flake.nix | `vram-monitor` | `{` |
| modules/ml/orchestration/flake.nix | `type` | `"app"` |
| modules/ml/orchestration/flake.nix | `program` | `"${pythonScripts}/bin/ml-offload-vram-monitor"` |
| modules/ml/orchestration/flake.nix | `shellHook` | `''` |
| modules/ml/orchestration/flake.nix | `nvidia-smi --query-gpu` | `name,memory.total --format=csv,noheader 2>/dev/null || echo "  nvidia-smi not available"` |
| modules/ml/orchestration/flake.nix | `ML_OFFLOAD_DATA_DIR` | `"./data"` |
| modules/ml/orchestration/flake.nix | `ML_OFFLOAD_MODELS_PATH` | `"./models"` |
| modules/ml/orchestration/flake.nix | `ML_OFFLOAD_LOG_DIR` | `"./logs"` |
| modules/ml/orchestration/flake.nix | `checks` | `{` |
| modules/ml/orchestration/flake.nix | `rust-build` | `rustApi` |
| modules/ml/orchestration/flake.nix | `python-build` | `pythonScripts` |
| modules/packages/deb-packages/default.nix | `default` | `true` |
| modules/packages/deb-packages/default.nix | `type` | `sharedTypes.methodType` |
| modules/packages/deb-packages/default.nix | `default` | `"auto"` |
| modules/packages/deb-packages/default.nix | `description` | `"Integration method: fhs, native, or auto"` |
| modules/packages/deb-packages/default.nix | `type` | `sharedTypes.sourceType` |
| modules/packages/deb-packages/default.nix | `type` | `sharedTypes.sandboxType` |
| modules/packages/deb-packages/default.nix | `default` | `{ }` |
| modules/packages/deb-packages/default.nix | `type` | `sharedTypes.auditType cfg.auditByDefault` |
| modules/packages/deb-packages/default.nix | `default` | `{ }` |
| modules/packages/deb-packages/default.nix | `type` | `sharedTypes.wrapperType name` |
| modules/packages/deb-packages/default.nix | `default` | `{ }` |
| modules/packages/deb-packages/default.nix | `type` | `sharedTypes.metaType` |
| modules/packages/deb-packages/default.nix | `default` | `{ }` |
| modules/packages/deb-packages/default.nix | `description` | `"Package metadata"` |
| modules/packages/deb-packages/default.nix | `default` | `{ }` |
| modules/packages/deb-packages/default.nix | `description` | `"Attribute set of .deb packages to manage"` |
| modules/packages/deb-packages/default.nix | `default` | `true` |
| modules/packages/deb-packages/default.nix | `description` | `"Enable audit logging by default for all packages"` |
| modules/packages/deb-packages/default.nix | `default` | `/etc/nixos/modules/packages/deb-packages/storage` |
| modules/packages/deb-packages/default.nix | `default` | `"/var/cache/deb-packages"` |
| modules/packages/deb-packages/default.nix | `description` | `"Runtime cache directory for extracted packages"` |
| modules/packages/deb-packages/default.nix | `builder` | `import ./builder.nix {` |
| modules/packages/deb-packages/default.nix | `enabledPackages` | `filterAttrs (_: pkg: pkg.enable) cfg.packages` |
| modules/packages/deb-packages/default.nix | `builtPackages` | `mapAttrs (name: pkg: builder.buildDebPackage name pkg) enabledPackages` |
| modules/packages/deb-packages/default.nix | `systemd.tmpfiles.rules` | `[ "d ${cfg.cacheDir} 0755 root root -" ]` |
| modules/packages/deb-packages/default.nix | `environment.systemPackages` | `attrValues builtPackages` |
| modules/packages/deb-packages/default.nix | `packagesWithoutHash` | `filterAttrs (_: pkg: pkg.enable && pkg.source.sha256 == "") cfg.packages` |
| modules/packages/deb-packages/default.nix | `assertion` | `packagesWithoutHash == { }` |
| modules/packages/deb-packages/default.nix | `message` | `"All .deb packages MUST have SHA256 hash. Missing: ${concatStringsSep ", " (attrNames packagesWithoutHash)}"` |
| modules/shell/aliases/service-control.nix | `environment.systemPackages` | `[` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total --format=csv,noheader 2>/dev/null || true` |
| modules/shell/aliases/service-control.nix | `echo "` | `== ML OFFLOAD API ==="` |
| modules/shell/aliases/service-control.nix | `echo "` | `== VRAM MONITOR ==="` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"` |
| modules/shell/aliases/service-control.nix | `echo "` | `== GPU STATUS ==="` |
| modules/shell/aliases/service-control.nix | `echo "` | `== GPU SERVICES ==="` |
| modules/shell/aliases/service-control.nix | `watch -n 1 'nvidia-smi && echo "" && echo "` | `== GPU Services ===" && \` |
| modules/shell/aliases/service-control.nix | `watch -n 1 'free -h && echo "" && echo "` | `== Top RAM Consumers ===" && \` |
| modules/shell/aliases/service-control.nix | `ps aux --sort` | `-%mem | head -11'` |
| modules/shell/aliases/service-control.nix | `echo "` | `== SYSTEM SERVICES STATUS ==="` |
| modules/shell/aliases/service-control.nix | `echo "` | `== RESOURCES ==="` |
| modules/shell/aliases/service-control.nix | `nvidia-smi --query-gpu` | `name,memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "GPU: N/A"` |
| modules/shell/aliases/service-control.nix | `if [[ $REPLY` | `~ ^[Yy]$ ]]; then` |
| modules/shell/aliases/service-control.nix | `programs.zsh.shellAliases` | `{` |
| modules/shell/aliases/service-control.nix | `"svc"` | `"monitor-services"` |
| modules/shell/aliases/service-control.nix | `programs.bash.shellAliases` | `{` |
| modules/shell/aliases/service-control.nix | `"svc"` | `"monitor-services"` |
| modules/ml/infrastructure/vram/monitoring.nix | `INTERVAL` | `${toString cfg.monitoringInterval}` |
| modules/ml/infrastructure/vram/monitoring.nix | `DB_PATH` | `"${offloadCfg.dataDir}/registry.db"` |
| modules/ml/infrastructure/vram/monitoring.nix | `LOG_FILE` | `"${offloadCfg.dataDir}/logs/vram-monitor.log"` |
| modules/ml/infrastructure/vram/monitoring.nix | `STATE_FILE` | `"${offloadCfg.dataDir}/vram-state.json"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `5` |
| modules/ml/infrastructure/vram/monitoring.nix | `autoScaling` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Enable automatic model eviction when VRAM threshold exceeded"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `85` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"VRAM usage percentage threshold for auto-scaling (0-100)"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `"priority"` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `''` |
| modules/ml/infrastructure/vram/monitoring.nix | `budgetPlanner` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Enable VRAM budget calculator for load predictions"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `10` |
| modules/ml/infrastructure/vram/monitoring.nix | `alerts` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Enable alerting for VRAM events"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `90` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Trigger alert when VRAM usage exceeds this percentage"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `"systemd"` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Alert notification method"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `null` |
| modules/ml/infrastructure/vram/monitoring.nix | `example` | `"http://localhost:8000/alerts"` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Webhook URL for alerts (if notificationMethod includes webhook)"` |
| modules/ml/infrastructure/vram/monitoring.nix | `scheduler` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Enable intelligent scheduling queue"` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `10` |
| modules/ml/infrastructure/vram/monitoring.nix | `default` | `300` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"Queue request timeout (auto-reject after N seconds)"` |
| modules/ml/infrastructure/vram/monitoring.nix | `systemd.tmpfiles.rules` | `[` |
| modules/ml/infrastructure/vram/monitoring.nix | `systemd.services.ml-vram-monitor` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `description` | `"ML VRAM Intelligence Monitor"` |
| modules/ml/infrastructure/vram/monitoring.nix | `documentation` | `[ "file:///etc/nixos/modules/ml/offload/vram-intelligence.nix" ]` |
| modules/ml/infrastructure/vram/monitoring.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/ml/infrastructure/vram/monitoring.nix | `after` | `[` |
| modules/ml/infrastructure/vram/monitoring.nix | `wants` | `[ "ml-offload-api.service" ]` |
| modules/ml/infrastructure/vram/monitoring.nix | `serviceConfig` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `Type` | `"simple"` |
| modules/ml/infrastructure/vram/monitoring.nix | `User` | `"ml-offload"` |
| modules/ml/infrastructure/vram/monitoring.nix | `Group` | `"ml-offload"` |
| modules/ml/infrastructure/vram/monitoring.nix | `ExecStart` | `"${vramMonitorScript}"` |
| modules/ml/infrastructure/vram/monitoring.nix | `Restart` | `"always"` |
| modules/ml/infrastructure/vram/monitoring.nix | `RestartSec` | `"10s"` |
| modules/ml/infrastructure/vram/monitoring.nix | `PrivateTmp` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `NoNewPrivileges` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `ProtectSystem` | `"strict"` |
| modules/ml/infrastructure/vram/monitoring.nix | `ProtectHome` | `true` |
| modules/ml/infrastructure/vram/monitoring.nix | `ReadWritePaths` | `[` |
| modules/ml/infrastructure/vram/monitoring.nix | `DeviceAllow` | `[` |
| modules/ml/infrastructure/vram/monitoring.nix | `SupplementaryGroups` | `[` |
| modules/ml/infrastructure/vram/monitoring.nix | `CPUQuota` | `"25%"` |
| modules/ml/infrastructure/vram/monitoring.nix | `MemoryMax` | `"256M"` |
| modules/ml/infrastructure/vram/monitoring.nix | `TasksMax` | `10` |
| modules/ml/infrastructure/vram/monitoring.nix | `programs.bash.shellAliases` | `{` |
| modules/ml/infrastructure/vram/monitoring.nix | `ml-vram` | `"sudo systemctl status ml-vram-monitor.service"` |
| modules/ml/infrastructure/vram/monitoring.nix | `ml-vram-status` | `"${pythonEnv}/bin/python3 ${./api/vram_monitor.py} status --state-file ${offloadCfg.dataDir}/vram-state.json"` |
| modules/ml/infrastructure/vram/monitoring.nix | `ml-vram-log` | `"sudo journalctl -u ml-vram-monitor.service -n 50 -f"` |
| modules/ml/infrastructure/vram/monitoring.nix | `ml-vram-restart` | `"sudo systemctl restart ml-vram-monitor.service"` |
| modules/shell/aliases/amazon/aws.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/amazon/aws.nix | `"aws-check"` | `"aws sts get-caller-identity"` |
| modules/development/cicd.nix | `kernelcore.development.cicd` | `{` |
| modules/development/cicd.nix | `platforms` | `{` |
| modules/development/cicd.nix | `pre-commit` | `{` |
| modules/development/cicd.nix | `default` | `true` |
| modules/development/cicd.nix | `description` | `"Check for uncommitted changes before push"` |
| modules/development/cicd.nix | `default` | `false` |
| modules/development/cicd.nix | `description` | `"Run tests before commit"` |
| modules/development/cicd.nix | `default` | `true` |
| modules/development/cicd.nix | `description` | `"Format code before commit"` |
| modules/development/cicd.nix | `default` | `true` |
| modules/development/cicd.nix | `default` | `false` |
| modules/development/cicd.nix | `description` | `"Automatically generate commit messages and commit changes using local LLM before push"` |
| modules/development/cicd.nix | `text` | `''` |
| modules/development/cicd.nix | `LFS_SIZE_LIMIT` | `52428800 # 50 MiB guardrail for git blobs` |
| modules/development/cicd.nix | `local bytes` | `$1` |
| modules/development/cicd.nix | `awk -v b` | `"$bytes" 'BEGIN { printf "%.1f", b/1048576 }'` |
| modules/development/cicd.nix | `local has_error` | `0` |
| modules/development/cicd.nix | `while IFS` | `read -r file; do` |
| modules/development/cicd.nix | `size` | `$(stat -c%s -- "$file" 2>/dev/null || echo 0)` |
| modules/development/cicd.nix | `attr` | `$(git check-attr filter -- "$file" 2>/dev/null | awk -F': ' '{print $3}')` |
| modules/development/cicd.nix | `if [ "$attr" !` | `"lfs" ]; then` |
| modules/development/cicd.nix | `has_error` | `1` |
| modules/development/cicd.nix | `mode` | `"0755"` |
| modules/development/cicd.nix | `text` | `''` |
| modules/development/cicd.nix | `LFS_SIZE_LIMIT` | `52428800 # 50 MiB guardrail for git blobs` |
| modules/development/cicd.nix | `local bytes` | `$1` |
| modules/development/cicd.nix | `awk -v b` | `"$bytes" 'BEGIN { printf "%.1f", b/1048576 }'` |
| modules/development/cicd.nix | `local has_error` | `0` |
| modules/development/cicd.nix | `while IFS` | `read -r file; do` |
| modules/development/cicd.nix | `size` | `$(stat -c%s -- "$file" 2>/dev/null || echo 0)` |
| modules/development/cicd.nix | `attr` | `$(git check-attr filter -- "$file" 2>/dev/null | awk -F': ' '{print $3}')` |
| modules/development/cicd.nix | `if [ "$attr" !` | `"lfs" ]; then` |
| modules/development/cicd.nix | `has_error` | `1` |
| modules/development/cicd.nix | `mode` | `"0755"` |
| modules/development/cicd.nix | `programs.git` | `{` |
| modules/development/cicd.nix | `enable` | `true` |
| modules/development/cicd.nix | `lfs.enable` | `true` |
| modules/development/cicd.nix | `core` | `{` |
| modules/development/cicd.nix | `environment.shellAliases` | `{` |
| modules/development/cicd.nix | `nix-check` | `"nix flake check --show-trace"` |
| modules/development/cicd.nix | `nix-fmt-check` | `"nix fmt -- --check ."` |
| modules/ml/orchestration/manager.nix | `pname` | `"ml-offload-api"` |
| modules/ml/orchestration/manager.nix | `version` | `"0.1.0"` |
| modules/ml/orchestration/manager.nix | `src` | `./api` |
| modules/ml/orchestration/manager.nix | `cargoLock` | `{` |
| modules/ml/orchestration/manager.nix | `lockFile` | `./api/Cargo.lock` |
| modules/ml/orchestration/manager.nix | `description` | `"ML Offload Manager - Unified REST API for ML model orchestration"` |
| modules/ml/orchestration/manager.nix | `license` | `licenses.mit` |
| modules/ml/orchestration/manager.nix | `maintainers` | `[ "kernelcore" ]` |
| modules/ml/orchestration/manager.nix | `default` | `"127.0.0.1"` |
| modules/ml/orchestration/manager.nix | `example` | `"0.0.0.0"` |
| modules/ml/orchestration/manager.nix | `description` | `"API server host address"` |
| modules/ml/orchestration/manager.nix | `default` | `9000` |
| modules/ml/orchestration/manager.nix | `description` | `"API server port"` |
| modules/ml/orchestration/manager.nix | `default` | `"info"` |
| modules/ml/orchestration/manager.nix | `description` | `"API logging level"` |
| modules/ml/orchestration/manager.nix | `default` | `1` |
| modules/ml/orchestration/manager.nix | `description` | `"Number of API worker processes (1 for single-threaded)"` |
| modules/ml/orchestration/manager.nix | `default` | `false` |
| modules/ml/orchestration/manager.nix | `description` | `"Enable CORS for API (useful for web frontends)"` |
| modules/ml/orchestration/manager.nix | `default` | `[ "http://localhost:3000" ]` |
| modules/ml/orchestration/manager.nix | `description` | `"Allowed CORS origins"` |
| modules/ml/orchestration/manager.nix | `rateLimiting` | `{` |
| modules/ml/orchestration/manager.nix | `default` | `true` |
| modules/ml/orchestration/manager.nix | `description` | `"Enable rate limiting for API endpoints"` |
| modules/ml/orchestration/manager.nix | `default` | `60` |
| modules/ml/orchestration/manager.nix | `description` | `"Maximum requests per minute per client IP"` |
| modules/ml/orchestration/manager.nix | `systemd.services.ml-offload-api` | `{` |
| modules/ml/orchestration/manager.nix | `description` | `"ML Offload Manager REST API (Rust)"` |
| modules/ml/orchestration/manager.nix | `documentation` | `[` |
| modules/ml/orchestration/manager.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/ml/orchestration/manager.nix | `after` | `[ "network.target" ]` |
| modules/ml/orchestration/manager.nix | `wants` | `[ "network.target" ]` |
| modules/ml/orchestration/manager.nix | `environment` | `{` |
| modules/ml/orchestration/manager.nix | `if cfg.logLevel` | `= "debug" then` |
| modules/ml/orchestration/manager.nix | `"ml_offload_api` | `debug,axum=debug"` |
| modules/ml/orchestration/manager.nix | `"ml_offload_api` | `info,axum=info"` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_DATA_DIR` | `offloadCfg.dataDir` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_MODELS_PATH` | `offloadCfg.modelsPath` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_DB_PATH` | `"${offloadCfg.dataDir}/registry.db"` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_STATE_FILE` | `"${offloadCfg.dataDir}/vram-state.json"` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_HOST` | `cfg.host` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_PORT` | `toString cfg.port` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_CORS_ENABLED` | `if cfg.corsEnabled then "true" else "false"` |
| modules/ml/orchestration/manager.nix | `ML_OFFLOAD_CORS_ORIGINS` | `lib.concatStringsSep "," cfg.corsOrigins` |
| modules/ml/orchestration/manager.nix | `LD_LIBRARY_PATH` | `"/run/opengl-driver/lib"` |
| modules/ml/orchestration/manager.nix | `serviceConfig` | `{` |
| modules/ml/orchestration/manager.nix | `Type` | `"simple"` |
| modules/ml/orchestration/manager.nix | `User` | `"ml-offload"` |
| modules/ml/orchestration/manager.nix | `Group` | `"ml-offload"` |
| modules/ml/orchestration/manager.nix | `ExecStart` | `"${ml-offload-api}/bin/ml-offload-api"` |
| modules/ml/orchestration/manager.nix | `Restart` | `"always"` |
| modules/ml/orchestration/manager.nix | `RestartSec` | `"10s"` |
| modules/ml/orchestration/manager.nix | `PrivateTmp` | `true` |
| modules/ml/orchestration/manager.nix | `NoNewPrivileges` | `true` |
| modules/ml/orchestration/manager.nix | `ProtectSystem` | `"strict"` |
| modules/ml/orchestration/manager.nix | `ProtectHome` | `true` |
| modules/ml/orchestration/manager.nix | `ReadWritePaths` | `[` |
| modules/ml/orchestration/manager.nix | `ReadOnlyPaths` | `[` |
| modules/ml/orchestration/manager.nix | `DeviceAllow` | `[` |
| modules/ml/orchestration/manager.nix | `SupplementaryGroups` | `[` |
| modules/ml/orchestration/manager.nix | `CPUQuota` | `"100%"` |
| modules/ml/orchestration/manager.nix | `MemoryMax` | `"1G"` |
| modules/ml/orchestration/manager.nix | `TasksMax` | `100` |
| modules/ml/orchestration/manager.nix | `RestrictAddressFamilies` | `[` |
| modules/ml/orchestration/manager.nix | `networking.firewall.allowedTCPPorts` | `mkIf (cfg.host != "127.0.0.1") [ cfg.port ]` |
| modules/ml/orchestration/manager.nix | `programs.bash.shellAliases` | `{` |
| modules/ml/orchestration/manager.nix | `ml-offload-api` | `"sudo systemctl status ml-offload-api.service"` |
| modules/ml/orchestration/manager.nix | `ml-offload-api-restart` | `"sudo systemctl restart ml-offload-api.service"` |
| modules/ml/orchestration/manager.nix | `ml-offload-api-log` | `"sudo journalctl -u ml-offload-api.service -n 100 -f"` |
| modules/ml/orchestration/manager.nix | `environment.systemPackages` | `[` |
| modules/shell/aliases/emergency.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/emergency.nix | `"emergency-status"` | `"bash /etc/nixos/scripts/nix-emergency.sh status"` |
| modules/shell/aliases/emergency.nix | `environment.interactiveShellInit` | `''` |
| modules/ml/services/ollama/gpu-manager.nix | `default` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `description` | `"Automatically unload Ollama models from GPU on shell exit"` |
| modules/ml/services/ollama/gpu-manager.nix | `default` | `300; # 5 minutes` |
| modules/ml/services/ollama/gpu-manager.nix | `description` | `"Seconds of inactivity before auto-unloading models (0 to disable)"` |
| modules/ml/services/ollama/gpu-manager.nix | `default` | `30` |
| modules/ml/services/ollama/gpu-manager.nix | `description` | `"Seconds between idle checks"` |
| modules/ml/services/ollama/gpu-manager.nix | `environment.interactiveShellInit` | `mkIf cfg.unloadOnShellExit ''` |
| modules/ml/services/ollama/gpu-manager.nix | `systemd.services.ollama-gpu-idle-monitor` | `mkIf (cfg.idleTimeout > 0) {` |
| modules/ml/services/ollama/gpu-manager.nix | `description` | `"Ollama GPU Idle Monitor - Auto-offload inactive models"` |
| modules/ml/services/ollama/gpu-manager.nix | `after` | `[ "ollama.service" ]` |
| modules/ml/services/ollama/gpu-manager.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/ml/services/ollama/gpu-manager.nix | `serviceConfig` | `{` |
| modules/ml/services/ollama/gpu-manager.nix | `Type` | `"simple"` |
| modules/ml/services/ollama/gpu-manager.nix | `Restart` | `"always"` |
| modules/ml/services/ollama/gpu-manager.nix | `RestartSec` | `10` |
| modules/ml/services/ollama/gpu-manager.nix | `User` | `"nobody"` |
| modules/ml/services/ollama/gpu-manager.nix | `Group` | `"nobody"` |
| modules/ml/services/ollama/gpu-manager.nix | `PrivateTmp` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `ProtectSystem` | `"strict"` |
| modules/ml/services/ollama/gpu-manager.nix | `ProtectHome` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `NoNewPrivileges` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `ProtectKernelTunables` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `ProtectKernelModules` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `ProtectControlGroups` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `RestrictNamespaces` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `RestrictRealtime` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `RestrictSUIDSGID` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `RemoveIPC` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `PrivateMounts` | `true` |
| modules/ml/services/ollama/gpu-manager.nix | `SystemCallFilter` | `"@system-service"` |
| modules/ml/services/ollama/gpu-manager.nix | `SystemCallErrorNumber` | `"EPERM"` |
| modules/ml/services/ollama/gpu-manager.nix | `script` | `''` |
| modules/ml/services/ollama/gpu-manager.nix | `IDLE_TIMEOUT` | `${toString cfg.idleTimeout}` |
| modules/ml/services/ollama/gpu-manager.nix | `CHECK_INTERVAL` | `${toString cfg.monitoringInterval}` |
| modules/ml/services/ollama/gpu-manager.nix | `LAST_ACTIVE` | `$(date +%s)` |
| modules/ml/services/ollama/gpu-manager.nix | `LAST_ACTIVE` | `$(date +%s)` |
| modules/ml/services/ollama/gpu-manager.nix | `CURRENT_TIME` | `$(date +%s)` |
| modules/ml/services/ollama/gpu-manager.nix | `IDLE_TIME` | `$((CURRENT_TIME - LAST_ACTIVE))` |
| modules/ml/services/ollama/gpu-manager.nix | `LAST_ACTIVE` | `$(date +%s)` |
| modules/ml/services/ollama/gpu-manager.nix | `environment.shellAliases` | `{` |
| modules/ml/services/ollama/gpu-manager.nix | `environment.systemPackages` | `[` |
| modules/development/jupyter.nix | `kernelcore.development.jupyter` | `{` |
| modules/development/jupyter.nix | `kernels` | `{` |
| modules/development/jupyter.nix | `default` | `true` |
| modules/development/jupyter.nix | `description` | `"Enable Python kernel"` |
| modules/development/jupyter.nix | `default` | `true` |
| modules/development/jupyter.nix | `description` | `"Enable Rust kernel (evcxr)"` |
| modules/development/jupyter.nix | `default` | `true` |
| modules/development/jupyter.nix | `description` | `"Enable Node.js kernel"` |
| modules/development/jupyter.nix | `default` | `true` |
| modules/development/jupyter.nix | `description` | `"Enable Nix kernel"` |
| modules/development/jupyter.nix | `default` | `true` |
| modules/development/jupyter.nix | `description` | `"Enable Jupyter-Daemon"` |
| modules/development/jupyter.nix | `extensions` | `{` |
| modules/development/jupyter.nix | `default` | `true` |
| modules/development/jupyter.nix | `description` | `"Enable common Jupyter extensions"` |
| modules/development/jupyter.nix | `description` | `"JupyterLab Server"` |
| modules/development/jupyter.nix | `after` | `[ "network.target" ]` |
| modules/development/jupyter.nix | `serviceConfig` | `{` |
| modules/development/jupyter.nix | `Type` | `"simple"` |
| modules/development/jupyter.nix | `Restart` | `"on-failure"` |
| modules/development/jupyter.nix | `LoadCredential` | `"jupyter-token:/etc/credstore/jupyter-token"` |
| modules/development/jupyter.nix | `DeviceAllow` | `[` |
| modules/development/jupyter.nix | `SupplementaryGroups` | `[ "nvidia" ]` |
| modules/development/jupyter.nix | `PrivateTmp` | `true` |
| modules/development/jupyter.nix | `ProtectSystem` | `"strict"` |
| modules/development/jupyter.nix | `NoNewPrivileges` | `true` |
| modules/ml/orchestration/default.nix | `default` | `"/var/lib/ml-offload"` |
| modules/ml/orchestration/default.nix | `description` | `"Base directory for ML Offload data (registry DB, logs, etc.)"` |
| modules/ml/orchestration/default.nix | `default` | `"/var/lib/ml-models"` |
| modules/ml/orchestration/default.nix | `description` | `"Path to models directory"` |
| modules/ml/orchestration/default.nix | `systemd.tmpfiles.rules` | `[` |
| modules/ml/orchestration/default.nix | `kernelcore.system.ml-gpu-users.enable` | `true` |
| modules/packages/deb-packages/audit.nix | `logDir` | `"/var/log/deb-packages"` |
| modules/packages/deb-packages/audit.nix | `logLevels` | `{` |
| modules/packages/deb-packages/audit.nix | `minimal` | `{` |
| modules/packages/deb-packages/audit.nix | `auditRules` | `[` |
| modules/packages/deb-packages/audit.nix | `journalFields` | `[ "MESSAGE" ]` |
| modules/packages/deb-packages/audit.nix | `standard` | `{` |
| modules/packages/deb-packages/audit.nix | `auditRules` | `[` |
| modules/packages/deb-packages/audit.nix | `journalFields` | `[` |
| modules/packages/deb-packages/audit.nix | `verbose` | `{` |
| modules/packages/deb-packages/audit.nix | `auditRules` | `[` |
| modules/packages/deb-packages/audit.nix | `"-a always,exit -F arch` | `b64 -S execve -F exe=${package}/bin/${name} -k deb_syscall_${name}"` |
| modules/packages/deb-packages/audit.nix | `journalFields` | `[` |
| modules/packages/deb-packages/audit.nix | `currentLogLevel` | `logLevels.${pkg.audit.logLevel}` |
| modules/packages/deb-packages/audit.nix | `LOG_DIR` | `"${logDir}"` |
| modules/packages/deb-packages/audit.nix | `LOG_FILE` | `"$LOG_DIR/${name}.log"` |
| modules/packages/deb-packages/audit.nix | `local level` | `"$1"` |
| modules/packages/deb-packages/audit.nix | `local message` | `"$2"` |
| modules/packages/deb-packages/audit.nix | `log_entry "INFO" "Environment: $(env | grep -E '^(PATH|LD_LIBRARY_PATH|HOME)` | `')"` |
| modules/packages/deb-packages/audit.nix | `if pkg.audit.logLevel` | `= "verbose" then` |
| modules/packages/deb-packages/audit.nix | `if pkg.audit.logLevel` | `= "verbose" then` |
| modules/packages/deb-packages/audit.nix | `START_TIME` | `$(date +%s)` |
| modules/packages/deb-packages/audit.nix | `TRACK_FILE` | `$(mktemp)` |
| modules/packages/deb-packages/audit.nix | `MEM` | `$(grep VmRSS /proc/$$/status | awk '{print $2}')` |
| modules/packages/deb-packages/audit.nix | `TRACKER_PID` | `$!` |
| modules/packages/deb-packages/audit.nix | `EXIT_CODE` | `0` |
| modules/packages/deb-packages/audit.nix | `${package}/bin/${name} "$@" || EXIT_CODE` | `$?` |
| modules/packages/deb-packages/audit.nix | `if pkg.audit.logLevel` | `= "verbose" then` |
| modules/packages/deb-packages/audit.nix | `END_TIME` | `$(date +%s)` |
| modules/packages/deb-packages/audit.nix | `DURATION` | `$((END_TIME - START_TIME))` |
| modules/packages/deb-packages/audit.nix | `PEAK_MEM` | `$(grep VmPeak /proc/$$/status | awk '{print $2}')` |
| modules/packages/deb-packages/audit.nix | `logRotationService` | `{` |
| modules/packages/deb-packages/audit.nix | `description` | `"Log rotation for ${name} deb package"` |
| modules/packages/deb-packages/audit.nix | `serviceConfig` | `{` |
| modules/packages/deb-packages/audit.nix | `Type` | `"oneshot"` |
| modules/packages/deb-packages/audit.nix | `LOG_FILE` | `"${logDir}/${name}.log"` |
| modules/packages/deb-packages/audit.nix | `FILE_SIZE` | `$(stat -f %z "$LOG_FILE" 2>/dev/null || stat -c %s "$LOG_FILE")` |
| modules/packages/deb-packages/audit.nix | `logRotationTimer` | `{` |
| modules/packages/deb-packages/audit.nix | `description` | `"Daily log rotation for ${name}"` |
| modules/packages/deb-packages/audit.nix | `wantedBy` | `[ "timers.target" ]` |
| modules/packages/deb-packages/audit.nix | `timerConfig` | `{` |
| modules/packages/deb-packages/audit.nix | `OnCalendar` | `"daily"` |
| modules/packages/deb-packages/audit.nix | `Persistent` | `true` |
| modules/packages/deb-packages/audit.nix | `monitoringService` | `mkIf (pkg.audit.logLevel == "verbose") {` |
| modules/packages/deb-packages/audit.nix | `description` | `"Resource monitoring for ${name}"` |
| modules/packages/deb-packages/audit.nix | `serviceConfig` | `{` |
| modules/packages/deb-packages/audit.nix | `Type` | `"simple"` |
| modules/packages/deb-packages/audit.nix | `MEM` | `$(grep VmRSS /proc/$pid/status | awk '{print $2}')` |
| modules/packages/deb-packages/audit.nix | `CPU` | `$(ps -p $pid -o %cpu= || echo "0")` |
| modules/packages/deb-packages/audit.nix | `Restart` | `"always"` |
| modules/packages/deb-packages/audit.nix | `RestartSec` | `"10s"` |
| modules/packages/deb-packages/audit.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/packages/deb-packages/audit.nix | `systemdServices` | `{` |
| modules/packages/deb-packages/audit.nix | `"deb-package-${name}-log-rotation"` | `logRotationService` |
| modules/packages/deb-packages/audit.nix | `systemdTimers` | `{` |
| modules/packages/deb-packages/audit.nix | `"deb-package-${name}-log-rotation"` | `logRotationTimer` |
| modules/packages/deb-packages/audit.nix | `auditRules` | `currentLogLevel.auditRules` |
| modules/packages/deb-packages/audit.nix | `logFiles` | `{` |
| modules/packages/deb-packages/audit.nix | `directory` | `logDir` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `RED` | `'\033[0;31m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `BLUE` | `'\033[0;34m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MAGENTA` | `'\033[0;35m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `NC` | `'\033[0m' # No Color` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `BOLD` | `'\033[1m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `ROCKET` | `"🚀"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CHECK` | `"✅"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `WARN` | `"⚠️ "` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `ERROR` | `"❌"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `GEAR` | `"⚙️ "` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CLEAN` | `"🧹"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `INFO` | `"ℹ️ "` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `FLAKE_PATH` | `"/etc/nixos"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `HOST` | `"kernelcore"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MAX_JOBS` | `"4"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CORES` | `"4"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `local color` | `$1` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `local icon` | `$2` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `local msg` | `$3` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `COMMAND` | `"switch"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MODE` | `"balanced"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `EXTRA_ARGS` | `()` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `COMMAND` | `$1` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `COMMAND` | `"check"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `COMMAND` | `"switch"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `EXTRA_ARGS+` | `("--show-trace")` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MODE` | `"safe"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MAX_JOBS` | `"1"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CORES` | `"4"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MODE` | `"balanced"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MAX_JOBS` | `"4"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CORES` | `"4"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MODE` | `"aggressive"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `MAX_JOBS` | `"6"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CORES` | `"2"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `START_TIME` | `$(date +%s)` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `EXIT_CODE` | `$?` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `END_TIME` | `$(date +%s)` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `DURATION` | `$((END_TIME - START_TIME))` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `BOLD` | `'\033[1m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CURRENT` | `$(readlink /nix/var/nix/profiles/system | grep -oP '\d+$')` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `BEFORE` | `$(du -sh /nix/store 2>/dev/null | cut -f1)` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `GENS` | `$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l)` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `if [[ ! $REPLY` | `~ ^[Yy]$ ]]; then` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `AFTER` | `$(du -sh /nix/store 2>/dev/null | cut -f1)` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `NEW_GENS` | `$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | wc -l)` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `environment.systemPackages` | `[` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `"rebuild"` | `"rebuild"` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `programs.bash.interactiveShellInit` | `''` |
| modules/shell/aliases/nix/rebuild-helpers.nix | `programs.zsh.interactiveShellInit` | `''` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `RED` | `'\033[0;31m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BLUE` | `'\033[0;34m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MAGENTA` | `'\033[0;35m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `WHITE` | `'\033[1;37m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `GRAY` | `'\033[0;90m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOLD` | `'\033[1m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DIM` | `'\033[2m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `UNDERLINE` | `'\033[4m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BLINK` | `'\033[5m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `REVERSE` | `'\033[7m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BG_RED` | `'\033[41m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BG_GREEN` | `'\033[42m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BG_YELLOW` | `'\033[43m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BG_BLUE` | `'\033[44m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BG_MAGENTA` | `'\033[45m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BG_CYAN` | `'\033[46m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `ORANGE` | `'\033[38;5;208m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PURPLE` | `'\033[38;5;141m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PINK` | `'\033[38;5;213m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `TEAL` | `'\033[38;5;51m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `LIME` | `'\033[38;5;190m'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `ROCKET` | `"🚀"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CHECK` | `"✅"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CROSS` | `"❌"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `WARN` | `"⚠️ "` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `INFO` | `"ℹ️ "` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `GEAR` | `"⚙️ "` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PACKAGE` | `"📦"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `FIRE` | `"🔥"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `STAR` | `"⭐"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CLOCK` | `"⏱️ "` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CHART` | `"📊"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CLEAN` | `"🧹"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `LOCK` | `"🔒"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `KEY` | `"🔑"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `SHIELD` | `"🛡️ "` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `WRENCH` | `"🔧"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MAGNIFY` | `"🔍"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `LIGHTNING` | `"⚡"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DISK` | `"💾"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MEMORY` | `"🧠"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CPU` | `"🔬"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `NETWORK` | `"🌐"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `ARROW_RIGHT` | `"→"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `ARROW_UP` | `"↑"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `ARROW_DOWN` | `"↓"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DOT` | `"•"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BULLET` | `"▸"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_H` | `"─"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_V` | `"│"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_TL` | `"╭"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_TR` | `"╮"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_BL` | `"╰"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_BR` | `"╯"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_VR` | `"├"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_VL` | `"┤"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_HU` | `"┴"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_HD` | `"┬"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BOX_VH` | `"┼"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PROG_FULL` | `"█"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PROG_EMPTY` | `"░"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PROG_LEFT` | `"▐"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `PROG_RIGHT` | `"▌"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `FLAKE_PATH` | `"/etc/nixos"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `HOST` | `"kernelcore"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DEFAULT_MAX_JOBS` | `"4"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DEFAULT_CORES` | `"4"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `LOG_DIR` | `"/var/log/nixos-rebuild"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `METRICS_DIR` | `"$HOME/.cache/nixos-rebuild"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `TIMESTAMP` | `$(date +%Y%m%d_%H%M%S)` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `LOG_FILE` | `"$LOG_DIR/rebuild_$TIMESTAMP.log"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `METRICS_FILE` | `"$METRICS_DIR/metrics_$TIMESTAMP.json"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local color` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local icon` | `$2` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local msg` | `$3` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local title` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local width` | `60` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local title` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local key` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local value` | `$2` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local color` | `''${3:-$WHITE}` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local current` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local total` | `$2` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local width` | `40` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local percentage` | `$((current * 100 / total))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local filled` | `$((width * current / total))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local empty` | `$((width - filled))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local pid` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local delay` | `0.1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local spinstr` | `'⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `spinstr` | `$temp''${spinstr%"$temp"}` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local seconds` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local minutes` | `$((seconds / 60))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local hours` | `$((minutes / 60))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `local days` | `$((hours / 24))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CPU_CORES` | `$(nproc)` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CPU_LOAD` | `$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MEM_TOTAL` | `$(free -b | awk '/^Mem:/ {print $2}')` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MEM_USED` | `$(free -b | awk '/^Mem:/ {print $3}')` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MEM_PERCENT` | `$((MEM_USED * 100 / MEM_TOTAL))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DISK_TOTAL` | `$(df -B1 /nix | awk 'NR==2 {print $2}')` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DISK_USED` | `$(df -B1 /nix | awk 'NR==2 {print $3}')` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DISK_PERCENT` | `$(df /nix | awk 'NR==2 {print $5}' | tr -d '%')` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `STORE_SIZE` | `$(du -sb /nix/store 2>/dev/null | cut -f1)` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `COMMAND` | `"switch"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MODE` | `"balanced"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MAX_JOBS` | `"$DEFAULT_MAX_JOBS"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CORES` | `"$DEFAULT_CORES"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `KEEP_GOING` | `"true"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `EXTRA_ARGS` | `()` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `COMMAND` | `$1` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `COMMAND` | `"check"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `COMMAND` | `"switch"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `EXTRA_ARGS+` | `("--show-trace")` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MODE` | `"safe"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MAX_JOBS` | `"1"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CORES` | `"4"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MODE` | `"balanced"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MAX_JOBS` | `"4"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CORES` | `"4"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MODE` | `"aggressive"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `MAX_JOBS` | `"6"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `CORES` | `"2"` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `EXIT_CODE` | `''${PIPESTATUS[0]}` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `START_TIME` | `$(date +%s)` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `BUILD_CMD` | `"sudo nixos-rebuild $COMMAND \` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `EXIT_CODE` | `''${PIPESTATUS[0]}` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `END_TIME` | `$(date +%s)` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `DURATION` | `$((END_TIME - START_TIME))` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `environment.systemPackages` | `[` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/nix/rebuild-advanced.nix | `"rebuild"` | `"rebuild"` |
| modules/development/claude-profiles.nix | `environment.systemPackages` | `[` |
| modules/development/claude-profiles.nix | `CYAN` | `'\033[0;36m'` |
| modules/development/claude-profiles.nix | `GREEN` | `'\033[0;32m'` |
| modules/development/claude-profiles.nix | `YELLOW` | `'\033[1;33m'` |
| modules/development/claude-profiles.nix | `RED` | `'\033[0;31m'` |
| modules/development/claude-profiles.nix | `BOLD` | `'\033[1m'` |
| modules/development/claude-profiles.nix | `NC` | `'\033[0m'` |
| modules/development/claude-profiles.nix | `CURRENT_PROFILE` | `"$PROFILE_DIR/current"` |
| modules/development/claude-profiles.nix | `GLOBAL_ENV` | `"$HOME/.claude-env"` |
| modules/development/claude-profiles.nix | `local current` | `""` |
| modules/development/claude-profiles.nix | `current` | `$(cat "$CURRENT_PROFILE")` |
| modules/development/claude-profiles.nix | `marker` | `"''${GREEN}✓''${NC}"` |
| modules/development/claude-profiles.nix | `status` | `"''${GREEN}(active)''${NC}"` |
| modules/development/claude-profiles.nix | `aws_region` | `''${aws_region:-us-east-1}` |
| modules/development/claude-profiles.nix | `programs.zsh.interactiveShellInit` | `''` |
| modules/development/claude-profiles.nix | `programs.bash.interactiveShellInit` | `''` |
| modules/development/claude-profiles.nix | `programs.zsh.shellAliases` | `{` |
| modules/development/claude-profiles.nix | `"claude-pro"` | `"claude-use-pro"` |
| modules/development/claude-profiles.nix | `programs.bash.shellAliases` | `{` |
| modules/development/claude-profiles.nix | `"claude-pro"` | `"claude-use-pro"` |
| modules/shell/aliases/ai/ollama.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/ai/ollama.nix | `"ollama-list"` | `"docker exec ollama-gpu ollama list 2>/dev/null || echo 'Ollama not running'"` |
| modules/shell/aliases/sync.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/sync.nix | `"sync-to"` | `"/etc/nixos/scripts/sync-to-desktop.sh"` |
| modules/shell/aliases/nixos-explorer.nix | `environment.systemPackages` | `[` |
| modules/shell/aliases/nixos-explorer.nix | `RED` | `'\033[0;31m'` |
| modules/shell/aliases/nixos-explorer.nix | `GREEN` | `'\033[0;32m'` |
| modules/shell/aliases/nixos-explorer.nix | `YELLOW` | `'\033[1;33m'` |
| modules/shell/aliases/nixos-explorer.nix | `BLUE` | `'\033[0;34m'` |
| modules/shell/aliases/nixos-explorer.nix | `CYAN` | `'\033[0;36m'` |
| modules/shell/aliases/nixos-explorer.nix | `BOLD` | `'\033[1m'` |
| modules/shell/aliases/nixos-explorer.nix | `NC` | `'\033[0m'` |
| modules/shell/aliases/nixos-explorer.nix | `COMMAND` | `"$1"` |
| modules/shell/aliases/nixos-explorer.nix | `programs.zsh.shellAliases` | `{` |
| modules/shell/aliases/nixos-explorer.nix | `"nxe"` | `"nixos-explore"` |
| modules/shell/aliases/nixos-explorer.nix | `programs.bash.shellAliases` | `{` |
| modules/shell/aliases/nixos-explorer.nix | `"nxe"` | `"nixos-explore"` |
| modules/shell/aliases/gcloud/gcloud.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/mcp.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/mcp.nix | `"mcp-sessions"` | `"bash /etc/nixos/scripts/mcp-helper.sh sessions"` |
| modules/shell/aliases/mcp.nix | `environment.interactiveShellInit` | `''` |
| modules/ml/services/llama-cpp-swap.nix | `default` | `8080` |
| modules/ml/services/llama-cpp-swap.nix | `example` | `11343` |
| modules/ml/services/llama-cpp-swap.nix | `description` | `''` |
| modules/ml/services/llama-cpp-swap.nix | `default` | `false` |
| modules/ml/services/llama-cpp-swap.nix | `description` | `''` |
| modules/ml/services/llama-cpp-swap.nix | `description` | `''` |
| modules/ml/services/llama-cpp-swap.nix | `example` | `lib.literalExpression ''` |
| modules/ml/services/llama-cpp-swap.nix | `llama-server` | `lib.getExe' llama-cpp "llama-server"` |
| modules/ml/services/llama-cpp-swap.nix | `healthCheckTimeout` | `60` |
| modules/ml/services/llama-cpp-swap.nix | `models` | `{` |
| modules/ml/services/llama-cpp-swap.nix | `"some-model"` | `{` |
| modules/ml/services/llama-cpp-swap.nix | `cmd` | `"$\{llama-server\} --port ''\${PORT} -m /var/lib/ml-models/llama-cpp/models/Qwen_Qwen2.5-Coder-7B-Instruct-GGUF_qwen2.5-coder-7b-i [... omitted end of long line]` |
| modules/ml/services/llama-cpp-swap.nix | `aliases` | `[` |
| modules/ml/services/llama-cpp-swap.nix | `proxy` | `"http://127.0.0.1:5555"` |
| modules/ml/services/llama-cpp-swap.nix | `cmd` | `"$\{llama-server\} --port 5555 -m /var/lib/ml-models/llama-cpp/models/unsloth_Qwen2.5-Coder-14B-Instruct-GGUF_Qwen2.5-Coder-14B-In [... omitted end of long line]` |
| modules/ml/services/llama-cpp-swap.nix | `concurrencyLimit` | `4` |
| modules/ml/services/llama-cpp-swap.nix | `systemd.services.llama-swap` | `{` |
| modules/ml/services/llama-cpp-swap.nix | `description` | `"Model swapping for LLaMA C++ Server (or any local OpenAPI compatible server)"` |
| modules/ml/services/llama-cpp-swap.nix | `after` | `[ "network.target" ]` |
| modules/ml/services/llama-cpp-swap.nix | `wantedBy` | `[ "multi-user.target" ]` |
| modules/ml/services/llama-cpp-swap.nix | `serviceConfig` | `{` |
| modules/ml/services/llama-cpp-swap.nix | `Type` | `"exec"` |
| modules/ml/services/llama-cpp-swap.nix | `Restart` | `"on-failure"` |
| modules/ml/services/llama-cpp-swap.nix | `RestartSec` | `3` |
| modules/ml/services/llama-cpp-swap.nix | `PrivateDevices` | `false` |
| modules/ml/services/llama-cpp-swap.nix | `DynamicUser` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `CapabilityBoundingSet` | `""` |
| modules/ml/services/llama-cpp-swap.nix | `RestrictAddressFamilies` | `[` |
| modules/ml/services/llama-cpp-swap.nix | `NoNewPrivileges` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `PrivateMounts` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `PrivateTmp` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `PrivateUsers` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectClock` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectControlGroups` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectHome` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectKernelLogs` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectKernelModules` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectKernelTunables` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectSystem` | `"strict"` |
| modules/ml/services/llama-cpp-swap.nix | `MemoryDenyWriteExecute` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `LockPersonality` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `RemoveIPC` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `RestrictNamespaces` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `RestrictRealtime` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `RestrictSUIDSGID` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `SystemCallArchitectures` | `"native"` |
| modules/ml/services/llama-cpp-swap.nix | `SystemCallFilter` | `[` |
| modules/ml/services/llama-cpp-swap.nix | `SystemCallErrorNumber` | `"EPERM"` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectProc` | `"invisible"` |
| modules/ml/services/llama-cpp-swap.nix | `ProtectHostname` | `true` |
| modules/ml/services/llama-cpp-swap.nix | `ProcSubset` | `"pid"` |
| modules/shell/aliases/desktop/hyprland.nix | `environment.shellAliases` | `{` |
| modules/shell/aliases/desktop/hyprland.nix | `"reload"` | `"source ~/.bashrc"` |
| modules/shell/aliases/security/secrets.nix | `environment.shellAliases` | `{` |

Note: This report is generated by a heuristic scan of source files and may not reflect the final evaluated configuration due to Nix's lazy evaluation, merging, and overriding mechanisms. It primarily captures literal assignments.
For / values, this indicates whether an 'enable' option appears to be set to that value.
