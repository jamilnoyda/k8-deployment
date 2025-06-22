#!/bin/bash
# build.sh - Build and push Docker images

set -e

# Configuration
REGISTRY=${REGISTRY:-"jamilnoyda"}
TAG=${TAG:-"latest"}

echo "Building microservices images..."

# Build Users Service
echo "Building users-service..."
cd users-service
docker build -t ${REGISTRY}/users-service:${TAG} .
docker push ${REGISTRY}/users-service:${TAG}
cd ..

# Build Todos Service
echo "Building todos-service..."
cd todos-service
docker build -t ${REGISTRY}/todos-service:${TAG} .
docker push ${REGISTRY}/todos-service:${TAG}
cd ..

echo "All images built and pushed successfully!"
echo "Users Service: ${REGISTRY}/users-service:${TAG}"
echo "Todos Service: ${REGISTRY}/todos-service:${TAG}"

# chmod +x executable   