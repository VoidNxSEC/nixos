package cli

import (
	"fmt"
	"os"
	"text/tabwriter"

	"vmctl/internal/vm"

	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all registered VMs",
	Long:  `List all VMs defined in the configuration file with their current status.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		return runList()
	},
}

func runList() error {
	cfg, err := vm.LoadConfig(cfgFile)
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	if len(cfg.VMs) == 0 {
		fmt.Println("No VMs configured.")
		fmt.Println("\nAdd VMs to your config file:")
		fmt.Printf("  %s\n", vm.DefaultConfigPath())
		return nil
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "NAME\tSTATUS\tMEMORY\tCPUs\tIMAGE")
	fmt.Fprintln(w, "----\t------\t------\t----\t-----")

	for name, vmCfg := range cfg.VMs {
		if !vmCfg.Enabled {
			continue
		}

		status := "stopped"
		statusIcon := "🔴"

		// Check if VM is running
		if vm.IsRunning(name) {
			status = "running"
			statusIcon = "🟢"
		}

		imageName := vmCfg.Image
		if len(imageName) > 40 {
			imageName = "..." + imageName[len(imageName)-37:]
		}

		fmt.Fprintf(w, "%s %s\t%s\t%s\t%d\t%s\n",
			statusIcon, name, status, vmCfg.Memory, vmCfg.CPUs, imageName)
	}
	w.Flush()

	return nil
}
