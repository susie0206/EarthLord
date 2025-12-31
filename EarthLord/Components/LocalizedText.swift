//
//  LocalizedText.swift
//  EarthLord
//
//  Created by Claude on 2025-12-31.
//

import SwiftUI

/// 支持动态语言切换的本地化文本组件
struct LocalizedText: View {
    let key: String
    let arguments: [CVarArg]

    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var localizedString: String = ""

    /// 初始化（无参数）
    init(_ key: String) {
        self.key = key
        self.arguments = []
    }

    /// 初始化（带参数）
    init(_ key: String, _ arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }

    var body: some View {
        Text(localizedString)
            .onAppear {
                updateLocalizedString()
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                updateLocalizedString()
            }
    }

    private func updateLocalizedString() {
        let baseString = languageManager.localizedString(forKey: key)

        // 如果有参数，使用 String(format:) 格式化
        if !arguments.isEmpty {
            localizedString = String(format: baseString, arguments: arguments)
        } else {
            localizedString = baseString
        }
    }
}

/// 扩展 View，提供便捷的本地化文本修饰符
extension View {
    /// 使用 LocalizedText 替换标准 Text
    func localizedText(_ key: String) -> some View {
        LocalizedText(key)
    }
}
