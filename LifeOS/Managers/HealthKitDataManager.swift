import Foundation
import HealthKit

final class HealthKitDataManager {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(
        healthStore: HKHealthStore = HKHealthStore(),
        calendar: Calendar = .current
    ) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    func fetchTodayHealthData(fallback: HealthData) async throws -> HealthData {
        guard HKHealthStore.isHealthDataAvailable() else { return fallback }

        async let sleepResult = fetchSleepHours()
        async let stepsResult = fetchSteps()
        async let workoutResult = fetchWorkoutCompleted()
        async let heartRateResult = fetchLatestRestingHeartRate()

        let (sleep, steps, workout, heartRate) = try await (
            sleepResult,
            stepsResult,
            workoutResult,
            heartRateResult
        )

        return HealthData(
            sleepHours: sleep ?? fallback.sleepHours,
            steps: steps ?? fallback.steps,
            workoutCompleted: workout,
            restingHeartRate: heartRate ?? fallback.restingHeartRate
        )
    }

    private func fetchSteps() async throws -> Int? {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return nil }
        let value = try await cumulativeQuantity(
            type: stepType,
            unit: .count(),
            start: calendar.startOfDay(for: Date()),
            end: Date()
        )
        return value.map { Int($0.rounded()) }
    }

    private func fetchLatestRestingHeartRate() async throws -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let value = try await latestQuantity(type: type, unit: unit)
        return value.map { Int($0.rounded()) }
    }

    private func fetchWorkoutCompleted() async throws -> Bool {
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: !(samples ?? []).isEmpty)
                }
            }
            healthStore.execute(query)
        }
    }

    private func fetchSleepHours() async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let todayStart = calendar.startOfDay(for: Date())
        let queryStart = calendar.date(byAdding: .hour, value: -12, to: todayStart) ?? todayStart
        let predicate = HKQuery.predicateForSamples(
            withStart: queryStart,
            end: Date(),
            options: []
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]

                let totalSeconds = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                continuation.resume(returning: totalSeconds > 0 ? totalSeconds / 3_600 : nil)
            }
            healthStore.execute(query)
        }
    }

    private func cumulativeQuantity(
        type: HKQuantityType,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(
                        returning: statistics?.sumQuantity()?.doubleValue(for: unit)
                    )
                }
            }
            healthStore.execute(query)
        }
    }

    private func latestQuantity(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let sample = samples?.first as? HKQuantitySample
                    continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
                }
            }
            healthStore.execute(query)
        }
    }
}
