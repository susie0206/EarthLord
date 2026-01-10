//
//  MapTabView.swift
//  EarthLord
//
//  地图页面
//  显示真实地图、用户位置、定位权限请求、路径追踪
//

import SwiftUI
import MapKit
import UIKit  // Day19: 震动反馈需要

struct MapTabView: View {

    // MARK: - State Objects

    /// 定位管理器
    @StateObject private var locationManager = LocationManager()

    /// 领地管理器 (Day18)
    private let territoryManager = TerritoryManager.shared

    /// 认证管理器 (Day18)
    @EnvironmentObject private var authManager: AuthManager

    // MARK: - State Properties

    /// 已加载的领地列表 (Day18)
    @State private var territories: [Territory] = []

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 重新居中触发器（每次点击定位按钮时递增）
    @State private var recenterTrigger = 0

    /// 是否显示定位权限被拒绝的提示
    @State private var showPermissionDenied = false

    /// 是否显示验证结果横幅 (Day17)
    @State private var showValidationBanner = false

    /// 是否正在上传 (Day18)
    @State private var isUploading = false

    /// 上传错误消息 (Day18)
    @State private var uploadError: String?

    /// 上传成功消息 (Day18)
    @State private var uploadSuccess = false

    /// 圈地开始时间 (Day18)
    @State private var trackingStartTime: Date?

    // MARK: - Day 19: 碰撞检测状态

    /// 碰撞检测定时器
    @State private var collisionCheckTimer: Timer?

    /// 碰撞警告消息
    @State private var collisionWarning: String?

    /// 是否显示碰撞警告横幅
    @State private var showCollisionWarning = false

    /// 碰撞预警级别
    @State private var collisionWarningLevel: WarningLevel = .safe

    // MARK: - Computed Properties

