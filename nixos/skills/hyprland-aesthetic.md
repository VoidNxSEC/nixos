---
name: hyprland-aesthetic
description: >
  Skill para desenvolvimento nativo em Hyprland com estética glassmorphism/minimalista.
  Cobre protocolo IPC do Hyprland (unix socket), integração com mako/dunst, waybar
  custom modules, e o sistema de notificações do ai-agent-os. Ativa sempre que
  trabalhar em crates que emitem eventos visuais, notificações, ou interagem com
  o compositor Hyprland.
scope: ai-agent-os workspace (crates/*, flake.nix, AGENTS.md)
---

# hyprland-aesthetic

Design e código nativos para Hyprland. Sem electron, sem browser, sem framework pesado.
O output é o desktop — notificação, waybar module, janela Wayland. A estética é a arquitetura.

---

## I. Aesthetic Doctrine

### Paleta — glassmorphism dark

Trabalha sobre fundo escuro profundo. Elementos usam blur + transparência, nunca cores sólidas.

```
background:    #080b0f        -- fundo base, quase preto azulado
surface:       rgba(13,17,23,0.75)  -- camadas com transparência
border:        rgba(255,255,255,0.06) -- bordas sutis, quase invisíveis
border-active: rgba(255,255,255,0.18) -- borda de elemento ativo
text-primary:  #e6edf3        -- texto principal
text-muted:    #8b949e        -- texto secundário
text-ghost:    #30363d        -- texto fantasma / hints

accent-hot:    #ff4500        -- vermelho fogo — alertas críticos
accent-warm:   #f5a623        -- âmbar — atenção
accent-idle:   #30363d        -- cinza escuro — neutro/inativo
accent-ok:     #3fb950        -- verde — success / healthy
```

### Tipografia

Terminal-first. Monospace sempre. Sem serif, sem sans-serif genérico.

```
font-family: 'JetBrains Mono', 'Fira Code', monospace
font-size-label:  10px  -- breadcrumbs, tags, timestamps
font-size-body:   12px  -- conteúdo principal
font-size-title:  14px  -- títulos de seção
letter-spacing:   0.12em para labels uppercase
text-transform:   uppercase para labels de status/categoria
```

### Princípios visuais

- **Menos é mais denso**: cada elemento que aparece tem peso. Sem decoração gratuita.
- **Estado comunica tudo**: cor = estado. Sem ícones redundantes se a cor já fala.
- **Blur é profundidade**: `backdrop-filter: blur(12px)` cria camadas sem sombra pesada.
- **Bordas finas, não ausentes**: 1px rgba — presente mas não dominante.
- **Animação tem função**: fade-in 150ms para aparecer, slide para transição. Nada decorativo.

---

## II. Hyprland IPC — Protocolo

### Como funciona

Hyprland expõe dois unix sockets por instância:

```
$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock   -- comandos
$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock  -- eventos
```

O `.socket.sock` recebe comandos dispatch e retorna resposta.
O `.socket2.sock` é stream contínuo — você conecta e ouve eventos indefinidamente.

### Rust: conectar e enviar comando

```rust
use tokio::net::UnixStream;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

pub async fn hypr_dispatch(cmd: &str) -> anyhow::Result<String> {
    let sig = std::env::var("HYPRLAND_INSTANCE_SIGNATURE")?;
    let socket_path = format!(
        "{}/hypr/{}/.socket.sock",
        std::env::var("XDG_RUNTIME_DIR")?,
        sig
    );

    let mut stream = UnixStream::connect(&socket_path).await?;
    stream.write_all(cmd.as_bytes()).await?;
    stream.shutdown().await?;

    let mut response = String::new();
    stream.read_to_string(&mut response).await?;
    Ok(response)
}

// uso:
// hypr_dispatch("dispatch focuswindow class:kitty").await?;
// hypr_dispatch("keyword animations:enabled 0").await?;
```

### Rust: subscrever eventos

```rust
use tokio::net::UnixStream;
use tokio::io::{AsyncBufReadExt, BufReader};

pub async fn subscribe_events<F>(mut handler: F) -> anyhow::Result<()>
where
    F: FnMut(HyprEvent) + Send,
{
    let sig = std::env::var("HYPRLAND_INSTANCE_SIGNATURE")?;
    let socket_path = format!(
        "{}/hypr/{}/.socket2.sock",
        std::env::var("XDG_RUNTIME_DIR")?,
        sig
    );

    let stream = UnixStream::connect(&socket_path).await?;
    let mut reader = BufReader::new(stream).lines();

    while let Some(line) = reader.next_line().await? {
        if let Some(event) = parse_hypr_event(&line) {
            handler(event);
        }
    }
    Ok(())
}
```

### Formato de evento

Cada linha do socket2 tem formato `event>>data`:

```
activewindow>>kitty,nvim flake.nix
workspace>>3
openwindow>>address,workspace,class,title
closewindow>>address
monitoradded>>name
fullscreen>>0
```

### Parser de eventos

```rust
#[derive(Debug, Clone)]
pub enum HyprEvent {
    ActiveWindow { class: String, title: String },
    Workspace(u32),
    OpenWindow { class: String, title: String },
    CloseWindow,
    Fullscreen(bool),
    Unknown(String),
}

fn parse_hypr_event(line: &str) -> Option<HyprEvent> {
    let (event, data) = line.split_once(">>")?;
    Some(match event {
        "activewindow" => {
            let (class, title) = data.split_once(',')?;
            HyprEvent::ActiveWindow {
                class: class.to_string(),
                title: title.to_string(),
            }
        }
        "workspace" => HyprEvent::Workspace(data.trim().parse().ok()?),
        "fullscreen" => HyprEvent::Fullscreen(data.trim() == "1"),
        _ => HyprEvent::Unknown(line.to_string()),
    })
}
```

---

## III. Notificações — mako / libnotify

### Filosofia

Notificação é interrupção. Só dispara quando o usuário precisa agir.
`hot` = notificação com urgência crítica.
`warm` = notificação normal.
`cold` = sem notificação — só atualiza waybar silenciosamente.

### Rust com notify-rust

```toml
# Cargo.toml
[dependencies]
notify-rust = "4"
```

```rust
use notify_rust::{Notification, Urgency, Timeout};

pub async fn notify_hot(summary: &str, body: &str) -> anyhow::Result<()> {
    Notification::new()
        .summary(summary)
        .body(body)
        .urgency(Urgency::Critical)
        .timeout(Timeout::Milliseconds(8000))
        .hint(notify_rust::Hint::Category("email".to_string()))
        // classe CSS para mako diferenciar visualmente
        .hint(notify_rust::Hint::Custom(
            "x-canonical-private-synchronous".to_string(),
            "voidnx-hot".to_string(),
        ))
        .show()?;
    Ok(())
}

pub async fn notify_warm(summary: &str, body: &str) -> anyhow::Result<()> {
    Notification::new()
        .summary(summary)
        .body(body)
        .urgency(Urgency::Normal)
        .timeout(Timeout::Milliseconds(4000))
        .show()?;
    Ok(())
}
```

### Config mako (glassmorphism)

```ini
# ~/.config/mako/config
font=JetBrains Mono 11
background-color=#0d1117bf
text-color=#e6edf3
border-color=#ffffff0f
border-size=1
border-radius=6
padding=14,16
margin=8
width=340
max-visible=5
sort=-time

# notificação crítica (hot)
[urgency=critical]
background-color=#0d1117e6
border-color=#ff450033
text-color=#e6edf3
default-timeout=8000

# email agent
[app-name=voidnx]
border-color=#ffffff18
```

---

## IV. Waybar — Custom Module

### Formato JSON que o módulo espera

```json
{
  "text": "🔥 2",
  "tooltip": "recruiter@stripe.com\nInterview invite — Platform Engineer\n\ncargoaudit@rustsec.org\nRUSTC-2024-0001: memory safety advisory",
  "class": "hot",
  "percentage": 0
}
```

### Waybar config

```jsonc
// ~/.config/waybar/config
"custom/inbox": {
    "exec": "cat /tmp/voidnx-inbox.json 2>/dev/null || echo '{\"text\":\"—\",\"class\":\"idle\"}'",
    "interval": 30,
    "return-type": "json",
    "format": "{}",
    "on-click": "~/.local/bin/voidnx-inbox-open"
}
```

### Waybar CSS (glassmorphism)

```css
/* ~/.config/waybar/style.css */
#custom-inbox {
    font-family: 'JetBrains Mono', monospace;
    font-size: 11px;
    padding: 0 12px;
    color: #30363d;
    transition: color 0.2s ease;
}

