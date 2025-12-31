# 语言切换功能使用指南 / Language Switching Guide

## 功能概述 / Overview

EarthLord App 现在支持 **App 内语言切换**，无需跟随系统语言设置。用户可以自由选择界面语言，切换后立即生效，无需重启应用。

The EarthLord App now supports **in-app language switching**, independent of system language settings. Users can freely choose their preferred interface language, with changes taking effect immediately without requiring an app restart.

---

## 支持的语言 / Supported Languages

1. **跟随系统 / Follow System**
   - 自动跟随设备系统语言设置
   - Automatically follows device system language settings

2. **简体中文**
   - 显示简体中文界面
   - Display Simplified Chinese interface

3. **English**
   - Display English interface
   - 显示英文界面

---

## 如何切换语言 / How to Switch Language

### 步骤 / Steps:

1. **打开应用 / Open the App**
   - 启动 EarthLord 应用
   - Launch the EarthLord app

2. **进入"更多"标签 / Go to "More" Tab**
   - 点击底部导航栏的"更多"（最右侧图标）
   - Tap "More" in the bottom navigation bar (rightmost icon)

3. **找到"设置"部分 / Find "Settings" Section**
   - 向下滚动找到"设置" Section
   - Scroll down to find the "Settings" section

4. **选择语言 / Select Language**
   - 当前语言会显示在"当前语言"下方
   - The current language is displayed under "Current Language"
   - 点击任一语言选项进行切换：
   - Tap any language option to switch:
     - 🌍 跟随系统 / Follow System
     - 🇨🇳 简体中文
     - 🇺🇸 English

5. **立即生效 / Immediate Effect**
   - 语言切换立即生效，无需重启应用
   - Language changes take effect immediately without restarting the app
   - 已选择的语言会显示勾选标记 ✓
   - Selected language shows a checkmark ✓

---

## 技术实现 / Technical Implementation

### 核心组件 / Core Components

#### 1. LanguageManager.swift
**位置 / Location**: `EarthLord/Services/LanguageManager.swift`

**功能 / Features**:
- 单例模式管理全局语言设置
- Singleton pattern for global language management
- 使用 `@Published` 属性触发 UI 更新
- Uses `@Published` property to trigger UI updates
- 通过 UserDefaults 持久化存储用户选择
- Persists user choice via UserDefaults
- 支持 xcstrings 格式的本地化文件
- Supports xcstrings localization format

**关键代码 / Key Code**:
```swift
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage

    func localizedString(forKey key: String) -> String {
        // 使用 String.LocalizationValue 和 locale 参数
        let locale = Locale(identifier: effectiveLanguageCode)
        let localizedValue = String.LocalizationValue(stringLiteral: key)
        return String(localized: localizedValue, locale: locale)
    }
}
```

#### 2. LocalizedText.swift
**位置 / Location**: `EarthLord/Components/LocalizedText.swift`

**功能 / Features**:
- 自定义 Text 视图包装器
- Custom Text view wrapper
- 监听语言变化通知并动态更新
- Listens to language change notifications and updates dynamically
- 支持带参数的本地化字符串
- Supports parameterized localized strings

**使用方法 / Usage**:
```swift
// 简单文本 / Simple text
LocalizedText("设置")

// 带参数的文本 / Text with parameters
LocalizedText("验证码已发送至 %@", email)
```

#### 3. MoreTabView.swift
**位置 / Location**: `EarthLord/Views/Tabs/MoreTabView.swift`

**功能 / Features**:
- 语言切换 UI 界面
- Language switching UI
- 显示当前选择的语言
- Displays currently selected language
- 提供三个语言选项供用户选择
- Provides three language options for user selection

---

## 开发者指南 / Developer Guide

### 在代码中使用本地化文本 / Using Localized Text in Code

#### ✅ 推荐方式 / Recommended Approach:

```swift
// 使用 LocalizedText 组件
LocalizedText("登录")
LocalizedText("验证码已发送至 %@", email)
```

#### ⚠️ 传统方式（不推荐）/ Traditional Approach (Not Recommended):

```swift
// 使用标准 Text 和 NSLocalizedString
Text(NSLocalizedString("登录", comment: ""))
```

