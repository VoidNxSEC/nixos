# CKA Coverage & Gap Matrix

> **Purpose:** make every gap *loud*. For each CKA capability this says where you
> can actually practice it across the environments in this repo, and — when the
> local lab can't do it — exactly how to close the gap. If a thing isn't here,
> that itself is the signal to raise it.
>
> Verified against the configs in this repo (code, not docs) on 2026-06-24.
> Curriculum: **CKA 1.31**.

---

## The three environments

| Env | Where | CNI | Status (verified) | Role |
|-----|-------|-----|-------------------|------|
| **kind-lab** | `services.kind-lab` on **kernelcore** | kindnetd (default) **or** Calico (`cni = "calico"`) | **enabled** | Fast, disposable practice on your workstation |
| **k3s (real)** | `services.k3s-cluster` on **k8s-node** host | flannel (wireguard-native) + k3s's built-in NetworkPolicy controller | `enable = true` on k8s-node; **`false` on kernelcore** | Real always-on cluster ("nix root works with real clusters") |
| **Cilium** | `services.cilium-cni` module | Cilium eBPF (enforces NetworkPolicy + CiliumNetworkPolicy, Hubble) | **`enable = false` on every active host** | Available to switch on; not currently running |

> ⚠️ **Reality check for *this workstation* (kernelcore):** the only cluster
> running by default is **kind-lab**. k3s and Cilium are defined but **off**
> here. The real k3s cluster lives on the **k8s-node** host. Plan your drills
> around that: workstation = kind-lab; deep control-plane/CNI work = k8s-node or
> `kindlab` with `cni = "calico"`.

---

## Domain 1 — Cluster Architecture, Installation & Configuration (25%)

| Capability | kind-lab | k3s (k8s-node) | How / gap-closer |
|-----------|:--------:|:--------------:|------------------|
| RBAC (SA/Role/Binding, `auth can-i`) | ✅ | ✅ | lab `01-rbac-serviceaccount` |
| etcd snapshot save/restore | ✅* | ✅ | lab `01-etcd-backup-restore`. *kind: etcd is a static pod in the control-plane container (`docker exec`). |
| Static pods | ✅ | ✅ | lab `01-static-pods` (kind node container) |
| Multi-master / etcd quorum | ✅ | ⚠️ | `kindlab` `haControlPlane = true` (3 control-plane). k3s here is single-server. |
| **`kubeadm init/join/upgrade`** | ❌ | ❌ | **GAP** — kind uses kubeadm internally but isn't user-upgradeable; k3s isn't kubeadm. Drill the *procedure* in lab `01-kubeadm-upgrade`; practice for real on **Killercoda CKA scenarios** or a throwaway VM. |
| Helm / Kustomize | ✅ | ✅ | both `helm` + `kustomize` in the toolset |

## Domain 2 — Workloads & Scheduling (15%)

| Capability | kind-lab | k3s | How / gap-closer |
|-----------|:--------:|:---:|------------------|
| Deployments / rollout / rollback | ✅ | ✅ | lab `02-deployment-rollout` |
| ConfigMaps & Secrets | ✅ | ✅ | lab `02-configmap-secret` |
| Taints / tolerations / nodeSelector | ✅ | ✅ | lab `02-taints-tolerations` (kind gives you real multiple nodes) |
| Affinity / anti-affinity | ✅ | ✅ | lab `02-affinity-hpa` |
| **HPA (autoscaling)** | ✅ | ⚠️ | lab `02-affinity-hpa`. Needs **metrics-server** — kind-lab installs it automatically; on k3s you'd add it. |

## Domain 3 — Services & Networking (20%)

