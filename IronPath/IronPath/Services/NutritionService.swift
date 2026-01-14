//
//  NutritionService.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Observable
final class NutritionService {
    private let modelContext: ModelContext
    
    // Cached data
    var recentFoods: [FoodItem] = []
    var favoriteFoods: [FoodItem] = []
    var bundledFoods: [FoodItem] = []
    
    // Daily tracking
    var todaysSummary: DailySummary?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadBundledFoods()
        loadCachedData()
        loadOrCreateTodaysSummary()
    }
    
    // MARK: - Three-Tier Search Architecture
    
    /// Search for food items using three-tier strategy:
    /// 1. User history (recent/frequent)
    /// 2. Bundled common foods
    /// 3. Open Food Facts API
    func searchFood(query: String) async throws -> [FoodSearchResult] {
        var results: [FoodSearchResult] = []
        
        // Tier 1: User History
        let userResults = searchUserHistory(query: query)
        results.append(contentsOf: userResults.map { .userHistory($0) })
        
        // Tier 2: Bundled Foods
        let bundledResults = searchBundledFoods(query: query)
        results.append(contentsOf: bundledResults.map { .bundled($0) })
        
        // Tier 3: Open Food Facts (only if we don't have enough results)
        if results.count < 10 {
            let apiResults = try await searchOpenFoodFacts(query: query)
            results.append(contentsOf: apiResults.map { .openFoodFacts($0) })
        }
        
        return results
    }
    
    /// Search user's history - prioritize frequent and recent items
    private func searchUserHistory(query: String) -> [FoodItem] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { food in
                food.source.rawValue == "user_history"
            },
            sortBy: [
                SortDescriptor(\.useCount, order: .reverse),
                SortDescriptor(\.lastUsed, order: .reverse)
            ]
        )
        
        do {
            let allItems = try modelContext.fetch(descriptor)
            let filtered = allItems.filter { $0.name.localizedStandardContains(lowercaseQuery) }
            return Array(filtered.prefix(5))
        } catch {
            print("Error searching user history: \(error)")
            return []
        }
    }
    
    /// Search bundled common foods
    private func searchBundledFoods(query: String) -> [FoodItem] {
        let lowercaseQuery = query.lowercased()
        return bundledFoods.filter { food in
            food.name.lowercased().contains(lowercaseQuery)
        }.prefix(5).map { $0 }
    }
    
    /// Search Open Food Facts API
    private func searchOpenFoodFacts(query: String) async throws -> [FoodItem] {
        let baseURL = AppConfiguration.openFoodFactsBaseURL
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search?search_terms=\(encodedQuery)&page_size=10&json=true"
        
        guard let url = URL(string: urlString) else {
            throw NutritionError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NutritionError.networkError
        }
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(OpenFoodFactsSearchResponse.self, from: data)
        
        return searchResponse.products.compactMap { product in
            parseFoodItemFromAPI(product)
        }
    }
    
    /// Search by barcode
    func searchByBarcode(_ barcode: String) async throws -> FoodItem? {
        // First check if we have it locally
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { food in
                food.barcode == barcode
            }
        )
        
        if let existingFood = try modelContext.fetch(descriptor).first {
            return existingFood
        }
        
        // Query Open Food Facts
        let baseURL = AppConfiguration.openFoodFactsBaseURL
        let urlString = "\(baseURL)/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            throw NutritionError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NutritionError.productNotFound
        }
        
        let decoder = JSONDecoder()
        let productResponse = try decoder.decode(OpenFoodFactsProductResponse.self, from: data)
        
        guard productResponse.status == 1 else {
            throw NutritionError.productNotFound
        }
        
        return parseFoodItemFromAPI(productResponse.product)
    }
    
    // MARK: - Food Logging
    
    /// Log a food item for a specific meal
    func logFood(
        foodItem: FoodItem,
        servingSizeGrams: Double,
        mealType: MealType,
        loggedAt: Date = Date()
    ) throws {
        let loggedFood = LoggedFood(
            foodItem: foodItem,
            servingSizeGrams: servingSizeGrams,
            mealType: mealType,
            loggedAt: loggedAt
        )
        
        // Update food item usage stats
        foodItem.lastUsed = loggedAt
        foodItem.useCount += 1
        
        // Add to today's summary
        let summary = try getTodaysSummary()
        if summary.loggedFoods == nil {
            summary.loggedFoods = []
        }
        summary.loggedFoods?.append(loggedFood)
        loggedFood.dailySummary = summary
        
        // Recalculate totals
        summary.recalculateNutritionTotals()
        
        modelContext.insert(loggedFood)
        try modelContext.save()
        
        loadCachedData()
    }
    
    /// Log a quick meal with manual macro entry
    func logQuickMeal(
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        mealType: MealType
    ) throws {
        let loggedFood = LoggedFood(
            servingSizeGrams: 0, // Not applicable for quick meals
            loggedAt: Date(),
            mealType: mealType,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        
        let summary = try getTodaysSummary()
        if summary.loggedFoods == nil {
            summary.loggedFoods = []
        }
        summary.loggedFoods?.append(loggedFood)
        loggedFood.dailySummary = summary
        
        summary.recalculateNutritionTotals()
        
        modelContext.insert(loggedFood)
        try modelContext.save()
    }
    
    /// Delete a logged food entry
    func deleteLoggedFood(_ loggedFood: LoggedFood) throws {
        if let summary = loggedFood.dailySummary {
            summary.loggedFoods?.removeAll { $0.id == loggedFood.id }
            summary.recalculateNutritionTotals()
        }
        
        modelContext.delete(loggedFood)
        try modelContext.save()
    }
    
    // MARK: - Daily Summary
    
    /// Get or create today's summary
    func getTodaysSummary() throws -> DailySummary {
        if let summary = todaysSummary {
            return summary
        }
        
        return loadOrCreateTodaysSummary()
    }
    
    @discardableResult
    private func loadOrCreateTodaysSummary() -> DailySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate { summary in
                summary.date == today
            }
        )
        
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                todaysSummary = existing
                return existing
            }
            
            let newSummary = DailySummary(date: today)
            modelContext.insert(newSummary)
            try modelContext.save()
            todaysSummary = newSummary
            return newSummary
        } catch {
            print("Error loading/creating today's summary: \(error)")
            let fallback = DailySummary(date: today)
            todaysSummary = fallback
            return fallback
        }
    }
    
    /// Get daily macros for a specific date
    func getDailyMacros(for date: Date) -> (calories: Double, protein: Double, carbs: Double, fat: Double)? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate { summary in
                summary.date == startOfDay
            }
        )
        
        do {
            guard let summary = try modelContext.fetch(descriptor).first else {
                return nil
            }
            return (
                calories: summary.totalCalories,
                protein: summary.totalProtein,
                carbs: summary.totalCarbs,
                fat: summary.totalFat
            )
        } catch {
            print("Error fetching daily macros: \(error)")
            return nil
        }
    }
    
    // MARK: - Suggestions
    
    /// Get food suggestions based on time of day and history
    func getSuggestionsForMealType(_ mealType: MealType) -> [FoodItem] {
        let descriptor = FetchDescriptor<LoggedFood>(
            predicate: #Predicate { logged in
                logged.mealType == mealType
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        
        do {
            let loggedFoods = try modelContext.fetch(descriptor)
            var foodFrequency: [UUID: (food: FoodItem, count: Int)] = [:]
            
            for logged in loggedFoods {
                if let foodItem = logged.foodItem {
                    if let existing = foodFrequency[foodItem.id] {
                        foodFrequency[foodItem.id] = (foodItem, existing.count + 1)
                    } else {
                        foodFrequency[foodItem.id] = (foodItem, 1)
                    }
                }
            }
            
            return foodFrequency.values
                .sorted { $0.count > $1.count }
                .prefix(5)
                .map { $0.food }
        } catch {
            print("Error fetching meal suggestions: \(error)")
            return []
        }
    }
    
    // MARK: - Data Management
    
    private func loadCachedData() {
        // Load recent foods
        let recentDescriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { food in
                food.lastUsed != nil
            },
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        
        do {
            recentFoods = try modelContext.fetch(recentDescriptor).prefix(10).map { $0 }
        } catch {
            print("Error loading recent foods: \(error)")
        }
        
        // Load favorites
        let favoritesDescriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { food in
                food.isFavorite
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            favoriteFoods = try modelContext.fetch(favoritesDescriptor)
        } catch {
            print("Error loading favorite foods: \(error)")
        }
    }
    
    private func loadBundledFoods() {
        // This will be populated from ExerciseLibrary.json
        // For now, it's empty - will be implemented with the JSON file
        bundledFoods = []
    }
    
    private func parseFoodItemFromAPI(_ product: OpenFoodFactsProduct) -> FoodItem? {
        guard let nutrients = product.nutriments else { return nil }
        
        return FoodItem(
            name: product.productName ?? "Unknown",
            barcode: product.code,
            brand: product.brands,
            caloriesPer100g: nutrients.energyKcal100g ?? 0,
            proteinPer100g: nutrients.proteins100g ?? 0,
            carbsPer100g: nutrients.carbohydrates100g ?? 0,
            fatPer100g: nutrients.fat100g ?? 0,
            fiberPer100g: nutrients.fiber100g,
            sugarPer100g: nutrients.sugars100g,
            source: .openFoodFacts
        )
    }
}

// MARK: - Search Results

enum FoodSearchResult {
    case userHistory(FoodItem)
    case bundled(FoodItem)
    case openFoodFacts(FoodItem)
    
    var foodItem: FoodItem {
        switch self {
        case .userHistory(let item), .bundled(let item), .openFoodFacts(let item):
            return item
        }
    }
    
    var sourceLabel: String {
        switch self {
        case .userHistory: return "Recent"
        case .bundled: return "Common"
        case .openFoodFacts: return "Database"
        }
    }
}

// MARK: - Open Food Facts API Models

struct OpenFoodFactsSearchResponse: Codable {
    let products: [OpenFoodFactsProduct]
}

struct OpenFoodFactsProductResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct
}

struct OpenFoodFactsProduct: Codable {
    let code: String?
    let productName: String?
    let brands: String?
    let nutriments: OpenFoodFactsNutriments?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case nutriments
    }
}

struct OpenFoodFactsNutriments: Codable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
    }
}

// MARK: - Errors

enum NutritionError: LocalizedError {
    case invalidURL
    case networkError
    case productNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network request failed"
        case .productNotFound:
            return "Product not found in database"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

