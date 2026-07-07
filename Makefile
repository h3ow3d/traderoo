APP_NAME ?= traderoo
NAMESPACE ?= traderoo-poc
CLUSTER_NAME ?= traderoo
ARGOCD_NAMESPACE ?= argocd
ARGOCD_APP_NAME ?= traderoo-poc
GHCR_OWNER ?= h3ow3d
GHCR_IMAGE ?= ghcr.io/$(GHCR_OWNER)/traderoo:latest
LOCAL_IMAGE ?= traderoo:local
IMAGE_NAME ?= $(GHCR_IMAGE)
K3D_CONFIG ?= platform/k3d/cluster.yaml
K8S_POC_OVERLAY ?= applications/traderoo/k8s/overlays/poc
ARGOCD_APP_MANIFEST ?= applications/traderoo/argocd/poc.yaml
PLATFORM_CHART ?= platform/charts/platform-services

.PHONY: \
	cluster-create cluster-delete cluster-status \
	install run test docker-build docker-run image-name validate-image-ref kustomize-traderoo-poc validate \
	argocd-install argocd-password argocd-port-forward argocd-status \
	argocd-apply-app argocd-sync argocd-get argocd-delete-app \
	validate-k8s-local \
	helm-lint-platform helm-template-platform validate-platform-services \
	platform-apply platform-status traderoo-image-import traderoo-apply traderoo-status bootstrap-local

install:
	python3 -m pip install -e app[dev]

run:
	uvicorn traderoo.main:app --host 0.0.0.0 --port 8000 --app-dir app

test:
	python3 -m pytest app/tests

docker-build:
	docker build -t $(LOCAL_IMAGE) -t $(IMAGE_NAME) app

docker-run:
	docker run --rm -p 8000:8000 $(LOCAL_IMAGE)

image-name:
	@echo $(IMAGE_NAME)

validate-image-ref:
	@echo "$(IMAGE_NAME)" | grep -E '^ghcr\.io/[^/]+/traderoo:latest$$'

kustomize-traderoo-poc:
	kubectl kustomize $(K8S_POC_OVERLAY)

validate: test validate-platform-services kustomize-traderoo-poc

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
	kubectl apply -k $(K8S_POC_OVERLAY)
	kubectl get ns $(NAMESPACE)
	kubectl get configmap $(APP_NAME)-config -n $(NAMESPACE)

helm-lint-platform:
	helm lint $(PLATFORM_CHART)

helm-template-platform:
	helm template platform-services $(PLATFORM_CHART) --dry-run=client | tee /tmp/platform-services.yaml >/dev/null

validate-platform-services: helm-lint-platform helm-template-platform
	grep -E "kind: AppProject|name: platform|name: traderoo-poc|kind: Namespace" /tmp/platform-services.yaml
	grep -E "name:[[:space:]]*poc|name:[[:space:]]*applications|name:[[:space:]]*traderoo-dev|name:[[:space:]]*traderoo-staging|name:[[:space:]]*traderoo-demo|name:[[:space:]]*traderoo-production" /tmp/platform-services.yaml && exit 1 || true

platform-apply:
	kubectl apply -f platform/bootstrap/argocd/root-platform-application.yaml

platform-status:
	kubectl get applications -n $(ARGOCD_NAMESPACE)
	kubectl get appprojects -n $(ARGOCD_NAMESPACE)
	kubectl get appproject platform -n $(ARGOCD_NAMESPACE)
	kubectl get appproject traderoo-poc -n $(ARGOCD_NAMESPACE)
	kubectl get ns $(NAMESPACE)

traderoo-apply:
	kubectl apply -f $(ARGOCD_APP_MANIFEST)

traderoo-image-import:
	k3d image import $(LOCAL_IMAGE) -c $(CLUSTER_NAME)

traderoo-status:
	kubectl get application $(ARGOCD_APP_NAME) -n $(ARGOCD_NAMESPACE)
	kubectl get ns $(NAMESPACE)
	kubectl get configmap $(APP_NAME)-config -n $(NAMESPACE)

bootstrap-local: argocd-install platform-apply platform-status traderoo-apply traderoo-status
