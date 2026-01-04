//
//  LocationManager.swift
//  EarthLord
//
//  GPS 定位管理器
//  负责请求定位权限、获取用户位置、处理定位状态、路径追踪
//

import Foundation
import CoreLocation
import Combine  // ⚠️ 必须导入：@Published 需要这个框架

/// GPS 定位管理器
class LocationManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// 用户当前位置坐标
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位授权状态
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// 定位错误信息
    @Published var locationError: String?

    // MARK: - Path Tracking Properties

    /// 是否正在追踪路径
    @Published var isTracking: Bool = false

    /// 路径坐标数组（存储原始 WGS-84 坐标）
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []

    /// 路径更新版本号（触发 SwiftUI 更新）
    @Published var pathUpdateVersion: Int = 0

    /// 路径是否闭合（Day16 会用）
    @Published var isPathClosed: Bool = false

    // MARK: - Private Properties

    /// CoreLocation 定位管理器
    private let locationManager = CLLocationManager()

    /// 当前位置（用于 Timer 采点）
    private var currentLocation: CLLocation?

    /// 采点定时器（每 2 秒检查一次）
    private var pathUpdateTimer: Timer?

    // MARK: - Computed Properties

    /// 是否已授权定位
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// 是否被拒绝定位权限
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Initialization

    override init() {
        super.init()

        // 配置定位管理器
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // 最高精度
        locationManager.distanceFilter = 10  // 移动10米才更新位置

        // 获取当前授权状态
        authorizationStatus = locationManager.authorizationStatus

        print("🌍 [LocationManager] 初始化完成，当前授权状态: \(authorizationStatus.rawValue)")
    }

    // MARK: - Public Methods

    /// 请求定位权限
    func requestPermission() {
        print("🌍 [LocationManager] 请求定位权限")
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始更新位置
    func startUpdatingLocation() {
        guard isAuthorized else {
            print("⚠️ [LocationManager] 未授权，无法开始定位")
            locationError = "未授权定位权限"
            return
        }

        print("🌍 [LocationManager] 开始更新位置")
        locationManager.startUpdatingLocation()
    }

    /// 停止更新位置
    func stopUpdatingLocation() {
        print("🌍 [LocationManager] 停止更新位置")
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Path Tracking Methods

    /// 开始路径追踪
    func startPathTracking() {
        guard isAuthorized else {
            print("⚠️ [LocationManager] 未授权定位，无法开始追踪")
            return
        }

        print("🚩 [LocationManager] 开始路径追踪")

        isTracking = true
        isPathClosed = false

        // 启动定时器，每 2 秒采集一次
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }

        // 立即记录第一个点
        recordPathPoint()
    }

    /// 停止路径追踪
    func stopPathTracking() {
        print("🛑 [LocationManager] 停止路径追踪")

        isTracking = false

        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil
    }

    /// 清除路径
    func clearPath() {
        print("🗑️ [LocationManager] 清除路径")

        pathCoordinates.removeAll()
        pathUpdateVersion += 1
        isPathClosed = false
    }

    // MARK: - Private Path Methods

    /// 记录路径点（定时器回调）
    private func recordPathPoint() {
        guard isTracking, let location = currentLocation else {
            return
        }

        let newCoordinate = location.coordinate

        // 判断是否需要记录新点
        if let lastCoordinate = pathCoordinates.last {
            // 计算与上个点的距离
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            let distance = location.distance(from: lastLocation)

            // 距离 > 10 米才记录新点
            guard distance > 10 else {
                print("📏 [LocationManager] 距离太近 (\(String(format: "%.1f", distance))m)，跳过采点")
                return
            }

            print("✅ [LocationManager] 记录新点: (\(String(format: "%.6f", newCoordinate.latitude)), \(String(format: "%.6f", newCoordinate.longitude))), 距离: \(String(format: "%.1f", distance))m")
        } else {
            print("✅ [LocationManager] 记录第一个点: (\(String(format: "%.6f", newCoordinate.latitude)), \(String(format: "%.6f", newCoordinate.longitude)))")
        }

        // 记录新点
        pathCoordinates.append(newCoordinate)
        pathUpdateVersion += 1  // 触发 SwiftUI 更新
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// 授权状态改变时调用
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("🌍 [LocationManager] 授权状态改变: \(authorizationStatus.rawValue)")

        // 如果已授权，自动开始定位
        if isAuthorized {
            startUpdatingLocation()
        }
    }

    /// 位置更新成功
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // ⚠️ 关键：更新 currentLocation，供 Timer 使用
        currentLocation = location

        // 更新位置坐标
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationError = nil
        }

        print("📍 [LocationManager] 位置更新: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
    }

    /// 定位失败
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [LocationManager] 定位失败: \(error.localizedDescription)")

        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
}
