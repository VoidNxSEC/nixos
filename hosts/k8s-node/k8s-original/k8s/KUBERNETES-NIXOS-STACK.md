# 🚀 KUBERNETES + NIXOS: STACK COMPLETA FORA DA CURVA

## 📊 VISÃO ARQUITETURAL

### A Filosofia da Integração
Integrar K8s no NixOS não é só instalar um cluster - é criar um **ecosystem declarativo** onde infraestrutura, aplicações e segurança convergem numa única fonte de verdade. Você vai operar em níveis que 95% dos DevOps não chegam.

```
┌─────────────────────────────────────────────────────────────┐
│                    DECLARATIVE LAYER                        │
│  /etc/nixos - Single Source of Truth                        │
│  ├── k8s-cluster/          (Cluster Definition)             │
│  ├── k8s-apps/             (GitOps Manifests)               │
│  ├── k8s-security/         (Policies + RBAC)                │
│  └── k8s-observability/    (Monitoring Stack)               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  KUBERNETES CONTROL PLANE                   │
│  • k3s (lightweight) OU kubeadm (production)                │
│  • Declaratively provisioned via Nix                        │
│  • Automated TLS + RBAC + NetworkPolicies                   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    WORKLOAD LAYER                           │
│  PHANTOM → ML Training Jobs (GPU scheduling)                │
│  SPECTRE → Sentiment Analysis Service                       │
│  OSWAKA  → SIEM Forensics Pipeline                          │
│  CEREBRO → RAG Knowledge System                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 STACK COMPONENTS (The Real Deal)

### 1. KUBERNETES DISTRIBUTION: k3s vs kubeadm

**K3S (RECOMENDADO pra começar)**
```nix
# modules/containers/k3s.nix
{ config, pkgs, lib, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";  # ou "agent" para workers
    
    # 🔥 TRICK: Disable traefik/servicelb se você quer controle total
    extraFlags = toString [
      "--disable=traefik"
      "--disable=servicelb"
      "--disable=local-storage"
      # Security hardening
      "--protect-kernel-defaults"
      "--secrets-encryption=true"
      # Networking
      "--flannel-backend=wireguard-native"  # 🚀 WireGuard native!
      "--kubelet-arg=max-pods=110"
    ];
    
    # Container runtime
    containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock";
    
    # Token management (use sops-nix)
    tokenFile = config.sops.secrets.k3s-token.path;
  };

  # Networking prerequisites
  networking.firewall.allowedTCPPorts = [ 
    6443  # K8s API
    10250 # Kubelet
  ];
  
  networking.firewall.allowedUDPPorts = [
    8472  # Flannel VXLAN
  ];

  # Container runtime
  virtualisation.containerd = {
    enable = true;
    settings = {
      version = 2;
      plugins."io.containerd.grpc.v1.cri" = {
        # GPU support para PHANTOM
        device_ownership_from_security_context = true;
      };
    };
  };
}
```

**KUBEADM (Para clusters multi-node production)**
```nix
# modules/containers/kubeadm.nix
{ config, pkgs, lib, ... }:
{
  services.kubernetes = {
    roles = [ "master" "node" ];
    
    masterAddress = "k8s-master.local";
    
    # Certificate management
    easyCerts = true;
    
    # API Server hardening
    apiserver = {
      securePort = 6443;
      advertiseAddress = "192.168.1.100";
      
      extraOpts = ''
        --anonymous-auth=false
        --audit-log-path=/var/log/kubernetes/audit.log
        --audit-log-maxage=30
        --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml
        --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
      '';
    };
    
    # Controller Manager
    controllerManager = {
      extraOpts = ''
        --terminated-pod-gc-threshold=100
        --node-cidr-mask-size=24
      '';
    };
  };
}
```

---

### 2. NETWORKING LAYER: CNI Choices

**Cilium (RECOMENDADO - eBPF beast)**
```yaml
# k8s-apps/cilium/values.nix.yaml
# Managed via Nix + Helm
ipam:
  mode: kubernetes

kubeProxyReplacement: strict  # 🔥 Replace kube-proxy completely

hubble:
  enabled: true
  relay:
    enabled: true
  ui:
    enabled: true  # Network observability UI

encryption:
  enabled: true
  type: wireguard  # Transparent pod-to-pod encryption

# Network Policies
policyEnforcementMode: always

