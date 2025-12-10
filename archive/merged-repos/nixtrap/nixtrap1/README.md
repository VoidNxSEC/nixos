# 🚀 NixOS Cache Server - Solução Enterprise Completa

## 📦 Conteúdo deste Pacote

Solução **production-ready** para servidor de cache NixOS com:
- ✅ **Nix Flakes** - Configuração declarativa moderna e reproduzível
- ✅ **NixOS Modules** - Módulos reutilizáveis para cache, API e monitoramento
- ✅ Bootstrap automatizado com diagnóstico de hardware
- ✅ TLS/HTTPS configurado (nginx reverse proxy)
- ✅ API REST para métricas em tempo real
- ✅ Dashboard React/TypeScript moderno
- ✅ Monitoramento com Prometheus
- ✅ Documentação completa
- ✅ Scripts de manutenção

## 🆕 Instalação com Nix Flakes (Recomendado)

### Quick Start com Flakes

```bash
# Opção 1: Template mínimo (apenas cache server)
nix flake init -t github:yourusername/nixtrap#minimal

# Opção 2: Template completo (com monitoramento)
nix flake init -t github:yourusername/nixtrap#full

# Instalar
sudo nixos-install --flake .#cache-server
```

**📚 Guia Completo**: Veja [FLAKE-GUIDE.md](FLAKE-GUIDE.md) para instruções detalhadas

### Por que usar Flakes?

- ✅ **Reproduzível**: Mesma configuração, sempre
- ✅ **Modular**: Reutilize módulos em diferentes máquinas
- ✅ **Versionado**: Controle de versão de todas as dependências
- ✅ **Simples**: Templates prontos para usar
- ✅ **Moderno**: Padrão recomendado pela comunidade NixOS

---

## 📂 Estrutura do Projeto

```
nixtrap/
├── 📖 README.md (você está aqui)
├── 📖 FLAKE-GUIDE.md                  # Guia completo Nix Flakes
│
├── 🔧 flake.nix                       # Configuração Nix Flakes principal
├── ⚙️  configuration.nix               # Exemplo de configuração tradicional
│
├── 📦 modules/                         # NixOS Modules
│   ├── cache-server.nix               # Módulo do servidor de cache
│   ├── api-server.nix                 # Módulo da API REST
│   └── monitoring.nix                 # Módulo de monitoramento
│
├── 📋 templates/                       # Templates prontos
│   ├── minimal/                       # Setup mínimo
│   │   ├── flake.nix
│   │   └── README.md
│   └── full/                          # Setup completo
│       ├── flake.nix
│       └── README.md
│
├── 🚀 Bootstrap (método tradicional)
│   └── nixos-cache-bootstrap.sh       # Script de bootstrap
│
├── 🔌 API Server
│   ├── cache-api-server.sh            # Servidor de API REST
│   └── cache-api-server.service       # Systemd service
│
├── 🎨 Dashboard
│   ├── src/                           # Código React/TypeScript
│   ├── package.json                   # Dependências
│   ├── vite.config.ts                 # Configuração Vite
│   └── tsconfig.json                  # Configuração TypeScript
│
└── 📚 Documentação
    ├── README-COMPLETO.md             # Documentação detalhada
    ├── CHEATSHEET.sh                  # Comandos rápidos
    └── FILES.txt                      # Lista de arquivos
```

---

## 🎯 Quick Start

### Método 1: Nix Flakes (Recomendado) ⚡

```bash
# 1. Inicializar com template
nix flake init -t github:yourusername/nixtrap#full

# 2. Gerar configuração de hardware
nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 3. Editar flake.nix com suas configurações

# 4. Instalar
sudo nixos-install --flake .#cache-server

# 5. Reiniciar
reboot
```

**📚 Documentação completa**: [FLAKE-GUIDE.md](FLAKE-GUIDE.md)

---

### Método 2: Bootstrap Tradicional (5 minutos)

No NixOS Live ISO:

```bash
# Tornar root
sudo su

# Navegar até o diretório bootstrap
cd /caminho/para/nixos-cache-server/bootstrap

# Executar bootstrap
./nixos-cache-bootstrap.sh
```

