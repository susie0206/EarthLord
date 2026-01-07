//
//  MapViewRepresentable.swift
//  EarthLord
//
//  MKMapView 的 SwiftUI 包装器
//  负责显示地图、应用末世滤镜、处理用户位置更新、自动居中、轨迹渲染
//

import SwiftUI
import MapKit

/// MapKit 地图视图的 SwiftUI 包装器
struct MapViewRepresentable: UIViewRepresentable {

    // MARK: - Bindings

    /// 用户位置（双向绑定）
    @Binding var userLocation: CLLocationCoordinate2D?

    /// 重新居中触发器（计数器，每次点击按钮时递增）
    @Binding var recenterTrigger: Int

    /// 追踪路径坐标数组
    @Binding var trackingPath: [CLLocationCoordinate2D]

    /// 路径更新版本号（触发轨迹重新渲染）
    var pathUpdateVersion: Int

    /// 是否正在追踪
    var isTracking: Bool

    /// 路径是否已闭合
    var isPathClosed: Bool

    /// Day18: 已加载的领地列表
    var territories: [Territory]

    /// Day18: 当前用户 ID
    var currentUserId: String?

    // MARK: - UIViewRepresentable

    /// 创建 MKMapView
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        // 基础配置
        mapView.mapType = .hybrid  // 卫星图 + 道路标签（末世废土风格）
        mapView.pointOfInterestFilter = .excludingAll  // 隐藏所有 POI 标签（餐厅、商店等）
        mapView.showsBuildings = false  // 隐藏 3D 建筑
        mapView.showsUserLocation = true  // ⚠️ 关键：显示用户位置蓝点
        mapView.isZoomEnabled = true  // 允许缩放
        mapView.isScrollEnabled = true  // 允许拖动
        mapView.isRotateEnabled = true  // 允许旋转
        mapView.isPitchEnabled = false  // 禁用倾斜（保持2D视角）

        // ⚠️ 关键：设置代理，否则 didUpdate userLocation 不会被调用
        mapView.delegate = context.coordinator

        // 应用末世滤镜效果
        applyApocalypseFilter(to: mapView)

        print("🗺️ [MapView] 地图初始化完成")

