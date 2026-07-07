# Argo CD install (local k3d)

Install Argo CD into the local cluster after creating the `traderoo` k3d cluster.

## Install

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Verify

```bash
kubectl get pods -n argocd
```

## Get initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

## Port forward UI

```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443
```

Open: https://localhost:8081

## Root Applications

Apply once after Argo CD installation:

```bash
kubectl apply -f platform/bootstrap/argocd/root-platform-application.yaml
kubectl apply -f platform/bootstrap/argocd/root-applications-application.yaml
```
