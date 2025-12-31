//
//  ProfileTabView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/25.
//

import SwiftUI

struct ProfileTabView: View {
    /// 认证管理器
    @EnvironmentObject var authManager: AuthManager
    /// 语言管理器
    @ObservedObject var languageManager = LanguageManager.shared

    /// 是否显示删除账户确认对话框
    @State private var showDeleteConfirmation = false

    /// 用户输入的确认文本
    @State private var deleteConfirmationText = ""
    /// 导航标题
    @State private var navigationTitle: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部背景
                    headerBackground

                    // 用户信息卡片
                    userInfoCard
                        .padding(.horizontal, 20)
                        .offset(y: -60)
                        .id(languageManager.currentLanguage)

                    // 统计信息
                    statisticsSection
                        .padding(.horizontal, 20)
                        .offset(y: -40)

                    // 功能区域
                    functionsSection
                        .padding(.horizontal, 20)
                        .offset(y: -20)

                    // 退出登录按钮
                    logoutButton
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    // 删除账户按钮（危险操作）
                    deleteAccountButton
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)

                    Spacer(minLength: 0)
                }
            }
            .background(ApocalypseTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(navigationTitle)
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
            .onAppear {
                updateLocalizedTexts()
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                updateLocalizedTexts()
            }
        }
    }

    private func updateLocalizedTexts() {
        navigationTitle = languageManager.localizedString(forKey: "幸存者档案")
    }

    // MARK: - 头部背景

    private var headerBackground: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    ApocalypseTheme.primary,
                    ApocalypseTheme.primary.opacity(0.7),
                    ApocalypseTheme.background
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)

            // 装饰图案
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 100))
                .foregroundColor(.white.opacity(0.1))
                .offset(x: 80, y: -20)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - 用户信息卡片

    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ApocalypseTheme.primary,
                                ApocalypseTheme.primary.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 10)

                if let avatarUrl = authManager.currentUser?.avatarUrl, !avatarUrl.isEmpty {
                    // TODO: 加载远程头像
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        defaultAvatarIcon
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    defaultAvatarIcon
                }
            }

            // 用户名
            Text(authManager.currentUser?.username ?? languageManager.localizedString(forKey: "未知幸存者"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 邮箱
            if let email = authManager.currentUser?.email, !email.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    LocalizedText("无邮箱")
                        .font(.subheadline)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            // 登录状态
            HStack(spacing: 6) {
                Circle()
                    .fill(authManager.isAuthenticated ? ApocalypseTheme.success : ApocalypseTheme.textMuted)
                    .frame(width: 8, height: 8)

                if authManager.isAuthenticated {
                    LocalizedText("在线")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                } else {
                    LocalizedText("离线")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            // 注册时间
            if let createdAt = authManager.currentUser?.createdAt {
                HStack(spacing: 0) {
                    LocalizedText("加入时间：%@", formatDate(createdAt))
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    // 默认头像图标
    private var defaultAvatarIcon: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(.white)
    }

    // MARK: - 统计信息

    private var statisticsSection: some View {
        VStack(spacing: 16) {
            LocalizedText("幸存者数据")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                statisticCard(
                    icon: "map.fill",
                    titleKey: "领地",
                    value: "0",
                    color: ApocalypseTheme.primary
                )

                statisticCard(
                    icon: "location.fill",
                    titleKey: "探索点",
                    value: "0",
                    color: .blue
                )

                statisticCard(
                    icon: "cube.box.fill",
                    titleKey: "资源",
                    value: "0",
                    color: .green
                )
            }
        }
    }

    // 统计卡片
    private func statisticCard(icon: String, titleKey: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            LocalizedText(titleKey)
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - 功能区域

    private var functionsSection: some View {
        VStack(spacing: 12) {
            LocalizedText("设置")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                functionRow(
                    icon: "person.fill",
                    titleKey: "编辑资料",
                    iconColor: .blue
                )

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 16)

                functionRow(
                    icon: "bell.fill",
                    titleKey: "通知设置",
                    iconColor: .orange
                )

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 16)

                functionRow(
                    icon: "shield.fill",
                    titleKey: "隐私设置",
                    iconColor: .green
                )

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 16)

                functionRow(
                    icon: "questionmark.circle.fill",
                    titleKey: "帮助与反馈",
                    iconColor: .purple
                )
            }
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
    }

    // 功能行
    private func functionRow(icon: String, titleKey: String, iconColor: Color) -> some View {
        Button {
            // TODO: 实现对应功能
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                LocalizedText(titleKey)
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 退出登录按钮

    private var logoutButton: some View {
        Button {
            Task {
                await authManager.signOut()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))

                LocalizedText("退出登录")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ApocalypseTheme.danger.opacity(0.1))
            .foregroundColor(ApocalypseTheme.danger)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ApocalypseTheme.danger.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - 删除账户按钮

    private var deleteAccountButton: some View {
        VStack(spacing: 12) {
            // 警告文本
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                LocalizedText("删除账户后，所有数据将被永久删除且无法恢复")
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .padding(.horizontal, 16)

            // 删除账户按钮
            Button {
                print("🔵 [UI] 用户点击了删除账户按钮")
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))

                    LocalizedText("删除账户")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .alert(LocalizedStringKey("删除账户"), isPresented: $showDeleteConfirmation) {
            // 输入框
            TextField(LocalizedStringKey("请输入\"删除\"以确认"), text: $deleteConfirmationText)
                .textInputAutocapitalization(.never)

            // 确认删除按钮
            Button(LocalizedStringKey("确认删除"), role: .destructive) {
                print("🔵 [UI] 用户确认删除账户")
                print("   用户输入的确认文本: '\(deleteConfirmationText)'")

                if deleteConfirmationText == "删除" {
                    print("✅ [UI] 确认文本匹配，开始删除账户")
                    Task {
                        await authManager.deleteAccount()
                        // 清空输入框
                        deleteConfirmationText = ""
                    }
                } else {
                    print("❌ [UI] 确认文本不匹配，取消删除")
                    print("   期望: '删除'")
                    print("   实际: '\(deleteConfirmationText)'")
                    authManager.errorMessage = "输入的文本不正确，请输入\"删除\"来确认"
                    deleteConfirmationText = ""
                }
            }
            .disabled(deleteConfirmationText != "删除")

            // 取消按钮
            Button(LocalizedStringKey("取消"), role: .cancel) {
                print("🔵 [UI] 用户取消了删除账户")
                deleteConfirmationText = ""
            }
        } message: {
            Text(LocalizedStringKey("⚠️ 此操作不可逆！\n\n删除后，您的所有领地、资源和探索记录都将永久丢失。\n\n请输入\"删除\"来确认此操作。"))
        }
    }

    // MARK: - 辅助方法

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        // 根据当前语言选择日期格式
        let languageCode = languageManager.effectiveLanguageCode
        if languageCode == "zh-Hans" {
            formatter.dateFormat = "yyyy年MM月dd日"
            formatter.locale = Locale(identifier: "zh_CN")
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            formatter.locale = Locale(identifier: "en_US")
        }

        return formatter.string(from: date)
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager())
}
