# 认证流程完善说明

## 概述

已完成 EarthLord 应用的完整认证流程实现，包括启动画面、会话检查和认证状态监听。

## 修改的文件

### 1. ✅ EarthLordApp.swift

**修改内容：**
- 添加应用级别的 `AuthManager` 单例
- 将 `authManager` 作为环境对象传递给整个应用

**代码：**
```swift
@main
struct EarthLordApp: App {
    /// 认证管理器（应用级别的单例）
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)  // ← 传递给整个应用
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**优点：**
- 整个应用共享同一个 `AuthManager` 实例
- 任何子视图都可以通过 `@EnvironmentObject` 访问
- 避免重复创建实例

---

### 2. ✅ SplashView.swift

**修改内容：**
- 接收 `AuthManager` 参数
- 在启动时调用 `checkSession()` 检查现有登录状态
- 更新加载文字提示

**代码：**
```swift
struct SplashView: View {
    /// 认证管理器
    @ObservedObject var authManager: AuthManager

    private func simulateLoading() {
        // 第一步：初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadingText = "正在检查登录状态..."
        }

        // 第二步：检查会话
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                await authManager.checkSession()  // ← 检查会话

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    loadingText = "正在加载资源..."
                }
            }
        }

        // 第三步：准备完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            loadingText = "准备就绪"
        }

        // 完成加载，进入主界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFinished = true
            }
        }
    }
}
```

**流程：**
```
启动应用
  ↓
显示 Logo 和动画 (0.5s)
  ↓
"正在检查登录状态..." (0.5s)
  ↓
调用 checkSession() (1.0s)
  ↓
"正在加载资源..." (0.5s)
  ↓
"准备就绪" (0.5s)
  ↓
进入主界面 (2.5s 后)
```

---

### 3. ✅ RootView.swift

**修改内容：**
- 使用 `@EnvironmentObject` 接收 `authManager`
- 将 `authManager` 传递给 `SplashView`

**代码：**
```swift
struct RootView: View {
    @State private var splashFinished = false

    /// 认证管理器（从 App 传递）
    @EnvironmentObject var authManager: AuthManager

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
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}
```

**页面切换逻辑：**
```
┌──────────────────────────────────────────┐
│ splashFinished == false                  │
│   → SplashView                           │
└──────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────┐
│ splashFinished == true                   │
│                                          │
│ ├─ authManager.isAuthenticated == true  │
│ │    → MainTabView (主应用)              │
│ │                                        │
│ └─ authManager.isAuthenticated == false │
│      → AuthView (认证页面)               │
└──────────────────────────────────────────┘
```

---

### 4. ✅ AuthView.swift

**修改内容：**
- 使用 `@EnvironmentObject` 接收 `authManager`
- 移除本地的 `@StateObject` 实例

**代码：**
```swift
struct AuthView: View {
    /// 认证管理器（从父视图传递）
    @EnvironmentObject var authManager: AuthManager

    // 其余代码保持不变...
}
```

---

### 5. ✅ AuthManager.swift

**新增功能：认证状态监听**

**代码：**
```swift
init() {
    // 初始化 Supabase 客户端
    self.supabase = SupabaseClient(...)

    // 设置认证状态监听（在后台运行）
    Task {
        await setupAuthStateListener()
    }

    // 检查现有会话
    Task {
        await checkSession()
    }
}

// MARK: - Auth State Listener

/// 设置认证状态监听器
/// 监听登录、登出等认证状态变化
private func setupAuthStateListener() async {
    // 监听认证状态变化
    for await state in supabase.auth.authStateChanges {
        await handleAuthStateChange(state)
    }
}

/// 处理认证状态变化
private func handleAuthStateChange(_ state: AuthChangeEvent) async {
    switch state {
    case .signedIn:
        // 用户登录
        print("🔐 用户已登录")
        isAuthenticated = true
        await fetchCurrentUser()

    case .signedOut:
        // 用户登出
        print("🔓 用户已登出")
        isAuthenticated = false
        currentUser = nil
        needsPasswordSetup = false
        otpSent = false
        otpVerified = false

    case .tokenRefreshed:
        // Token 刷新
        print("🔄 Token 已刷新")

    case .userUpdated:
        // 用户信息更新
        print("📝 用户信息已更新")
        await fetchCurrentUser()

    default:
        break
    }
}
```

**监听的事件：**
- ✅ `.signedIn` - 用户登录
- ✅ `.signedOut` - 用户登出
- ✅ `.tokenRefreshed` - Token 刷新
- ✅ `.userUpdated` - 用户信息更新

---

## 完整的认证流程

### 首次启动（未登录）

```
1. 应用启动
   ↓
