#!/bin/bash
# destroy.sh - Clean up and destroy microservices from Kubernetes

set -e

# Configuration
NAMESPACE=${NAMESPACE:-"microservices"}
FORCE=${FORCE:-false}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_warning "Namespace '$NAMESPACE' does not exist. Nothing to destroy."
        exit 0
    fi
}

# Function to show resources before deletion
show_resources() {
    print_status "Current resources in namespace '$NAMESPACE':"
    echo ""
    
    echo "Deployments:"
    kubectl get deployments -n "$NAMESPACE" 2>/dev/null || echo "  No deployments found"
    echo ""
    
    echo "Services:"
    kubectl get services -n "$NAMESPACE" 2>/dev/null || echo "  No services found"
    echo ""
    
    echo "Pods:"
    kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "  No pods found"
    echo ""
    
    echo "Ingress:"
    kubectl get ingress -n "$NAMESPACE" 2>/dev/null || echo "  No ingress found"
    echo ""
    
    echo "HPA:"
    kubectl get hpa -n "$NAMESPACE" 2>/dev/null || echo "  No HPA found"
    echo ""
    
    echo "ConfigMaps:"
    kubectl get configmaps -n "$NAMESPACE" 2>/dev/null || echo "  No configmaps found"
    echo ""
}

# Function to confirm deletion
confirm_deletion() {
    if [ "$FORCE" != "true" ]; then
        echo ""
        print_warning "This will DELETE ALL resources in the '$NAMESPACE' namespace!"
        print_warning "This action CANNOT be undone!"
        echo ""
        read -p "Are you sure you want to continue? (yes/no): " -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_status "Destruction cancelled."
            exit 0
        fi
    fi
}

# Function to delete specific resources
delete_resources() {
    print_status "Starting destruction of microservices..."
    echo ""
    
    # Delete HPA first (to prevent recreation of pods)
    print_status "Deleting Horizontal Pod Autoscalers..."
    if kubectl get hpa -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl delete hpa --all -n "$NAMESPACE" --ignore-not-found=true
        print_status "HPA deleted successfully"
    else
        print_warning "No HPA found to delete"
    fi
    echo ""
    
    # Delete Ingress
    print_status "Deleting Ingress..."
    if kubectl get ingress -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl delete ingress --all -n "$NAMESPACE" --ignore-not-found=true
        print_status "Ingress deleted successfully"
    else
        print_warning "No Ingress found to delete"
    fi
    echo ""
    
    # Delete Services
    print_status "Deleting Services..."
    if kubectl get services -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl delete services --all -n "$NAMESPACE" --ignore-not-found=true
        print_status "Services deleted successfully"
    else
        print_warning "No Services found to delete"
    fi
    echo ""
    
    # Delete Deployments
    print_status "Deleting Deployments..."
    if kubectl get deployments -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl delete deployments --all -n "$NAMESPACE" --ignore-not-found=true
        print_status "Deployments deleted successfully"
    else
        print_warning "No Deployments found to delete"
    fi
    echo ""
    
    # Delete ConfigMaps
    print_status "Deleting ConfigMaps..."
    if kubectl get configmaps -n "$NAMESPACE" >/dev/null 2>&1; then
        kubectl delete configmaps --all -n "$NAMESPACE" --ignore-not-found=true
        print_status "ConfigMaps deleted successfully"
    else
        print_warning "No ConfigMaps found to delete"
    fi
    echo ""
    
    # Wait for pods to terminate
    print_status "Waiting for pods to terminate..."
    kubectl wait --for=delete pods --all -n "$NAMESPACE" --timeout=60s 2>/dev/null || true
    echo ""
}

# Function to delete namespace
delete_namespace() {
    print_status "Deleting namespace '$NAMESPACE'..."
    if kubectl delete namespace "$NAMESPACE" --ignore-not-found=true; then
        print_status "Namespace deleted successfully"
    else
        print_error "Failed to delete namespace"
        exit 1
    fi
    echo ""
}

# Function to clean up Docker images (optional)
cleanup_docker_images() {
    if command -v docker >/dev/null 2>&1; then
        print_status "Cleaning up Docker images..."
        
        # Remove unused images
        docker image prune -f >/dev/null 2>&1 || true
        
        # Remove specific service images if they exist
        docker rmi users-service:latest >/dev/null 2>&1 || true
        docker rmi todos-service:latest >/dev/null 2>&1 || true
        
        print_status "Docker cleanup completed"
    else
        print_warning "Docker not found, skipping image cleanup"
    fi
    echo ""
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_error "Namespace '$NAMESPACE' still exists!"
        exit 1
    else
        print_status "Namespace '$NAMESPACE' successfully removed"
    fi
    
    echo ""
    print_status "Cleanup verification completed successfully!"
}

# Main execution
main() {
    echo "=========================================="
    echo "  Kubernetes Microservices Destroyer"
    echo "=========================================="
    echo ""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                FORCE=true
                shift
                ;;
            --namespace|-n)
                NAMESPACE="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -f, --force              Skip confirmation prompts"
                echo "  -n, --namespace NAME     Specify namespace (default: microservices)"
                echo "  --keep-namespace         Delete resources but keep namespace"
                echo "  --docker-cleanup         Also cleanup Docker images"
                echo "  -h, --help              Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                       # Interactive destruction"
                echo "  $0 --force               # Force destruction without prompts"
                echo "  $0 -n my-namespace       # Destroy specific namespace"
                echo "  $0 --docker-cleanup      # Also cleanup Docker images"
                exit 0
                ;;
            --keep-namespace)
                KEEP_NAMESPACE=true
                shift
                ;;
            --docker-cleanup)
                DOCKER_CLEANUP=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    print_status "Target namespace: $NAMESPACE"
    echo ""
    
    # Check if namespace exists
    check_namespace
    
    # Show current resources
    show_resources
    
    # Confirm deletion
    confirm_deletion
    
    # Delete resources
    delete_resources
    
    # Delete namespace (unless --keep-namespace is specified)
    if [ "$KEEP_NAMESPACE" != "true" ]; then
        delete_namespace
        verify_cleanup
    else
        print_status "Namespace '$NAMESPACE' preserved as requested"
    fi
    
    # Optional Docker cleanup
    if [ "$DOCKER_CLEANUP" = "true" ]; then
        cleanup_docker_images
    fi
    
    echo "=========================================="
    print_status "Destruction completed successfully!"
    echo "=========================================="
}

# Run main function
main "$@"