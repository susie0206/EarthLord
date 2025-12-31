//
//  PlaceholderView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/25.
//

import SwiftUI

/// 通用占位视图
struct PlaceholderView: View {
    let icon: String
    let titleKey: String
    let subtitleKey: String

    var body: some View {
        ZStack {
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(ApocalypseTheme.primary)

                LocalizedText(titleKey)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ApocalypseTheme.textPrimary)

                LocalizedText(subtitleKey)
                    .font(.subheadline)
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
    }
}

#Preview {
    PlaceholderView(
        icon: "map.fill",
        titleKey: "地图",
        subtitleKey: "探索和圈占领地"
    )
}
