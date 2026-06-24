# kind + CKA Exam Prep Guide

> Companion to the `services.kind-lab` NixOS module
> ([`modules/containers/kind.nix`](../../modules/containers/kind.nix)).
> Target certification: **CKA — Certified Kubernetes Administrator**
> (curriculum 1.31). Hands-on material lives in `~/learn/kuber-labs/`.

---

## 1. What this gives you

The `kind-lab` module provisions a *disposable, multi-node* Kubernetes
cluster inside Docker so you can practice every CKA task on real `kubectl`,
real `etcd`, real `kubeadm`-style nodes — then throw it away and start clean.

| Layer | What you get |
|-------|--------------|
| Cluster | 1 (or HA/3) control-plane + N workers via `kind`, custom CIDRs, pinned k8s version |
| Networking | `ingress-nginx` auto-installed, host ports 80/443 mapped |
| Observability | `metrics-server` (patched for kind) → `kubectl top` works |
| Toolset | `kubectl`, `helm`, `kustomize`, `k9s`, `kubectx`/`kubens`, `stern`, `kubecolor`, `etcdctl`, `crictl`, `dive`, `kubeconform` |
| Helpers | `kindlab-up` / `-down` / `-reset` / `-status` / `-load` / `-help` |

> **kind vs k3s in this repo:** `services.k3s-cluster` is the *always-on*
> cluster meant for real workloads on real hardware. `services.kind-lab` is
> the *throwaway study* cluster. They can coexist — different kubeconfig
> contexts (`kind-cka-lab` vs the k3s context).

---

## 2. Quick start

```bash
# Module is enabled on the kernelcore host. After a rebuild:
kindlab-up        # create (or reattach to) the cluster
kindlab-status    # nodes / namespaces / pods overview
kubectl get nodes -o wide

# ... practice ...

kindlab-reset     # nuke + recreate from scratch (do this often!)
kindlab-down      # tear down when finished
```

To practice **Cluster Architecture** topics (etcd quorum, multi-master,
node failure), enable HA:

```nix
services.kind-lab = {
  enable = true;
  haControlPlane = true;   # 3 control-plane nodes + a load balancer
  workerCount = 3;
  kubernetesVersion = "v1.31.0";
};
```

You can also drive kind directly from the standalone flake in
`~/learn/kuber-labs/` (`nix develop` → auto-creates the cluster), which is
handy when you want a self-contained env outside the system config.

---

## 3. CKA curriculum coverage (1.31)

The CKA is **performance-based**: ~2 hours, a live terminal, ~15–20 tasks,
graded on the *end state* of the cluster (not on how you got there).
Passing score is **66%**. Domains and weights:

| # | Domain | Weight | Practice in this lab |
|---|--------|:------:|----------------------|
| 1 | **Cluster Architecture, Installation & Configuration** | 25% | `haControlPlane`, RBAC, kubeadm concepts, etcd backup/restore, Helm/Kustomize |
| 2 | **Workloads & Scheduling** | 15% | Deployments, rollouts, ConfigMaps/Secrets, taints/tolerations, affinity, HPA |
| 3 | **Services & Networking** | 20% | Services, Ingress (nginx pre-installed), NetworkPolicy, CoreDNS, Gateway API |
| 4 | **Storage** | 10% | PV/PVC, StorageClasses, dynamic provisioning, volume modes |
| 5 | **Troubleshooting** | 30% | Node/pod/control-plane failures, logs, events, `crictl`, network debug |

> ⚠️ The Linux Foundation revises the curriculum periodically. Always verify
> the **current** domains and weights at the official source before exam day:
> <https://github.com/cncf/curriculum> and the LF exam page. The numbers above
> match the 1.31 curriculum your `~/learn/CKA-StudyGuide/` is based on.

The labs in `~/learn/kuber-labs/labs/` are numbered to mirror these domains
(`01-*` … `05-*`), and the study tracker (§6) scores you per domain.

---

## 4. Exam-day muscle memory