# Security
enableRuntimeSecurity: true
```

**Implementação em Nix:**
```nix
# modules/network/cilium.nix
{ config, pkgs, lib, ... }:
{
  # Install Cilium CLI
  environment.systemPackages = with pkgs; [
    cilium-cli
    hubble
  ];

  # Helm chart deployment via Nix
  systemd.services.cilium-install = {
    description = "Install Cilium CNI";
    after = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      ${pkgs.cilium-cli}/bin/cilium install \
        --set encryption.enabled=true \
        --set encryption.type=wireguard
    '';
  };
}
```

---

### 3. STORAGE: PERSISTENT VOLUMES

**OpenEBS (Dynamic provisioning)**
```nix
# modules/containers/openebs.nix
{ config, pkgs, lib, ... }:
{
  # Prerequisites
  boot.supportedFilesystems = [ "iscsi" ];
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiator";
  };

  # Install OpenEBS via Helm
  systemd.services.openebs-install = {
    description = "Install OpenEBS Storage";
    after = [ "k3s.service" "cilium-install.service" ];
    wantedBy = [ "multi-user.target" ];
    
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      ${pkgs.kubernetes-helm}/bin/helm repo add openebs https://openebs.github.io/charts
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install openebs openebs/openebs \
        --namespace openebs --create-namespace \
        --set localprovisioner.enabled=true \
        --set ndm.enabled=true
    '';
  };
}
```

**Longhorn (CNCF graduated, user-friendly)**
```nix
# Alternative: Longhorn for easier management
systemd.services.longhorn-install = {
  script = ''
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    ${pkgs.kubectl}/bin/kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
  '';
};
```

---

### 4. INGRESS CONTROLLER: Traffic Management

**Traefik (Cloud-native, auto TLS)**
```nix
# modules/network/traefik-k8s.nix
{ config, pkgs, lib, ... }:
let
  traefikValues = pkgs.writeText "traefik-values.yaml" ''
    ingressClass:
      enabled: true
      isDefaultClass: true
    
    ports:
      web:
        port: 80
        redirectTo: websecure
      websecure:
        port: 443
        tls:
          enabled: true
    
    # Automatic HTTPS
    certResolver:
      letsencrypt:
        email: ${config.sops.secrets.email.path}
        storage: /data/acme.json
        tlsChallenge: true
    
    # Observability
    accessLog:
      enabled: true
    metrics:
      prometheus:
        enabled: true
  '';
