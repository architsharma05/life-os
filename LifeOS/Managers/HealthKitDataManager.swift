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

    func fetchWeeklySummary() async throws -> WeeklyHealthSummary {
        guard HKHealthStore.isHealthDataAvailable() else {
            return WeeklyHealthSummary(days: [])
        }

        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        async let stepsResult = fetchDailySteps(start: start, end: end)
        async let sleepResult = fetchDailySleep(start: start, end: end)
        async let workoutsResult = fetchDailyWorkoutCounts(start: start, end: end)

        let (steps, sleep, workouts) = try await (
            stepsResult,
            sleepResult,
            workoutsResult
        )

        let days = (0..<7).compactMap { offset -> DailyHealthTrend? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let day = calendar.startOfDay(for: date)
            return DailyHealthTrend(
                date: day,
                sleepHours: sleep[day],
                steps: steps[day],
                workoutCount: workouts[day] ?? 0
            )
        }

        return WeeklyHealthSummary(days: days)
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

    private func fetchDailySteps(start: Date, end: Date) async throws -> [Date: Int] {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return [:] }
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        var interval = DateComponents()
        interval.day = 1

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: calendar.startOfDay(for: start),
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var values: [Date: Int] = [:]
                collection?.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let quantity = statistics.sumQuantity() else { return }
                    let day = self.calendar.startOfDay(for: statistics.startDate)
                    values[day] = Int(quantity.doubleValue(for: .count()).rounded())
                }
                continuation.resume(returning: values)
            }
            healthStore.execute(query)
        }
    }

    private func fetchDailySleep(start: Date, end: Date) async throws -> [Date: Double] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [:] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])

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
                var totals: [Date: Double] = [:]

                for sample in samples as? [HKCategorySample] ?? [] where asleepValues.contains(sample.value) {
                    let day = self.calendar.startOfDay(for: sample.endDate)
                    totals[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate) / 3_600
                }

                continuation.resume(returning: totals)
            }
            healthStore.execute(query)
        }
    }

    private func fetchDailyWorkoutCounts(start: Date, end: Date) async throws -> [Date: Int] {
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                var counts: [Date: Int] = [:]
                for sample in samples ?? [] {
                    let day = self.calendar.startOfDay(for: sample.startDate)
                    counts[day, default: 0] += 1
                }
                continuation.resume(returning: counts)
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
