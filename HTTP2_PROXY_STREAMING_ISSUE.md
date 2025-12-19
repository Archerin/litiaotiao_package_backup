# HTTP/2 Proxy Bidirectional Streaming Issue

## Problem Description

Bidirectional streaming is not supported by the HTTP/2 proxy in the current network environment. This affects Cursor's AI agent communication which relies on bidirectional streaming for real-time interactions.

## Technical Background

- **Bidirectional Streaming**: A communication pattern where both client and server can send messages independently and simultaneously over a single connection
- **HTTP/2**: Modern protocol that supports multiplexing and streaming, but some corporate proxies may not fully support all HTTP/2 features
- **Impact**: This limitation can cause:
  - Connection timeouts
  - Incomplete AI responses
  - Agent communication failures
  - Degraded IDE experience

## Potential Causes

1. **Corporate Proxy Restrictions**: Many enterprise HTTP/2 proxies only support unidirectional streaming
2. **Network Middleware**: Deep packet inspection (DPI) systems may interfere with streaming
3. **Firewall Rules**: Strict firewall configurations blocking streaming protocols
4. **Proxy Configuration**: Misconfigured proxy settings that don't properly handle HTTP/2 streams

## Suggested Solutions

### 1. Network Configuration Changes

If you have network admin access:

- **Allow HTTP/2 Bidirectional Streaming**: Configure proxy to support full HTTP/2 specification
- **Whitelist Cursor Domains**: Add Cursor's API endpoints to proxy whitelist
- **Update Proxy Software**: Ensure proxy software supports modern HTTP/2 features

### 2. Connection Workarounds

#### Option A: Direct Connection
```bash
# Bypass proxy for Cursor connections
export NO_PROXY="*.cursor.sh,cursor.sh,api.cursor.sh"
export no_proxy="*.cursor.sh,cursor.sh,api.cursor.sh"
```

#### Option B: Use HTTP/1.1 Fallback
```bash
# Force HTTP/1.1 (if supported by Cursor)
export FORCE_HTTP1=1
```

#### Option C: Alternative DNS
```bash
# Use alternative DNS that might route differently
export DNS_SERVER="8.8.8.8"
```

### 3. VPN/Tunnel Solutions

- Use a VPN that bypasses the problematic proxy
- Set up a tunnel (SSH/SOCKS) to route Cursor traffic
- Use a personal hotspot/mobile data temporarily

### 4. Cursor Settings

Check Cursor settings for:
- Proxy configuration options
- Connection protocol preferences
- Fallback mode settings
- Network timeout adjustments

### 5. System Proxy Settings

#### Linux
```bash
# Unset system proxy temporarily
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
```

#### Check current proxy settings
```bash
env | grep -i proxy
```

## Diagnostic Steps

1. **Test Connection**:
```bash
curl -v https://api.cursor.sh
```

2. **Check HTTP Version**:
```bash
curl --http2 -v https://api.cursor.sh
curl --http1.1 -v https://api.cursor.sh
```

3. **Proxy Detection**:
```bash
echo $http_proxy $https_proxy
```

4. **Network Trace**:
```bash
traceroute api.cursor.sh
```

## Temporary Workarounds

While resolving the issue:
- Use Cursor in offline mode (if available)
- Use a different network connection (home/mobile)
- Contact network administrator for proxy exemption
- Use Cursor from a non-proxied environment

## Reporting the Issue

If you need to escalate:
1. Document your network configuration
2. Capture connection logs/errors
3. Note your proxy software/version
4. Contact Cursor support with details
5. Request HTTP/1.1 fallback feature

## Additional Resources

- [HTTP/2 Specification](https://httpwg.org/specs/rfc7540.html)
- [Proxy Configuration Best Practices](https://www.rfc-editor.org/rfc/rfc7230)
- Cursor Documentation (check for proxy settings)

---

**Date**: December 19, 2025  
**Status**: Active Issue  
**Environment**: Linux 6.1.147, Corporate/Restricted Network
