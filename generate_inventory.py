import os
import csv
from pathlib import Path

# --- CONFIGURAÇÃO ---
CONFIG = {
    ".nix": {"icon": "❄️", "type": "System Core", "tag": "Nix"},
    ".sh":  {"icon": "🐚", "type": "Automation",  "tag": "Shell"},
    ".py":  {"icon": "🐍", "type": "Automation",  "tag": "Python"},
    ".md":  {"icon": "📘", "type": "Documentation", "tag": "Docs"},
    ".lua": {"icon": "🌙", "type": "Config",      "tag": "Lua"},
    ".json": {"icon": "📦", "type": "Data",        "tag": "Json"},
}

# Pastas globais para ignorar totalmente
IGNORE_DIRS_GLOBAL = {".git", "result", ".direnv", "node_modules", "__pycache__", "target", "modules/packages/_archive*", "archive/merged-repos*"}

# Caminho específico onde JSONs devem ser ignorados (caminho parcial), API precisa ser revista para onde vai ser movida ou construida.
IGNORE_JSON_PATH = "modules/ml/orchestration" 

OUTPUT_FILE = "nixos_inventory_v3.csv"

def generate_csv():
    print(f"🚀 Iniciando varredura inteligente em: {os.getcwd()}")

    # Lista para armazenar dados antes de escrever (para poder ordenar)
    inventory_data = []

    for root, dirs, files in os.walk("."):
        # Remove pastas ignoradas da travessia
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS_GLOBAL]

        for filename in files:
            file_path = Path(root) / filename
            ext = file_path.suffix

            # Checa se a extensão nos interessa
            if ext in CONFIG:
                clean_path = str(file_path).replace("./", "")

                # --- NOVO: FILTRO ESPECÍFICO ---
                # Se for JSON e estiver dentro da pasta de orquestração de ML, PULA.
                if ext == ".json" and IGNORE_JSON_PATH in clean_path:
                    continue

                # --- NOVO: CÁLCULO DE PROFUNDIDADE ---
                # Conta quantas barras '/' existem no caminho.
                # flake.nix (0 barras) = Depth 0
                # hosts/laptop/config.nix (2 barras) = Depth 2
                depth = clean_path.count(os.sep)

                meta = CONFIG[ext]
                display_name = f"{meta['icon']} {filename}"

                # Adiciona à lista temporária
                inventory_data.append({
                    "Name": display_name,
                    "Path": clean_path,
                    "Type": meta['type'],
                    "Status": "Analyzing",
                    "Extension": meta['tag'],
                    "Depth": depth # Nova coluna numérica
                })

    # --- NOVO: ORDENAÇÃO ---
    # Ordena primeiro por Profundidade (menor para maior), depois por Nome
    # Isso coloca os arquivos da raiz no topo da tabela.
    inventory_data.sort(key=lambda x: (x["Depth"], x["Name"]))

    # Escrevendo o CSV
    with open(OUTPUT_FILE, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)

        # Cabeçalhos
        writer.writerow(["Name", "Path", "Type", "Status", "Extension", "Depth"])

        for item in inventory_data:
            writer.writerow([
                item["Name"],
                item["Path"],
                item["Type"],
                item["Status"],
                item["Extension"],
                item["Depth"]
            ])

    print(f"✅ Sucesso! {len(inventory_data)} arquivos processados.")
    print(f"🧹 JSONs de '{IGNORE_JSON_PATH}' foram ignorados.")
    print(f"📄 Arquivo gerado: {OUTPUT_FILE}")

if __name__ == "__main__":
    generate_csv()
