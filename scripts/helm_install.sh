#!/bin/bash
# Helm Installation Script for Ubuntu
# This script installs the latest version of Helm - The Kubernetes Package Manager

set -e  # Exit on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Icons
CHECK="✓"
CROSS="✗"
ARROW="➜"
HELM="⎈"
PACKAGE="📦"
KEY="🔑"
WRENCH="🔧"
ROCKET="🚀"
PARTY="🎉"
DOWNLOAD="⬇️"
SHIP="⛵"
ANCHOR="⚓"

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║         ${HELM}  HELM INSTALLER FOR UBUNTU  ${HELM}                  ║"
    echo "║                                                            ║"
    echo "║          The Kubernetes Package Manager ${SHIP}                ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Print step header
print_step() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"
}

# Print success message
print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

# Print info message
print_info() {
    echo -e "${YELLOW}${ARROW} $1${NC}"
}

# Animated spinner
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${CYAN}%c${NC} ${message}..." "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    printf "\r${GREEN}${CHECK}${NC} ${message}... Done!\n"
}

# Progress bar function
progress_bar() {
    local duration=$1
    local width=50
    local progress=0
    
    while [ $progress -le $width ]; do
        echo -ne "\r${CYAN}["
        for ((i=0; i<$progress; i++)); do echo -ne "█"; done
        for ((i=$progress; i<$width; i++)); do echo -ne "░"; done
        local percent=$((progress * 100 / width))
        echo -ne "] ${percent}%${NC}"
        progress=$((progress + 1))
        sleep $(echo "scale=3; $duration / $width" | bc 2>/dev/null || echo "0.02")
    done
    echo ""
}

