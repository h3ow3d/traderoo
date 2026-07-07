APP_NAME ?= traderoo
NAMESPACE ?= traderoo-poc
CLUSTER_NAME ?= traderoo
ARGOCD_NAMESPACE ?= argocd
ARGOCD_APP_NAME ?= traderoo
K3D_CONFIG ?= platform/k3d/cluster.yaml
K8S_LOCAL_OVERLAY ?= applications/traderoo/k8s/overlays/local
ARGOCD_APP_MANIFEST ?= applications/traderoo/argocd/application.yaml

.PHONY: \
	cluster-create cluster-delete cluster-status \
	argocd-install argocd-password argocd-port-forward argocd-status \
	argocd-apply-app argocd-sync argocd-get argocd-delete-app \
	validate-k8s-local

cluster-create:
	k3d cluster create --config $(K3D_CONFIG)

cluster-delete:
	k3d cluster delete $(CLUSTER_NAME)

cluster-status:
	k3d cluster list
	kubectl get nodes

argocd-install:
	kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply --server-side -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-password:
	kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

argocd-port-forward:
	kubectl -n $(ARGOCD_NAMESPACE) port-forward svc/argocd-server 8081:443

argocd-status:
	kubectl get pods -n $(ARGOCD_NAMESPACE)

argocd-apply-app:
	kubectl apply -f $(ARGOCD_APP_MANIFEST)

argocd-sync:
	argocd app sync $(ARGOCD_APP_NAME)

argocd-get:
	argocd app get $(ARGOCD_APP_NAME)

argocd-delete-app:
	kubectl delete -f $(ARGOCD_APP_MANIFEST)

validate-k8s-local:
	kubectl apply -k $(K8S_LOCAL_OVERLAY)
	kubectl get ns $(NAMESPACE)
	kubectl get configmap $(APP_NAME)-config -n $(NAMESPACE)
