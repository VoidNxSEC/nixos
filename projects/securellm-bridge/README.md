# SecureLLM Bridge

Sistema seguro e isolado para comunicação com LLMs (Cloud, Local, Provider, Serverless)

## 🔒 Segurança por Design

- Isolamento máximo de ambiente
- Autenticação mútua TLS
- Rate limiting adaptativo
- Auditoria completa
- Sandboxing de execução
- Zero-trust architecture

## 📁 Estrutura do Projeto

```
secure-llm-bridge/
├── src/                    # Código fonte principal
│   ├── core/              # Abstrações principais (request, response, error)
│   ├── security/          # Módulos de segurança (TLS, crypto, secrets)
│   ├── providers/         # Implementações de providers (DeepSeek, OpenAI, etc)
│   └── config.rs          # Gestão de configuração
│
├── cli/                    # Aplicação CLI
│   └── src/main.rs
│
├── docs/                   # Documentação completa
│   ├── README.md
│   ├── GETTING_STARTED.md
│   ├── SECURITY.md
│   ├── CONTRIBUTING.md
│   ├── PROJETO_COMPLETO.md
│   └── QUICK_START.md
│
├── examples/               # Exemplos de uso
│   ├── rust_api_example.rs
│   ├── basic_usage.sh
│   └── config.toml.example
│
├── docker/                 # Configurações Docker
│   ├── Dockerfile
│   ├── Dockerfile.alpine
│   └── docker-compose.yml
│
├── nix/                    # Configurações Nix/NixOS
│   ├── flake.nix
│   └── flake.lock
│
├── config/                 # Arquivos de configuração
│   └── config.toml
│
└── mnt/                    # Dados persistentes/montagens
```

## 🚀 Quick Start

```bash
# Build
cargo build --release

# Run CLI
cargo run --bin securellm -- chat --provider deepseek "Hello!"

# With Docker
docker build -t securellm -f docker/Dockerfile .
docker run --rm securellm --help
```

## 📚 Documentação

Para documentação completa, veja:
- [Getting Started](docs/GETTING_STARTED.md) - Guia completo do projeto
- [Security](docs/SECURITY.md) - Best practices de segurança
- [Contributing](docs/CONTRIBUTING.md) - Como contribuir
- [Quick Start](docs/QUICK_START.md) - Início rápido
- [Projeto Completo](docs/PROJETO_COMPLETO.md) - Visão geral completa

## 🎯 Providers Suportados

- **Cloud**: OpenAI, Anthropic, DeepSeek, Cohere
- **Local**: Ollama, llama.cpp, LocalAI
- **Custom**: Servidores próprios
- **Serverless**: AWS Lambda, GCP Functions, Azure Functions

## 📝 License

MIT OR Apache-2.0
