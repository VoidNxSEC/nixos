use hyprland::event_listener::EventListener;
use rdkafka::config::ClientConfig;
use rdkafka::producer::{FutureProducer, FutureRecord};
use std::time::Duration;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Configuração do Kafka (Redpanda local)
    let producer: FutureProducer = ClientConfig::new()
        .set("bootstrap.servers", "localhost:9092")
        .set("message.timeout.ms", "5000")
        .create()?;

    let mut event_listener = EventListener::new();

    println!("󱘗 Nexus Core: Event Dispatcher iniciado.");

    // Handler: Mudança de Janela -> Despacha para Kafka
    event_listener.add_active_window_change_handler(move |data| {
        let producer = producer.clone();
        tokio::spawn(async move {
            if let Some(window) = data {
                let payload = format!(r#"{{"event": "window_focus", "class": "{}", "title": "{}"}}"#, 
                                      window.class, window.title);
                
                let record = FutureRecord::to("desktop.events")
                    .payload(&payload)
                    .key("hyprland");

                let _ = producer.send(record, Duration::from_secs(0)).await;
                println!("󰖲 Evento enviado ao Kafka: focus -> {}", window.class);
            }
        });
    });

    // Loop do Hyprland
    tokio::task::spawn_blocking(move || {
        event_listener.start_listener().unwrap();
    });

    // Mantém o processo vivo
    loop { tokio::time::sleep(Duration::from_secs(3600)).await; }
}