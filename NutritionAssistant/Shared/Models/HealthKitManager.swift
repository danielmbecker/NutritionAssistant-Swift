import Foundation
import HealthKit
import Observation

@Observable
class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    var isAuthorized: Bool = false
    
    // Data points requested
    var totalSteps: Double = 0.0
    var activeEnergyBurned: Double = 0.0
    var basalEnergyBurned: Double = 0.0
    var exerciseCalories: Double = 0.0
    
    var totalBurnedEnergy: Double {
        return activeEnergyBurned + basalEnergyBurned
    }
    
    // Historical Averages
    var latestBMR: Double = 0.0
    var tdeeYesterday: Double = 0.0
    var tdeeLastWeekAverage: Double = 0.0
    var tdeeLastMonthAverage: Double = 0.0
    var tdeeLast90DaysAverage: Double = 0.0
    
    private init() { }
    
    /// Requests user authorization to read and share HealthKit data.
    func requestAuthorization(customWindowEnabled: Bool = false, startHour: Int = 0) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        guard let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalEnergy = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return
        }
        
        let workoutType = HKObjectType.workoutType()
        
        let typesToRead: Set<HKObjectType> = [stepCount, activeEnergy, basalEnergy, workoutType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    self.fetchAllData(customWindowEnabled: customWindowEnabled, startHour: startHour)
                } else if let error = error {
                    print("Error requesting HealthKit authorization: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Fetches all relevant HealthKit data for today.
    func fetchAllData(customWindowEnabled: Bool = false, startHour: Int = 0) {
        guard isAuthorized else { return }
        
        let now = Date()
        let startDate: Date
        
        if customWindowEnabled {
            startDate = now.healthKitWindowStart(startHour: startHour)
        } else {
            startDate = Calendar.current.startOfDay(for: now)
        }
        
        fetchTotalSteps(since: startDate)
        fetchActiveEnergy(since: startDate)
        fetchBasalEnergy(since: startDate)
        fetchExerciseCalories(since: startDate)
        
        fetchHistoricalAverages()
    }
    
    // MARK: - Fetch Methods
    
    private func fetchTotalSteps(since startDate: Date) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let steps = sum.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    self.totalSteps = steps
                }
            } else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergy(since startDate: Date) {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let kcal = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.activeEnergyBurned = kcal
                }
            } else {
                print("Failed to fetch active energy: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBasalEnergy(since startDate: Date) {
        guard let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return }
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: basalEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let sum = result?.sumQuantity() {
                let kcal = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.basalEnergyBurned = kcal
                }
            } else {
                print("Failed to fetch basal energy: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchExerciseCalories(since startDate: Date) {
        let workoutType = HKObjectType.workoutType()
        
        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Failed to fetch workouts: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
            
            let totalWorkoutCalories = workouts.compactMap { workout -> Double? in
                return workout.statistics(for: activeEnergyType)?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
            }.reduce(0, +)
            
            DispatchQueue.main.async {
                self.exerciseCalories = totalWorkoutCalories
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Historical Fetch Methods
    
    func fetchHistoricalAverages() {
        guard isAuthorized else { return }
        
        // 1. Fetch Latest BMR (usually just today's basal energy projected, or a single day)
        fetchAverageEnergy(forDays: 1, isBMR: true) { bmr in
            DispatchQueue.main.async { self.latestBMR = bmr }
        }
        
        // 2. Fetch TDEE Yesterday (1 day ago)
        fetchAverageEnergy(forDays: 1, offsetDays: 1, isBMR: false) { tdee in
            DispatchQueue.main.async { self.tdeeYesterday = tdee }
        }
        
        // 3. Fetch TDEE Last Week (7 days)
        fetchAverageEnergy(forDays: 7, isBMR: false) { avg in
            DispatchQueue.main.async { self.tdeeLastWeekAverage = avg }
        }
        
        // 4. Fetch TDEE Last Month (30 days)
        fetchAverageEnergy(forDays: 30, isBMR: false) { avg in
            DispatchQueue.main.async { self.tdeeLastMonthAverage = avg }
        }
        
        // 5. Fetch TDEE Last 90 Days
        fetchAverageEnergy(forDays: 90, isBMR: false) { avg in
            DispatchQueue.main.async { self.tdeeLast90DaysAverage = avg }
        }
    }
    
    private func fetchAverageEnergy(forDays days: Int, offsetDays: Int = 0, isBMR: Bool, completion: @escaping (Double) -> Void) {
        guard let activeType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            completion(0.0)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Offset the start date backward by `offsetDays`
        guard let endDate = calendar.date(byAdding: .day, value: -offsetDays, to: now),
              let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            completion(0.0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // If we only want BMR, we only fetch basal energy
        let typesToFetch = isBMR ? [basalType] : [basalType, activeType]
        let group = DispatchGroup()
        
        // We use a statistics collection query to get daily sums, so we can correctly average them
        var dailySums: [Date: Double] = [:]
        let lock = NSLock()
        
        for type in typesToFetch {
            group.enter()
            
            var interval = DateComponents()
            interval.day = 1
            
            let anchorDate = calendar.startOfDay(for: startDate)
            
            let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: interval)
            
            query.initialResultsHandler = { _, results, error in
                guard let statsCollection = results, error == nil else {
                    group.leave()
                    return
                }
                
                statsCollection.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        let kcal = sum.doubleValue(for: HKUnit.kilocalorie())
                        let day = calendar.startOfDay(for: stats.startDate)
                        
                        lock.lock()
                        dailySums[day, default: 0.0] += kcal
                        lock.unlock()
                    }
                }
                group.leave()
            }
            healthStore.execute(query)
        }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            // Calculate the average across the days that actually had data
            let sums = dailySums.values.filter { $0 > 0 }
            if sums.isEmpty {
                completion(0.0)
            } else {
                let total = sums.reduce(0, +)
                let average = total / Double(days) // Dividing by total days requested to create a true rolling average
                completion(average)
            }
        }
    }
}
