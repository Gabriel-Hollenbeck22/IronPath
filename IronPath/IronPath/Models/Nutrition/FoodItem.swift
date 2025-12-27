//
//  FoodItem.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var barcode: String?
    var brand: String?
    
    // Macros per 100g
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fiberPer100g: Double?
    var sugarPer100g: Double?
    
    var source: FoodSource
    var lastUsed: Date?
    var useCount: Int
    var isFavorite: Bool
    
    @Relationship(deleteRule: .nullify, inverse: \LoggedFood.foodItem)
    var loggedFoods: [LoggedFood]?
    
    @Relationship(deleteRule: .nullify, inverse: \RecipeIngredient.foodItem)
    var recipeIngredients: [RecipeIngredient]?
    
    init(
        id: UUID = UUID(),
        name: String,
        barcode: String? = nil,
        brand: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double? = nil,
        sugarPer100g: Double? = nil,
        source: FoodSource = .userHistory,
        lastUsed: Date? = nil,
        useCount: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.barcode = barcode
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.source = source
        self.lastUsed = lastUsed
        self.useCount = useCount
        self.isFavorite = isFavorite
    }
    
    /// Calculate macros for a specific serving size in grams
    func macrosForServing(_ grams: Double) -> MacroNutrients {
        let multiplier = grams / 100.0
        return MacroNutrients(
            calories: caloriesPer100g * multiplier,
            protein: proteinPer100g * multiplier,
            carbs: carbsPer100g * multiplier,
            fat: fatPer100g * multiplier,
            fiber: (fiberPer100g ?? 0) * multiplier,
            sugar: (sugarPer100g ?? 0) * multiplier
        )
    }
    
    /// Check if this is a high-protein food (>25g per 100g or >25g per typical serving)
    var isHighProtein: Bool {
        return proteinPer100g >= 25.0
    }
}

// MARK: - Supporting Types

enum FoodSource: String, Codable {
    case userHistory = "user_history"
    case bundled = "bundled"
    case openFoodFacts = "open_food_facts"
    case manual = "manual"
}

struct MacroNutrients: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
}

