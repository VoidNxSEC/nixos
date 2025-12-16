# Declarative .deb Package Management Module

> **Módulo NixOS para gestão declarativa, segura e controlada de pacotes .deb**

## Visão Geral

Este módulo permite integrar pacotes `.deb` ao seu sistema NixOS de forma:

- **Declarativa**: Toda configuração em Nix
- **Segura**: Múltiplas camadas de segurança (checksum, sandbox, audit)
- **Controlada**: Limites de recursos e isolamento de hardware
- **Rastreável**: Auditoria completa de execuções
- **Flexível**: Múltiplos métodos de integração (FHS, native, auto)

## Estrutura do Módulo

```
deb-packages/
├── README.md              # Este arquivo - visão geral do módulo
├── default.nix            # Módulo principal com opções NixOS
├── builder.nix            # Funções de build (FHS, native, auto-detect)
├── sandbox.nix            # Configuração de sandboxing e isolamento
├── audit.nix              # Sistema de auditoria e monitoramento
├── packages/              # Definições de pacotes .deb
│   ├── README.md          # Guia de configuração de pacotes
│   └── example.nix        # Exemplos completos
└── storage/               # Armazenamento de .deb files (Git LFS)
    ├── README.md          # Guia de armazenamento
    └── .gitattributes     # Configuração Git LFS
```

## Componentes Principais

### 1. default.nix - Módulo Principal

Define toda a interface NixOS para o módulo:

- **Opções**: `kernelcore.packages.deb.*`
- **Tipos**: Definições de tipos para pacotes
- **Validação**: Assertions de segurança
- **Integração**: Exporta pacotes para `environment.systemPackages`

**Principais opções**:
- `enable`: Ativa o módulo
- `packages`: Attribute set de pacotes a gerenciar
- `auditByDefault`: Ativa audit logging por padrão
- `storageDir`: Diretório para armazenamento local
- `cacheDir`: Diretório de cache runtime

### 2. builder.nix - Sistema de Build

Funções para construir pacotes `.deb` de diferentes formas:

#### Métodos de Build:

**FHS (buildFHSUserEnv)**
- Para binários complexos com muitas dependências
- Cria ambiente FHS completo
- Suporta sandboxing com bubblewrap
- Ideal para: aplicações GUI, ferramentas complexas

**Native (patchelf)**
- Extrai e patcheia binários diretamente
- Integração nativa com Nix
- Mais leve que FHS
- Ideal para: ferramentas CLI simples, scripts

**Auto-detect**
- Analisa complexidade do pacote
- Escolhe automaticamente entre FHS e native
- Heurística: >10 bibliotecas → FHS, caso contrário → native

#### Funções principais:
- `fetchDeb`: Busca .deb de URL ou path local
- `extractDeb`: Extrai conteúdo do .deb
- `buildFHS`: Constrói com FHS user environment
- `buildNative`: Constrói com patchelf nativo
- `buildDebPackage`: Função principal de build

### 3. sandbox.nix - Isolamento e Segurança

Configurações de sandboxing usando bubblewrap e systemd:

#### Recursos:

**Isolamento de Namespace**
- User, IPC, PID, UTS, cgroup namespaces
- Filesystem isolado
- Capabilities dropped

**Bloqueio de Hardware**
- GPU (`/dev/nvidia*`, `/dev/dri`)
- Audio (`/dev/snd`)
- USB (`/dev/bus/usb`)
- Camera (`/dev/video*`)
- Bluetooth (`/dev/rfkill`)

**Limites de Recursos (systemd)**
- Memória: `MemoryMax`
- CPU: `CPUQuota`
- Tasks: `TasksMax`

**Systemd Hardening**
- System call filtering
- Device restrictions
- Filesystem protection
- Capability bounding

#### Perfis de Sandbox:
- `baseSandboxProfile`: Isolamento mínimo
- `strictSandboxProfile`: Isolamento máximo
- `devSandboxProfile`: Permissivo para desenvolvimento

### 4. audit.nix - Auditoria e Monitoramento

Sistema completo de logging e tracking:

#### Níveis de Auditoria:

**Minimal**
- Log apenas de execuções
- Baixo overhead

**Standard** (padrão)
- Execuções
- Acesso a arquivos
- Uso de recursos

**Verbose**
- Tudo do standard
- Syscalls monitored
- Tracking contínuo de recursos
- Timeline detalhada

#### Componentes:

**Wrapper de Auditoria**
- Intercepta execuções
- Coleta métricas
- Log estruturado

**Systemd Services**
- Service de rotação de logs
- Service de monitoramento (opcional)
- Timer para rotação diária

**Integração com Linux Audit**
- Regras do auditd por pacote
- Tracking de execve, open, unlink

**Logs**
- Diretório: `/var/log/deb-packages/`
- Rotação automática (>10MB)
- Mantém últimas 5 rotações
- Também loga no systemd journal

## Fluxo de Funcionamento

