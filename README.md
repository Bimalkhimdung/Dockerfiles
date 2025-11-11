# 🚀 DevOps Files Collection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/Bimalkhimdung/devops-files?style=social)](https://github.com/Bimalkhimdung/devops-files)
[![GitHub issues](https://img.shields.io/github/issues/Bimalkhimdung/devops-files)](https://github.com/Bimalkhimdung/devops-files/issues)

A comprehensive collection of reusable DevOps configurations, Dockerfiles, and GitHub Actions workflows to streamline your CI/CD pipelines and containerization efforts.

## 📁 Repository Structure

```
devops-files/
├── docker/
│   ├── Dockerfile.typescript       # Multi-stage Node.js/TypeScript Dockerfile
│   ├── Dockerfile.golang22-alpine  # Golang 2.2 Alpine Dockerfile
│   ├── Dockerfile.java11-alpine    # Java 11 Alpine Dockerfile
│   └── docker-install.sh           # Docker installation script for Ubuntu
├── github-action/
│   ├── github-action-build-and-push-to-ecr.yml     # Build & push to AWS ECR
│   ├── github-action-auto-deploy-with-self-hosted.yaml  # Deploy to dev env
│   ├── github-action-auto-realase-package-to-exec.yml   # Auto release executable
│   ├── node-auto-upload-package.yaml                   # Publish Node.js packages
│   └── update-github-package.yml                       # Update GitHub packages
├── LICENSE
└── README.md
```

## 🐳 Docker Configurations

### Multi-Stage Dockerfiles

This repository provides optimized, production-ready Dockerfiles for popular programming languages:

#### 📦 TypeScript/Node.js Dockerfile
- **File**: `docker/Dockerfile.typescript`
- **Features**:
  - Multi-stage build for optimal image size
  - Based on Node.js 20 Alpine
  - Optimized for Next.js applications
  - Includes standalone build support
  - Production-ready configuration

#### 🐹 Golang Dockerfile
- **File**: `docker/Dockerfile.golang22-alpine`
- **Features**:
  - Golang 2.2 on Alpine Linux
  - Minimal base image
  - Perfect for Go microservices

#### ☕ Java Dockerfile
- **File**: `docker/Dockerfile.java11-alpine`
- **Features**:
  - OpenJDK 11 on Alpine Linux
  - Lightweight Java runtime
  - Suitable for Spring Boot applications

### Docker Installation Script

- **File**: `docker/docker-install.sh`
- **Purpose**: Automated Docker installation on Ubuntu systems
- **Features**:
  - Installs Docker CE, CLI, and Compose
  - Configures user permissions
  - Sets up Docker Buildx

## ⚡ GitHub Actions Workflows

### CI/CD Pipelines

#### 🔄 Build and Push to AWS ECR
- **File**: `github-action/github-action-build-and-push-to-ecr.yml`
- **Triggers**: Push to main branch
- **Features**:
  - Automatic semantic versioning
  - Build and push Docker images to AWS ECR
  - Deploy to production via SSH
  - Integrated release tagging

#### 🚀 Auto Deploy with Self-Hosted Runners
- **File**: `github-action/github-action-auto-deploy-with-self-hosted.yaml`
- **Triggers**: Workflow completion
- **Features**:
  - Deploys to development environment
  - Uses self-hosted runners
  - Kubernetes deployment support
  - SSH-based deployment

#### 📦 Node.js Package Publishing
- **File**: `github-action/node-auto-upload-package.yaml`
- **Triggers**: Release published
- **Features**:
  - Builds Node.js packages with pnpm
  - Creates release bundles
  - Uploads assets to GitHub releases
  - Supports Node.js 24

#### 🔧 Additional Workflows
- **Auto Release Package to Executable**: `github-action/github-action-auto-realase-package-to-exec.yml`
- **Update GitHub Package**: `github-action/update-github-package.yml`

## 🚀 Quick Start

### Using Dockerfiles

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Bimalkhimdung/devops-files.git
   cd devops-files
   ```

2. **Copy the appropriate Dockerfile** to your project:
   ```bash
   cp docker/Dockerfile.typescript /path/to/your/project/Dockerfile
   ```

3. **Build your image**:
   ```bash
   docker build -t my-app .
   ```

### Using GitHub Actions

1. **Copy workflow files** to your `.github/workflows/` directory
2. **Configure secrets** in your repository settings:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `ECR_ACCOUNT_ID`
   - `SSH_HOST`, `SSH_USERNAME`, `SSH_KEY`
3. **Customize** the workflows for your specific needs

### Installing Docker

Run the installation script on Ubuntu:
```bash
chmod +x docker/docker-install.sh
sudo ./docker/docker-install.sh
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by various DevOps best practices
- Built with ❤️ for the developer community

---

⭐ **Star this repo** if you find it useful!

📧 **Contact**: For questions or suggestions, please open an issue.
