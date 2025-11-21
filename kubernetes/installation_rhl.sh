#!/bin/bash
# =============================================================================
# Self-managed Kubernetes (kubeadm) installer for RHEL 9
# Skips all firewall commands
# Supports: containerd + Calico + Kubernetes v1.31 (latest stable Nov 2025)
# Run this script as root on every node (master first, then workers)
# =============================================================================

set -euo pipefail

# -------------------------- Configuration ------------------------------------
K8S_VERSION="1.31"                    # Change only if you need another version
POD_NETWORK_CIDR="192.168.0.0/16"     # Calico default – change only if needed
MASTER_IP=""                          # Will be auto-detected on master node
# ----------------------------------------------------------------------------

echo "=== Starting Kubernetes installation on RHEL 9 (firewall rules skipped)"

# 1. System update & basic tools
dnf update -y
dnf install -y conntrack-tools iproute-tc wget vim tar

# 2. Disable SWAP (mandatory)
swapoff -a
sed -i '/[[:space:]]swap[[:space:]]/ s/^\(.*\)$/#\1/g' /etc/fstab

# 3. Load kernel modules & sysctl settings
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system >/dev/null

modprobe overlay
modprobe br_netfilter

# 4. Install and configure containerd
dnf install -y containerd

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null

# Use systemd cgroup driver (required by Kubernetes)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

# 5. Add Kubernetes repo (official pkgs.k8s.io)
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# 6. Install kubeadm, kubelet, kubectl
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# 7. Detect if this is the first node (master)
if [[ -z "$MASTER_IP" ]]; then
    MASTER_IP=$(hostname -I | awk '{print $1}')
    echo "Detected IP $MASTER_IP – assuming this is the master node"
    
    echo " Initializing control plane..."
    kubeadm init \
        --pod-network-cidr=$POD_NETWORK_CIDR \
        --cri-socket unix:///run/containerd/containerd.sock \
        --control-plane-endpoint="$MASTER_IP" \
        --upload-certs | tee /root/kubeadm-init.log

    echo " Setting up kubeconfig for root user..."
    mkdir -p /root/.kube
    cp -i /etc/kubernetes/admin.conf /root/.kube/config
    chown root:root /root/.kube/config

    echo " Installing Calico CNI..."
    kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f \
        https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

    echo ""
    echo "============================================================"
    echo "Cluster ready!"
    echo "To add worker nodes, run the following command on each worker:"
    echo ""
    kubeadm token create --print-join-command --cri-socket unix:///run/containerd/containerd.sock
    echo ""
    echo "Or copy the exact join command from /root/kubeadm-init.log"
    echo "============================================================"

else
    echo "This is a worker node. Waiting for join command..."
    echo "Run the following command (copy from master):"
    echo ""
    echo "   kubeadm join $MASTER_IP:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --cri-socket unix:///run/containerd/containerd.sock"
    echo ""
    echo "You can generate a fresh command on master with:"
    echo "   kubeadm token create --print-join-command --cri-socket unix:///run/containerd/containerd.sock"
fi

echo "Installation script finished!"
