# NixOS Docker Stack Orchestrator Configuration
# =============================================================================
# Para usar, adicione no seu configuration.nix:
#
# environment.shellAliases = import /home/kernelcore/Documents/nx/docker/nixos-aliases.nix;
#
# Ou para home-manager (~/.config/home-manager/home.nix):
#
# home.shellAliases = import /home/kernelcore/Documents/nx/docker/nixos-aliases.nix;
# =============================================================================

let
  dockerOrchPath = "/home/kernelcore/Documents/nx/docker/main.py";
  orch = "python3 ${dockerOrchPath}";
in
{
  # ==========================================================================
  # ORQUESTRADOR PRINCIPAL
  # ==========================================================================
  dstack = orch;
  dstack-list = "${orch} list";

  # ==========================================================================
  # MULTIMODAL AI STACK
  # ==========================================================================
  ai-up = "${orch} up multimodal";
  ai-down = "${orch} down multimodal";
  ai-status = "${orch} status multimodal";
  ai-logs = "${orch} logs multimodal -f";
  ai-health = "${orch} health multimodal";
  ai-restart = "${orch} restart multimodal";

  # ==========================================================================
  # GPU + DATABASE STACK
  # ==========================================================================
  gpu-up = "${orch} up gpu";
  gpu-down = "${orch} down gpu";
  gpu-status = "${orch} status gpu";
  gpu-logs = "${orch} logs gpu -f";
  gpu-health = "${orch} health gpu";
  gpu-restart = "${orch} restart gpu";

  # ==========================================================================
  # TODOS OS STACKS
  # ==========================================================================
  all-up = "${orch} up-all";
  all-down = "${orch} down-all";
  all-status = "${orch} status";
  all-health = "${orch} health";

  # ==========================================================================
  # SERVIÇOS ESPECÍFICOS - LOGS
  # ==========================================================================
  api-logs = "${orch} logs gpu api -f";
  db-logs = "${orch} logs gpu db -f";
  jupyter-logs-gpu = "${orch} logs gpu jupyter -f";
  jupyter-logs-ai = "${orch} logs multimodal jupyter -f";
  nginx-logs-gpu = "${orch} logs gpu nginx -f";
  nginx-logs-ai = "${orch} logs multimodal nginx -f";
  ollama-logs = "${orch} logs multimodal ollama -f";
  vllm-logs = "${orch} logs multimodal vllm -f";
  whisper-logs = "${orch} logs multimodal whisper-api -f";

  # ==========================================================================
  # SERVIÇOS ESPECÍFICOS - RESTART
  # ==========================================================================
  api-restart = "${orch} restart gpu api";
  db-restart = "${orch} restart gpu db";

  # ==========================================================================
  # OLLAMA
  # ==========================================================================
  ollama-list = "docker exec ollama-gpu ollama list 2>/dev/null || echo 'Ollama não está rodando'";

  # ==========================================================================
  # DOCKER UTILITIES
  # ==========================================================================
  dps = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | head -20";
  dlogs-help = "echo 'Use: ${orch} logs <stack> <service> -f'";
  drestart-help = "echo 'Use: ${orch} restart <stack> <service>'";
}
