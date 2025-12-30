# AuthView 使用说明

## 概述

`AuthView` 是 EarthLord 的完整认证页面，提供登录、注册、忘记密码等功能，使用末日废土风格的 UI 设计。

## 界面预览

### 整体布局
```
┌─────────────────────────────┐
│   [深色渐变背景]              │
│                              │
│         🌍                   │
│      地球新主                 │
│     EarthLord               │
│                              │
│   ┌────────┬────────┐        │
│   │  登录  │  注册  │ ← Tab  │
│   └────────┴────────┘        │
│                              │
│   [当前 Tab 内容区域]         │
│                              │
│   ───── 或者使用以下方式登录 ───│
│                              │
│   [🍎 使用 Apple 登录]        │
│   [G  使用 Google 登录]       │
│                              │
└─────────────────────────────┘
```

## 功能详解

### 1. 登录 Tab

**界面元素：**
- 邮箱输入框
- 密码输入框
- "忘记密码？"链接
- 登录按钮

**流程：**
```
输入邮箱 + 密码 → 点击登录 → 成功后直接进入主应用
```

**代码逻辑：**
```swift
await authManager.signIn(email: loginEmail, password: loginPassword)
// 成功后 authManager.isAuthenticated = true
// RootView 自动切换到 MainTabView
```

### 2. 注册 Tab - 三步流程

#### 第一步：输入邮箱

**界面：**
- 步骤指示器（● ○ ○）
- 邮箱输入框
- "发送验证码"按钮

**验证：**
- 邮箱格式校验
- 按钮仅在有效邮箱时启用

**流程：**
```swift
await authManager.sendRegisterOTP(email: registerEmail)
// 成功后 otpSent = true，自动跳转到第二步
```

#### 第二步：验证验证码

**界面：**
- 步骤指示器（● ● ○）
- "验证码已发送至 xxx@xxx.com"提示
- 6位验证码输入框（纯数字）
- 60秒倒计时 / "重新发送验证码"链接
- "验证"按钮

**特性：**
- 自动限制只能输入数字
- 自动限制最多6位
- 倒计时结束前不能重发
- 按钮仅在输入6位数字时启用

**流程：**
```swift
await authManager.verifyRegisterOTP(email: registerEmail, code: registerOTP)
// 成功后 otpVerified = true，用户已登录但没密码
// 自动跳转到第三步
```

⚠️ **重要**：此时用户已登录，但 `isAuthenticated` 仍为 `false`

#### 第三步：设置密码

**界面：**
- 步骤指示器（● ● ●）
- "验证成功！请设置您的密码"提示（绿色）
- 密码输入框（带提示）
- 确认密码输入框
- 密码强度指示（✓ 至少 8 位字符）
- "完成注册"按钮

**验证：**
- 密码长度 ≥ 8
- 两次密码一致
- 实时显示密码强度

**流程：**
```swift
if registerPassword == registerConfirmPassword {
    await authManager.completeRegistration(password: registerPassword)
    // 成功后 isAuthenticated = true
    // RootView 自动切换到 MainTabView
}
```

### 3. 忘记密码弹窗

**触发方式：**
点击登录页面的"忘记密码？"链接

**界面：**
- 半透明黑色背景遮罩
- 白色卡片弹窗
- 标题栏带关闭按钮
- 三步流程（同注册流程）

#### 第一步：输入邮箱
```swift
await authManager.sendResetOTP(email: resetEmail)
```

#### 第二步：验证验证码
```swift
await authManager.verifyResetOTP(email: resetEmail, code: resetOTP)
// ⚠️ 注意：使用 .recovery 类型，不是 .email
```

#### 第三步：设置新密码
```swift
await authManager.resetPassword(newPassword: resetPassword)
// 成功后关闭弹窗，用户已登录
```

### 4. 第三方登录（占位）

**界面：**
- 分隔线："或者使用以下方式登录"
- Apple 登录按钮（黑色）
- Google 登录按钮（白色）

**当前行为：**
点击后显示 Toast："Apple/Google 登录功能即将开放"

**代码预留：**
```swift
// AuthManager.swift 中已预留方法
func signInWithApple() async { /* TODO */ }
func signInWithGoogle() async { /* TODO */ }
```

## 状态管理

### AuthManager 状态监听

