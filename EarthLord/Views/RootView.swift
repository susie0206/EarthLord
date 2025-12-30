//
//  RootView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/25.
//

import SwiftUI

/// 根视图：控制启动页、认证页与主界面的切换
struct RootView: View {
    /// 启动页是否完成
    @State private var splashFinished = false

    /// 认证管理器（从 App 传递）
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            if !splashFinished {
                // 启动页
                SplashView(authManager: authManager, isFinished: $splashFinished)
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                // 已认证：显示主应用
                MainTabView()
                    .transition(.opacity)
                    .environmentObject(authManager)
            } else {
                // 未认证：显示认证页面
                AuthView()
                    .transition(.opacity)
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager())
}
