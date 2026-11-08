//
//  WatchViewModel.swift
//  watchOS/ViewModels
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class WatchViewModel: ObservableObject {
    @Published var currentScore: Double?
    @Published var currentLevel: StressLevel = .calm
    @Published var currentHRV: Double?
    @Published var baseline: Double?
    @Published var sampleCount: Int = 0
    @Published var recentSnapshots: [StressSnapshot] = []
    @Published var customEmojis: [StressLevel: String] = [:]

    private let health = HealthKitManager.shared
    private var calculator = StressCalculator()

    func onAppear() async {
        do {
            try await health.requestAuthorization()
            await refresh()
            health.startObserving()
        } catch {
            print("HealthKit 授权失败: \(error)")
        }
    }

    func refresh() async {
        do {
            let samples = try await health.fetchHRVHistory(days: 14)
            sampleCount = samples.count

            let result = calculator.calculate(historySamples: samples)
            currentScore = result.score
            currentHRV = result.currentHRV
            baseline = result.baseline

            if let score = result.score {
                currentLevel = StressLevel.from(score: score)
            }

            // 用历史样本重建最近 6h 曲线
            if let base = result.baseline {
                let cutoff = Date().addingTimeInterval(-6 * 3600)
                recentSnapshots = samples.filter { $0.date >= cutoff }.map { s in
                    let dev = (base - s.value) / base * 100.0
                    let score = min(max(50.0 + dev * 2.0, 0.0), 100.0)
                    return StressSnapshot(timestamp: s.date, score: score, hrvSDNN: s.value, baseline: base)
                }
            }
        } catch {
            print("Watch 刷新失败: \(error)")
        }
    }
}
