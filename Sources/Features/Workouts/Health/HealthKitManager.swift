import Foundation

struct HealthImportedData: Codable {
    var importedAt: Date
    var steps: Int
    var caloriesBurned: Double
    var workouts: Int
    var latestWeightKg: Double?
    var averageHeartRate: Double?

    static let empty = HealthImportedData(
        importedAt: Date(),
        steps: 0,
        caloriesBurned: 0,
        workouts: 0,
        latestWeightKg: nil,
        averageHeartRate: nil
    )
}

#if canImport(HealthKit)
#if canImport(HealthKit)
import HealthKit
#endif

final class HealthKitManager {
    private let store = HKHealthStore()

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let ids: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .bodyMass,
            .heartRate
        ]

        let quantityTypes = ids.compactMap(HKObjectType.quantityType)
        let readTypes: Set<HKObjectType> = Set(quantityTypes + [HKObjectType.workoutType()])

        return await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: [], read: readTypes) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    func fetchLatestHeartRate() async -> Double? {
        await readLatest(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchHealthData() async -> HealthImportedData {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Date()

        let steps = Int(await readSum(.stepCount, unit: HKUnit.count(), start: start, end: end))
        let calories = await readSum(.activeEnergyBurned, unit: HKUnit.kilocalorie(), start: start, end: end)
        let workouts = await readWorkoutCount(start: start, end: end)
        let weight = await readLatest(.bodyMass, unit: HKUnit.gramUnit(with: .kilo))
        let heartRate = await readAverage(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)

        return HealthImportedData(
            importedAt: Date(),
            steps: steps,
            caloriesBurned: calories,
            workouts: workouts,
            latestWeightKg: weight,
            averageHeartRate: heartRate
        )
    }

    private func readSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func readAverage(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func readLatest(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func readWorkoutCount(start: Date, end: Date) async -> Int {
        let type = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: samples?.count ?? 0)
            }
            store.execute(query)
        }
    }
}

#else

final class HealthKitManager {
    func requestAuthorization() async -> Bool { false }
    func fetchHealthData() async -> HealthImportedData { .empty }
    func fetchLatestHeartRate() async -> Double? { nil }
}

#endif
