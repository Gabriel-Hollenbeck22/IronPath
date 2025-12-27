//
//  LoggedFood.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class LoggedFood {
    var id: UUID
    var servingSizeGrams: Double
    var loggedAt: Date
    var mealType: MealType
    var notes: String?
    
    // Cached macros for this specific logged portion
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem?
    
    @Relationship(deleteRule: .nullify)
    var recipe: Recipe?
    
    @Relationship(deleteRule: .nullify, inverse: \DailySummary.loggedFoods)
    var dailySummary: DailySummary?
    
    init(
        id: UUID = UUID(),
        servingSizeGrams: Double,
        loggedAt: Date = Date(),
        mealType: MealType,
        notes: String? = nil,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.id = id
        self.servingSizeGrams = servingSizeGrams
        self.loggedAt = loggedAt
        self.mealType = mealType
        self.notes = notes
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    /// Convenience initializer from FoodItem
    convenience init(
        foodItem: FoodItem,
        servingSizeGrams: Double,
        mealType: MealType,
        loggedAt: Date = Date()
    ) {
        let macros = foodItem.macrosForServing(servingSizeGrams)
        self.init(
            servingSizeGrams: servingSizeGrams,
            loggedAt: loggedAt,
            mealType: mealType,
            calories: macros.calories,
            protein: macros.protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
        self.foodItem = foodItem
    }
}

// MARK: - Supporting Enums

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case preworkout = "pre_workout"
    case postworkout = "post_workout"
    
    var displayName: String {
        switch self {
        case .preworkout: return "Pre-Workout"
        case .postworkout: return "Post-Workout"
        default: return rawValue.capitalized
        }
    }
    
    /// Typical time ranges for meal type suggestions
    var typicalHourRange: ClosedRange<Int> {
        switch self {
        case .breakfast: return 6...10
        case .lunch: return 11...14
        case .dinner: return 17...20
        case .snack: return 0...23
        case .preworkout: return 0...23
        case .postworkout: return 0...23
        }
    }
}

