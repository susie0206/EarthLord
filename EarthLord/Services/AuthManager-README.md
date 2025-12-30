# AuthManager 使用说明

## 概述

`AuthManager` 是 EarthLord 游戏的认证管理器，负责处理用户注册、登录、密码重置等所有认证流程。

## 核心特性

### 1. 注册流程（三步走）

```
发送验证码 → 验证OTP（已登录） → 强制设置密码 → 完成
```

**示例代码：**

```swift
let authManager = AuthManager()

// 步骤 1: 发送注册验证码
await authManager.sendRegisterOTP(email: "user@example.com")

// 步骤 2: 验证验证码（验证成功后用户已登录，但需要设置密码）
await authManager.verifyRegisterOTP(email: "user@example.com", code: "123456")

// 此时：otpVerified = true, needsPasswordSetup = true, isAuthenticated = false

// 步骤 3: 设置密码完成注册
await authManager.completeRegistration(password: "securePassword123")

// 此时：needsPasswordSetup = false, isAuthenticated = true
```

### 2. 登录流程（一步直达）

```swift
// 使用邮箱和密码直接登录
await authManager.signIn(email: "user@example.com", password: "securePassword123")

// 成功后：isAuthenticated = true
```

### 3. 找回密码流程

```
发送重置验证码 → 验证OTP（已登录） → 设置新密码 → 完成
```

**示例代码：**

```swift
// 步骤 1: 发送密码重置验证码
await authManager.sendResetOTP(email: "user@example.com")

// 步骤 2: 验证验证码（⚠️ 注意使用 .recovery 类型）
await authManager.verifyResetOTP(email: "user@example.com", code: "123456")

// 步骤 3: 设置新密码
await authManager.resetPassword(newPassword: "newSecurePassword123")
```

## 状态属性

### Published 属性（可在 SwiftUI 中观察）

| 属性 | 类型 | 说明 |
|------|------|------|
| `isAuthenticated` | Bool | 用户已完全认证（已登录且完成所有流程） |
| `needsPasswordSetup` | Bool | OTP 验证后需要设置密码的中间状态 |
| `currentUser` | User? | 当前登录用户信息 |
| `isLoading` | Bool | 是否正在处理请求 |
| `errorMessage` | String? | 错误消息 |
| `otpSent` | Bool | 验证码是否已发送 |
| `otpVerified` | Bool | 验证码是否已验证（等待设置密码） |

## 在 SwiftUI 中使用

### 基本用法

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // 已认证，显示主应用
                MainTabView()
            } else if authManager.needsPasswordSetup {
                // 需要设置密码
                SetPasswordView(authManager: authManager)
            } else {
                // 未认证，显示登录页面
                LoginView(authManager: authManager)
            }
        }
    }
}
```

### 作为环境对象使用

```swift
@main
struct EarthLordApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}

