#!/bin/bash
# Docker Installation Script for Ubuntu
# This script installs Docker CE, CLI, and related tools on Ubuntu systems

# Update package index
sudo apt-get update

# Create directory for Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings

# Download and add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set appropriate permissions on the key
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository to apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with new repository
sudo apt-get update

# Install Docker CE, CLI, containerd, and plugins
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (requires logout/login to take effect)
sudo usermod -aG docker $USER

# Set permissions on Docker socket for group access
sudo chmod 666 /var/run/docker.sock
