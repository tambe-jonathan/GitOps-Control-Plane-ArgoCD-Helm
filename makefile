---

```makefile
# Variables
NAMESPACE=argocd
APP_NAMESPACE=webapp
DEPLOY_NAME=devops-taskmaster

.PHONY: bootstrap password forward test-drift clean

# 1. Full Bootstrap
bootstrap:
	@echo "Creating ArgoCD Namespace..."
	kubectl create namespace $(NAMESPACE) || true
	@echo "Installing ArgoCD..."
	kubectl apply -n $(NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD Server..."
	kubectl wait --for=condition=available deployment/argocd-server -n $(NAMESPACE) --timeout=300s
	@echo "Applying Root Application..."
	kubectl apply -f gitops/clusters/production/application.yaml

# 2. Get Admin Password
password:
	@kubectl -n $(NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# 3. Port Forward UI
forward:
	@echo "ArgoCD UI available at https://localhost:8080"
	kubectl port-forward svc/argocd-server -n $(NAMESPACE) 8080:443

# 4. Run SRE Drift Test
test-drift:
	@chmod +x scripts/simulate-drift.sh
	@./scripts/simulate-drift.sh

# 5. Cleanup
clean:
	kubectl delete ns $(NAMESPACE)
	kubectl delete ns $(APP_NAMESPACE)