```swift
@StateObject private var authManager = AuthManager()

// 监听的关键状态
authManager.isAuthenticated      // 控制是否进入主应用
authManager.needsPasswordSetup   // 控制是否显示设置密码步骤
authManager.otpSent              // 控制步骤跳转
authManager.otpVerified          // 控制步骤跳转
authManager.isLoading            // 显示 loading
authManager.errorMessage         // 显示错误
```

### 流程状态自动控制

```swift
.onChange(of: authManager.otpSent) { sent in
    if sent {
        registerStep = 2  // 自动跳转到验证码步骤
        startCountdown()  // 开始倒计时
    }
}

.onChange(of: authManager.otpVerified) { verified in
    if verified {
        registerStep = 3  // 自动跳转到设置密码步骤
    }
}
```

## UI 样式

### 主题色（ApocalypseTheme）

- **背景**：深色渐变（background → cardBackground）
- **主色调**：橙色（#FF6619）- 按钮、高亮
- **文字**：
  - 主文字：白色（textPrimary）
  - 次要文字：灰色（textSecondary）
  - 提示文字：暗灰（textMuted）
- **状态色**：
  - 成功：绿色（success）
  - 错误：红色（danger）

### 自定义组件

**AuthTextFieldStyle**
```swift
struct AuthTextFieldStyle: TextFieldStyle {
    // 统一的文本框样式
    // 深色背景 + 圆角 + 边框
}
```

**stepIndicator**
```swift
// 步骤指示器：● ● ○
// 已完成步骤显示橙色，未完成显示灰色
```

## 集成到应用

### RootView 集成

```swift
struct RootView: View {
    @StateObject private var authManager = AuthManager()
    @State private var splashFinished = false

    var body: some View {
        if !splashFinished {
            SplashView()
        } else if authManager.isAuthenticated {
            MainTabView()
        } else {
            AuthView()
        }
    }
}
```

### 流程图

```
启动应用
   ↓
SplashView (2.5秒动画)
   ↓
检查登录状态
   ├─ 已登录 → MainTabView
   └─ 未登录 → AuthView
              ├─ 登录 Tab
              │  └─ 成功 → MainTabView
              └─ 注册 Tab
                 ├─ 步骤1：发送OTP
                 ├─ 步骤2：验证OTP（已登录但未完成）
                 └─ 步骤3：设置密码 → MainTabView
```

## 注意事项

### 🔴 关键逻辑

1. **注册流程必须完成三步**
   - 第二步验证成功后，用户已登录（Session 已创建）
   - 但 `isAuthenticated = false`，不能进入主应用
   - 必须完成第三步设置密码

2. **密码重置的 OTP 类型不同**
   - 注册/登录：`type: .email`
   - 密码重置：`type: .recovery`

3. **验证码倒计时**
   - 发送成功后开始 60 秒倒计时
   - 倒计时结束前不允许重发
   - 切换 Tab 或关闭弹窗后计时器会继续（可优化）

4. **错误处理**
   - 所有错误通过 Alert 弹窗显示
   - 用户点击"确定"后清除错误

### 🔧 可优化点

1. **验证码输入**
   - 可改为 6 个独立输入框
   - 自动跳转和粘贴优化

2. **密码强度**
   - 可添加更详细的强度指示器
   - 密码可见性切换按钮

3. **加载状态**
   - 可添加全局 loading overlay
   - 防止重复点击

4. **动画优化**
   - 步骤切换可添加滑动动画
   - 错误提示可用 Toast 代替 Alert

## 测试流程

### 注册测试

1. 切换到"注册"Tab
2. 输入邮箱（必须是真实邮箱）
3. 点击"发送验证码"
4. 查收邮箱，获取 6 位验证码
5. 输入验证码，点击"验证"
6. 设置密码（≥8位），确认密码
7. 点击"完成注册"
8. 自动进入主应用

### 登录测试

1. 切换到"登录"Tab
2. 输入注册时使用的邮箱和密码
3. 点击"登录"
4. 自动进入主应用

### 忘记密码测试

1. 点击"忘记密码？"
2. 输入邮箱，发送验证码
3. 输入验证码验证
4. 设置新密码
5. 自动登录并关闭弹窗

---

**版本**: 1.0
**创建日期**: 2025-12-29
**依赖**: AuthManager.swift, ApocalypseTheme.swift