**O que acontece:**
- ✅ Diagnóstico automático de hardware (CPU, RAM, Disco)
- ✅ Geração de chaves criptográficas para assinatura de cache
- ✅ Criação de certificados TLS auto-assinados
- ✅ Configuração NixOS otimizada para seu hardware
- ✅ Scripts de monitoramento e manutenção

**Resultado:** Arquivos prontos em `/etc/nixos/`

---

### 2️⃣ Instalar NixOS (10 minutos)

```bash
# Ver guia completo:
cat docs/CHEATSHEET.sh

# Ou seguir passos em:
cat docs/README-COMPLETO.md
```

**Resumo rápido:**
1. Particionar disco
2. Montar partições
3. Copiar configuração gerada pelo bootstrap
4. Instalar: `nixos-install`
5. Reiniciar

---

### 3️⃣ Configurar API Server (2 minutos)

Após reiniciar no sistema instalado:

```bash
# Copiar arquivos
sudo cp api-server/cache-api-server.sh /etc/nixos/scripts/
sudo cp api-server/cache-api-server.service /etc/systemd/system/

# Habilitar e iniciar
sudo systemctl daemon-reload
sudo systemctl enable --now cache-api-server

# Testar
curl http://localhost:8080/api/metrics | jq
```

---

### 4️⃣ Deploy Dashboard React (5 minutos)

```bash
# Entrar no diretório
cd dashboard/

# Instalar dependências
npm install

# Desenvolvimento (localhost)
npm run dev
# Acesse: http://localhost:3000

# Ou build para produção
npm run build
# Deploy: copiar dist/ para o servidor
```

---

## 🎨 Preview do Dashboard

O dashboard React mostra em tempo real:

- 📊 **Métricas do Sistema**: CPU, RAM, Disco, Rede
- 📈 **Gráficos Históricos**: Uso de CPU e Memória
- ⚙️ **Status dos Serviços**: nix-serve, nginx, prometheus
- 🌐 **Conexões de Rede**: Estabelecidas, aguardando, escutando
- 🔄 **Auto-refresh**: Atualização automática a cada 5 segundos

---

## 📚 Documentação

### Leia primeiro (essencial):
1. **[CHEATSHEET.sh](docs/CHEATSHEET.sh)** - Comandos rápidos para copiar/colar
2. **[README-COMPLETO.md](docs/README-COMPLETO.md)** - Guia detalhado completo

### Documentação Adicional:
- **Arquitetura**: Diagramas e explicações técnicas
- **Troubleshooting**: Soluções para problemas comuns
- **Configuração de Clientes**: Como conectar outras máquinas
- **Operação**: Comandos úteis do dia-a-dia
- **Customização**: Como adaptar para suas necessidades

---

## 🔐 Segurança

Esta solução inclui:

