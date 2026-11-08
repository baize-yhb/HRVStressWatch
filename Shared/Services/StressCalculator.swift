//
//  StressCalculator.swift
//  Shared/Services
//

import Foundation

public final class StressCalculator {

    public struct Config {
        public var baselineWindowDays: Int = 14
        public var currentWindowMinutes: Int = 30
        public var fallbackBaseline: Double = 40.0
        public var minSamplesForBaseline: Int = 20
        public var multiplier: Double = 2.0
        public init() {}
    }

    public struct Result {
        public var score: Double?
        public var baseline: Double?
        public var currentHRV: Double?
        public var isLearning: Bool
        public var sampleCount: Int
    }

    private var config: Config

    public init(config: Config = Config()) {
        self.config = config
    }

    public func updateConfig(_ newConfig: Config) {
        self.config = newConfig
    }

    public func calculate(
        historySamples: [(date: Date, value: Double)],
        now: Date = Date()
    ) -> Result {
        guard !historySamples.isEmpty else {
            return Result(score: nil, baseline: nil, currentHRV: nil, isLearning: true, sampleCount: 0)
        }

        let allValues = historySamples.map { $0.value }.sorted()
        let baseline: Double
        let isLearning: Bool

        if allValues.count < config.minSamplesForBaseline {
            baseline = config.fallbackBaseline
        } else {
            baseline = median(allValues)
        }
        isLearning = allValues.count < config.minSamplesForBaseline

        let windowStart = now.addingTimeInterval(-Double(config.currentWindowMinutes * 60))
        let recentSamples = historySamples.filter { $0.date >= windowStart }
        let currentHRV: Double
        if recentSamples.isEmpty {
            guard let latest = historySamples.max(by: { $0.date < $1.date }) else {
                return Result(score: nil, baseline: baseline, currentHRV: nil, isLearning: true, sampleCount: allValues.count)
            }
            currentHRV = latest.value
        } else {
            currentHRV = recentSamples.map { $0.value }.reduce(0, +) / Double(recentSamples.count)
        }

        if isLearning {
            return Result(score: nil, baseline: baseline, currentHRV: currentHRV, isLearning: true, sampleCount: allValues.count)
        }

        guard baseline > 0 else {
            return Result(score: nil, baseline: baseline, currentHRV: currentHRV, isLearning: true, sampleCount: allValues.count)
        }
        let deviation = (baseline - currentHRV) / baseline * 100.0
        let rawScore = 50.0 + deviation * config.multiplier
        let score = min(max(rawScore, 0.0), 100.0)

        return Result(score: score, baseline: baseline, currentHRV: currentHRV, isLearning: false, sampleCount: allValues.count)
    }

    private func median(_ sortedValues: [Double]) -> Double {
        let n = sortedValues.count
        guard n > 0 else { return 0 }
        if n % 2 == 1 {
            return sortedValues[n / 2]
        } else {
            return (sortedValues[n / 2 - 1] + sortedValues[n / 2]) / 2.0
        }
    }
}