        return mapView
    }

    /// 更新地图视图（处理重新居中和轨迹更新）
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 检测重新居中触发器的变化
        if context.coordinator.lastRecenterTrigger != recenterTrigger {
            context.coordinator.lastRecenterTrigger = recenterTrigger

            // 如果有用户位置，重新居中
            if let location = userLocation {
                print("🎯 [MapView] 触发重新居中到用户位置")

                let region = MKCoordinateRegion(
                    center: location,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )

                mapView.setRegion(region, animated: true)
            }
        }

        // 检测路径更新版本号的变化
        if context.coordinator.lastPathUpdateVersion != pathUpdateVersion {
            context.coordinator.lastPathUpdateVersion = pathUpdateVersion
            updateTrackingPath(on: mapView)
        }

        // 更新 Coordinator 的 isPathClosed 状态（用于渲染颜色）
        context.coordinator.isPathClosed = isPathClosed

        // Day18: 绘制领地（每次更新都重新绘制）
        drawTerritories(on: mapView)
    }

    /// 创建 Coordinator（处理地图回调）
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Apocalypse Filter

    /// 应用末世滤镜效果（泛黄的废土风格）
    private func applyApocalypseFilter(to mapView: MKMapView) {
        // 注意：直接应用 CIFilter 到 layer.filters 可能影响交互
        // 这里使用更轻量的方式：调整 alpha 和 tintColor

        // 降低亮度（通过半透明黑色遮罩）
        let overlay = UIView(frame: mapView.bounds)
        overlay.backgroundColor = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 0.15)
        overlay.isUserInteractionEnabled = false  // ⚠️ 关键：不拦截用户交互
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.tag = 999  // 设置 tag 以便识别
        mapView.addSubview(overlay)

        print("🎨 [MapView] 已应用末世滤镜（轻量版）")
    }

    // MARK: - Path Tracking

    /// 更新追踪路径显示
    private func updateTrackingPath(on mapView: MKMapView) {
        // 移除所有旧的覆盖物（轨迹线 + 多边形）
        let oldOverlays = mapView.overlays
        mapView.removeOverlays(oldOverlays)

        // 如果路径点数少于 2 个，不绘制
        guard trackingPath.count >= 2 else {
            print("📍 [MapView] 路径点数不足 2 个，跳过绘制")
            return
        }

        // ⚠️ 关键：坐标转换（WGS-84 → GCJ-02）
        let gcj02Coordinates = CoordinateConverter.convertCoordinates(trackingPath)

        // 创建轨迹线
        let polyline = MKPolyline(coordinates: gcj02Coordinates, count: gcj02Coordinates.count)
        mapView.addOverlay(polyline)

        // 如果路径已闭合且点数 ≥ 3，绘制多边形填充
        if isPathClosed && trackingPath.count >= 3 {
            let polygon = MKPolygon(coordinates: gcj02Coordinates, count: gcj02Coordinates.count)
            mapView.addOverlay(polygon)
            print("🎨 [MapView] 绘制闭环多边形，点数: \(trackingPath.count)")
        } else {
            print("🎨 [MapView] 绘制轨迹线，点数: \(trackingPath.count)")
        }
    }

    // MARK: - Day18: Territory Drawing

    /// 绘制所有领地（从云端加载的领地）
    private func drawTerritories(on mapView: MKMapView) {
        // 移除旧的领地多边形（保留路径轨迹）
        let territoryOverlays = mapView.overlays.filter { overlay in
            if let polygon = overlay as? MKPolygon {
                return polygon.title == "mine" || polygon.title == "others"
            }
            return false
        }
        mapView.removeOverlays(territoryOverlays)

        // 绘制每个领地
        for territory in territories {
            var coords = territory.toCoordinates()

            // ⚠️ 中国大陆需要坐标转换（WGS-84 → GCJ-02）
            coords = coords.map { coord in
                CoordinateConverter.wgs84ToGcj02(coord)
            }

            guard coords.count >= 3 else { continue }

            let polygon = MKPolygon(coordinates: coords, count: coords.count)

            // ⚠️ 关键：比较 userId 时必须统一大小写！
            // 数据库存的是小写 UUID，但 iOS 的 uuidString 返回大写
            // 如果不转换，会导致自己的领地显示为橙色
            let isMine = territory.userId.lowercased() == currentUserId?.lowercased()
            polygon.title = isMine ? "mine" : "others"

            mapView.addOverlay(polygon, level: .aboveRoads)
        }

        if !territories.isEmpty {
            print("🏠 [MapView] 绘制了 \(territories.count) 个领地")
        }
    }

    // MARK: - Coordinator

    /// 地图视图协调器（处理 MKMapViewDelegate 回调）
    class Coordinator: NSObject, MKMapViewDelegate {

        var parent: MapViewRepresentable

        /// 是否已完成首次自动居中（防止重复居中）
        private var hasInitialCentered = false

        /// 上次的重新居中触发器值
        var lastRecenterTrigger: Int = 0

        /// 上次的路径更新版本号
        var lastPathUpdateVersion: Int = 0

        /// 路径是否已闭合（用于渲染颜色）
        var isPathClosed: Bool = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // MARK: - MKMapViewDelegate

        /// ⭐ 关键方法：用户位置更新时调用
        /// 这是实现地图自动居中的核心方法
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 获取位置坐标
            guard let location = userLocation.location else {
                print("⚠️ [MapView] 用户位置为空")
                return
            }

            print("📍 [MapView] 用户位置更新: (\(location.coordinate.latitude), \(location.coordinate.longitude))")

            // 更新绑定的位置
            DispatchQueue.main.async {
                self.parent.userLocation = location.coordinate
            }

            // 如果已经完成首次居中，不再自动居中（避免打断用户手动拖动）
            guard !hasInitialCentered else {
                return
            }

            // ⭐ 首次获得位置时，自动居中地图
            print("🎯 [MapView] 首次定位成功，地图自动居中")

            // 创建居中区域（约1公里范围）
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,  // 纵向范围（米）
                longitudinalMeters: 1000  // 横向范围（米）
            )

            // 平滑居中地图（动画效果）
            mapView.setRegion(region, animated: true)

            // 标记已完成首次居中
            hasInitialCentered = true
        }

        /// ⚠️ 关键方法：渲染轨迹线和多边形
        /// 如果不实现这个方法，轨迹添加了也看不见！
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // 渲染轨迹线
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                // ⚠️ 根据是否闭环改变颜色
                renderer.strokeColor = isPathClosed ? UIColor.systemGreen : UIColor.cyan
                renderer.lineWidth = 5  // 线宽 5pt
                renderer.lineCap = .round  // 圆头线条
                return renderer
            }

            // 渲染多边形填充
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)

                // Day18: 根据 title 区分不同类型的多边形
                if polygon.title == "mine" {
                    // 我的领地：绿色
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemGreen
                } else if polygon.title == "others" {
                    // 他人领地：橙色
                    renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemOrange
                } else {
                    // 当前圈地轨迹：绿色（默认）
                    renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
                    renderer.strokeColor = UIColor.systemGreen
                }

                renderer.lineWidth = 2  // 边框线宽
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        /// 地图区域改变完成后调用
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // 可用于调试
            // print("🗺️ [MapView] 地图区域改变")
        }

        /// 地图加载完成
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("✅ [MapView] 地图加载完成")
        }
    }
}
