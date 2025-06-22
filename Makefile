# Makefile
.PHONY: help build deploy clean test local-up local-down

# Configuration
REGISTRY ?= localhost:5000
TAG ?= latest
NAMESPACE ?= microservices

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Docker images
	@echo "Building Docker images..."
	cd users-service && docker build -t users-service:$(TAG) .
	cd todos-service && docker build -t todos-service:$(TAG) .

build-push: ## Build and push Docker images
	@echo "Building and pushing Docker images..."
	cd users-service && docker build -t $(REGISTRY)/users-service:$(TAG) . && docker push $(REGISTRY)/users-service:$(TAG)
	cd todos-service && docker build -t $(REGISTRY)/todos-service:$(TAG) . && docker push $(REGISTRY)/todos-service:$(TAG)

deploy: ## Deploy to Kubernetes
	@echo "Deploying to Kubernetes..."
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/configmap.yaml
	kubectl apply -f k8s/users-deployment.yaml