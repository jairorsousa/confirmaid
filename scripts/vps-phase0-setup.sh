#!/bin/bash
# ============================================================
# ConfirmaID - Phase 0 VPS Setup Script (Ubuntu)
# ============================================================
# This script prepares a fresh Hostinger VPS for ConfirmaID.
#
# HOW TO USE:
# 1. On your LOCAL machine, make the script executable:
#    chmod +x scripts/vps-phase0-setup.sh
#
# 2. Copy it to your VPS (replace with your VPS IP and user):
#    scp scripts/vps-phase0-setup.sh root@YOUR_VPS_IP:/root/
#
# 3. SSH into the VPS:
#    ssh root@YOUR_VPS_IP
#
# 4. Run it (as root initially):
#    bash /root/vps-phase0-setup.sh
#
# 5. After it finishes, follow the on-screen instructions
#    to create the 'deploy' user, configure Cloudflare Tunnel, etc.
#
# WARNING: This script makes significant changes to the system.
# Review it before running. It is designed for a fresh Ubuntu 22.04/24.04 LTS.
# ============================================================

set -e

echo "=============================================="
echo "  ConfirmaID Phase 0 - VPS Initial Setup"
echo "=============================================="
echo ""

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected OS: $PRETTY_NAME"
fi

echo ""
read -p "This will update the system, install Docker, UFW, Fail2Ban, etc. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo ">>> [1/8] Updating system packages..."
apt update && apt upgrade -y

echo ""
echo ">>> [2/8] Installing essential packages..."
apt install -y \
    curl \
    git \
    htop \
    ufw \
    fail2ban \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    wget \
    vim

echo ""
echo ">>> [3/8] Configuring UFW Firewall (only allow SSH for now)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable
ufw status

echo ""
echo ">>> [4/8] Installing Docker (official script)..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

echo ""
echo ">>> [5/8] Installing Docker Compose plugin..."
apt install -y docker-compose-plugin

echo ""
echo ">>> [6/8] Installing cloudflared (Cloudflare Tunnel)..."
# Download latest cloudflared
ARCH=$(dpkg --print-architecture)
curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" -o /tmp/cloudflared.deb
dpkg -i /tmp/cloudflared.deb || apt install -f -y
rm /tmp/cloudflared.deb
cloudflared --version

echo ""
echo ">>> [7/8] Enabling and starting Fail2Ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo ""
echo ">>> [8/8] Creating basic directory structure for ConfirmaID..."
mkdir -p /home/deploy/confirmaid/{storage/private,backups,scripts}
chown -R 1000:1000 /home/deploy/confirmaid || true   # will be adjusted after deploy user is created

echo ""
echo "=============================================="
echo "  Phase 0 Base Setup COMPLETE"
echo "=============================================="
echo ""
echo "NEXT STEPS YOU MUST DO MANUALLY:"
echo ""
echo "1. Create a non-root user (recommended 'deploy'):"
echo "   adduser deploy"
echo "   usermod -aG sudo deploy"
echo "   usermod -aG docker deploy"
echo ""
echo "2. Set up SSH key access for the 'deploy' user (highly recommended):"
echo "   - Copy your public key to /home/deploy/.ssh/authorized_keys"
echo ""
echo "3. (Optional but recommended) Disable root password login:"
echo "   Edit /etc/ssh/sshd_config:"
echo "     PermitRootLogin no"
echo "     PasswordAuthentication no"
echo "   Then: systemctl restart ssh"
echo ""
echo "4. Configure Cloudflare Tunnel (very important):"
echo "   - Go to Cloudflare Zero Trust > Tunnels"
echo "   - Create tunnel or use existing one"
echo "   - Run the token command provided by Cloudflare, or set it up as a service"
echo ""
echo "5. Switch to the deploy user and continue:"
echo "   su - deploy"
echo "   cd /home/deploy/confirmaid"
echo ""
echo "6. Copy your project files (via git clone or scp from your local machine)"
echo ""
echo "7. Create the .env file from .env.example and fill the secrets"
echo ""
echo "After these steps, you can proceed with Fase 1 (Next.js project)."
echo ""
echo "Script finished. Review the output above for any errors."
echo "=============================================="