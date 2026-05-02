#!/usr/bin/env python3
import json
import subprocess
import os
from kafka import KafkaConsumer, KafkaProducer

class ProductivityAgent:
    def __init__(self):
        self.agent_id = "nexus-productivity-001"
        self.consumer = KafkaConsumer(
            'agent.stt.completed',
            bootstrap_servers=['localhost:9092'],
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )
        self.producer = KafkaProducer(
            bootstrap_servers=['localhost:9092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        print("🚀 Nexus Productivity Agent online. Aguardando comandos inteligentes...")

    def execute_with_llm(self, user_text):
        """
        Usa o Gemini CLI (que já existe na infra) para interpretar e agir.
        """
        print(f"🧠 Interpretando: {user_text}")
        
        # Prompt de sistema para o Agente
        system_prompt = (
            "Você é um Agente de Produtividade Senior operando em um sistema NixOS. "
            "Sua tarefa é converter o comando de voz do usuário em uma ação técnica ou explicação concisa. "
            "Se for um comando de sistema, retorne apenas o comando para execução. "
            "Contexto: O usuário trabalha em /home/kernelcore/arch."
        )
        
        try:
            # Chamada ao Gemini CLI da sua infra
            # Nota: Ajustamos o comando conforme o binário real disponível
            process = subprocess.run(
                ["gemini", "ask", f"{system_prompt}\n\nComando do Usuário: {user_text}"],
                capture_output=True, text=True, timeout=15
            )
            return process.stdout.strip()
        except Exception as e:
            return f"Erro ao consultar o cérebro: {str(e)}"

    def speak(self, text):
        self.producer.send('agent.tts.requests', value={
            "agent_id": self.agent_id,
            "text": text,
            "language": "pt"
        })

    def run(self):
        for message in self.consumer:
            text = message.value.get('text', '')
            if not text: continue
            
            # 1. Inteligência: Decide o que fazer
            response = self.execute_with_llm(text)
            
            # 2. Feedback por voz: Diz ao usuário o que está fazendo/pensando
            self.speak(response)
            
            # 3. Log para o terminal (opcional: executar comandos se o LLM retornar algo como 'EXEC: ...')
            print(f"💬 Resposta: {response}")

if __name__ == "__main__":
    agent = ProductivityAgent()
    agent.run()
