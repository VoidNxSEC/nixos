# SecureLLM Bridge - Guia Completo do Projeto

## 📋 Visão Geral

O **SecureLLM Bridge** é uma solução completa e segura para comunicação com modelos de linguagem (LLMs), focada em:

- **Segurança por padrão**: Todas as comunicações são criptografadas e validadas
- **Isolamento máximo**: Sandboxing e proteção de dados sensíveis
- **Suporte multi-provider**: DeepSeek, OpenAI, Anthropic, Ollama e outros
- **Flexibilidade**: Desktop, CLI, containers e biblioteca Rust

## 🏗️ Arquitetura

### Estrutura do Projeto

```
secure-llm-bridge/
├── crates/
│   ├── core/           # Biblioteca principal com abstrações
│   │   ├── request.rs  # Gestão de requisições com validação
│   │   ├── response.rs # Processamento de respostas
│   │   ├── error.rs    # Sistema de erros tipado
│   │   └── audit.rs    # Sistema de auditoria
│   │
│   ├── security/       # Primitivos de segurança
│   │   ├── tls.rs      # Autenticação mútua TLS
│   │   ├── crypto.rs   # Criptografia AES-256-GCM
│   │   ├── secrets.rs  # Gestão segura de secrets
│   │   └── sandbox.rs  # Isolamento de execução
│   │
│   ├── providers/      # Implementações de providers
│   │   ├── deepseek.rs # ✅ Implementado (completo)
│   │   ├── openai.rs   # 🚧 Placeholder
│   │   ├── anthropic.rs# 🚧 Placeholder
│   │   └── ollama.rs   # 🚧 Placeholder (local)
│   │
│   ├── cli/            # Interface de linha de comando
│   ├── desktop/        # 🚧 Aplicação desktop (futuro)
│   └── proxy/          # 🚧 Servidor proxy HTTP/S (futuro)
│
├── containers/         # Dockerfiles e compose
├── nix/                # Configuração NixOS
├── examples/           # Exemplos de uso
└── docs/               # Documentação adicional
```

## 🚀 Como Começar

### Pré-requisitos

#### Método 1: Usando Cargo (Rust)

```bash
# Instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clonar o repositório
git clone https://github.com/securellm/bridge.git
cd secure-llm-bridge

# Build
cargo build --release

# Instalar globalmente (opcional)
cargo install --path crates/cli
```

#### Método 2: Usando Nix (NixOS/Nix)

```bash
# Com flakes habilitado
nix build
nix run

# Entrar no ambiente de desenvolvimento
nix develop

# Para usuários NixOS - adicione ao configuration.nix:
services.securellm = {
  enable = true;
  configFile = /etc/securellm/config.toml;
};
```

#### Método 3: Usando Docker

```bash
# Build da imagem
docker build -t securellm:latest .

# Ou usar Alpine (mais leve)
docker build -f containers/Dockerfile.alpine -t securellm:alpine .

# Executar
docker run --rm securellm:latest --help
```

## 💡 Uso Básico

### CLI - Linha de Comando

```bash
# Configurar API key
export SECURELLM_API_KEY="your-deepseek-api-key"

# Chat simples
securellm chat \
  --provider deepseek \
  --model deepseek-chat \
  "Explique computação quântica de forma simples"

# Com system prompt
securellm chat \
  --provider deepseek \
  --model deepseek-chat \
  --system "Você é um assistente de programação" \
  "Escreva uma função para calcular fibonacci"

# Personalizar parâmetros
securellm chat \
  --provider deepseek \
  --model deepseek-coder \
  --max-tokens 2000 \
  --temperature 0.3 \
  "Otimize este código Rust: ..."

# Health check
securellm health deepseek

# Listar modelos disponíveis
securellm models deepseek

# Ver capacidades do provider
securellm info deepseek
```

### API Rust

```rust
use securellm_core::*;
use securellm_providers::deepseek::{DeepSeekConfig, DeepSeekProvider};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Configurar provider
    let config = DeepSeekConfig::new(std::env::var("SECURELLM_API_KEY")?)
        .with_timeout(Duration::from_secs(60))
        .with_logging(true);
    
    let provider = DeepSeekProvider::new(config)?;
    
    // Criar requisição
    let request = Request::new("deepseek", "deepseek-chat")
        .with_system("Você é um assistente útil")
        .add_message(Message {
            role: MessageRole::User,
            content: MessageContent::Text("O que é Rust?".to_string()),
            name: None,
            metadata: None,
        })
        .with_max_tokens(500)
        .mark_sensitive(); // Para dados sensíveis
    
    // Enviar requisição
    let response = provider.send_request(request).await?;
    
    // Processar resposta
    println!("Resposta: {}", response.text()?);
    println!("Tokens usados: {}", response.usage.total_tokens);
    
    Ok(())
}
```

## 🔒 Segurança

### Níveis de Segurança

```rust
// Configuração em config.toml
[security]
security_level = "Critical"  # Low, Medium, High, Critical

# Critical: TLS mútuo, criptografia end-to-end, audit completo
# High: TLS, rate limiting, audit
# Medium: TLS opcional, basic audit
# Low: Apenas para desenvolvimento
```

