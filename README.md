# VPNDemo

[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Network Extension](https://img.shields.io/badge/Network%20Extension-Packet%20Tunnel-purple.svg)](https://developer.apple.com/documentation/networkextension)

**中文** | [English](#english)

iOS VPN 客户端 Demo：基于 `Network Extension` / `NEPacketTunnelProvider` 的智能分流、扫码添加节点、多连接模式演示。

适合学习：**Packet Tunnel、CHNRoutes 式分流、NETunnelProviderManager、App Group 配置下发**。

> An iOS VPN client demo with Packet Tunnel, smart split tunneling, QR node import, and multi-mode connections. Ideal for learning Network Extension.

---

## ✨ 功能 Features

| 能力 Feature | 说明 Description |
|------|------|
| **Packet Tunnel** | 独立扩展，在系统层设置路由 / Dedicated extension that applies routes at system level |
| **智能分流 Smart Routing** | 国内 IP / 直连规则走本地，其余进隧道 / China IPs & direct rules stay local; others go through the tunnel |
| **连接模式 Modes** | 智能分流 · 全球出国 · 全球回国 / Smart · Global Outbound · Global Inbound |
| **扫码加节点 QR Import** | JSON 二维码导入节点并本地持久化 / Import nodes via JSON QR codes with local persistence |
| **规则中心 Rules** | 域名 / 后缀 / IP CIDR，支持开关与排序 / Domain, suffix, IP CIDR with toggle & reorder |
| **优雅降级 Fallback** | 扩展无法拉起时回落 App 演示模式 / Falls back to in-app demo mode if the extension fails |

---

## 🏗 架构 Architecture

```text
VPNDemo (App)
├── Home / Rules / Profile
├── VPNManager  ──► NETunnelProviderManager
├── RoutingPolicyManager（规则 + 国内 IP / rules + China IPs）
└── App Group ──► excluded_cidrs.txt / traffic stats
         │
         ▼
PacketTunnel.appex
├── PacketTunnelProvider
├── TunnelRouteBuilder（included / excluded routes）
└── UDP session placeholder（可替换为自有协议 / swap in your own protocol）
```

**Shared/** 供主 App 与扩展共用：App Group 常量、CIDR 工具、隧道设置构建。  
Shared by the app and the extension: App Group IDs, CIDR helpers, tunnel settings builder.

---

## 📦 环境要求 Requirements

- Xcode 15+（推荐最新 / latest recommended）
- iOS 15.0+
- CocoaPods
- Apple Developer 账号（真机需 **Network Extension**、**App Groups** / required for device builds）

---

## 🚀 快速开始 Getting Started

```bash
git clone https://github.com/476139183/VPNDemo.git
cd VPNDemo
pod install
open VPNDemo.xcworkspace
```

1. 选择 **VPNDemo** scheme（会自动嵌入 PacketTunnel）  
   Select the **VPNDemo** scheme (embeds PacketTunnel automatically)
2. Signing：主 App 与 `PacketTunnel` 使用同一 Team  
   Use the same signing Team for both targets
3. Capabilities：
   - **Network Extensions** → Packet Tunnel
   - **App Groups** → `group.com.languageclass.vpndemo`
4. 真机运行；模拟器可验证 UI，VPN 权限以真机为准  
   Run on a real device; Simulator is fine for UI only

### Bundle Identifiers

| Target | Bundle ID |
|--------|-----------|
| VPNDemo | `com.languageclass` |
| PacketTunnel | `com.languageclass.PacketTunnel` |
| App Group | `group.com.languageclass.vpndemo` |

---

## 📷 扫码节点格式 QR Node Format

扫码内容为 JSON（单个对象或数组） / JSON object or array:

```json
{
  "name": "香港自定义",
  "countryCode": "HK",
  "address": "hk.example.com",
  "port": 51820,
  "publicKey": "optional",
  "allowedIPs": "0.0.0.0/0",
  "serverType": "outbound"
}
```

- **必填 Required**：`address`
- `serverType`：`outbound`（出国 / outbound）或 `inbound`（回国 / inbound）
- 扫码节点可左滑删除 / Swipe left to delete scanned nodes

---

## 🔀 分流模式 Routing Modes

| 模式 Mode | 行为 Behavior |
|------|------|
| **智能分流 Smart** | 默认路由进隧道；国内 IP + 直连规则 → `excludedRoutes` / Default route into tunnel; China IPs & direct rules excluded |
| **全球出国 Global Outbound** | 全流量经海外节点 / All traffic via overseas node |
| **全球回国 Global Inbound** | 全流量经国内节点 / All traffic via mainland node |

> 演示节点（`*.example.com`）不会接管默认路由，避免无真实转发时断网。  
> Demo nodes (`*.example.com`) do not take over the default route, so the device stays online without a real forwarder.

---

## 📁 目录结构 Project Structure

```text
VPNDemo/
├── VPNDemo/           # 主 App / Main app (UI, VPNManager, rules, QR)
├── PacketTunnel/      # Network Extension
├── Shared/            # App ↔ Extension 共享 / Shared code
├── Podfile
└── README.md
```

---

## 🛣 路线图 Roadmap

- [x] Packet Tunnel 扩展骨架 / Extension skeleton
- [x] 智能分流路由落地 / Smart routing applied in-tunnel
- [x] 扫码导入节点 / QR node import
- [ ] 自有隧道加密协议 / Custom tunnel crypto protocol
- [ ] 更完整流量统计与 Widget / Richer stats & widget
- [ ] 节点延迟探测 / Latency probing

---

## 📚 学习说明 Learning Notes

本项目参考了经典开源 [ShadowVPN-iOS](https://github.com/clowwindy/ShadowVPN-iOS) 的扩展架构思路（`PacketTunnelProvider` + CHNRoutes），用现代 Swift / 工程结构重写，便于继续迭代。

Inspired by [ShadowVPN-iOS](https://github.com/clowwindy/ShadowVPN-iOS) (`PacketTunnelProvider` + CHNRoutes-style routing), rewritten with modern Swift project layout for easier iteration.

**Keywords / 关键词：** `iOS VPN` · `Network Extension` · `NEPacketTunnelProvider` · `NETunnelProviderManager` · `split tunneling` · `智能分流` · `CHNRoutes` · `扫码节点` · `Swift VPN Demo`

---

<a id="english"></a>

## English Summary

**VPNDemo** is a learning-oriented iOS VPN client that demonstrates:

1. **Packet Tunnel** via `NEPacketTunnelProvider`
2. **Smart split tunneling** (CHNRoutes-style `excludedRoutes`)
3. **QR-based node import** with local persistence
4. **Three connection modes**: Smart / Global Outbound / Global Inbound
5. **Graceful fallback** to in-app demo mode when the extension cannot start

Clone, `pod install`, open the workspace, enable Network Extension + App Groups, and run on a real device. See sections above for QR JSON schema and bundle IDs.

---

## ⚠️ 免责声明 Disclaimer

本仓库仅为 **学习与演示** 用途，不提供任何翻墙服务，也不附带可用的商业 VPN 服务器。请遵守当地法律法规与 Apple 开发者协议。

This repository is for **learning and demonstration only**. It does not provide VPN services or production servers. Comply with local laws and Apple’s developer agreements.

---

## 📄 License

MIT — free for learning and derivative works. See [LICENSE](LICENSE).

---

<p align="center">
  <sub>Made for learning iOS Network Extension · <a href="https://github.com/476139183/VPNDemo">476139183/VPNDemo</a></sub>
</p>
