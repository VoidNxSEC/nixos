package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/user/cognitive-vault/internal/crypto"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize a new secure vault",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Print("Enter master password: ")
		var password string
		fmt.Scanln(&password) // TODO: Use terminal echo suppression

		// Initialize vault with a test secret or structure
		// For now, just a string "VAULT_INITIALIZED"
		payload := []byte("VAULT_INITIALIZED")

		encrypted, err := crypto.Encrypt(password, payload)
		if err != nil {
			fmt.Printf("Error encrypting vault: %v\n", err)
			return
		}

		// Save to .vault.dat
		home, _ := os.UserHomeDir()
		path := filepath.Join(home, ".vault.dat")

		err = os.WriteFile(path, encrypted, 0600)
		if err != nil {
			fmt.Printf("Error writing vault file: %v\n", err)
			return
		}

		fmt.Printf("Vault initialized at %s\n", path)
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
}
