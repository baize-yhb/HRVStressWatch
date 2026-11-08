# HRVStressWatch

一个基于 HRVSDNN 的 iOS + watchOS 压力监测应用，功能对标 StressWatch。

## 项目结构

```
.
├── .github/workflows/build.yml    # GitHub Actions CI 配置
├── project.yml                     # xcodegen 声明式项目定义
├── Shared/                         # iOS + watchOS 共用代码
│   ├── Models/StressLevel.swift
│   └── Services/
│       ├── HealthKitManager.swift
│       └── StressCalculator.swift
├── iOS/                            # iPhone App Target
│   ├── HRVStressWatchApp.swift
│   ├── DashboardView.swift
│   ├── iOSDashboardViewModel.swift
│   └── Assets.xcassets/
└── watchOS/                        # Watch App Target
    ├── HRVStressWatchWatchApp.swift
    ├── EmojiFace.swift
    ├── WatchMainView.swift
    ├── WatchViewModel.swift
    ├── WatchSettingsView.swift
    └── Assets.xcassets/
```

## CI 编译（GitHub Actions）

每次 push 到 `main` / `develop` 分支自动触发：

1. `build` job：macos-15 runner + Xcode 16.2，用 xcodegen 生成项目后编译 iOS + watchOS 两个 Scheme（模拟器 SDK，不做签名）
2. `package-unsigned` job：产出未签名的 `.app`，打包成 `HRVStressWatch-unsigned.ipa` 作为 artifact

在 Actions 页面可以下载：
- `build-log-iOS` / `build-log-watchOS`：完整编译日志
- `HRVStressWatch-unsigned`：可安装到设备的未签名 ipa（需要重签）

## 本地生成 Xcode 项目（可选）

如果你有 Mac：

```bash
brew install xcodegen
xcodegen generate
open HRVStressWatch.xcodeproj
```

## 部署到设备

见 [`SIDLOAD-Guide.md`](./SIDLOAD-Guide.md)。

**重要**：由于免费 Apple Developer 账号的限制，从 Windows 直接装机存在障碍。推荐路径：
- **短期验证**：借一台 Mac 一次性装机（最快）
- **长期使用**：租云 Mac 一次性签名 + Sideloadly 每 7 天重签

## 开发路线图

- [x] Week 1：CI 编译通过，代码骨架完成
- [ ] Week 2：真机装机验证 HRV 数据读取
- [ ] Week 3：Complication + 表情自定义完善
- [ ] Week 4：稳定化 + 电池优化
