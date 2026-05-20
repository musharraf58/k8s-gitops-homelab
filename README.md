# k8s-gitops-homelab

A self-managed Kubernetes cluster built from scratch to simulate a production-grade DevOps environment. Every component is provisioned as code, deployed via GitOps, and monitored with a full observability stack.

## Stack

| Layer | Tool | Purpose |
|---|---|---|
| Cluster | k3s | Lightweight self-managed Kubernetes |
| GitOps | ArgoCD + ApplicationSets | Git as single source of truth |
| Packaging | Helm (authored from scratch) | App templating and deployment |
| IaC | Terraform / OpenTofu | Infrastructure as code |
| Observability | Prometheus + Grafana | Metrics and dashboards |
| CI | GitHub Actions | Lint and validate on every push |

## Architecture
GitHub repo (source of truth)
|
|-- terraform/        # provisions infrastructure
|-- charts/           # helm charts authored from scratch
|   |-- nginx-app/    # stateless web app
|   +-- postgres-app/ # stateful workload with PVC
|-- apps/             # argocd applicationset
+-- .github/workflows # ci pipeline
|
v
ArgoCD (watches Git, syncs cluster)
|
v
k3s cluster
|-- apps namespace
|   |-- nginx-app (2 replicas)
|   +-- postgres-app (StatefulSet + PVC)
+-- monitoring namespace
|-- Prometheus
+-- Grafana

## Key design decisions

**GitOps over manual kubectl** — no workload is applied by hand. ArgoCD selfHeal and prune flags ensure the cluster always matches Git. If someone manually changes a resource, ArgoCD corrects it within 3 minutes.

**Helm authoring over Helm install** — charts are written from scratch with templates, helpers, and values files. This makes the packaging logic transparent and auditable.

**Stateful workloads** — Postgres runs as a StatefulSet with a PersistentVolumeClaim. Data survives pod restarts and rescheduling.

**Blast radius awareness** — infrastructure changes are tested locally with helm lint and tofu validate before pushing. The CI pipeline enforces this on every commit.

## Runbook

### Check cluster health
```bash
kubectl get nodes
kubectl get pods -A
```

### Check ArgoCD sync status
```bash
argocd app list
argocd app get nginx-app
argocd app get postgres-app
```

### Force a sync
```bash
argocd app sync nginx-app
argocd app sync postgres-app
```

### Access Grafana
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# open http://localhost:3000 — admin / homelab123
```

### Access ArgoCD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# open https://localhost:8080 — admin
```

### Safely update a Helm chart
1. Edit the chart in charts/
2. Run helm lint charts/<chart-name> locally
3. Commit and push to main
4. ArgoCD detects the change and syncs automatically
5. Verify with argocd app get <app-name> and kubectl get pods -n apps

### What to do if a pod is stuck
```bash
# describe the pod for events
kubectl describe pod <pod-name> -n <namespace>

# check logs
kubectl logs <pod-name> -n <namespace>

# check node resources
kubectl top nodes
kubectl top pods -A
```

## Lessons learned

- ImagePullBackOff in restricted networks is a timeout issue, not a registry block — retrying with --timeout 10m resolved it
- ArgoCD sync status Unknown means the app was created but not yet synced — argocd app sync forces it
- StatefulSets require a headless service and PVC template — different from a standard Deployment

## Local setup

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Configure kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply ApplicationSet
kubectl apply -f apps/applicationset.yaml

# Install monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=homelab123 \
  --set alertmanager.enabled=false \
  --timeout 10m0s
```
