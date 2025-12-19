#!/bin/bash

# Automated DNS Fix Script for Cursor API Connectivity
# Attempts multiple strategies to resolve api.cursor.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================="
echo "Cursor API DNS Fix Script"
echo "==================================${NC}"
echo ""

# Function to test DNS resolution
test_dns() {
    if nslookup api.cursor.sh > /dev/null 2>&1; then
        return 0
    elif host api.cursor.sh > /dev/null 2>&1; then
        return 0
    elif getent hosts api.cursor.sh > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to test connectivity
test_connectivity() {
    if timeout 5 curl -s -I https://api.cursor.sh > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Initial test
echo "Step 1: Testing current DNS resolution..."
if test_dns; then
    echo -e "${GREEN}✓${NC} DNS resolution working"
    if test_connectivity; then
        echo -e "${GREEN}✓${NC} Connectivity working"
        echo ""
        echo -e "${GREEN}Success!${NC} No issues detected. api.cursor.sh is accessible."
        exit 0
    else
        echo -e "${YELLOW}⚠${NC} DNS works but connectivity fails (firewall issue?)"
    fi
else
    echo -e "${RED}✗${NC} DNS resolution failing"
fi
echo ""

# Check if we have necessary permissions
HAS_SUDO=false
if sudo -n true 2>/dev/null; then
    HAS_SUDO=true
    echo -e "${GREEN}✓${NC} Sudo access available"
else
    echo -e "${YELLOW}⚠${NC} No sudo access (some fixes may not work)"
fi
echo ""

# Strategy 1: Try alternative DNS servers in /etc/resolv.conf
echo "Step 2: Attempting to configure DNS servers..."
if [ "$HAS_SUDO" = true ]; then
    echo "Backing up current /etc/resolv.conf..."
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    echo "Adding Google and Cloudflare DNS servers..."
    {
        echo "# Added by Cursor DNS fix script"
        echo "nameserver 8.8.8.8"
        echo "nameserver 8.8.4.4"
        echo "nameserver 1.1.1.1"
        echo "nameserver 1.0.0.1"
    } | sudo tee /etc/resolv.conf.new > /dev/null
    
    # Keep existing nameservers if any
    if [ -f /etc/resolv.conf ]; then
        grep "^nameserver" /etc/resolv.conf | sudo tee -a /etc/resolv.conf.new > /dev/null || true
    fi
    
    sudo mv /etc/resolv.conf.new /etc/resolv.conf
    echo -e "${GREEN}✓${NC} DNS servers configured"
    
    # Test again
    sleep 2
    echo "Testing DNS resolution..."
    if test_dns; then
        echo -e "${GREEN}✓${NC} DNS resolution now working!"
        if test_connectivity; then
            echo -e "${GREEN}✓${NC} Connectivity restored!"
            echo ""
            echo -e "${GREEN}Success!${NC} Issue fixed via DNS configuration."
            exit 0
        fi
    else
        echo -e "${YELLOW}⚠${NC} Still failing, trying next strategy..."
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping (requires sudo)"
fi
echo ""

# Strategy 2: Try to find and add IP to /etc/hosts
echo "Step 3: Attempting to add static host entry..."
if [ "$HAS_SUDO" = true ]; then
    # Try to resolve from common DNS servers
    IP=""
    for dns in 8.8.8.8 1.1.1.1 208.67.222.222; do
        echo "Querying DNS server $dns..."
        IP=$(nslookup api.cursor.sh $dns 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
        if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
            echo -e "${GREEN}✓${NC} Found IP: $IP"
            break
        fi
    done
    
    if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
        echo "Adding $IP api.cursor.sh to /etc/hosts..."
        if ! grep -q "api.cursor.sh" /etc/hosts; then
            echo "$IP api.cursor.sh # Added by Cursor DNS fix script" | sudo tee -a /etc/hosts > /dev/null
            echo -e "${GREEN}✓${NC} Host entry added"
            
            sleep 1
            echo "Testing connectivity..."
            if test_connectivity; then
                echo -e "${GREEN}✓${NC} Connectivity restored!"
                echo ""
                echo -e "${GREEN}Success!${NC} Issue fixed via /etc/hosts entry."
                exit 0
            fi
        else
            echo -e "${YELLOW}⚠${NC} Entry already exists in /etc/hosts"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Could not resolve IP from external DNS servers"
    fi
else
    echo -e "${YELLOW}⚠${NC} Skipping (requires sudo)"
fi
echo ""

# Strategy 3: Check for systemd-resolved
echo "Step 4: Checking systemd-resolved configuration..."
if command -v systemctl > /dev/null 2>&1; then
    if systemctl is-active systemd-resolved > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} systemd-resolved is running"
        
        if [ "$HAS_SUDO" = true ]; then
            echo "Configuring systemd-resolved..."
            sudo mkdir -p /etc/systemd/resolved.conf.d/
            cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/cursor-dns.conf > /dev/null
[Resolve]
DNS=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1
FallbackDNS=208.67.222.222 208.67.220.220
DNSSEC=no
DNSOverTLS=no
EOF
            echo -e "${GREEN}✓${NC} Configuration written"
            
            echo "Restarting systemd-resolved..."
            sudo systemctl restart systemd-resolved
            sleep 2
            
            echo "Testing DNS resolution..."
            if test_dns; then
                echo -e "${GREEN}✓${NC} DNS resolution now working!"
                if test_connectivity; then
                    echo -e "${GREEN}✓${NC} Connectivity restored!"
                    echo ""
                    echo -e "${GREEN}Success!${NC} Issue fixed via systemd-resolved."
                    exit 0
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} Skipping configuration (requires sudo)"
        fi
    else
        echo -e "${YELLOW}⚠${NC} systemd-resolved is not running"
    fi
else
    echo -e "${YELLOW}⚠${NC} systemctl not available"
fi
echo ""

# Strategy 4: Environment-specific fixes
echo "Step 5: Checking for environment-specific issues..."

# Check if we're in a container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Running in Docker container"
    echo "Container DNS configuration may be controlled by Docker daemon"
    echo "You may need to:"
    echo "  1. Restart the container with --dns flags"
    echo "  2. Configure /etc/docker/daemon.json on the host"
    echo "  3. Use docker-compose DNS settings"
fi

# Check network configuration
if [ -f /etc/netplan/*.yaml ] 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Netplan configuration detected"
    echo "You may need to configure DNS via netplan YAML files"
fi
echo ""

# Final status
echo "=================================="
echo "Final Status"
echo "=================================="
echo ""

if test_dns; then
    echo -e "${GREEN}✓${NC} DNS Resolution: WORKING"
else
    echo -e "${RED}✗${NC} DNS Resolution: FAILING"
fi

if test_connectivity; then
    echo -e "${GREEN}✓${NC} API Connectivity: WORKING"
else
    echo -e "${RED}✗${NC} API Connectivity: FAILING"
fi

echo ""
echo "=================================="
echo "Manual Steps (if automated fix failed)"
echo "=================================="
echo ""
echo "1. Check with your network administrator about DNS access"
echo "2. Verify firewall rules allow HTTPS to *.cursor.sh"
echo "3. Try using a VPN or different network"
echo "4. Contact Cursor support with diagnostics from diagnose_network.sh"
echo ""
echo "For more information, see:"
echo "  - ISSUE_ANALYSIS.md"
echo "  - HTTP2_PROXY_STREAMING_ISSUE.md"
echo ""

if ! test_dns || ! test_connectivity; then
    exit 1
else
    exit 0
fi
