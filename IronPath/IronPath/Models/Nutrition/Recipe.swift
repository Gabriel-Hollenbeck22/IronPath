//
//  Recipe.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var name: String
    var recipeDescription: String?
    var isFavorite: Bool
    var servings: Int
    var prepTimeMinutes: Int?
    var lastUsed: Date?
    var useCount: Int
    
    @Relationship(deleteRule: .cascade)
    var ingredients: [RecipeIngredient]?
    
    @Relationship(deleteRule: .nullify, inverse: \LoggedFood.recipe)
    var loggedFoods: [LoggedFood]?
    
    init(
        id: UUID = UUID(),
        name: String,
        recipeDescription: String? = nil,
        isFavorite: Bool = false,
        servings: Int = 1,
        prepTimeMinutes: Int? = nil,
        lastUsed: Date? = nil,
        useCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.recipeDescription = recipeDescription
        self.isFavorite = isFavorite
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.lastUsed = lastUsed
        self.useCount = useCount
    }
    
    /// Calculate total macros for entire recipe
    var totalMacros: MacroNutrients {
        guard let ingredients = ingredients else {
            return MacroNutrients(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0)
        }
        
        var totalCalories = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var totalFiber = 0.0
        var totalSugar = 0.0
        
        for ingredient in ingredients {
            if let foodItem = ingredient.foodItem {
                let macros = foodItem.macrosForServing(ingredient.amountGrams)
                totalCalories += macros.calories
                totalProtein += macros.protein
                totalCarbs += macros.carbs
                totalFat += macros.fat
                totalFiber += macros.fiber
                totalSugar += macros.sugar
            }
        }
        
        return MacroNutrients(
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            sugar: totalSugar
        )
    }
    
    /// Calculate macros per serving
    var macrosPerServing: MacroNutrients {
        let total = totalMacros
        let servingDivisor = Double(max(servings, 1))
        
        return MacroNutrients(
            calories: total.calories / servingDivisor,
            protein: total.protein / servingDivisor,
            carbs: total.carbs / servingDivisor,
            fat: total.fat / servingDivisor,
            fiber: total.fiber / servingDivisor,
            sugar: total.sugar / servingDivisor
        )
    }
}

// MARK: - Recipe Ingredient

@Model
final class RecipeIngredient {
    var id: UUID
    var amountGrams: Double
    var notes: String?
    
    @Relationship(deleteRule: .nullify, inverse: \Recipe.ingredients)
    var recipe: Recipe?
    
    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem?
    
    init(
        id: UUID = UUID(),
        amountGrams: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.amountGrams = amountGrams
        self.notes = notes
    }
}

