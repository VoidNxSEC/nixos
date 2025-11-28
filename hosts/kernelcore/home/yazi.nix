{
  config,
  pkgs,
  lib,
  ...
}:

# Configuração completa do Yazi file manager no home-manager.
# Inclui atalhos customizados para triagem rápida de arquivos.

let
  # Defina seus caminhos de triagem aqui para ficar fácil de mudar depois
  dirDocs = "~/Documentos/Processados";
  dirImages = "~/Imagens/Processadas";
  dirTrash = "~/Lixo_Temporario";

  # Função auxiliar para gerar o comando shell seguro
  # Cria a pasta se não existir (mkdir -p) e move o arquivo ($0)
  mkMoveCmd = dir: "shell 'mkdir -p ${dir} && mv \"$0\" ${dir}/' --confirm";
in
{
  programs.yazi = {
    enable = true;

    # Habilita integração com Bash e Zsh
    # Isso cria a função yy() que muda o diretório ao sair do Yazi
    enableBashIntegration = true;
    enableZshIntegration = true;

    # Configurações Visuais e de Comportamento (yazi.toml)
    settings = {
      manager = {
        show_hidden = false;
        sort_by = "mtime"; # Ordenar por data de modificação (útil para ver o que chegou por último)
        sort_reverse = true; # Mais recentes primeiro
        sort_sensitive = false;
      };
      preview = {
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
      };
    };

    # Mapeamento de Teclas (keymap.toml)
    # A mágica acontece aqui. Usamos 'prepend_keymap' para não perder os atalhos originais.
    keymap = {
      manager.prepend_keymap = [
        # Atalho 1: Move para Documentos
        {
          on = [ "1" ];
          run = mkMoveCmd dirDocs;
          desc = "Mover para Docs (Processados)";
        }

        # Atalho 2: Move para Imagens
        {
          on = [ "2" ];
          run = mkMoveCmd dirImages;
          desc = "Mover para Imagens";
        }

        # Atalho 3: "Lixo" (ou outra categoria)
        {
          on = [ "3" ];
          run = mkMoveCmd dirTrash;
          desc = "Mover para Lixo Temp";
        }

        # Extra: Espaço para preview rápido (se já não for padrão)
        {
          on = [ "<Space>" ];
          run = "peek";
          desc = "Espiar arquivo";
        }
      ];
    };
  };
}