### TLS Mútuo (Production)

```toml
[security]
tls_enabled = true
security_level = "Critical"

[tls]
ca_cert = "/path/to/ca.pem"
client_cert = "/path/to/client.pem"
client_key = "/path/to/client-key.pem"
verify_peer = true
```

### Gestão de Secrets

```bash
# Nunca hardcode API keys!

# Método 1: Variável de ambiente
export SECURELLM_API_KEY="your-key"

# Método 2: Arquivo de config protegido
chmod 600 ~/.config/securellm/secrets.toml

# Método 3: Sistema keyring (em desenvolvimento)
```

### Proteção de Dados Sensíveis

```rust
let request = Request::new("deepseek", "model")
    .mark_sensitive()  // Ativa proteções extras
    .with_caller_id("user-123")  // Para audit trail
    .add_message(...);
```

## 📊 Auditoria e Monitoramento

### Configuração de Audit

```toml
[audit]
enabled = true
log_requests = true
log_responses = false  # Apenas se necessário (pode conter dados sensíveis)
retention_days = 90
database_path = "/var/lib/securellm/audit.db"
```

### Eventos de Segurança

O sistema automaticamente loga:
- Falhas de autenticação
- Violações de rate limit
- Erros TLS
- Requisições com dados sensíveis
- Padrões de acesso incomuns

## 🐳 Deploy com Containers

### Docker Compose

```yaml
# containers/docker-compose.yml
version: '3.8'
services:
  securellm:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SECURELLM_API_KEY=${API_KEY}
      - RUST_LOG=info
    volumes:
      - ./config:/config:ro
      - ./data:/data
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
```

### Kubernetes (exemplo)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: securellm
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: securellm
        image: securellm:latest
        securityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
        env:
        - name: SECURELLM_API_KEY
          valueFrom:
            secretKeyRef:
              name: securellm-secrets
              key: api-key
```

## 🔧 Desenvolvimento

### Setup do Ambiente

```bash
# Com Nix
nix develop

# Sem Nix
cargo build
cargo test
cargo clippy
cargo fmt
```

### Adicionar Novo Provider

1. Criar arquivo em `crates/providers/src/novo_provider.rs`
2. Implementar trait `LLMProvider`
3. Adicionar testes
4. Documentar no README

Exemplo mínimo:

```rust
use async_trait::async_trait;
use securellm_core::*;

pub struct NovoProvider {
    config: NovoConfig,
}

#[async_trait]
impl LLMProvider for NovoProvider {
    fn name(&self) -> &str { "novo" }
    fn version(&self) -> &str { "v1" }
    
    fn validate_config(&self) -> Result<()> { todo!() }
    async fn send_request(&self, req: Request) -> Result<Response> { todo!() }
    async fn health_check(&self) -> Result<ProviderHealth> { todo!() }
    fn capabilities(&self) -> ProviderCapabilities { todo!() }
    async fn list_models(&self) -> Result<Vec<ModelInfo>> { todo!() }
}
```

## 📈 Roadmap

### ✅ Fase 1: Core Foundation (Atual)
- [x] Estrutura base do projeto
- [x] Provider abstraction layer
- [x] DeepSeek implementation completa
- [x] CLI básico
- [x] Security primitives
- [x] Docker support
- [x] NixOS module

### 🚧 Fase 2: Security Hardening (Em andamento)
- [ ] TLS mutual authentication completo
- [ ] Request sandboxing real
- [ ] Rate limiting adaptativo
- [ ] Audit logging com SQLite
- [ ] PII detection e sanitization

### 📋 Fase 3: Provider Integration
- [ ] OpenAI adapter
- [ ] Anthropic adapter
- [ ] Ollama (local) adapter
- [ ] llama.cpp integration
- [ ] Custom server support

### 🔮 Fase 4: Advanced Features
- [ ] E2E encryption
- [ ] Key rotation automática
- [ ] HSM support
- [ ] Distributed tracing
- [ ] GraphQL API

### 🎨 Fase 5: Distribution
- [ ] Desktop app (Tauri/Iced)
- [ ] Proxy server (Go)
- [ ] Web UI
- [ ] Mobile apps
- [ ] Package managers (apt, yum, brew)

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](CONTRIBUTING.md).

### Áreas que precisam de ajuda:
1. Implementação de novos providers (OpenAI, Anthropic, Ollama)
2. Testes de integração
3. Documentação e exemplos
4. Performance optimization
5. Security audits

## 📝 Licença

Dual-licensed: MIT OR Apache-2.0

## 🔐 Reportar Vulnerabilidades

Encontrou uma vulnerabilidade? Reporte privadamente para:
security@securellm.dev

**Não** crie issues públicas para vulnerabilidades de segurança.

## 💬 Suporte

- GitHub Issues: https://github.com/securellm/bridge/issues
- Discussions: https://github.com/securellm/bridge/discussions
- Discord: [em breve]

## 🙏 Agradecimentos

Construído com tecnologias incríveis:
- Rust e Tokio
- rustls para TLS seguro
- Axum para HTTP
- NixOS para builds reproduzíveis

---

**Made with ❤️ for secure AI communication**
