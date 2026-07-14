# Secrets Structure Documentation

Mapeamento entre arquivos SOPS e módulos Nix.

## Estrutura Atual (Reorganizada 2026-01-08)

### Arquivos SOPS → Módulos Nix

| Arquivo SOPS | Módulo Nix | Status | Secrets |
|--------------|------------|--------|---------|
| `secrets/api-keys.yaml` | `modules/secrets/api-keys.nix` | ✅ | anthropic_api_key, openrouter_api_key, gemini_api_key, mistralai_api_key, deepseek_api_key, replicate_api_key |
| `secrets/gcp-ml.yaml` | `modules/secrets/gcp-ml.nix` | ✅ | GCP_PROJECT_ID, GCP_LOCATION |
| `secrets/github.yaml` | `modules/secrets/github.nix` | ✅ | github_token |
| `secrets/gitea.yaml` | `modules/secrets/gitea.nix` | ✅ | cloudflare-api-token, gitea-admin-token |
| `secrets/grok.yaml` | `modules/secrets/grok.nix` | ✅ | api_key_grok |
| `secrets/k8s.yaml` | `modules/secrets/k8s.nix` | ✅ | k3s-token |
| `secrets/tailscale.yaml` | `modules/secrets/tailscale.nix` | ✅ | tailscale-auth-key |
| `secrets/aws.yaml` | `modules/secrets/aws-bedrock.nix` | ✅ | AWS credentials |
| `secrets/api.yaml` | ❌ Não usado | Vazio | - |
| `secrets/database.yaml` | ❌ Não usado | Vazio | - |
| `secrets/prod.yaml` | ❌ Não usado | Vazio | - |
| `secrets/ssh.yaml` | ❌ Não usado | Vazio | - |
| `secrets/vertex.yaml` | ❌ Não usado | Vazio | - |
| `secrets/secrets.yaml` | ❌ Não usado | ? | - |

## Como Usar

### Enable secrets no configuration.nix

```nix
{
  # Enable SOPS (required)
  kernelcore.secrets.sops.enable = true;

  # Enable specific secret modules
  kernelcore.secrets.api-keys.enable = true;
  kernelcore.secrets.gcp-ml.enable = true;
  kernelcore.secrets.github.enable = true;
  kernelcore.secrets.k8s.enable = true;
}
```

### Acessar secrets em runtime

```bash
# Secrets são descriptografados em /run/secrets/
cat /run/secrets/anthropic_api_key
cat /run/secrets/GCP_PROJECT_ID

# Ou usar scripts helpers
source /etc/load-api-keys.sh
source /etc/load-gcp-ml.sh

# Verificar se secrets estão disponíveis
ls -la /run/secrets/
```

### Usar secrets em módulos

```nix
{
  # Example: usar GitHub token em serviço
  systemd.services.my-service = {
    environment = {
      GITHUB_TOKEN = config.sops.secrets.github_token.path;
    };
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.github_token.path;
    };
  };
}
```

## Princípios de Organização

1. **Um módulo por arquivo SOPS**: Cada `.yaml` em `/etc/nixos/secrets/` tem um `.nix` correspondente em `/etc/nixos/modules/secrets/`

2. **Naming consistente**:
   - SOPS file: `api-keys.yaml`
   - Module: `api-keys.nix`
   - Option: `kernelcore.secrets.api-keys.enable`

3. **Sem cross-references**: Cada módulo lê APENAS seu arquivo SOPS correspondente

4. **Owner/permissions corretos**:
   - User secrets: `owner = kernelcore`, `mode = "0440"`
   - System secrets: `owner = root`, `mode = "0400"`

## Validação

### Verificar que módulos estão corretos

```bash
# Check SOPS files
ls -1 /etc/nixos/secrets/*.yaml | xargs -I {} basename {} .yaml | sort

# Check modules
ls -1 /etc/nixos/modules/secrets/*.nix | grep -v default | xargs -I {} basename {} .nix | sort

# Compare (should match)
diff <(ls -1 /etc/nixos/secrets/*.yaml | xargs -I {} basename {} .yaml | sort) \
     <(ls -1 /etc/nixos/modules/secrets/*.nix | grep -v -E '(default|sops-config|anthropic)' | xargs -I {} basename {} .nix | sort)
```

### Test decrypt

```bash
# Test individual secrets
sops -d /etc/nixos/secrets/api-keys.yaml
sops -d /etc/nixos/secrets/gcp-ml.yaml

# After rebuild, check /run/secrets
sudo nixos-rebuild switch
ls -la /run/secrets/
```

## Troubleshooting

### Secret não aparece em /run/secrets

1. Verificar se módulo está enabled:
   ```nix
   kernelcore.secrets.api-keys.enable = true;
   ```

2. Verificar se arquivo SOPS existe:
   ```bash
   ls -la /etc/nixos/secrets/api-keys.yaml
   ```

3. Verificar se pode descriptografar:
   ```bash
   sops -d /etc/nixos/secrets/api-keys.yaml
   ```

4. Check systemd service:
   ```bash
   systemctl status sops-secrets
   journalctl -u sops-secrets
   ```

### Permission denied

- Verificar owner/group no módulo
- Verificar mode (0400, 0440, etc)
- User deve estar em group correto

### Module not found

- Verificar import em `modules/secrets/default.nix`
- Run `nix flake check` para validar sintaxe

## Migration Notes

**2026-01-08**: Reorganized secrets structure
- Separated `api-keys.nix` from `gcp-ml.nix`
- Created dedicated `github.nix` and `gitea.nix` modules
- Each module now reads ONLY from its corresponding SOPS file
- Updated `default.nix` with proper imports

## See Also

- `.sops.yaml` - SOPS configuration with encryption keys
- `modules/secrets/sops-config.nix` - SOPS integration module
- [SOPS-nix documentation](https://github.com/Mic92/sops-nix)