**为什么？ / Why?**
- LocalizedText 会自动响应语言切换
- LocalizedText automatically responds to language changes
- 标准 Text 不会在语言切换时更新
- Standard Text won't update when language changes

### 添加新的本地化字符串 / Adding New Localized Strings

1. **打开 Localizable.xcstrings 文件**
   - Open the Localizable.xcstrings file

2. **添加新的 key**
   - Add a new key

3. **为每种语言提供翻译**
   - Provide translations for each language:
   ```json
   "新功能": {
       "localizations": {
           "en": {
               "stringUnit": {
                   "state": "translated",
                   "value": "New Feature"
               }
           }
       }
   }
   ```

4. **在代码中使用**
   - Use in code:
   ```swift
   LocalizedText("新功能")
   ```

---

## 数据持久化 / Data Persistence

用户的语言选择会自动保存到 **UserDefaults**，下次打开应用时会自动恢复上次的选择。

User language preference is automatically saved to **UserDefaults** and will be restored when the app is opened next time.

**存储键 / Storage Key**: `app_language_preference`

---

## 调试日志 / Debug Logs

语言切换功能包含详细的中文调试日志，方便开发者调试：

The language switching feature includes detailed Chinese debug logs for developers:

```
🌍 [语言管理] 加载已保存的语言设置: 简体中文
🌍 [语言切换] 用户选择: English
🌍 [语言切换] 语言已更改为: English
```

---

## 系统要求 / System Requirements

- **iOS 16.0+**
- **Swift 5.9+**
- **Xcode 15.0+**

---

## 文件列表 / File List

### 新增文件 / New Files:
1. `EarthLord/Services/LanguageManager.swift` - 语言管理服务
2. `EarthLord/Components/LocalizedText.swift` - 自定义本地化文本组件

### 修改文件 / Modified Files:
1. `EarthLord/Views/Tabs/MoreTabView.swift` - 添加语言切换 UI
2. `Localizable.xcstrings` - 包含所有翻译

---

## 常见问题 / FAQ

### Q1: 切换语言后，部分文本没有更新？
**A**: 确保使用 `LocalizedText` 组件而不是标准的 `Text` 组件。

### Q1: Some text doesn't update after language switch?
**A**: Make sure to use the `LocalizedText` component instead of the standard `Text` component.

---

### Q2: 如何添加更多语言？
**A**:
1. 在 `AppLanguage` 枚举中添加新语言
2. 在 `Localizable.xcstrings` 中添加对应的翻译
3. 更新 `effectiveLanguageCode` 逻辑

### Q2: How to add more languages?
**A**:
1. Add new language to `AppLanguage` enum
2. Add corresponding translations in `Localizable.xcstrings`
3. Update `effectiveLanguageCode` logic

---

### Q3: 语言设置会在卸载应用后保留吗？
**A**: 不会，UserDefaults 会在卸载应用时清除。重新安装后会恢复为默认的"跟随系统"设置。

### Q3: Will language settings persist after uninstalling the app?
**A**: No, UserDefaults are cleared when the app is uninstalled. After reinstalling, it will revert to the default "Follow System" setting.

---

## 性能优化建议 / Performance Optimization Recommendations

1. **避免过度使用 LocalizedText**
   - 对于固定不变的文本（如品牌名），使用标准 Text
   - For fixed text (like brand names), use standard Text

2. **缓存本地化字符串**
   - 如果同一字符串在列表中多次出现，考虑缓存结果
   - If the same string appears multiple times in a list, consider caching the result

3. **减少通知订阅**
   - LocalizedText 已经优化了通知订阅，避免重复订阅
   - LocalizedText has optimized notification subscriptions to avoid duplicates

---

## 未来计划 / Future Plans

- [ ] 支持更多语言（繁体中文、日语、韩语等）
- [ ] 支持从服务器动态加载翻译
- [ ] 支持用户自定义翻译贡献
- [ ] 添加语言切换动画效果

- [ ] Support more languages (Traditional Chinese, Japanese, Korean, etc.)
- [ ] Support dynamic loading of translations from server
- [ ] Support user-contributed translations
- [ ] Add language switch animation effects

---

**最后更新 / Last Updated**: 2025-12-31

**文档版本 / Document Version**: 1.0.0