2. EarthLordApp 创建 AuthManager
   ↓
3. AuthManager.init()
   - setupAuthStateListener() (后台监听)
   - checkSession() (检查会话 → 无会话)
   ↓
4. RootView 显示 SplashView
   ↓
5. SplashView 再次调用 checkSession()
   - 确认无有效会话
   - isAuthenticated = false
   ↓
6. SplashView 完成 (2.5s 后)
   - splashFinished = true
   ↓
7. RootView 显示 AuthView
   ↓
8. 用户完成注册/登录
   - signIn() 或 completeRegistration()
   - isAuthenticated = true
   - 触发 authStateChanges → .signedIn
   ↓
9. RootView 自动切换到 MainTabView
```

### 再次启动（已登录）

```
1. 应用启动
   ↓
2. AuthManager.checkSession()
   - 检测到有效 session
   - isAuthenticated = true
   - fetchCurrentUser()
   ↓
3. SplashView 加载完成
   ↓
4. RootView 直接显示 MainTabView
   - 无需重新登录
```

### 用户登出

```
1. 用户点击登出
   ↓
2. AuthManager.signOut()
   - 调用 supabase.auth.signOut()
   ↓
3. 触发 authStateChanges → .signedOut
   ↓
4. handleAuthStateChange()
   - isAuthenticated = false
   - currentUser = nil
   - 清空所有状态
   ↓
5. RootView 自动切换到 AuthView
```

---

## 关键特性

### 1. 🔄 自动状态同步

- 使用 `supabase.auth.authStateChanges` 监听认证状态
- 登录/登出自动更新 `isAuthenticated`
- UI 自动响应状态变化

### 2. 🎯 单一数据源

- 整个应用只有一个 `AuthManager` 实例
- 通过 `@EnvironmentObject` 共享
- 避免状态不一致

### 3. 💾 会话持久化

- 启动时自动检查现有会话
- Token 自动刷新
- 无需重复登录

### 4. 🎨 流畅的用户体验

- SplashView 显示加载进度
- 平滑的页面切换动画
- 自动跳转（登录后进入主应用，登出后返回登录页）

---

## 测试流程

### 测试场景 1：首次启动并注册

1. 启动应用 → 看到 SplashView
2. 2.5秒后自动进入 AuthView
3. 切换到"注册" Tab
4. 完成三步注册流程
5. 自动进入 MainTabView

### 测试场景 2：登出后重新登录

1. 在 MainTabView 中点击登出
2. 自动返回 AuthView
3. 输入邮箱密码登录
4. 自动进入 MainTabView

### 测试场景 3：重启应用（已登录）

1. 关闭应用
2. 重新启动
3. SplashView 加载时检测到有效会话
4. 自动进入 MainTabView（无需重新登录）

---

## 控制台日志

应用运行时，你会看到以下日志：

```
🔐 用户已登录
📝 用户信息已更新
🔄 Token 已刷新
🔓 用户已登出
```

这些日志帮助你了解认证状态的变化。

---

## 注意事项

### ⚠️ 重要

1. **EnvironmentObject 传递**
   - 必须在 `EarthLordApp` 中创建 `authManager`
   - 所有子视图通过 `.environmentObject()` 接收
   - Preview 中也需要提供 `authManager`

2. **异步监听**
   - `setupAuthStateListener()` 使用 `for await` 循环
   - 必须在后台 Task 中运行
   - 不会阻塞主线程

3. **会话检查时机**
   - `init()` 中检查一次（初始化）
   - `SplashView` 中检查一次（确保最新状态）
   - 可以在需要时手动调用 `checkSession()`

---

## 未来优化建议

1. **错误处理增强**
   - 网络错误提示
   - 会话过期处理
   - 自动重试机制

2. **加载优化**
   - 并行加载资源
   - 缓存用户数据
   - 减少启动时间

3. **安全性提升**
   - 生物识别登录（Face ID / Touch ID）
   - 设备绑定
   - 异常登录检测

4. **用户体验**
   - 记住上次登录的邮箱
   - 自动填充
   - 手势快捷登录

---

**完成时间**: 2025-12-29
**状态**: ✅ 完整实现
**测试**: 待验证
