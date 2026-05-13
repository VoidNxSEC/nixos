#!/usr/bin/env python3
"""
Voice Assistant Agent - Example

Demonstra como um agente pode usar as speech capabilities (TTS + STT)
para criar um assistente de voz completo que automatiza tarefas via speech.

Arquitetura:
1. Agente escuta eventos de STT completados (user speech → text)
2. Processa o comando de voz usando LLM
3. Executa a tarefa solicitada
4. Responde via TTS (text → speech)

Kafka Topics:
- INPUT:  agent.stt.completed (transcrições de fala do usuário)
- OUTPUT: agent.tts.requests (respostas do agente em texto para TTS)
- OUTPUT: agent.task.executed (resultados de tarefas executadas)
"""

import json
import uuid
from kafka import KafkaConsumer, KafkaProducer
from typing import Dict, Any
import subprocess
import os

class VoiceAssistantAgent:
    def __init__(self, agent_id: str = "voice-assistant-001"):
        self.agent_id = agent_id

        # Kafka consumer para receber transcrições STT
        self.consumer = KafkaConsumer(
            'agent.stt.completed',
            bootstrap_servers=['localhost:9092'],
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            group_id=f'{agent_id}-consumer'
        )

        # Kafka producer para enviar requests TTS e resultados
        self.producer = KafkaProducer(
            bootstrap_servers=['localhost:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )

        print(f"🎤 Voice Assistant Agent [{agent_id}] initialized")
        print("📡 Listening for voice commands on Kafka topic: agent.stt.completed")

    def process_voice_command(self, text: str) -> Dict[str, Any]:
        """
        Processa comando de voz e executa ação correspondente.

        Comandos suportados:
        - "listar arquivos" → ls
        - "qual a data de hoje" → date
        - "abrir navegador" → firefox
        - "status do sistema" → systemctl status
        """
        text_lower = text.lower()

        # Mapeamento de comandos
        commands = {
            "listar arquivos": ("ls -lah", "Listando arquivos do diretório atual"),
            "data de hoje": ("date '+%A, %d de %B de %Y'", "A data de hoje é"),
            "hora atual": ("date '+%H:%M:%S'", "São"),
            "abrir navegador": ("firefox &", "Abrindo o navegador Firefox"),
            "status do sistema": ("systemctl status", "Verificando status do sistema"),
            "uso de memória": ("free -h", "Uso de memória do sistema"),
            "processos ativos": ("ps aux | head -10", "Primeiros 10 processos ativos"),
        }

        # Encontra comando correspondente
        for trigger, (cmd, response_prefix) in commands.items():
            if trigger in text_lower:
                try:
                    result = subprocess.run(
                        cmd,
                        shell=True,
                        capture_output=True,
                        text=True,
                        timeout=5
                    )
                    output = result.stdout.strip()
                    return {
                        "status": "success",
                        "command": cmd,
                        "output": output,
                        "response": f"{response_prefix}: {output[:200]}"  # Limita resposta
                    }
                except Exception as e:
                    return {
                        "status": "error",
                        "command": cmd,
                        "error": str(e),
                        "response": f"Desculpe, ocorreu um erro ao executar o comando: {str(e)}"
                    }

        # Comando não reconhecido
        return {
            "status": "unknown",
            "response": f"Desculpe, não entendi o comando: {text}. "
                       f"Comandos disponíveis: {', '.join(commands.keys())}"
        }

    def speak(self, text: str) -> str:
        """Envia texto para ser convertido em fala via TTS"""
        request_id = str(uuid.uuid4())

        tts_request = {
            "agent_id": self.agent_id,
            "request_id": request_id,
            "text": text,
            "language": "pt"
        }

        self.producer.send('agent.tts.requests', value=tts_request)
        print(f"🔊 TTS Request sent: {text[:50]}...")

        return request_id

    def run(self):
        """Loop principal do agente"""
        print("✅ Voice Assistant Agent ready. Waiting for voice commands...")

        for message in self.consumer:
            try:
                data = message.value
                text = data.get('text', '')
                request_id = data.get('request_id', '')

                print(f"\n📝 Received transcription [{request_id}]: {text}")

                # Processa comando de voz
                result = self.process_voice_command(text)

                # Envia resposta via TTS
                response_text = result['response']
                tts_request_id = self.speak(response_text)

                # Publica resultado da tarefa
                task_result = {
                    "agent_id": self.agent_id,
                    "stt_request_id": request_id,
                    "tts_request_id": tts_request_id,
                    "command_text": text,
                    "result": result
                }

                self.producer.send('agent.task.executed', value=task_result)

                print(f"✅ Task executed: {result['status']}")
                print(f"💬 Response: {response_text}")

            except Exception as e:
                print(f"❌ Error processing message: {e}")

if __name__ == "__main__":
    agent = VoiceAssistantAgent()
    agent.run()
