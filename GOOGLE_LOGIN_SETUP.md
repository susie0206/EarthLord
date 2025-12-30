# Google 登录功能实现说明

## ✅ 已完成的配置

### 1. Info.plist 配置
⚠️ **需要手动配置 URL Scheme**

由于项目配置冲突，已删除独立的 Info.plist 文件。

**请按照以下步骤在 Xcode 中配置：**

1. 打开 Xcode 项目
2. 选择项目 → Target → Info
3. 找到 "URL Types" 部分
4. 添加 URL Scheme：
   ```
   com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd
   ```

**详细配置指南**：请查看 `XCODE_GOOGLE_SIGNIN_SETUP.md`

### 2. 依赖包
已安装：
- GoogleSignIn v9.0.0
- GoogleSignInSwift
- 相关依赖（AppAuth, GoogleUtilities, GTMAppAuth 等）

### 3. Supabase 配置
- ✅ Google Provider 已启用
- ✅ Authorized Client IDs 已填入
- ✅ Skip nonce check 已开启

## 📝 代码实现

### AuthManager.swift
实现了完整的 Google 登录流程：

```swift
func signInWithGoogle() async {
    // 1. 获取根视图控制器
    // 2. 配置 Google Sign-In (Client ID)
    // 3. 启动 Google 登录界面
    // 4. 获取 ID Token
    // 5. 使用 ID Token 登录 Supabase
    // 6. 更新认证状态
    // 7. 获取用户信息
}
```

### EarthLordApp.swift
添加了 URL 回调处理：

```swift
.onOpenURL { url in
    // 处理 Google OAuth 回调
    if url.scheme == "com.googleusercontent.apps..." {
        GIDSignIn.sharedInstance.handle(url)
    }
}
```

### AuthView.swift
更新了 Google 登录按钮：

```swift
Button {
    Task {
        await authManager.signInWithGoogle()
    }
} label: {
    // Google 登录按钮 UI
}
```

## 🔍 调试日志

代码中已添加详细的中文日志，方便调试：

### 登录流程日志
```
🔵 [Google登录] 开始 Google 登录流程
🔵 [Google登录] 步骤1: 获取根视图控制器
✅ [Google登录] 根视图控制器获取成功
🔵 [Google登录] 步骤2: 配置 Google Sign-In
✅ [Google登录] Google 配置完成，Client ID: xxx
🔵 [Google登录] 步骤3: 启动 Google 登录界面
✅ [Google登录] Google 登录界面完成
🔵 [Google登录] 步骤4: 获取 Google ID Token
✅ [Google登录] ID Token 获取成功 (长度: xxx 字符)
🔵 [Google登录] 步骤5: 使用 ID Token 登录 Supabase
✅ [Google登录] Supabase 登录成功
   用户ID: xxx
   用户邮箱: xxx
🔵 [Google登录] 步骤6: 更新认证状态
✅ [Google登录] 认证状态已更新
🔵 [Google登录] 步骤7: 获取用户详细信息
✅ [Google登录] 用户信息已加载
🎉 [Google登录] Google 登录流程完成！
```

### 错误日志
```
❌ [Google登录] 登录失败: xxx
⚠️ [Google登录] 用户取消了登录
⚠️ [Google登录] 没有保存的认证信息
⚠️ [Google登录] Google 错误代码: xxx
```

### OAuth 回调日志
```
🔵 [OAuth回调] 收到 URL: xxx
✅ [OAuth回调] 识别为 Google Sign-In 回调
⚠️ [OAuth回调] 未知的 URL Scheme: xxx
```

## 🧪 测试步骤

### 1. 在模拟器/真机上测试
```bash
# 1. 构建并运行应用
Cmd+R

# 2. 导航到登录页面
# 3. 点击"使用 Google 登录"按钮
# 4. 在弹出的 Google 登录界面中选择账号
# 5. 授权应用访问
# 6. 观察控制台日志
```

### 2. 查看日志
在 Xcode 控制台中查看：
- 打开 Xcode
- 运行应用
- 查看底部控制台输出
- 搜索 "[Google登录]" 或 "[OAuth回调]"

### 3. 验证登录成功
登录成功后应该：
- ✅ 自动跳转到主页面（四个Tab）
- ✅ 个人页面显示用户信息
- ✅ 用户邮箱显示为 Google 账号邮箱
- ✅ 登录状态显示"在线"（绿点）

## ⚠️ 常见问题

### 1. Info.plist 未生效
**解决方案：**
- 在 Xcode 中，选择项目 → Target → Info 标签
- 手动添加 URL Types
- 或者清理构建：`Cmd+Shift+K` 后重新构建

### 2. Google 登录界面不显示
**可能原因：**
- Client ID 配置错误
- URL Scheme 配置错误
- 网络连接问题

**解决方案：**
- 检查控制台日志
- 确认 Client ID 正确
- 确认 URL Scheme 与 Client ID 匹配

### 3. Supabase 登录失败
**可能原因：**
- Supabase Google Provider 未启用
- Authorized Client IDs 未填写
- Skip nonce check 未开启

**解决方案：**
- 登录 Supabase Dashboard
- 检查 Authentication → Providers → Google
- 确认配置正确

### 4. 用户取消登录
这是正常行为，日志会显示：
```
⚠️ [Google登录] 用户取消了登录
```
用户界面会显示提示：`登录已取消`

## 📱 生产环境配置

### 需要注意的事项：

1. **Client ID 安全**
   - 当前 Client ID 硬编码在代码中
   - 生产环境建议使用配置文件或环境变量

2. **Supabase Key**
   - 当前使用 publishable key（安全）
   - 确保不要泄露 service_role key

3. **URL Scheme**
   - 确保与 Google Cloud Console 配置一致
   - iOS Bundle ID 需要匹配

4. **RLS 策略**
   - 确保 profiles 表的 RLS 策略正确
   - 测试新用户创建流程

## 🔗 相关链接

- Google Cloud Console: https://console.cloud.google.com/
- Supabase Dashboard: https://supabase.com/dashboard
- GoogleSignIn iOS 文档: https://github.com/google/GoogleSignIn-iOS

## 📊 配置信息

- **Google Client ID**: `517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd.apps.googleusercontent.com`
- **URL Scheme**: `com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd`
- **Supabase URL**: `https://absexnnamqwkqedaaamt.supabase.co`
- **GoogleSignIn 版本**: v9.0.0

---

**最后更新**: 2025-12-30
**状态**: ✅ 已实现并可测试
