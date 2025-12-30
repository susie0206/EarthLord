# 临时跳过认证（仅用于测试）

## 如何跳过登录直接进入主应用

如果你想快速测试那四个 Tab 页面，可以临时注释掉认证逻辑。

### 修改 RootView.swift

**原代码：**
```swift
var body: some View {
    ZStack {
        if !splashFinished {
            // 启动页
            SplashView(authManager: authManager, isFinished: $splashFinished)
                .transition(.opacity)
        } else if authManager.isAuthenticated {
            // 已认证：显示主应用
            MainTabView()
                .transition(.opacity)
                .environmentObject(authManager)
        } else {
            // 未认证：显示认证页面
            AuthView()
                .transition(.opacity)
                .environmentObject(authManager)
        }
    }
}
```

**修改为（临时测试）：**
```swift
var body: some View {
    ZStack {
        if !splashFinished {
            // 启动页
            SplashView(authManager: authManager, isFinished: $splashFinished)
                .transition(.opacity)
        } else {
            // 🔧 临时跳过认证，直接显示主应用
            MainTabView()
                .transition(.opacity)
                .environmentObject(authManager)
        }
    }
}
```

或者更简单，直接在 RootView 返回 MainTabView：

```swift
var body: some View {
    MainTabView()  // 🔧 直接显示主应用（跳过启动页和认证）
        .environmentObject(authManager)
}
```

### ⚠️ 重要提示

这种修改**仅用于开发测试**！

完成测试后，请**恢复原来的代码**，否则：
- ❌ 用户无法注册/登录
- ❌ 没有用户数据
- ❌ 数据库操作会失败（因为没有 auth.uid()）

---

## 正确的开发流程

1. **第一次运行**：完成注册流程，创建测试账号
2. **后续开发**：应用会记住登录状态，直接进入主应用
3. **如需重置**：
   - 方式1：在"更多"页面添加"登出"按钮
   - 方式2：卸载应用重新安装

---

**建议**: 不要跳过认证，而是完成一次注册，后续开发会自动保持登录状态。
