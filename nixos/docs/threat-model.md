# Threat Model — kernelcore NixOS

**Versão**: 1.0  
**Data**: 2026-06-29  
**Escopo**: Sistema NixOS em `/etc/nixos` (host `kernelcore`, Acer laptop)  
**Metodologia**: STRIDE por superfície + Risk Matrix (Probabilidade × Impacto)

---

## 1. Asset Inventory (Crown Jewels)

| Prioridade | Ativo | Localização | Impacto se comprometido |
|-----------|-------|-------------|-------------------------|
| P0 | Chaves SOPS / age keys | `/var/lib/sops-nix/key.txt` | Decripta TODOS os secrets |
| P0 | Secrets SOPS: blockchain, GCP, GitHub, AWS, K8s | `secrets/*.yaml` | Vazamento de credenciais críticas |
| P0 | SSH keys (host + user) | `/etc/ssh/`, `~/.ssh/` | Acesso remoto irrestrito |
| P1 | OAuth tokens MCP | `secrets/oauth/*.token.enc.json` | Acesso a serviços externos |
| P1 | Código-fonte + git history | Forgejo (3002) / gitea.voidnx.com | Exposição de IP, configs privadas |
| P1 | Ambiente de inferência ML | LLaMA :8081, Ollama :11434 | Abuso de recursos computacionais |
| P2 | Ambiente de desenvolvimento | code-server :8443, Jupyter :8888 | Execução de código arbitrário |
| P2 | Identidade Tailscale | `tailscale0` interface | Acesso ao Tailnet privado |

---

## 2. Adversary Profiles

### 2.1 Oportunista Externo
**Motivação**: Monetizar recursos — botnet, cryptomining, ransomware, revenda de acesso.  
**Capacidade**: Ferramentas automatizadas, exploits públicos, pouca sofisticação manual.  
**TTPs principais**:
- Port scan → explorar NGINX/SSH em versão vulnerável
- Credential stuffing em portas abertas
- Explorar serviços sem autenticação (Jupyter, Buildbot)
- Persistência via cron / systemd unit malicioso

**Vetor de entrada primário**: NGINX público (80/443), SSH (22), Mosh UDP (60000-61000).

---

### 2.2 Atacante Direcionado
**Motivação**: Secrets específicos (blockchain keys, GCP/AWS, tokens GitHub), IP de ML, acesso ao Tailnet.  
**Capacidade**: Reconhecimento manual, encadeamento de vulnerabilidades, paciência para lateral movement.  
**TTPs principais**:
- Comprometer dependency → escape do sandbox Nix → acesso ao host
- Comprometer SSH key de dispositivo secundário (iphone/glab) → pivot
- Explorar serviço sem auth (LLaMA Router) → reiniciar com config maliciosa → RCE
- Exfiltrar `/var/lib/sops-nix/key.txt` → decriptar todos os secrets offline

**Vetor de entrada primário**: Supply chain Nix/npm, SSH keys de dispositivos satélite, serviços ML sem auth.

---

### 2.3 Supply Chain
**Motivação**: Comprometer o sistema via dependência envenenada; instalar backdoor silencioso.  
**Capacidade**: Controle de um pacote upstream (Nix, npm, pip, Docker image).  
**TTPs principais**:
- Pacote npm/pip malicioso escapa sandbox via `/proc/self/fd` ou tmpfs compartilhado
- Derivação Nix substituída por hash idêntico (collision) com código extra
- Docker image com camada maliciosa nos containers ML
- GitHub Action comprometida no CI pipeline

**Vetor de entrada primário**: `npm` em Buildbot worker, `pip` em containers ML, flake inputs sem pin.

---

## 3. Análise STRIDE por Superfície

### 3.1 LLaMA Model Router `:8080` — RISCO CRÍTICO