in
{
  systemd.services.traefik-install = {
    description = "Install Traefik Ingress";
    after = [ "k3s.service" ];
    
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install traefik traefik/traefik \
        --namespace traefik --create-namespace \
        --values ${traefikValues}
    '';
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

### 5. OBSERVABILITY STACK: The Full Monty

**Prometheus + Grafana + Loki + Tempo**
```nix
# modules/services/k8s-observability.nix
{ config, pkgs, lib, ... }:
{
  systemd.services.kube-prometheus-stack = {
    description = "Install Observability Stack";
    after = [ "k3s.service" ];
    
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      
      # Add repos
      ${pkgs.kubernetes-helm}/bin/helm repo add prometheus-community \
        https://prometheus-community.github.io/helm-charts
      ${pkgs.kubernetes-helm}/bin/helm repo add grafana \
        https://grafana.github.io/helm-charts
      
      # Install kube-prometheus-stack (Prometheus + Grafana + AlertManager)
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install kube-prometheus \
        prometheus-community/kube-prometheus-stack \
        --namespace monitoring --create-namespace \
        --set prometheus.prometheusSpec.retention=30d \
        --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
        --set grafana.adminPassword=$(cat ${config.sops.secrets.grafana-password.path})
      
      # Install Loki (Log aggregation)
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install loki grafana/loki-stack \
        --namespace monitoring \
        --set grafana.enabled=false \
        --set loki.persistence.enabled=true \
        --set loki.persistence.size=20Gi
      
      # Install Tempo (Distributed tracing)
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install tempo grafana/tempo \
        --namespace monitoring \
        --set tempo.retention=720h
    '';
  };
}
```

**Custom Dashboards para teus projetos:**
```nix
# Custom Grafana dashboard ConfigMaps
environment.etc."k8s-dashboards/phantom-ml.json".source = 
  ./dashboards/phantom-ml-metrics.json;
environment.etc."k8s-dashboards/spectre-sentiment.json".source = 
  ./dashboards/spectre-analysis.json;
```

---

### 6. GITOPS: ArgoCD (The Right Way™)

```nix
# modules/services/argocd.nix
{ config, pkgs, lib, ... }:
{
  systemd.services.argocd-install = {
    description = "Install ArgoCD GitOps";
    after = [ "k3s.service" ];
    
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      
      # Install ArgoCD
      ${pkgs.kubectl}/bin/kubectl create namespace argocd --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
      ${pkgs.kubectl}/bin/kubectl apply -n argocd -f \
        https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
      
      # Patch for Ingress
      ${pkgs.kubectl}/bin/kubectl patch svc argocd-server -n argocd -p \
        '{"spec": {"type": "LoadBalancer"}}'
    '';
  };

  # ArgoCD CLI
  environment.systemPackages = [ pkgs.argocd ];
}
```

**Application-of-Applications Pattern:**
```yaml
# /etc/nixos/k8s-apps/apps-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/pina/nixos-k8s-manifests
    targetRevision: main
    path: applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

### 7. SECURITY HARDENING: Defense in Depth

**Pod Security Standards + OPA Gatekeeper**
```nix
# modules/security/k8s-policies.nix
{ config, pkgs, lib, ... }:
{
  systemd.services.opa-gatekeeper = {
    description = "Install OPA Gatekeeper";
    
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      
      # Install Gatekeeper
      ${pkgs.kubectl}/bin/kubectl apply -f \
        https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
      
      # Apply constraint templates
      ${pkgs.kubectl}/bin/kubectl apply -f /etc/nixos/k8s-security/constraints/
    '';
  };
  
  # Sample constraints
  environment.etc."k8s-security/constraints/deny-privileged.yaml".text = ''
    apiVersion: constraints.gatekeeper.sh/v1beta1
    kind: K8sPSPPrivilegedContainer
    metadata:
      name: deny-privileged-containers
    spec:
      match:
        kinds:
          - apiGroups: [""]
            kinds: ["Pod"]
  '';
}
```

**Falco (Runtime Security)**
```nix
# modules/security/falco.nix
{ config, pkgs, lib, ... }:
{
  systemd.services.falco-install = {
    script = ''
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install falco falcosecurity/falco \
        --namespace falco --create-namespace \
        --set ebpf.enabled=true \
        --set falcosidekick.enabled=true
    '';
  };
}
```

---

## 🛠️ INTEGRATION COM TEUS PROJETOS

### PHANTOM (ML Classifier Framework)
```yaml
# k8s-apps/phantom/deployment.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: phantom-training
spec:
  template:
    spec:
      containers:
      - name: phantom-trainer
        image: ghcr.io/pina/phantom:latest
        resources:
          limits:
            nvidia.com/gpu: 1  # GPU scheduling
        volumeMounts:
        - name: model-storage
          mountPath: /models
        - name: dataset
          mountPath: /data
      volumes:
      - name: model-storage
        persistentVolumeClaim:
          claimName: phantom-models-pvc
      - name: dataset
        hostPath:
          path: /mnt/datasets
      restartPolicy: OnFailure
      
      # Node affinity para GPU nodes
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: nvidia.com/gpu
                operator: Exists
```

### SPECTRE (Sentiment Analysis)
```yaml
# k8s-apps/spectre/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spectre-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: spectre
  template:
    metadata:
      labels:
        app: spectre
    spec:
      containers:
      - name: spectre
        image: ghcr.io/pina/spectre:latest
        ports:
        - containerPort: 8080
        env:
        - name: MODEL_PATH
          value: /models/sentiment-v2
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: spectre-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: spectre-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### CEREBRO (RAG Knowledge System)
```yaml
# k8s-apps/cerebro/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cerebro-vectordb
spec:
  serviceName: cerebro
  replicas: 3
  selector:
    matchLabels:
      app: cerebro
  template:
    metadata:
      labels:
        app: cerebro
    spec:
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        ports:
        - containerPort: 6333
        volumeMounts:
        - name: cerebro-data
          mountPath: /qdrant/storage
  volumeClaimTemplates:
  - metadata:
      name: cerebro-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

---

## 🚀 ADVANCED TRICKS & HACKS

### 1. **Kustomize Overlays (Multi-Environment)**
```nix
# Base + Overlays pattern
/etc/nixos/k8s-apps/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml (replicas: 1)
    ├── staging/
    │   └── kustomization.yaml (replicas: 2)
    └── production/
        └── kustomization.yaml (replicas: 5, HPA)
```

### 2. **Sealed Secrets (GitOps-safe secrets)**
```nix
# modules/security/sealed-secrets.nix
systemd.services.sealed-secrets = {
  script = ''
    ${pkgs.kubernetes-helm}/bin/helm upgrade --install sealed-secrets \
      sealed-secrets/sealed-secrets \
      --namespace kube-system
  '';
};

# Usage:
# echo -n mypassword | kubectl create secret generic mysecret \
#   --dry-run=client --from-file=password=/dev/stdin -o yaml | \
#   kubeseal -o yaml > mysealedsecret.yaml
```

### 3. **Custom Resource Definitions (CRDs)**
```yaml
# Extend K8s API para teus projetos
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: mlmodels.pina.dev
spec:
  group: pina.dev
  names:
    kind: MLModel
    plural: mlmodels
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              framework:
                type: string
              version:
                type: string
              gpuRequired:
                type: boolean
```

### 4. **Service Mesh (Istio - Optional mas powerful)**
```nix
# modules/network/istio.nix
systemd.services.istio-install = {
  script = ''
    ${pkgs.istioctl}/bin/istioctl install --set profile=demo -y
  '';
};
```

### 5. **External Secrets Operator (Integrate com SOPS)**
```nix
# modules/security/external-secrets.nix
systemd.services.external-secrets = {
  script = ''
    ${pkgs.kubernetes-helm}/bin/helm install external-secrets \
      external-secrets/external-secrets \
      -n external-secrets --create-namespace
  '';
};
```

---

## 📚 LEARNING PATH: Do Zero ao Hero

### Week 1: Foundation
- [ ] Deploy k3s single-node
- [ ] Install Cilium CNI
- [ ] Setup kubectl + k9s
- [ ] Deploy first app (nginx)

### Week 2: Storage & Networking
- [ ] Configure OpenEBS/Longhorn
- [ ] Setup Traefik Ingress
- [ ] Create PVCs and test persistence
- [ ] Configure NetworkPolicies

### Week 3: Observability
- [ ] Install Prometheus stack
- [ ] Configure Grafana dashboards
- [ ] Setup Loki for logs
- [ ] Create alerts

### Week 4: GitOps & Automation
- [ ] Deploy ArgoCD
- [ ] Migrate apps to GitOps
- [ ] Implement CI/CD pipeline
- [ ] Test rollback scenarios

### Week 5: Security Hardening
- [ ] OPA Gatekeeper policies
- [ ] Falco runtime security
- [ ] RBAC configuration
- [ ] Network segmentation

### Week 6: Production Ready
- [ ] Multi-node cluster
- [ ] HA configuration
- [ ] Backup/Restore strategy
- [ ] Disaster recovery plan

---

## 🎓 RECURSOS ESSENCIAIS

### Books
- **"Kubernetes in Action"** - Marko Lukša (Bible)
- **"Kubernetes Patterns"** - Bilgin Ibryam (Advanced)
- **"Production Kubernetes"** - Josh Rosso (Real-world)

### Labs & Practice
- **Killer.sh** - CKA/CKAD exam simulator
- **KodeKloud** - Hands-on labs
- **Katacoda** - Interactive scenarios

### Monitoring & Debugging
```bash
# Essential tools
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl top nodes
kubectl top pods -A
kubectl describe pod <pod-name>

# k9s (TUI Kubernetes manager)
k9s

# Stern (multi-pod log tailing)
stern <pod-prefix>

# Kubectx/Kubens (context/namespace switching)
kubectx
kubens monitoring
```

---

## 🔮 PRÓXIMOS PASSOS

1. **Start small**: k3s single-node + basic workload
2. **Iterate**: Add observability → GitOps → Security
3. **Scale**: Multi-node → HA → Multi-cluster
4. **Integrate**: Connect com teus projetos (PHANTOM, SPECTRE, etc)
5. **Document**: Create runbooks no teu repo
6. **Automate**: Everything via Nix modules

---

**Remember**: Kubernetes is a journey, not a destination. Cada layer que você adiciona, você entende melhor como orquestração funciona em escala. Com NixOS, você tem o poder de version control TUDO - desde o kernel até os manifestos K8s.

Bora começar pelo k3s básico e ir escalando? 🚀
