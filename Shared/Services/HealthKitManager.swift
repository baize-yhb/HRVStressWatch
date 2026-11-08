//
//  HealthKitManager.swift
//  Shared/Services
//

import Foundation
import HealthKit
import Combine

@MainActor
public final class HealthKitManager: ObservableObject {

    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private let hrvType = HKQuantityType(.heartRateVariabilitySDNN)

    @Published public var isAuthorized: Bool = false
    @Published public var latestSamples: [(date: Date, value: Double)] = []
    @Published public var lastError: String?

    private var observerQuery: HKObserverQuery?

    private init() {}

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "该设备不支持 HealthKit"
            throw NSError(domain: "HRVStressWatch", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available"])
        }
        let readTypes: Set<HKObjectType> = [hrvType]
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    public func fetchHRVHistory(days: Int = 14) async throws -> [(date: Date, value: Double)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let results: [(Date, Double)] = (samples as? [HKQuantitySample])?.map { sample in
                    let value = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                    return (sample.endDate, value)
                } ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }

    public func startObserving(windowDays: Int = 14) {
        observerQuery = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completionHandler, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let error = error {
                    self.lastError = error.localizedDescription
                } else {
                    try? await self.refreshSamples(windowDays: windowDays)
                }
                completionHandler()
            }
        }
        if let q = observerQuery { healthStore.execute(q) }
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { _, _ in }
    }

    public func stopObserving() {
        if let q = observerQuery { healthStore.stop(q) }
        observerQuery = nil
        healthStore.disableAllBackgroundDelivery { _, _ in }
    }

    public func refreshSamples(windowDays: Int = 14) async throws {
        let samples = try await fetchHRVHistory(days: windowDays)
        latestSamples = samples
    }
}
