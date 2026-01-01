# NixOS Linux Master Skill - Resumo Executivo

## 🎯 Visão Geral

Skill projetada para domínio completo de NixOS/Linux com expertise em:
- Flakes avançados com auto-detecção e integração out-of-the-box
- Debugging excepcional (eBPF, namespaces, system tracing)
- Packaging universal e cross-compilation
- Security hardening enterprise-grade
- Problem-solving proativo e inovador

## 🚀 Características Principais

### 1. **Domínio Total de Flakes**
- Arquitetura multi-sistema com modularidade máxima
- Auto-detecção de linguagens (Rust, Go, Python, Node.js)
- Templates prontos para produção
- Overlays e módulos composáveis
- Zero-config packaging que descobre dependências automaticamente

### 2. **Debugging Fora da Curva**
- eBPF para tracing sem overhead
- Namespace isolation para reprodução de bugs
- Core dump analysis avançada
- Network debugging profundo (tcpdump, SSL/TLS)
- Binary analysis e reverse engineering

### 3. **Packaging Inovador**
- Wrapper universal que detecta build system
- Cross-compilation nativa
- Profile-Guided Optimization (PGO) + Link-Time Optimization (LTO)
- Binary patching automático
- Incremental builds com cache inteligente

### 4. **Security Enterprise**
- Kernel hardening com 30+ parâmetros
- AppArmor/SELinux profiles
- Container security (rootless, seccomp)
- Zero-trust architecture
- Runtime Application Self-Protection (RASP)

### 5. **Proatividade Nata**
A skill NÃO só responde - ela:
- Antecipa problemas antes de acontecerem
- Sugere otimizações arquiteturais
- Propõe melhorias de performance
- Identifica oportunidades de security hardening
- Faz brainstorming de soluções alternativas

## 📦 Conteúdo do Pacote

```
nixos-linux-master/
├── SKILL.md                           # Definição principal da skill
│   
├── references/                        # Documentação técnica profunda
│   ├── nix-flakes-patterns.md        # Padrões avançados de flakes
│   ├── linux-debug-cookbook.md       # Arsenal completo de debugging
│   ├── packaging-guide.md            # Técnicas avançadas de packaging
│   ├── security-hardening.md         # Implementações de segurança
│   └── git-workflow.md               # Workflows Git otimizados
│
├── scripts/                           # Ferramentas automatizadas
│   ├── nix-build-debug.sh            # Troubleshooting de builds
│   ├── flake-scaffold.sh             # Gerador de flakes avançados
│   └── system-analyzer.sh            # Diagnóstico de sistema
│
└── assets/
    └── flake-templates/               # Templates prontos
        └── smart-template.nix         # Flake com auto-detecção
```

## 🔥 Scripts Principais

### nix-build-debug.sh
Troubleshooter avançado que:
- Detecta padrões de erro automaticamente
- Verifica integridade do store
- Analisa tamanho de closure
- Modo interativo para debugging
- Gera relatórios detalhados

```bash
./scripts/nix-build-debug.sh check      # Diagnósticos
./scripts/nix-build-debug.sh build      # Build interativo
./scripts/nix-build-debug.sh analyze    # Análise de closure
./scripts/nix-build-debug.sh report     # Relatório completo
```

### flake-scaffold.sh
Gera estruturas de flakes production-ready:
- Dev environments multi-linguagem (Rust, Python, Node, Go)
- Organização modular (hosts, modules, packages, overlays)
- Integração com pre-commit hooks
- Suporte a Home Manager
- Rust overlay configurado

```bash
./scripts/flake-scaffold.sh meu-projeto
cd meu-projeto
nix develop .#rust      # Ou .#python, .#node, .#go
```

### system-analyzer.sh
Diagnóstico completo do sistema:
- Análise de recursos (CPU, memória, disco)
- Monitoramento de rede
- Análise de processos
- Health checks de serviços
- Auditoria de segurança
- Checks específicos de NixOS
- Recomendações automatizadas

```bash
./scripts/system-analyzer.sh full       # Análise completa
./scripts/system-analyzer.sh quick      # Overview rápido
./scripts/system-analyzer.sh security   # Audit de segurança
./scripts/system-analyzer.sh nixos      # Específico NixOS
```

## 💡 Filosofia da Skill

### Think Outside the Box
- Desafia suposições convencionais
- Explora abordagens alternativas
- Usa primitives do NixOS/Linux de forma criativa
- Não aceita limitações artificiais

