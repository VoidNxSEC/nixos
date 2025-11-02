# ============================================================
# GCLOUD & KUBERNETES ALIASES
# ============================================================
# Aliases for Google Cloud Platform and Kubernetes operations
# Includes GKE GPU management, disk rescue, and cluster ops
# ============================================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # ============================================================
  # GCLOUD & KUBECTL ALIASES
  # ============================================================

  environment.shellAliases = {
    # ──────────────────────────────────────────────────────
    # GCLOUD COMPUTE - REGIONS & ZONES
    # ──────────────────────────────────────────────────────

    # List all regions
    gc-regions = "gcloud compute regions list";

    # List all zones
    gc-zones = "gcloud compute zones list";

    # Describe specific region (use with argument)
    gc-region-info = "gcloud compute regions describe";

    # Describe specific zone (use with argument)
    gc-zone-info = "gcloud compute zones describe";

    # ──────────────────────────────────────────────────────
    # GCLOUD PROJECT INFO
    # ──────────────────────────────────────────────────────

    # Show project info
    gc-project-info = "gcloud compute project-info describe --project";

    # Show current region config
    gc-config-region = "gcloud config list compute/region";

    # Show current zone config
    gc-config-zone = "gcloud config list compute/zone";

    # ──────────────────────────────────────────────────────
    # GCLOUD INSTANCE MANAGEMENT
    # ──────────────────────────────────────────────────────

    # List all instances
    gc-instances = "gcloud compute instances list";

    # Describe instance (use with instance name and zone)
    gc-instance-info = "gcloud compute instances describe";

    # SSH into instance (use with instance name and zone)
    gc-ssh = "gcloud compute ssh";

    # Start instance
    gc-start = "gcloud compute instances start";

    # Stop instance
    gc-stop = "gcloud compute instances stop";

    # ──────────────────────────────────────────────────────
    # KUBERNETES - GPU OPERATOR
    # ──────────────────────────────────────────────────────

    # Get GPU operator pods
    k8s-gpu-pods = "kubectl get pods -n gpu-operator";

    # Describe GPU operator deployment
    k8s-gpu-describe = "kubectl describe deployment -n gpu-operator";

    # Get GPU operator logs
    k8s-gpu-logs = "kubectl logs -n gpu-operator -l app=nvidia-gpu-operator";

    # ──────────────────────────────────────────────────────
    # KUBERNETES - GENERAL
    # ──────────────────────────────────────────────────────

    # Get all pods
    k8s-pods = "kubectl get pods --all-namespaces";

    # Get all nodes
    k8s-nodes = "kubectl get nodes";

    # Describe node
    k8s-node-info = "kubectl describe node";

    # Get node GPU allocatable resources
    k8s-node-gpu = "kubectl describe node | grep -A7 Allocatable";

    # Get all jobs
    k8s-jobs = "kubectl get jobs --all-namespaces";

    # Delete job
    k8s-job-delete = "kubectl delete job";

    # ──────────────────────────────────────────────────────
    # HELM
    # ──────────────────────────────────────────────────────

    # List helm releases
    helm-list = "helm list --all-namespaces";

    # Helm repo update
    helm-update = "helm repo update";

    # List helm repos
    helm-repos = "helm repo list";
  };

  # ============================================================
  # ADVANCED FUNCTIONS
  # ============================================================

  environment.etc."profile.d/gcloud-k8s-functions.sh" = {
    text = ''
            # ──────────────────────────────────────────────────────
            # HELM INSTALLATION
            # ──────────────────────────────────────────────────────

            # Install Helm 3
            helm-install() {
                echo "📦 Installing Helm 3..."

                curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
                chmod 700 /tmp/get_helm.sh
                /tmp/get_helm.sh

                if [ $? -eq 0 ]; then
                    echo "✓ Helm 3 installed successfully"
                    rm -f /tmp/get_helm.sh
                    helm version
                else
                    echo "✗ Helm installation failed"
                    return 1
                fi
            }

            # ──────────────────────────────────────────────────────
            # GPU OPERATOR INSTALLATION
            # ──────────────────────────────────────────────────────

            # Install NVIDIA GPU Operator via Helm
            k8s-gpu-operator-install() {
                echo "🎮 Installing NVIDIA GPU Operator..."

                # Add NVIDIA Helm repo
                echo "📦 Adding NVIDIA Helm repository..."
                helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
                helm repo update

                if [ $? -ne 0 ]; then
                    echo "✗ Failed to add NVIDIA Helm repo"
                    return 1
                fi

                # Install GPU operator
                echo "📦 Installing GPU operator (driver.enabled=false for pre-installed drivers)..."
                helm install --wait --generate-name \
                    -n gpu-operator --create-namespace \
                    nvidia/gpu-operator \
                    --set driver.enabled=false

                if [ $? -eq 0 ]; then
                    echo "✓ GPU Operator installed successfully"
                    echo ""
                    echo "🔍 Checking pods status..."
                    kubectl get pods -n gpu-operator
                else
                    echo "✗ GPU Operator installation failed"
                    return 1
                fi
            }

            # ──────────────────────────────────────────────────────
            # GPU TESTING
            # ──────────────────────────────────────────────────────

            # Test GPU access in Kubernetes
            k8s-gpu-test() {
                if [ -z "$1" ]; then
                    echo "Usage: k8s-gpu-test <node-name>"
                    echo "Example: k8s-gpu-test gke-cluster-gpu-node-1"
                    echo ""
                    echo "Available nodes:"
                    kubectl get nodes
                    return 1
                fi

                local node_name="$1"

                echo "🧪 Testing GPU on node: $node_name"
                echo ""
                echo "📊 GPU Resources on node:"
                kubectl describe node "$node_name" | grep -A7 Allocatable
                echo ""

                echo "🚀 Creating GPU test job..."
                cat <<EOF | kubectl create -f -
      apiVersion: batch/v1
      kind: Job
      metadata:
        name: test-job-gpu
      spec:
        template:
          spec:
            runtimeClassName: nvidia
            containers:
            - name: nvidia-test
              image: nvidia/cuda:12.0.0-base-ubuntu22.04
              command: ["nvidia-smi"]
              resources:
                limits:
                  nvidia.com/gpu: 1
            nodeSelector:
              kubernetes.io/hostname: ''${node_name}
            restartPolicy: Never
      EOF

                if [ $? -ne 0 ]; then
                    echo "✗ Failed to create test job"
                    return 1
                fi

                echo ""
                echo "⏳ Waiting for job to complete..."
                kubectl wait --for=condition=complete --timeout=60s job/test-job-gpu

                echo ""
                echo "📋 Job logs:"
                kubectl logs job/test-job-gpu

                echo ""
                echo "🧹 Cleaning up test job..."
                kubectl delete job test-job-gpu

                echo "✓ GPU test completed"
            }

            # ──────────────────────────────────────────────────────
            # DISK RESCUE OPERATIONS
            # ──────────────────────────────────────────────────────

            # Detach boot disk from instance
            gc-disk-detach() {
                if [ $# -lt 3 ]; then
                    echo "Usage: gc-disk-detach <instance-name> <disk-name> <zone>"
                    echo "Example: gc-disk-detach my-vm my-vm-boot us-central1-a"
                    return 1
                fi

                local instance="$1"
                local disk="$2"
                local zone="$3"

                echo "⚠️  Detaching disk '$disk' from instance '$instance'..."
                gcloud compute instances detach-disk "$instance" \
                    --disk="$disk" \
                    --zone="$zone"

                if [ $? -eq 0 ]; then
                    echo "✓ Disk detached successfully"
                else
                    echo "✗ Failed to detach disk"
                    return 1
                fi
            }

            # Attach disk to instance
            gc-disk-attach() {
                if [ $# -lt 3 ]; then
                    echo "Usage: gc-disk-attach <instance-name> <disk-name> <zone> [--boot]"
                    echo "Example: gc-disk-attach my-vm my-vm-boot us-central1-a --boot"
                    return 1
                fi

                local instance="$1"
                local disk="$2"
                local zone="$3"
                local boot_flag="$4"

                echo "🔗 Attaching disk '$disk' to instance '$instance'..."

                if [ "$boot_flag" = "--boot" ]; then
                    gcloud compute instances attach-disk "$instance" \
                        --disk="$disk" \
                        --zone="$zone" \
                        --boot
                else
                    gcloud compute instances attach-disk "$instance" \
                        --disk="$disk" \
                        --zone="$zone"
                fi

                if [ $? -eq 0 ]; then
                    echo "✓ Disk attached successfully"
                else
                    echo "✗ Failed to attach disk"
                    return 1
                fi
            }

            # Create rescue VM and attach disk
            gc-disk-rescue() {
                if [ $# -lt 3 ]; then
                    echo "Usage: gc-disk-rescue <disk-name> <zone> <rescue-vm-name>"
                    echo "Example: gc-disk-rescue my-vm-boot us-central1-a vm-rescue"
                    echo ""
                    echo "This will:"
                    echo "  1. Create a temporary rescue VM"
                    echo "  2. Attach the specified disk to it"
                    echo "  3. SSH into the rescue VM"
                    return 1
                fi

                local disk="$1"
                local zone="$2"
                local rescue_vm="$3"

                echo "🚑 Creating rescue VM: $rescue_vm"
                gcloud compute instances create "$rescue_vm" \
                    --zone="$zone" \
                    --machine-type=e2-medium \
                    --image-family=debian-11 \
                    --image-project=debian-cloud

                if [ $? -ne 0 ]; then
                    echo "✗ Failed to create rescue VM"
                    return 1
                fi

                echo ""
                echo "🔗 Attaching disk '$disk' to rescue VM..."
                gcloud compute instances attach-disk "$rescue_vm" \
                    --disk="$disk" \
                    --zone="$zone"

                if [ $? -ne 0 ]; then
                    echo "✗ Failed to attach disk"
                    echo "⚠️  Cleaning up rescue VM..."
                    gcloud compute instances delete "$rescue_vm" --zone="$zone" --quiet
                    return 1
                fi

                echo ""
                echo "✓ Rescue VM ready!"
                echo ""
                echo "📝 To access the disk:"
                echo "  1. SSH: gcloud compute ssh $rescue_vm --zone=$zone"
                echo "  2. List disks: lsblk"
                echo "  3. Mount disk: sudo mount /dev/sdb1 /mnt"
                echo ""
                echo "🧹 To cleanup after rescue:"
                echo "  1. Detach: gcloud compute instances detach-disk $rescue_vm --disk=$disk --zone=$zone"
                echo "  2. Delete VM: gcloud compute instances delete $rescue_vm --zone=$zone"
                echo ""
                read -p "Press Enter to SSH into rescue VM, or Ctrl+C to cancel..."
                gcloud compute ssh "$rescue_vm" --zone="$zone"
            }

            # ──────────────────────────────────────────────────────
            # GCLOUD QUICK INFO
            # ──────────────────────────────────────────────────────

            # Show current gcloud configuration
            gc-info() {
                echo "╔════════════════════════════════════════╗"
                echo "║    Google Cloud Configuration         ║"
                echo "╚════════════════════════════════════════╝"
                echo ""

                echo "📋 Current Configuration:"
                gcloud config list
                echo ""

                echo "🌍 Available Regions (sample):"
                gcloud compute regions list --limit=5
                echo "  ... (use 'gc-regions' for full list)"
                echo ""

                echo "🏢 Current Project:"
                gcloud config get-value project
                echo ""

                echo "💻 Compute Instances:"
                gcloud compute instances list
            }

            # Show Kubernetes cluster info
            k8s-info() {
                echo "╔════════════════════════════════════════╗"
                echo "║    Kubernetes Cluster Info            ║"
                echo "╚════════════════════════════════════════╝"
                echo ""

                echo "🏗️  Cluster:"
                kubectl cluster-info
                echo ""

                echo "🖥️  Nodes:"
                kubectl get nodes -o wide
                echo ""

                echo "🎮 GPU Resources:"
                kubectl get nodes -o json | jq -r '.items[] | select(.status.capacity."nvidia.com/gpu" != null) | "\(.metadata.name): \(.status.capacity."nvidia.com/gpu") GPUs"'
                echo ""

                echo "📦 Pods by Namespace:"
                kubectl get pods --all-namespaces | head -20
            }

            # Export functions
            export -f helm-install
            export -f k8s-gpu-operator-install
            export -f k8s-gpu-test
            export -f gc-disk-detach
            export -f gc-disk-attach
            export -f gc-disk-rescue
            export -f gc-info
            export -f k8s-info
    '';
    mode = "0755";
  };

  # ============================================================
  # PACKAGE DEPENDENCIES
  # ============================================================

  environment.systemPackages = with pkgs; [
    # Google Cloud SDK
    google-cloud-sdk

    # Kubernetes tools
    kubectl
    kubernetes-helm

    # Utilities
    jq # JSON processing for k8s-info function
  ];
}
