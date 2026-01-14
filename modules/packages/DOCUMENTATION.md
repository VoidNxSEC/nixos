# Package Management Module - Documentation Index

> **Índice completo de toda a documentação do módulo de gerenciamento de pacotes**

## 📚 Documentação Disponível

### 1. Visão Geral

- **[modules/packages/README.md](./README.md)** - Visão geral do módulo agregador de pacotes
  - Filosofia de design
  - Submódulos disponíveis
  - Quando usar vs nixpkgs
  - Exemplos práticos

### 2. deb-packages - Gestão de Pacotes .deb

#### Documentação Principal

- **[deb-packages/README.md](./deb-packages/README.md)** - Documentação técnica completa do módulo
  - Arquitetura detalhada
  - Componentes (default.nix, builder.nix, sandbox.nix, audit.nix)
  - Fluxo de funcionamento
  - Quick start
  - Troubleshooting

- **[/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md)** - Guia completo do usuário (26KB)
  - Tutorial passo-a-passo
  - Referência completa de opções
  - Modelo de segurança detalhado
  - Exemplos práticos
  - Best practices
  - Manutenção

#### Documentação de Configuração

- **[deb-packages/packages/README.md](./deb-packages/packages/README.md)** - Guia de configuração de pacotes
  - Como adicionar novos pacotes
  - Estrutura de configuração
  - Exemplos rápidos
  - Troubleshooting específico

- **[deb-packages/packages/example.nix](./deb-packages/packages/example.nix)** - Exemplos práticos
  - Pacote simples com URL
  - Pacote com Git LFS
  - Aplicação com sandbox estrito
  - Ferramenta de desenvolvimento

#### Documentação de Armazenamento

- **[deb-packages/storage/README.md](./deb-packages/storage/README.md)** - Guia de armazenamento
  - Configuração Git LFS
  - Workflow de adição de arquivos
  - URL vs Git LFS
  - Manutenção e limpeza

#### Script de Automação

- **[/etc/nixos/scripts/deb-add](/etc/nixos/scripts/deb-add)** - Script de automação
  - Uso: `deb-add --help`
  - Geração automática de configurações
  - Cálculo de SHA256
  - Integração com Git LFS

## 🎯 Documentação por Caso de Uso

### Iniciante - Primeiro Uso

