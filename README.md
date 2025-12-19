# LiTiaotiao APK Package Backup Repo

[https://mp.weixin.qq.com/s/ha6hHr40umlj-ExHdGFXXw](https://mp.weixin.qq.com/s/ha6hHr40umlj-ExHdGFXXw)

[https://mp.weixin.qq.com/s/gsC9STZlGrPNNEKUV4btkA](https://mp.weixin.qq.com/s/gsC9STZlGrPNNEKUV4btkA)

All files were downloaded from [https://pan.baidu.com/s/1IHPQp1Rgn9K67N-v4ZcNxw?pwd=1233](https://pan.baidu.com/s/1IHPQp1Rgn9K67N-v4ZcNxw?pwd=1233) on August 24, 2023

所有文件均于 2023 年 8 月 24 日从 [https://pan.baidu.com/s/1IHPQp1Rgn9K67N-v4ZcNxw?pwd=1233](https://pan.baidu.com/s/1IHPQp1Rgn9K67N-v4ZcNxw?pwd=1233) 上下载

| File \| 文件                                                                                                                                              | Author Upload Time \| 作者上传时间 | Feature \| 功能                                                             |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------- |
| [李跳跳2.2正式版.apk](https://github.com/eddlez/litiaotiao_package_backup/raw/main/%E6%9D%8E%E8%B7%B3%E8%B7%B32.2%E6%AD%A3%E5%BC%8F%E7%89%88.apk)             | 2023-05-17 16:20:42          | 李跳跳                                                                       |
| [李跳跳_派大星2.01.apk](https://github.com/eddlez/litiaotiao_package_backup/raw/main/%E6%9D%8E%E8%B7%B3%E8%B7%B3_%E6%B4%BE%E5%A4%A7%E6%98%9F2.01.apk)         | 2023-04-09 19:20:06          | 似乎是李跳跳的一个旧版                                                               |
| [李跳跳_真实好友4.0.apk](https://github.com/eddlez/litiaotiao_package_backup/raw/main/%E6%9D%8E%E8%B7%B3%E8%B7%B3_%E7%9C%9F%E5%AE%9E%E5%A5%BD%E5%8F%8B4.0.apk) | 2023-04-09 19:21:26          | 检测微信好友是否把我们删除了，[详见此链接](https://mp.weixin.qq.com/s/v5ejXKQbDTI6cbmSSYMyaw) |

---

## ⚠️ Cursor HTTP/2 Streaming Issue (December 2025)

This branch contains diagnostic tools and solutions for the "bidirectional streaming is not supported by the http2 proxy" error.

### 🎯 Quick Fix

If you're experiencing Cursor connection issues:

```bash
# Run the quick fix (requires sudo)
sudo ./quick_fix.sh
```

### 📋 What's the Issue?

**TL;DR**: Cursor is trying to connect to `api.cursor.sh` which doesn't exist. The correct domain is `api.cursor.com`.

**Error Reported**: "Bidirectional streaming is not supported by the http2 proxy in your network environment"

**Actual Problem**: DNS resolution failure for non-existent domain `api.cursor.sh`

### 📁 Diagnostic & Solution Files

| File | Purpose |
|------|---------|
| `SOLUTION.md` | ✅ **START HERE** - Complete analysis and solution |
| `quick_fix.sh` | 🔧 One-command fix (adds DNS alias) |
| `diagnose_network.sh` | 🔍 Network diagnostics tool |
| `fix_dns_issue.sh` | 🤖 Automated fix attempts |
| `ISSUE_ANALYSIS.md` | 📊 Detailed diagnostic findings |
| `HTTP2_PROXY_STREAMING_ISSUE.md` | 📖 General HTTP/2 proxy information |

### 🚀 Usage

#### Option 1: Quick Fix (Recommended)

```bash
# Make script executable
chmod +x quick_fix.sh

# Run with sudo
sudo ./quick_fix.sh

# Restart Cursor agent
```

#### Option 2: Diagnose First

```bash
# Run diagnostics
./diagnose_network.sh

# Review findings
cat SOLUTION.md

# Apply fix if needed
sudo ./quick_fix.sh
```

#### Option 3: Manual Fix

```bash
# Get IP of api.cursor.com
nslookup api.cursor.com

# Add to /etc/hosts (replace X.X.X.X with actual IP)
echo "X.X.X.X api.cursor.sh" | sudo tee -a /etc/hosts
```

### 🔍 Verification

```bash
# Check DNS resolution
nslookup api.cursor.sh

# Test connectivity
curl -I https://api.cursor.sh

# Verify HTTP/2 support
curl --http2 -v https://api.cursor.com
```

### 📝 What Was Fixed?

1. **Identified**: `api.cursor.sh` has no DNS record (doesn't exist)
2. **Found**: `api.cursor.com` is the working endpoint
3. **Created**: DNS alias workaround in `/etc/hosts`
4. **Documented**: Complete analysis for Cursor team

### 🐛 Report to Cursor

This appears to be a configuration issue in Cursor. Please report:
- Cursor is using wrong domain (`api.cursor.sh` vs `api.cursor.com`)
- Error message is misleading (reports proxy issue, not DNS issue)
- Include diagnostic output from `diagnose_network.sh`

### 📚 More Information

See `SOLUTION.md` for:
- Complete root cause analysis
- Technical details
- Alternative solutions
- Recommendations for Cursor team

---

**Issue Status**: ✅ Identified and Workaround Available  
**Date**: December 19, 2025  
**Branch**: `cursor/http2-proxy-streaming-issue-059e`
