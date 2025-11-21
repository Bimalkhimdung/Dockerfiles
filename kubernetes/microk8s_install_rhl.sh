#!/bin/bash
# =============================================================================
# One-click MicroK8s installer for RHEL 9 (and RHEL 8)
# Single command → production-ready Kubernetes cluster in < 3 minutes
# Run as root or with sudo

# =============================================================================
# =============================================================================
# Run command  externally
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Bimalkhimdung/devops-files/blob/main/kubernetes/microk8s_install_rhl.sh)"
# =============================================================================

set -euo pipefail

echo "============================================================="
echo "   MicroK8s Automatic Installer for RHEL 9"
echo "   Kubernetes in < 3 minutes – no kubeadm hassle"
echo "============================================================= ================================="

# 1. Install EPEL + snapd
dnf install -y epel-release
dnf install -y snapd

# 2. Enable and start snapd (including socket for auto-start)
systemctl enable --now snapd.socket
systemctl enable --now snapd.service

# 3. Create /snap → /var/lib/snapd/snap symlink (required on RHEL)
[[ -d /snap ]] || ln -s /var/lib/snapd/snap /snap

# 4. Wait until snapd is fully seeded (important!)
echo "Waiting for snapd seeding..."
until snap wait system seed.loaded 2>/dev/null; do
    sleep 5
done

# 5. Install MicroK8s (latest stable 1.31 series as of Nov 2025)
echo "Installing MicroK8s (this can take 1–2 minutes)..."
snap install microk8s --classic --channel=1.31/stable

# 6. Add user to microk8s group (so you can run without sudo)
usermod -a -G snap_microk8s $SUDO_USER 2>/dev/null || usermod -a -G snap_microk8s $(whoami)

# 7. Create convenient kubectl alias for the current user
KUBECTL_ALIAS="alias kubectl='microk8s kubectl'"
if ! grep -q "$KUBECTL_ALIAS" /root/.bashrc; then
    echo "$KUBECTL_ALIAS >> /root/.bashrc
fi

# For non-root user (if running with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    HOME_USER=$(getent passwd $SUDO_USER | cut -d: -f6)
    if ! sudo -u $SUDO_USER grep -q "$KUBECTL_ALIAS" "$HOME_USER/.bashrc" 2>/dev/null; then
        echo "$KUBECTL_ALIAS" | tee -a "$HOME_USER/.bashrc" >/dev/null
    fi
fi

# 8. Wait until MicroK8s is ready
echo "Waiting for MicroK8s to be ready..."
microk8s status --wait-ready

# 9. Enable the most useful add-ons automatically
echo "Enabling common add-ons (dns, dashboard, ingress, helm3, storage, metallb)..."
microk8s enable dns
microk8s enable dashboard
microk8s enable ingress
microk8s enable helm3
microk8s enable storage
microk8s enable metallb:10.0.0.100-10.0.0.200   # Change this range to match your network!

# 10. Final status & instructions
clear
echo "============================================================"
echo "  MICROK8S IS SUCCESSFULLY INSTALLED AND READY!"
echo "============================================================"
echo ""
echo "Useful commands:"
echo "   kubectl get all --all-namespaces"
echo "   microk8s status"
echo "   microk8s dashboard-proxy   ← opens Kubernetes Dashboard in browser"
echo ""
echo "To add more nodes (high-availability cluster):"
echo "   On this master run:  microk8s add-node"
echo "   On worker nodes run the printed 'microk8s join ...' command"
echo ""
echo "Test deployment:"
echo "   kubectl create deployment nginx --image=nginx"
echo "   kubectl expose deployment nginx --port=80 --type=LoadBalancer"
echo "   kubectl get svc"
echo ""
echo "Enjoy your super-simple Kubernetes cluster on RHEL!"
echo "============================================================"

exit 0
