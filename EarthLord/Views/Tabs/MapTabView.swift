//
//  MapTabView.swift
//  EarthLord
//
//  地图页面
//  显示真实地图、用户位置、定位权限请求、路径追踪
//

import SwiftUI
import MapKit

struct MapTabView: View {

    // MARK: - State Objects

    /// 定位管理器
    @StateObject private var locationManager = LocationManager()

    // MARK: - State Properties

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 重新居中触发器（每次点击定位按钮时递增）
    @State private var recenterTrigger = 0

    /// 是否显示定位权限被拒绝的提示
    @State private var showPermissionDenied = false

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
                isPathClosed: locationManager.isPathClosed
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

            // 右下角叠加层：按钮组（圈地按钮 + 定位按钮）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 圈地按钮
                        territoryButton

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
            locationManager.stopPathTracking()
        } else {
            // 开始追踪
            print("🚩 [MapTabView] 用户点击开始圈地")
            locationManager.clearPath()  // 清除旧路径
            locationManager.startPathTracking()
        }
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
}

#Preview {
    MapTabView()
}
