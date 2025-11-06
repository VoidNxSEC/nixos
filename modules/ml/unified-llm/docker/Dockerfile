# Multi-stage Dockerfile for SecureLLM Bridge
FROM rust:1.75-slim as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy workspace files
COPY Cargo.toml Cargo.lock ./
COPY crates ./crates

# Build release binaries
RUN cargo build --release --bin securellm

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 securellm

# Copy binary
COPY --from=builder /app/target/release/securellm /usr/local/bin/

# Set ownership
RUN chown securellm:securellm /usr/local/bin/securellm

USER securellm
WORKDIR /home/securellm

# Create config directory
RUN mkdir -p .config/securellm

ENTRYPOINT ["securellm"]
CMD ["--help"]
