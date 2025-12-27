//
//  UserProfile.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var createdAt: Date
    var lastUpdated: Date
    
    // Macro Targets
    var targetProtein: Double // grams
    var targetCarbs: Double // grams
    var targetFat: Double // grams
    var targetCalories: Double
    
    // Bio Metrics
    var bodyWeight: Double? // pounds
    var heightInches: Double?
    var age: Int?
    var biologicalSex: BiologicalSex?
    
    // Goals
    var sleepGoalHours: Double
    var activityLevel: ActivityLevel
    var primaryGoal: FitnessGoal
    
    // Preferences
    var preferredWeightUnit: WeightUnit
    var useMetricSystem: Bool
    
    @Relationship(deleteRule: .cascade)
    var workouts: [Workout]?
    
    @Relationship(deleteRule: .cascade)
    var dailySummaries: [DailySummary]?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        lastUpdated: Date = Date(),
        targetProtein: Double = 150.0,
        targetCarbs: Double = 200.0,
        targetFat: Double = 65.0,
        targetCalories: Double = 2200.0,
        bodyWeight: Double? = nil,
        heightInches: Double? = nil,
        age: Int? = nil,
        biologicalSex: BiologicalSex? = nil,
        sleepGoalHours: Double = 7.5,
        activityLevel: ActivityLevel = .moderate,
        primaryGoal: FitnessGoal = .muscleGain,
        preferredWeightUnit: WeightUnit = .pounds,
        useMetricSystem: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.targetCalories = targetCalories
        self.bodyWeight = bodyWeight
        self.heightInches = heightInches
        self.age = age
        self.biologicalSex = biologicalSex
        self.sleepGoalHours = sleepGoalHours
        self.activityLevel = activityLevel
        self.primaryGoal = primaryGoal
        self.preferredWeightUnit = preferredWeightUnit
        self.useMetricSystem = useMetricSystem
    }
    
    /// Calculate protein target based on bodyweight (if available)
    /// Standard recommendation: 0.8-1.0g per lb for muscle gain
    func calculateProteinTarget(multiplier: Double = 0.9) -> Double? {
        guard let bodyWeight = bodyWeight else { return nil }
        return bodyWeight * multiplier
    }
    
    /// Calculate BMR using Mifflin-St Jeor equation
    func calculateBMR() -> Double? {
        guard let bodyWeight = bodyWeight,
              let heightInches = heightInches,
              let age = age,
              let biologicalSex = biologicalSex else {
            return nil
        }
        
        // Convert to metric for calculation
        let weightKg = bodyWeight * 0.453592
        let heightCm = heightInches * 2.54
        
        let bmr: Double
        if biologicalSex == .male {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        } else {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        }
        
        return bmr * activityLevel.multiplier
    }
}

// MARK: - Supporting Enums

enum BiologicalSex: String, Codable {
    case male
    case female
    case other
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive = "very_active"
    
    var displayName: String {
        switch self {
        case .veryActive: return "Very Active"
        default: return rawValue.capitalized
        }
    }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case muscleGain = "muscle_gain"
    case fatLoss = "fat_loss"
    case maintenance
    case athleticPerformance = "athletic_performance"
    case generalHealth = "general_health"
    
    var displayName: String {
        switch self {
        case .muscleGain: return "Muscle Gain"
        case .fatLoss: return "Fat Loss"
        case .athleticPerformance: return "Athletic Performance"
        case .generalHealth: return "General Health"
        default: return rawValue.capitalized
        }
    }
}

enum WeightUnit: String, Codable {
    case pounds = "lbs"
    case kilograms = "kg"
    
    var displayName: String {
        rawValue
    }
}

