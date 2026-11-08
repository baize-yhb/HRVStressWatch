# 把项目 push 到 GitHub 并触发 CI

## 前置：Windows 上安装 Git

如果没装：https://git-scm.com/download/win

## 步骤 1：创建 GitHub 仓库

1. 打开 https://github.com/new
2. Repository name: `HRVStressWatch`
3. 选 **Private**（推荐，避免代码公开）
   - **⚠️ 私有仓库每月免费 CI 分钟数 2000，本项目单次构建约 8-15 分钟，够用**
   - 如果选 Public，CI 无限免费，但代码公开
4. **不要**勾选 "Add a README"、".gitignore"、"license"（我们已经有了）
5. 点 Create repository
6. 记下仓库地址，例如 `https://github.com/YOUR_NAME/HRVStressWatch.git`

## 步骤 2：本地初始化 + push

打开 PowerShell 或 Git Bash，切换到项目目录：

```bash
cd "C:\Users\百泽\.qoderworkcn\workspace\mw7yvlszqcm75szd\outputs\HRVStressWatch\github-build"

git init
git add .
git commit -m "Initial commit: HRVStressWatch iOS+watchOS skeleton"
git branch -M main
git remote add origin https://github.com/YOUR_NAME/HRVStressWatch.git
git push -u origin main
```

首次 push 会弹出 GitHub 登录窗口，用浏览器授权即可。

## 步骤 3：观察 CI 运行

1. 打开 https://github.com/YOUR_NAME/HRVStressWatch/actions
2. 应该看到一个 "Build iOS + watchOS" workflow 正在运行
3. 约 8-15 分钟完成
4. 点进去看每个 job 的日志

## 步骤 4：下载产物

CI 成功后，页面底部 "Artifacts" 区域会有：
- `build-log-iOS`
- `build-log-watchOS`
- `HRVStressWatch-unsigned` ← 这是重签用的 .ipa

点击即可下载 zip。

## 步骤 5：如果编译失败

**常见错误**：

### A. Xcode 版本不匹配
```
error: The Xcode version 16.2 is not available
```
→ 编辑 `.github/workflows/build.yml`，把 `Xcode_16.2.app` 改成实际存在的版本。
可用版本查询：https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md

### B. xcodegen 找不到 target
```
Target 'HRVStressWatch Watch App' has no sources
```
→ 检查 `project.yml` 里的路径和实际目录结构是否一致。

### C. HealthKit 权限错误
```
error: Use of undeclared type 'HKQuantityType'
```
→ HealthKit framework 需要在 target 里显式引入。xcodegen 会自动处理，但如果失败可以在 `project.yml` 加：
```yaml
dependencies:
  - sdk: HealthKit.framework
```

### D. watchOS SDK 版本问题
```
error: watchOS 10.0 is not available
```
→ Xcode 16 默认支持 watchOS 11+，把 project.yml 里的 `watchOS: "10.0"` 改成 `"11.0"`。

### E. Swift 语法错误
→ 把 `build-log-iOS.zip` 下载后解压看具体错误，发给我我帮你修。

## 步骤 6：迭代

改代码 → `git add . && git commit -m "fix: xxx" && git push` → CI 自动重跑

## 提示：私有仓库转公开

如果私有仓库的 2000 分钟/月不够用，可以：
- 临时转 Public（Settings → General → Danger Zone → Change visibility）
- 或者升级 GitHub Pro（$4/月，3000 分钟）
- 或者优化 workflow 减少构建时间（缓存 Derived Data 已配置）

## 让 AI 帮你调试

CI 失败后，把 build-log 里的 error 部分复制粘贴给我，我会：
1. 定位错误位置
2. 给出修改后的完整 Swift 代码
3. 你在 Windows 上用编辑器改，push，重新触发 CI

这个循环直到编译通过为止。
