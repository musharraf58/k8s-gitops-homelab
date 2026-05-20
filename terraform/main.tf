terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# This documents the infrastructure that was provisioned manually.
# In a cloud setup (Scaleway/GCP) these would be real resources.
# For this homelab we are running directly on a Linux machine.

resource "local_file" "cluster_info" {
  content  = <<-EOT
    Cluster: k8s-gitops-homelab
    Distribution: k3s
    Node: single-node (Linux desktop)
    RAM: 30Gi
    CPUs: 12
  EOT
  filename = "${path.module}/cluster-info.txt"
}
