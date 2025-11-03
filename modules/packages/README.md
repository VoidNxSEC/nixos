# Packages Module

> **Módulo agregador para diferentes sistemas de gerenciamento de pacotes no NixOS**

## Visão Geral

Este módulo serve como ponto central para integração de diferentes formatos de pacotes ao NixOS, mantendo a filosofia declarativa e de reproducibilidade do Nix.

## Estrutura

```
packages/
├── README.md          # Este arquivo
├── default.nix        # Agregador de módulos de pacotes
└── deb-packages/      # Sistema de gestão de .deb packages
    └── README.md      # Documentação completa do módulo .deb
```

## Submódulos Disponíveis

### 1. deb-packages/ - Gestão de Pacotes .deb

Sistema completo para integração declarativa de pacotes `.deb` no NixOS.

**Status**: ✅ Implementado e Testado

**Recursos**:
- Integração declarativa com Nix
- Múltiplos métodos de build (FHS, native, auto)
- Sandboxing com bubblewrap
- Auditoria completa de execuções
- Limites de recursos via systemd
- Storage híbrido (URL + Git LFS)
- Script de automação `deb-add`

**Documentação**: [deb-packages/README.md](./deb-packages/README.md)

**Uso rápido**:
```nix
kernelcore.packages.deb = {
  enable = true;
  packages = {
    my-tool = {
      enable = true;
      source.url = "https://example.com/tool.deb";
      source.sha256 = "sha256-...";
      sandbox.enable = true;
    };
  };
};
```

## Submódulos Futuros

### 2. flatpak/ - Gestão de Flatpaks (Planejado)

Integração declarativa de aplicações Flatpak.

**Status**: 🔜 Planejado

**Recursos planejados**:
- Declaração de remotes e aplicações
- Permissões granulares
- Versioning de aplicações
- Sandboxing nativo do Flatpak

### 3. appimage/ - Gestão de AppImages (Planejado)

Sistema para executar AppImages de forma controlada.

**Status**: 🔜 Planejado

**Recursos planejados**:
- Extração e cache de AppImages
- Sandboxing opcional
- Integração com desktop entries
- Verificação de checksums

### 4. snap/ - Gestão de Snaps (Em Consideração)

Integração opcional com Snapcraft.

**Status**: 🤔 Em Consideração

## Filosofia de Design

### Princípios

1. **Declarativo**: Toda configuração em Nix
2. **Seguro por Padrão**: Checksums, sandboxing, auditoria
3. **Reproducível**: Hashes obrigatórios, versões fixas
4. **Isolado**: Sandboxing e namespaces quando possível
5. **Rastreável**: Logs e auditoria de todas as operações
6. **Flexível**: Múltiplas opções de configuração

### Por Que Este Módulo Existe?

**Problema**: Às vezes precisamos de software que:
- Não está disponível no nixpkgs
- Está desatualizado no nixpkgs
- É proprietário e só distribuído como binário
- É interno/customizado da empresa

**Solução**: Integrar esses formatos de forma:
- Controlada (não quebra reproducibilidade)
- Segura (sandboxing, checksums)
- Declarativa (configuração em Nix)
- Auditável (tracking completo)

### Quando Usar vs nixpkgs

| Situação | Usar nixpkgs | Usar packages/ |
|----------|-------------|----------------|
| Pacote público e popular | ✅ | ❌ |
| Pacote atualizado em nixpkgs | ✅ | ❌ |
| Precisa versão específica antiga | ✅ (via override) | ⚠️ (se muito diferente) |
| Pacote não está em nixpkgs | ❌ | ✅ |
| Versão muito mais nova que nixpkgs | ❌ | ✅ |
| Software proprietário | ❌ | ✅ |
| Binário customizado/interno | ❌ | ✅ |
| Precisa isolamento extra | ⚠️ | ✅ |
| Teste rápido de software | ⚠️ | ✅ |

## Uso

### Ativação do Módulo

O módulo é automaticamente importado no flake.nix:

```nix
# flake.nix
modules = [
  ./modules/packages  # Importa default.nix deste diretório
  # ...
];
```