✅ **Cache Signing**: Assinaturas criptográficas para validar pacotes  
✅ **TLS/HTTPS**: Comunicação criptografada via nginx  
✅ **Firewall**: Regras restritivas (apenas porta 443)  
✅ **Service Hardening**: Isolamento com systemd  
✅ **Auto-signed Certs**: Para dev/staging (substitua por Let's Encrypt em produção)

**⚠️ IMPORTANTE**: Faça backup das chaves privadas!
```bash
/etc/nixos/scripts/backup-keys.sh
```

---

## 📊 Monitoramento

### Métricas disponíveis:

- **Prometheus**: `http://servidor:9090`
- **API REST**: `http://servidor:8080/api/metrics`
- **Node Exporter**: `http://servidor:9100/metrics`
- **Nginx Stats**: `http://servidor/nginx-metrics`

### Scripts de monitoramento:

```bash
# Monitor em tempo real (TUI)
/etc/nixos/scripts/monitor.sh

# Health check
/etc/nixos/scripts/health-check.sh
```

---

## 🛠️ Stack Tecnológico

### Backend:
- **NixOS** - Sistema operacional
- **nix-serve** - Servidor de cache binário
- **nginx** - Reverse proxy com TLS
- **Prometheus** - Métricas e observabilidade
- **Bash** - Scripts de automação

### Frontend:
- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool e dev server
- **Tailwind CSS** - Styling
- **Recharts** - Gráficos
- **SWR** - Data fetching
- **Lucide React** - Ícones

---

## 💡 Melhores Práticas Implementadas

✅ **Progressive Disclosure**: Começa simples, adiciona complexidade conforme necessário  
✅ **Hardware-Aware**: Configuração adaptada aos recursos disponíveis  
✅ **Security by Default**: Configurações seguras desde o início  
✅ **Observable**: Logs, métricas e health checks incluídos  
✅ **Resilient**: Auto-recovery, GC automático, limites de recursos  
✅ **Documented**: Comentários inline, README, cheatsheet  
✅ **Testable**: Scripts de verificação e health check

---

## 🚀 Próximos Passos

Após o setup inicial:

1. **Testar em cliente**: Configurar outra máquina NixOS para usar o cache
2. **Monitorar por 24h**: Observar uso de recursos com os scripts
3. **Backup das chaves**: Guardar em local seguro
4. **Let's Encrypt**: Substituir certificado auto-assinado (produção)
5. **Ajustar GC**: Adaptar política de garbage collection ao uso real
6. **Configurar alertas**: Email/Slack para problemas críticos

---

## 🤔 FAQ

**P: Quanto de RAM eu preciso?**  
R: Mínimo 4GB (recomendado 8GB+). O bootstrap detecta automaticamente e ajusta.

**P: Posso usar em produção?**  
R: Sim! Mas substitua o certificado auto-assinado por Let's Encrypt.

**P: E se meu hardware for muito limitado?**  
R: O sistema ajusta automaticamente. Para casos extremos, considere distributed builds.

**P: Funciona com NixOS unstable?**  
R: Sim! Testado com stable e unstable.

**P: Como atualizo o servidor?**  
R: `sudo nix-channel --update && sudo nixos-rebuild switch`

---

## 📝 Licença

MIT License - use livremente para projetos pessoais e comerciais.

---

## 🆘 Suporte e Recursos

- **Documentação NixOS**: https://nixos.org/manual/
- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **NixOS Wiki**: https://nixos.wiki/
- **Community**: https://discourse.nixos.org/

---

## 🎉 Começar Agora

```bash
# 1. Executar bootstrap
cd bootstrap/
sudo ./nixos-cache-bootstrap.sh

# 2. Ver próximos passos
cat ../docs/CHEATSHEET.sh

# 3. Documentação completa
cat ../docs/README-COMPLETO.md
```

---

**Desenvolvido com ❤️ para a comunidade NixOS**

*Solução enterprise-grade para caching, agora acessível para todos*

---

## 📸 Screenshots

### Dashboard React
```
╔═══════════════════════════════════════════════════════════╗
║  NixOS Cache Server Dashboard                             ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  [CPU: 12.3%]  [RAM: 45.2%]  [Disk: 34.1%]  [Store: 12GB] ║
║                                                           ║
║  📊 Gráficos de CPU e Memória (últimos 20 pontos)        ║
║  ⚙️  Status: nix-serve ✓  nginx ✓  prometheus ✓          ║
║  🌐 Conexões: 15 estabelecidas, 3 aguardando             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

### Monitor CLI
```
╔═══════════════════════════════════════════════════════════╗
║  NixOS Cache Server - Monitor em Tempo Real              ║
╚═══════════════════════════════════════════════════════════╝

=== CPU & Load ===
Load Average: 0.24 0.31 0.28
CPU: 12.3% usado

=== Memória ===
RAM: 3.6GB / 8GB (45% usado)

=== Disco ===
Root: 85GB / 250GB (34% usado)
Nix Store: 12GB

=== Serviços ===
✓ nix-serve: ATIVO
✓ nginx: ATIVO
✓ prometheus: ATIVO
```

---

**Pronto para começar? Execute o bootstrap e em minutos terá um cache server enterprise-grade rodando! 🚀**
