//
//  User.swift
//  EarthLord
//
//  Created by Claude Code on 2025/12/29.
//

import Foundation

/// 用户模型
/// 对应 Supabase profiles 表和 auth.users
struct User: Codable, Identifiable {
    /// 用户ID（对应 auth.users.id）
    let id: UUID

    /// 用户名
    var username: String?

    /// 头像URL
    var avatarUrl: String?

    /// 邮箱（来自 auth.users）
    var email: String?

    /// 创建时间
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarUrl = "avatar_url"
        case email
        case createdAt = "created_at"
    }
}