These are the habits that win the CKA. Practice them until automatic.

### 4.1 Set up your shell first (every exam session)

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"   # generate manifests fast
export now="--force --grace-period=0"  # delete immediately
source <(kubectl completion bash)
complete -F __start_kubectl k
```

In the kind lab, `k`, `kgp`, `kgs`, `kgn`, `kdp`, `kns`, `kctx` are already
wired as shell aliases (via the module / the kuber-labs flake `shellHook`).

### 4.2 Always pin context + namespace

Every task switches you to a specific cluster/namespace. Burning points by
acting on the wrong one is the #1 avoidable mistake.

```bash
kubectl config use-context <ctx>                 # the task tells you which
kubectl config set-context --current --namespace=<ns>
```

### 4.3 Generate, don't type, YAML

```bash
k create deploy web --image=nginx --replicas=3 $do > web.yaml
k run tmp --image=busybox $do --command -- sleep 3600 > pod.yaml
k expose deploy web --port=80 $do > svc.yaml
k create job pi --image=perl $do -- perl -Mbignum=bpi -wle 'print bpi(200)' > job.yaml
```

### 4.4 Use the docs you're allowed

During the exam you may use `kubernetes.io/docs`, `/blog`, and `/training`.
Bookmark the YAML snippets you always forget (NetworkPolicy, PV, RBAC,
tolerations). Faster still: `kubectl explain <resource>.<field> --recursive`.

### 4.5 Vim for speed

```vim
" ~/.vimrc — paste this at the start of the exam
set number expandtab tabstop=2 shiftwidth=2
" YAML hates tabs; expandtab saves you from invisible indent errors
```

---

## 5. Domain cheat-paths

Quick reminders for the highest-value tasks. Full reference:
[`~/learn/kuber-labs/k8s-cheatsheet.md`](file:///home/kernelcore/learn/kuber-labs/k8s-cheatsheet.md).

### etcd backup & restore (Domain 1 — frequently tested)

```bash
# Snapshot (run on a control-plane node / where etcdctl can reach etcd)
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot.db -w table

# Restore to a new data dir, then point etcd's static pod at it
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot.db \
  --data-dir=/var/lib/etcd-restore
