{
  config,
  lib,
  pkgs,
  ...
}:

{
  # =================================================================
  # TICKET #IO-992: IO OPTIMIZATION & LATENCY REDUCTION
  # Based on RCA: Suricata Restart Loop + High Swap Latency
  # =================================================================

  # 1. ZRAM SWAP (CRUCIAL - Fixes Swap Thrashing)
  # Evidence: vmstat showed high si/so (swap in/out).
  # Solution: Compress swap in RAM (zstd) instead of hitting slow disk.
  zramSwap = lib.mkForce {
    enable = true;
    priority = 1000; # Max priority to ensure ZRAM is used first
    memoryPercent = 50; # Use up to 50% of RAM
    algorithm = "zstd";
  };

  # 2. IO SCHEDULER & BLOCK LAYER
  services.udev.extraRules = ''
    # NVMe: 'none' is usually best, but 'kyber' can help latency under load
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
    # SATA SSD/HDD: 'bfq' is mandatory for desktop responsiveness
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  # 3. KERNEL VIRTUAL MEMORY TUNING (Reduce IO Spikes)
  boot.kernel.sysctl = lib.mkForce {
    # Swappiness: Reduce preference for swapping.
    # Default 60 -> 10. Only swap when RAM is actually full.
    "vm.swappiness" = 10;

    # Dirty Pages: Write to disk sooner but in smaller chunks.
    # Prevents "system freeze" when flushing huge buffers.
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;

    # Improve inode cache retention (makes `ls` and file searches faster)
    "vm.vfs_cache_pressure" = 50;
  };

  # 4. SYSTEMD JOURNAL TUNING (Mitigate Log Spam Impact)
  # Evidence: Suricata was spamming logs in a restart loop.
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    # Rate limit: max 1000 messages in 30s per service
    RateLimitIntervalSec=30s
    RateLimitBurst=1000
    # Compress aggressively to save IO bandwidth
    Compress=yes
    Storage=persistent
  '';

  # 5. SYSTEMD GLOBAL LIMITS (Prevent Service Runaways)
  #systemd.extraConfig = ''
  # Stop services that fail too quickly (5 times in 10s)
  #DefaultStartLimitIntervalSec=10s
  #DefaultStartLimitBurst=5
  #'';
}
