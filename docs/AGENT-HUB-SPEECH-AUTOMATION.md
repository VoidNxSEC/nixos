# Agent Hub - Speech Automation Workflow

## Visão Geral

Este documento descreve como o **Agent Hub** integra capacidades de **Speech** (TTS + STT) para permitir automatização completa via voz.

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                        Agent Hub - Speech                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────┐      │
│  │  User    │─────▶│ Microphone   │─────▶│   Whisper    │      │
│  │  Voice   │      │   Input      │      │   STT Gateway│      │
│  └──────────┘      └──────────────┘      └──────┬───────┘      │
│                                                   │              │
│                                          Kafka Topic:           │
│                                       agent.stt.completed       │
│                                                   │              │
│                                                   ▼              │
│                                          ┌────────────────┐     │
│                                          │ Voice Assistant│     │
│                                          │     Agent      │     │
│                                          │  (Python/Rust) │     │
│                                          └────────┬───────┘     │
│                                                   │              │
│                                          Processes Command      │
│                                          Executes Task          │
│                                                   │              │
│                                          Kafka Topic:           │
│                                       agent.tts.requests        │
│                                                   │              │
│                                                   ▼              │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────┐      │
│  │  User    │◀─────│   Speaker    │◀─────│   F5-TTS     │      │
│  │  Hears   │      │   Output     │      │  TTS Gateway │      │
│  └──────────┘      └──────────────┘      └──────────────┘      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes

### 1. Whisper STT Gateway

**Função**: Converte áudio (fala) em texto

**Kafka Topics**:
- **Input**: `agent.stt.requests`
- **Output**: `agent.stt.completed`

**Formato da Mensagem (Input)**:
```json
{
  "agent_id": "voice-recorder-001",
  "request_id": "uuid-1234",
  "audio_path": "/tmp/recording-001.wav",
  "language": "pt",
  "model": "base"
}
```

**Formato da Mensagem (Output)**:
```json
{
  "request_id": "uuid-1234",
  "agent_id": "voice-recorder-001",
  "status": "completed",
  "text": "listar todos os arquivos do diretório atual",
  "confidence": 0.95
}
```

### 2. F5-TTS Gateway

**Função**: Converte texto em áudio (fala)

**Kafka Topics**:
- **Input**: `agent.tts.requests`
- **Output**: `agent.tts.completed`

**Formato da Mensagem (Input)**:
```json
{
  "agent_id": "voice-assistant-001",
  "request_id": "uuid-5678",
  "text": "Listando arquivos: README.md, main.rs, config.toml",
  "language": "pt",
  "voice_profile": "default"
}
```

**Formato da Mensagem (Output)**:
```json
{
  "request_id": "uuid-5678",
  "agent_id": "voice-assistant-001",
  "status": "completed",
  "audio_path": "/tmp/tts-uuid-5678.wav",
  "duration_ms": 3500
}
```

### 3. Voice Assistant Agent (Exemplo)

**Função**: Processa comandos de voz e executa tarefas

**Kafka Topics**:
- **Input**: `agent.stt.completed` (escuta transcrições)
- **Output**: `agent.tts.requests` (envia respostas)
- **Output**: `agent.task.executed` (publica resultados)

**Comandos Suportados** (exemplo):
- "listar arquivos" → executa `ls -lah`
- "data de hoje" → executa `date`
- "abrir navegador" → executa `firefox`
- "status do sistema" → executa `systemctl status`

## Workflow Completo (End-to-End)

### Cenário: Usuário pergunta "qual a data de hoje?"

