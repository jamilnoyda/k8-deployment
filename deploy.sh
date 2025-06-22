#!/bin/bash
# deploy.sh - Deploy microservices to Kubernetes

set -e

echo "Deploying microservices to Kubernetes..."

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
echo "Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

# Deploy services
echo "Deploying Users Service..."
kubectl apply -f k8s/users-deployment.yaml
kubectl apply -f k8s/users-service.yaml

echo "Deploying Todos Service..."
kubectl apply -f k8s/todos-deployment.yaml
kubectl apply -f k8s/todos-service.yaml

# Apply Ingress
echo "Applying Ingress..."
kubectl apply -f k8s/ingress.yaml

# Apply HPA
echo "Applying Horizontal Pod Autoscaler..."
kubectl apply -f k8s/hpa.yaml

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/users-service -n microservices
kubectl rollout status deployment/todos-service -n microservices

echo "Deployment complete!"
echo ""
echo "Services status:"
kubectl get pods -n microservices
echo ""
echo "Services endpoints:"
kubectl get svc -n microservices
echo ""
echo "To test the services locally, add this to your /etc/hosts:"
echo "127.0.0.1 microservices.local"
echo ""
echo "Then access:"
echo "Users API: http://microservices.local/api/users"
echo "Todos API: http://microservices.local/api/todos"