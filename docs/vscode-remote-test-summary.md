# VSCode Remote SSH - Correções Aplicadas e Teste

## 📋 Resumo das Correções

### Problema Inicial
```
Error: EACCES: permission denied, open '/etc/nix/builder_key'
Error: Timed out while waiting for handshake
```

### Causa Raiz
1. Extensão VSCode tentava ler `/etc/nix/builder_key` (root-only, 600 permissions)
2. Configuração SSH tinha referências a arquivo inacessível
3. User incorreto (`kernelcore` vs `cypher`)

### Arquivos Corrigidos

#### 1. `modules/system/ssh-config.nix`
```diff
# Desktop/Builder - General access (VSCode Remote SSH)
Host desktop
  HostName 192.168.15.7
- User kernelcore
+ User cypher
- IdentityFile ~/.ssh/id_ed25519
+ IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  Port 22
+ ForwardAgent yes
+ ForwardX11 yes
+ ServerAliveInterval 60

# Alternative alias for nix builds (use accessible key)
Host nix-desktop
  HostName 192.168.15.7
  User nix-builder
- IdentityFile /etc/nix/builder_key
+ IdentityFile ~/.ssh/nix-builder
```

#### 2. `modules/services/laptop-offload-client.nix`
```diff
- builderKeyPath = "/etc/nix/builder_key";
+ builderKeyPath = "/home/kernelcore/.ssh/nix-builder";
```

#### 3. `modules/services/laptop-builder-client.nix`
```diff
- default = "/etc/nix/builder_key";
+ default = "/home/kernelcore/.ssh/nix-builder";
```

## ✅ Verificações Concluídas

- [x] Nenhuma referência a `/etc/nix/builder_key` no SSH config
- [x] SSH direto funciona (`ssh desktop whoami` → `cypher`)
- [x] SSH handshake bem-sucedido
- [x] Comandos remotos funcionam
- [x] Pode criar `.vscode-server` directory no desktop
- [x] Bash, tar, gzip disponíveis no desktop
- [x] Permissões do home directory corretas

## ⚠️  Ponto de Atenção

**Node.js não está no PATH padrão do desktop**
- Disponível via: `nix-shell -p nodejs`
- VSCode pode precisar de configuração adicional

### Solução (se necessário):
Adicionar Node.js ao PATH do usuário `cypher` no desktop:
```bash
# No desktop, editar ~/.bashrc ou ~/.profile:
export PATH="$PATH:$(nix-env -q nodejs --out-path | cut -d' ' -f3)/bin"
```

## 🧪 Teste de Conexão VSCode

### Passo 1: Reiniciar VSCodium
```bash
# Matar processos VSCode existentes
pkill -f vscodium

# Iniciar VSCodium novamente
codium
```

### Passo 2: Conectar ao Desktop
1. Abrir VSCodium
2. Pressionar `Ctrl+Shift+P`
3. Digitar: `Remote-SSH: Connect to Host`
4. Selecionar: `desktop`
5. Aguardar conexão (pode demorar na primeira vez enquanto instala o server)

### Passo 3: Monitorar Logs (se houver problemas)
```bash
# Em outro terminal, monitorar logs do SSH:
journalctl -f | grep -i ssh

# Ou verificar logs do VSCode:
tail -f ~/.config/VSCodium/logs/*/output*.log
```

## 🐛 Se ainda houver problemas

### Teste Manual de Conexão
```bash
# Simular conexão do VSCode:
ssh desktop "bash -c 'echo Connected && uname -a'"
```

### Verificar Chaves SSH
```bash
# Listar chaves no SSH agent:
ssh-add -l

# Adicionar chave se necessário:
ssh-add ~/.ssh/id_ed25519
```

### Limpar Cache do VSCode
```bash
# Remover cache de extensão remote SSH:
rm -rf ~/.vscode-oss/extensions/jeanp413.open-remote-ssh-*/
rm -rf ~/.config/VSCodium/User/globalStorage/jeanp413.open-remote-ssh

# Reinstalar extensão no VSCode
```

### Adicionar Node.js ao PATH do Desktop (solução permanente)
```bash
# SSH para o desktop:
ssh desktop

# Adicionar ao ~/.bashrc do usuário cypher:
echo 'export PATH="$HOME/.nix-profile/bin:$PATH"' >> ~/.bashrc

# Instalar Node.js no perfil do usuário:
nix-env -iA nixos.nodejs

# Recarregar:
source ~/.bashrc

# Verificar:
node --version
```

## 📊 Status Atual

```
✅ SSH Config:       /etc/ssh/ssh_config - LIMPO
✅ Builder Keys:     ~/.ssh/nix-builder - ACESSÍVEL
✅ Desktop User:     cypher
✅ SSH Connection:   FUNCIONANDO
✅ Remote Commands:  FUNCIONANDO
⚠️  Node.js:         VIA NIX-SHELL (pode precisar PATH config)
```

## 🎯 Próximos Passos

1. **Reiniciar VSCodium**
2. **Tentar conectar via Remote SSH**
3. **Se falhar**: Adicionar Node.js ao PATH do desktop
4. **Reportar resultados**

---

**Script de Diagnóstico**: `/tmp/vscode-ssh-diagnostic.sh`
**Logs de Rebuild**: `/tmp/rebuild.log`
**Data**: 2025-11-27T03:42:00Z
