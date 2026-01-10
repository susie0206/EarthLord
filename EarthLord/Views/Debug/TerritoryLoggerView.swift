//
//  TerritoryLoggerView.swift
//  EarthLord
//
//  圈地日志查看器 - 在 App 内查看调试日志
//

import SwiftUI

struct TerritoryLoggerView: View {

    // MARK: - Observed Objects

    @ObservedObject private var logger = TerritoryLogger.shared

    // MARK: - State Properties

    /// 是否显示分享菜单
    @State private var showShareSheet = false

    /// 导出的日志文本
    @State private var exportedLogText = ""

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbarSection

            // 日志列表
            if logger.logs.isEmpty {
                emptyStateView
            } else {
                logListView
            }
        }
        .background(ApocalypseTheme.background.ignoresSafeArea())
        .navigationTitle("圈地日志")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [exportedLogText])
        }
    }

    // MARK: - Subviews

    /// 工具栏
    private var toolbarSection: some View {
        HStack(spacing: 16) {
            // 日志数量
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Text("\(logger.logs.count) 条日志")
                    .font(.system(size: 14))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }

            Spacer()

            // 导出按钮
            Button {
                exportedLogText = logger.export()
                showShareSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("导出")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ApocalypseTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ApocalypseTheme.primary.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(logger.logs.isEmpty)

            // 清空按钮
            Button {
                logger.clear()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("清空")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(logger.logs.isEmpty)
        }
        .padding()
        .background(ApocalypseTheme.cardBackground)
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.5))

            Text("暂无日志")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("开始圈地后，日志会显示在这里")
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.7))

            Spacer()
        }
    }

    /// 日志列表
    private var logListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(logger.logs) { entry in
                        logEntryRow(entry)
                            .id(entry.id)
                    }
                }
                .padding()
            }
            .onChange(of: logger.logs.count) { _ in
                // 自动滚动到最新日志
                if let lastLog = logger.logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    /// 单条日志
    private func logEntryRow(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 图标
            logTypeIcon(entry.type)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                // 时间戳
                Text(formatTime(entry.timestamp))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(ApocalypseTheme.textSecondary)

                // 消息内容
                Text(entry.message)
                    .font(.system(size: 14))
                    .foregroundColor(logTypeColor(entry.type))
            }

            Spacer()
        }
        .padding(12)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(8)
    }

    /// 日志类型图标
    private func logTypeIcon(_ type: LogType) -> some View {
        let (icon, color): (String, Color) = {
            switch type {
            case .info:
                return ("info.circle.fill", .blue)
            case .success:
                return ("checkmark.circle.fill", .green)
            case .warning:
                return ("exclamationmark.triangle.fill", .orange)
            case .error:
                return ("xmark.circle.fill", .red)
            }
        }()

        return Image(systemName: icon)
            .foregroundColor(color)
    }

    /// 日志类型颜色
    private func logTypeColor(_ type: LogType) -> Color {
        switch type {
        case .info:
            return ApocalypseTheme.textPrimary
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    /// 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        TerritoryLoggerView()
    }
}
