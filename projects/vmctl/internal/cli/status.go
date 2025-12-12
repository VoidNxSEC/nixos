package cli

import (
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/spf13/cobra"
	"vmctl/internal/vm"
)

var statusCmd = &cobra.Command{
	Use:   "status [vm-name]",
	Short: "Show VM status",
	Long:  `Show status of all VMs or a specific VM.`,
	Args:  cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 1 {
			return runStatusSingle(args[0])
		}
		return runStatusAll()
	},
}

func runStatusAll() error {
	cfg, err := vm.LoadConfig(cfgFile)
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	if len(cfg.VMs) == 0 {
		fmt.Println("No VMs configured.")
		return nil
	}

	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Println(" VM Status")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "NAME\tSTATUS\tPID\tMEMORY\tCPUs")
	fmt.Fprintln(w, "----\t------\t---\t------\t----")

	for name, vmCfg := range cfg.VMs {
		status := "stopped"
		statusIcon := "🔴"
		pidStr := "-"

		if vm.IsRunning(name) {
			status = "running"
			statusIcon = "🟢"
			if pid, err := vm.GetPID(name); err == nil {
				pidStr = fmt.Sprintf("%d", pid)
			}
		}

		if !vmCfg.Enabled {
			status = "disabled"
			statusIcon = "⚫"
		}

		fmt.Fprintf(w, "%s %s\t%s\t%s\t%s\t%d\n",
			statusIcon, name, status, pidStr, vmCfg.Memory, vmCfg.CPUs)
	}
	w.Flush()

	return nil
}

func runStatusSingle(vmName string) error {
	cfg, err := vm.LoadConfig(cfgFile)
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	vmCfg, exists := cfg.VMs[vmName]
	if !exists {
		return fmt.Errorf("VM '%s' not found in config", vmName)
	}

	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	fmt.Printf(" VM: %s\n", vmName)
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	status := "stopped"
	if vm.IsRunning(vmName) {
		status = "running"
		if pid, err := vm.GetPID(vmName); err == nil {
			fmt.Printf("  Status:  🟢 %s (PID: %d)\n", status, pid)
		}
	} else {
		fmt.Printf("  Status:  🔴 %s\n", status)
	}

	fmt.Printf("  Enabled: %v\n", vmCfg.Enabled)
	fmt.Printf("  Image:   %s\n", vmCfg.Image)
	fmt.Printf("  Memory:  %s\n", vmCfg.Memory)
	fmt.Printf("  CPUs:    %d\n", vmCfg.CPUs)
	fmt.Printf("  Network: %s\n", vmCfg.Network)
	fmt.Printf("  Display: %s\n", vmCfg.Display)

	if len(vmCfg.Disks) > 0 {
		fmt.Println("  Disks:")
		for _, d := range vmCfg.Disks {
			fmt.Printf("    - %s (%s)\n", d.Path, d.Format)
		}
	}

	if len(vmCfg.Shares) > 0 {
		fmt.Println("  Shares:")
		for _, s := range vmCfg.Shares {
			fmt.Printf("    - %s → %s (%s)\n", s.HostPath, s.GuestTag, s.Driver)
		}
	}

	return nil
}
