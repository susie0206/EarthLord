//
//  EarthLordApp.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/23.
//

import SwiftUI
import SwiftData

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
        }
        .modelContainer(sharedModelContainer)
    }
}
