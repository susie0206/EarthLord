//
//  MapViewRepresentable.swift
//  EarthLord
//
//  MKMapView 的 SwiftUI 包装器
//  负责显示地图、应用末世滤镜、处理用户位置更新和自动居中
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

    /// 更新地图视图（处理重新居中）
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

    // MARK: - Coordinator

    /// 地图视图协调器（处理 MKMapViewDelegate 回调）
    class Coordinator: NSObject, MKMapViewDelegate {

        var parent: MapViewRepresentable

        /// 是否已完成首次自动居中（防止重复居中）
        private var hasInitialCentered = false

        /// 上次的重新居中触发器值
        var lastRecenterTrigger: Int = 0

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
