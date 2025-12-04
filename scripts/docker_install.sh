#!/bin/bash
# Docker Installation Script for Ubuntu
# This script installs Docker CE, CLI, and related tools on Ubuntu systems

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
DOCKER="🐳"
PACKAGE="📦"
KEY="🔑"
WRENCH="🔧"
ROCKET="🚀"
PARTY="🎉"

# Print banner
print_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        ${DOCKER}  DOCKER CE INSTALLER FOR UBUNTU  ${DOCKER}           ║"
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
    
    echo -e "${DOCKER} ${WHITE}Starting Docker installation...${NC}\n"
    sleep 1
    
    # Step 1: Update package index
    print_step "${PACKAGE} STEP 1: Updating Package Index"
    print_info "Updating apt package lists..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating package index"
    
    # Step 2: Create directory for Docker GPG key
    print_step "${KEY} STEP 2: Preparing Docker GPG Key Directory"
    print_info "Creating secure keyring directory..."
    sudo install -m 0755 -d /etc/apt/keyrings
    print_success "Directory created: /etc/apt/keyrings"
    sleep 0.5
    
    # Step 3: Download and add Docker's official GPG key
    print_step "${KEY} STEP 3: Installing Docker GPG Key"
    print_info "Downloading Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null &
    spinner $! "Installing GPG key"
    
    # Step 4: Set appropriate permissions on the key
    print_step "${WRENCH} STEP 4: Setting GPG Key Permissions"
    print_info "Configuring key permissions..."
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    progress_bar 0.5
    print_success "Permissions configured"
    
    # Step 5: Add Docker repository to apt sources
    print_step "${PACKAGE} STEP 5: Adding Docker Repository"
    print_info "Configuring Docker APT repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    print_success "Docker repository added"
    sleep 0.5
    
    # Step 6: Update package index with new repository
    print_step "${PACKAGE} STEP 6: Updating Package Index"
    print_info "Refreshing package lists with Docker repository..."
    sudo apt-get update > /dev/null 2>&1 &
    spinner $! "Updating package index"
    
    # Step 7: Install Docker CE, CLI, containerd, and plugins
    print_step "${DOCKER} STEP 7: Installing Docker Components"
    print_info "Installing Docker CE, CLI, containerd, and plugins..."
    echo -e "${CYAN}This may take a few minutes...${NC}\n"
    
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1 &
    spinner $! "Installing Docker packages"
    
    print_success "Docker CE installed"
    print_success "Docker CLI installed"
    print_success "containerd.io installed"
    print_success "Docker Buildx plugin installed"
    print_success "Docker Compose plugin installed"
    
    # Step 8: Add current user to docker group
    print_step "${WRENCH} STEP 8: Configuring User Permissions"
    print_info "Adding user '${USER}' to docker group..."
    sudo usermod -aG docker $USER
    progress_bar 0.5
    print_success "User added to docker group"
    
    # Step 9: Set permissions on Docker socket
    print_step "${WRENCH} STEP 9: Configuring Docker Socket"
    print_info "Setting Docker socket permissions..."
    sudo chmod 666 /var/run/docker.sock
    progress_bar 0.5
    print_success "Docker socket configured"
    
    # Step 10: Verify installation
    print_step "${ROCKET} STEP 10: Verifying Installation"
    sleep 1
    
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>&1)
        local compose_version=$(docker compose version 2>&1)
        
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                            ║${NC}"
        echo -e "${GREEN}║  ${PARTY}  Docker Installation Successful! ${PARTY}                   ║${NC}"
        echo -e "${GREEN}║                                                            ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}Installed Versions:${NC}"
        echo -e "${CYAN}  ${DOCKER} ${docker_version}${NC}"
        echo -e "${CYAN}  📦 ${compose_version}${NC}"
        echo ""
        echo -e "${YELLOW}${ARROW} Important Next Steps:${NC}"
        echo -e "  ${RED}1. Log out and log back in${NC} for docker group changes to take effect"
        echo -e "     ${CYAN}(or run: newgrp docker)${NC}"
        echo -e "  2. Test Docker: ${CYAN}docker run hello-world${NC}"
        echo -e "  3. Check status: ${CYAN}docker ps${NC}"
        echo -e "  4. View info: ${CYAN}docker info${NC}"
        echo ""
        echo -e "${PURPLE}Documentation: ${CYAN}https://docs.docker.com${NC}"
        echo ""
    else
        print_error "Installation failed. Docker command not found."
        exit 1
    fi
}

# Run main function
main