1. Leia: [modules/packages/README.md](./README.md) - Visão geral
2. Leia: [deb-packages/README.md](./deb-packages/README.md#quick-start) - Quick Start
3. Use: `deb-add --help` - Para adicionar primeiro pacote
4. Leia: [deb-packages/packages/example.nix](./deb-packages/packages/example.nix) - Exemplos

### Usuário - Configuração Avançada

1. Referência: [DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md#configuration-reference) - Todas as opções
2. Exemplos: [deb-packages/packages/example.nix](./deb-packages/packages/example.nix) - Casos de uso
3. Segurança: [DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md#security-model) - Modelo de segurança

### Desenvolvedor - Entender Internamente

1. Arquitetura: [deb-packages/README.md](./deb-packages/README.md#componentes-principais) - Componentes
2. Código: [deb-packages/builder.nix](./deb-packages/builder.nix) - Sistema de build
3. Código: [deb-packages/sandbox.nix](./deb-packages/sandbox.nix) - Sandboxing
4. Código: [deb-packages/audit.nix](./deb-packages/audit.nix) - Auditoria

### Administrador - Manutenção e Monitoramento

1. Monitoramento: [deb-packages/README.md](./deb-packages/README.md#monitoramento) - Como monitorar
2. Manutenção: [DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md#maintenance) - Rotinas de manutenção
3. Troubleshooting: [DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md#troubleshooting) - Resolução de problemas

### DevOps - Integração CI/CD

1. Validação: [deb-packages/README.md](./deb-packages/README.md#troubleshooting) - Build e testes
2. Automação: [/etc/nixos/scripts/deb-add](/etc/nixos/scripts/deb-add) - Script para pipelines
3. Storage: [deb-packages/storage/README.md](./deb-packages/storage/README.md) - Git LFS workflow

## 📖 Documentação por Tópico

### Instalação e Configuração

- [Quick Start](./deb-packages/README.md#quick-start)
- [Ativação do Módulo](./README.md#ativação-do-módulo)
- [Configuração Básica](./deb-packages/packages/README.md#quick-start)

### Métodos de Build

- [FHS User Environment](./deb-packages/README.md#fhs-buildFHSUserEnv)
- [Native com patchelf](./deb-packages/README.md#native-patchelf)
- [Auto-detect](./deb-packages/README.md#auto-detect)

### Segurança

- [Modelo de Segurança](./deb-packages/README.md#segurança)
- [Sandboxing](./deb-packages/README.md#3-sandboxnix---isolamento-e-segurança)
- [Auditoria](./deb-packages/README.md#4-auditnix---auditoria-e-monitoramento)
- [Best Practices](./deb-packages/README.md#security-best-practices)

### Armazenamento

- [URL vs Git LFS](./deb-packages/storage/README.md#when-to-use-git-lfs-vs-urls)
- [Configuração Git LFS](./deb-packages/storage/README.md#setup-git-lfs)
- [Adicionando Arquivos](./deb-packages/storage/README.md#adding-deb-files)

### Monitoramento e Logs

- [Verificar Status](./deb-packages/README.md#verificar-status)
- [Audit Logs](./deb-packages/README.md#audit-logs)
- [Resource Usage](./deb-packages/README.md#resource-usage)

### Troubleshooting

- [Build Fails](./deb-packages/README.md#build-fails)
- [Runtime Errors](./deb-packages/README.md#runtime-errors)
- [Permission Issues](./deb-packages/README.md#permission-issues)
- [Problemas Comuns](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md#troubleshooting)

### Automação

- [Script deb-add](./deb-packages/packages/README.md#using-the-automation-script)
- [Geração Automática de Configs](/etc/nixos/scripts/deb-add)
- [Integração com Pipelines](./deb-packages/storage/README.md)

## 🔧 Referência Rápida

### Comandos Úteis

```bash
# Adicionar novo pacote
/etc/nixos/scripts/deb-add --name NOME --url URL

# Validar configuração
nix flake check

# Aplicar mudanças
sudo nixos-rebuild switch

# Ver status de um pacote
systemctl status deb-package-NOME

# Ver logs
journalctl -u deb-package-NOME -f

# Ver audit logs
ausearch -k deb_exec_NOME
```

### Arquivos Importantes

```
/etc/nixos/
├── modules/packages/
│   ├── README.md                          # Visão geral
│   ├── DOCUMENTATION.md                   # Este arquivo
│   └── deb-packages/
│       ├── README.md                      # Doc técnica
│       ├── default.nix                    # Módulo principal
│       ├── builder.nix                    # Build system
│       ├── sandbox.nix                    # Sandboxing
│       ├── audit.nix                      # Auditoria
│       ├── packages/
│       │   ├── README.md                  # Guia de configs
│       │   └── example.nix                # Exemplos
│       └── storage/
│           ├── README.md                  # Guia de storage
│           └── .gitattributes             # Git LFS config
├── scripts/
│   └── deb-add                            # Script de automação
└── docs/guides/
    └── DEB-PACKAGES-GUIDE.md              # Guia completo
```

### Logs e Cache

```
/var/log/deb-packages/           # Logs por pacote
/var/cache/deb-packages/         # Cache de builds
```

## 🚀 Workflows Comuns

### Workflow 1: Adicionar Pacote Público

```bash
# 1. Adicionar com script
deb-add --name chrome \
        --url https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
        --sandbox

# 2. Validar
nix flake check

# 3. Aplicar
sudo nixos-rebuild switch

# 4. Verificar
systemctl status deb-package-chrome
```

### Workflow 2: Adicionar Pacote Interno

```bash
# 1. Copiar .deb para storage
cp internal-tool.deb /etc/nixos/modules/packages/deb-packages/storage/

# 2. Gerar config com Git LFS
deb-add --name internal-tool \
        --deb /etc/nixos/modules/packages/deb-packages/storage/internal-tool.deb \
        --storage git-lfs \
        --audit-level verbose

# 3. Adicionar ao git
git add modules/packages/deb-packages/storage/internal-tool.deb
git add modules/packages/deb-packages/packages/internal-tool.nix

# 4. Commit
git commit -m "Add internal-tool package"

# 5. Rebuild
nix flake check && sudo nixos-rebuild switch
```

### Workflow 3: Atualizar Pacote

```bash
# 1. Obter novo hash
nix-prefetch-url https://example.com/new-version.deb

# 2. Atualizar configuração
# Editar: modules/packages/deb-packages/packages/NOME.nix
# Mudar: source.sha256 e/ou source.url

# 3. Rebuild
nix flake check && sudo nixos-rebuild switch

# 4. Verificar nova versão
NOME --version
```

### Workflow 4: Depuração de Problemas

```bash
# 1. Ver logs detalhados
journalctl -u deb-package-NOME -n 100

# 2. Verificar configuração
nixos-option kernelcore.packages.deb.packages.NOME

# 3. Build manual com trace
nix build .#nixosConfigurations.kernelcore.config.environment.systemPackages --show-trace

# 4. Testar extração
dpkg-deb -x /path/to/package.deb /tmp/test-extract
ls -la /tmp/test-extract

# 5. Verificar sandbox
bwrap --version
```

## 📝 Notas de Versão

### v1.0.0 (2025-11-03)

**Recursos Implementados**:
- ✅ Módulo deb-packages completo
- ✅ Builders: FHS, native, auto-detect
- ✅ Sandboxing com bubblewrap
- ✅ Auditoria multi-nível
- ✅ Limites de recursos systemd
- ✅ Script deb-add
- ✅ Suporte Git LFS
- ✅ Documentação completa

**Próximos Passos**:
- 🔜 Submódulo flatpak
- 🔜 Submódulo appimage
- 🔜 Dashboard de monitoramento
- 🔜 Auto-update de pacotes

## 🤝 Contribuindo

Se você adicionar documentação:

1. Adicione link neste arquivo (DOCUMENTATION.md)
2. Siga o formato markdown consistente
3. Inclua exemplos práticos
4. Mantenha TOC atualizado
5. Use português brasileiro

## 📧 Suporte

- **Issues**: Problemas técnicos
- **Documentação**: Para melhorias na documentação
- **Exemplos**: Compartilhe seus casos de uso

---

**Última Atualização**: 2025-11-03
**Versão**: 1.0.0
**Mantido por**: kernelcore