Proxy Python sem autenticação. Expõe troca de modelo via POST e pode reiniciar o serviço `llamacpp-swap` via `subprocess`.

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Tampering** | POST /v1/* troca modelo ativo, reinicia serviço | Bind 127.0.0.1 | Qualquer processo local pode fazer swap |
| **Elevation** | Restart via subprocess executa como `llamacpp-swap` | User dedicado | Sem validação de origem da requisição |
| **Information** | GET /v1/models expõe paths de todos os modelos | — | Enumeração de filesystem via API |
| **Repudiation** | Sem log de qual cliente fez qual swap | journald via systemd | Logs não identificam PID/uid do chamador |
| **DoS** | Flood de swaps pode travar inferência por minutos | — | Sem rate limiting |

**Remediação**: Adicionar API key obrigatória no proxy Python + rate limiting de swap.

---

### 3.2 LLaMA.cpp SWAP `:8081` — RISCO ALTO

Backend de inferência com `--api-key` opcional (valor padrão: `null`).

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Spoofing** | Qualquer processo local é tratado como cliente legítimo | Bind 127.0.0.1 | `apiKey = null` por padrão |
| **Information** | `/v1/models` lista modelos carregados e metadados | — | Exige auth apenas se apiKey definida |
| **DoS** | Inferência cara em GPU/CPU pode ser abusada | `llamacpp-swap` user limits | Sem quota por cliente |

**Remediação**: Definir `apiKey` em SOPS e passar via `ExecStart`.

---

### 3.3 Buildbot Master `:8010` — RISCO ALTO

CI/CD sem autenticação documentada. Worker conecta em `:9989` (senha inline no código).

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Tampering** | Submissão de build malicioso via API | Bind 127.0.0.1 | Sem autenticação na web UI |
| **Elevation** | Build executa como `bbworker` com Docker/Podman | `bbworker` user | Docker group → fuga de container |
| **Information** | Logs de build podem conter secrets de ambiente | — | Sem sanitização de logs |
| **Repudiation** | Sem audit de quem trigou qual build | Buildbot DB local | DB não é centralizado |

**Remediação**: Habilitar autenticação Buildbot + mover senha do worker para SOPS.

---

### 3.4 Jupyter Lab (container `:8888`) — RISCO CRÍTICO

Execução de código Python/shell sem autenticação no container ML.

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Elevation** | Exec arbitrário de código como root no container | Rede privada 192.168.200.0/24 | Sem token/senha |
| **Tampering** | Escrever arquivos no volume montado do container | — | Sem controle de acesso |
| **Information** | Acesso a dados de treinamento/modelos no volume | — | Sem autenticação |

**Remediação**: Forçar `--NotebookApp.token` com valor do SOPS.

---

### 3.5 SSH `:22` — RISCO MÉDIO

Configuração hardened (key-only, no root, ED25519), mas com múltiplas chaves de dispositivos satélite.

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Spoofing** | Chave comprometida (iphone, glab) → acesso total | Key-only, no password | 3 authorized keys de dispositivos externos |
| **Information** | Acesso ao filesystem via shell | Imutable users | `/etc/nixos` acessível ao usuário logado |
| **DoS** | Brute force de chave (improvável, mas possível) | Rate limit: 4 conn/60s | — |

**Remediação**: Auditar e remover chaves não utilizadas; considerar 2FA para dispositivos satélite.

---

### 3.6 MCP Server (subprocess) — RISCO CRÍTICO

`securellm-mcp` roda como subprocess com `PROJECT_ROOT=~/master`. Acesso total de leitura/escrita ao projeto.

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Information** | Lê todos os arquivos de `~/master` (inclui configs, scripts) | Sem rede exposta | Sem controle granular por ferramenta |
| **Tampering** | Pode escrever arquivos no projeto | — | Sem whitelist de paths permitidos |
| **Elevation** | Pode executar ferramentas MCP com permissões do usuário kernelcore | — | Sem sandbox de processo |

**Remediação (parcial)**: Documentar quais ferramentas MCP têm acesso de escrita e restringir `PROJECT_ROOT` ao mínimo necessário.

---

### 3.7 Forgejo `:3002` / `gitea.voidnx.com` — RISCO MÉDIO

Git forge com credenciais SOPS. Exposto publicamente via NGINX com TLS.

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Spoofing** | Autenticação admin pode ser alvo de credential stuffing | SOPS + TLS | Registration desabilitada |
| **Information** | Repos públicos expõem código | TLS | Depende de configuração por repo |
| **Tampering** | Admin comprometido → push malicioso nos repos | SSH key + HTTPS | 2FA não documentada |

---

### 3.8 NGINX Público `:443` — RISCO BAIXO

Proxy reverso com TLS (Cloudflare DNS-01). Headers de segurança configurados (HSTS, CSP, X-Frame-Options).

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **DoS** | DDoS volumétrico | Firewall rate-limit | Sem upstream CDN/scrubbing |
| **Information** | Headers podem vazar info de backend | Security headers configurados | Verificar `Server:` header leaking |

---

### 3.9 DNS / AdGuard Home — RISCO MÉDIO (gap operacional)

Infraestrutura pronta (DNSSEC, Quad9, cache otimista), mas **blocklists vazias**.

| Ameaça | Descrição | Controle Atual | Gap |
|--------|-----------|----------------|-----|
| **Information** | Queries de malware passam sem bloqueio | DNSSEC ativo | `extraFilters = []` — zero blocklists |
| **Tampering** | DNS poisoning de queries não protegidas | DNSSEC valida respostas upstream | — |
| **DoS** | Resposta a domínios de C2 não bloqueada | Quad9 bloqueia alguns | Sem lista local customizada |

**Remediação**: Adicionar blocklists no `extraFilters` (abuse.ch URLhaus, EasyList, PhishTank).

---

## 4. Risk Matrix

| Serviço / Gap | Probabilidade | Impacto | Score | Prioridade |
|---------------|--------------|---------|-------|-----------|
| LLaMA Router sem auth (service restart) | Alta | Alto | 🔴 9 | P0 |
| Jupyter sem auth (code exec) | Alta | Alto | 🔴 9 | P0 |
| AdGuard blocklists vazias | Alta | Médio | 🟠 6 | P1 |
| LLaMA.cpp sem API key | Média | Médio | 🟠 6 | P1 |
| AIDE/ClamAV desabilitados | Média | Alto | 🟠 6 | P1 |
| Buildbot sem auth | Baixa (127.0.0.1) | Alto | 🟡 4 | P2 |
| SSH chaves satélite (iphone/glab) | Baixa | Alto | 🟡 4 | P2 |
| MCP sem controle granular | Baixa (local) | Médio | 🟢 3 | P3 |
| Mosh UDP aberto | Baixa | Médio | 🟢 3 | P3 |

*Score: 1=Baixo … 9=Crítico. Probabilidade × Impacto (1-3 cada).*

---

## 5. Controles Existentes (Efetividade)

| Controle | Adversário Coberto | Efetividade |
|----------|-------------------|-------------|
| Kernel lockdown=confidentiality | Direcionado, Supply Chain | ✅ Alta |
| Module blacklist (algif_aead, dccp…) | Direcionado | ✅ Alta |
| ASLR + memory poisoning | Direcionado | ✅ Alta |
| Firewall nftables + rate limiting | Oportunista | ✅ Alta |
| SSH key-only + immutable users | Oportunista | ✅ Alta |
| SOPS + age encryption | Todos | ✅ Alta |
| Nix sandbox + require-sigs | Supply Chain | ✅ Alta |
| DNSSEC | Oportunista | ✅ Alta (sem blocklists) |
| auditd + Suricata IDS | Direcionado | 🟡 Média (SOC configurado, não auditado) |
| AppArmor | Oportunista | 🟡 Média (perfis genéricos) |
| AIDE (FIM) | Todos | ❌ Desabilitado |
| ClamAV | Oportunista, Supply Chain | ❌ Desabilitado |
| AdGuard blocklists | Oportunista, Direcionado | ❌ Vazias |

---

## 6. Plano de Remediação

### Quick Wins (esta sessão)
- [ ] Habilitar AdGuard blocklists (`extraFilters` em `modules/network/dns/adguard-home.nix`)
- [ ] Habilitar AIDE (`kernelcore.security.aide.enable = true`)
- [ ] Habilitar ClamAV (`kernelcore.security.clamav.enable = true`)
- [ ] LLaMA Router: adicionar validação de API key obrigatória
- [ ] Jupyter container: forçar token de autenticação

### Backlog (próximas sessões)
- [ ] run0 (substituição segura de sudo sem SUID bit)
- [ ] argon2id no PAM (KDF mais forte)
- [ ] WireGuard kill switch (bloquear tráfego não-VPN)
- [ ] `allowed-uris` restrito no nix-daemon
- [ ] Logs remotos (rsyslog → servidor externo / SIEM)
- [ ] Auditoria de SSH keys satélite (iphone, glab)
- [ ] Senha do worker Buildbot mover para SOPS
- [ ] 2FA no SSH para dispositivos satélite

---

## 7. Referências de Controles

| Arquivo | Controle |
|---------|----------|
| `modules/security/kernel.nix` | Kernel params, module blacklist |
| `sec/hardening.nix` | Final overrides (mkForce) |
| `modules/network/security/firewall-zones.nix` | nftables zones |
| `modules/network/dns/adguard-home.nix` | DNS filtering |
| `modules/security/aide.nix` | File integrity monitoring |
| `modules/security/clamav.nix` | Antivirus |
| `modules/security/audit.nix` | auditd + AppArmor |
| `modules/security/soc/` | SOC stack (Wazuh, Suricata, Grafana) |
| `modules/ml/services/llama-model-router.nix` | LLaMA Router (gap de auth) |
| `modules/ml/services/llama-cpp-swap.nix` | LLaMA.cpp SWAP |
