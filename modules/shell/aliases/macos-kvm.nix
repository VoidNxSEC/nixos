{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

# ============================================================
# macOS KVM Shell Aliases
# ============================================================
# Purpose: Quick commands for macOS VM management
# Enabled by: kernelcore.macos-kvm.enable
# ============================================================

let
  cfg = config.kernelcore.virtualization.macos-kvm;
in
{
  config = mkIf cfg.enable {
    environment.shellAliases = {
      # === VM Control ===
      mvm = "macos-vm"; # Launch macOS VM
      mfetch = "macos-fetch"; # Download macOS installer
      mref = "macos-reference"; # Launch reference VM (ngi-nix)

      # === SSH Access ===
      mssh = "macos-ssh"; # SSH into macOS VM
      mscp = "macos-scp"; # SCP to/from macOS VM
      mwait = "macos-wait"; # Wait for VM boot
      mwait5 = "macos-wait 300"; # Wait 5 minutes
      mwait10 = "macos-wait 600"; # Wait 10 minutes

      # === Snapshots ===
      msnap = "macos-snapshot"; # Snapshot management
      msnap-list = "macos-snapshot list"; # List snapshots
      msnap-create = "macos-snapshot create"; # Create snapshot
      msnap-restore = "macos-snapshot apply"; # Restore snapshot
      msnap-clean = "macos-snapshot create clean && macos-snapshot delete old";

      # === Benchmarks ===
      mbench = "macos-benchmark"; # Run performance benchmark

      # === Quick Diagnostics ===
      minfo = "mssh 'sw_vers; sysctl -n machdep.cpu.brand_string; sysctl hw.memsize'";
      mcpu = "mssh 'sysctl -n machdep.cpu.brand_string'";
      mmem = "mssh 'sysctl hw.memsize | awk \"{print \\$2/1024/1024/1024 \\\" GB\\\"}\"'";
      mdisk = "mssh 'df -h /'";

      # === Development Shortcuts ===
      mxcode = "mssh 'xcode-select --version'"; # Check Xcode CLI tools
      mxcode-install = "mssh 'xcode-select --install'";
      mbrew = "mssh 'brew --version 2>/dev/null || echo \"Homebrew not installed\"'";
      mbrew-install = "mssh '/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"'";

      # === iOS Development ===
      msim = "mssh 'xcrun simctl list devices available'";
      msim-boot = "mssh 'xcrun simctl boot'"; # + device ID
      msim-shutdown = "mssh 'xcrun simctl shutdown all'";

      # === QMP Control (advanced) ===
      mqmp = "socat - UNIX-CONNECT:/tmp/macos-qmp.sock";
      mmonitor = "socat - UNIX-CONNECT:/tmp/macos-monitor.sock";
      mpause = "echo '{\"execute\":\"stop\"}' | socat - UNIX-CONNECT:/tmp/macos-qmp.sock";
      mresume = "echo '{\"execute\":\"cont\"}' | socat - UNIX-CONNECT:/tmp/macos-qmp.sock";
      mstatus = "echo '{\"execute\":\"query-status\"}' | socat - UNIX-CONNECT:/tmp/macos-qmp.sock";

      # === File Transfers ===
      mpush = "macos-scp"; # Push files: mpush local remote
      mpull = "macos-scp admin@localhost:"; # Pull files: mpull remote local

      # === Logs & Debugging ===
      mlog = "journalctl -f | grep -i qemu"; # QEMU logs
      mps = "ps aux | grep qemu-system"; # QEMU processes
      mkill = "pkill -9 qemu-system-x86_64"; # Force kill VM

      # === Network ===
      mport = "echo 'SSH: ${toString cfg.sshPort}, VNC: ${toString cfg.vncPort}'";
      mvnc = "echo 'Connect via: vnc://localhost:${toString cfg.vncPort}'";

      # === Workspace ===
      mcd = "cd ${cfg.workDir}"; # Go to macOS KVM dir
      mls = "ls -la ${cfg.workDir}"; # List macOS KVM files
      msize = "du -sh ${cfg.workDir}/*"; # Disk usage

      # === CI/CD Helpers ===
      mci-boot = "macos-vm & macos-wait 300"; # Boot VM and wait
      mci-snapshot = "msnap-create ci-baseline && echo 'CI baseline created'";
      mci-reset = "macos-snapshot apply ci-baseline";
      mci-test = "mssh 'xcodebuild test -scheme MyApp -destination \"platform=iOS Simulator,name=iPhone 15\"'";
    };
  };
}
