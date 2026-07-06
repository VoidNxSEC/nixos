#!/usr/bin/env python3
import shutil
import os
from pathlib import Path
from collections import Counter

# --- CONFIGURAÇÃO ---
BASE_DIR = Path.cwd()

# Pastas que serão aniquiladas antes de qualquer coisa (Lixo puro)
LIXO_PARA_APAGAR = {
    'node_modules', 'target', '__pycache__', '.cache', 'dist', 'build', '.git', '.idea', '.vscode'
}

# Configuração Especial para Compactados (Agrupar RAR e ZIP juntos)
EXTENSOES_COMPACTADAS = {'.rar', '.zip', '.7z', '.tar', '.gz', '.xz'}
NOME_PASTA_COMPACTADOS = "Arquivos_Rar" # Atendendo ao seu pedido

def handle_collision(destination_path):
    """
    Se o arquivo já existir no destino (ex: README.md de dois projetos diferentes),
    renomeia para README_1.md, README_2.md, etc.
    """
    if not destination_path.exists():
        return destination_path

    stem = destination_path.stem
    suffix = destination_path.suffix
    parent = destination_path.parent
    counter = 1

    while True:
        new_name = f"{stem}_{counter}{suffix}"
        new_path = parent / new_name
        if not new_path.exists():
            return new_path
        counter += 1

def nuke_garbage():
    """Apaga pastas inúteis primeiro para não mover lixo."""
    print(f"[*] Varrendo e apagando lixo ({', '.join(LIXO_PARA_APAGAR)})...")
    count = 0
    # Walk topdown para poder modificar a lista de diretórios e não entrar no que apagamos
    for root, dirs, files in os.walk(BASE_DIR, topdown=True):
        # Filtra in-place
        dirs[:] = [d for d in dirs if d not in LIXO_PARA_APAGAR]
        
        # Verifica diretórios na lista negra
        for d in os.listdir(root):
            if d in LIXO_PARA_APAGAR and os.path.isdir(os.path.join(root, d)):
                full_path = Path(root) / d
                try:
                    shutil.rmtree(full_path)
                    print(f"  [X] Apagado: {full_path}")
                    count += 1
                except Exception as e:
                    print(f"  [!] Erro ao apagar {d}: {e}")
    return count

def flatten_and_organize():
    print(f"\n[*] Iniciando reestruturação TOTAL (Recursivo)...")
    stats = Counter()
    moved_count = 0
    
    # Usamos rglob('*') para pegar TUDO recursivamente
    # Convertemos para lista para evitar erros se a árvore mudar durante a iteração
    all_files = [f for f in BASE_DIR.rglob('*') if f.is_file()]
    
    for arquivo in all_files:
        # Pula o próprio script
        if arquivo.name == Path(__file__).name:
            continue
            
        ext = arquivo.suffix.lower()
        if not ext:
            folder_name = "Sem_Extensao"
        elif ext in EXTENSOES_COMPACTADAS:
            folder_name = NOME_PASTA_COMPACTADOS
        else:
            # Cria pasta com o nome da extensão (sem o ponto). Ex: .pdf -> pdf
            folder_name = ext.replace('.', '')

        # Define destino
        target_dir = BASE_DIR / folder_name
        target_dir.mkdir(exist_ok=True)
        
        # Verifica se o arquivo já não está na pasta certa (para evitar loop)
        if arquivo.parent == target_dir:
            continue

        # Move com segurança
        dest_path = handle_collision(target_dir / arquivo.name)
        
        try:
            shutil.move(str(arquivo), str(dest_path))
            stats[folder_name] += 1
            moved_count += 1
            # Opcional: printar cada arquivo (pode poluir se tiver milhares)
            # print(f"Movel: {arquivo.name} -> {folder_name}/")
        except Exception as e:
            print(f"Erro ao mover {arquivo}: {e}")

    print(f"\n[OK] {moved_count} arquivos movidos e organizados.")
    print("Resumo por pasta:")
    for folder, count in stats.most_common():
        print(f"  - {folder}: {count}")

def remove_empty_dirs():
    """Remove pastas que ficaram vazias após a movimentação."""
    print("\n[*] Removendo diretórios vazios restantes...")
    deleted = 0
    # Walk bottom-up (de baixo para cima) é essencial para apagar pastas aninhadas vazias
    for root, dirs, files in os.walk(BASE_DIR, topdown=False):
        for d in dirs:
            full_path = Path(root) / d
            # Se não tem arquivos dentro, apaga
            # (Note: pode ter sobrado pastas ocultas ou ignoradas, então checamos try/except)
            try:
                full_path.rmdir() # rmdir só apaga se estiver vazio
                deleted += 1
            except OSError:
                pass # Não está vazia, ignora
    print(f"[OK] {deleted} pastas vazias removidas.")

if __name__ == "__main__":
    print("!!! MODO EXTRACTOR ATIVADO !!!")
    print("Isso vai tirar TODOS os arquivos das subpastas e organizar na raiz.")
    print("Estruturas de projetos serão desfeitas.")
    
    confirm = input(f"Tem certeza que quer organizar {BASE_DIR}? (s/n): ")
    
    if confirm.lower() == 's':
        nuke_garbage()         # 1. Apaga node_modules, etc
        flatten_and_organize() # 2. Puxa tudo pra pastas organizadas (rar, pdf, nix, etc)
        remove_empty_dirs()    # 3. Limpa o esqueleto de pastas vazias
        print("\nProcesso concluído. Tudo limpo e organizado.")
    else:
        print("Cancelado.")
