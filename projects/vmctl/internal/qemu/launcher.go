package qemu

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"syscall"

	"vmctl/internal/vm"
)

// QEMUBinary is the default QEMU binary for x86_64
const QEMUBinary = "qemu-system-x86_64"

// LaunchOptions contains options for launching a VM
type LaunchOptions struct {
	VMName   string
	Config   *vm.VMConfig
	Detached bool
	DryRun   bool
	Verbose  bool
}

// BuildArgs constructs QEMU command line arguments from VM config
func BuildArgs(cfg *vm.VMConfig, vmName string) []string {
	args := []string{
		"-name", vmName,
		"-enable-kvm",
		"-m", cfg.Memory,
		"-smp", strconv.Itoa(cfg.CPUs),
	}

	// Main disk
	args = append(args,
		"-drive", fmt.Sprintf("file=%s,format=qcow2,if=virtio,cache=writeback", cfg.Image),
	)

	// Additional disks
	for i, disk := range cfg.Disks {
		format := disk.Format
		if format == "" {
			format = "qcow2"
		}
		args = append(args,
			"-drive", fmt.Sprintf("file=%s,format=%s,if=virtio,id=disk%d", disk.Path, format, i+1),
		)
	}

	// Network
	args = append(args, buildNetworkArgs(cfg)...)

	// Display
	args = append(args, buildDisplayArgs(cfg)...)

	// VirtioFS shares
	for _, share := range cfg.Shares {
		args = append(args, buildShareArgs(&share)...)
	}

	// PID file for tracking
	runDir := os.Getenv("XDG_RUNTIME_DIR")
	if runDir == "" {
		runDir = "/tmp"
	}
	pidDir := filepath.Join(runDir, "vmctl")
	os.MkdirAll(pidDir, 0755)
	args = append(args, "-pidfile", filepath.Join(pidDir, vmName+".pid"))

	// QMP socket for control
	args = append(args,
		"-qmp", fmt.Sprintf("unix:%s,server,nowait", filepath.Join(pidDir, vmName+".qmp")),
	)

	// Extra arguments
	args = append(args, cfg.ExtraArgs...)

	return args
}

func buildNetworkArgs(cfg *vm.VMConfig) []string {
	var args []string

	switch {
	case cfg.Network == "user" || cfg.Network == "":
		// User mode networking (NAT)
		args = append(args,
			"-netdev", "user,id=net0,hostfwd=tcp::2222-:22",
			"-device", "virtio-net-pci,netdev=net0",
		)
	case len(cfg.Network) > 7 && cfg.Network[:7] == "bridge:":
		// Bridge networking
		bridgeName := cfg.Network[7:]
		netdev := fmt.Sprintf("bridge,id=net0,br=%s", bridgeName)
		if cfg.MacAddress != "" {
			args = append(args,
				"-netdev", netdev,
				"-device", fmt.Sprintf("virtio-net-pci,netdev=net0,mac=%s", cfg.MacAddress),
			)
		} else {
			args = append(args,
				"-netdev", netdev,
				"-device", "virtio-net-pci,netdev=net0",
			)
		}
	default:
		// Assume it's a bridge name directly
		args = append(args,
			"-netdev", fmt.Sprintf("bridge,id=net0,br=%s", cfg.Network),
			"-device", "virtio-net-pci,netdev=net0",
		)
	}

	return args
}

func buildDisplayArgs(cfg *vm.VMConfig) []string {
	var args []string

	switch cfg.Display {
	case "gtk":
		args = append(args, "-display", "gtk,show-cursor=on")
	case "sdl":
		args = append(args, "-display", "sdl")
	case "spice":
		args = append(args,
			"-spice", "port=5900,disable-ticketing=on",
			"-device", "virtio-serial-pci",
			"-device", "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0",
			"-chardev", "spicevmc,id=spicechannel0,name=vdagent",
		)
	case "none", "headless":
		args = append(args, "-display", "none")
	default:
		args = append(args, "-display", "gtk")
	}

	// Add video device
	if cfg.Display != "none" && cfg.Display != "headless" {
		args = append(args, "-device", "virtio-vga")
	}

	return args
}

func buildShareArgs(share *vm.ShareConfig) []string {
	var args []string

	if share.Driver == "virtiofs" || share.Driver == "" {
		// VirtioFS requires memory backend
		args = append(args,
			"-object", fmt.Sprintf("memory-backend-memfd,id=mem,size=4G,share=on"),
			"-numa", "node,memdev=mem",
			"-chardev", fmt.Sprintf("socket,id=%s,path=/tmp/vhost-%s.sock", share.GuestTag, share.GuestTag),
			"-device", fmt.Sprintf("vhost-user-fs-pci,chardev=%s,tag=%s", share.GuestTag, share.GuestTag),
		)
	}

	return args
}

// Launch starts a QEMU process for the given VM
func Launch(opts LaunchOptions) (int, error) {
	args := BuildArgs(opts.Config, opts.VMName)

	cmd := exec.Command(QEMUBinary, args...)
	cmd.Env = append(os.Environ(), "DISPLAY="+os.Getenv("DISPLAY"))
	
	// Detach from terminal
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setsid: true,
	}

	// Redirect output for debugging
	if opts.Verbose || os.Getenv("VMCTL_DEBUG") != "" {
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
	}

	if err := cmd.Start(); err != nil {
		return 0, fmt.Errorf("starting QEMU: %w", err)
	}

	// Don't wait for the process - it runs independently
	go cmd.Wait()

	return cmd.Process.Pid, nil
}

// Stop sends shutdown signal to a VM via QMP
func Stop(vmName string) error {
	pid, err := vm.GetPID(vmName)
	if err != nil {
		return err
	}

	// Send SIGTERM for graceful shutdown
	process, err := os.FindProcess(pid)
	if err != nil {
		return fmt.Errorf("finding process: %w", err)
	}

	if err := process.Signal(syscall.SIGTERM); err != nil {
		return fmt.Errorf("sending signal: %w", err)
	}

	return nil
}

// ForceStop kills a VM immediately
func ForceStop(vmName string) error {
	pid, err := vm.GetPID(vmName)
	if err != nil {
		return err
	}

	process, err := os.FindProcess(pid)
	if err != nil {
		return fmt.Errorf("finding process: %w", err)
	}

	if err := process.Kill(); err != nil {
		return fmt.Errorf("killing process: %w", err)
	}

	// Clean up PID file
	os.Remove(vm.PidFile(vmName))

	return nil
}
