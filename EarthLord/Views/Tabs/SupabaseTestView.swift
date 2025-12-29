//
//  SupabaseTestView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/26.
//

import SwiftUI
import Supabase

// 在 View 外部定义 SupabaseClient 实例
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://absexnnamqwkqedaaamt.supabase.co")!,
    supabaseKey: "sb_publishable_-jUhdtSZdLOBoDMNfIZXZA_5E-UTaU5"
)

struct SupabaseTestView: View {
    @State private var isConnected: Bool? = nil
    @State private var debugLog: String = "点击按钮开始测试连接..."
    @State private var isTesting: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 状态图标
                statusIcon

                // 调试日志文本框
                ScrollView {
                    Text(debugLog)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)

                // 测试连接按钮
                Button(action: testConnection) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wifi")
                        }
                        Text(isTesting ? "测试中..." : "测试连接")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTesting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isTesting)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Supabase 连接测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // 状态图标视图
    private var statusIcon: some View {
        Group {
            if let connected = isConnected {
                if connected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 40)
    }

    // 测试连接函数
    private func testConnection() {
        isTesting = true
        debugLog = "开始测试连接...\n"
        debugLog += "URL: https://absexnnamqwkqedaaamt.supabase.co\n"
        debugLog += "尝试查询不存在的表...\n\n"

        Task {
            do {
                // 使用 v2.0 语法：故意查询一个不存在的表
                _ = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()

                // 如果没有抛出错误（不太可能），说明表存在
                await MainActor.run {
                    isConnected = true
                    debugLog += "✅ 意外情况：表存在或查询成功\n"
                    isTesting = false
                }

            } catch {
                await MainActor.run {
                    analyzeError(error)
                    isTesting = false
                }
            }
        }
    }

    // 分析错误类型
    private func analyzeError(_ error: Error) {
        let errorString = error.localizedDescription
        let errorDebug = String(describing: error)

        debugLog += "收到错误响应：\n"
        debugLog += "错误信息: \(errorString)\n"
        debugLog += "详细信息: \(errorDebug)\n\n"

        // 判断错误类型
        if errorDebug.contains("PGRST") ||
           errorDebug.contains("PGRST205") ||
           errorString.contains("Could not find the table") ||
           errorDebug.contains("relation") && errorDebug.contains("does not exist") {
            // 这些错误说明成功连接到 Supabase，只是表不存在
            isConnected = true
            debugLog += "✅ 连接成功（服务器已响应）\n"
            debugLog += "说明：收到来自 PostgreSQL 的错误响应，证明已成功连接到 Supabase 服务器。\n"

        } else if errorString.contains("hostname") ||
                  errorString.contains("URL") ||
                  errorDebug.contains("NSURLErrorDomain") {
            // URL 错误或网络错误
            isConnected = false
            debugLog += "❌ 连接失败：URL 错误或无网络\n"
            debugLog += "请检查：\n"
            debugLog += "1. 网络连接是否正常\n"
            debugLog += "2. Supabase URL 是否正确\n"
            debugLog += "3. 是否有防火墙或代理限制\n"

        } else {
            // 其他未知错误
            isConnected = false
            debugLog += "❌ 连接失败：未知错误\n"
            debugLog += "完整错误：\(errorDebug)\n"
        }
    }
}

#Preview {
    SupabaseTestView()
}
