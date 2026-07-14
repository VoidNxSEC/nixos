# SOPS-nix Troubleshooting Guide

## Arquitetura do SOPS-nix

```
┌─────────────────────────────────────────────────────────────┐
│ Fluxo de Criptografia/Descriptografia                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Criação/Edição de Secret                               │
│     sops secrets/github.yaml                               │
│     ↓                                                       │
│  2. SOPS lê .sops.yaml para saber qual chave usar          │
│     creation_rules: age176ca9a693ujm2d...                  │
│     ↓                                                       │
│  3. Criptografa com chave pública age                      │
│     (arquivo fica criptografado no repo)                   │
│     ↓                                                       │
│  4. Durante nixos-rebuild                                  │
│     sops-install-secrets roda                              │
│     ↓                                                       │
│  5. SOPS-nix busca chave privada                           │
│     sops.age.sshKeyPaths → /etc/ssh/ssh_host_ed25519_key  │
│     ↓                                                       │
│  6. Converte SSH key para age format                       │
│     ssh-to-age -private-key < ssh_host_ed25519_key         │
│     ↓                                                       │
│  7. Descriptografa e coloca em /run/secrets/               │
│     /run/secrets/github/runner/token                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Estrutura de Arquivos

```
/etc/nixos/
├── .sops.yaml                    # Regras de criptografia
├── secrets/
│   ├── github.yaml              # Secret criptografado
│   ├── api.yaml                 # Outros secrets
│   └── ...
├── flake.nix                     # Configuração sops.age.sshKeyPaths
└── modules/secrets/sops-config.nix

/etc/ssh/
├── ssh_host_ed25519_key         # Chave privada (usado pelo SOPS)
└── ssh_host_ed25519_key.pub     # Chave pública

/run/secrets/                     # Secrets descriptografados (runtime)
└── github/runner/token
```

## Comandos Essenciais

### 1. Verificar qual chave age o sistema está usando

```bash
# Extrair chave pública age da SSH host key
nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
# Output: age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn
```

### 2. Ver secrets descriptografados (requer chave privada)

```bash
# Ver conteúdo de um secret
sops -d secrets/github.yaml

# Editar um secret (descriptografa, abre editor, re-criptografa)
sops secrets/github.yaml
```

### 3. Verificar se um secret pode ser descriptografado

```bash
# Teste simples
sops -d secrets/github.yaml > /dev/null && echo "✓ Pode descriptografar" || echo "✗ Erro de descriptografia"
```

### 4. Ver quais chaves estão autorizadas em um secret

```bash
# Ver metadados do arquivo criptografado
sops -d --extract '["sops"]["age"]' secrets/github.yaml

# Ou inspecionar manualmente
grep "recipient:" secrets/github.yaml
```

---

## Cenários de Troubleshooting

### ❌ Erro: "0 successful groups required, got 0"

**Problema**: Secret está criptografado com uma chave diferente da que o sistema tem.

```
sops-install-secrets: failed to decrypt '/nix/store/.../github.yaml':
Error getting data key: 0 successful groups required, got 0
```

**Diagnóstico**:
```bash
# 1. Ver qual chave o sistema está tentando usar
sudo journalctl -u sops-install-secrets | grep "Imported.*age key"
# Output: age176ca9a...

# 2. Ver qual chave o secret foi criptografado
grep "recipient:" secrets/github.yaml
# Output: age1h0m5uwsjq... (diferente!)
```

**Solução**:
```bash
# 1. Atualizar .sops.yaml com a chave correta
vim .sops.yaml
# Trocar age: age1h0m5... por age: age176ca9a...

# 2. Re-criptografar o secret
sops updatekeys -y secrets/github.yaml

# 3. Verificar que foi re-criptografado corretamente
grep "recipient:" secrets/github.yaml
# Agora deve mostrar age176ca9a...

# 4. Rebuild
sudo nixos-rebuild switch
```

---

### ❌ Erro: "failed to create reader for decrypting"

**Problema**: SOPS não encontra a chave privada.

**Diagnóstico**:
```bash
# Verificar se chave SSH existe
ls -l /etc/ssh/ssh_host_ed25519_key
sudo cat /etc/ssh/ssh_host_ed25519_key | head -1
# Deve mostrar: -----BEGIN OPENSSH PRIVATE KEY-----

