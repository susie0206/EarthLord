//
//  TerritoryManager.swift
//  EarthLord
//
//  领地管理器 - 处理领地数据的上传和拉取
//

import Foundation
import CoreLocation
import Supabase

/// 领地上传错误
enum TerritoryUploadError: LocalizedError {
    case invalidCoordinates
    case authenticationRequired
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCoordinates:
            return "坐标数据无效"
        case .authenticationRequired:
            return "需要登录后才能上传领地"
        case .uploadFailed(let message):
            return "上传失败：\(message)"
        }
    }
}

/// 领地上传数据结构（用于 Supabase 插入）
private struct TerritoryUploadData: Encodable {
    let user_id: String
    let path: [[String: Double]]
    let polygon: String
    let bbox_min_lat: Double
    let bbox_max_lat: Double
    let bbox_min_lon: Double
    let bbox_max_lon: Double
    let area: Double
    let point_count: Int
    let started_at: String
    let is_active: Bool
}

/// 领地管理器
final class TerritoryManager {

    // MARK: - Singleton

    static let shared = TerritoryManager()

    // MARK: - Public Properties

    /// 已加载的所有领地（用于碰撞检测）
    var territories: [Territory] = []

    // MARK: - Private Properties

    private let supabase: SupabaseClient

    // MARK: - Initialization

