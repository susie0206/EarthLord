//
//  EarthLordApp.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/23.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct EarthLordApp: App {
    /// 认证管理器（应用级别的单例）
    @StateObject private var authManager = AuthManager()

    /// SwiftData 模型容器
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    // 处理 Google OAuth 回调
                    print("🔵 [OAuth回调] 收到 URL: \(url.absoluteString)")

                    // 检查是否是 Google Sign-In 的回调
                    if url.scheme == "com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd" {
                        print("✅ [OAuth回调] 识别为 Google Sign-In 回调")
                        GIDSignIn.sharedInstance.handle(url)
                    } else {
                        print("⚠️ [OAuth回调] 未知的 URL Scheme: \(url.scheme ?? "无")")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
