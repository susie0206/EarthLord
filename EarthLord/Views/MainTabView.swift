//
//  MainTabView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject var languageManager = LanguageManager.shared

    // Tab labels
    @State private var mapTabLabel: String = ""
    @State private var territoryTabLabel: String = ""
    @State private var profileTabLabel: String = ""
    @State private var moreTabLabel: String = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            MapTabView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text(mapTabLabel)
                }
                .tag(0)

            TerritoryTabView()
                .tabItem {
                    Image(systemName: "flag.fill")
                    Text(territoryTabLabel)
                }
                .tag(1)

            ProfileTabView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text(profileTabLabel)
                }
                .tag(2)

            MoreTabView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text(moreTabLabel)
                }
                .tag(3)
        }
        .tint(ApocalypseTheme.primary)
        .onAppear {
            updateTabLabels()
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            updateTabLabels()
        }
    }

    private func updateTabLabels() {
        mapTabLabel = languageManager.localizedString(forKey: "地图")
        territoryTabLabel = languageManager.localizedString(forKey: "领地")
        profileTabLabel = languageManager.localizedString(forKey: "个人")
        moreTabLabel = languageManager.localizedString(forKey: "更多")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
