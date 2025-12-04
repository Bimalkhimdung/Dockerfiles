#!/bin/bash
# kubectl Installation Script for Ubuntu
# This script installs the latest stable version of kubectl

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
KUBE="☸️"
PACKAGE="📦"
KEY="🔑"
WRENCH="🔧"
ROCKET="🚀"
PARTY="🎉"
DOWNLOAD="⬇️"

# Print banner
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║       ${KUBE}  KUBECTL INSTALLER FOR UBUNTU  ${KUBE}              ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Print step header
print_step() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
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

# Main installation
main() {
    print_banner
    
    echo -e "${KUBE} ${WHITE}Starting kubectl installation...${NC}\n"
    sleep 1
    
    # Step 1: Update package index
    print_step "${PACKAGE} STEP 1: Updating Package Index"
    print_info "Updating apt package lists..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating package index"
    
    # Step 2: Install required dependencies
    print_step "${WRENCH} STEP 2: Installing Dependencies"
    print_info "Installing apt-transport-https and curl..."
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg > /dev/null 2>&1 &
    spinner $! "Installing dependencies"
    
    # Step 3: Create directory for Kubernetes GPG key
    print_step "${KEY} STEP 3: Preparing Kubernetes GPG Key Directory"
    print_info "Creating secure keyring directory..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    print_success "Directory ready: /etc/apt/keyrings"
    sleep 0.5
    
    # Step 4: Download and add Kubernetes GPG key
    print_step "${KEY} STEP 4: Installing Kubernetes GPG Key"
    print_info "Downloading Kubernetes official GPG key..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null &
    spinner $! "Installing GPG key"
    
    # Step 5: Add Kubernetes repository
    print_step "${PACKAGE} STEP 5: Adding Kubernetes Repository"
    print_info "Configuring Kubernetes APT repository..."
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    print_success "Kubernetes repository added"
    sleep 0.5
    
    # Step 6: Update package index with new repository
    print_step "${PACKAGE} STEP 6: Updating Package Index"
    print_info "Refreshing package lists with Kubernetes repository..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating package index"
    
    # Step 7: Install kubectl
    print_step "${KUBE} STEP 7: Installing kubectl"
    print_info "Installing kubectl binary..."
    sudo apt-get install -y kubectl > /dev/null 2>&1 &
    spinner $! "Installing kubectl"
    print_success "kubectl installed successfully"
    
    # Step 8: Enable kubectl autocompletion
    print_step "${WRENCH} STEP 8: Configuring kubectl Autocompletion"
    print_info "Setting up bash autocompletion..."
    
    # Add autocompletion to bashrc if not already present
    if ! grep -q "kubectl completion bash" ~/.bashrc 2>/dev/null; then
        echo 'source <(kubectl completion bash)' >> ~/.bashrc
        echo 'alias k=kubectl' >> ~/.bashrc
        echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
        print_success "Autocompletion configured in ~/.bashrc"
    else
        print_success "Autocompletion already configured"
    fi
    
    progress_bar 0.5
    
    # Step 9: Verify installation
    print_step "${ROCKET} STEP 9: Verifying Installation"
    sleep 1
    
    if command -v kubectl &> /dev/null; then
        local kubectl_version=$(kubectl version --client --short 2>&1 | grep -i "client version" || kubectl version --client 2>&1 | head -n1)
        
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                            ║${NC}"
        echo -e "${GREEN}║  ${PARTY}  kubectl Installation Successful! ${PARTY}                  ║${NC}"
        echo -e "${GREEN}║                                                            ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Installed Version:${NC}"
        echo -e "${CYAN}  ${KUBE} ${kubectl_version}${NC}"
        echo ""
        echo -e "${YELLOW}${ARROW} Next Steps:${NC}"
        echo -e "  1. Reload bash: ${CYAN}source ~/.bashrc${NC} (for autocompletion)"
        echo -e "  2. Configure cluster: ${CYAN}kubectl config view${NC}"
        echo -e "  3. Check cluster: ${CYAN}kubectl cluster-info${NC}"
        echo -e "  4. View nodes: ${CYAN}kubectl get nodes${NC}"
        echo -e "  5. Use alias: ${CYAN}k get pods${NC} (shortcut for kubectl)"
        echo ""
        echo -e "${PURPLE}${ARROW} Helpful Commands:${NC}"
        echo -e "  • Get all resources: ${CYAN}kubectl get all${NC}"
        echo -e "  • Describe resource: ${CYAN}kubectl describe <resource> <name>${NC}"
        echo -e "  • View logs: ${CYAN}kubectl logs <pod-name>${NC}"
        echo -e "  • Execute in pod: ${CYAN}kubectl exec -it <pod-name> -- /bin/bash${NC}"
        echo ""
        echo -e "${PURPLE}Documentation: ${CYAN}https://kubernetes.io/docs/reference/kubectl/${NC}"
        echo ""
        echo -e "${YELLOW}${ARROW} Note: Configure your kubeconfig to connect to a cluster${NC}"
        echo ""
    else
        print_error "Installation failed. kubectl command not found."
        exit 1
    fi
}

# Run main function
main