#custom-inbox.hot {
    color: #ff4500;
    text-shadow: 0 0 8px rgba(255, 69, 0, 0.4);
}

#custom-inbox.warm {
    color: #f5a623;
}

#custom-inbox.idle {
    color: #30363d;
}
```

### Rust: escrever estado para waybar

```rust
use serde::Serialize;
use std::path::Path;

#[derive(Serialize)]
struct WaybarPayload {
    text: String,
    tooltip: String,
    class: String,
}

pub fn update_waybar(hot_count: usize, items: &[EmailItem]) -> anyhow::Result<()> {
    let class = if hot_count > 0 { "hot" } else { "idle" };
    let text = if hot_count > 0 {
        format!("🔥 {}", hot_count)
    } else {
        "—".to_string()
    };

    let tooltip = items
        .iter()
        .filter(|e| e.temperature == Temperature::Hot)
        .map(|e| format!("{}\n{}", e.from, e.reason))
        .collect::<Vec<_>>()
        .join("\n\n");

    let payload = WaybarPayload { text, tooltip, class: class.to_string() };
    let json = serde_json::to_string(&payload)?;
    std::fs::write("/tmp/voidnx-inbox.json", json)?;
    Ok(())
}
```

---

## V. Integração no ai-agent-os

### Estrutura esperada do novo crate

```
crates/email-monitor/
├── Cargo.toml
└── src/
    └── lib.rs      -- EmailMonitor struct + poll loop