```
┌─────────────────────────────────────────────────────────────┐
│ 1. CAPTURA DE VOZ                                            │
├─────────────────────────────────────────────────────────────┤
│ User fala: "Qual a data de hoje?"                            │
│ Recording Agent captura áudio → /tmp/rec-001.wav            │
│                                                              │
│ Recording Agent → Kafka Topic: agent.stt.requests           │
│ {                                                            │
│   "audio_path": "/tmp/rec-001.wav",                         │
│   "language": "pt"                                           │
│ }                                                            │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. TRANSCRIÇÃO (STT)                                         │
├─────────────────────────────────────────────────────────────┤
│ Whisper STT Gateway processa áudio                          │
│ Transcrição: "qual a data de hoje"                          │
│                                                              │
│ Whisper Gateway → Kafka Topic: agent.stt.completed         │
│ {                                                            │
│   "text": "qual a data de hoje",                            │
│   "confidence": 0.92                                         │
│ }                                                            │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. PROCESSAMENTO DO COMANDO                                  │
├─────────────────────────────────────────────────────────────┤
│ Voice Assistant Agent recebe transcrição                    │
│ Identifica comando: "data de hoje"                          │
│ Executa: date '+%A, %d de %B de %Y'                         │
│ Resultado: "Sábado, 25 de Janeiro de 2026"                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. GERAÇÃO DE RESPOSTA (TTS)                                 │
├─────────────────────────────────────────────────────────────┤
│ Voice Assistant Agent → Kafka Topic: agent.tts.requests    │
│ {                                                            │
│   "text": "A data de hoje é Sábado, 25 de Janeiro de 2026", │
│   "language": "pt"                                           │
│ }                                                            │
│                                                              │
│ F5-TTS Gateway processa request                             │
│ Gera áudio → /tmp/tts-resp-001.wav                          │
│                                                              │
│ F5-TTS Gateway → Kafka Topic: agent.tts.completed          │
│ {                                                            │
│   "audio_path": "/tmp/tts-resp-001.wav",                    │
│   "duration_ms": 4200                                        │
│ }                                                            │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. REPRODUÇÃO DE ÁUDIO                                       │
├─────────────────────────────────────────────────────────────┤
│ Audio Player Agent recebe evento agent.tts.completed        │
│ Reproduz áudio: /tmp/tts-resp-001.wav                       │
│ User ouve: "A data de hoje é Sábado, 25 de Janeiro de 2026" │
└─────────────────────────────────────────────────────────────┘
```

## Configuração NixOS

### Habilitar Speech Capabilities no Agent Hub

```nix
# /etc/nixos/hosts/kernelcore/configuration.nix

{
  # Enable Agent Hub Infrastructure
  kernelcore.ai.agent-hub.infra.enable = true;
  kernelcore.ai.agent-hub.infra.orchestrator = "nomad";

  # Enable Speech Capabilities (TTS + STT)
  kernelcore.ai.agent-hub.capabilities.speech = {
    enable = true;
    enableTTS = true;  # F5-TTS
    enableSTT = true;  # Whisper

    # Whisper model (tiny, base, small, medium, large)
    whisperModel = "base";

    # Reference voice for F5-TTS cloning (optional)
    referenceVoice = ./assets/my-voice.wav;
    referenceText = "Olá, eu sou o seu assistente pessoal.";
  };
}
```

### Rebuild

```bash
sudo nixos-rebuild switch
```

## Serviços Systemd

Após rebuild, os seguintes serviços estarão disponíveis:

```bash
# Check status
systemctl status speech-gateway-tts
systemctl status speech-gateway-stt
systemctl status redpanda  # Kafka-compatible backbone

# View logs
journalctl -fu speech-gateway-tts
journalctl -fu speech-gateway-stt
```

## Desenvolvimento de Agentes

### Exemplo Mínimo: Agente Python que usa TTS

```python
from kafka import KafkaProducer
import json
import uuid

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

def speak(text):
    request = {
        "agent_id": "my-agent-001",
        "request_id": str(uuid.uuid4()),
        "text": text,
        "language": "pt"
    }
    producer.send('agent.tts.requests', value=request)
    print(f"🔊 Speaking: {text}")

# Uso
speak("Olá, este é um teste de text-to-speech")
```

### Exemplo Mínimo: Agente Python que usa STT

