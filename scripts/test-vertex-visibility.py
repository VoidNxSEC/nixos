#!/usr/bin/env python3
import os
import subprocess
import sys

def check_env():
    print("--- Verificando Ambiente GCP ---")
    project = os.environ.get("GOOGLE_CLOUD_PROJECT")
    region = os.environ.get("GOOGLE_CLOUD_REGION")
    
    print(f"GOOGLE_CLOUD_PROJECT: {project}")
    print(f"GOOGLE_CLOUD_REGION: {region}")
    
    adc_path = os.path.expanduser("~/.config/gcloud/application_default_credentials.json")
    if os.path.exists(adc_path):
        print(f"✅ ADC encontrado em: {adc_path}")
    else:
        print(f"❌ ADC NÃO ENCONTRADO. Execute: gcloud auth application-default login")

def test_vertex_ai():
    print("
--- Testando Acesso Vertex AI ---")
    try:
        import vertexai
        from vertexai.generative_models import GenerativeModel
        
        project = os.environ.get("GOOGLE_CLOUD_PROJECT")
        region = os.environ.get("GOOGLE_CLOUD_REGION", "us-central1")
        
        if not project:
            print("❌ Erro: GOOGLE_CLOUD_PROJECT não definido.")
            return

        vertexai.init(project=project, location=region)
        model = GenerativeModel("gemini-1.5-pro")
        print(f"✅ SDK inicializado com sucesso para o projeto {project}")
        
        # Testar uma chamada simples
        response = model.generate_content("Olá, você está funcionando?")
        print(f"✅ Resposta do modelo: {response.text[:50]}...")
        
    except ImportError:
        print("❌ Erro: Biblioteca 'vertexai' não instalada no ambiente Python.")
    except Exception as e:
        print(f"❌ Falha ao acessar Vertex AI: {str(e)}")

if __name__ == "__main__":
    check_env()
    test_vertex_ai()
