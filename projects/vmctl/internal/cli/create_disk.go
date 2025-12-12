package cli

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var (
	diskFormat string
)

var createDiskCmd = &cobra.Command{
	Use:   "create-disk <name> <size>",
	Short: "Create a new disk image",
	Long: `Create a new QEMU disk image.

Examples:
  vmctl create-disk myvm 50G
  vmctl create-disk data 100G --format raw`,
	Args: cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		return runCreateDisk(args[0], args[1])
	},
}

func init() {
	createDiskCmd.Flags().StringVar(&diskFormat, "format", "qcow2", "disk format: qcow2 (default), raw")
}

func runCreateDisk(name, size string) error {
	// Determine output path
	var outPath string
	
	// If name contains path separator, use as-is
	if filepath.IsAbs(name) || filepath.Dir(name) != "." {
		outPath = name
	} else {
		// Default to common VM images directory
		vmDir := os.Getenv("VMCTL_VM_DIR")
		if vmDir == "" {
			vmDir = "/var/lib/vm-images"
		}
		
		// Add extension based on format
		ext := ".qcow2"
		if diskFormat == "raw" {
			ext = ".raw"
		}
		outPath = filepath.Join(vmDir, name+ext)
	}

	// Ensure parent directory exists
	dir := filepath.Dir(outPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("creating directory %s: %w", dir, err)
	}

	// Check if file already exists
	if _, err := os.Stat(outPath); err == nil {
		return fmt.Errorf("disk already exists: %s", outPath)
	}

	if verbose {
		fmt.Printf("[vmctl] Creating disk: %s\n", outPath)
		fmt.Printf("[vmctl] Size: %s, Format: %s\n", size, diskFormat)
	}

	if dryRun {
		fmt.Printf("[dry-run] qemu-img create -f %s %s %s\n", diskFormat, outPath, size)
		return nil
	}

	// Create disk using qemu-img
	cmd := exec.Command("qemu-img", "create", "-f", diskFormat, outPath, size)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("creating disk: %w", err)
	}

	// Set permissions for libvirtd group compatibility
	os.Chmod(outPath, 0660)

	fmt.Printf("✓ Created disk: %s (%s, %s)\n", outPath, size, diskFormat)
	return nil
}
