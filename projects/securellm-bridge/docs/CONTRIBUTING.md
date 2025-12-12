# Contributing to SecureLLM Bridge

Thank you for your interest in contributing! 

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/secure-llm-bridge`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests: `cargo test --all`
6. Run lints: `cargo clippy --all-targets --all-features`
7. Format code: `cargo fmt --all`
8. Commit with clear messages
9. Push and create a pull request

## Development Setup

### Using Cargo

```bash
cargo build
cargo test
cargo run --bin securellm -- --help
```

### Using Nix

```bash
nix develop
cargo build
```

## Code Standards

- Follow Rust conventions
- Write tests for new features
- Document public APIs
- Keep security as top priority
- Add examples for new providers

## Pull Request Process

1. Update documentation
2. Add tests
3. Ensure CI passes
4. Get review approval
5. Squash commits if needed

## Security

Report security issues privately to security@securellm.dev

## Code of Conduct

Be respectful and inclusive. We follow the Rust Code of Conduct.
