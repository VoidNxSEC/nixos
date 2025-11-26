# 🚀 Quick Start - SecureLLM Bridge

## Instalação Rápida

### Opção 1: Com Rust (Recomendado)

```bash
# Instalar Rust se não tiver
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clonar e compilar
git clone https://github.com/securellm/bridge.git
cd secure-llm-bridge
make build

# Ou instalar globalmente
make install
```

### Opção 2: Com Nix (Para usuários NixOS)

```bash
# Build
nix build

# Rodar direto
nix run . -- --help

# Ou adicionar ao seu sistema
# configuration.nix:
services.securellm = {
  enable = true;
  configFile = /etc/securellm/config.toml;
};
```

### Opção 3: Com Docker

```bash
# Build
docker build -t securellm:latest .

# Rodar
docker run --rm \
  -e SECURELLM_API_KEY=your-key \
  securellm:latest \
  chat --provider deepseek --model deepseek-chat "Hello"
```

## Primeiro Uso

### 1. Configure sua API Key

```bash
# DeepSeek API Key (obtenha em https://platform.deepseek.com)
export SECURELLM_API_KEY="your-deepseek-api-key"
```

### 2. Teste a Conexão

```bash
# Health check
securellm health deepseek

# Listar modelos
securellm models deepseek
```

### 3. Primeiro Chat

```bash
securellm chat \
  --provider deepseek \
  --model deepseek-chat \
  "Explique o que é Rust em 3 frases"
```

### 4. Chat com Parâmetros

```bash
securellm chat \
  --provider deepseek \
  --model deepseek-coder \
  --system "Você é um expert em Rust" \
  --max-tokens 2000 \
  --temperature 0.3 \
  "Como implementar um trait customizado?"
```

## Exemplos de Uso

### Chat Simples

```bash
securellm chat -p deepseek -m deepseek-chat "Hello!"
```

### Chat Criativo

```bash
securellm chat \
  -p deepseek \
  -m deepseek-chat \
  --temperature 0.9 \
  "Escreva um poema sobre Rust programming"
```

### Chat para Código

```bash
securellm chat \
  -p deepseek \
  -m deepseek-coder \
  --system "Expert Rust programmer" \
  "Write a secure HTTP client in Rust"
```

### Usando em Scripts

```bash
#!/bin/bash

RESPONSE=$(securellm chat \
  -p deepseek \
  -m deepseek-chat \
  "What is 2+2?" 2>&1 | grep -A 100 "Response:")

echo "$RESPONSE"
```

## Uso como Biblioteca Rust

### Cargo.toml

```toml
[dependencies]
securellm-core = { path = "./secure-llm-bridge/crates/core" }
securellm-providers = { path = "./secure-llm-bridge/crates/providers" }
tokio = { version = "1", features = ["full"] }
```

### main.rs

```rust
use securellm_core::*;
use securellm_providers::deepseek::{DeepSeekConfig, DeepSeekProvider};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Configurar
    let config = DeepSeekConfig::new(std::env::var("SECURELLM_API_KEY")?);
    let provider = DeepSeekProvider::new(config)?;
    
    // Criar request
    let request = Request::new("deepseek", "deepseek-chat")
        .add_message(Message {
            role: MessageRole::User,
            content: MessageContent::Text("Olá!".into()),
            name: None,
            metadata: None,
        });
    
    // Enviar
    let response = provider.send_request(request).await?;
    
    // Usar
    println!("Resposta: {}", response.text()?);
    println!("Tokens: {}", response.usage.total_tokens);
    
    Ok(())
}
```

## Configuração Avançada

### Arquivo de Configuração

Crie `~/.config/securellm/config.toml`:

```toml
[security]
security_level = "High"
tls_enabled = true

[[providers]]
name = "deepseek"
enabled = true
timeout_seconds = 60

[rate_limiting]
default_limit = 60
```

### Variáveis de Ambiente

```bash
export SECURELLM_API_KEY="your-key"
export SECURELLM_CONFIG_PATH="$HOME/.config/securellm/config.toml"
export RUST_LOG=info
```

## Comandos Úteis

```bash
# Ver ajuda completa
securellm --help

# Ver ajuda de um comando
securellm chat --help

# Modo verbose
securellm -v chat -p deepseek -m deepseek-chat "Hello"

# Info do provider
securellm info deepseek

# Listar modelos
securellm models deepseek

# Health check
securellm health deepseek
```

## Troubleshooting

### API Key não encontrada

```bash
# Certifique-se de exportar a variável
export SECURELLM_API_KEY="your-key"

# Ou passe diretamente
securellm chat --api-key "your-key" -p deepseek -m deepseek-chat "test"
```

### Erro de compilação

```bash
# Limpar e recompilar
make clean
make build

# Ou com cargo
cargo clean
cargo build --release
```

### Erro de network

```bash
# Testar conexão
curl https://api.deepseek.com/v1/models

# Ver logs detalhados
RUST_LOG=debug securellm -v chat -p deepseek -m deepseek-chat "test"
```

## Próximos Passos

1. ✅ Configure o DeepSeek (já funcionando!)
2. 🔜 Aguarde implementação do OpenAI
3. 🔜 Aguarde implementação do Anthropic
4. 🔜 Teste o Ollama para modelos locais

## Links Úteis

- **Documentação Completa**: [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)
- **Segurança**: [docs/SECURITY.md](docs/SECURITY.md)
- **Exemplos**: [examples/](examples/)
- **API DeepSeek**: https://platform.deepseek.com

## Suporte

- Issues: GitHub Issues
- Discussões: GitHub Discussions
- Email: help@securellm.dev

---

**Aproveite o SecureLLM Bridge! 🚀**
