//
//  HealthKitManager.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import HealthKit

@Observable
final class HealthKitManager {
    private let healthStore = HKHealthStore()
    
    var isAuthorized = false
    var lastSyncDate: Date?
    
    // Cached data
    var latestBodyWeight: Double?
    var todaySleepHours: Double?
    var todayActiveCalories: Double?
    var todaySteps: Int?
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    static var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization for HealthKit data types
    func requestAuthorization() async throws {
        guard Self.isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        
        isAuthorized = true
    }
    
    private func checkAuthorizationStatus() {
        guard Self.isHealthKitAvailable else { return }
        
        // Check if we have authorization for body mass as a proxy
        if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            let status = healthStore.authorizationStatus(for: bodyMassType)
            isAuthorized = status == .sharingAuthorized
        }
    }
    
    // MARK: - Body Weight
    
    /// Fetch the most recent body weight
    func fetchBodyWeight() async throws -> Double? {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching body weight: \(error)")
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let weightInPounds = sample.quantity.doubleValue(for: .pound())
                Task { @MainActor in
                    self.latestBodyWeight = weightInPounds
                }
            }
        }
        
        healthStore.execute(query)
        
        // Wait for result
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return latestBodyWeight
    }
    
    /// Save body weight to HealthKit
    func saveBodyWeight(_ pounds: Double, date: Date = Date()) async throws {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let quantity = HKQuantity(unit: .pound(), doubleValue: pounds)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
        latestBodyWeight = pounds
    }
    
    // MARK: - Sleep
    
    /// Fetch sleep hours for a specific date
    func fetchSleep(for date: Date) async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var totalSleepSeconds: TimeInterval = 0
                
                for sample in samples {
                    // Only count asleep states (not in bed)
                    if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                let sleepHours = totalSleepSeconds / 3600.0
                
                Task { @MainActor in
                    if calendar.isDateInToday(date) {
                        self.todaySleepHours = sleepHours
                    }
                }
                
                continuation.resume(returning: sleepHours > 0 ? sleepHours : nil)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Active Calories
    
    /// Fetch active calories burned for a specific date
    func fetchActiveCalories(for date: Date) async throws -> Double? {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let sum = statistics?.sumQuantity() {
                    let calories = sum.doubleValue(for: .kilocalorie())
                    
                    Task { @MainActor in
                        if calendar.isDateInToday(date) {
                            self.todayActiveCalories = calories
                        }
                    }
                    
                    continuation.resume(returning: calories)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Steps
    
    /// Fetch step count for a specific date
    func fetchSteps(for date: Date) async throws -> Int? {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let sum = statistics?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: .count()))
                    
                    Task { @MainActor in
                        if calendar.isDateInToday(date) {
                            self.todaySteps = steps
                        }
                    }
                    
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // MARK: - Batch Sync
    
    /// Sync all health data for today
    func syncTodaysData() async throws {
        let today = Date()
        
        async let weight = try? fetchBodyWeight()
        async let sleep = try? fetchSleep(for: today)
        async let calories = try? fetchActiveCalories(for: today)
        async let steps = try? fetchSteps(for: today)
        
        let (weightResult, sleepResult, caloriesResult, stepsResult) = await (weight, sleep, calories, steps)
        
        latestBodyWeight = weightResult
        todaySleepHours = sleepResult
        todayActiveCalories = caloriesResult
        todaySteps = stepsResult
        
        lastSyncDate = Date()
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .typeNotAvailable:
            return "Requested health data type is not available"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}

