# Phoenix Cloud Run - Aliases Inteligentes para NixOS
# Adicione ao seu configuration.nix ou home-manager

{ config, pkgs, ... }:

let
  phoenixDir = "/home/kernelcore/dev/low-level/phoenix-cloud-run";

  # Smart functions para shell
  phoenixFunctions = ''
        # Phoenix Query - Execute query de qualquer lugar
        pxq() {
          if [ -z "$1" ]; then
            echo "Usage: pxq 'your query here'"
            echo "Example: pxq 'how to configure nvidia on nixos'"
            return 1
          fi

          local query="$*"
          local tmpfile=$(mktemp)
          echo "$query" > "$tmpfile"

          cd ${phoenixDir}
          nix develop --command python scripts/batch_burn.py \
            --file "$tmpfile" \
            --project ''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234} \
            --location ''${GOOGLE_CLOUD_LOCATION:-global} \
            --engine "$ENGINE_ID" \
            --workers 1

          rm "$tmpfile"
          cd - > /dev/null
        }

        # Phoenix Batch - Process file de qualquer lugar
        pxb() {
          local file="$1"
          local workers="''${2:-10}"

          if [ ! -f "$file" ]; then
            echo "Error: File not found: $file"
            return 1
          fi

          cd ${phoenixDir}
          nix develop --command python scripts/batch_burn.py \
            --file "$(realpath "$file")" \
            --project ''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234} \
            --location ''${GOOGLE_CLOUD_LOCATION:-global} \
            --engine "$ENGINE_ID" \
            --workers "$workers"
          cd - > /dev/null
        }

        # Phoenix Generate - Gera queries com tema
        pxg() {
          local count="''${1:-100}"
          local output="''${2:-queries_$(date +%Y%m%d_%H%M%S).txt}"

          cd ${phoenixDir}
          nix develop --command python scripts/generate_queries.py \
            --count "$count" \
            --output "$output"

          echo "Generated: $(realpath $output)"
          cd - > /dev/null
        }

        # Phoenix Smart Query - Com contexto do diretório atual
        pxqs() {
          if [ -z "$1" ]; then
            echo "Usage: pxqs 'query with context'"
            return 1
          fi

          local query="$*"
          local context=""

          # Detecta contexto baseado em arquivos no dir atual
          if [ -f "flake.nix" ]; then
            context="NixOS flake context: "
          elif [ -f "Cargo.toml" ]; then
            context="Rust project context: "
          elif [ -f "go.mod" ]; then
            context="Go project context: "
          elif [ -f "package.json" ]; then
            context="Node.js project context: "
          elif [ -f "Dockerfile" ]; then
            context="Docker project context: "
          fi

          pxq "$context$query"
        }

        # Phoenix Status - Ver status de créditos
        pxst() {
          cd ${phoenixDir}
          nix develop --command python scripts/monitor_credits.py \
            --project ''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234} \
            --once
          cd - > /dev/null
        }

        # Phoenix Strategy - Run optimizer
        pxopt() {
          cd ${phoenixDir}
          nix develop --command python scripts/strategy_optimizer.py
          cat MASTER_EXECUTION_PLAN.md
          cd - > /dev/null
        }

        # Phoenix Salary Intel
        pxsal() {
          local current="''${1:-150000}"
          local target="''${2:-300000}"

          cd ${phoenixDir}
          nix develop --command python scripts/salary_intel.py \
            --current "$current" \
            --target "$target" \
            --execute
          cd - > /dev/null
        }

        # Phoenix Trend Predictor
        pxtrend() {
          cd ${phoenixDir}
          nix develop --command python scripts/trend_predictor.py --execute
          cd - > /dev/null
        }

        # Phoenix Content Miner
        pxmine() {
          cd ${phoenixDir}
          nix develop --command python scripts/content_gold_miner.py

          if [ -f "content_output/content_calendar_30days.md" ]; then
            less content_output/content_calendar_30days.md
          fi
          cd - > /dev/null
        }

        # Phoenix Moat Builder
        pxmoat() {
          cd ${phoenixDir}
          nix develop --command python scripts/personal_moat_builder.py --execute

          if [ -f "moat_building_strategy.md" ]; then
            less moat_building_strategy.md
          fi
          cd - > /dev/null
        }

        # Phoenix GCloud Setup - Auto-configure gcloud
        pxsetup() {
          echo "🔧 Phoenix GCloud Setup"

          # Check gcloud auth
          if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1; then
            echo "📝 Setting up gcloud authentication..."
            gcloud auth application-default login
          fi

          # Set project
          gcloud config set project ''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234}

          # Enable APIs
          echo "🔌 Enabling required APIs..."
          gcloud services enable discoveryengine.googleapis.com \
            --project=''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234}

          gcloud services enable dialogflow.googleapis.com \
            --project=''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234}

          gcloud services enable bigquery.googleapis.com \
            --project=''${GOOGLE_CLOUD_PROJECT:-gen-lang-client-0530325234}

          echo "✅ Setup complete!"
          echo ""
          echo "Next: Set ENGINE_ID environment variable"
          echo "export ENGINE_ID=your-discovery-engine-id"
        }

        # Phoenix List Results - Ver resultados recentes
        pxls() {
          cd ${phoenixDir}
          echo "📊 Recent batch results:"
          ls -lht batch_results_*.json 2>/dev/null | head -n 5

          if [ -n "$1" ]; then
            echo ""
            echo "📄 Content of latest:"
            jq -r '.results[] | "\(.question)\n  → \(.answer[:200])...\n"' \
              "$(ls -t batch_results_*.json | head -n 1)" | head -n 20
          fi
          cd - > /dev/null
        }

        # Phoenix Search Results - Busca em results
        pxfind() {
          if [ -z "$1" ]; then
            echo "Usage: pxfind 'search term'"
            return 1
          fi

          cd ${phoenixDir}
          echo "🔍 Searching for: $1"

          for file in batch_results_*.json; do
            if [ -f "$file" ]; then
              matches=$(jq -r ".results[] | select(.question | contains(\"$1\")) | .question" "$file")
              if [ -n "$matches" ]; then
                echo ""
                echo "📄 $file:"
                echo "$matches"
              fi
            fi
          done
          cd - > /dev/null
        }

        # Phoenix Interactive Query - Com prompt interativo
        pxi() {
          echo "🧠 Phoenix Interactive Query"
          echo ""
          echo -n "Query: "
          read query

          if [ -z "$query" ]; then
            echo "Cancelled."
            return 0
          fi

          echo ""
          echo -n "Workers [10]: "
          read workers
          workers="''${workers:-10}"

          echo ""
          echo "Executing: $query"
          echo "Workers: $workers"
          echo ""

          pxq "$query"
        }

        # Phoenix Daily Digest - Workflow completo
        pxdaily() {
          echo "📅 Phoenix Daily Digest"
          echo ""

          cd ${phoenixDir}

          # Generate queries
          echo "1️⃣ Generating daily queries..."
          nix develop --command python scripts/generate_queries.py \
            --count 50 \
            --output "queries_daily_$(date +%Y%m%d).txt"

          # Execute
          echo ""
          echo "2️⃣ Processing queries..."
          ./speedrun.sh burn "queries_daily_$(date +%Y%m%d).txt" 10

          # Mine content
          echo ""
          echo "3️⃣ Mining for content..."
          nix develop --command python scripts/content_gold_miner.py

          # Status
          echo ""
          echo "4️⃣ Credit status:"
          pxst

          cd - > /dev/null
        }

        # Phoenix Help
        pxhelp() {
          cat <<'EOF'
    🔥 PHOENIX ALIASES - Quick Reference

    QUERY EXECUTION:
      pxq 'query'           Single query from anywhere
      pxqs 'query'          Smart query (auto-detects context)
      pxb file [workers]    Batch process file
      pxi                   Interactive query prompt

    GENERATION:
      pxg [count] [output]  Generate queries
      pxsal [curr] [target] Salary negotiation queries
      pxtrend               Trend prediction queries
      pxmoat                Personal moat queries

    ANALYSIS:
      pxmine                Mine content from results
      pxopt                 Run strategy optimizer
      pxst                  Credit status
      pxls [verbose]        List recent results
      pxfind 'term'         Search in results

    WORKFLOWS:
      pxdaily               Daily digest workflow
      pxsetup               GCloud setup

    UTILS:
      pxhelp                This help

    EXAMPLES:
      pxq 'how to configure nvidia on nixos'
      pxqs 'best practices for this project'
      pxb my_queries.txt 20
      pxsal 150000 300000
      pxmine

    ENVIRONMENT VARIABLES:
      ENGINE_ID                    Discovery Engine ID (required)
      GOOGLE_CLOUD_PROJECT         GCP Project (default: gen-lang-client-0530325234)
      GOOGLE_CLOUD_LOCATION        Location (default: global)
    EOF
        }

        # Phoenix CD - Quick navigate
        pxcd() {
          cd ${phoenixDir}
        }

        # Phoenix Edit - Edit docs
        pxedit() {
          local file="''${1:-EXECUTIVE_SUMMARY.md}"
          cd ${phoenixDir}
          ''${EDITOR:-nvim} "$file"
          cd - > /dev/null
        }
  '';

