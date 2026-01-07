//
//  TerritoryTabView.swift
//  EarthLord
//
//  领地Tab - 显示和管理我的领地列表
//

import SwiftUI

struct TerritoryTabView: View {

    // MARK: - State Objects

    /// 领地管理器
    private let territoryManager = TerritoryManager.shared

    // MARK: - State Properties

    /// 我的领地列表
    @State private var myTerritories: [Territory] = []

    /// 选中的领地（用于显示详情）
    @State private var selectedTerritory: Territory?

    /// 是否正在加载
    @State private var isLoading = false

    /// 是否正在刷新
    @State private var isRefreshing = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                ApocalypseTheme.background
                    .ignoresSafeArea()

                if isLoading {
                    // 加载状态
                    loadingView
                } else if myTerritories.isEmpty {
                    // 空状态
                    emptyStateView
                } else {
                    // 领地列表
                    territoryListView
                }
            }
            .navigationTitle("我的领地")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadMyTerritories()
                }
            }
            .sheet(item: $selectedTerritory) { territory in
                TerritoryDetailView(
                    territory: territory,
                    onDelete: {
                        Task {
                            await loadMyTerritories()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ApocalypseTheme.primary)

            Text("加载领地中...")
                .font(.system(size: 16))
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "flag.slash")
                .font(.system(size: 64))
                .foregroundColor(ApocalypseTheme.textSecondary)

            VStack(spacing: 8) {
                Text("还没有领地")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text("前往地图页面开始圈地吧！")
                    .font(.system(size: 14))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Territory List View

    private var territoryListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计信息卡片
                statisticsCard

                // 领地列表
                ForEach(myTerritories) { territory in
                    territoryCard(territory)
                        .onTapGesture {
                            selectedTerritory = territory
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await loadMyTerritories()
        }
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text("领地统计")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()
            }

            HStack(spacing: 0) {
                // 领地数量
                VStack(spacing: 8) {
                    Text("\(myTerritories.count)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ApocalypseTheme.primary)

                    Text("领地数量")
                        .font(.system(size: 12))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 50)
                    .background(ApocalypseTheme.textSecondary.opacity(0.3))

                // 总面积
                VStack(spacing: 8) {
                    Text(formattedTotalArea)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ApocalypseTheme.primary)

                    Text("总面积")
                        .font(.system(size: 12))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Territory Card

    private func territoryCard(_ territory: Territory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(ApocalypseTheme.primary)

                Text(territory.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            // 信息栏
            HStack(spacing: 16) {
                // 面积
                HStack(spacing: 4) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 12))
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    Text(territory.formattedArea)
                        .font(.system(size: 14))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }

                // 点数
                if let pointCount = territory.pointCount {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 12))
                            .foregroundColor(ApocalypseTheme.textSecondary)

                        Text("\(pointCount) 个点")
                            .font(.system(size: 14))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }

                Spacer()
            }

            // 时间
            Text(territory.formattedCreatedAt)
                .font(.system(size: 12))
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helper Properties

    /// 格式化总面积
    private var formattedTotalArea: String {
        let totalArea = myTerritories.reduce(0) { $0 + $1.area }
        if totalArea >= 1_000_000 {
            return String(format: "%.2f km²", totalArea / 1_000_000)
        } else {
            return String(format: "%.0f m²", totalArea)
        }
    }

    // MARK: - Methods

    /// 加载我的领地
    private func loadMyTerritories() async {
        isLoading = true

        do {
            myTerritories = try await territoryManager.loadMyTerritories()
            print("✅ [TerritoryTabView] 加载了 \(myTerritories.count) 个我的领地")
        } catch {
            print("❌ [TerritoryTabView] 加载失败：\(error.localizedDescription)")
        }

        isLoading = false
    }
}

#Preview {
    TerritoryTabView()
}
