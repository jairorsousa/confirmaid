#!/bin/bash
# ============================================================
# ConfirmaID - Fase 0: SAFE & NON-DESTRUCTIVE SETUP
# ============================================================
# This is a **safe** version meant for a VPS that already runs other services.
#
# It does the following with lots of checks:
# - Installs Docker ONLY if not present
# - Installs cloudflared ONLY if not present
# - Creates 'deploy' user if it doesn't exist
# - Creates the required directory structure with safe permissions
# - Does NOT touch UFW / firewall rules
# - Does NOT change SSH configuration
# - Does NOT enable any services that might conflict
#
# Run this ONLY after you have reviewed the INSPECTION REPORT
# and we have decided together what is safe.
# ============================================================

set -e

echo "=============================================="
echo "  ConfirmaID - SAFE Phase 0 Setup (Non-destructive)"
echo "=============================================="
echo ""
echo "This script will ONLY:"
echo "  • Install Docker (if missing)"
echo "  • Install cloudflared (if missing)"
echo "  • Create 'deploy' user (if missing)"
echo "  • Create /home/deploy/confirmaid/{storage/private,backups}"
echo "  • Set safe permissions on storage/private"
echo ""
echo "It will NOT:"
echo "  • Modify firewall (UFW/iptables)"
echo "  • Change SSH settings"
echo "  • Restart or stop existing services"
echo "  • Enable UFW"
echo ""

read -p "Are you sure you want to continue? (yes/no) " answer
if [ "$answer" != "yes" ]; then
    echo "Aborted by user."
    exit 0
fi

echo ""
echo ">>> [1/6] Checking current user..."
if [ "$(whoami)" != "root" ]; then
    echo "ERROR: You must run this script as root."
    exit 1
fi

echo ""
echo ">>> [2/6] Checking/Installing Docker..."
if command -v docker &> /dev/null; then
    echo "✓ Docker is already installed: $(docker --version)"
else
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    echo "✓ Docker installed"
fi

echo ""
echo ">>> [3/6] Checking/Installing Docker Compose plugin..."
if docker compose version &> /dev/null; then
    echo "✓ Docker Compose plugin already available"
else
    echo "Installing docker-compose-plugin..."
    apt update
    apt install -y docker-compose-plugin
    echo "✓ Docker Compose plugin installed"
fi

echo ""
echo ">>> [4/6] Checking/Installing cloudflared..."
if command -v cloudflared &> /dev/null; then
    echo "✓ cloudflared is already installed: $(cloudflared --version)"
else
    echo "Installing cloudflared..."
    ARCH=$(dpkg --print-architecture)
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" -o /tmp/cloudflared.deb
    dpkg -i /tmp/cloudflared.deb || apt install -f -y
    rm -f /tmp/cloudflared.deb
    echo "✓ cloudflared installed"
fi

echo ""
echo ">>> [5/6] Creating 'deploy' user (if it doesn't exist)..."
if id "deploy" &>/dev/null; then
    echo "✓ User 'deploy' already exists"
else
    echo "Creating user 'deploy'..."
    adduser --gecos "" --disabled-password deploy
    usermod -aG sudo deploy
    usermod -aG docker deploy
    echo "✓ User 'deploy' created and added to sudo + docker groups"
    echo ""
    echo "IMPORTANT: Set a password for deploy user (you can do this later with 'passwd deploy')"
fi

echo ""
echo ">>> [6/6] Creating ConfirmaID directory structure with safe permissions..."
mkdir -p /home/deploy/confirmaid/{storage/private,backups,scripts}
chown -R deploy:deploy /home/deploy/confirmaid
chmod 700 /home/deploy/confirmaid/storage/private

echo ""
echo "=============================================="
echo "  SAFE Phase 0 Setup FINISHED"
echo "=============================================="
echo ""
echo "Next manual steps:"
echo "1. Set up SSH key auth for the 'deploy' user (highly recommended)"
echo "2. Configure Cloudflare Tunnel (create systemd service pointing to the tunnel token)"
echo "3. As the 'deploy' user, clone the repository into /home/deploy/confirmaid/app"
echo "4. Create .env file with your real secrets"
echo ""
echo "Directory created at: /home/deploy/confirmaid"
echo "Private storage:      /home/deploy/confirmaid/storage/private (700 permissions)"
echo ""
echo "Please run the inspection script again after these changes and share the new report."
echo "=============================================="