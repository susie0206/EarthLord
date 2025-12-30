# 🚨 快速修复 Google URL Scheme 配置

## 错误信息
```
Your app is missing support for the following URL schemes:
com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd
```

## ✅ 5分钟快速修复

### 步骤 1: 打开项目设置
1. 在 Xcode 中，点击左侧导航栏最顶部的 **EarthLord** 项目（蓝色文件夹图标）
2. 确保选择的是 **TARGETS** 下的 **EarthLord**（不是 PROJECT）

### 步骤 2: 进入 Info 标签
1. 点击顶部的 **Info** 标签页
2. 向下滚动找到 **URL Types** 部分

### 步骤 3: 添加 URL Type
1. 点击 **URL Types** 左侧的 **▸** 展开（如果已经展开则跳过）
2. 点击列表下方的 **+** 按钮（或右键选择 "Add Row"）

### 步骤 4: 填写配置
在新添加的 URL Type 中填写：

| 字段 | 值 |
|------|-----|
| **Identifier** | `Google Sign-In` |
| **URL Schemes** | 点击展开，添加下面的值 |
| → Item 0 | `com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd` |
| **Role** | `Editor` (默认) |

**⚠️ 重要**:
- URL Scheme 必须**完整复制**，不能有空格
- 如果 "URL Schemes" 是折叠的，点击左侧箭头展开
- 确保在 "Item 0" 中粘贴完整的 URL Scheme

### 步骤 5: 保存并运行
1. **Command + S** 保存
2. **Command + Shift + K** 清理构建
3. **Command + R** 运行应用

## 📸 配置后应该看到

在 Xcode Info 标签中，URL Types 应该显示：

```
URL Types (1 item)
  ▾ Item 0
      Identifier: Google Sign-In
      ▾ URL Schemes (1 item)
          Item 0: com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd
      Role: Editor
```

## ✅ 验证配置成功

### 方法 1: 运行应用
1. **Command + R** 运行应用
2. 点击 "使用 Google 登录"
3. 应该弹出 Google 登录界面（不再显示错误）

### 方法 2: 检查构建输出
查看 Xcode 底部的构建日志，不应该再有 "missing support for URL schemes" 的错误。

## 🐛 如果还是不行

### 检查清单：

1. **URL Scheme 拼写正确吗？**
   - 复制这个：`com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd`
   - 粘贴时确保没有多余空格

2. **配置在正确的 Target 吗？**
   - 必须是 **TARGETS** → **EarthLord**
   - 不是 PROJECT → EarthLord

3. **清理构建了吗？**
   ```bash
   Command + Shift + K  # 清理
   Command + B          # 重新构建
   ```

4. **URL Types 保存了吗？**
   - 点击其他地方确保输入框失焦
   - Command + S 保存

## 🎯 复制粘贴用的 URL Scheme

```
com.googleusercontent.apps.517596145126-v9arshn1as1j6rra58hh81mht8ivmbnd
```

## 📚 更详细的说明

如需更详细的配置说明，请查看：
- `XCODE_GOOGLE_SIGNIN_SETUP.md` - 完整配置指南
- `GOOGLE_LOGIN_SETUP.md` - Google 登录功能说明

---

**配置完成后，Google 登录功能应该正常工作！** 🎉
