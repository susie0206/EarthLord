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
                        .padding(.bottom, 40)

                    Spacer(minLength: 0)
                }
            }
            .background(ApocalypseTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("幸存者档案")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            }
        }
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
            Text(authManager.currentUser?.username ?? "未知幸存者")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 邮箱
            HStack(spacing: 6) {
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Text(authManager.currentUser?.email ?? "无邮箱")
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            // 登录状态
            HStack(spacing: 6) {
                Circle()
                    .fill(authManager.isAuthenticated ? ApocalypseTheme.success : ApocalypseTheme.textMuted)
                    .frame(width: 8, height: 8)

                Text(authManager.isAuthenticated ? "在线" : "离线")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            // 注册时间
            if let createdAt = authManager.currentUser?.createdAt {
                Text("加入时间：\(formatDate(createdAt))")
                    .font(.caption2)
                    .foregroundColor(ApocalypseTheme.textMuted)
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
            Text("幸存者数据")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                statisticCard(
                    icon: "map.fill",
                    title: "领地",
                    value: "0",
                    color: ApocalypseTheme.primary
                )

                statisticCard(
                    icon: "location.fill",
                    title: "探索点",
                    value: "0",
                    color: .blue
                )

                statisticCard(
                    icon: "cube.box.fill",
                    title: "资源",
                    value: "0",
                    color: .green
                )
            }
        }
    }

    // 统计卡片
    private func statisticCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text(title)
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
            Text("设置")
                .font(.headline)
                .foregroundColor(ApocalypseTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                functionRow(
                    icon: "person.fill",
                    title: "编辑资料",
                    iconColor: .blue
                )

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 16)

                functionRow(
                    icon: "bell.fill",
                    title: "通知设置",
                    iconColor: .orange
                )

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 16)

                functionRow(
                    icon: "shield.fill",
                    title: "隐私设置",
                    iconColor: .green
                )

                Divider()
                    .background(ApocalypseTheme.textMuted.opacity(0.3))
                    .padding(.horizontal, 16)

                functionRow(
                    icon: "questionmark.circle.fill",
                    title: "帮助与反馈",
                    iconColor: .purple
                )
            }
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
        }
    }

    // 功能行
    private func functionRow(icon: String, title: String, iconColor: Color) -> some View {
        Button {
            // TODO: 实现对应功能
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                Text(title)
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

                Text("退出登录")
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

    // MARK: - 辅助方法

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager())
}