    private init() {
        // 初始化 Supabase 客户端
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: "https://absexnnamqwkqedaaamt.supabase.co")!,
            supabaseKey: "sb_publishable_-jUhdtSZdLOBoDMNfIZXZA_5E-UTaU5"
        )
    }

    // MARK: - Public Methods

    /// 上传领地到 Supabase
    /// - Parameters:
    ///   - coordinates: 坐标数组
    ///   - area: 面积（平方米）
    ///   - startTime: 开始时间
    /// - Throws: TerritoryUploadError
    func uploadTerritory(
        coordinates: [CLLocationCoordinate2D],
        area: Double,
        startTime: Date
    ) async throws {
        print("🚀 [TerritoryManager] 开始上传领地")

        // 1. 验证坐标数据
        guard !coordinates.isEmpty else {
            print("❌ [TerritoryManager] 坐标数组为空")
            throw TerritoryUploadError.invalidCoordinates
        }

        // 2. 获取当前用户
        guard let userId = try? await supabase.auth.session.user.id else {
            print("❌ [TerritoryManager] 未登录")
            throw TerritoryUploadError.authenticationRequired
        }

        // 3. 转换坐标为 path JSON 格式
        let pathJSON = coordinatesToPathJSON(coordinates)
        print("✅ [TerritoryManager] path 转换完成，点数: \(pathJSON.count)")

        // 4. 转换坐标为 WKT 格式
        let wktPolygon = coordinatesToWKT(coordinates)
        print("✅ [TerritoryManager] WKT 转换完成")

        // 5. 计算边界框
        let bbox = calculateBoundingBox(coordinates)
        print("✅ [TerritoryManager] 边界框计算完成")

        // 6. 构建上传数据
        let territoryData = TerritoryUploadData(
            user_id: userId.uuidString,
            path: pathJSON,
            polygon: wktPolygon,
            bbox_min_lat: bbox.minLat,
            bbox_max_lat: bbox.maxLat,
            bbox_min_lon: bbox.minLon,
            bbox_max_lon: bbox.maxLon,
            area: area,
            point_count: coordinates.count,
            started_at: startTime.ISO8601Format(),
            is_active: true
        )

        // 7. 上传到 Supabase
        do {
            let _: Territory = try await supabase
                .from("territories")
                .insert(territoryData)
                .select()
                .single()
                .execute()
                .value

            print("🎉 [TerritoryManager] 领地上传成功！")

            // Day18: 记录成功日志
            TerritoryLogger.shared.log(
                "领地上传成功！面积: \(Int(area))m², 点数: \(coordinates.count)",
                type: .success
            )
        } catch {
            print("❌ [TerritoryManager] 上传失败：\(error)")

            // Day18: 记录失败日志
            TerritoryLogger.shared.log(
                "领地上传失败: \(error.localizedDescription)",
                type: .error
            )

            throw TerritoryUploadError.uploadFailed(error.localizedDescription)
        }
    }

    /// 加载所有激活的领地
    /// - Returns: 领地数组
    /// - Throws: Error
    func loadAllTerritories() async throws -> [Territory] {
        print("📥 [TerritoryManager] 开始加载领地")

        do {
            let territories: [Territory] = try await supabase
                .from("territories")
                .select()
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            print("✅ [TerritoryManager] 加载成功，共 \(territories.count) 个领地")
            return territories
        } catch {
            print("❌ [TerritoryManager] 加载失败：\(error)")
            throw error
        }
    }

    /// 加载我的领地（仅加载当前用户的领地）
    /// - Returns: 我的领地数组
    /// - Throws: Error
    func loadMyTerritories() async throws -> [Territory] {
        print("📥 [TerritoryManager] 开始加载我的领地")

        // 获取当前用户
        guard let userId = try? await supabase.auth.session.user.id else {
            print("❌ [TerritoryManager] 未登录")
            throw TerritoryUploadError.authenticationRequired
        }

        do {
            let territories: [Territory] = try await supabase
                .from("territories")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            print("✅ [TerritoryManager] 加载成功，共 \(territories.count) 个我的领地")
            TerritoryLogger.shared.log("加载了 \(territories.count) 个我的领地", type: .info)
            return territories
        } catch {
            print("❌ [TerritoryManager] 加载失败：\(error)")
            TerritoryLogger.shared.log("加载我的领地失败: \(error.localizedDescription)", type: .error)
            throw error
        }
    }

    /// 删除领地
    /// - Parameter territoryId: 领地ID
    /// - Returns: 是否删除成功
    func deleteTerritory(territoryId: String) async -> Bool {
        print("🗑️ [TerritoryManager] 开始删除领地：\(territoryId)")

        do {
            try await supabase
                .from("territories")
                .delete()
                .eq("id", value: territoryId)
                .execute()

            print("✅ [TerritoryManager] 领地删除成功")
            TerritoryLogger.shared.log("领地删除成功", type: .success)
            return true
        } catch {
            print("❌ [TerritoryManager] 领地删除失败：\(error)")
            TerritoryLogger.shared.log("领地删除失败: \(error.localizedDescription)", type: .error)
            return false
        }
    }

    // MARK: - Private Helper Methods

    /// 将坐标数组转换为 path JSON 格式
    /// - Parameter coordinates: 坐标数组
    /// - Returns: [{"lat": x, "lon": y}, ...]
    private func coordinatesToPathJSON(_ coordinates: [CLLocationCoordinate2D]) -> [[String: Double]] {
        return coordinates.map { coordinate in
            return [
                "lat": coordinate.latitude,
                "lon": coordinate.longitude
            ]
        }
    }

    /// 将坐标数组转换为 WKT 格式（PostGIS）
    /// - Parameter coordinates: 坐标数组
    /// - Returns: SRID=4326;POLYGON((lon lat, lon lat, ...))
    /// - Note: WKT 格式要求「经度在前，纬度在后」，且多边形必须闭合（首尾相同）
    private func coordinatesToWKT(_ coordinates: [CLLocationCoordinate2D]) -> String {
        guard !coordinates.isEmpty else {
            return ""
        }

        // 确保多边形闭合（首尾相同）
        var closedCoordinates = coordinates
        let first = coordinates.first!
        let last = coordinates.last!

        // 如果首尾不同，添加首个坐标到末尾
        if first.latitude != last.latitude || first.longitude != last.longitude {
            closedCoordinates.append(first)
        }

        // 转换为 WKT 格式：经度在前，纬度在后
        let points = closedCoordinates.map { coordinate in
            return "\(coordinate.longitude) \(coordinate.latitude)"
        }.joined(separator: ", ")

        return "SRID=4326;POLYGON((\(points)))"
    }

    /// 计算边界框
    /// - Parameter coordinates: 坐标数组
    /// - Returns: (minLat, maxLat, minLon, maxLon)
    private func calculateBoundingBox(_ coordinates: [CLLocationCoordinate2D]) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        guard !coordinates.isEmpty else {
            return (0, 0, 0, 0)
        }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        return (minLat, maxLat, minLon, maxLon)
    }

    // MARK: - 碰撞检测算法 (Day 19)

    /// 射线法判断点是否在多边形内
    /// - Parameters:
    ///   - point: 待检测的点
    ///   - polygon: 多边形顶点数组
    /// - Returns: true 表示点在多边形内
    func isPointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        let x = point.longitude
        let y = point.latitude

        var j = polygon.count - 1
        for i in 0..<polygon.count {
            let xi = polygon[i].longitude
            let yi = polygon[i].latitude
            let xj = polygon[j].longitude
            let yj = polygon[j].latitude

            let intersect = ((yi > y) != (yj > y)) &&
                           (x < (xj - xi) * (y - yi) / (yj - yi) + xi)

            if intersect {
                inside.toggle()
            }
            j = i
        }

        return inside
    }

    /// 检查起始点是否在他人领地内
    /// - Parameters:
    ///   - location: 当前位置
    ///   - currentUserId: 当前用户ID
    /// - Returns: 碰撞检测结果
    func checkPointCollision(location: CLLocationCoordinate2D, currentUserId: String) -> CollisionResult {
        let otherTerritories = territories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else {
            return .safe
        }

        for territory in otherTerritories {
            let polygon = territory.toCoordinates()
            guard polygon.count >= 3 else { continue }

            if isPointInPolygon(point: location, polygon: polygon) {
                TerritoryLogger.shared.log("起点碰撞：位于他人领地内", type: .error)
                return CollisionResult(
                    hasCollision: true,
                    collisionType: .pointInTerritory,
                    message: "不能在他人领地内开始圈地！",
                    closestDistance: 0,
                    warningLevel: .violation
                )
            }
        }

        return .safe
    }

    /// 判断两条线段是否相交（CCW 算法）
    /// - Parameters:
    ///   - p1: 线段1起点
    ///   - p2: 线段1终点
    ///   - p3: 线段2起点
    ///   - p4: 线段2终点
    /// - Returns: true 表示相交
    private func segmentsIntersectForCollision(
        p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D, p4: CLLocationCoordinate2D
    ) -> Bool {
        func ccw(_ A: CLLocationCoordinate2D, _ B: CLLocationCoordinate2D, _ C: CLLocationCoordinate2D) -> Bool {
            return (C.latitude - A.latitude) * (B.longitude - A.longitude) >
                   (B.latitude - A.latitude) * (C.longitude - A.longitude)
        }

        return ccw(p1, p3, p4) != ccw(p2, p3, p4) && ccw(p1, p2, p3) != ccw(p1, p2, p4)
    }

    /// 检查路径是否穿越他人领地边界
    /// - Parameters:
    ///   - path: 路径坐标数组
    ///   - currentUserId: 当前用户ID
    /// - Returns: 碰撞检测结果
    func checkPathCrossTerritory(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard path.count >= 2 else { return .safe }

        let otherTerritories = territories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else { return .safe }

        for i in 0..<(path.count - 1) {
            let pathStart = path[i]
            let pathEnd = path[i + 1]

            for territory in otherTerritories {
                let polygon = territory.toCoordinates()
                guard polygon.count >= 3 else { continue }

                // 检查与领地每条边的相交
                for j in 0..<polygon.count {
                    let boundaryStart = polygon[j]
                    let boundaryEnd = polygon[(j + 1) % polygon.count]

                    if segmentsIntersectForCollision(p1: pathStart, p2: pathEnd, p3: boundaryStart, p4: boundaryEnd) {
                        TerritoryLogger.shared.log("路径碰撞：轨迹穿越他人领地边界", type: .error)
                        return CollisionResult(
                            hasCollision: true,
                            collisionType: .pathCrossTerritory,
                            message: "轨迹不能穿越他人领地！",
                            closestDistance: 0,
                            warningLevel: .violation
                        )
                    }
                }

                // 检查路径点是否在领地内
                if isPointInPolygon(point: pathEnd, polygon: polygon) {
                    TerritoryLogger.shared.log("路径碰撞：轨迹点进入他人领地", type: .error)
                    return CollisionResult(
                        hasCollision: true,
                        collisionType: .pointInTerritory,
                        message: "轨迹不能进入他人领地！",
                        closestDistance: 0,
                        warningLevel: .violation
                    )
                }
            }
        }

        return .safe
    }

    /// 计算当前位置到他人领地的最近距离
    /// - Parameters:
    ///   - location: 当前位置
    ///   - currentUserId: 当前用户ID
    /// - Returns: 最近距离（米），如果没有他人领地则返回无穷大
    func calculateMinDistanceToTerritories(location: CLLocationCoordinate2D, currentUserId: String) -> Double {
        let otherTerritories = territories.filter { territory in
            territory.userId.lowercased() != currentUserId.lowercased()
        }

        guard !otherTerritories.isEmpty else { return Double.infinity }

        var minDistance = Double.infinity
        let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        for territory in otherTerritories {
            let polygon = territory.toCoordinates()

            for vertex in polygon {
                let vertexLocation = CLLocation(latitude: vertex.latitude, longitude: vertex.longitude)
                let distance = currentLocation.distance(from: vertexLocation)
                minDistance = min(minDistance, distance)
            }
        }

        return minDistance
    }

    /// 综合碰撞检测（主方法）
    /// - Parameters:
    ///   - path: 路径坐标数组
    ///   - currentUserId: 当前用户ID
    /// - Returns: 碰撞检测结果
    func checkPathCollisionComprehensive(path: [CLLocationCoordinate2D], currentUserId: String) -> CollisionResult {
        guard path.count >= 2 else { return .safe }

        // 1. 检查路径是否穿越他人领地
        let crossResult = checkPathCrossTerritory(path: path, currentUserId: currentUserId)
        if crossResult.hasCollision {
            return crossResult
        }

        // 2. 计算到最近领地的距离
        guard let lastPoint = path.last else { return .safe }
        let minDistance = calculateMinDistanceToTerritories(location: lastPoint, currentUserId: currentUserId)

        // 3. 根据距离确定预警级别和消息
        let warningLevel: WarningLevel
        let message: String?

        if minDistance > 100 {
            warningLevel = .safe
            message = nil
        } else if minDistance > 50 {
            warningLevel = .caution
            message = "注意：距离他人领地 \(Int(minDistance))m"
        } else if minDistance > 25 {
            warningLevel = .warning
            message = "警告：正在靠近他人领地（\(Int(minDistance))m）"
        } else {
            warningLevel = .danger
            message = "危险：即将进入他人领地！（\(Int(minDistance))m）"
        }

        if warningLevel != .safe {
            TerritoryLogger.shared.log("距离预警：\(warningLevel.description)，距离 \(Int(minDistance))m", type: .warning)
        }

        return CollisionResult(
            hasCollision: false,
            collisionType: nil,
            message: message,
            closestDistance: minDistance,
            warningLevel: warningLevel
        )
    }
}
