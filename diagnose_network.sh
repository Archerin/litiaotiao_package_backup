#!/bin/bash

echo "=================================="
echo "Cursor HTTP/2 Network Diagnostics"
echo "=================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check proxy settings
echo "1. Checking Proxy Settings..."
echo "----------------------------"
if [ -z "$http_proxy" ] && [ -z "$https_proxy" ] && [ -z "$HTTP_PROXY" ] && [ -z "$HTTPS_PROXY" ]; then
    echo -e "${GREEN}✓${NC} No proxy environment variables set"
else
    echo -e "${YELLOW}⚠${NC} Proxy variables detected:"
    env | grep -i proxy
fi
echo ""

# Check HTTP/2 support
echo "2. Checking HTTP/2 Support..."
echo "----------------------------"
if curl --version | grep -q "HTTP2"; then
    echo -e "${GREEN}✓${NC} curl supports HTTP/2"
else
    echo -e "${RED}✗${NC} curl does NOT support HTTP/2"
fi
echo ""

# Test common API endpoints
echo "3. Testing Cursor API Endpoints..."
echo "-----------------------------------"
endpoints=(
    "https://api.cursor.sh"
    "https://www.cursor.sh"
    "https://cursor.sh"
)

for endpoint in "${endpoints[@]}"; do
    echo "Testing: $endpoint"
    
    # Test HTTP/2
    if timeout 5 curl -s --http2 -I "$endpoint" > /dev/null 2>&1; then
        echo -e "  HTTP/2: ${GREEN}✓ Reachable${NC}"
    else
        echo -e "  HTTP/2: ${RED}✗ Failed${NC}"
    fi
    
    # Test HTTP/1.1
    if timeout 5 curl -s --http1.1 -I "$endpoint" > /dev/null 2>&1; then
        echo -e "  HTTP/1.1: ${GREEN}✓ Reachable${NC}"
    else
        echo -e "  HTTP/1.1: ${RED}✗ Failed${NC}"
    fi
    echo ""
done

# Check DNS resolution
echo "4. Checking DNS Resolution..."
echo "----------------------------"
if command -v nslookup > /dev/null 2>&1; then
    nslookup api.cursor.sh | grep -A2 "Name:" || echo "Could not resolve api.cursor.sh"
elif command -v dig > /dev/null 2>&1; then
    dig api.cursor.sh +short
else
    echo -e "${YELLOW}⚠${NC} No DNS tools available (nslookup/dig)"
fi
echo ""

# Check network route
echo "5. Checking Network Route..."
echo "----------------------------"
if command -v traceroute > /dev/null 2>&1; then
    echo "Traceroute to api.cursor.sh (first 5 hops):"
    timeout 10 traceroute -m 5 api.cursor.sh 2>/dev/null || echo "Traceroute not available or failed"
else
    echo -e "${YELLOW}⚠${NC} traceroute not available"
fi
echo ""

# Check firewall/iptables
echo "6. Checking Firewall Rules..."
echo "----------------------------"
if command -v iptables > /dev/null 2>&1; then
    if sudo -n iptables -L > /dev/null 2>&1; then
        echo "Checking for blocking rules..."
        sudo iptables -L | grep -i drop | head -5 || echo "No obvious DROP rules found"
    else
        echo -e "${YELLOW}⚠${NC} Cannot check iptables (need sudo)"
    fi
else
    echo -e "${YELLOW}⚠${NC} iptables not available"
fi
echo ""

# Network interface info
echo "7. Network Interface Info..."
echo "----------------------------"
if command -v ip > /dev/null 2>&1; then
    ip addr show | grep -E "^[0-9]|inet " | head -10
else
    ifconfig | grep -E "^[a-z]|inet " | head -10
fi
echo ""

# Check for corporate proxies
echo "8. Checking for Corporate Proxy Indicators..."
echo "-------------------------------------------"
common_proxy_ports=(3128 8080 8888 8443 3129 8081)
for port in "${common_proxy_ports[@]}"; do
    if netstat -tln 2>/dev/null | grep -q ":$port "; then
        echo -e "${YELLOW}⚠${NC} Port $port is listening (common proxy port)"
    fi
done
echo ""

# System info
echo "9. System Information..."
echo "-----------------------"
echo "OS: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "Hostname: $(hostname)"
echo ""

# Recommendations
echo "=================================="
echo "Recommendations"
echo "=================================="
echo ""
echo "If you see HTTP/2 failures but HTTP/1.1 succeeds:"
echo "  → The proxy/firewall is blocking HTTP/2 bidirectional streaming"
echo ""
echo "If both HTTP/2 and HTTP/1.1 fail:"
echo "  → Network connectivity issue or firewall blocking Cursor domains"
echo ""
echo "Potential solutions:"
echo "  1. Contact network admin to whitelist *.cursor.sh domains"
echo "  2. Use a VPN or different network connection"
echo "  3. Request HTTP/2 bidirectional streaming support on proxy"
echo "  4. Use mobile hotspot as temporary workaround"
echo ""
echo "See HTTP2_PROXY_STREAMING_ISSUE.md for detailed solutions"
echo "=================================="