```

### RBAC (Domain 1)

```bash
k create sa builder
k create role pod-reader --verb=get,list,watch --resource=pods
k create rolebinding read-pods --role=pod-reader --serviceaccount=default:builder
k auth can-i list pods --as=system:serviceaccount:default:builder   # verify!
```

### NetworkPolicy (Domain 3) — default deny + allow

```bash
kubectl explain networkpolicy.spec --recursive | less   # when you blank
```

### Troubleshooting reflexes (Domain 3 — 30% of the exam)

```bash
k get events --sort-by=.lastTimestamp -A
k describe pod <pod>                 # Events section first
k logs <pod> --previous              # CrashLoopBackOff
crictl ps -a                         # when kubectl can't reach the node
journalctl -u kubelet -f             # kubelet down → node NotReady
```

---

## 6. Study tracker / game

`~/learn/kuber-labs/` ships a gamified CLI tracker (`cka-tracker`) to
*simulate learning and tally progress*:

- Marks labs done per domain, awards XP, levels you up.
- Spaced-repetition review queue so you revisit weak topics.
- **Exam-simulation mode**: a timed (2 h) run that mirrors the real CKA —
  weighted per domain, 66% to pass — and records your score history.

```bash
cka-tracker status          # dashboard: XP, level, per-domain mastery
cka-tracker labs            # list labs + completion state
cka-tracker done 03-services-clusterip
cka-tracker review          # today's spaced-repetition queue
cka-tracker exam            # start a timed mock exam
```

See `~/learn/kuber-labs/README.md` for the full tracker reference.

---

## 7. Final-week prep plan

You're in the last week. Stop learning new things; drill speed, accuracy, and
the gaps. The exam is 30% troubleshooting and rewards muscle memory.

### Know your environment's limits first

Read [`CKA-COVERAGE-MATRIX.md`](CKA-COVERAGE-MATRIX.md). The capabilities the
**local kind-lab cannot** practice by default, and how to handle them:

| Gap | Action this week |
|-----|------------------|
| **NetworkPolicy enforcement** | Set `services.kind-lab.cni = "calico"`, rebuild, redo lab `03-networkpolicy` until the `attacker` pod is actually blocked. |
| **kubeadm init/join/upgrade** | Can't be done here. Spend 2–3 Killercoda sessions on it; memorise the order in lab `01-kubeadm-upgrade`. |
| **Control-plane break-fix** | Killercoda "killer-shell-cka" scenarios — best source for these. |

### 7-day drill (adapt to your weak domains)

| Day | Focus (domain weight) | Do |
|-----|-----------------------|-----|
| 1 | Troubleshooting (30%) | All `05-*` labs; break things yourself in the kind node containers |
| 2 | Services & Networking (20%) | `03-*`; switch to `cni = "calico"` and prove NetworkPolicy enforcement |
| 3 | Architecture (25%) | `01-*`; etcd backup/restore until automatic; RBAC `auth can-i` reflex |
| 4 | kubeadm lifecycle | Killercoda upgrade scenarios; rehearse drain→upgrade→uncordon order |
| 5 | Workloads (15%) + Storage (10%) | `02-*`, `04-*`; rollouts, probes, PV/PVC, dynamic provisioning |
| 6 | **Full timed mock** | `cka-tracker exam` — 2h, no notes except kubernetes.io. Grade honestly. |
| 7 | Patch weak spots | Redo whatever the mock + tracker mastery bars show as red |

### Readiness checklist (target: pass 2 mocks ≥ 75%)

```bash
cka-tracker status          # every domain bar should be green
cka-tracker exam            # score ≥ 75% twice, comfortably inside 2h
```

- [ ] etcd snapshot save **and** restore without looking it up
- [ ] RBAC Role+Binding + `auth can-i` verify in < 2 min
- [ ] NetworkPolicy default-deny + selective-allow, **enforced** (Calico)
- [ ] kubeadm upgrade order recited from memory (drain → kubeadm → kubelet → uncordon)
- [ ] static pod created + deleted via the manifest dir
- [ ] PV/PVC bind + dynamic StorageClass
- [ ] node NotReady diagnosed via `journalctl -u kubelet`
- [ ] shell aliases + vim `expandtab` set reflexively at task start
- [ ] context/namespace switch before **every** task

### Exam-day logistics (verify, don't assume)

PSI/proctor environment, one browser tab of `kubernetes.io/docs` allowed,
fixed time. Confirm current rules on the Linux Foundation exam page before the
day — they change. Bookmark your weak-spot doc pages in advance.

---

## 8. Related material

- `~/learn/kuber-labs/` — flake devShell, manifests, structured `labs/`, tracker
- [`CKA-COVERAGE-MATRIX.md`](CKA-COVERAGE-MATRIX.md) — **what's practiceable vs gaps**, per capability, across kind-lab / k3s / Cilium
- `~/learn/CKA-StudyGuide/` — mkDocs revision topics + lab guide (domains 01–05)
- `~/learn/Anthropic-Cybersecurity-Skills/` — Kubernetes security skills (CKS-adjacent)
- [`modules/containers/kind.nix`](../../modules/containers/kind.nix) — the module (incl. `cni` option)
- [`modules/containers/k3s-cluster.nix`](../../modules/containers/k3s-cluster.nix) — real always-on cluster (k8s-node)
- [`modules/network/cilium-cni.nix`](../../modules/network/cilium-cni.nix) — Cilium CNI (NetworkPolicy enforcement, Hubble)
- [`profiles/k8s-lab.nix`](../../profiles/k8s-lab.nix) — host firewall/sysctl relaxations for local k8s
- Official curriculum: <https://github.com/cncf/curriculum> · Killercoda CKA: <https://killercoda.com/killer-shell-cka>
