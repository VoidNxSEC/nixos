package cli

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	// Global flags
	cfgFile string
	verbose bool
	dryRun  bool
	showGUI bool

	// Version info
	version = "0.1.0"
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "vmctl",
	Short: "Lightweight VM manager for QEMU",
	Long: `vmctl is a lightweight virtual machine manager that directly interfaces
with QEMU for simple and efficient VM management.

Features:
  • Direct QEMU execution (no libvirt overhead)
  • CLI-first design with optional GTK4 GUI
  • TOML-based configuration
  • VirtioFS support for host-guest file sharing
  • Snapshot management via qemu-img`,
	Version: version,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		if verbose {
			fmt.Fprintf(os.Stderr, "[vmctl] Verbose mode enabled\n")
		}
		if dryRun {
			fmt.Fprintf(os.Stderr, "[vmctl] Dry-run mode - no actions will be taken\n")
		}
	},
	Run: func(cmd *cobra.Command, args []string) {
		if showGUI {
			// Launch GUI mode
			if err := runGUI(); err != nil {
				fmt.Fprintf(os.Stderr, "Error launching GUI: %v\n", err)
				os.Exit(1)
			}
			return
		}
		// No subcommand provided, show help
		cmd.Help()
	},
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().StringVarP(&cfgFile, "config", "c", "", "config file (default: ~/.config/vmctl/config.toml)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "enable verbose output")
	rootCmd.PersistentFlags().BoolVar(&dryRun, "dry-run", false, "print commands without executing")

	// GUI flag
	rootCmd.Flags().BoolVar(&showGUI, "gui", false, "launch GTK4 GUI instead of CLI")

	// Add subcommands
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(stopCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(createDiskCmd)
}

// runGUI launches the GTK4 GUI - placeholder for now
func runGUI() error {
	fmt.Println("🖥️  Launching vmctl GUI...")
	fmt.Println("   (GTK4 GUI not yet implemented)")
	fmt.Println("   Run 'vmctl list' for CLI mode")
	return nil
}
