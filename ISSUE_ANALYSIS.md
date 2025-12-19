# HTTP/2 Proxy Streaming Issue - Analysis and Resolution

## Date: December 19, 2025

## Issue Summary

The reported "bidirectional streaming is not supported by the http2 proxy" issue has been diagnosed. The root cause appears to be **DNS resolution failure** for `api.cursor.sh` rather than HTTP/2 protocol limitations.

## Diagnostic Results

### ✅ Working Components
- ✓ No proxy environment variables interfering
- ✓ curl supports HTTP/2 (nghttp2/1.59.0)
- ✓ `cursor.sh` is reachable (HTTP/2 and HTTP/1.1)
- ✓ `www.cursor.sh` is reachable (HTTP/2 and HTTP/1.1)
- ✓ Network interfaces operational

### ❌ Failing Components
- ✗ `api.cursor.sh` - DNS resolution failed
- ✗ Cannot connect to API endpoint (both HTTP/2 and HTTP/1.1)

## Root Cause

**DNS Resolution Failure**: The `api.cursor.sh` domain cannot be resolved in this network environment.

This is NOT a HTTP/2 bidirectional streaming limitation, but rather:
1. DNS server not configured properly
2. Corporate DNS filtering `api.cursor.sh`
3. Network isolation preventing external DNS queries
4. Cursor cloud agent environment DNS configuration issue

## Environment Details

- **OS**: Linux 6.1.147
- **Environment**: Docker container (cursor hostname)
- **Network**: 172.30.0.2/24 (likely containerized environment)
- **Context**: Cursor Cloud Agent remote workspace

## Solutions

### Solution 1: Add DNS Entry (Immediate Fix)

If you know the IP address of `api.cursor.sh`, add to `/etc/hosts`:

```bash
# Find the IP (from a working environment)
nslookup api.cursor.sh

# Add to /etc/hosts (requires sudo)
echo "X.X.X.X api.cursor.sh" | sudo tee -a /etc/hosts
```

### Solution 2: Use Alternative DNS Server

```bash
# Configure custom DNS (requires sudo)
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf

# Test resolution
nslookup api.cursor.sh
```

### Solution 3: Configure systemd-resolved (if available)

```bash
# Check if systemd-resolved is running
systemctl status systemd-resolved

# Configure DNS
sudo systemctl edit systemd-resolved
# Add:
# [Resolve]
# DNS=8.8.8.8 1.1.1.1
# FallbackDNS=8.8.4.4

sudo systemctl restart systemd-resolved
```

### Solution 4: Network Policy Fix (For Cursor Team)

This appears to be a Cursor cloud agent environment issue where:
- The container network may not have proper DNS configuration
- Network policies may be blocking DNS queries
- The remote workspace needs proper DNS resolver setup

**Action Required**: Cursor infrastructure team should:
1. Ensure DNS resolvers are properly configured in cloud agent containers
2. Whitelist `*.cursor.sh` domains in network policies
3. Provide fallback DNS servers (8.8.8.8, 1.1.1.1, etc.)

### Solution 5: Workaround - Use Different Connection Method

If this is a Cursor cloud agent issue:
1. Try using local mode instead of cloud agent
2. Check Cursor settings for connection method preferences
3. Report the issue to Cursor support with these diagnostics

## Testing the Fix

After applying any solution, test with:

```bash
# Test DNS resolution
nslookup api.cursor.sh

# Test connectivity
curl -v https://api.cursor.sh

# Test HTTP/2
curl --http2 -v https://api.cursor.sh

# Run full diagnostics again
./diagnose_network.sh
```

## Prevention

For Cursor Cloud Agent environments:
1. Pre-configure DNS resolvers in container images
2. Include fallback DNS servers in network configuration
3. Add health checks for critical domains before agent activation
4. Provide clear error messages when DNS fails

## Next Steps

1. **Immediate**: Try Solution 1 or 2 to fix DNS resolution
2. **Short-term**: Report this to Cursor support with diagnostic output
3. **Long-term**: Cursor should fix DNS configuration in cloud agent environments

## Related Files

- `HTTP2_PROXY_STREAMING_ISSUE.md` - Detailed explanation of HTTP/2 streaming issues
- `diagnose_network.sh` - Network diagnostic script
- `ISSUE_ANALYSIS.md` - This file

## Conclusion

The "bidirectional streaming not supported" error message is misleading. The actual issue is **DNS resolution failure** for Cursor's API endpoint in this containerized cloud agent environment. This requires either:

1. Manual DNS configuration (short-term fix)
2. Cursor infrastructure update (proper long-term fix)

---

**Status**: Diagnosed - DNS Resolution Issue  
**Severity**: High - Blocks Cursor AI functionality  
**Owner**: Cursor Infrastructure Team  
**Workaround Available**: Yes (manual DNS configuration)
