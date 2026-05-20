# k8s-gitops-homelab

A self-managed Kubernetes cluster (k3s) with full GitOps via ArgoCD,
Helm charts authored from scratch, Terraform provisioning,
and Prometheus + Grafana monitoring.

## Stack
- **k3s** — lightweight self-managed Kubernetes
- **ArgoCD** — GitOps controller (Git is the source of truth)
- **Helm** — app packaging (charts written from scratch)
- **Terraform/OpenTofu** — infrastructure as code
- **Prometheus + Grafana** — observability