in
{
  # Environment variables
  environment.variables = {
    PHOENIX_DIR = phoenixDir;
    GOOGLE_CLOUD_PROJECT = "gen-lang-client-0530325234";
    GOOGLE_CLOUD_LOCATION = "global";
  };

  # Shell initialization
  programs.bash.interactiveShellInit = phoenixFunctions;
  programs.zsh.interactiveInit = phoenixFunctions;
  programs.fish.interactiveShellInit = ''
    # Convert bash functions to fish (simplified)
    function pxhelp
      bash -c 'source ${phoenixDir}/nix/phoenix-aliases.nix; pxhelp'
    end
  '';

  # Aliases simples (compatibilidade)
  environment.shellAliases = {
    # Phoenix core
    px = "cd ${phoenixDir}";
    pxh = "pxhelp";

    # GCloud integration
    gcpx = "gcloud config set project gen-lang-client-0530325234";
    gcpxs = "gcloud services list --enabled --project=gen-lang-client-0530325234";

    # Quick docs
    pxdoc = "less ${phoenixDir}/EXECUTIVE_SUMMARY.md";
    pxhacks = "less ${phoenixDir}/HACKS_ROI.md";
    pxqueries = "less ${phoenixDir}/HIGH_ROI_QUERIES.md";
  };

  # Completion (bash)
  environment.etc."bash_completion.d/phoenix".text = ''
    # Phoenix completion
    _phoenix_complete() {
      local cur prev
      COMPREPLY=()
      cur="''${COMP_WORDS[COMP_CWORD]}"
      prev="''${COMP_WORDS[COMP_CWORD-1]}"

      case "$prev" in
        pxedit)
          local files="EXECUTIVE_SUMMARY.md HACKS_ROI.md HIGH_ROI_QUERIES.md VICTORY_PLAYBOOK.md"
          COMPREPLY=( $(compgen -W "$files" -- "$cur") )
          return 0
          ;;
      esac

      return 0
    }
    complete -F _phoenix_complete pxedit
  '';
}
