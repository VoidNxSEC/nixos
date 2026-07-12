# modules/containers/kind.nix
#
# kind (Kubernetes IN Docker) lab environment.
# Declarative local multi-node cluster generator + CKA/CKAD/CKS toolset,
# meant to complement (not replace) the heavier kernelcore.kubernetes.k3s module:
# kind is for fast, disposable, multi-node practice clusters used to study
# for Kubernetes certification exams; k3s-cluster.nix is for an always-on
# cluster on real hardware.
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.kernelcore.kubernetes.kind;

  controlPlaneCount = if cfg.haControlPlane then 3 else 1;

  nodeImageLine = optional (
    cfg.kubernetesVersion != null
  ) "    image: kindest/node:${cfg.kubernetesVersion}";

  ingressPortMappings = optionals cfg.ingress.enable [
    {
      containerPort = 80;
      hostPort = 80;
      protocol = "TCP";
    }
    {
      containerPort = 443;
      hostPort = 443;
      protocol = "TCP";
    }
  ];

  allPortMappings = ingressPortMappings ++ cfg.extraPortMappings;

  mkPortMappingLines = pm: [
    "      - containerPort: ${toString pm.containerPort}"
    "        hostPort: ${toString pm.hostPort}"
    "        protocol: ${pm.protocol}"
  ];

  portMappingBlock = optionals (allPortMappings != [ ]) (
    [ "    extraPortMappings:" ] ++ concatMap mkPortMappingLines allPortMappings
  );

  ingressLabelBlock = optionals cfg.ingress.enable [
    "    kubeadmConfigPatches:"
    "      - |"
    "        kind: InitConfiguration"
    "        nodeRegistration:"
    "          kubeletExtraArgs:"
    "            node-labels: \"ingress-ready=true\""
  ];

  mkControlPlaneNode =
    isFirst:
    concatStringsSep "\n" (
      [ "  - role: control-plane" ]
      ++ nodeImageLine
      ++ optionals isFirst ingressLabelBlock
      ++ optionals isFirst portMappingBlock
    );

  mkWorkerNode =
    idx:
    concatStringsSep "\n" (
      [ "  - role: worker" ]
      ++ nodeImageLine
      ++ [
        "    labels:"
        "      tier: \"app\""
        "      worker-index: \"${toString idx}\""
      ]
    );

  # A non-default CNI means we must tell kind NOT to install kindnetd.
  disableCNI = cfg.cni != "default";

  cniLabel =
    if cfg.cni == "calico" then
      "calico (NetworkPolicy ENFORCED)"
    else
      "kindnetd default (NetworkPolicy NOT enforced — see CKA-COVERAGE-MATRIX.md)";

  # Calico's default IPv4 pool is 192.168.0.0/16. If the user kept kind's
  # default podSubnet, match Calico's so the stock manifest works unmodified.
  effectivePodSubnet =
    if cfg.cni == "calico" && cfg.podSubnet == "10.244.0.0/16" then "192.168.0.0/16" else cfg.podSubnet;

  networkingBlock = [
    "networking:"
    "  podSubnet: \"${effectivePodSubnet}\""
    "  serviceSubnet: \"${cfg.serviceSubnet}\""
  ]
  ++ optional disableCNI "  disableDefaultCNI: true";

  kindClusterYaml = pkgs.writeText "kind-${cfg.clusterName}-config.yaml" (
    concatStringsSep "\n" (
      [
        "kind: Cluster"
        "apiVersion: kind.x-k8s.io/v1alpha4"
        "name: ${cfg.clusterName}"
      ]
      ++ networkingBlock
      ++ [ "nodes:" ]
      ++ genList (idx: mkControlPlaneNode (idx == 0)) controlPlaneCount
      ++ genList mkWorkerNode cfg.workerCount
    )
  );

  contextName = "kind-${cfg.clusterName}";

  kindlab-up = pkgs.writeShellScriptBin "kindlab-up" ''
    set -euo pipefail

    if ${pkgs.kind}/bin/kind get clusters 2>/dev/null | grep -qx "${cfg.clusterName}"; then
      echo "✓ Cluster '${cfg.clusterName}' already running."
    else
      echo "⟳ Creating cluster '${cfg.clusterName}' (${toString controlPlaneCount} control-plane, ${toString cfg.workerCount} worker)..."
      ${pkgs.kind}/bin/kind create cluster --config ${kindClusterYaml}
    fi

    ${pkgs.kubectl}/bin/kubectl config use-context "${contextName}" >/dev/null

    ${optionalString (cfg.cni == "calico") ''
      echo "⟳ Installing Calico CNI (policy-capable — enables NetworkPolicy ENFORCEMENT)..."
      ${pkgs.kubectl}/bin/kubectl apply -f ${cfg.calicoManifestUrl}
      echo "  waiting for Calico (nodes stay NotReady until the CNI is up)..."
      ${pkgs.kubectl}/bin/kubectl -n kube-system rollout status ds/calico-node --timeout=300s || true
      ${pkgs.kubectl}/bin/kubectl wait --for=condition=Ready nodes --all --timeout=300s || true
    ''}

    ${optionalString cfg.ingress.enable ''
      echo "⟳ Installing ingress-nginx (kind provider)..."
      ${pkgs.kubectl}/bin/kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
      ${pkgs.kubectl}/bin/kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=180s
    ''}

    ${optionalString cfg.metricsServer.enable ''
      echo "⟳ Installing metrics-server (patched for kind's self-signed kubelet certs)..."
      ${pkgs.kubectl}/bin/kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
      ${pkgs.kubectl}/bin/kubectl patch deployment metrics-server -n kube-system --type=json \
        -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true
    ''}

    echo "✓ Cluster ready. Context: ${contextName}"
    ${pkgs.kubectl}/bin/kubectl get nodes -o wide
  '';

  kindlab-down = pkgs.writeShellScriptBin "kindlab-down" ''
    set -euo pipefail
    echo "⟳ Destroying cluster '${cfg.clusterName}'..."
    ${pkgs.kind}/bin/kind delete cluster --name ${cfg.clusterName}
    echo "✓ Cluster removed."
  '';

  kindlab-reset = pkgs.writeShellScriptBin "kindlab-reset" ''
    set -euo pipefail
    ${pkgs.kind}/bin/kind delete cluster --name ${cfg.clusterName} 2>/dev/null || true
    exec ${kindlab-up}/bin/kindlab-up
  '';

  kindlab-status = pkgs.writeShellScriptBin "kindlab-status" ''
    set -euo pipefail
    echo "=== kind clusters ==="
    ${pkgs.kind}/bin/kind get clusters 2>/dev/null || echo "(none)"
    echo ""
    if ${pkgs.kind}/bin/kind get clusters 2>/dev/null | grep -qx "${cfg.clusterName}"; then
      echo "=== Nodes ==="
      ${pkgs.kubectl}/bin/kubectl get nodes -o wide
      echo ""
      echo "=== Namespaces ==="
      ${pkgs.kubectl}/bin/kubectl get ns
      echo ""
      echo "=== Pods (all namespaces) ==="
      ${pkgs.kubectl}/bin/kubectl get pods -A
    fi
  '';

  kindlab-load = pkgs.writeShellScriptBin "kindlab-load" ''
    set -euo pipefail
    if [ $# -lt 1 ]; then
      echo "Usage: kindlab-load <image:tag> [<image:tag> ...]"
      echo "Loads locally-built/pulled docker images into every node of '${cfg.clusterName}'."
      exit 1
    fi
    ${pkgs.kind}/bin/kind load docker-image "$@" --name ${cfg.clusterName}
  '';

  kindlab-help = pkgs.writeShellScriptBin "kindlab-help" ''
    cat <<'EOF'

    ╔════════════════════════════════════════════════════════════════╗
    ║  kind-lab — CKA/CKAD/CKS local cluster toolkit                 ║
    ╠════════════════════════════════════════════════════════════════╣
    ║  kindlab-up      → create/connect to the cluster                ║
    ║  kindlab-down    → destroy the cluster                          ║
    ║  kindlab-reset   → destroy + recreate from scratch              ║
    ║  kindlab-status  → nodes / namespaces / pods overview           ║
    ║  kindlab-load    → load local docker images into cluster nodes  ║
    ║  kindlab-help    → this panel                                   ║
    ║                                                                  ║
    ║  kubectl / k9s / stern / kubectx / kubens / kubecolor / helm    ║
    ║  kustomize / crictl / etcdctl / dive / kubeconform              ║
    ╠════════════════════════════════════════════════════════════════╣
    ║  Study material:                                                ║
    ║    ~/learn/kuber-labs/        → flake devShell, manifests, labs ║
    ║    ~/learn/kuber-labs/k8s-cheatsheet.md                         ║
    ║    ~/learn/CKA-StudyGuide/                                       ║
    ║    docs/guides/KIND-CKA-EXAM-GUIDE.md (this repo)                ║
    ║    docs/guides/CKA-COVERAGE-MATRIX.md (what's covered vs gaps)   ║
    ╚════════════════════════════════════════════════════════════════╝
    EOF
    echo "    CNI: ${cniLabel}"
    echo ""
  '';

in
{
  options.kernelcore.kubernetes.kind = {
    enable = mkEnableOption "kind (Kubernetes IN Docker) lab environment for Kubernetes certification exam prep (CKA/CKAD/CKS)";

    clusterName = mkOption {
      type = types.str;
      default = "cka-lab";
      description = "Name of the kind cluster (becomes kubeconfig context kind-<name>).";
    };

    provider = mkOption {
      type = types.enum [
        "docker"
        "podman"
      ];
      default = "docker";
      description = "Container runtime kind uses to run cluster nodes. Podman support is experimental upstream.";
    };

    workerCount = mkOption {
      type = types.ints.unsigned;
      default = 2;
      description = "Number of worker nodes in the generated cluster.";
    };

    haControlPlane = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use 3 control-plane nodes instead of 1 (kind automatically fronts them
        with a load balancer container). Useful for practicing CKA "Cluster
        Architecture" topics: etcd quorum, multi-master failover, kubeadm join.
      '';
    };

    kubernetesVersion = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "v1.31.0";
      description = "Pin every node to a specific kindest/node image tag. Null = kind's bundled default.";
    };

    podSubnet = mkOption {
      type = types.str;
      default = "10.244.0.0/16";
      description = "Cluster pod CIDR.";
    };

    serviceSubnet = mkOption {
      type = types.str;
      default = "10.96.0.0/12";
      description = "Cluster service CIDR.";
    };

    cni = mkOption {
      type = types.enum [
        "default"
        "calico"
      ];
      default = "default";
      description = ''
        CNI plugin for the cluster:
        - "default": kindnetd — simple and fast, but does NOT enforce
          NetworkPolicy. Applied policies are silently ignored.
        - "calico": disables kindnetd (disableDefaultCNI) and installs Calico
          on kindlab-up. Calico enforces standard NetworkPolicy, so you can
          actually practice CKA Domain 3 (Services & Networking) NetworkPolicy
          *enforcement* locally — the 03-networkpolicy lab needs this.

        See docs/guides/CKA-COVERAGE-MATRIX.md for what each mode covers.
        Note: with "calico", if podSubnet is left at the default it is switched
        to Calico's 192.168.0.0/16 so the stock manifest works unmodified.
      '';
    };

    calicoManifestUrl = mkOption {
      type = types.str;
      default = "https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml";
      description = ''
        Calico install manifest, applied when cni = "calico". Pinned to a known
        version; bump it as Calico releases. Verify the tag exists if you change it.
      '';
    };

    ingress = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Label the first control-plane node ingress-ready=true, map host
          ports 80/443 to it, and install ingress-nginx's kind provider
          manifest on kindlab-up.
        '';
      };
    };

    metricsServer = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install metrics-server on kindlab-up, patched with --kubelet-insecure-tls (required for kind's self-signed kubelet certs).";
      };
    };

    extraPortMappings = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            containerPort = mkOption {
              type = types.port;
              description = "Port inside the first control-plane node's container.";
            };
            hostPort = mkOption {
              type = types.port;
              description = "Port on the host machine.";
            };
            protocol = mkOption {
              type = types.enum [
                "TCP"
                "UDP"
                "SCTP"
              ];
              default = "TCP";
              description = "Port protocol.";
            };
          };
        }
      );
      default = [ ];
      description = "Additional host<->container port mappings on the first control-plane node, e.g. for exposing a NodePort service.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages to add to environment.systemPackages alongside the kind toolset.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          (cfg.provider == "docker" && config.virtualisation.docker.enable)
          || (cfg.provider == "podman" && config.virtualisation.podman.enable);
        message = "kernelcore.kubernetes.kind.provider = \"${cfg.provider}\" requires virtualisation.${cfg.provider}.enable = true.";
      }
    ];

    environment.systemPackages =
      with pkgs;
      [
        # Core
        kind
        kubectl
        kubernetes-helm
        kustomize

        # UX / productivity
        k9s # TUI cluster browser
        kubectx # kubectx + kubens
        stern # multi-pod log tailing
        kubecolor # kubectl with syntax color

        # CKA-relevant low-level tooling
        etcd # etcdctl: backup/restore, member list
        cri-tools # crictl: inspect containerd from inside nodes
        dive # container image layer analysis
        openssl # TLS/cert inspection (kubeadm PKI)
        jq
        yq-go
        kubeconform # validate manifests against the K8s schema

        # Helper scripts generated above
        kindlab-up
        kindlab-down
        kindlab-reset
        kindlab-status
        kindlab-load
        kindlab-help
      ]
      ++ cfg.extraPackages;

    environment.variables = optionalAttrs (cfg.provider == "podman") {
      KIND_EXPERIMENTAL_PROVIDER = "podman";
    };

    # Convenience aliases. mkDefault so a host that already defines these
    # (e.g. hosts/kernelcore uses plain `kubectl`) wins; the module only
    # fills in whatever the host hasn't set.
    environment.shellAliases = mkDefault {
      kgp = "kubecolor get pods";
      kgs = "kubecolor get svc";
      kgn = "kubecolor get nodes";
      kga = "kubecolor get all";
      kdp = "kubecolor describe pod";
      kns = "kubens";
      kctx = "kubectx";
    };
  };
}