```
1. Configuração Nix
   ↓
2. Validação (SHA256, opções)
   ↓
3. Fetch .deb (URL ou local)
   ↓
4. Build (FHS/native/auto)
   ↓
5. Wrap com Sandbox (se ativo)
   ↓
6. Wrap com Audit (se ativo)
   ↓
7. Export para systemPackages
   ↓
8. Systemd Services criados
   ↓
9. Audit rules configuradas
```

## Quick Start

### 1. Ativar o Módulo

```nix
# Em flake.nix ou configuration.nix
kernelcore.packages.deb.enable = true;
```

### 2. Adicionar um Pacote

**Opção A: Script Automático**

```bash
/etc/nixos/scripts/deb-add \
  --name my-tool \
  --url https://example.com/my-tool.deb \
  --sandbox \
  --block-gpu \
  --memory 2G
```

**Opção B: Configuração Manual**

```nix
# modules/packages/deb-packages/packages/my-tool.nix
{
  my-tool = {
    enable = true;
    method = "auto";

    source = {
      url = "https://example.com/my-tool.deb";
      sha256 = "sha256-HASH";
    };

    sandbox = {
      enable = true;
      blockHardware = ["gpu"];
      resourceLimits.memory = "2G";
    };

    audit = {
      enable = true;
      logLevel = "standard";
    };
  };
}
```

### 3. Rebuild

```bash
nix flake check
sudo nixos-rebuild switch
```

## Segurança

### Multi-Layer Security Model

#### Camada 1: Checksum
- SHA256 obrigatório
- Validação em build-time
- Build falha se inválido

#### Camada 2: Sandbox (Bubblewrap)
- Isolamento de filesystem
- Namespace isolation
- Capability dropping
- Device blocking

#### Camada 3: Systemd
- Resource limits
- SecComp filtering
- Device restrictions
- Filesystem protection

#### Camada 4: Linux Audit
- Execution logging
- File access tracking
- Syscall monitoring

#### Camada 5: Application Monitoring
- Systemd journal
- Per-package logs
- Resource tracking

### Security Best Practices

1. **Sempre habilitar sandbox** para pacotes untrusted
2. **Usar perfil strict** para fontes desconhecidas
3. **Habilitar audit** para tracking
4. **Bloquear hardware desnecessário**
5. **Definir resource limits**
6. **Revisar logs regularmente**

## Monitoramento

### Verificar Status

```bash
# Status do systemd service
systemctl status deb-package-my-tool

# Logs em tempo real
journalctl -u deb-package-my-tool -f

# Log específico do pacote
tail -f /var/log/deb-packages/my-tool.log
```

### Audit Logs

```bash
# Buscar execuções
ausearch -k deb_exec_my-tool

# Buscar acesso a libs
ausearch -k deb_lib_my-tool
```

### Resource Usage

```bash
# CPU e memória
systemd-cgtop | grep deb-package

# Detalhes do service
systemctl show deb-package-my-tool
```

## Manutenção

### Atualizar Pacote

```bash
# 1. Obter novo hash
nix-prefetch-url https://example.com/new-version.deb

# 2. Atualizar sha256 na configuração

# 3. Rebuild
sudo nixos-rebuild switch
```

### Limpar Cache

```bash
# Limpar cache local
sudo rm -rf /var/cache/deb-packages/*

# Limpar Nix store
nix-collect-garbage -d
```

### Rotação de Logs

```bash
# Manual
systemctl start deb-package-my-tool-log-rotation

# Automática (configurada diariamente)
```

## Troubleshooting

### Build Fails

```bash
# Ver trace completo
nix flake check --show-trace

# Build isolado
nix build .#nixosConfigurations.kernelcore.config.environment.systemPackages --show-trace
```

### Runtime Errors

```bash
# Logs do systemd
journalctl -u deb-package-my-tool -n 100

# Verificar sandbox
bwrap --version

# Testar extração manual
dpkg-deb -x package.deb /tmp/test
```

### Permission Issues

```bash
# Verificar allowed paths
# Adicionar na configuração:
sandbox.allowedPaths = ["/path/needed"];
```

## Documentação Adicional

- **Guia Completo**: [DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md)
- **Exemplos**: [packages/example.nix](./packages/example.nix)
- **Package Config**: [packages/README.md](./packages/README.md)
- **Storage Guide**: [storage/README.md](./storage/README.md)
- **Script deb-add**: [/etc/nixos/scripts/deb-add](/etc/nixos/scripts/deb-add)

## Roadmap

### Futuras Melhorias

- [ ] Suporte a múltiplas arquiteturas (arm64, i686)
- [ ] Cache distribuído de pacotes
- [ ] Profiles pré-configurados (browser, dev-tool, etc)
- [ ] Integração com binary cache
- [ ] Dashboard de monitoramento
- [ ] Auto-update de pacotes
- [ ] Verificação de assinaturas GPG
- [ ] Suporte a outros formatos (AppImage, Flatpak)

## Contribuindo

Ao modificar este módulo:

1. Teste com `nix flake check`
2. Adicione exemplos na documentação
3. Atualize o CHANGELOG
4. Teste em VM antes de produção
5. Documente breaking changes

## License

Este módulo faz parte da configuração NixOS kernelcore.

**Autor**: kernelcore
**Criado**: 2025-11-03
**Versão**: 1.0.0