```

### Interface com agent-core

Cada monitor novo implementa um trait e é spawnado pelo orchestrator:

```rust
// crates/agent-core/src/lib.rs — padrão existente
pub trait Monitor: Send + Sync {
    async fn run(&self, alerts: Arc<AlertSystem>) -> anyhow::Result<()>;
}

// crates/email-monitor/src/lib.rs
pub struct EmailMonitor {
    pub poll_interval_secs: u64,
    pub anthropic_api_key: String,
}

impl Monitor for EmailMonitor {
    async fn run(&self, alerts: Arc<AlertSystem>) -> anyhow::Result<()> {
        loop {
            let emails = self.fetch_and_classify().await?;
            let hot: Vec<_> = emails.iter().filter(|e| e.is_hot()).collect();

            update_waybar(hot.len(), &emails)?;

            for email in &hot {
                alerts.send(Alert {
                    title: format!("🔥 {}", email.subject),
                    body: email.reason.clone(),
                    urgency: Urgency::Critical,
                })?;
            }

            tokio::time::sleep(Duration::from_secs(self.poll_interval_secs)).await;
        }
    }
}
```

### AgentConfig — extensão

```rust
// adicionar em AgentConfig:
pub email_monitor_enabled: bool,           // default: false
pub email_poll_interval_secs: u64,         // default: 300
pub email_hot_only_notify: bool,           // default: true
```

---

## VI. Checklist antes de abrir PR

- [ ] Novo crate adicionado em `[workspace.members]` no `Cargo.toml` raiz
- [ ] `flake.nix` atualiza outputs para incluir novo crate
- [ ] `AgentConfig` tem os novos campos com `Default` implementado
- [ ] Monitor registrado no orchestrator em `agent-core/src/lib.rs`
- [ ] `/tmp/voidnx-inbox.json` é escrito mesmo quando não há emails hot (estado idle)
- [ ] Nenhum `unwrap()` em paths de produção — usar `?` ou `anyhow::bail!`
- [ ] `RUST_LOG=debug cargo run` não printa dados sensíveis (API keys, email content)
