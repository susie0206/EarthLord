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
}
