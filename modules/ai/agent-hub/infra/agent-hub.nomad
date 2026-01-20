job "agent-hub-nexus" {
  datacenters = ["dc1"]
  type        = "service"

  group "control-plane" {
    count = 1
    
    task "nexus-core" {
      driver = "raw_exec"
      config {
        command = "/etc/nixos/modules/ai/agent-hub/core/target/release/nexus-core"
      }
      
      resources {
        cpu    = 500
        memory = 256
      }
    }

    task "gitops-worker" {
      driver = "wasm" # Requer plugin wasmtime-nomad
      config {
        wasm_file = "/etc/nixos/modules/ai/agent-hub/agents/gitops_agent.wasm"
      }
      
      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
