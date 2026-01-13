package main

import (
	"embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

// --- 1. EMBED ZARF CLI ---
// We embed the binary file located at cli/embedded/zarf inside THIS program.
//go:embed embedded/zarf
var embeddedFS embed.FS

// INJECTED AT BUILD TIME (See Makefile)
var Version = "0.0.0-local"
var Registry = "localhost:5000"

// CONFIGURATION
var packages = map[string]string{
	// Key: What the user types (e.g. 'staq deploy core')
	// Value: The start of the filename in the release folder
	
	"core":    "staq-core",    // Will match staq-core-v1.0.0.tar.zst
	"factory": "staq-factory", // Will match staq-factory-v1.0.0.tar.zst
	"ide":     "staq-ide",     // Will match staq-ide-v1.0.0.tar.zst
}

func main() {
	// A. EXTRACT THE ENGINE
	zarfBinPath, err := extractZarf()
	if err != nil {
		fmt.Printf("❌ Critical: Failed to load internal engine: %v\n", err)
		os.Exit(1)
	}
	// Clean up the temp binary when 'staq' finishes running
	defer os.Remove(zarfBinPath)

	var rootCmd = &cobra.Command{
		Use:     "staq",
		Short:   "PlatformStaq Interface",
		Version: Version,
		Long:    `Deploy secure, air-gapped infrastructure.`,
	}

	// --- COMMAND: DEPLOY ---
	var deployCmd = &cobra.Command{
		Use:   "deploy [layer]",
		Short: "Deploy a stack layer (core | factory)",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			layer := args[0]
			pkgPrefix, ok := packages[layer]
			if !ok {
				fmt.Println("❌ Unknown layer. Options: core, factory")
				os.Exit(1)
			}

			// B. CHECK & RUN INIT (Only for Core)
			if layer == "core" {
				ensureZarfInitialized(zarfBinPath)
			}

			// C. FIND PACKAGE (Local or OCI)
			var deployTarget string
			pkgFile, err := findFile(pkgPrefix + "*.tar.zst")

			if err != nil {
				// Fallback: Stream from Registry
				// Example: oci://public.ecr.aws/my-repo/staq-core:1.0.0
				deployTarget = fmt.Sprintf("oci://%s/%s:%s", Registry, pkgPrefix, Version)
				fmt.Printf("☁️  Local package not found. Pulling from: %s\n", deployTarget)
			} else {
				deployTarget = pkgFile
			}

			// D. DEPLOY PACKAGE
			fmt.Printf("\n🏗️  Deploying Staq Layer: %s\n", strings.ToUpper(layer))
			runCommand(zarfBinPath, "package", "deploy", deployTarget, "--confirm")
		},
	}

	rootCmd.AddCommand(deployCmd)
	rootCmd.Execute()
}

// --- LOGIC HELPERS ---

// ensureZarfInitialized checks if Zarf is running. If not, it runs 'zarf init'.
func ensureZarfInitialized(zarfBin string) {
	fmt.Println("🔍 Checking Cluster Initialization...")

	// We use 'zarf tools kubectl' to check if the 'zarf' namespace exists
	checkCmd := exec.Command(zarfBin, "tools", "kubectl", "get", "namespace", "zarf")
	if err := checkCmd.Run(); err == nil {
		fmt.Println("✅ Cluster is already initialized.")
		return
	}

	fmt.Println("⚠️  Cluster not initialized. Running Bootstrap...")

	initPackage, err := findFile("staq-init-*.tar.zst")
	
	if err != nil {
		fmt.Printf("❌ Error: Cluster needs initialization, but I cannot find 'staq-init-*.tar.zst' in this folder.\n")
		os.Exit(1)
	}

	fmt.Printf("🚀 Bootstrapping with: %s\n", filepath.Base(initPackage))

	// Run Init
	runCommand(zarfBin, "init", "--confirm", initPackage)
}

func extractZarf() (string, error) {
	tmpDir := os.TempDir()
	destPath := filepath.Join(tmpDir, "staq-engine")
	// On Windows, you might need to add .exe extension logic here
	
	data, err := embeddedFS.ReadFile("embedded/zarf")
	if err != nil {
		return "", err
	}
	
	// Write file with executable permissions (0755)
	err = os.WriteFile(destPath, data, 0755)
	if err != nil {
		return "", err
	}
	return destPath, nil
}

func findFile(pattern string) (string, error) {
	matches, _ := filepath.Glob(pattern)
	if len(matches) == 0 {
		return "", fmt.Errorf("not found")
	}
	return matches[len(matches)-1], nil
}

func runCommand(bin string, args ...string) {
	cmd := exec.Command(bin, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	if err := cmd.Run(); err != nil {
		fmt.Println("❌ Command Failed")
		os.Exit(1)
	}
}