# Supabase 删除账户边缘函数

## ✅ 已部署

**函数名称**: `delete-account`
**函数版本**: v1
**状态**: ACTIVE ✅
**部署时间**: 2025-12-30

## 📝 功能说明

这个 Supabase 边缘函数用于删除用户账户。它提供了一个安全的方式让用户自己删除自己的账户。

### 主要功能

1. ✅ **身份验证**: 验证请求者的 JWT token
2. ✅ **权限控制**: 只允许用户删除自己的账户
3. ✅ **安全删除**: 使用 service_role key 执行删除操作
4. ✅ **详细日志**: 记录每个步骤的执行情况
5. ✅ **错误处理**: 提供清晰的错误信息

## 🔧 API 使用

### 端点 URL

```
POST https://absexnnamqwkqedaaamt.supabase.co/functions/v1/delete-account
```

### 请求头

```http
Authorization: Bearer <USER_JWT_TOKEN>
Content-Type: application/json
```

### 请求示例

#### 使用 cURL

```bash
curl -X POST \
  https://absexnnamqwkqedaaamt.supabase.co/functions/v1/delete-account \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json"
```

#### 使用 JavaScript/TypeScript

```typescript
const { data, error } = await supabase.functions.invoke('delete-account', {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${session.access_token}`
  }
});

if (error) {
  console.error('删除账户失败:', error);
} else {
  console.log('账户删除成功:', data);
}
```

#### 使用 Swift (iOS)

```swift
// 在 AuthManager 中添加删除账户方法
func deleteAccount() async throws {
    // 1. 获取当前会话
    let session = try await supabase.auth.session

    // 2. 调用边缘函数
    let response: DeleteAccountResponse = try await supabase.functions
        .invoke(
            "delete-account",
            options: FunctionInvokeOptions(
                headers: [
                    "Authorization": "Bearer \(session.accessToken)"
                ],
                method: .post
            )
        )

    print("账户删除成功: \(response.message)")

    // 3. 登出
    try await supabase.auth.signOut()
}

