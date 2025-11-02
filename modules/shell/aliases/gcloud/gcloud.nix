{ config, pkgs, lib, ... }:

# ============================================================
# Google Cloud Platform Aliases
# ============================================================

{
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
}
