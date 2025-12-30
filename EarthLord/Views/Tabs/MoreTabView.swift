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
                                    .foregroundColor(ApocalypseTheme.textPrimary)

                                Text(authManager.currentUser?.email ?? "无邮箱")
                                    .font(.caption)
                                    .foregroundColor(ApocalypseTheme.textSecondary)

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(authManager.isAuthenticated ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)

                                    Text(authManager.isAuthenticated ? "已登录" : "未登录")
                                        .font(.caption2)
                                        .foregroundColor(ApocalypseTheme.textSecondary)
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
                                Text("登出")
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
                    Text("账户信息")
                }

                Section {
                    NavigationLink(destination: SupabaseTestView()) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Supabase 连接测试")
                                    .font(.body)
                                Text("测试数据库连接状态")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("开发工具")
                }

                Section {
                    PlaceholderView(
                        icon: "ellipsis",
                        title: "更多功能",
                        subtitle: "即将推出"
                    )
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("其他功能")
                }
            }
            .navigationTitle("更多")
        }
    }
}

#Preview {
    MoreTabView()
}
