# 从 GitHub Actions 产物装机到 iPhone + Apple Watch

**目标**：Windows 电脑（你现有的） + 免费 Apple ID → iPhone 15 Pro (iOS 27) + Apple Watch S10 装上自研 App。

**残酷的现实**：Watch App 的旁加载比 iOS App 复杂得多，免费账号 + 无 Mac 环境下**成功率约 50%**。下面按可行性从高到低列出方案，你可以按顺序尝试。

---

## 方案 A（最推荐）：租一次云 Mac，一次性装机

**成本**：约 ¥30-50 人民币，用 1-2 小时

**服务商**：
- **MacinCloud**：https://www.macincloud.com/  $1/小时起，按小时付费
- **Scaleway Mac mini**：https://www.scaleway.com/en/dedibox/apple-silicon/  €0.15/小时
- **AWS EC2 Mac**：$1.083/小时（mac2-m2.4xlarge），最少租 24 小时（$26），不划算

**操作步骤**：
1. 注册 MacinCloud，选 "Pay-As-You-Go" 或 "Managed Server 1 hour"
2. 用远程桌面（Windows 自带 mstsc.exe）连接
3. 云 Mac 上装 Xcode（预装的最好）
4. 用你的 Apple ID 登录 Xcode → Settings → Accounts
5. Git clone 你的仓库，`xcodegen generate`，`open HRVStressWatch.xcodeproj`
6. **关键**：Xcode 里手动把你的 iPhone UDID 和 Watch UDID 添加到 Personal Team 的 Devices 列表
   - iPhone UDID：连接后 Xcode 顶部设备菜单可以看到
   - Watch UDID：Xcode → Window → Devices and Simulators → 选 iPhone → 底部 paired Watches
7. 用数据线（云端要用 IPoverUSB 或者 Xcode 无线调试）连接你的 iPhone 到云 Mac
   - **注意**：云端 Mac 无法直接连接你本地的 iPhone！需要用 **Xcode Cloud 无线调试** 或者放弃此路，改用方案 B
8. Build & Run

**⚠️ 云端 Mac 装机的死结**：Xcode 需要通过 USB 或同一 WiFi 的无线调试连接你的 iPhone。云 Mac 在数据中心，物理上无法连接你的手机。**除非用 Apple 官方的 Xcode Cloud（需要付费开发者账号）**，否则云 Mac 方案对"装机到自己手机"这个目标是无效的。

**云 Mac 真正能做的是**：验证代码能编译、生成 provisioning profile 和签名证书文件（.p12 + .mobileprovision），下载到你 Windows 上，然后用 Sideloadly 完成最终签名。

---

## 方案 B（推荐）：借一台 Mac，一次性装机

**成本**：0，靠人情

**操作**：
1. 找一个有 Mac 的朋友/同事，借用 30 分钟
2. 提前把你 GitHub 仓库地址准备好
3. 到 Mac 上：
   ```bash
   brew install xcodegen
   git clone https://github.com/YOUR_NAME/HRVStressWatch
   cd HRVStressWatch
   xcodegen generate
   open HRVStressWatch.xcodeproj
   ```
4. Xcode 里 Signing & Capabilities 选 **你自己的** Personal Team（用你的 Apple ID 登录 Xcode）
5. iPhone 数据线连 Mac，Xcode 顶部选你的 iPhone，按 ▶️ Run
6. Watch App 会自动通过 iPhone 装到配对的 Watch 上
7. 首次装完，7 天内可以正常使用

**7 天后重签**：
- 再借一次 Mac，重跑步骤 3-6
- 或者用下面方案 C

---

## 方案 C（可行但复杂）：Sideloadly 从 Windows 装机

**成本**：0，Sideloadly 免费

**限制**：**只对 iOS App 稳定，Watch App 支持不完善**

**准备工作**：
1. 下载 Sideloadly：https://sideloadly.io/
2. 安装 iTunes（Windows 版，为 iPhone 提供驱动）：Microsoft Store 或 https://www.apple.com/itunes/
3. 从 GitHub Actions 下载 `HRVStressWatch-unsigned.ipa` artifact
4. 用你的 Apple ID 申请 **App-Specific Password**：https://appleid.apple.com/ → 登录 → Sign-In and Security → App-Specific Passwords

**装机步骤（iOS App 部分）**：
1. iPhone 数据线连 Windows，信任电脑
2. 打开 Sideloadly
3. 拖入 `.ipa` 文件
4. Apple ID 填你的邮箱，Password 填 App-Specific Password
5. 点 Start
6. 等待签名 + 安装完成
7. iPhone 上：设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID

**Watch App 部分——这是难点**：
- Sideloadly 对 Watch App 的支持需要 `.ipa` 里正确嵌入 Watch App
- 免费账号的 provisioning profile 需要同时列出 iPhone 和 Watch 的 UDID
- Sideloadly 自动生成的 profile 通常只包含 iPhone UDID
- **成功率约 30-50%**，社区反馈不一

**如果 Watch App 装不上，只能装 iOS App 的降级方案**：
- iOS App 依然能读 HRVSDNN（Watch 采集后自动同步到 iPhone 健康数据库）
- 但没有 Watch 端的实时表情，需要掏手机看
- 这已经不是"类似 StressWatch"了

**7 天重签**：Sideloadly 支持 "Auto Re-sign"（自动重签），需要在 Windows 上保持 Sideloadly 后台运行 + iPhone 定期连接。可以设置每周日晚上提醒。

---

## 方案 D（最诚实）：先别装机，先用 CI 验证代码正确性

**成本**：0

**做法**：
1. 把代码 push 到 GitHub
2. 等 Actions 跑完（约 5-10 分钟）
3. 看 build log 有没有编译错误
4. 有错误就修，没错误就说明代码本身没问题
5. 装机推迟到你有 Mac 或找到愿意借 Mac 的朋友

**优势**：
- 零成本验证代码质量
- 编译日志能提前发现 iOS 27 SDK 兼容性问题
- 修 bug 比装机重要，装不上机也不影响开发进度

---

## 我的建议路径

**第一步（今天/明天）**：走方案 D
- 建 GitHub 仓库，push 代码，看 CI 编译能否通过
- 我帮你解决编译错误
- 目标是拿到一个"确定能编译"的代码库

**第二步（一周内）**：走方案 B
- 找机会借一台 Mac，装到你自己设备
- 实测 3-5 天，验证 HRV 数据准确性和表情效果

**第三步（如果验证有效）**：决定长期投入
- 效果好 → 花 $99 买付费账号（可以用 TestFlight，不用每周重签）
- 效果不好 → 项目终止，改用 App Store 上现成的 StressWatch Pro 版

---

## 附录：查询设备 UDID

**iPhone UDID**（Windows）：
1. 装 iTunes，用数据线连接 iPhone
2. iTunes 顶部点击 iPhone 图标
3. 点击设备名下方的序列号，会切换显示 UDID
4. 右键复制

**Apple Watch UDID**：
- 只能通过 Xcode 或 macOS 的 Apple Configurator 2 查看
- Windows 上没有原生工具
- **这也是为什么方案 C 对 Watch App 不友好**
