//
//  LanguageManager.swift
//  EarthLord
//
//  Created by Claude on 2025-12-31.
//

import Foundation
import SwiftUI
import Combine

/// 语言管理器 - 处理 App 内语言切换
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// 当前选择的语言（用于触发 UI 更新）
    @Published var currentLanguage: AppLanguage {
        didSet {
            print("🌍 [语言切换] 语言已更改为: \(currentLanguage.displayName)")
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)

            // 通知所有观察者语言已更改
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    private let userDefaultsKey = "app_language_preference"

    private init() {
        // 从 UserDefaults 读取用户选择
        if let savedLanguage = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
            print("🌍 [语言管理] 加载已保存的语言设置: \(language.displayName)")
        } else {
            self.currentLanguage = .system
            print("🌍 [语言管理] 使用默认语言设置: 跟随系统")
        }
    }

    /// 获取实际使用的语言代码（考虑系统语言）
    var effectiveLanguageCode: String {
        switch currentLanguage {
        case .system:
            // 跟随系统语言
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("zh") {
                return "zh-Hans"
            } else {
                return "en"
            }
        case .chinese:
            return "zh-Hans"
        case .english:
            return "en"
        }
    }

    /// 获取本地化字符串
    func localizedString(forKey key: String) -> String {
        let languageCode = effectiveLanguageCode

        print("🌍 [本地化] 查找 key='\(key)', languageCode='\(languageCode)'")

        // 对于源语言（中文），直接返回 key
        if languageCode == "zh-Hans" {
            print("✅ [本地化] 使用源语言（中文）: '\(key)'")
            return key
        }

        // 对于其他语言，从 lproj bundle 中读取
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)

            // 如果找到翻译且不等于 key（表示确实有翻译）
            if localizedString != key {
                print("✅ [本地化] 找到 \(languageCode) 翻译: '\(localizedString)'")
                return localizedString
            } else {
                print("⚠️ [本地化] \(languageCode) 没有此 key 的翻译，返回原始 key")
                return key
            }
        }

        // 如果找不到 lproj bundle，返回 key（中文）
        print("⚠️ [本地化] 未找到 \(languageCode).lproj，使用原始 key: '\(key)'")
        return key
    }
}

/// App 支持的语言选项
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"      // 跟随系统
    case chinese = "zh-Hans"    // 简体中文
    case english = "en"         // English

    var id: String { rawValue }

    /// 显示名称（使用对应语言显示）
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统 / Follow System"
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }

    /// 图标
    var icon: String {
        switch self {
        case .system:
            return "globe"
        case .chinese:
            return "flag.fill"  // 🇨🇳
        case .english:
            return "flag.fill"  // 🇺🇸
        }
    }
}

/// 语言变更通知
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

/// SwiftUI 环境值扩展 - 注入 LanguageManager
struct LanguageManagerKey: EnvironmentKey {
    static let defaultValue = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}
