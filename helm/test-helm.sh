#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_error() {
    echo -e "${RED}$1${NC}"
}

# Function to check if helm is installed
check_helm() {
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    log_success "✓ Helm is installed"
}

# Function to validate chart
validate_chart() {
    local chart_path=$1
    local chart_name=$(basename "$chart_path")
    
    echo "Validating chart: $chart_name"
    
    # Lint the chart
    echo "Linting $chart_name..."
    if helm lint "$chart_path"; then
        log_success "✓ $chart_name lint passed"
    else
        log_error "✗ $chart_name lint failed"
        return 1
    fi
    
    # Template the chart and save output
    echo "Generating templates for $chart_name..."
    if helm template "test-release" "$chart_path" > "test-output-$chart_name.yaml" 2>/dev/null; then
        log_success "✓ $chart_name template generation passed"
        echo "Generated templates:"
        cat "test-output-$chart_name.yaml"
        rm "test-output-$chart_name.yaml"
        return 0
    else
        log_error "✗ $chart_name template generation failed"
        return 1
    fi
}

# Main execution
echo "Starting Helm charts validation..."

# Check prerequisites
check_helm

# Get script directory for relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Add bitnami repo for MongoDB dependency
echo "Adding Bitnami repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Test application chart
if validate_chart "$SCRIPT_DIR/url-shortener"; then
    log_success "✓ Application chart validation successful"
else
    log_error "✗ Application chart validation failed"
    exit 1
fi

# Test umbrella chart
if validate_chart "$SCRIPT_DIR/url-shortener-umbrella"; then
    log_success "✓ Umbrella chart validation successful"
else
    log_error "✗ Umbrella chart validation failed"
    exit 1
fi

log_success "All chart validations completed successfully!"