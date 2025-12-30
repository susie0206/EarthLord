# Xcode Google Sign-In URL Scheme 配置指南

## 问题说明

我已经删除了独立的 `Info.plist` 文件，因为它与 Xcode 自动生成的配置冲突。

现代 SwiftUI 项目（iOS 14+）不需要独立的 Info.plist 文件，可以直接在 Xcode 项目设置中配置 URL Schemes。

## 📝 配置步骤

### 方法 1: 在 Xcode 中配置 URL Schemes（推荐）

1. **打开 Xcode 项目**
   - 双击 `EarthLord.xcodeproj` 打开项目

2. **选择项目和 Target**
   - 在左侧导航栏中点击项目名称 "EarthLord"（最顶部的蓝色图标）
   - 在中间栏选择 "EarthLord" Target（不是项目）

3. **进入 Info 标签**
   - 点击顶部的 "Info" 标签

4. **添加 URL Types**
   - 找到 "URL Types" 部分
   - 如果没有看到，点击底部的 "+" 按钮添加新部分
   - 或者展开 "Custom iOS Target Properties"

5. **添加 Google URL Scheme**
   - 点击 "URL Types" 左侧的展开箭头
   - 点击 "URL Types" 右侧的 "+" 按钮添加新项
   - 在新添加的项中：
     - **Identifier**: `Google Sign-In` （可选，任意名称）
     - **URL Schemes**: 点击展开，添加：
       ```
       com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd
       ```
     - **Role**: `Editor`（默认）

6. **保存并重新构建**
   - Command + B 重新构建项目
   - 或 Command + R 运行项目

### 方法 2: 使用 Info.plist 文件（备选）

如果你更喜欢使用 Info.plist 文件：

1. **在 Xcode 中创建 Info.plist**
   - 右键点击 "EarthLord" 文件夹
   - 选择 "New File..."
   - 选择 "Property List"
   - 命名为 "Info.plist"

2. **编辑 Info.plist**
   - 在 Info.plist 中右键 → "Open As" → "Source Code"
   - 添加以下内容：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

3. **配置项目使用此 Info.plist**
   - 选择项目 → Target → Build Settings
   - 搜索 "Info.plist File"
   - 设置为 `EarthLord/Info.plist`

## ✅ 验证配置

### 1. 检查 URL Scheme 是否正确

在 Xcode 中：
1. 选择项目 → Target → Info
2. 展开 "URL Types"
3. 确认看到 Google 的 URL Scheme

### 2. 测试 URL Scheme

在终端运行：

```bash
xcrun simctl openurl booted "com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd://oauth2callback"
```

如果配置正确，应用会接收到这个 URL。

### 3. 查看编译后的 Info.plist

在终端运行：

```bash
# 构建项目后
cat ~/Library/Developer/Xcode/DerivedData/EarthLord-*/Build/Products/Debug-iphonesimulator/EarthLord.app/Info.plist | grep -A 10 CFBundleURLTypes
```

应该能看到配置的 URL Scheme。

## 🎯 预期效果

配置完成后，Info.plist 应该包含：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd</string>
        </array>
    </dict>
</array>
```

## 🔍 如何确认配置成功

1. **构建项目成功**
   - Command + B 构建项目
   - 没有 Info.plist 相关的错误

2. **Google 登录流程正常**
   - 运行应用
   - 点击 "使用 Google 登录"
   - Google 登录界面正常弹出
   - 登录后能正常回调到应用

3. **查看控制台日志**
   ```
   🔵 [OAuth回调] 收到 URL: com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd://...
   ✅ [OAuth回调] 识别为 Google Sign-In 回调
   ```

## 📸 配置截图参考

### URL Types 配置界面应该显示：

```
URL Types (1 item)
  └─ Item 0
      ├─ Identifier: Google Sign-In
      ├─ URL Schemes (1 item)
      │   └─ Item 0: com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd
      └─ Role: Editor
```

## 🐛 常见问题

### 问题 1: "Multiple commands produce Info.plist"

**原因**:
- 有多个 Info.plist 文件
- Info.plist 被错误地添加到 Copy Bundle Resources

**解决方案**:
1. 删除多余的 Info.plist 文件
2. 使用方法 1（在 Xcode 中直接配置）
3. 确保 Info.plist 不在 Build Phases → Copy Bundle Resources 中

### 问题 2: URL Scheme 不生效

**检查清单**:
- ✅ URL Scheme 拼写正确
- ✅ 没有多余的空格
- ✅ 项目已重新构建
- ✅ `.onOpenURL` 在 EarthLordApp.swift 中已配置

### 问题 3: Google 登录后无法回调

**可能原因**:
- URL Scheme 配置错误
- Google Client ID 不匹配
- `.onOpenURL` 处理器未正确配置

**解决方案**:
1. 检查 URL Scheme 是否与 Client ID 匹配
2. 确认 EarthLordApp.swift 中的 `.onOpenURL` 配置
3. 查看控制台是否有 OAuth 回调日志

## 📚 相关文档

- [Google Sign-In iOS 文档](https://developers.google.com/identity/sign-in/ios)
- [Apple URL Scheme 文档](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Xcode Info.plist 配置](https://developer.apple.com/documentation/bundleresources/information_property_list)

## 🔗 项目相关文件

- **Google 登录实现**: `EarthLord/Services/AuthManager.swift`
- **OAuth 回调处理**: `EarthLord/EarthLordApp.swift`
- **Google 登录文档**: `GOOGLE_LOGIN_SETUP.md`

---

**重要提示**:
1. ✅ 已删除独立的 Info.plist 文件
2. ✅ 使用方法 1 在 Xcode 中直接配置（推荐）
3. ✅ 配置完成后重新构建项目

**状态**: 配置指南已创建
**最后更新**: 2025-12-30
