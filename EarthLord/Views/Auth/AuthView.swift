//
//  AuthView.swift
//  EarthLord
//
//  Created by Claude Code on 2025/12/29.
//

import SwiftUI

/// 认证主视图
/// 包含登录、注册、忘记密码等完整认证流程
struct AuthView: View {
    /// 认证管理器（从父视图传递）
    @EnvironmentObject var authManager: AuthManager

    // Tab 状态
    @State private var selectedTab = 0 // 0: 登录, 1: 注册

    // 登录状态
    @State private var loginEmail = ""
    @State private var loginPassword = ""

    // 注册状态
    @State private var registerEmail = ""
    @State private var registerOTP = ""
    @State private var registerPassword = ""
    @State private var registerConfirmPassword = ""
    @State private var registerStep = 1 // 1: 邮箱, 2: 验证码, 3: 设置密码

    // 忘记密码状态
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var resetOTP = ""
    @State private var resetPassword = ""
    @State private var resetConfirmPassword = ""
    @State private var resetStep = 1

    // 验证码倒计时
    @State private var otpCountdown = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    ApocalypseTheme.background,
                    ApocalypseTheme.cardBackground,
                    ApocalypseTheme.background
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Logo 和标题
                    VStack(spacing: 16) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 80))
                            .foregroundColor(ApocalypseTheme.primary)
                            .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 10)

                        Text("地球新主")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(ApocalypseTheme.textPrimary)

                        Text("EarthLord")
                            .font(.system(size: 16))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)

                    // Tab 切换
                    Picker("", selection: $selectedTab) {
                        Text("登录").tag(0)
                        Text("注册").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTab) { _ in
                        // 切换 Tab 时清除错误
                        authManager.clearError()
                    }

                    // 内容区域
                    if selectedTab == 0 {
                        loginContent
                    } else {
                        registerContent
                    }

                    // 分隔线
                    HStack {
                        Rectangle()
                            .fill(ApocalypseTheme.textMuted)
                            .frame(height: 1)

                        Text("或者使用以下方式登录")
                            .font(.caption)
                            .foregroundColor(ApocalypseTheme.textSecondary)
                            .padding(.horizontal, 8)

                        Rectangle()
                            .fill(ApocalypseTheme.textMuted)
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // 第三方登录按钮
                    thirdPartyButtons

                    Spacer(minLength: 40)
                }
            }

            // 忘记密码弹窗
            if showForgotPassword {
                forgotPasswordSheet
            }
        }
        .alert("提示", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("确定") {
                authManager.clearError()
            }
        } message: {
            if let error = authManager.errorMessage {
                Text(error)
            }
        }
    }

    // MARK: - 登录内容

    private var loginContent: some View {
        VStack(spacing: 16) {
            // 邮箱输入
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("请输入邮箱", text: $loginEmail)
                    .textFieldStyle(AuthTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            // 密码输入
            VStack(alignment: .leading, spacing: 8) {
                Text("密码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                SecureField("请输入密码", text: $loginPassword)
                    .textFieldStyle(AuthTextFieldStyle())
            }

            // 忘记密码链接
            HStack {
                Spacer()
                Button {
                    showForgotPassword = true
                } label: {
                    Text("忘记密码？")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            // 登录按钮
            Button {
                Task {
                    await authManager.signIn(email: loginEmail, password: loginPassword)
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("登录")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || loginEmail.isEmpty || loginPassword.isEmpty)
            .opacity((authManager.isLoading || loginEmail.isEmpty || loginPassword.isEmpty) ? 0.6 : 1.0)
        }
        .padding(.horizontal)
    }

    // MARK: - 注册内容

    private var registerContent: some View {
        VStack(spacing: 16) {
            // 根据注册步骤和状态显示不同内容
            if registerStep == 1 {
                registerStep1
            } else if registerStep == 2 || (authManager.otpSent && !authManager.otpVerified) {
                registerStep2
            } else if registerStep == 3 || (authManager.otpVerified && authManager.needsPasswordSetup) {
                registerStep3
            }
        }
        .padding(.horizontal)
        .onChange(of: authManager.otpSent) { sent in
            if sent {
                registerStep = 2
                startCountdown()
            }
        }
        .onChange(of: authManager.otpVerified) { verified in
            if verified {
                registerStep = 3
            }
        }
        .onChange(of: authManager.isAuthenticated) { authenticated in
            if authenticated {
                // 认证成功，重置注册状态
                registerStep = 1
                registerEmail = ""
                registerOTP = ""
                registerPassword = ""
                registerConfirmPassword = ""
                authManager.resetOTPState()
            }
        }
    }

    // 注册第一步：输入邮箱
    private var registerStep1: some View {
        VStack(spacing: 16) {
            // 步骤指示
            stepIndicator(currentStep: 1)

            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("请输入邮箱", text: $registerEmail)
                    .textFieldStyle(AuthTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Button {
                Task {
                    await authManager.sendRegisterOTP(email: registerEmail)
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("发送验证码")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || !isValidEmail(registerEmail))
            .opacity((authManager.isLoading || !isValidEmail(registerEmail)) ? 0.6 : 1.0)
        }
    }

    // 注册第二步：验证验证码
    private var registerStep2: some View {
        VStack(spacing: 16) {
            // 步骤指示
            stepIndicator(currentStep: 2)

            Text("验证码已发送至 \(registerEmail)")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("验证码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("请输入 6 位验证码", text: $registerOTP)
                    .textFieldStyle(AuthTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onChange(of: registerOTP) { newValue in
                        // 限制只能输入数字，最多6位
                        registerOTP = String(newValue.filter { $0.isNumber }.prefix(6))
                    }
            }

            // 重发倒计时
            if otpCountdown > 0 {
                Text("重新发送 (\(otpCountdown)s)")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            } else {
                Button {
                    Task {
                        authManager.resetOTPState()
                        await authManager.sendRegisterOTP(email: registerEmail)
                    }
                } label: {
                    Text("重新发送验证码")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            Button {
                Task {
                    await authManager.verifyRegisterOTP(email: registerEmail, code: registerOTP)
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("验证")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || registerOTP.count != 6)
            .opacity((authManager.isLoading || registerOTP.count != 6) ? 0.6 : 1.0)
        }
    }

    // 注册第三步：设置密码
    private var registerStep3: some View {
        VStack(spacing: 16) {
            // 步骤指示
            stepIndicator(currentStep: 3)

            Text("验证成功！请设置您的密码")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.success)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("设置密码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                SecureField("至少 8 位，包含字母和数字", text: $registerPassword)
                    .textFieldStyle(AuthTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("确认密码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                SecureField("再次输入密码", text: $registerConfirmPassword)
                    .textFieldStyle(AuthTextFieldStyle())
            }

            // 密码强度提示
            if !registerPassword.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: registerPassword.count >= 8 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(registerPassword.count >= 8 ? ApocalypseTheme.success : ApocalypseTheme.textMuted)
                    Text("至少 8 位字符")
                        .font(.caption2)
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }

            Button {
                Task {
                    if registerPassword == registerConfirmPassword {
                        await authManager.completeRegistration(password: registerPassword)
                    } else {
                        authManager.errorMessage = "两次输入的密码不一致"
                    }
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("完成注册")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || !isPasswordValid())
            .opacity((authManager.isLoading || !isPasswordValid()) ? 0.6 : 1.0)
        }
    }

    // MARK: - 忘记密码弹窗

    private var forgotPasswordSheet: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showForgotPassword = false
                    resetStep = 1
                    authManager.resetOTPState()
                }

            // 弹窗内容
            VStack(spacing: 20) {
                HStack {
                    Text("找回密码")
                        .font(.headline)
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Spacer()

                    Button {
                        showForgotPassword = false
                        resetStep = 1
                        authManager.resetOTPState()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ApocalypseTheme.textMuted)
                            .font(.title3)
                    }
                }

                if resetStep == 1 {
                    resetPasswordStep1
                } else if resetStep == 2 {
                    resetPasswordStep2
                } else if resetStep == 3 {
                    resetPasswordStep3
                }
            }
            .padding(24)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 30)
        }
        .onChange(of: authManager.otpSent) { sent in
            if sent && showForgotPassword {
                resetStep = 2
                startCountdown()
            }
        }
        .onChange(of: authManager.otpVerified) { verified in
            if verified && showForgotPassword {
                resetStep = 3
            }
        }
        .onChange(of: authManager.isAuthenticated) { authenticated in
            if authenticated && showForgotPassword {
                // 密码重置成功，关闭弹窗并重置状态
                showForgotPassword = false
                resetStep = 1
                resetEmail = ""
                resetOTP = ""
                resetPassword = ""
                resetConfirmPassword = ""
                authManager.resetOTPState()
            }
        }
    }

    // 重置密码第一步
    private var resetPasswordStep1: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("请输入注册邮箱", text: $resetEmail)
                    .textFieldStyle(AuthTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Button {
                Task {
                    await authManager.sendResetOTP(email: resetEmail)
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("发送验证码")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || !isValidEmail(resetEmail))
            .opacity((authManager.isLoading || !isValidEmail(resetEmail)) ? 0.6 : 1.0)
        }
    }

    // 重置密码第二步
    private var resetPasswordStep2: some View {
        VStack(spacing: 16) {
            Text("验证码已发送至 \(resetEmail)")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("验证码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                TextField("请输入 6 位验证码", text: $resetOTP)
                    .textFieldStyle(AuthTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onChange(of: resetOTP) { newValue in
                        resetOTP = String(newValue.filter { $0.isNumber }.prefix(6))
                    }
            }

            if otpCountdown > 0 {
                Text("重新发送 (\(otpCountdown)s)")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textMuted)
            } else {
                Button {
                    Task {
                        authManager.resetOTPState()
                        await authManager.sendResetOTP(email: resetEmail)
                    }
                } label: {
                    Text("重新发送验证码")
                        .font(.caption)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            }

            Button {
                Task {
                    await authManager.verifyResetOTP(email: resetEmail, code: resetOTP)
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("验证")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || resetOTP.count != 6)
            .opacity((authManager.isLoading || resetOTP.count != 6) ? 0.6 : 1.0)
        }
    }

    // 重置密码第三步
    private var resetPasswordStep3: some View {
        VStack(spacing: 16) {
            Text("验证成功！请设置新密码")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.success)

            VStack(alignment: .leading, spacing: 8) {
                Text("新密码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                SecureField("至少 8 位，包含字母和数字", text: $resetPassword)
                    .textFieldStyle(AuthTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("确认密码")
                    .font(.caption)
                    .foregroundColor(ApocalypseTheme.textSecondary)

                SecureField("再次输入密码", text: $resetConfirmPassword)
                    .textFieldStyle(AuthTextFieldStyle())
            }

            Button {
                Task {
                    if resetPassword == resetConfirmPassword {
                        await authManager.resetPassword(newPassword: resetPassword)
                        if authManager.isAuthenticated {
                            showForgotPassword = false
                        }
                    } else {
                        authManager.errorMessage = "两次输入的密码不一致"
                    }
                }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("重置密码")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ApocalypseTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authManager.isLoading || resetPassword.count < 8 || resetPassword != resetConfirmPassword)
            .opacity((authManager.isLoading || resetPassword.count < 8 || resetPassword != resetConfirmPassword) ? 0.6 : 1.0)
        }
    }

    // MARK: - 第三方登录按钮

    private var thirdPartyButtons: some View {
        VStack(spacing: 12) {
            // Apple 登录
            Button {
                showComingSoonToast(provider: "Apple")
            } label: {
                HStack {
                    Image(systemName: "apple.logo")
                        .font(.title3)
                    Text("使用 Apple 登录")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            // Google 登录
            Button {
                showComingSoonToast(provider: "Google")
            } label: {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title3)
                    Text("使用 Google 登录")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 辅助视图

    // 步骤指示器
    private func stepIndicator(currentStep: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? ApocalypseTheme.primary : ApocalypseTheme.textMuted)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - 辅助方法

    // 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // 验证密码
    private func isPasswordValid() -> Bool {
        return registerPassword.count >= 8 &&
               registerPassword == registerConfirmPassword
    }

    // 开始倒计时
    private func startCountdown() {
        otpCountdown = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if otpCountdown > 0 {
                otpCountdown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    // 显示"即将开放" Toast
    private func showComingSoonToast(provider: String) {
        authManager.errorMessage = "\(provider) 登录功能即将开放"
    }
}

// MARK: - 自定义文本框样式

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ApocalypseTheme.cardBackground)
            .foregroundColor(ApocalypseTheme.textPrimary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ApocalypseTheme.textMuted.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