```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'agent.stt.completed',
    bootstrap_servers=['localhost:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

for message in consumer:
    data = message.value
    text = data['text']
    confidence = data.get('confidence', 0)

    print(f"📝 Heard: {text} (confidence: {confidence:.2f})")

    # Processar comando aqui
    if "olá" in text.lower():
        print("👋 Respondendo ao cumprimento...")
```

## Casos de Uso

### 1. Assistente de Voz para Automação Residencial

```python
# Comandos suportados:
# - "acender as luzes" → MQTT publish lights/living_room ON
# - "desligar tv" → IR command TV_POWER_OFF
# - "qual a temperatura" → Read sensor temperature
```

### 2. Assistente de Desenvolvimento

```python
# Comandos suportados:
# - "rodar os testes" → pytest
# - "fazer commit" → git commit -am "Auto-commit"
# - "buildar o projeto" → nix build
# - "status do CI" → gh api /repos/user/repo/actions/runs
```

### 3. Narrador de Logs em Tempo Real

```python
# Lê logs do sistema e narra eventos importantes
# - "Erro crítico detectado no serviço X"
# - "Deploy concluído com sucesso"
# - "Alta carga de CPU detectada: 95%"
```

### 4. Chatbot com Voz

```python
# Integra com LLM (OpenAI, Anthropic, local)
# User fala → STT → LLM processa → TTS → User ouve resposta
```

## Monitoramento

### Kafka Topics Health

```bash
# List all topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# View messages in real-time
kafkacat -C -b localhost:9092 -t agent.tts.requests
kafkacat -C -b localhost:9092 -t agent.stt.completed
```

### Prometheus Metrics

```bash
# Speech Gateway metrics
curl http://localhost:8081/metrics

# Redpanda metrics
curl http://localhost:9644/metrics
```

## Troubleshooting

### TTS não está gerando áudio

1. Verificar se F5-TTS está instalado:
   ```bash
   python3 -m f5_tts.infer.infer_cli --help
   ```

2. Verificar logs:
   ```bash
   journalctl -fu speech-gateway-tts
   ```

3. Testar manualmente:
   ```bash
   echo '{"text":"teste","agent_id":"test","request_id":"123"}' | \
     kafkacat -P -b localhost:9092 -t agent.tts.requests
   ```

### STT não está transcrevendo

1. Verificar se Whisper está instalado:
   ```bash
   whisper --help
   ```

2. Verificar logs:
   ```bash
   journalctl -fu speech-gateway-stt
   ```

3. Testar Whisper diretamente:
   ```bash
   whisper /tmp/test-audio.wav --model base --language pt
   ```

### Redpanda não está rodando

```bash
# Check status
systemctl status redpanda

# Restart
systemctl restart redpanda

# Check if Kafka is accepting connections
kafkacat -L -b localhost:9092
```

## Próximos Passos

1. **Voice Cloning**: Implementar perfis de voz personalizados com F5-TTS
2. **Multilingual**: Suporte completo para múltiplos idiomas (PT, EN, ES, FR)
3. **Streaming STT**: Whisper em modo streaming para respostas mais rápidas
4. **Emotion Detection**: Análise de emoção na voz para contexto adicional
5. **Wake Word**: Implementar "wake word" (ex: "Hey Assistant") com Porcupine
6. **gRPC Integration**: Implementar endpoints gRPC do proto para comunicação direta
7. **WebSocket API**: Expor API WebSocket para integração com frontend web

## Referências

- [F5-TTS Paper](https://arxiv.org/abs/2410.06885)
- [OpenAI Whisper](https://github.com/openai/whisper)
- [Redpanda Docs](https://docs.redpanda.com/)
- [Agent Hub Proto](/etc/nixos/modules/ai/agent-hub/proto/agent_hub.proto)
- [Voice Assistant Example](/etc/nixos/modules/ai/agent-hub/examples/voice-assistant-agent.py)
