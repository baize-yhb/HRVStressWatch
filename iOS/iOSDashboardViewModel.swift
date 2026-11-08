//
//  iOSDashboardViewModel.swift
//  iOS/ViewModels
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class iOSDashboardViewModel: ObservableObject {
    @Published var currentScore: Double?
    @Published var currentLevel: StressLevel = .calm
    @Published var currentHRV: Double?
    @Published var baseline: Double?
    @Published var sampleCount: Int = 0
    @Published var recentSnapshots: [StressSnapshot] = []
    @Published var baselineDays: Int = 14 {
        didSet { UserDefaults.standard.set(baselineDays, forKey: "baselineDays") }
    }
    @Published var customEmojis: [StressLevel: String] = [:] {
        didSet { persistEmojis() }
    }
    @Published var healthAuthorized: Bool = false

    private let health = HealthKitManager.shared
    private var calculator = StressCalculator()

    init() {
        // 恢复持久化设置
        let saved = UserDefaults.standard.integer(forKey: "baselineDays")
        if saved > 0 { baselineDays = saved }
        loadEmojis()
    }

    func bootstrap() async {
        do {
            try await health.requestAuthorization()
            healthAuthorized = true
            await refresh()
            health.startObserving(windowDays: baselineDays)
        } catch {
            print("HealthKit 授权失败: \(error)")
        }
    }

    func refresh() async {
        do {
            var cfg = StressCalculator.Config()
            cfg.baselineWindowDays = baselineDays
            calculator.updateConfig(cfg)

            let samples = try await health.fetchHRVHistory(days: baselineDays)
            sampleCount = samples.count

            let result = calculator.calculate(historySamples: samples)
            currentScore = result.score
            currentHRV = result.currentHRV
            baseline = result.baseline

            if let score = result.score {
                currentLevel = StressLevel.from(score: score)
                if let hrv = result.currentHRV, let base = result.baseline {
                    let snap = StressSnapshot(timestamp: Date(), score: score, hrvSDNN: hrv, baseline: base)
                    recentSnapshots.append(snap)
                    // 只保留最近 24h
                    let cutoff = Date().addingTimeInterval(-24 * 3600)
                    recentSnapshots = recentSnapshots.filter { $0.timestamp >= cutoff }
                }
            }

            // 从历史样本填充 24h 曲线（如果本地快照不够）
            if recentSnapshots.count < 5, let base = result.baseline {
                let cutoff = Date().addingTimeInterval(-24 * 3600)
                recentSnapshots = samples.filter { $0.date >= cutoff }.map { s in
                    let dev = (base - s.value) / base * 100.0
                    let score = min(max(50.0 + dev * 2.0, 0.0), 100.0)
                    return StressSnapshot(timestamp: s.date, score: score, hrvSDNN: s.value, baseline: base)
                }
            }
        } catch {
            print("刷新失败: \(error)")
        }
    }

    func emoji(for level: StressLevel) -> String {
        customEmojis[level] ?? level.defaultEmoji
    }

    // MARK: - 表情持久化
    private func persistEmojis() {
        let dict = customEmojis.reduce(into: [String: String]()) { acc, pair in
            acc[String(pair.key.rawValue)] = pair.value
        }
        UserDefaults.standard.set(dict, forKey: "customEmojis")
    }

    private func loadEmojis() {
        guard let dict = UserDefaults.standard.dictionary(forKey: "customEmojis") as? [String: String] else { return }
        customEmojis = dict.reduce(into: [StressLevel: String]()) { acc, pair in
            if let raw = Int(pair.key), let level = StressLevel(rawValue: raw) {
                acc[level] = pair.value
            }
        }
    }
}
