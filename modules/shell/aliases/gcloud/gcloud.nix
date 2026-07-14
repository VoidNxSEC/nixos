{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Google Cloud Platform Aliases
# ============================================================

{
  # Gate da Fase 4: config era incondicional; default true preserva o
  # sistema como está e permite desligar por host/specialisation.
  options.kernelcore.shell.aliases.gcloud.enable = lib.mkEnableOption "gcloud aliases" // {
    default = true;
  };

  config = lib.mkIf config.kernelcore.shell.aliases.gcloud.enable {
    environment.shellAliases = {
      # Basic (note: 'gc' is reserved for 'git commit', use 'gcloud' or 'gc-*' aliases)
      "gc-config" = "gcloud config list";
      "gc-projects" = "gcloud projects list";
      "gc-set-project" = "gcloud config set project";

      # Compute Engine
      "gc-vms" = "gcloud compute instances list";
      "gc-ssh" = "gcloud compute ssh";
      "gc-start" = "gcloud compute instances start";
      "gc-stop" = "gcloud compute instances stop";

      # Kubernetes Engine (GKE)
      "gke-clusters" = "gcloud container clusters list";
      "gke-get-creds" = "gcloud container clusters get-credentials";

      # Cloud Storage
      "gs-list" = "gsutil ls";
      "gs-cp" = "gsutil cp";
      "gs-sync" = "gsutil -m rsync -r";

      # Logs
      "gc-logs" = "gcloud logging read --limit 50";
      "gc-logs-tail" = "gcloud logging tail";

      # IAM
      "gc-accounts" = "gcloud auth list";
      "gc-switch" = "gcloud config set account";
    };
  };
}