// 在子视图中访问
struct SomeView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        // 使用 authManager
    }
}
```

## 重要注意事项

### ⚠️ 关键流程说明

1. **注册后必须设置密码**
   - `verifyRegisterOTP` 成功后，`otpVerified = true`，`needsPasswordSetup = true`
   - 此时用户已登录，但 `isAuthenticated` 仍为 `false`
   - **必须**调用 `completeRegistration` 设置密码后，才能进入主页

2. **密码重置使用不同的 OTP 类型**
   - 注册/登录：`type: .email`
   - 密码重置：`type: .recovery`（重要！）

3. **会话管理**
   - 应用启动时自动调用 `checkSession()`
   - 检测并恢复现有登录状态

4. **错误处理**
   - 所有方法都会更新 `errorMessage` 属性
   - UI 应监听并显示错误消息
   - 使用 `clearError()` 清除错误消息

## 完整流程示例

### 注册流程视图

```swift
struct RegisterFlowView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var code = ""
    @State private var password = ""
    @State private var step = 1

    var body: some View {
        VStack(spacing: 20) {
            if step == 1 {
                // 步骤 1: 输入邮箱
                TextField("邮箱", text: $email)
                    .textFieldStyle(.roundedBorder)

                Button("发送验证码") {
                    Task {
                        await authManager.sendRegisterOTP(email: email)
                        if authManager.otpSent {
                            step = 2
                        }
                    }
                }
                .disabled(authManager.isLoading)

            } else if step == 2 {
                // 步骤 2: 输入验证码
                TextField("验证码", text: $code)
                    .textFieldStyle(.roundedBorder)

                Button("验证") {
                    Task {
                        await authManager.verifyRegisterOTP(email: email, code: code)
                        if authManager.otpVerified {
                            step = 3
                        }
                    }
                }
                .disabled(authManager.isLoading)

            } else if step == 3 {
                // 步骤 3: 设置密码
                SecureField("设置密码", text: $password)
                    .textFieldStyle(.roundedBorder)

                Button("完成注册") {
                    Task {
                        await authManager.completeRegistration(password: password)
                        // 成功后 isAuthenticated = true，自动跳转到主页
                    }
                }
                .disabled(authManager.isLoading)
            }

            if let error = authManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            if authManager.isLoading {
                ProgressView()
            }
        }
        .padding()
    }
}
```

## 第三方登录（预留）

### Sign in with Apple

```swift
// TODO: 未来实现
await authManager.signInWithApple()
```

### Sign in with Google

```swift
// TODO: 未来实现
await authManager.signInWithGoogle()
```

## 工具方法

### 登出

```swift
await authManager.signOut()
```

### 重置 OTP 状态（重新发送验证码）

```swift
authManager.resetOTPState()
```

### 清除错误消息

```swift
authManager.clearError()
```

## 数据流图

```
                    注册流程
        ┌─────────────────────────────┐
        │ sendRegisterOTP()           │
        │ otpSent = true              │
        └──────────┬──────────────────┘
                   │
        ┌──────────▼──────────────────┐
        │ verifyRegisterOTP()         │
        │ otpVerified = true          │
        │ needsPasswordSetup = true   │
        │ isAuthenticated = false     │ ◄── 已登录但未完成
        └──────────┬──────────────────┘
                   │
        ┌──────────▼──────────────────┐
        │ completeRegistration()      │
        │ needsPasswordSetup = false  │
        │ isAuthenticated = true      │ ◄── 完全认证
        └─────────────────────────────┘


                    登录流程
        ┌─────────────────────────────┐
        │ signIn()                    │
        │ isAuthenticated = true      │ ◄── 直接完成
        └─────────────────────────────┘


                找回密码流程
        ┌─────────────────────────────┐
        │ sendResetOTP()              │
        │ otpSent = true              │
        └──────────┬──────────────────┘
                   │
        ┌──────────▼──────────────────┐
        │ verifyResetOTP()            │
        │ type: .recovery (⚠️重要)    │
        │ otpVerified = true          │
        │ needsPasswordSetup = true   │
        └──────────┬──────────────────┘
                   │
        ┌──────────▼──────────────────┐
        │ resetPassword()             │
        │ needsPasswordSetup = false  │
        │ isAuthenticated = true      │
        └─────────────────────────────┘
```

## 安全建议

1. **生产环境配置**
   - 将 Supabase URL 和 Key 移至环境变量或配置文件
   - 不要在代码中硬编码敏感信息

2. **密码强度验证**
   - 建议在 UI 层添加密码强度检查
   - 最小长度 8 位，包含大小写字母和数字

3. **OTP 验证码**
   - 默认 6 位数字
   - 有效期通常为 5-10 分钟（Supabase 配置）

4. **错误处理**
   - 生产环境不要直接显示详细错误信息
   - 使用用户友好的错误提示

---

**版本**: 1.0
**创建日期**: 2025-12-29
**维护者**: 开发团队
