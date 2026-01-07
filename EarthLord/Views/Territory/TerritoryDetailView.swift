//
//  TerritoryDetailView.swift
//  EarthLord
//
//  领地详情页 - 显示领地信息、地图预览、管理功能
//

import SwiftUI
import MapKit

struct TerritoryDetailView: View {

    // MARK: - Properties

    /// 领地数据
    let territory: Territory

    /// 删除回调
    let onDelete: (() -> Void)?

    /// 环境变量：关闭页面
    @Environment(\.dismiss) private var dismiss

    // MARK: - State Properties

    /// 是否显示删除确认
    @State private var showDeleteAlert = false

    /// 是否正在删除
    @State private var isDeleting = false

    /// 领地管理器
    private let territoryManager = TerritoryManager.shared

    /// 地图区域
    @State private var mapRegion: MKCoordinateRegion

    // MARK: - Initialization

    init(territory: Territory, onDelete: (() -> Void)? = nil) {
        self.territory = territory
        self.onDelete = onDelete

        // 计算地图区域
        let coords = territory.toCoordinates()
        let center = coords.isEmpty
            ? CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
            : coords[coords.count / 2]

        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: center,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 地图预览
                    mapPreview

                    // 领地信息卡片
                    territoryInfoCard

                    // 管理操作区
                    managementSection

                    // 未来功能占位
                    futureFeaturesSection
                }
                .padding()
            }
            .background(ApocalypseTheme.background.ignoresSafeArea())
            .navigationTitle("领地详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(isDeleting)
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    Task {
                        await deleteTerritory()
                    }
                }
            } message: {
                Text("确定要删除「\(territory.displayName)」吗？此操作无法撤销。")
            }
        }
    }

    // MARK: - Map Preview

    private var mapPreview: some View {
        Map(coordinateRegion: $mapRegion)
            .frame(height: 300)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Text("地图预览")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding()
                }
                Spacer()
            }
        )
    }

    // MARK: - Territory Info Card

    private var territoryInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("领地信息")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()
            }

            Divider()

            // 名称
            infoRow(icon: "text.quote", label: "名称", value: territory.displayName)

            // 面积
            infoRow(icon: "square.on.square", label: "面积", value: territory.formattedArea)

            // 点数
            if let pointCount = territory.pointCount {
                infoRow(icon: "mappin.circle", label: "路径点数", value: "\(pointCount) 个点")
            }

            // 创建时间
            infoRow(icon: "calendar", label: "创建时间", value: territory.formattedCreatedAt)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Management Section

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("领地管理")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()
            }

            Divider()

            // 删除按钮
            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("删除领地")
                    Spacer()
                    if isDeleting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
            .disabled(isDeleting)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Future Features Section

    private var futureFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Text("未来功能")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()
            }

            Divider()

            // 功能占位
            featurePlaceholder(icon: "pencil", title: "重命名领地", subtitle: "为你的领地起个响亮的名字")
            featurePlaceholder(icon: "building.2", title: "建筑系统", subtitle: "在领地上建造建筑物")
            featurePlaceholder(icon: "arrow.left.arrow.right", title: "领地交易", subtitle: "与其他玩家交易领地")
        }
        .padding()
        .background(ApocalypseTheme.cardBackground.opacity(0.6))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helper Views

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Spacer()
        }
    }

    private func featurePlaceholder(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.7))
            }

            Spacer()

            Text("敬请期待")
                .font(.system(size: 12))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ApocalypseTheme.textSecondary.opacity(0.2))
                .cornerRadius(8)
        }
    }

    // MARK: - Methods

    /// 删除领地
    private func deleteTerritory() async {
        isDeleting = true

        let success = await territoryManager.deleteTerritory(territoryId: territory.id)

        isDeleting = false

        if success {
            // 通知父页面刷新
            onDelete?()
            // 关闭详情页
            dismiss()
        }
    }
}

#Preview {
    TerritoryDetailView(
        territory: Territory(
            id: "test-id",
            userId: "test-user-id",
            name: "测试领地",
            path: [["lat": 31.2304, "lon": 121.4737]],
            area: 1500,
            pointCount: 20,
            isActive: true,
            createdAt: "2025-12-26T10:00:00Z",
            startedAt: nil,
            completedAt: nil
        ),
        onDelete: nil
    )
}