### Proativo por Natureza
- Antecipa necessidades
- Sugere melhorias arquiteturais
- Identifica problemas potenciais
- Propõe otimizações continuamente

### Inovação Constante
- Abraça tecnologias emergentes
- Experimenta sem medo
- Otimiza agressivamente
- Automatiza tudo que for repetível

## 🎯 Quando a Skill é Acionada

Trigger automático quando:
- Trabalhar com configurações NixOS ou flakes
- Debuggar problemas complexos de Linux
- Construir ou empacotar software
- Implementar medidas de segurança
- Otimizar builds ou performance
- Projetar arquitetura de sistemas
- Precisar de soluções criativas/não-convencionais
- Querer sugestões proativas
- Explorar tecnologias cutting-edge

## 🔧 Integração com MCP Server

### Compatibilidade
- **Drop-in**: Todos os scripts funcionam standalone
- **Estruturada**: Output parseable e human-readable
- **Robusta**: Error handling em todos os níveis
- **Modular**: Fácil extensão e customização

### Setup Recomendado
1. Extrair o pacote no diretório de skills do MCP
2. Scripts disponíveis via PATH ou chamadas diretas
3. References carregadas on-demand pelo Claude
4. Integração automática via skill description

### Output Format
- Exit codes significativos para automação
- UTF-8 compatible em todo output
- JSON structured data onde aplicável
- Sem prompts interativos em modo automação

## 🚀 Quick Start Examples

### 1. Setup Rápido de Projeto
```bash
./scripts/flake-scaffold.sh meu-rust-app
cd meu-rust-app
nix develop  # Ambiente Rust pronto
```

### 2. Debug de Build Failure
```bash
./scripts/nix-build-debug.sh build .#meu-package
# Entra em modo debug interativo com diagnósticos
```

### 3. Health Check do Sistema
```bash
./scripts/system-analyzer.sh full
# Análise completa com recomendações
```

### 4. Criar Package Custom
```bash
# Consultar packaging-guide.md para patterns
nix develop
# Criar derivation usando wrappers universais
nix build .#meu-package
```

## 📊 Features Destacadas

### Auto-Detecção Inteligente
Detecta automaticamente linguagem do projeto e configura ambiente:
```nix
projectType = 
  if builtins.pathExists ./Cargo.toml then "rust"
  else if builtins.pathExists ./go.mod then "go"
  else "generic";
```

### Zero-Config Packaging
Derivations que descobrem dependências via:
- pkg-config scanning
- Manifest parsing (Cargo.toml, package.json, etc)
- AST analysis

### Cross-Compilation Nativa
Suporte first-class para múltiplas arquiteturas:
- ARM64/aarch64
- x86_64
- RISC-V (experimental)

### Optimization Agressiva
- Link-Time Optimization (LTO)
- Profile-Guided Optimization (PGO)
- Native CPU features (`-march=native`)
- Build caching inteligente

## 🎨 Estilo de Comunicação

A skill se comunica com:
- **Precisão técnica**: Terminologia exata, referências a docs
- **Proatividade**: "Você também pode considerar..."
- **Múltiplas soluções**: Trade-offs entre abordagens
- **Educacional**: Explica o *porquê*, não só o *como*
- **Confiante mas humilde**: Opiniões fortes com awareness de edge cases

## 📈 Próximos Passos

1. **Extrair o pacote**: `tar -xzf nixos-linux-master.tar.gz`
2. **Testar scripts**: Rodar `./scripts/system-analyzer.sh quick`
3. **Explorar references**: Ler markdown files em `references/`
4. **Integrar no MCP**: Colocar no diretório de skills
5. **Experimentar**: Criar novo projeto com flake-scaffold.sh

## 🤝 Filosofia de Uso

- **Experimente patterns avançados**
- **Combine técnicas criativamente**
- **Compartilhe descobertas**
- **Quebre limites**
- **Aprenda continuamente**

## 🔥 Diferenciais

1. **Não é só documentação**: Scripts funcionais e testados
2. **Não é genérica**: Otimizada para NixOS/Linux advanced use cases
3. **Não é reativa**: Sugere proativamente melhorias
4. **Não é conservadora**: Abraça soluções inovadoras
5. **Não é superficial**: Deep dive em cada tópico

---

**Construída para**: Desenvolvimento NixOS/Linux avançado, problem-solving inovador, e engenharia de sistemas proativa.

**Otimizada para**: Eficiência máxima, inovação contínua, e out-of-the-box thinking.

**Alinhada com**: Seu estilo de trabalho - dominando flakes, integrando tudo, debugando como ninja, e sempre um passo à frente.
