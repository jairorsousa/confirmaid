#!/bin/bash
# =============================================
# ConfirmaID - Secret Generator (run locally)
# =============================================
# Usage: bash scripts/generate-secrets.sh
#
# This script generates the critical secrets for ConfirmaID.
# Run it on your LOCAL machine (Mac), then copy the values safely
# to your password manager and later to the VPS .env file.

echo "=== ConfirmaID Secret Generator ==="
echo ""
echo "STORAGE_ENCRYPTION_KEY (for AES-256-GCM - 32 bytes hex):"
openssl rand -hex 32
echo ""

echo "NEXTAUTH_SECRET (for Auth.js sessions):"
openssl rand -base64 32
echo ""

echo "Strong Postgres password example (copy and customize):"
openssl rand -base64 24 | tr -d '\n' | head -c 24; echo ""
echo ""

echo "=== IMPORTANT ==="
echo "1. Store these values in a password manager (Bitwarden, 1Password, etc.)"
echo "2. NEVER commit real secrets to git"
echo "3. Use different values for development vs production"
echo "4. The STORAGE_ENCRYPTION_KEY is especially critical - if lost, all encrypted files become unreadable"
echo ""