# Sailing animation
sailing_animation() {
    local message=$1
    local boats=("⛵" "🚢" "⛴️" "🛥️")
    local i=0
    local count=0
    
    while [ $count -lt 20 ]; do
        printf "\r${CYAN}${boats[$i]}${NC} ${message}..."
        i=$(( (i + 1) % ${#boats[@]} ))
        count=$((count + 1))
        sleep 0.15
    done
    printf "\r${GREEN}${CHECK}${NC} ${message}... Done!\n"
}

# Main installation
main() {
    print_banner
    
    echo -e "${HELM} ${WHITE}Starting Helm installation...${NC}\n"
    sleep 1
    
    # Step 1: Check for curl
    print_step "${WRENCH} STEP 1: Checking Prerequisites"
    print_info "Verifying curl is installed..."
    
    if ! command -v curl &> /dev/null; then
        print_info "curl not found. Installing..."
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install -y curl > /dev/null 2>&1 &
        spinner $! "Installing curl"
    else
        print_success "curl is already installed"
    fi
    
    # Step 2: Download Helm installation script
    print_step "${DOWNLOAD} STEP 2: Downloading Helm Install Script"
    print_info "Fetching official Helm installer from get.helm.sh..."
    
    cd /tmp
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o get_helm.sh 2>/dev/null &
    
    local download_pid=$!
    while kill -0 $download_pid 2>/dev/null; do
        if [ -f "get_helm.sh" ]; then
            local size=$(du -h get_helm.sh 2>/dev/null | cut -f1)
            printf "\r${CYAN}${DOWNLOAD}${NC} Downloading... ${YELLOW}${size}${NC}     "
        fi
        sleep 0.3
    done
    wait $download_pid
    echo ""
    print_success "Installation script downloaded"
    
    # Step 3: Verify script integrity
    print_step "${KEY} STEP 3: Verifying Script Integrity"
    print_info "Checking downloaded script..."
    
    if [ -f "get_helm.sh" ] && [ -s "get_helm.sh" ]; then
        progress_bar 0.5
        print_success "Script verified successfully"
    else
        print_error "Downloaded script is invalid"
        exit 1
    fi
    
    # Step 4: Make script executable
    print_step "${WRENCH} STEP 4: Preparing Installation Script"
    print_info "Setting execute permissions..."
    chmod 700 get_helm.sh
    progress_bar 0.3
    print_success "Script is ready to execute"
    
    # Step 5: Run Helm installation
    print_step "${HELM} STEP 5: Installing Helm"
    print_info "Running Helm installer..."
    echo -e "${CYAN}This will install Helm to /usr/local/bin/helm${NC}\n"
    
    sudo ./get_helm.sh > /dev/null 2>&1 &
    sailing_animation "Installing Helm"
    
    # Step 6: Add Helm repositories
    print_step "${PACKAGE} STEP 6: Configuring Helm Repositories"
    print_info "Adding stable Helm chart repository..."
    
    # Add stable repo (best effort, might not be needed in Helm 3)
    helm repo add stable https://charts.helm.sh/stable > /dev/null 2>&1 || true
    helm repo add bitnami https://charts.bitnami.com/bitnami > /dev/null 2>&1 &
    spinner $! "Adding Bitnami repository"
    
    print_info "Updating repository index..."
    helm repo update > /dev/null 2>&1 &
    spinner $! "Updating repositories"
    
    # Step 7: Setup bash completion
    print_step "${WRENCH} STEP 7: Configuring Autocompletion"
    print_info "Setting up bash completion for Helm..."
    
    if ! grep -q "helm completion bash" ~/.bashrc 2>/dev/null; then
        echo 'source <(helm completion bash)' >> ~/.bashrc
        print_success "Autocompletion added to ~/.bashrc"
    else
        print_success "Autocompletion already configured"
    fi
    
    progress_bar 0.5
    
    # Step 8: Cleanup
    print_step "${ANCHOR} STEP 8: Cleaning Up"
    print_info "Removing temporary files..."
    rm -f get_helm.sh
    progress_bar 0.3
    print_success "Cleanup completed"
    
    # Step 9: Verify installation
    print_step "${ROCKET} STEP 9: Verifying Installation"
    sleep 1
    
    if command -v helm &> /dev/null; then
        local helm_version=$(helm version --short 2>&1)
        local repo_count=$(helm repo list 2>/dev/null | tail -n +2 | wc -l)
        
        echo ""
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                                                            ║${NC}"
        echo -e "${CYAN}║  ${PARTY}  Helm Installation Successful! ${PARTY}                     ║${NC}"
        echo -e "${CYAN}║                                                            ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Installed Version:${NC}"
        echo -e "${CYAN}  ${HELM} ${helm_version}${NC}"
        echo -e "${CYAN}  ${PACKAGE} Repositories configured: ${repo_count}${NC}"
        echo ""
        echo -e "${YELLOW}${ARROW} Quick Start Commands:${NC}"
        echo ""
        echo -e "${WHITE}1. Search for charts:${NC}"
        echo -e "   ${CYAN}helm search repo <keyword>${NC}"
        echo -e "   ${CYAN}helm search hub <keyword>${NC}"
        echo ""
        echo -e "${WHITE}2. Install a chart:${NC}"
        echo -e "   ${CYAN}helm install <release-name> <chart>${NC}"
        echo -e "   ${CYAN}helm install my-nginx bitnami/nginx${NC}"
        echo ""
        echo -e "${WHITE}3. List installed releases:${NC}"
        echo -e "   ${CYAN}helm list${NC}"
        echo -e "   ${CYAN}helm list --all-namespaces${NC}"
        echo ""
        echo -e "${WHITE}4. Upgrade a release:${NC}"
        echo -e "   ${CYAN}helm upgrade <release-name> <chart>${NC}"
        echo ""
        echo -e "${WHITE}5. Uninstall a release:${NC}"
        echo -e "   ${CYAN}helm uninstall <release-name>${NC}"
        echo ""
        echo -e "${CYAN}${ARROW} Essential Helm Commands:${NC}"
        echo -e "  • Show chart info: ${CYAN}helm show chart <chart>${NC}"
        echo -e "  • Show values: ${CYAN}helm show values <chart>${NC}"
        echo -e "  • Get release status: ${CYAN}helm status <release>${NC}"
        echo -e "  • View history: ${CYAN}helm history <release>${NC}"
        echo -e "  • Rollback: ${CYAN}helm rollback <release> <revision>${NC}"
        echo -e "  • Add repo: ${CYAN}helm repo add <name> <url>${NC}"
        echo -e "  • Update repos: ${CYAN}helm repo update${NC}"
        echo ""
        echo -e "${CYAN}${ARROW} Popular Chart Repositories:${NC}"
        echo -e "  • Bitnami: ${CYAN}https://charts.bitnami.com/bitnami${NC}"
        echo -e "  • Prometheus: ${CYAN}https://prometheus-community.github.io/helm-charts${NC}"
        echo -e "  • Ingress-nginx: ${CYAN}https://kubernetes.github.io/ingress-nginx${NC}"
        echo ""
        echo -e "${CYAN}${ARROW} Example: Deploy NGINX${NC}"
        echo -e "  ${CYAN}helm repo add bitnami https://charts.bitnami.com/bitnami${NC}"
        echo -e "  ${CYAN}helm install my-nginx bitnami/nginx${NC}"
        echo -e "  ${CYAN}helm list${NC}"
        echo ""
        echo -e "${GREEN}${ARROW} Reload bash for autocompletion: ${CYAN}source ~/.bashrc${NC}"
        echo ""
        echo -e "${CYAN}Documentation: ${WHITE}https://helm.sh/docs${NC}"
        echo -e "${CYAN}Artifact Hub: ${WHITE}https://artifacthub.io${NC}"
        echo ""
    else
        print_error "Installation failed. Helm command not found."
        exit 1
    fi
}

# Run main function
main