    /// 当前用户 ID (Day19)
    private var currentUserId: String? {
        authManager.currentUser?.id.uuidString
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 地图视图
            MapViewRepresentable(
                userLocation: $userLocation,
                recenterTrigger: $recenterTrigger,
                trackingPath: $locationManager.pathCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion,
                isTracking: locationManager.isTracking,
                isPathClosed: locationManager.isPathClosed,
                territories: territories,  // Day18: 传入已加载的领地
                currentUserId: authManager.currentUser?.id.uuidString  // Day18: 当前用户 ID
            )
            .ignoresSafeArea()

            // 顶部叠加层：权限被拒绝提示
            if locationManager.isDenied {
                permissionDeniedOverlay
            }

            // 顶部叠加层：速度警告横幅
            if locationManager.speedWarning != nil {
                speedWarningBanner
            }

            // 顶部叠加层：验证结果横幅 (Day17)
            if showValidationBanner {
                validationResultBanner
            }

            // Day 19: 碰撞警告横幅（分级颜色）
            if showCollisionWarning, let warning = collisionWarning {
                collisionWarningBanner(message: warning, level: collisionWarningLevel)
            }

            // 左上角叠加层：当前坐标显示
            VStack {
                HStack {
                    coordinateDisplay
                        .padding(.leading, 20)
                        .padding(.top, 60)
                    Spacer()
                }
                Spacer()
            }

            // 右下角叠加层：按钮组（圈地按钮 + 确认登记按钮 + 定位按钮）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 圈地按钮
                        territoryButton

                        // Day18: 确认登记按钮（仅在验证通过时显示）
                        if locationManager.territoryValidationPassed && !isUploading {
                            confirmButton
                        }

                        // 定位按钮
                        locationButton
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            handleLocationPermission()
            // Day18: 加载所有领地
            Task {
                await loadTerritories()
            }
        }
        .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
            handleLocationPermission()
        }
        .onChange(of: locationManager.speedWarning) { oldValue, newValue in
            // 当速度警告出现时，3 秒后自动消失
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    locationManager.speedWarning = nil
                }
            }
        }
        .onChange(of: locationManager.isPathClosed) { oldValue, newValue in
            // Day17: 监听闭环状态，闭环后根据验证结果显示横幅
            if newValue {
                // 闭环后延迟一点点，等待验证结果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        showValidationBanner = true
                    }
                    // 3 秒后自动隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showValidationBanner = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Speed Warning Banner

    /// 速度警告横幅
    private var speedWarningBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 警告图标
                Image(systemName: locationManager.isTracking ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                // 警告文字
                if let warning = locationManager.speedWarning {
                    Text(warning)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                // 根据是否还在追踪选择背景色
                locationManager.isTracking ? Color.orange : Color.red
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: locationManager.speedWarning)
    }

    // MARK: - Validation Result Banner (Day17)

    /// 验证结果横幅（根据验证结果显示成功或失败）
    private var validationResultBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 结果图标
                Image(systemName: locationManager.territoryValidationPassed
                      ? "checkmark.circle.fill"
                      : "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                // 结果文字
                if locationManager.territoryValidationPassed {
                    Text("圈地成功！领地面积: \(String(format: "%.0f", locationManager.calculatedArea))m²")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text(locationManager.territoryValidationError ?? "验证失败")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                // 根据验证结果选择背景色
                locationManager.territoryValidationPassed ? Color.green : Color.red
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut, value: showValidationBanner)
    }

    // MARK: - Permission Denied Overlay

    /// 定位权限被拒绝的提示卡片
    private var permissionDeniedOverlay: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // 图标
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ApocalypseTheme.warning)

                // 标题
                LocalizedText("需要定位权限")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                // 说明
                LocalizedText("《地球新主》需要获取您的位置来显示您在末日世界中的坐标，帮助您探索和圈定领地。")
                    .font(.body)
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // 前往设置按钮
                Button {
                    openSettings()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        LocalizedText("前往设置")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ApocalypseTheme.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 30)

            Spacer()
        }
        .padding(.top, 100)
        .background(Color.black.opacity(0.5))
    }

    // MARK: - Coordinate Display

    /// 左上角的坐标显示卡片
    private var coordinateDisplay: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题
            LocalizedText("当前坐标")
                .font(.caption)
                .foregroundColor(ApocalypseTheme.textSecondary)

            // 坐标值
            if let location = userLocation {
                Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textPrimary)
            } else {
                LocalizedText("获取中...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ApocalypseTheme.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ApocalypseTheme.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Territory Button

    /// 圈地按钮（胶囊型）
    private var territoryButton: some View {
        Button {
            toggleTracking()
        } label: {
            HStack(spacing: 8) {
                // 图标
                Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                    .font(.system(size: 16))

                // 文字
                if locationManager.isTracking {
                    LocalizedText("停止圈地")
                        .font(.system(size: 14, weight: .semibold))

                    // 点数标记
                    if locationManager.pathCoordinates.count > 0 {
                        Text("\(locationManager.pathCoordinates.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.3))
                            .cornerRadius(8)
                    }
                } else {
                    LocalizedText("开始圈地")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(locationManager.isTracking ? Color.red : ApocalypseTheme.primary)
            )
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }

    // MARK: - Location Button

    /// 定位按钮（回到当前位置）
    private var locationButton: some View {
        Button {
            recenterMap()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(ApocalypseTheme.primary)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }

    // MARK: - Helper Methods

    /// 处理定位权限逻辑
    private func handleLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // 首次使用，请求权限
            print("🌍 [MapTabView] 首次使用，请求定位权限")
            locationManager.requestPermission()

        case .authorizedWhenInUse, .authorizedAlways:
            // 已授权，开始定位
            print("✅ [MapTabView] 已授权定位，开始更新位置")
            locationManager.startUpdatingLocation()

        case .denied, .restricted:
            // 被拒绝，显示提示
            print("⚠️ [MapTabView] 定位权限被拒绝")
            showPermissionDenied = true

        @unknown default:
            break
        }
    }

    /// 切换追踪状态
    private func toggleTracking() {
        if locationManager.isTracking {
            // 停止追踪
            print("🛑 [MapTabView] 用户点击停止圈地")
            stopCollisionMonitoring()  // Day19: 完全停止碰撞监控
            locationManager.stopPathTracking()
            trackingStartTime = nil  // Day18: 清除开始时间
        } else {
            // Day 19: 开始圈地前检测起始点
            startClaimingWithCollisionCheck()
        }
    }

    // MARK: - Day 19: 碰撞检测方法

    /// Day 19: 带碰撞检测的开始圈地
    private func startClaimingWithCollisionCheck() {
        guard let location = locationManager.userLocation,
              let userId = currentUserId else {
            print("⚠️ [MapTabView] 无法开始圈地：位置或用户ID缺失")
            return
        }

        // 检测起始点是否在他人领地内
        let result = territoryManager.checkPointCollision(
            location: location,
            currentUserId: userId
        )

        if result.hasCollision {
            // 起点在他人领地内，显示错误并震动
            collisionWarning = result.message
            collisionWarningLevel = .violation
            showCollisionWarning = true

            // 错误震动
            triggerHapticFeedback(level: .violation)

            TerritoryLogger.shared.log("起点碰撞：阻止圈地", type: .error)

            // 3秒后隐藏警告
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showCollisionWarning = false
                collisionWarning = nil
                collisionWarningLevel = .safe
            }

            return
        }

        // 起点安全，开始圈地
        print("🚩 [MapTabView] 起始点安全，开始圈地")
        TerritoryLogger.shared.log("起始点安全，开始圈地", type: .info)
        locationManager.clearPath()  // 清除旧路径
        trackingStartTime = Date()  // Day18: 记录开始时间
        locationManager.startPathTracking()
        startCollisionMonitoring()
    }

    /// Day 19: 启动碰撞检测监控
    private func startCollisionMonitoring() {
        // 先停止已有定时器
        stopCollisionCheckTimer()

        // 同步领地数据到 TerritoryManager
        territoryManager.territories = territories

        // 每 10 秒检测一次
        collisionCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [self] _ in
            performCollisionCheck()
        }

        TerritoryLogger.shared.log("碰撞检测定时器已启动", type: .info)
    }

    /// Day 19: 仅停止定时器（不清除警告状态）
    private func stopCollisionCheckTimer() {
        collisionCheckTimer?.invalidate()
        collisionCheckTimer = nil
    }

    /// Day 19: 完全停止碰撞监控（停止定时器 + 清除警告）
    private func stopCollisionMonitoring() {
        stopCollisionCheckTimer()
        // 清除警告状态
        showCollisionWarning = false
        collisionWarning = nil
        collisionWarningLevel = .safe
        TerritoryLogger.shared.log("碰撞检测监控已停止", type: .info)
    }

    /// Day 19: 执行碰撞检测
    private func performCollisionCheck() {
        guard locationManager.isTracking,
              let userId = currentUserId else {
            return
        }

        let path = locationManager.pathCoordinates
        guard path.count >= 2 else { return }

        let result = territoryManager.checkPathCollisionComprehensive(
            path: path,
            currentUserId: userId
        )

        // 根据预警级别处理
        switch result.warningLevel {
        case .safe:
            // 安全，隐藏警告横幅
            showCollisionWarning = false
            collisionWarning = nil
            collisionWarningLevel = .safe

        case .caution:
            // 注意（50-100m）- 黄色横幅 + 轻震 1 次
            collisionWarning = result.message
            collisionWarningLevel = .caution
            showCollisionWarning = true
            triggerHapticFeedback(level: .caution)

        case .warning:
            // 警告（25-50m）- 橙色横幅 + 中震 2 次
            collisionWarning = result.message
            collisionWarningLevel = .warning
            showCollisionWarning = true
            triggerHapticFeedback(level: .warning)

        case .danger:
            // 危险（<25m）- 红色横幅 + 强震 3 次
            collisionWarning = result.message
            collisionWarningLevel = .danger
            showCollisionWarning = true
            triggerHapticFeedback(level: .danger)

        case .violation:
            // 【关键】违规处理 - 必须先显示横幅，再停止！

            // 1. 先设置警告状态（让横幅显示出来）
            collisionWarning = result.message
            collisionWarningLevel = .violation
            showCollisionWarning = true

            // 2. 触发震动
            triggerHapticFeedback(level: .violation)

            // 3. 只停止定时器，不清除警告状态！
            stopCollisionCheckTimer()

            // 4. 停止圈地追踪
            locationManager.stopPathTracking()
            trackingStartTime = nil

            TerritoryLogger.shared.log("碰撞违规，自动停止圈地", type: .error)

            // 5. 5秒后再清除警告横幅
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                showCollisionWarning = false
                collisionWarning = nil
                collisionWarningLevel = .safe
            }
        }
    }

    /// Day 19: 触发震动反馈
    private func triggerHapticFeedback(level: WarningLevel) {
        switch level {
        case .safe:
            // 安全：无震动
            break

        case .caution:
            // 注意：轻震 1 次
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)

        case .warning:
            // 警告：中震 2 次
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }

        case .danger:
            // 危险：强震 3 次
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                generator.impactOccurred()
            }

        case .violation:
            // 违规：错误震动
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }

    /// Day 19: 碰撞警告横幅（分级颜色）
    private func collisionWarningBanner(message: String, level: WarningLevel) -> some View {
        // 根据级别确定颜色
        let backgroundColor: Color
        switch level {
        case .safe:
            backgroundColor = .green
        case .caution:
            backgroundColor = .yellow
        case .warning:
            backgroundColor = .orange
        case .danger, .violation:
            backgroundColor = .red
        }

        // 根据级别确定文字颜色（黄色背景用黑字）
        let textColor: Color = (level == .caution) ? .black : .white

        // 根据级别确定图标
        let iconName = (level == .violation) ? "xmark.octagon.fill" : "exclamationmark.triangle.fill"

        return VStack {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 18))

                Text(message)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor.opacity(0.95))
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .padding(.top, 120)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: showCollisionWarning)
    }

    /// 重新居中地图到当前位置
    private func recenterMap() {
        // 递增触发器，触发地图重新居中
        recenterTrigger += 1
        print("🎯 [MapTabView] 用户点击定位按钮，触发器值: \(recenterTrigger)")
    }

    /// 打开系统设置页面
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Day18: Territory Upload

    /// 确认登记按钮
    private var confirmButton: some View {
        Button {
            Task {
                await uploadCurrentTerritory()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))

                Text("确认登记领地")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }

    /// 上传当前领地到服务器
    private func uploadCurrentTerritory() async {
        // ⚠️ 再次检查验证状态（防止并发问题）
        guard locationManager.territoryValidationPassed else {
            showUploadError("领地验证未通过，无法上传")
            return
        }

        // 检查是否有开始时间
        guard let startTime = trackingStartTime else {
            showUploadError("缺少圈地开始时间")
            return
        }

        // 设置上传状态
        isUploading = true
        uploadError = nil
        uploadSuccess = false

        print("📤 [MapTabView] 开始上传领地")

        do {
            // 上传领地
            try await territoryManager.uploadTerritory(
                coordinates: locationManager.pathCoordinates,
                area: locationManager.calculatedArea,
                startTime: startTime
            )

            // 上传成功
            print("✅ [MapTabView] 领地上传成功")
            uploadSuccess = true

            // ⚠️ 关键：上传成功后必须停止追踪（防止重复上传）
            stopCollisionMonitoring()  // Day19: 停止碰撞监控
            locationManager.stopPathTracking()
            trackingStartTime = nil

            // Day18: 刷新领地列表（显示刚上传的领地）
            await loadTerritories()

            // 显示成功消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showValidationBanner = false
                }
            }

        } catch {
            // 上传失败
            print("❌ [MapTabView] 领地上传失败：\(error.localizedDescription)")
            showUploadError(error.localizedDescription)
        }

        isUploading = false
    }

    /// 显示上传错误
    private func showUploadError(_ message: String) {
        uploadError = message
        // 3秒后自动清除错误消息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            uploadError = nil
        }
    }

    /// 加载所有领地
    private func loadTerritories() async {
        do {
            territories = try await territoryManager.loadAllTerritories()
            TerritoryLogger.shared.log("加载了 \(territories.count) 个领地", type: .info)
            print("🏠 [MapTabView] 加载了 \(territories.count) 个领地")
        } catch {
            TerritoryLogger.shared.log("加载领地失败: \(error.localizedDescription)", type: .error)
            print("❌ [MapTabView] 加载领地失败：\(error.localizedDescription)")
        }
    }
}

#Preview {
    MapTabView()
}