# Verificar configuração no flake
grep -A2 "sops.age" flake.nix
```

**Solução**:
```nix
# Adicionar no flake.nix, depois de sops-nix.nixosModules.sops
{
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
```

---

### 🔄 Criar um novo secret do zero

```bash
# 1. Verificar qual chave age usar
nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
# age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn

# 2. Criar/editar .sops.yaml (se necessário)
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: secrets/meu-novo-secret\.yaml$
    age: age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn
EOF

# 3. Criar o secret
sops secrets/meu-novo-secret.yaml

# No editor, adicione:
# api_key: "minha-chave-secreta"
# password: "minha-senha"
# Salve e feche

# 4. Verificar que foi criptografado
cat secrets/meu-novo-secret.yaml
# Deve mostrar conteúdo criptografado (ENC[AES256_GCM,...])

# 5. Configurar no NixOS
# Edite seu módulo .nix:
```

```nix
sops.secrets."meu-novo-secret/api_key" = {
  sopsFile = ../../secrets/meu-novo-secret.yaml;
  owner = "seu-usuario";
  group = "seu-grupo";
  mode = "0400";
};

# Usar no código:
config.sops.secrets."meu-novo-secret/api_key".path
# → /run/secrets/meu-novo-secret/api_key
```

---

### 🔑 Trocar para uma nova chave age dedicada

Se você quiser usar uma chave age dedicada em vez da SSH host key:

```bash
# 1. Gerar nova chave age
nix-shell -p age --run "age-keygen -o ~/.config/sops/age/keys.txt"
# public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 2. Copiar para diretório do sistema
sudo mkdir -p /var/lib/sops-nix
sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt

# 3. Atualizar .sops.yaml com a NOVA chave pública
vim .sops.yaml
# age: age1xxxx... (nova chave)

# 4. Re-criptografar TODOS os secrets
for file in secrets/*.yaml; do
  sops updatekeys -y "$file"
done

# 5. Atualizar flake.nix
# Trocar de:
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
# Para:
sops.age.keyFile = "/var/lib/sops-nix/key.txt";

# 6. Rebuild
sudo nixos-rebuild switch
```

---

### 📋 Adicionar múltiplas chaves (para backup/múltiplos hosts)

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn,
      age1anotherkey1234567890abcdefghijklmnopqrstuvwxyz1234567890ab,
      age1yetanotherkey098765432109876543210987654321098765432109876
```

Qualquer uma dessas chaves pode descriptografar os secrets.

---

### 🔍 Debug avançado

```bash
# Ver logs do sops-install-secrets
sudo journalctl -u sops-install-secrets.service -e

# Ver quais secrets estão disponíveis em runtime
ls -la /run/secrets/

# Testar se consegue ler um secret (como usuário correto)
sudo -u actions cat /run/secrets/github/runner/token

# Ver configuração SOPS no sistema após rebuild
nix-instantiate --eval -E '(import <nixpkgs/nixos> {}).config.sops'

# Rebuild com trace completo
sudo nixos-rebuild switch --show-trace
```

---

### 🚨 Perdi acesso aos secrets! E agora?

Se você perdeu a chave privada e os secrets estão inacessíveis:

**Opção 1**: Restaurar backup da chave privada
```bash
# Se você tem backup do /etc/ssh/ssh_host_ed25519_key
sudo cp backup/ssh_host_ed25519_key /etc/ssh/
sudo chmod 600 /etc/ssh/ssh_host_ed25519_key
```

**Opção 2**: Recriar secrets do zero
```bash
# 1. Gerar nova chave
nix-shell -p age --run "age-keygen -o /var/lib/sops-nix/key.txt"

# 2. Atualizar .sops.yaml com nova chave pública

# 3. DELETAR secrets antigos e criar novos
rm secrets/*.yaml
sops secrets/github.yaml
# Adicione os valores novamente manualmente
```

---

## Boas Práticas

### ✅ DO

- **Backup da chave privada**: Guarde cópia segura do `/etc/ssh/ssh_host_ed25519_key`
- **Commit do `.sops.yaml`**: Sempre versione no git
- **Commit dos secrets criptografados**: É seguro versionar `secrets/*.yaml`
- **Use múltiplas chaves**: Para disaster recovery
- **Teste descriptografia**: Antes de fazer commit, teste `sops -d`

### ❌ DON'T

- **NUNCA comite chaves privadas**: `/etc/ssh/ssh_host_ed25519_key`, `/var/lib/sops-nix/key.txt`
- **NUNCA comite secrets descriptografados**: Só commit arquivos criptografados
- **Não compartilhe chaves**: Gere chaves separadas para cada ambiente/host
- **Não use a mesma chave do GitHub**: SSH pessoal ≠ SSH host ≠ age key

---

## Referências Rápidas

### Estrutura de um secret YAML

```yaml
# secrets/github.yaml (descriptografado)
github:
  runner:
    token: "ghp_xxxxxxxxxxxxxxxxxxxx"
  api_key: "ghp_yyyyyyyyyyyyyyyyyyyy"

# secrets/github.yaml (criptografado - como fica no git)
github:
  runner:
    token: ENC[AES256_GCM,data:abc123...,iv:def456...,tag:ghi789...,type:str]
sops:
  age:
    - recipient: age176ca9a693ujm2d6fmqm6ezuwy0ka2fm39u5gu9tvr7njlzps6qhqqfnecn
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        ...
        -----END AGE ENCRYPTED FILE-----
```

### Configuração NixOS mínima

```nix
# flake.nix
{
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  outputs = { self, nixpkgs, sops-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        sops-nix.nixosModules.sops
        {
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

          sops.secrets."github/runner/token" = {
            sopsFile = ./secrets/github.yaml;
            owner = "actions";
            mode = "0400";
          };
        }
      ];
    };
  };
}
```

---

## Comandos de Emergência

```bash
# Reset completo do SOPS (CUIDADO: você perderá acesso aos secrets)
sudo rm -rf /run/secrets/*
sudo systemctl restart sops-nix.service

# Ver configuração ativa do SOPS
nix repl
:l <nixpkgs/nixos>
config.sops

# Forçar rebuild ignorando hooks
sudo nixos-rebuild switch --fast

# Rollback se algo der errado
sudo nixos-rebuild switch --rollback
```

---

## Checklist de Troubleshooting

- [ ] Chave pública age no `.sops.yaml` está correta?
- [ ] Secret foi re-criptografado após mudar `.sops.yaml`? (`sops updatekeys`)
- [ ] Chave privada existe em `/etc/ssh/ssh_host_ed25519_key`?
- [ ] `sops.age.sshKeyPaths` está configurado no `flake.nix`?
- [ ] Consegue descriptografar manualmente? (`sops -d secrets/github.yaml`)
- [ ] Permissões corretas? (`chmod 600 /etc/ssh/ssh_host_ed25519_key`)
- [ ] `sops-install-secrets.service` rodou com sucesso? (`systemctl status sops-install-secrets`)
- [ ] Secret está acessível em `/run/secrets/`?

---

## Troubleshooting por Erro Específico

| Erro | Causa Provável | Solução |
|------|----------------|---------|
| `0 successful groups required` | Chave errada no secret | `sops updatekeys` |
| `failed to create reader` | Chave privada não encontrada | Verificar `sops.age.sshKeyPaths` |
| `permission denied` | Permissões erradas no secret | Ajustar `owner`, `group`, `mode` |
| `no such file or directory` | Caminho errado em `sopsFile` | Verificar path relativo |
| `MAC verification failed` | Arquivo corrompido | Restaurar do git ou recriar |
| `syntax error` | YAML inválido | Verificar formatação YAML |

---

## Contato e Suporte

- **Documentação oficial**: https://github.com/Mic92/sops-nix
- **SOPS docs**: https://github.com/getsops/sops
- **Age docs**: https://age-encryption.org/

---

**Última atualização**: 2025-10-21
**Sistema**: NixOS 25.11
