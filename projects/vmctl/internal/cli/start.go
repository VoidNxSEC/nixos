package cli

import (
	"fmt"

	"github.com/spf13/cobra"
	"vmctl/internal/qemu"
	"vmctl/internal/vm"
)

var (
	startDetached bool
	startDisplay  string
)

var startCmd = &cobra.Command{
	Use:   "start <vm-name>",
	Short: "Start a VM",
	Long: `Start a virtual machine by name. The QEMU window will open automatically.

Examples:
  vmctl start ubuntu          # Start with default display (gtk)
  vmctl start ubuntu -d       # Start detached (no console)
  vmctl start ubuntu --display sdl  # Use SDL display`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return runStart(args[0])
	},
}

func init() {
	startCmd.Flags().BoolVarP(&startDetached, "detached", "d", false, "run VM in background (no console)")
	startCmd.Flags().StringVar(&startDisplay, "display", "", "display type (gtk, sdl, spice, vnc, none)")
}

func runStart(name string) error {
	cfg, err := vm.LoadConfig(cfgFile)
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	vmCfg, exists := cfg.VMs[name]
	if !exists {
		return fmt.Errorf("VM '%s' not found in configuration", name)
	}

	if !vmCfg.Enabled {
		return fmt.Errorf("VM '%s' is disabled", name)
	}

	// Check if already running
	if vm.IsRunning(name) {
		return fmt.Errorf("VM '%s' is already running", name)
	}

	// Override display if specified
	if startDisplay != "" {
		vmCfg.Display = startDisplay
	}

	// Build QEMU launch options
	opts := qemu.LaunchOptions{
		VMName:   name,
		Config:   &vmCfg,
		Detached: startDetached,
		DryRun:   dryRun,
		Verbose:  verbose,
	}

	if verbose {
		fmt.Printf("[vmctl] Starting VM: %s\n", name)
		fmt.Printf("[vmctl] Image: %s\n", vmCfg.Image)
		fmt.Printf("[vmctl] Memory: %s, CPUs: %d\n", vmCfg.Memory, vmCfg.CPUs)
	}

	if dryRun {
		args := qemu.BuildArgs(&vmCfg, name)
		fmt.Println("[dry-run] Would execute:")
		fmt.Printf("  qemu-system-x86_64 %v\n", args)
		return nil
	}

	// Launch the VM
	pid, err := qemu.Launch(opts)
	if err != nil {
		return fmt.Errorf("launching VM: %w", err)
	}

	fmt.Printf("✓ VM '%s' started (PID: %d)\n", name, pid)
	
	if startDetached {
		fmt.Println("  Running in background. Use 'vmctl stop " + name + "' to stop.")
	}

	return nil
}
