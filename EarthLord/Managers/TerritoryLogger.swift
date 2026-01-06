//
//  TerritoryLogger.swift
//  EarthLord
//
//  圈地日志管理器 - 在 App 内显示调试日志
//

import Foundation
import Combine

// MARK: - LogType 枚举

/// 日志类型
enum LogType: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
}

// MARK: - LogEntry 结构

/// 日志条目
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
}

// MARK: - TerritoryLogger

/// 圈地日志管理器（单例模式 + ObservableObject）
final class TerritoryLogger: ObservableObject {

    // MARK: - Singleton

    /// 全局单例
    static let shared = TerritoryLogger()

    // MARK: - Published Properties

    /// 日志数组
    @Published var logs: [LogEntry] = []

    /// 格式化的日志文本（用于显示）
    @Published var logText: String = ""

    // MARK: - Private Properties

    /// 最大日志条数（防止内存溢出）
    private let maxLogCount = 200

    /// 显示格式的日期格式化器
    private let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// 导出格式的日期格式化器
    private let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        // 私有初始化，确保单例
    }

    // MARK: - Public Methods

    /// 添加日志
    func log(_ message: String, type: LogType = .info) {
        // 确保在主线程更新 UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let entry = LogEntry(timestamp: Date(), message: message, type: type)

            // 添加到数组
            self.logs.append(entry)

            // 限制最大条数
            if self.logs.count > self.maxLogCount {
                self.logs.removeFirst(self.logs.count - self.maxLogCount)
            }

            // 更新显示文本
            self.updateLogText()
        }

        // 同时输出到控制台（方便 Xcode 调试）
        let prefix: String
        switch type {
        case .info: prefix = "📝"
        case .success: prefix = "✅"
        case .warning: prefix = "⚠️"
        case .error: prefix = "❌"
        }
        print("\(prefix) [Territory] \(message)")
    }

    /// 清空所有日志
    func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
            self?.logText = ""
        }
    }

    /// 导出日志为文本
    func export() -> String {
        guard !logs.isEmpty else {
            return "暂无日志记录"
        }

        let lines = logs.map { entry in
            let timestamp = exportDateFormatter.string(from: entry.timestamp)
            return "[\(timestamp)] [\(entry.type.rawValue)] \(entry.message)"
        }

        return """
        === 圈地功能测试日志 ===
        导出时间: \(exportDateFormatter.string(from: Date()))
        日志条数: \(logs.count)

        \(lines.joined(separator: "\n"))
        """
    }

    // MARK: - Private Methods

    /// 更新显示文本
    private func updateLogText() {
        let lines = logs.map { entry in
            let timestamp = displayDateFormatter.string(from: entry.timestamp)
            return "[\(timestamp)] [\(entry.type.rawValue)] \(entry.message)"
        }
        logText = lines.joined(separator: "\n")
    }
}
