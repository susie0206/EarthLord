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

    /// 速度警告信息
    @Published var speedWarning: String?

    /// 是否超速
    @Published var isOverSpeed: Bool = false

    // MARK: - Validation Properties (Day17)

    /// 领地验证是否通过
    @Published var territoryValidationPassed: Bool = false

    /// 领地验证错误信息
    @Published var territoryValidationError: String? = nil

    /// 计算出的领地面积（平方米）
    @Published var calculatedArea: Double = 0

    // MARK: - Private Properties

    /// CoreLocation 定位管理器
    private let locationManager = CLLocationManager()

    /// 当前位置（用于 Timer 采点）
    private var currentLocation: CLLocation?

    /// 采点定时器（每 2 秒检查一次）
    private var pathUpdateTimer: Timer?

    /// 上次位置时间戳（用于速度计算）
    private var lastLocationTimestamp: Date?

    // MARK: - Constants

    /// 闭环距离阈值（米）
    private let closureDistanceThreshold: Double = 30.0

    /// 最少路径点数
    private let minimumPathPoints: Int = 10

    /// 最小行走距离（米）
    private let minimumTotalDistance: Double = 50.0

    /// 最小领地面积（平方米）
    private let minimumEnclosedArea: Double = 100.0

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

    /// 停止路径追踪（并重置所有状态）
    func stopPathTracking() {
        print("🛑 [LocationManager] 停止路径追踪")

        isTracking = false

        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil

        // Day18: 重置路径和验证状态（防止重复上传）
        pathCoordinates.removeAll()
        pathUpdateVersion += 1
        isPathClosed = false
        speedWarning = nil
        isOverSpeed = false
        lastLocationTimestamp = nil

        // 重置验证状态
        territoryValidationPassed = false
        territoryValidationError = nil
        calculatedArea = 0

        print("✅ [LocationManager] 所有状态已重置")
    }

    /// 清除路径
    func clearPath() {
        print("🗑️ [LocationManager] 清除路径")

        pathCoordinates.removeAll()
        pathUpdateVersion += 1
        isPathClosed = false
        speedWarning = nil
        isOverSpeed = false
        lastLocationTimestamp = nil

        // Day17: 清除验证状态
        territoryValidationPassed = false
        territoryValidationError = nil
        calculatedArea = 0
    }

    // MARK: - Private Path Methods

    /// 记录路径点（定时器回调）
    private func recordPathPoint() {
        guard isTracking, let location = currentLocation else {
            return
        }

        // ⚠️ 速度检测：超速则不记录该点
        guard validateMovementSpeed(newLocation: location) else {
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

        // ⚠️ 闭环检测：每次添加新点后检查是否闭环
        checkPathClosure()
    }

    /// 检查路径是否闭环
    private func checkPathClosure() {
        // 已经闭环则不再检查
        guard !isPathClosed else { return }

        // 点数不足，无法闭环
        guard pathCoordinates.count >= minimumPathPoints else {
            print("🔍 [LocationManager] 点数不足 (\(pathCoordinates.count)/\(minimumPathPoints))，无法判断闭环")
            return
        }

        // 获取起点和当前点
        guard let startPoint = pathCoordinates.first,
              let currentPoint = pathCoordinates.last else {
            return
        }

        // 计算当前点到起点的距离
        let startLocation = CLLocation(latitude: startPoint.latitude, longitude: startPoint.longitude)
        let currentLocation = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
        let distance = currentLocation.distance(from: startLocation)

        print("🔍 [LocationManager] 闭环检测: 当前点到起点距离 \(String(format: "%.1f", distance))m (阈值: \(closureDistanceThreshold)m)")

        // 距离 ≤ 阈值则闭环成功
        if distance <= closureDistanceThreshold {
            isPathClosed = true
            pathUpdateVersion += 1  // 触发地图重绘
            print("✅ [LocationManager] 闭环检测成功！路径已闭合，点数: \(pathCoordinates.count)")

            // ⚠️ Day17: 闭环成功后立即进行领地验证
            let validationResult = validateTerritory()

            DispatchQueue.main.async {
                self.territoryValidationPassed = validationResult.isValid
                self.territoryValidationError = validationResult.errorMessage

                if validationResult.isValid {
                    // 验证通过，保存计算的面积
                    self.calculatedArea = self.calculatePolygonArea()
                } else {
                    // 验证失败，面积设为 0
                    self.calculatedArea = 0
                }
            }
        }
    }

    /// 验证移动速度（防止作弊）
    /// - Parameter newLocation: 新位置
    /// - Returns: true 表示速度正常，false 表示超速
    private func validateMovementSpeed(newLocation: CLLocation) -> Bool {
        // 第一个点，无需检测速度
        guard let lastCoordinate = pathCoordinates.last,
              let lastTimestamp = lastLocationTimestamp else {
            lastLocationTimestamp = Date()
            return true
        }

        // 计算距离
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = newLocation.distance(from: lastLocation)  // 单位：米

        // 计算时间差
        let currentTimestamp = Date()
        let timeDiff = currentTimestamp.timeIntervalSince(lastTimestamp)  // 单位：秒

        // 避免除以 0
        guard timeDiff > 0 else {
            lastLocationTimestamp = currentTimestamp
            return true
        }

        // 计算速度（km/h）
        let speed = (distance / timeDiff) * 3.6

        print("🚗 [LocationManager] 速度检测: \(String(format: "%.1f", speed)) km/h (距离: \(String(format: "%.1f", distance))m, 时间: \(String(format: "%.1f", timeDiff))s)")

        // 更新时间戳
        lastLocationTimestamp = currentTimestamp

        // 速度 > 30 km/h：暂停追踪
        if speed > 30 {
            DispatchQueue.main.async {
                self.speedWarning = "速度过快 (\(String(format: "%.1f", speed)) km/h)，已暂停追踪"
                self.isOverSpeed = true
            }
            print("⚠️ [LocationManager] 速度超过 30 km/h，暂停追踪")
            stopPathTracking()
            return false
        }

        // 速度 > 15 km/h：警告但继续追踪
        if speed > 15 {
            DispatchQueue.main.async {
                self.speedWarning = "速度较快 (\(String(format: "%.1f", speed)) km/h)，请放慢速度"
                self.isOverSpeed = true
            }
            print("⚠️ [LocationManager] 速度超过 15 km/h，发出警告")
        } else {
            // 速度正常，清除警告
            DispatchQueue.main.async {
                self.speedWarning = nil
                self.isOverSpeed = false
            }
        }

        return true
    }

    // MARK: - Distance & Area Calculation (Day17)

    /// 计算路径总距离
    /// - Returns: 总距离（米）
    private func calculateTotalPathDistance() -> Double {
        guard pathCoordinates.count >= 2 else { return 0 }

        var totalDistance: Double = 0

        for i in 0..<(pathCoordinates.count - 1) {
            let current = pathCoordinates[i]
            let next = pathCoordinates[i + 1]

            let currentLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
            let nextLocation = CLLocation(latitude: next.latitude, longitude: next.longitude)

            totalDistance += currentLocation.distance(from: nextLocation)
        }

        return totalDistance
    }

    /// 计算多边形面积（使用鞋带公式，考虑地球曲率）
    /// - Returns: 面积（平方米）
    private func calculatePolygonArea() -> Double {
        guard pathCoordinates.count >= 3 else { return 0 }

        let earthRadius: Double = 6371000  // 地球半径（米）
        var area: Double = 0

        for i in 0..<pathCoordinates.count {
            let current = pathCoordinates[i]
            let next = pathCoordinates[(i + 1) % pathCoordinates.count]  // 循环取点

            // 经纬度转弧度
            let lat1 = current.latitude * .pi / 180
            let lon1 = current.longitude * .pi / 180
            let lat2 = next.latitude * .pi / 180
            let lon2 = next.longitude * .pi / 180

            // 鞋带公式（球面修正）
            area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2))
        }

        area = abs(area * earthRadius * earthRadius / 2.0)
        return area
    }

    // MARK: - Self-Intersection Detection (Day17)

    /// 判断两条线段是否相交（使用 CCW 算法）
    /// - Parameters:
    ///   - p1: 线段1的起点
    ///   - p2: 线段1的终点
    ///   - p3: 线段2的起点
    ///   - p4: 线段2的终点
    /// - Returns: true 表示相交
    private func segmentsIntersect(p1: CLLocationCoordinate2D,
                                   p2: CLLocationCoordinate2D,
                                   p3: CLLocationCoordinate2D,
                                   p4: CLLocationCoordinate2D) -> Bool {
        /// CCW 辅助函数：计算三点的旋转方向
        /// - Returns: true 表示逆时针（叉积 > 0）
        func ccw(a: CLLocationCoordinate2D,
                b: CLLocationCoordinate2D,
                c: CLLocationCoordinate2D) -> Bool {
            // ⚠️ 坐标映射：longitude = X轴，latitude = Y轴
            let crossProduct = (c.latitude - a.latitude) * (b.longitude - a.longitude) -
                              (b.latitude - a.latitude) * (c.longitude - a.longitude)
            return crossProduct > 0
        }

        // 判断相交条件
        return ccw(a: p1, b: p3, c: p4) != ccw(a: p2, b: p3, c: p4) &&
               ccw(a: p1, b: p2, c: p3) != ccw(a: p1, b: p2, c: p4)
    }

    /// 检测路径是否自相交
    /// - Returns: true 表示有自交
    func hasPathSelfIntersection() -> Bool {
        // ✅ 防御性检查：至少需要4个点才可能自交
        guard pathCoordinates.count >= 4 else { return false }

        // ✅ 创建路径快照的深拷贝，避免并发修改问题
        let pathSnapshot = Array(pathCoordinates)

        // ✅ 再次检查快照是否有效
        guard pathSnapshot.count >= 4 else { return false }

        let segmentCount = pathSnapshot.count - 1

        // ✅ 防御性检查：确保有足够的线段
        guard segmentCount >= 2 else { return false }

        // ✅ 闭环时需要跳过的首尾线段数量
        let skipHeadCount = 2
        let skipTailCount = 2

        for i in 0..<segmentCount {
            guard i < pathSnapshot.count - 1 else { break }

            let p1 = pathSnapshot[i]
            let p2 = pathSnapshot[i + 1]

            let startJ = i + 2
            guard startJ < segmentCount else { continue }

            for j in startJ..<segmentCount {
                guard j < pathSnapshot.count - 1 else { break }

                // ✅ 跳过首尾附近线段的比较
                let isHeadSegment = i < skipHeadCount
                let isTailSegment = j >= segmentCount - skipTailCount

                if isHeadSegment && isTailSegment {
                    continue
                }

                let p3 = pathSnapshot[j]
                let p4 = pathSnapshot[j + 1]

                if segmentsIntersect(p1: p1, p2: p2, p3: p3, p4: p4) {
                    print("❌ [LocationManager] 自交检测: 线段\(i)-\(i+1) 与 线段\(j)-\(j+1) 相交")
                    return true
                }
            }
        }

        print("✅ [LocationManager] 自交检测: 无交叉 ✓")
        return false
    }

    // MARK: - Territory Validation (Day17)

    /// 综合验证领地是否合法
    /// - Returns: (是否合法, 错误信息)
    func validateTerritory() -> (isValid: Bool, errorMessage: String?) {
        print("🔍 [LocationManager] 开始领地验证")

        // 1. 点数检查
        if pathCoordinates.count < minimumPathPoints {
            let error = "点数不足: \(pathCoordinates.count)个点 (需≥\(minimumPathPoints)个)"
            print("❌ [LocationManager] \(error)")
            return (false, error)
        }
        print("✅ [LocationManager] 点数检查: \(pathCoordinates.count)个点 ✓")

        // 2. 距离检查
        let totalDistance = calculateTotalPathDistance()
        if totalDistance < minimumTotalDistance {
            let error = "距离不足: \(String(format: "%.0f", totalDistance))m (需≥\(String(format: "%.0f", minimumTotalDistance))m)"
            print("❌ [LocationManager] \(error)")
            return (false, error)
        }
        print("✅ [LocationManager] 距离检查: \(String(format: "%.0f", totalDistance))m ✓")

        // 3. 自交检测
        if hasPathSelfIntersection() {
            let error = "轨迹自相交，请勿画8字形"
            print("❌ [LocationManager] \(error)")
            return (false, error)
        }

        // 4. 面积检查
        let area = calculatePolygonArea()
        if area < minimumEnclosedArea {
            let error = "面积不足: \(String(format: "%.0f", area))m² (需≥\(String(format: "%.0f", minimumEnclosedArea))m²)"
            print("❌ [LocationManager] \(error)")
            return (false, error)
        }
        print("✅ [LocationManager] 面积检查: \(String(format: "%.0f", area))m² ✓")

        // 全部通过
        print("🎉 [LocationManager] 领地验证通过！面积: \(String(format: "%.0f", area))m²")
        return (true, nil)
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
