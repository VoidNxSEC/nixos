{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# EMERGENCY RESPONSE ALIASES
# ============================================================
# Aliases para situações críticas do sistema
# Framework: /etc/nixos/scripts/nix-emergency.sh
# Documentação: /etc/nixos/docs/NIX-EMERGENCY-PROCEDURES.md

{
  environment.shellAliases = {
    # ========================================
    # EMERGENCY FRAMEWORK (Main Commands)
    # ========================================

    # Status do sistema
    "emergency-status" = "bash /etc/nixos/scripts/nix-emergency.sh status";
    "emstatus" = "bash /etc/nixos/scripts/nix-emergency.sh status";
    "ems" = "bash /etc/nixos/scripts/nix-emergency.sh status";

    # Abortar builds NIX
    "emergency-abort" = "bash /etc/nixos/scripts/nix-emergency.sh abort";
    "emabort" = "bash /etc/nixos/scripts/nix-emergency.sh abort";
    "ema" = "bash /etc/nixos/scripts/nix-emergency.sh abort";

    # Nuke (último recurso - mata processos pesados)
    "emergency-nuke" = "bash /etc/nixos/scripts/nix-emergency.sh nuke";
    "emnuke" = "bash /etc/nixos/scripts/nix-emergency.sh nuke";
    "emn" = "bash /etc/nixos/scripts/nix-emergency.sh nuke";

    # Cooldown (reduz temperatura CPU)
    "emergency-cooldown" = "bash /etc/nixos/scripts/nix-emergency.sh cooldown";
    "emcool" = "bash /etc/nixos/scripts/nix-emergency.sh cooldown";
    "emc" = "bash /etc/nixos/scripts/nix-emergency.sh cooldown";

    # Swap emergency
    "emergency-swap" = "bash /etc/nixos/scripts/nix-emergency.sh swap-emergency";
    "emswap" = "bash /etc/nixos/scripts/nix-emergency.sh swap-emergency";

    # Monitor contínuo
    "emergency-monitor" = "bash /etc/nixos/scripts/nix-emergency.sh monitor";
    "emmon" = "bash /etc/nixos/scripts/nix-emergency.sh monitor";

    # Help
    "emergency-help" = "bash /etc/nixos/scripts/nix-emergency.sh help";
    "emhelp" = "bash /etc/nixos/scripts/nix-emergency.sh help";

    # ========================================
    # QUICK ACTIONS (Ações Diretas)
    # ========================================

    # Matar builds NIX imediatamente
    "kill-nix-builds" =
      "pkill -9 -f 'nix flake check' 2>/dev/null; sudo killall -9 nixbld 2>/dev/null; echo 'Builds abortados'";
    "knix" =
      "pkill -9 -f 'nix flake check' 2>/dev/null; sudo killall -9 nixbld 2>/dev/null; echo 'Builds abortados'";

    # Matar compiladores
    "kill-compilers" =
      "sudo killall -9 cc1plus cudafe cicc ninja cmake g++ gcc clang 2>/dev/null; echo 'Compiladores terminados'";
    "kcc" =
      "sudo killall -9 cc1plus cudafe cicc ninja cmake g++ gcc clang 2>/dev/null; echo 'Compiladores terminados'";

    # Limpar caches
    "drop-caches" =
      "sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null && echo 'Caches limpos'";

    # Renovar swap
    "renew-swap" = "sudo swapoff -a && sudo swapon -a && echo 'Swap renovado'";

    # ========================================
    # MONITORING (Monitoramento)
    # ========================================

    # Status rápido
    "sys-status" =
      "echo '=== CPU ===' && uptime && echo '=== RAM ===' && free -h && echo '=== SWAP ===' && swapon --show";
    "ss" =
      "echo '=== CPU ===' && uptime && echo '=== RAM ===' && free -h && echo '=== SWAP ===' && swapon --show";

    # Watch system resources
    "watch-sys" =
      "watch -n 2 'echo === CPU === && uptime && echo === RAM === && free -h && echo === SWAP === && swapon --show'";

    # Top processos por CPU
    "top-cpu" = "top -b -n 1 | head -20";

    # Top processos por memória (precisa instalar procps)
    "top-mem" = "ps aux | head -20";

    # Temperatura CPU
    "cpu-temp" =
      "sensors 2>/dev/null | grep -i 'Package id 0' || cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000 \"°C\"}'";

    # ========================================
    # NIX-SPECIFIC (Específico Nix)
    # ========================================

    # Verificar builds ativos
    "nix-builds" = "pgrep -af 'nix.*build\\|nix.*flake\\|nixbld' || echo 'Nenhum build ativo'";
    "nb" = "pgrep -af 'nix.*build\\|nix.*flake\\|nixbld' || echo 'Nenhum build ativo'";

    # Listar workers nixbld
    "nix-workers" = "ps aux | grep nixbld | grep -v grep || echo 'Nenhum worker ativo'";
    "nw" = "ps aux | grep nixbld | grep -v grep || echo 'Nenhum worker ativo'";

    # ========================================
    # PREVENTIVE (Preventivo)
    # ========================================

    # Safe nix commands (limited resources)
    "safe-check" = "nix flake check --no-build";
    "safe-build" = "nix build --max-jobs 2 --cores 4";
    "safe-rebuild" = "sudo nixos-rebuild switch --max-jobs 2 --cores 4 --fast";

    # ========================================
    # EMERGENCY COMBOS (Combinações)
    # ========================================

    # Abort + Status
    "emergency-abort-status" =
      "bash /etc/nixos/scripts/nix-emergency.sh abort && sleep 5 && bash /etc/nixos/scripts/nix-emergency.sh status";
    "emas" =
      "bash /etc/nixos/scripts/nix-emergency.sh abort && sleep 5 && bash /etc/nixos/scripts/nix-emergency.sh status";

    # Full recovery (abort + drop-caches + renew-swap)
    "emergency-recover" =
      "bash /etc/nixos/scripts/nix-emergency.sh abort && sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null && sleep 5 && bash /etc/nixos/scripts/nix-emergency.sh status";
    "emrecover" =
      "bash /etc/nixos/scripts/nix-emergency.sh abort && sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null && sleep 5 && bash /etc/nixos/scripts/nix-emergency.sh status";

    # ========================================
    # DOCUMENTATION
    # ========================================

    # Mostrar guia de emergência
    "emergency-guide" = "cat /etc/nixos/docs/NIX-EMERGENCY-PROCEDURES.md";
    "emguide" = "cat /etc/nixos/docs/NIX-EMERGENCY-PROCEDURES.md";
  };

  # ========================================
  # SHELL INIT (Mensagem de boas-vindas)
  # ========================================

  environment.interactiveShellInit = ''
    # Emergency framework disponível
    # Digite: emhelp ou emergency-help
  '';
}