### Configuração

Cada submódulo tem seu próprio namespace:

```nix
# configuration.nix ou flake.nix
{
  # Pacotes .deb
  kernelcore.packages.deb = {
    enable = true;
    packages = { /* ... */ };
  };

  # Flatpak (futuro)
  # kernelcore.packages.flatpak = {
  #   enable = true;
  #   remotes = { /* ... */ };
  # };
}
```

## Estrutura de Arquivos

### default.nix - Agregador

```nix
{
  imports = [
    ./deb-packages      # Módulo .deb
    # ./flatpak         # Futuro
    # ./appimage        # Futuro
  ];
}
```

Este arquivo simplesmente importa todos os submódulos, permitindo que cada um seja ativado/desativado independentemente.

## Exemplos Práticos

### Exemplo 1: Ferramenta Proprietária

```nix
kernelcore.packages.deb = {
  enable = true;
  packages = {
    proprietary-tool = {
      enable = true;
      method = "fhs";
      source = {
        url = "https://vendor.com/tool.deb";
        sha256 = "sha256-...";
      };
      sandbox = {
        enable = true;
        blockHardware = ["gpu" "camera"];
        resourceLimits.memory = "2G";
      };
    };
  };
};
```

### Exemplo 2: Ferramenta Interna com Git LFS

```nix
kernelcore.packages.deb = {
  enable = true;
  packages = {
    internal-tool = {
      enable = true;
      source = {
        path = ./deb-packages/storage/internal-tool.deb;
        sha256 = "sha256-...";
      };
      audit = {
        enable = true;
        logLevel = "verbose";
      };
    };
  };
};
```

### Exemplo 3: Múltiplos Pacotes

```nix
kernelcore.packages.deb = {
  enable = true;
  packages = import ./packages/deb-packages/packages/company-tools.nix {};
};

# company-tools.nix contém múltiplas definições
```

## Monitoramento

### Ver Todos os Pacotes Gerenciados

```bash
# Listar services do systemd
systemctl list-units "deb-package-*"

# Ver logs agregados
journalctl -t "deb-package-*" -f
```

### Estatísticas

```bash
# Número de pacotes instalados
find /var/log/deb-packages -name "*.log" | wc -l

# Tamanho total do cache
du -sh /var/cache/deb-packages
```

## Troubleshooting

### Módulo Não Aparece nas Opções

Verifique se está importado no flake.nix:

```bash
# Verificar importação
grep -r "modules/packages" /etc/nixos/flake.nix

# Listar opções disponíveis
nixos-option kernelcore.packages
```

### Conflito Entre Submódulos

Cada submódulo deve ter seu próprio namespace (`deb`, `flatpak`, etc) para evitar conflitos.

## Desenvolvimento

### Adicionar Novo Submódulo

1. Criar diretório: `mkdir modules/packages/novo-formato/`
2. Criar módulo: `modules/packages/novo-formato/default.nix`
3. Importar em: `modules/packages/default.nix`
4. Documentar: `modules/packages/novo-formato/README.md`
5. Testar: `nix flake check`

### Estrutura Recomendada

```
modules/packages/novo-formato/
├── README.md           # Documentação completa
├── default.nix         # Módulo principal com opções
├── builder.nix         # Lógica de build (se aplicável)
├── sandbox.nix         # Configuração de isolamento (se aplicável)
└── examples/
    └── example.nix     # Exemplos de uso
```

## Contribuindo

Ao contribuir com este módulo:

1. **Documente tudo**: Cada submódulo precisa de README.md
2. **Siga o padrão**: Use estrutura similar ao deb-packages
3. **Segurança primeiro**: Implemente checksums e sandboxing
4. **Teste**: `nix flake check` deve passar
5. **Exemplos**: Forneça exemplos práticos

## Documentação

- **deb-packages**: [deb-packages/README.md](./deb-packages/README.md)
- **Guia Completo .deb**: [/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md](/etc/nixos/docs/guides/DEB-PACKAGES-GUIDE.md)

## Versão

**Versão**: 1.0.0
**Última Atualização**: 2025-11-03
**Autor**: kernelcore
