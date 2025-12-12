package vm

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
)

// Config represents the root configuration
type Config struct {
	VMs map[string]VMConfig `toml:"vm"`
}

// VMConfig represents a single VM configuration
type VMConfig struct {
	Enabled bool   `toml:"enabled"`
	Image   string `toml:"image"`
	Memory  string `toml:"memory"`
	CPUs    int    `toml:"cpus"`
	Network string `toml:"network"`
	Display string `toml:"display"`
	Spice   bool   `toml:"spice"`
	
	// Optional
	MacAddress string `toml:"mac_address,omitempty"`
	
	// Additional disks
	Disks []DiskConfig `toml:"disks,omitempty"`
	
	// Shared directories (virtiofs)
	Shares []ShareConfig `toml:"shares,omitempty"`
	
	// Extra QEMU arguments
	ExtraArgs []string `toml:"extra_args,omitempty"`
}

// DiskConfig represents an additional disk
type DiskConfig struct {
	Path   string `toml:"path"`
	Size   string `toml:"size,omitempty"`
	Format string `toml:"format"`
}

// ShareConfig represents a shared directory
type ShareConfig struct {
	HostPath string `toml:"host_path"`
	GuestTag string `toml:"guest_tag"`
	Driver   string `toml:"driver"`
	ReadOnly bool   `toml:"readonly"`
}

// DefaultConfigPath returns the default config file path
func DefaultConfigPath() string {
	// Check XDG config dir first
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return filepath.Join(xdg, "vmctl", "config.toml")
	}
	
	// Fall back to ~/.config
	home, err := os.UserHomeDir()
	if err != nil {
		return "/etc/vmctl/config.toml"
	}
	return filepath.Join(home, ".config", "vmctl", "config.toml")
}

// LoadConfig loads configuration from file
func LoadConfig(cfgFile string) (*Config, error) {
	if cfgFile == "" {
		cfgFile = DefaultConfigPath()
	}

	// Check system config if user config doesn't exist
	if _, err := os.Stat(cfgFile); os.IsNotExist(err) {
		systemCfg := "/etc/vmctl/config.toml"
		if _, err := os.Stat(systemCfg); err == nil {
			cfgFile = systemCfg
		} else {
			// Return empty config
			return &Config{VMs: make(map[string]VMConfig)}, nil
		}
	}

	var cfg Config
	if _, err := toml.DecodeFile(cfgFile, &cfg); err != nil {
		return nil, fmt.Errorf("parsing config %s: %w", cfgFile, err)
	}

	// Apply defaults
	for name, vm := range cfg.VMs {
		if vm.Memory == "" {
			vm.Memory = "2G"
		}
		if vm.CPUs == 0 {
			vm.CPUs = 2
		}
		if vm.Display == "" {
			vm.Display = "gtk"
		}
		if vm.Network == "" {
			vm.Network = "user"
		}
		cfg.VMs[name] = vm
	}

	return &cfg, nil
}

// PidFile returns the path to a VM's PID file
func PidFile(vmName string) string {
	runDir := os.Getenv("XDG_RUNTIME_DIR")
	if runDir == "" {
		runDir = "/tmp"
	}
	return filepath.Join(runDir, "vmctl", vmName+".pid")
}

// IsRunning checks if a VM is currently running
func IsRunning(vmName string) bool {
	pidFile := PidFile(vmName)
	data, err := os.ReadFile(pidFile)
	if err != nil {
		return false
	}

	pid := strings.TrimSpace(string(data))
	
	// Check if process exists
	cmd := exec.Command("kill", "-0", pid)
	return cmd.Run() == nil
}

// GetPID returns the PID of a running VM
func GetPID(vmName string) (int, error) {
	pidFile := PidFile(vmName)
	data, err := os.ReadFile(pidFile)
	if err != nil {
		return 0, fmt.Errorf("VM '%s' is not running", vmName)
	}

	var pid int
	if _, err := fmt.Sscanf(strings.TrimSpace(string(data)), "%d", &pid); err != nil {
		return 0, fmt.Errorf("invalid PID file: %w", err)
	}

	return pid, nil
}
