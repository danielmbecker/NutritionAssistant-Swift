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
}
