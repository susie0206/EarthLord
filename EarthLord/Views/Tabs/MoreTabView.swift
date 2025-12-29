//
//  MoreTabView.swift
//  EarthLord
//
//  Created by 快乐一家人 on 2025/12/25.
//

import SwiftUI

struct MoreTabView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: SupabaseTestView()) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Supabase 连接测试")
                                    .font(.body)
                                Text("测试数据库连接状态")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("开发工具")
                }

                Section {
                    PlaceholderView(
                        icon: "ellipsis",
                        title: "更多功能",
                        subtitle: "即将推出"
                    )
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("其他功能")
                }
            }
            .navigationTitle("更多")
        }
    }
}

#Preview {
    MoreTabView()
}