struct DeleteAccountResponse: Codable {
    let success: Bool
    let message: String
    let user_id: String
}
```

## 📊 响应格式

### 成功响应 (200 OK)

```json
{
  "success": true,
  "message": "账户已成功删除",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### 错误响应

#### 405 Method Not Allowed
```json
{
  "error": "只支持 POST 请求"
}
```

#### 401 Unauthorized - 缺少认证
```json
{
  "error": "缺少身份验证信息"
}
```

#### 401 Unauthorized - 认证失败
```json
{
  "error": "身份验证失败"
}
```

#### 500 Internal Server Error
```json
{
  "error": "删除账户失败",
  "details": "具体错误信息"
}
```

## 🔍 调试日志

函数执行时会输出详细的中文日志：

```
🔵 [删除账户] 开始处理删除账户请求
🔵 [删除账户] 检查 Authorization header: 存在
✅ [删除账户] JWT token 已提取 (长度: 234 字符)
🔵 [删除账户] 创建用户验证客户端
🔵 [删除账户] 验证用户身份
✅ [删除账户] 用户身份验证成功
   用户ID: 550e8400-e29b-41d4-a716-446655440000
   用户邮箱: user@example.com
🔵 [删除账户] 创建管理员客户端
🔵 [删除账户] 开始删除用户账户: 550e8400-e29b-41d4-a716-446655440000
✅ [删除账户] 用户账户删除成功
🎉 [删除账户] 账户删除流程完成！
```

## 🛡️ 安全特性

1. **JWT 验证**:
   - 函数配置了 `verify_jwt: true`
   - Supabase 自动验证 JWT 的有效性

2. **用户权限**:
   - 只能删除自己的账户
   - 通过验证 JWT 中的用户 ID 确保权限

3. **Service Role Key**:
   - 使用环境变量存储
   - 不会暴露给客户端

4. **CORS 保护**:
   - 配置了适当的 CORS 头
   - 允许的方法：POST, OPTIONS

## 📱 在 EarthLord App 中集成

### 1. 在 AuthManager.swift 添加删除账户方法

```swift
/// 删除用户账户
/// ⚠️ 警告：此操作不可逆！
func deleteAccount() async throws {
    print("🔵 [删除账户] 开始删除账户流程")
    isLoading = true
    errorMessage = nil

    do {
        // 1. 确认用户已登录
        guard isAuthenticated else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "用户未登录"
            ])
        }

        print("🔵 [删除账户] 获取当前会话")
        let session = try await supabase.auth.session

        // 2. 调用删除账户的边缘函数
        print("🔵 [删除账户] 调用 delete-account 边缘函数")

        struct DeleteResponse: Codable {
            let success: Bool
            let message: String
            let user_id: String
        }

        let response: DeleteResponse = try await supabase.functions
            .invoke(
                "delete-account",
                options: FunctionInvokeOptions(
                    headers: [
                        "Authorization": "Bearer \(session.accessToken)"
                    ],
                    method: .post
                )
            )

        print("✅ [删除账户] 账户删除成功: \(response.message)")
        print("   用户ID: \(response.user_id)")

        // 3. 登出并清空本地状态
        print("🔵 [删除账户] 清空本地状态")
        isAuthenticated = false
        needsPasswordSetup = false
        currentUser = nil
        otpSent = false
        otpVerified = false

        print("🎉 [删除账户] 账户删除流程完成")

    } catch {
        print("❌ [删除账户] 删除失败: \(error.localizedDescription)")
        errorMessage = "删除账户失败: \(error.localizedDescription)"
        throw error
    }

    isLoading = false
}
```

### 2. 在 UI 中添加删除账户按钮

在 `ProfileTabView.swift` 或设置页面中添加：

```swift
// 删除账户区域（危险操作）
Section {
    Button(role: .destructive) {
        showDeleteConfirmation = true
    } label: {
        HStack {
            Image(systemName: "trash.fill")
                .font(.system(size: 20))
                .foregroundColor(.red)

            Text("删除账户")
                .font(.body)
                .foregroundColor(.red)
        }
    }
} header: {
    Text("危险操作")
} footer: {
    Text("删除账户后，所有数据将被永久删除且无法恢复。")
        .font(.caption)
        .foregroundColor(.red)
}
.confirmationDialog(
    "确认删除账户",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("删除账户", role: .destructive) {
        Task {
            do {
                try await authManager.deleteAccount()
            } catch {
                // 错误已在 AuthManager 中处理
            }
        }
    }
    Button("取消", role: .cancel) {}
} message: {
    Text("此操作不可逆！删除后，您的所有领地、资源和探索记录都将永久丢失。")
}
```

## ⚠️ 重要注意事项

### 1. 数据删除范围

删除账户时，Supabase 会：
- ✅ 删除 `auth.users` 表中的用户记录
- ❓ **需要手动处理** `profiles` 表中的用户数据
- ❓ **需要手动处理** 其他关联数据（territories, pois 等）

### 2. 级联删除配置

建议在数据库中配置级联删除：

```sql
-- 在 profiles 表上设置级联删除
ALTER TABLE profiles
DROP CONSTRAINT IF EXISTS profiles_id_fkey,
ADD CONSTRAINT profiles_id_fkey
  FOREIGN KEY (id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 在 territories 表上设置级联删除
ALTER TABLE territories
DROP CONSTRAINT IF EXISTS territories_user_id_fkey,
ADD CONSTRAINT territories_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 在 pois 表上设置级联删除（如果有 user_id 外键）
ALTER TABLE pois
DROP CONSTRAINT IF EXISTS pois_discovered_by_fkey,
ADD CONSTRAINT pois_discovered_by_fkey
  FOREIGN KEY (discovered_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;  -- 或 CASCADE，取决于业务需求
```

### 3. 用户体验建议

- ⚠️ **二次确认**: 必须要求用户确认删除操作
- 📧 **邮件通知**: 可以发送确认邮件
- ⏰ **延迟删除**: 考虑实现"软删除"，给用户30天恢复期
- 📊 **数据导出**: 删除前允许用户导出数据

## 🧪 测试

### 使用 Supabase Dashboard 测试

1. 登录 Supabase Dashboard
2. 导航到 Edge Functions → delete-account
3. 点击 "Invoke" 按钮
4. 在 Headers 中添加有效的 Authorization token
5. 点击 "Send Request"
6. 查看响应和日志

### 使用 Postman 测试

1. 创建新的 POST 请求
2. URL: `https://absexnnamqwkqedaaamt.supabase.co/functions/v1/delete-account`
3. Headers:
   - `Authorization: Bearer <YOUR_JWT_TOKEN>`
   - `Content-Type: application/json`
4. 发送请求
5. 查看响应

### 获取测试用的 JWT Token

在应用中登录后，可以通过以下方式获取：

```swift
// 在 AuthManager 中添加
func getAccessToken() async -> String? {
    do {
        let session = try await supabase.auth.session
        return session.accessToken
    } catch {
        print("获取 token 失败: \(error)")
        return nil
    }
}
```

## 📚 相关文档

- [Supabase Edge Functions 文档](https://supabase.com/docs/guides/functions)
- [Supabase Auth Admin API](https://supabase.com/docs/reference/javascript/auth-admin-deleteuser)
- [Deno Deploy 文档](https://deno.com/deploy/docs)

## 🔄 更新函数

如果需要修改函数，使用以下步骤：

1. 修改本地的 TypeScript 代码
2. 使用 Supabase CLI 部署：
   ```bash
   supabase functions deploy delete-account
   ```

或者使用 MCP 工具重新部署（传入新的代码）。

---

**创建时间**: 2025-12-30
**函数 ID**: ed7d95d1-df1d-4631-b613-9660c269b7e0
**版本**: v1
**状态**: ✅ ACTIVE
