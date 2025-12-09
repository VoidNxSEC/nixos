● Aqui estão as melhores formas de usar o tree ignorando arquivos específicos:

🌳 Comando Tree com Filtros

Opção 1: Ignorar Múltiplos Padrões (Recomendado)

tree -I 'node_modules|_.ts|_.map'

Explicação:

- -I = ignore pattern
- | = separador OR (pipe)
- Sem espaços entre os padrões!

Opção 2: Com Profundidade Limitada

tree -L 3 -I 'node_modules|_.ts|_.map|\*.js.map|.git'

Onde:

- -L 3 = máximo 3 níveis de profundidade
- Adiciona mais padrões conforme necessário

Opção 3: Ignorar Só Diretórios vs Arquivos

# Ignorar node_modules e .git (diretórios)

tree -I 'node_modules|.git|.venv|**pycache**'

# Ignorar extensões (arquivos)

tree -I '_.ts|_.map|\*.pyc'

# Combinar ambos

tree -I 'node_modules|.git|_.ts|_.map|\*.pyc|**pycache**'

Opção 4: Tree Mais Limpo (Sem Ícones)

tree -I 'node_modules|_.ts|_.map' --charset ascii

Opção 5: Padrão Completo Para Projetos JS/TS

tree -L 4 -I 'node_modules|dist|build|_.ts|_.map|\*.js.map|.git|coverage|.next'

Opção 6: Padrão Para Projetos Python

tree -L 3 -I '.venv|**pycache**|_.pyc|_.pyo|\*.egg-info|.git|.ipynb_checkpoints'

🎨 Opções Úteis Adicionais

# Mostrar apenas diretórios

tree -d -I 'node_modules|.git'

# Mostrar permissões e tamanhos

tree -psh -I 'node_modules|\*.map'

# Colorido (padrão no Linux)

tree -C -I 'node_modules|\*.ts'

# Salvar em arquivo

tree -I 'node_modules|_.ts|_.map' > estrutura.txt

# Mostrar arquivos ocultos também

tree -a -I 'node_modules|.git'

💡 Exemplo Prático Para Este Projeto

# Ver estrutura limpa dos kits

tree -L 3 -I '.venv|ComfyUI|node_modules|\*.pyc|**pycache**|.git|.ipynb_checkpoints' kits/

# Ver toda a estrutura (mais limpa)

tree -L 2 -I '.venv|ComfyUI|node_modules|models|ollama-models|koboldcpp-models|.Trash-0'

📝 Alias Útil (Adicionar ao ~/.bashrc)

# Adicione no seu ~/.bashrc ou ~/.zshrc

alias treeclean='tree -I "node_modules|.git|.venv|**pycache**|_.pyc|_.map|.ipynb_checkpoints|dist|build|coverage"'

# Usar:

treeclean
treeclean -L 3
treeclean kits/

🔍 Pattern Matching

O -I aceita glob patterns:

_.ts # Todos arquivos .ts
node_modules # Diretório node_modules
test_ # Tudo que começa com 'test'
_.test.js # Arquivos de teste
\_\__ # Tudo que começa com \_\_

⚡ Quick Reference

# Básico

tree -I 'node_modules'

# Múltiplos

tree -I 'node_modules|.git|dist'

# Com profundidade

tree -L 3 -I 'node_modules|\*.map'

# Só diretórios

tree -d -I 'node_modules'

# Com tamanhos

tree -h -I 'node_modules'

Dica: Sempre use aspas simples '...' para evitar que o shell interprete os caracteres especiais!