| Capability | kind-lab (kindnetd) | kind-lab (`cni=calico`) | k3s | How / gap-closer |
|-----------|:-------------------:|:-----------------------:|:---:|------------------|
| Services ClusterIP/NodePort | ✅ | ✅ | ✅ | lab `03-services` |
| Ingress | ✅ | ✅ | ✅* | lab `03-ingress`. kind-lab pre-installs ingress-nginx + maps :80/:443. *k3s here disables traefik. |
| CoreDNS / cluster DNS | ✅ | ✅ | ✅ | lab `03-coredns` |
| **NetworkPolicy — author/apply** | ✅ | ✅ | ✅ | the YAML is gradeable anywhere |
| **NetworkPolicy — ENFORCEMENT** | ❌ | ✅ | ✅ | **GAP on default kind-lab.** kindnetd silently ignores policies. **Close it:** set `services.kind-lab.cni = "calico"` (auto-installs Calico) — then lab `03-networkpolicy` actually blocks traffic. k3s also enforces (built-in NetworkPolicy controller). |
| Gateway API / CiliumNetworkPolicy | ❌ | ⚠️ | ❌ | Beyond core CKA. Needs Cilium (`services.cilium-cni.enable = true`) — available but currently off. |

## Domain 4 — Storage (10%)

| Capability | kind-lab | k3s | How / gap-closer |
|-----------|:--------:|:---:|------------------|
| Static PV + PVC + mount | ✅ | ✅ | lab `04-pv-pvc` (hostPath) |
| StorageClass / dynamic provisioning | ✅ | ✅ | lab `04-storageclass-dynamic`. kind ships `standard` (rancher local-path); k3s ships local-path too (here `local-storage` is disabled, so add one). |
| `WaitForFirstConsumer` binding | ✅ | ✅ | covered in lab `04-storageclass-dynamic` |
| Distributed / RWX storage (Longhorn) | ❌ | ⚠️ | Not core CKA. `services.longhorn-storage` module exists (disabled). |

## Domain 5 — Troubleshooting (30% — the biggest slice)

| Capability | kind-lab | k3s | How / gap-closer |
|-----------|:--------:|:---:|------------------|
| Pod failures (CrashLoop/ImagePull) | ✅ | ✅ | lab `05-broken-pod` |
| Service / endpoint / selector debug | ✅ | ✅ | lab `05-service-no-endpoints` |
| Node NotReady / kubelet | ✅ | ✅ | lab `05-node-notready` (stop kubelet in the kind node container) |
| `crictl` runtime inspection | ✅ | ✅ | `crictl` in toolset; kind uses containerd |
| **Control-plane component failure** | ⚠️ | ⚠️ | Practiceable by breaking a static-pod manifest in the kind control-plane container; not a packaged lab yet. Best drilled on Killercoda. |
| Network/CNI-level debug (drops) | ⚠️ | ⚠️ | Meaningful only with an enforcing CNI — use `cni = "calico"` or Cilium+Hubble (`services.cilium-cni`). |

---

## Open gaps to be aware of (final-week priorities)

1. **NetworkPolicy enforcement** — default kind-lab can't. → `cni = "calico"`. *(closeable here)*
2. **kubeadm cluster lifecycle (init/join/upgrade)** — no env in this repo does real kubeadm. → study lab `01-kubeadm-upgrade` for the procedure, do hands-on on **Killercoda / a VM**. *(external)*
3. **Control-plane component troubleshooting** — doable by hand in the kind control-plane container, but no packaged scenario. → Killercoda has the best break-fix scenarios.
4. **Cilium/Hubble & advanced networking** — module exists but disabled everywhere. → `services.cilium-cni.enable = true` if you want eBPF/Hubble practice (beyond core CKA).

> **Legend:** ✅ practiceable · ⚠️ partial / needs a toggle · ❌ not here (gap).

## See also

- [`KIND-CKA-EXAM-GUIDE.md`](KIND-CKA-EXAM-GUIDE.md) — exam-day tips + final-week plan
- [`../../modules/containers/kind.nix`](../../modules/containers/kind.nix) — `services.kind-lab` (incl. `cni` option)
- [`../../modules/containers/k3s-cluster.nix`](../../modules/containers/k3s-cluster.nix) — real k3s cluster
- [`../../modules/network/cilium-cni.nix`](../../modules/network/cilium-cni.nix) — Cilium CNI (enforcing, Hubble)
- `~/learn/kuber-labs/labs/` — the hands-on labs referenced above
- Killercoda CKA: <https://killercoda.com/killer-shell-cka> · CNCF curriculum: <https://github.com/cncf/curriculum>
