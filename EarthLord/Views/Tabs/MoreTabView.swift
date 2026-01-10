//
//  MoreTabView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/25.
//

import SwiftUI

struct MoreTabView: View {
    /// 认证管理器
    @EnvironmentObject var authManager: AuthManager
    /// 语言管理器
    @ObservedObject var languageManager = LanguageManager.shared
    /// 导航标题
    @State private var navigationTitle: String = ""
    /// 当前语言文本
    @State private var currentLanguageText: String = ""

    var body: some View {
        NavigationView {
            List {
                // 用户信息区域
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(ApocalypseTheme.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.currentUser?.username ?? "未知用户")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(authManager.currentUser?.email ?? "无邮箱")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(authManager.isAuthenticated ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)

                                    if authManager.isAuthenticated {
                                        LocalizedText("已登录")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        LocalizedText("未登录")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            Spacer()
                        }

                        // 登出按钮
                        Button {
                            Task {
                                await authManager.signOut()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                LocalizedText("登出")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(ApocalypseTheme.danger.opacity(0.1))
                            .foregroundColor(ApocalypseTheme.danger)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    LocalizedText("账户信息")
                }

                Section {
                    NavigationLink(destination: SupabaseTestView()) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                LocalizedText("Supabase 连接测试")
                                    .font(.body)
                                LocalizedText("测试数据库连接状态")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    NavigationLink(destination: TerritoryLoggerView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.orange)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("圈地日志")
                                    .font(.body)
                                Text("查看圈地调试日志")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    LocalizedText("开发工具")
                }

                // 设置 Section
                Section {
                    // 语言设置
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(ApocalypseTheme.primary)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                LocalizedText("设置")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                HStack(spacing: 4) {
                                    Text(currentLanguageText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }

                        // 语言选择器
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                print("🌍 [语言切换] 用户选择: \(language.displayName)")
                                withAnimation {
                                    languageManager.currentLanguage = language
                                }
                            } label: {
                                HStack {
                                    Image(systemName: language.icon)
                                        .foregroundColor(languageManager.currentLanguage == language ? ApocalypseTheme.primary : .secondary)
                                        .frame(width: 24)

                                    Text(language.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if languageManager.currentLanguage == language {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ApocalypseTheme.primary)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    languageManager.currentLanguage == language
                                        ? ApocalypseTheme.primary.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    LocalizedText("设置")
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            LocalizedText("更多功能")
                                .font(.headline)
                            LocalizedText("即将推出")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                } header: {
                    LocalizedText("其他功能")
                }
            }
            .navigationTitle(navigationTitle)
            .onAppear {
                updateAllLocalizedTexts()
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                updateAllLocalizedTexts()
            }
        }
    }

    private func updateAllLocalizedTexts() {
        navigationTitle = languageManager.localizedString(forKey: "更多")

        let prefix = languageManager.localizedString(forKey: "当前语言: %@")
        let languageName = languageManager.currentLanguage.displayName
        currentLanguageText = prefix.replacingOccurrences(of: "%@", with: languageName)

        print("🌍 [MoreTabView] 更新文本: navigationTitle='\(navigationTitle)', currentLanguageText='\(currentLanguageText)'")
    }
}

#Preview {
    MoreTabView()
}
