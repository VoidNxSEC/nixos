package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "vault",
	Short: "CognitiveVault - Hybrid Secure Password Manager",
	Long: `A secure, TUI-based password manager built with Rust and Go.
Combines AES-256-GCM / Argon2id (Rust) with Bubbletea TUI (Go).`,
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
