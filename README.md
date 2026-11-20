# VPNDemo

[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Network Extension](https://img.shields.io/badge/Network%20Extension-Packet%20Tunnel-purple.svg)](https://developer.apple.com/documentation/networkextension)

**iOS VPN 客户端 Demo**：基于 `Network Extension` / `NEPacketTunnelProvider` 的智能分流、扫码添加节点、多连接模式演示。

适合学习：**Packet Tunnel、CHNRoutes 式分流、NETunnelProviderManager、App Group 配置下发**。

---

## ✨ Features

| 能力 | 说明 |
|------|------|
| **Packet Tunnel** | 独立 `PacketTunnel` 扩展，真正在系统层设置路由 |
| **智能分流** | 国内 IP / 直连规则走本地，其余进隧道（excludedRoutes） |
| **连接模式** | 智能分流 · 全球出国 · 全球回国 |
| **扫码加节点** | 扫描 JSON 二维码导入自定义节点并本地持久化 |
| **规则中心** | 域名 / 后缀 / IP CIDR 规则，支持开关与拖拽排序 |
| **优雅降级** | 扩展无法拉起时自动回落 App 内演示模式 |

---

## 🏗 Architecture

```text
VPNDemo (App)
├── Home / Rules / Profile
├── VPNManager  ──► NETunnelProviderManager
├── RoutingPolicyManager（规则 + 国内 IP）
└── App Group ──► excluded_cidrs.txt / 流量统计
         │
         ▼
PacketTunnel.appex
├── PacketTunnelProvider
├── TunnelRouteBuilder（included / excluded routes）
└── UDP session 占位（可替换为自有协议）
```

**Shared/** 供主 App 与扩展共用：App Group 常量、CIDR 路由工具、隧道设置构建。

---

## 📦 Requirements

- Xcode 15+（推荐最新）
- iOS 15.0+
- CocoaPods
- Apple Developer 账号（真机需开启 **Network Extension**、**App Groups**）

---

## 🚀 Getting Started

```bash
git clone https://github.com/476139183/VPNDemo.git
cd VPNDemo
pod install
open VPNDemo.xcworkspace
```

1. 选择 **VPNDemo** scheme（会自动嵌入 PacketTunnel）
2. Signing：主 App 与 `PacketTunnel` 使用同一 Team
3. Capabilities 确认：
   - **Network Extensions** → Packet Tunnel
   - **App Groups** → `group.com.languageclass.vpndemo`
4. 真机运行；模拟器可验证 UI，VPN 权限以真机为准

### Bundle Identifiers

| Target | Bundle ID |
|--------|-----------|
| VPNDemo | `com.languageclass` |
| PacketTunnel | `com.languageclass.PacketTunnel` |
| App Group | `group.com.languageclass.vpndemo` |

---

## 📷 QR Node Format

扫码内容为 JSON（单个对象或数组）：

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

- **必填**：`address`
- `serverType`：`outbound`（出国）或 `inbound`（回国）
- 扫码节点可左滑删除

---

## 🔀 Routing Modes

| 模式 | 行为 |
|------|------|
| **智能分流** | 默认路由进隧道；国内 IP 段 + 直连规则写入 `excludedRoutes` |
| **全球出国** | 全流量经海外节点 |
| **全球回国** | 全流量经国内节点 |

> 演示节点（`*.example.com`）不会接管默认路由，避免无真实转发时断网。

---

## 📁 Project Structure

```text
VPNDemo/
├── VPNDemo/           # 主 App（UI / VPNManager / 规则 / 扫码）
├── PacketTunnel/      # Network Extension
├── Shared/            # App ↔ Extension 共享代码
├── Podfile
└── README.md
```

---

## 🛣 Roadmap

- [x] Packet Tunnel 扩展骨架
- [x] 智能分流路由落地
- [x] 扫码导入节点
- [ ] 自有隧道加密协议（替换 UDP 占位）
- [ ] 更完整的流量统计与 Today Widget
- [ ] 节点延迟探测

---

## 📚 Learning Notes

本项目参考了经典开源 [ShadowVPN-iOS](https://github.com/clowwindy/ShadowVPN-iOS) 的扩展架构思路（`PacketTunnelProvider` + CHNRoutes），用现代 Swift / 工程结构重写，便于继续迭代。

关键词（便于检索）：`iOS VPN` · `Network Extension` · `NEPacketTunnelProvider` · `NETunnelProviderManager` · `split tunneling` · `智能分流` · `CHNRoutes` · `扫码节点` · `Swift VPN Demo`

---

## ⚠️ Disclaimer

本仓库仅为 **学习与演示** 用途，不提供任何翻墙服务，也不附带可用的商业 VPN 服务器。请遵守当地法律法规与 Apple 开发者协议。

---

## 📄 License

MIT — 可自由用于学习与二次开发。详见 [LICENSE](LICENSE)。

---

<p align="center">
  <sub>Made for learning iOS Network Extension · <a href="https://github.com/476139183/VPNDemo">476139183/VPNDemo</a></sub>
</p>
