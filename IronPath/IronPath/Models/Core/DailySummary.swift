//
//  DailySummary.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class DailySummary {
    var id: UUID
    var date: Date
    
    // Nutrition Totals (cached for performance)
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var totalFiber: Double
    
    // Workout Totals
    var totalWorkoutVolume: Double
    var totalWorkoutDuration: Int // seconds
    var workoutCount: Int
    var averageWorkoutRPE: Double?
    
    // HealthKit Data
    var sleepHours: Double?
    var activeCalories: Double?
    var steps: Int?
    var bodyWeight: Double?
    
    // Integration Engine Output
    var recoveryScore: Double
    var volumePercentile: Double? // Compared to user's history
    var calorieDeficitSurplus: Double? // Compared to target
    
    @Relationship(deleteRule: .nullify, inverse: \UserProfile.dailySummaries)
    var userProfile: UserProfile?
    
    @Relationship(deleteRule: .cascade)
    var loggedFoods: [LoggedFood]?
    
    init(
        id: UUID = UUID(),
        date: Date,
        totalCalories: Double = 0,
        totalProtein: Double = 0,
        totalCarbs: Double = 0,
        totalFat: Double = 0,
        totalFiber: Double = 0,
        totalWorkoutVolume: Double = 0,
        totalWorkoutDuration: Int = 0,
        workoutCount: Int = 0,
        averageWorkoutRPE: Double? = nil,
        sleepHours: Double? = nil,
        activeCalories: Double? = nil,
        steps: Int? = nil,
        bodyWeight: Double? = nil,
        recoveryScore: Double = 0,
        volumePercentile: Double? = nil,
        calorieDeficitSurplus: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.totalFiber = totalFiber
        self.totalWorkoutVolume = totalWorkoutVolume
        self.totalWorkoutDuration = totalWorkoutDuration
        self.workoutCount = workoutCount
        self.averageWorkoutRPE = averageWorkoutRPE
        self.sleepHours = sleepHours
        self.activeCalories = activeCalories
        self.steps = steps
        self.bodyWeight = bodyWeight
        self.recoveryScore = recoveryScore
        self.volumePercentile = volumePercentile
        self.calorieDeficitSurplus = calorieDeficitSurplus
    }
    
    /// Recalculate nutrition totals from logged foods
    func recalculateNutritionTotals() {
        guard let loggedFoods = loggedFoods else {
            totalCalories = 0
            totalProtein = 0
            totalCarbs = 0
            totalFat = 0
            totalFiber = 0
            return
        }
        
        totalCalories = loggedFoods.reduce(0) { $0 + $1.calories }
        totalProtein = loggedFoods.reduce(0) { $0 + $1.protein }
        totalCarbs = loggedFoods.reduce(0) { $0 + $1.carbs }
        totalFat = loggedFoods.reduce(0) { $0 + $1.fat }
        totalFiber = 0 // Would need to store fiber in LoggedFood
    }
    
    /// Calculate remaining macros vs targets
    func remainingMacros(profile: UserProfile) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        return (
            calories: profile.targetCalories - totalCalories,
            protein: profile.targetProtein - totalProtein,
            carbs: profile.targetCarbs - totalCarbs,
            fat: profile.targetFat - totalFat
        )
    }
    
    /// Check if nutrition goals were met
    func didMeetNutritionGoals(profile: UserProfile, tolerance: Double = 0.05) -> Bool {
        let proteinRatio = totalProtein / profile.targetProtein
        let calorieRatio = totalCalories / profile.targetCalories
        
        return proteinRatio >= (1.0 - tolerance) &&
               calorieRatio >= (1.0 - tolerance) &&
               calorieRatio <= (1.0 + tolerance)
    }
    
    /// Check if workout was completed
    var didWorkout: Bool {
        return workoutCount > 0
    }
    
    /// Check if sleep goal was met
    func didMeetSleepGoal(profile: UserProfile) -> Bool {
        guard let sleepHours = sleepHours else { return false }
        return sleepHours >= profile.sleepGoalHours
    }
}

