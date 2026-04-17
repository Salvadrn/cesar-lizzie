import Foundation
import HealthKit
import SwiftUI

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    // MARK: - State

    var isAuthorized = false
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // Vitals
    var heartRate: Double?
    var restingHeartRate: Double?
    var bloodOxygen: Double?
    var bloodPressureSystolic: Double?
    var bloodPressureDiastolic: Double?

    // Activity
    var stepsToday: Int = 0
    var activeCaloriesToday: Double = 0
    var exerciseMinutesToday: Double = 0
    var distanceToday: Double = 0 // meters

    // Sleep
    var sleepHoursLastNight: Double?

    // Body
    var weight: Double? // kg
    var height: Double? // cm
    var bmi: Double? {
        guard let w = weight, let h = height, h > 0 else { return nil }
        return w / pow(h / 100, 2)
    }

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.oxygenSaturation),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.bodyMass),
            HKQuantityType(.height),
            HKCategoryType(.sleepAnalysis),
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit auth error: \(error)")
            return false
        }
    }

    // MARK: - Fetch All

    func fetchAll() async {
        guard isAuthorized else { return }

        async let hr = fetchLatestQuantity(.heartRate, unit: .count().unitDivided(by: .minute()))
        async let rhr = fetchLatestQuantity(.restingHeartRate, unit: .count().unitDivided(by: .minute()))
        async let o2 = fetchLatestQuantity(.oxygenSaturation, unit: .percent())
        async let sysBP = fetchLatestQuantity(.bloodPressureSystolic, unit: .millimeterOfMercury())
        async let diaBP = fetchLatestQuantity(.bloodPressureDiastolic, unit: .millimeterOfMercury())
        async let steps = fetchTodaySum(.stepCount, unit: .count())
        async let cals = fetchTodaySum(.activeEnergyBurned, unit: .kilocalorie())
        async let exercise = fetchTodaySum(.appleExerciseTime, unit: .minute())
        async let dist = fetchTodaySum(.distanceWalkingRunning, unit: .meter())
        async let w = fetchLatestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let h = fetchLatestQuantity(.height, unit: .meterUnit(with: .centi))
        async let sleep = fetchSleepLastNight()

        heartRate = await hr
        restingHeartRate = await rhr
        bloodOxygen = await o2.map { $0 * 100 } // convert to percentage
        bloodPressureSystolic = await sysBP
        bloodPressureDiastolic = await diaBP
        stepsToday = await Int(steps ?? 0)
        activeCaloriesToday = await cals ?? 0
        exerciseMinutesToday = await exercise ?? 0
        distanceToday = await dist ?? 0
        weight = await w
        height = await h
        sleepHoursLastNight = await sleep
    }

    // MARK: - Helpers

    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(identifier)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -7, to: Date()), end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchTodaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(identifier)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchSleepLastNight() async -> Double? {
        let type = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let sleepWindowStart = calendar.date(byAdding: .hour, value: -14, to: startOfToday)! // yesterday 10am

        let predicate = HKQuery.predicateForSamples(withStart: sleepWindowStart, end: now)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ]

                let totalSeconds = sleepSamples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                let hours = totalSeconds / 3600
                continuation.resume(returning: hours > 0 ? hours : nil)
            }
            store.execute(query)
        }
    }
}
