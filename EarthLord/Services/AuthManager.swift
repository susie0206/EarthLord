//
//  AuthManager.swift
//  EarthLord
//
//  Created by Claude Code on 2025/12/29.
//

import Foundation
import Combine
import Supabase

/// 认证管理器
/// 负责处理用户注册、登录、密码重置等认证流程
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    /// 用户是否已完全认证（已登录且完成所有必要流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP 验证后的中间状态）
    @Published var needsPasswordSetup: Bool = false

    /// 当前登录用户
    @Published var currentUser: User?

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误消息
    @Published var errorMessage: String?

    /// OTP 是否已发送
    @Published var otpSent: Bool = false

    /// OTP 是否已验证（等待设置密码）
    @Published var otpVerified: Bool = false

    // MARK: - Private Properties

    /// Supabase 客户端实例
    private let supabase: SupabaseClient

    // MARK: - Initialization

    init() {
        // 初始化 Supabase 客户端
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: "https://absexnnamqwkqedaaamt.supabase.co")!,
            supabaseKey: "sb_publishable_-jUhdtSZdLOBoDMNfIZXZA_5E-UTaU5"
        )

        // 设置认证状态监听（在后台运行）
        Task {
            await setupAuthStateListener()
        }

        // 检查现有会话
        Task {
            await checkSession()
        }
    }

    // MARK: - Auth State Listener

    /// 设置认证状态监听器
    /// 监听登录、登出等认证状态变化
    private func setupAuthStateListener() async {
        // 监听认证状态变化
        for await (event, session) in supabase.auth.authStateChanges {
            await handleAuthStateChange(event: event, session: session)
        }
    }

    /// 处理认证状态变化
    /// - Parameters:
    ///   - event: 认证事件类型
    ///   - session: 会话信息（可选）
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            // 用户登录
            print("🔐 用户已登录")

            // ⚠️ 重要：如果正在进行密码设置流程，不要设置 isAuthenticated
            // 这确保注册和找回密码流程必须完成密码设置才能进入主页
            if !needsPasswordSetup {
                isAuthenticated = true
            }

            await fetchCurrentUser()

        case .signedOut:
            // 用户登出
            print("🔓 用户已登出")
            isAuthenticated = false
            currentUser = nil
            needsPasswordSetup = false
            otpSent = false
            otpVerified = false

        case .tokenRefreshed:
            // Token 刷新
            print("🔄 Token 已刷新")

        case .userUpdated:
            // 用户信息更新
            print("📝 用户信息已更新")
            await fetchCurrentUser()

        default:
            break
        }
    }

    // MARK: - 注册流程

    /// 发送注册验证码
    /// - Parameter email: 用户邮箱
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 调用 Supabase Auth 发送 OTP（会自动创建用户）
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            otpSent = true
            errorMessage = nil
        } catch {
            errorMessage = "发送验证码失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 验证注册验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    /// - Note: 验证成功后用户已登录，但需要设置密码
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP，type 为 .email（注册/登录类型）
            _ = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录
            otpVerified = true
            needsPasswordSetup = true

            // 但 isAuthenticated 保持 false，因为还需要设置密码
            isAuthenticated = false

            // 获取用户信息
            await fetchCurrentUser()

        } catch {
            errorMessage = "验证码错误: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 完成注册（设置密码）
    /// - Parameter password: 用户设置的密码
    /// - Note: 调用此方法前必须先验证 OTP
    func completeRegistration(password: String) async {
        guard otpVerified else {
            errorMessage = "请先验证邮箱"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            let userAttributes = UserAttributes(password: password)
            try await supabase.auth.update(user: userAttributes)

            // 注册完成
            needsPasswordSetup = false
            isAuthenticated = true
            otpVerified = false

            // 刷新用户信息
            await fetchCurrentUser()

        } catch {
            errorMessage = "设置密码失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 登录

    /// 使用邮箱和密码登录
    /// - Parameters:
    ///   - email: 邮箱
    ///   - password: 密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 使用邮箱密码登录
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            // 登录成功，直接标记为已认证
            isAuthenticated = true
            needsPasswordSetup = false

            // 获取用户信息
            await fetchCurrentUser()

        } catch {
            errorMessage = "登录失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 找回密码流程

    /// 发送密码重置验证码
    /// - Parameter email: 用户邮箱
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 发送密码重置邮件（会触发 Reset Password 邮件模板）
            try await supabase.auth.resetPasswordForEmail(email)

            otpSent = true
            errorMessage = nil

        } catch {
            errorMessage = "发送重置验证码失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 验证密码重置验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    /// - Note: ⚠️ type 必须是 .recovery（恢复类型），不是 .email
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP，type 为 .recovery（密码重置类型）
            _ = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .recovery  // ⚠️ 注意：密码重置使用 .recovery 类型
            )

            // 验证成功，用户已登录
            otpVerified = true
            needsPasswordSetup = true

            // 获取用户信息
            await fetchCurrentUser()

        } catch {
            errorMessage = "验证码错误: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 重置密码（设置新密码）
    /// - Parameter newPassword: 新密码
    /// - Note: 调用此方法前必须先验证 OTP
    func resetPassword(newPassword: String) async {
        guard otpVerified else {
            errorMessage = "请先验证邮箱"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            let userAttributes = UserAttributes(password: newPassword)
            try await supabase.auth.update(user: userAttributes)

            // 密码重置完成
            needsPasswordSetup = false
            isAuthenticated = true
            otpVerified = false

            // 刷新用户信息
            await fetchCurrentUser()

        } catch {
            errorMessage = "重置密码失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 第三方登录（预留）

    /// Sign in with Apple（预留）
    /// TODO: 实现 Apple ID 登录
    func signInWithApple() async {
        isLoading = true
        errorMessage = "Apple 登录功能即将推出"

        // TODO: 集成 AuthenticationServices 框架
        // 1. 导入 AuthenticationServices
        // 2. 使用 ASAuthorizationAppleIDProvider
        // 3. 获取 identityToken 和 authorizationCode
        // 4. 调用 supabase.auth.signInWithIdToken(provider: .apple, idToken:)

        isLoading = false
    }

    /// Sign in with Google（预留）
    /// TODO: 实现 Google 登录
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = "Google 登录功能即将推出"

        // TODO: 集成 Google Sign-In SDK
        // 1. 添加 GoogleSignIn 依赖
        // 2. 配置 OAuth 客户端 ID
        // 3. 获取 idToken
        // 4. 调用 supabase.auth.signInWithIdToken(provider: .google, idToken:)

        isLoading = false
    }

    // MARK: - 登出

    /// 用户登出
    func signOut() async {
        isLoading = true

        do {
            try await supabase.auth.signOut()

            // 清空状态
            isAuthenticated = false
            needsPasswordSetup = false
            currentUser = nil
            otpSent = false
            otpVerified = false
            errorMessage = nil

        } catch {
            errorMessage = "登出失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 会话管理

    /// 检查现有会话
    /// 应用启动时调用，恢复用户登录状态
    func checkSession() async {
        isLoading = true

        do {
            // 获取当前会话
            let session = try await supabase.auth.session

            // 有效会话存在
            isAuthenticated = true
            await fetchCurrentUser()

        } catch {
            // 会话无效或不存在
            isAuthenticated = false
            currentUser = nil
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// 获取当前用户信息
    /// 从 profiles 表获取用户详细资料
    private func fetchCurrentUser() async {
        do {
            // 获取当前认证用户
            let authUser = try await supabase.auth.session.user

            // 从 profiles 表查询用户资料
            let profile: User = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: authUser.id.uuidString)
                .single()
                .execute()
                .value

            currentUser = profile

        } catch {
            print("获取用户信息失败: \(error.localizedDescription)")

            // 如果 profile 不存在，尝试创建基本 User 对象
            do {
                let authUser = try await supabase.auth.session.user
                currentUser = User(
                    id: authUser.id,
                    username: authUser.email?.components(separatedBy: "@").first,
                    avatarUrl: nil,
                    email: authUser.email,
                    createdAt: authUser.createdAt
                )
            } catch {
                print("无法创建用户对象: \(error.localizedDescription)")
                currentUser = nil
            }
        }
    }

    /// 重置错误消息
    func clearError() {
        errorMessage = nil
    }

    /// 重置 OTP 状态（用于重新发送验证码）
    func resetOTPState() {
        otpSent = false
        otpVerified = false
        errorMessage = nil
    }
}
