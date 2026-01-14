#!/usr/bin/env bash
# K8s Stack Setup Script for NixOS
# Automates the deployment of a production-ready Kubernetes cluster
#
# Usage: sudo ./k8s-setup.sh [init|deploy|verify|destroy]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NIXOS_CONFIG_DIR="/etc/nixos"
MODULES_DIR="${NIXOS_CONFIG_DIR}/modules"
K8S_MODULES_DIR="${MODULES_DIR}/k8s"
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
  fi
}

check_dependencies() {
  log_info "Checking dependencies..."

  local deps=(git kubectl helm sops age)
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing dependencies: ${missing[*]}"
    log_info "Install with: nix-env -iA nixos.${missing[*]}"
    exit 1
  fi

  log_success "All dependencies present"
}

init_structure() {
  log_info "Initializing K8s module structure..."

  # Create directory structure
  mkdir -p "${K8S_MODULES_DIR}"/{containers,network,security,observability}
  mkdir -p "${NIXOS_CONFIG_DIR}"/{k8s-apps,k8s-secrets}

  # Create .gitignore for secrets
  cat >"${NIXOS_CONFIG_DIR}/k8s-secrets/.gitignore" <<EOF
# Ignore all secrets
*.yaml
*.yml
*.json
*.key
*.pem

# Except encrypted SOPS files
!*.enc.yaml
!.sops.yaml
EOF

  log_success "Directory structure created"
}

generate_secrets() {
  log_info "Generating cluster secrets..."

  local secrets_file="${NIXOS_CONFIG_DIR}/k8s-secrets/secrets.yaml"

  # Generate k3s token if not exists
  if [[ ! -f "$secrets_file" ]]; then
    local k3s_token
    k3s_token=$(openssl rand -hex 32)

    cat >"$secrets_file" <<EOF
# Kubernetes Cluster Secrets
# Encrypt with: sops -e -i secrets.yaml

k3s-token: ${k3s_token}
grafana-password: $(openssl rand -base64 16)

# Example AWS credentials for Longhorn backups
# aws-access-key-id: YOUR_ACCESS_KEY
# aws-secret-access-key: YOUR_SECRET_KEY
EOF

    log_warning "Generated secrets at: $secrets_file"
    log_warning "IMPORTANT: Encrypt with SOPS before committing!"
    log_info "Run: sops -e -i $secrets_file"
  else
    log_info "Secrets file already exists"
  fi
}

copy_modules() {
  log_info "Installing K8s NixOS modules..."

  # Copy modules if they exist in current directory
  if [[ -d "./modules" ]]; then
    cp -r ./modules/containers/k3s-cluster.nix "${MODULES_DIR}/containers/" 2>/dev/null || true
    cp -r ./modules/network/cilium-cni.nix "${MODULES_DIR}/network/" 2>/dev/null || true
    cp -r ./modules/containers/longhorn-storage.nix "${MODULES_DIR}/containers/" 2>/dev/null || true

    log_success "Modules installed"
  else
    log_warning "Module files not found in current directory"
    log_info "Place module files in: ${MODULES_DIR}"
  fi
}

deploy_cluster() {
  log_info "Deploying Kubernetes cluster..."

  # Rebuild NixOS configuration
  log_info "Rebuilding NixOS with K8s modules..."
  nixos-rebuild switch

  # Wait for k3s to be ready
  log_info "Waiting for K8s API server..."
  local max_attempts=60
  local attempt=0

  while [[ $attempt -lt $max_attempts ]]; do
    if kubectl get nodes &>/dev/null; then
      log_success "K8s API server is ready!"
      break
    fi

    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
  done

  if [[ $attempt -eq $max_attempts ]]; then
    log_error "Timeout waiting for K8s API server"
    exit 1
  fi

  log_success "Cluster deployed successfully"
}

verify_cluster() {
  log_info "Verifying cluster health..."

  export KUBECONFIG="$KUBECONFIG"

  echo ""
  log_info "=== Nodes ==="
  kubectl get nodes -o wide

  echo ""
  log_info "=== System Pods ==="
  kubectl get pods -A

  echo ""
  log_info "=== Storage Classes ==="
  kubectl get storageclass

  echo ""
  log_info "=== Cilium Status ==="
  cilium status 2>/dev/null || log_warning "Cilium CLI not available"

  echo ""
  log_info "=== Cluster Info ==="
  kubectl cluster-info

  echo ""
  log_success "Cluster verification complete!"

  # Display access information
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║              KUBERNETES CLUSTER READY                      ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  echo "📊 Dashboards:"
  echo "   • Hubble UI:    http://$(hostname -I | awk '{print $1}'):12000"
  echo "   • Longhorn UI:  http://$(hostname -I | awk '{print $1}'):8000"
  echo ""
  echo "🔧 Tools:"
  echo "   • kubectl:  kubectl get all -A"
  echo "   • k9s:      k9s"
  echo "   • stern:    stern -n kube-system cilium"
  echo ""
  echo "📝 KUBECONFIG: $KUBECONFIG"
  echo ""
}

deploy_sample_app() {
  log_info "Deploying sample application..."

  export KUBECONFIG="$KUBECONFIG"

  cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
  namespace: demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  namespace: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: demo-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo
  namespace: demo
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

  log_success "Sample app deployed to 'demo' namespace"
  log_info "Check status with: kubectl get all -n demo"
}

destroy_cluster() {
  log_warning "This will destroy the K8s cluster and all data!"
  read -p "Are you sure? (yes/no): " confirm

  if [[ "$confirm" != "yes" ]]; then
    log_info "Aborted"
    exit 0
  fi

  log_info "Destroying cluster..."

  # Stop k3s
  systemctl stop k3s

  # Remove k3s data
  rm -rf /var/lib/rancher/k3s
  rm -rf /var/lib/longhorn

  # Remove kubeconfig
  rm -f /etc/rancher/k3s/k3s.yaml

  log_success "Cluster destroyed"
}

show_help() {
  cat <<EOF
K8s Stack Setup Script for NixOS

Usage: $0 [COMMAND]

Commands:
    init        Initialize directory structure and generate secrets
    deploy      Deploy the K8s cluster
    verify      Verify cluster health and show status
    sample      Deploy a sample nginx application
    destroy     Destroy the cluster (WARNING: deletes all data)
    help        Show this help message

Examples:
    # Initial setup
    $0 init

    # Deploy cluster
    $0 deploy

    # Verify deployment
    $0 verify

    # Full setup (init + deploy + verify)
    $0 init && $0 deploy && $0 verify

Environment:
    KUBECONFIG=$KUBECONFIG
    NIXOS_CONFIG_DIR=$NIXOS_CONFIG_DIR

EOF
}

main() {
  local command="${1:-help}"

  check_root

  case "$command" in
    init)
      check_dependencies
      init_structure
      generate_secrets
      copy_modules
      log_success "Initialization complete!"
      log_info "Next steps:"
      log_info "  1. Review and encrypt secrets: sops -e -i $NIXOS_CONFIG_DIR/k8s-secrets/secrets.yaml"
      log_info "  2. Add K8s modules to your configuration.nix"
      log_info "  3. Run: $0 deploy"
      ;;

    deploy)
      deploy_cluster
      ;;

    verify)
      verify_cluster
      ;;

    sample)
      deploy_sample_app
      ;;

    destroy)
      destroy_cluster
      ;;

    help | --help | -h)
      show_help
      ;;

    *)
      log_error "Unknown command: $command"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
