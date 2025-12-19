#!/bin/bash

# Quick Fix for Cursor API Connection Issue
# Creates DNS alias for api.cursor.sh pointing to api.cursor.com's IP

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "Cursor API Quick Fix"
echo "==================================${NC}"
echo ""

# Check if running as root or has sudo
if [ "$EUID" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}✗${NC} This script requires sudo access"
        echo "Please run: sudo $0"
        exit 1
    fi
fi

echo "Step 1: Resolving api.cursor.com..."
IP=$(nslookup api.cursor.com | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)

if [ -z "$IP" ]; then
    # Fallback method
    IP=$(nslookup api.cursor.com 2>/dev/null | grep "^Address:" | tail -1 | awk '{print $2}')
fi

if [ -z "$IP" ] || [ "$IP" = "1.1.1.1" ]; then
    echo -e "${RED}✗${NC} Could not resolve api.cursor.com"
    echo "Using known fallback IP..."
    IP="3.232.152.42"
fi

echo -e "${GREEN}✓${NC} Found IP: $IP"
echo ""

echo "Step 2: Checking /etc/hosts..."
if grep -q "api.cursor.sh" /etc/hosts; then
    echo -e "${YELLOW}⚠${NC} Entry already exists in /etc/hosts"
    echo "Current entry:"
    grep "api.cursor.sh" /etc/hosts
    echo ""
    read -p "Do you want to replace it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    # Remove old entry
    sudo sed -i.backup '/api.cursor.sh/d' /etc/hosts
    echo -e "${GREEN}✓${NC} Old entry removed (backup saved as /etc/hosts.backup)"
fi

echo "Step 3: Adding DNS alias..."
echo "$IP api.cursor.sh # Added by Cursor quick fix $(date)" | sudo tee -a /etc/hosts > /dev/null
echo -e "${GREEN}✓${NC} Entry added to /etc/hosts"
echo ""

echo "Step 4: Verifying fix..."
sleep 1

# Test DNS resolution
if nslookup api.cursor.sh > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} DNS resolution works"
else
    if getent hosts api.cursor.sh > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Host resolution works"
    else
        echo -e "${RED}✗${NC} Resolution still failing"
        exit 1
    fi
fi

# Test connectivity
echo "Testing HTTPS connectivity..."
if timeout 10 curl -s -I https://api.cursor.sh > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} HTTPS connection successful"
else
    echo -e "${YELLOW}⚠${NC} Connection test failed"
    echo "This might be due to SSL certificate mismatch"
    echo "(api.cursor.com certificate may not include api.cursor.sh)"
fi

echo ""
echo -e "${GREEN}=================================="
echo "Fix Applied Successfully!"
echo "==================================${NC}"
echo ""
echo "What was done:"
echo "  • Added '$IP api.cursor.sh' to /etc/hosts"
echo "  • This redirects api.cursor.sh to api.cursor.com's IP"
echo ""
echo "Next steps:"
echo "  1. Restart Cursor or reload the agent"
echo "  2. Test if bidirectional streaming works"
echo "  3. Report this issue to Cursor support"
echo ""
echo "Note: This is a WORKAROUND. Cursor should either:"
echo "  - Use api.cursor.com instead of api.cursor.sh, OR"
echo "  - Create DNS records for api.cursor.sh"
echo ""
echo "To undo this fix:"
echo "  sudo sed -i '/api.cursor.sh/d' /etc/hosts"
echo ""
