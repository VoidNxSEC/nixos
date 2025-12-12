package cli

import (
	"fmt"
	"time"

	"github.com/spf13/cobra"
	"vmctl/internal/qemu"
	"vmctl/internal/vm"
)

var (
	forceStop bool
	waitStop  bool
)

var stopCmd = &cobra.Command{
	Use:   "stop <vm-name>",
	Short: "Stop a running VM",
	Long: `Stop a running virtual machine gracefully.

By default sends ACPI shutdown signal. Use --force for immediate termination.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return runStop(args[0])
	},
}

func init() {
	stopCmd.Flags().BoolVarP(&forceStop, "force", "f", false, "force kill VM immediately")
	stopCmd.Flags().BoolVarP(&waitStop, "wait", "w", false, "wait for VM to fully stop")
}

func runStop(vmName string) error {
	if !vm.IsRunning(vmName) {
		return fmt.Errorf("VM '%s' is not running", vmName)
	}

	if verbose {
		fmt.Printf("[vmctl] Stopping VM: %s\n", vmName)
	}

	if dryRun {
		if forceStop {
			fmt.Printf("[dry-run] kill -9 <pid>\n")
		} else {
			fmt.Printf("[dry-run] kill -TERM <pid>\n")
		}
		return nil
	}

	var err error
	if forceStop {
		err = qemu.ForceStop(vmName)
	} else {
		err = qemu.Stop(vmName)
	}

	if err != nil {
		return fmt.Errorf("stopping VM: %w", err)
	}

	if waitStop {
		fmt.Printf("Waiting for VM '%s' to stop...\n", vmName)
		for i := 0; i < 30; i++ {
			if !vm.IsRunning(vmName) {
				fmt.Printf("✓ VM '%s' stopped\n", vmName)
				return nil
			}
			time.Sleep(1 * time.Second)
		}
		return fmt.Errorf("timeout waiting for VM to stop")
	}

	if forceStop {
		fmt.Printf("✓ VM '%s' killed\n", vmName)
	} else {
		fmt.Printf("✓ Shutdown signal sent to '%s'\n", vmName)
	}

	return nil
}
