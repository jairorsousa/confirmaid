#!/bin/bash
# Safe commands to create deploy user and structure
# Run as root on the VPS

echo "=== Creating 'deploy' user ==="
if id "deploy" &>/dev/null; then
    echo "User 'deploy' already exists"
else
    adduser --gecos "" --disabled-password deploy
    echo "User 'deploy' created"
fi

echo ""
echo "=== Adding deploy to groups ==="
usermod -aG sudo deploy
usermod -aG docker deploy
echo "Added to sudo and docker groups"

echo ""
echo "=== Creating ConfirmaID directory structure ==="
mkdir -p /home/deploy/confirmaid/{storage/private,backups,scripts,app}
chown -R deploy:deploy /home/deploy/confirmaid
chmod 700 /home/deploy/confirmaid/storage/private

echo ""
echo "=== Current structure ==="
ls -la /home/deploy/confirmaid/
echo ""
echo "storage/private permissions:"
ls -ld /home/deploy/confirmaid/storage/private

echo ""
echo "=== Done ==="
echo "Next: Set a password for deploy (optional but useful): passwd deploy"
echo "Then set up SSH key auth for deploy user."
