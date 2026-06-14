#!/bin/bash
# ============================================================
# ConfirmaID - Fase 0: SAFE INSPECTION SCRIPT
# ============================================================
# Run this FIRST on the VPS as root.
# This script is READ-ONLY. It only gathers information.
# It will NOT install anything or change any configuration.
#
# Usage on VPS:
#   scp scripts/vps-phase0-inspect.sh root@72.60.0.47:/root/
#   ssh root@72.60.0.47
#   bash /root/vps-phase0-inspect.sh
#
# Then copy the entire output and paste it back to Grok.
# ============================================================

echo "=============================================="
echo "  ConfirmaID Fase 0 - VPS INSPECTION REPORT"
echo "  Date: $(date)"
echo "=============================================="
echo ""

echo ">>> 1. SYSTEM INFORMATION"
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Current user: $(whoami)"
echo ""

echo ">>> 2. EXISTING USERS (non-system)"
getent passwd | awk -F: '$3 >= 1000 && $3 != 65534 {print $1, $3, $6}'
echo ""

echo ">>> 3. DOCKER STATUS"
if command -v docker &> /dev/null; then
    echo "Docker is INSTALLED"
    docker --version
    echo ""
    echo "--- Running Containers ---"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "--- All Containers (including stopped) ---"
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo ""
    echo "--- Docker Networks ---"
    docker network ls
    echo ""
    echo "--- Docker Volumes ---"
    docker volume ls
else
    echo "Docker is NOT installed"
fi
echo ""

echo ">>> 4. DOCKER COMPOSE"
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo "Docker Compose available"
    docker compose version 2>/dev/null || docker-compose --version
else
    echo "Docker Compose NOT found"
fi
echo ""

echo ">>> 5. FIREWALL STATUS"
echo "--- UFW ---"
ufw status verbose 2>/dev/null || echo "UFW not installed or not active"
echo ""
echo "--- iptables (basic) ---"
iptables -L -n | head -30
echo ""

echo ">>> 6. LISTENING PORTS (what services are exposed)"
echo "ss -tuln (TCP/UDP listening):"
ss -tuln
echo ""
echo "netstat -tuln (if available):"
netstat -tuln 2>/dev/null | head -20 || echo "netstat not available"
echo ""

echo ">>> 7. CLOUDFLARE TUNNEL STATUS"
if command -v cloudflared &> /dev/null; then
    echo "cloudflared is installed: $(cloudflared --version)"
    echo ""
    echo "--- cloudflared services ---"
    systemctl status cloudflared --no-pager 2>/dev/null || echo "No systemd service for cloudflared"
    echo ""
    echo "--- Any running cloudflared processes ---"
    ps aux | grep -i cloudflared | grep -v grep
else
    echo "cloudflared is NOT installed"
fi
echo ""

echo ">>> 8. EXISTING SERVICES (systemd)"
echo "Active services (top 30):"
systemctl list-units --type=service --state=running | head -35
echo ""

echo ">>> 9. DISK USAGE"
df -h
echo ""

echo ">>> 10. MEMORY"
free -h
echo ""

echo ">>> 11. EXISTING /home/deploy or similar project dirs"
ls -la /home/ 2>/dev/null || echo "No /home subdirs visible"
ls -la /root/ 2>/dev/null | head -10
echo ""

echo ">>> 12. SSH CONFIG (important - do not break existing access)"
echo "SSH Port:"
grep -E "^Port |^PermitRootLogin |^PasswordAuthentication " /etc/ssh/sshd_config 2>/dev/null || echo "Default config or file not readable"
echo ""

echo "=============================================="
echo "END OF INSPECTION REPORT"
echo "Please copy ALL the output above and send it back."
echo "=============================================="