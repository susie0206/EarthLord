//
//  LoginView.swift
//  EarthLord
//
//  Created by Claude Code on 2025/12/29.
//

import SwiftUI

/// 登录视图示例
/// 展示如何使用 AuthManager 进行用户认证
struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ApocalypseTheme.primary)
                    .padding(.bottom, 20)

                Text("地球新主")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // 邮箱输入
                TextField("邮箱", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                // 密码输入
                SecureField("密码", text: $password)
                    .textFieldStyle(.roundedBorder)

                // 错误消息
                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // 登录按钮
                Button {
                    Task {
                        await authManager.signIn(email: email, password: password)
                    }
                } label: {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(authManager.isLoading)

                // 注册链接
                NavigationLink(destination: RegisterView()) {
                    Text("还没有账号？立即注册")
                        .font(.footnote)
                        .foregroundColor(ApocalypseTheme.primary)
                }

                // 忘记密码
                NavigationLink(destination: ForgotPasswordView()) {
                    Text("忘记密码？")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 注册视图示例（占位符）
struct RegisterView: View {
    var body: some View {
        Text("注册页面")
            .navigationTitle("注册")
    }
}

/// 忘记密码视图示例（占位符）
struct ForgotPasswordView: View {
    var body: some View {
        Text("忘记密码页面")
            .navigationTitle("找回密码")
    }
}

#Preview {
    LoginView()
}
