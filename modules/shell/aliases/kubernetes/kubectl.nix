{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# Kubernetes kubectl Aliases
# ============================================================

{
  # Gate da Fase 4: config era incondicional; default true preserva o
  # sistema como está e permite desligar por host/specialisation.
  options.kernelcore.shell.aliases.kubectl.enable = lib.mkEnableOption "kubectl aliases" // {
    default = true;
  };

  config = lib.mkIf config.kernelcore.shell.aliases.kubectl.enable {
    environment.shellAliases = {
      # Basic
      "k" = "kubectl";
      "k-get" = "kubectl get";
      "k-describe" = "kubectl describe";
      "k-delete" = "kubectl delete";
      "k-apply" = "kubectl apply -f";

      # Pods
      "k-pods" = "kubectl get pods";
      "k-pods-all" = "kubectl get pods --all-namespaces";
      "k-pod-logs" = "kubectl logs -f";
      "k-pod-exec" = "kubectl exec -it";
      "k-pod-shell" = ''
        f() { kubectl exec -it "$1" -- /bin/bash || kubectl exec -it "$1" -- /bin/sh; }; f
      '';

      # Services & Deployments
      "k-svc" = "kubectl get services";
      "k-deploy" = "kubectl get deployments";
      "k-nodes" = "kubectl get nodes";

      # Port Forward
      "k-port" = "kubectl port-forward";

      # Context
      "k-ctx" = "kubectl config current-context";
      "k-ctx-use" = "kubectl config use-context";
      "k-ctx-list" = "kubectl config get-contexts";

      # Namespace
      "k-ns" = "kubectl config set-context --current --namespace";

      # Watch
      "k-watch-pods" = "watch -n 2 kubectl get pods";
      "k-watch-all" = "watch -n 2 kubectl get all";
    };
  };
}
