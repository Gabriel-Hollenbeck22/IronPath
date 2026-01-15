//
//  NutritionService.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

// #region debug log helper
func debugLogNutrition(_ location: String, _ message: String, _ data: [String: Any] = [:], hypothesisId: String = "") {
    let logPath = "/Users/gabehollenbeck/Desktop/IronPath Ai/.cursor/debug.log"
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    var logData: [String: Any] = ["location": location, "message": message, "data": data, "timestamp": timestamp, "sessionId": "debug-session"]
    if !hypothesisId.isEmpty { logData["hypothesisId"] = hypothesisId }
    if let jsonData = try? JSONSerialization.data(withJSONObject: logData), let jsonString = String(data: jsonData, encoding: .utf8) {
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write((jsonString + "\n").data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: (jsonString + "\n").data(using: .utf8))
        }
    }
}
// #endregion

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
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-start", "Starting food search", ["query": query], hypothesisId: "A")
        // #endregion
        var results: [FoodSearchResult] = []
        
        // Tier 1: User History (convert FoodItem to FoodSearchItem)
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-tier1", "Searching user history", [:], hypothesisId: "A")
        // #endregion
        let userResults = searchUserHistory(query: query)
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-tier1-done", "User history search complete", ["count": userResults.count], hypothesisId: "A")
        // #endregion
        results.append(contentsOf: userResults.map { .userHistory(FoodSearchItem(from: $0)) })
        
        // Tier 2: Bundled Foods (convert FoodItem to FoodSearchItem) - Show immediately
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-tier2", "Searching bundled foods", [:], hypothesisId: "A")
        // #endregion
        let bundledResults = searchBundledFoods(query: query)
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-tier2-done", "Bundled foods search complete", ["count": bundledResults.count], hypothesisId: "A")
        // #endregion
        results.append(contentsOf: bundledResults.map { .bundled(FoodSearchItem(from: $0)) })
        
        // Tier 3: Cached API results (fast, synchronous)
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-tier3-cache", "Searching cached API results", [:], hypothesisId: "A")
        // #endregion
        let cachedResults = searchCachedFoods(query: query)
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-tier3-cache-done", "Cached results search complete", ["count": cachedResults.count], hypothesisId: "A")
        // #endregion
        results.append(contentsOf: cachedResults.map { .openFoodFacts($0) })
        
        // Tier 4: Open Food Facts API (async, only if we need more results)
        // Increase threshold to 30 results for more options
        if results.count < 30 {
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchFood-tier4-api", "Searching Open Food Facts API", [:], hypothesisId: "A")
            // #endregion
            do {
                let apiResults = try await searchOpenFoodFacts(query: query)
                // #region agent log
                debugLogNutrition("NutritionService.swift:searchFood-tier4-api-done", "Open Food Facts search complete", ["count": apiResults.count], hypothesisId: "A")
                // #endregion
                // Only add results not already in our list (avoid duplicates)
                let existingNames = Set(results.map { $0.searchItem.name.lowercased() })
                let newResults = apiResults.filter { !existingNames.contains($0.name.lowercased()) }
                results.append(contentsOf: newResults.map { .openFoodFacts($0) })
            } catch {
                // #region agent log
                debugLogNutrition("NutritionService.swift:searchFood-tier4-api-error", "Open Food Facts API failed", ["error": "\(error)"], hypothesisId: "A")
                // #endregion
                print("Open Food Facts API error: \(error)")
            }
        }
        
        // Tier 5: Fallback - ensure we always return at least one result
        if results.isEmpty {
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchFood-fallback", "No results found, creating fallback", [:], hypothesisId: "A")
            // #endregion
            let fallbackItem = createFallbackFoodItem(query: query)
            results.append(.openFoodFacts(fallbackItem))
        }
        
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchFood-complete", "Search complete", ["totalResults": results.count], hypothesisId: "A")
        // #endregion
        return results
    }
    
    /// Search user's history - prioritize frequent and recent items
    private func searchUserHistory(query: String) -> [FoodItem] {
        // #region agent log
        debugLogNutrition("NutritionService.swift:searchUserHistory-start", "Starting user history search", ["query": query], hypothesisId: "A")
        // #endregion
        let lowercaseQuery = query.lowercased()
        
        // Fetch all items and filter in memory (SwiftData predicates may not support enum comparison)
        let descriptor = FetchDescriptor<FoodItem>(
            sortBy: [
                SortDescriptor(\.useCount, order: .reverse),
                SortDescriptor(\.lastUsed, order: .reverse)
            ]
        )
        
        do {
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchUserHistory-fetch", "Fetching items from database", [:], hypothesisId: "A")
            // #endregion
            let allItems = try modelContext.fetch(descriptor)
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchUserHistory-fetched", "Fetched items from database", ["count": allItems.count], hypothesisId: "A")
            // #endregion
            
            // Filter by source enum and name in memory
            let userHistoryItems = allItems.filter { $0.source == .userHistory }
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchUserHistory-filtered-source", "Filtered by source", ["count": userHistoryItems.count], hypothesisId: "A")
            // #endregion
            
            let filtered = userHistoryItems.filter { $0.name.localizedStandardContains(lowercaseQuery) }
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchUserHistory-filtered-name", "Filtered by name", ["count": filtered.count], hypothesisId: "A")
            // #endregion
            return Array(filtered.prefix(5))
        } catch {
            // #region agent log
            debugLogNutrition("NutritionService.swift:searchUserHistory-error", "Error fetching user history", ["error": "\(error)"], hypothesisId: "A")
            // #endregion
            print("Error searching user history: \(error)")
            return []
        }
    }
    
    /// Search bundled common foods (optimized for speed)
    private func searchBundledFoods(query: String) -> [FoodItem] {
        let lowercaseQuery = query.lowercased()
        // Increase results to 30 for more options, use localizedStandardContains for better matching
        return bundledFoods.filter { food in
            food.name.lowercased().localizedStandardContains(lowercaseQuery) ||
            food.name.lowercased().contains(lowercaseQuery)
        }.prefix(30).map { $0 }
    }
    
    /// Search Open Food Facts API (cache check is done in searchFood, this just fetches from API)
    private func searchOpenFoodFacts(query: String) async throws -> [FoodSearchItem] {
        // Fetch from API (cache is checked in searchFood method)
        let baseURL = AppConfiguration.openFoodFactsBaseURL
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search?search_terms=\(encodedQuery)&page_size=30&json=true"
        
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
        
        let apiResults = searchResponse.products.compactMap { product in
            parseSearchItemFromAPI(product)
        }
        
        // Cache the results
        cacheFoodItems(apiResults)
        
        return apiResults
    }
    
    /// Search cached foods from SwiftData (30-day expiration)
    private func searchCachedFoods(query: String) -> [FoodSearchItem] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Fetch all foods and filter in memory (SwiftData predicates don't support enum comparison)
        let descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse), SortDescriptor(\.lastUsed, order: .reverse)]
        )
        
        do {
            let allFoods = try modelContext.fetch(descriptor)
            let lowercaseQuery = query.lowercased()
            
            // Filter by source, date, and query in memory - use better matching
            return allFoods
                .filter { food in
                    food.source == .openFoodFacts &&
                    food.lastUsed != nil &&
                    food.lastUsed! >= thirtyDaysAgo &&
                    (food.name.lowercased().localizedStandardContains(lowercaseQuery) ||
                     food.name.lowercased().contains(lowercaseQuery))
                }
                .prefix(30)
                .map { FoodSearchItem(from: $0) }
        } catch {
            print("Error searching cached foods: \(error)")
            return []
        }
    }
    
    /// Cache food items from API search
    private func cacheFoodItems(_ searchItems: [FoodSearchItem]) {
        for searchItem in searchItems {
            // Extract values for predicate (SwiftData predicates can't reference external values directly)
            let searchItemID = searchItem.id
            let searchItemBarcode = searchItem.barcode
            
            // Check if already exists by ID
            let idDescriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate<FoodItem> { food in
                    food.id == searchItemID
                }
            )
            
            do {
                var existing = try modelContext.fetch(idDescriptor).first
                
                // If not found by ID, check by barcode
                if existing == nil, let barcode = searchItemBarcode {
                    let barcodeDescriptor = FetchDescriptor<FoodItem>(
                        predicate: #Predicate<FoodItem> { food in
                            food.barcode == barcode
                        }
                    )
                    existing = try modelContext.fetch(barcodeDescriptor).first
                }
                
                if existing == nil {
                    // Create and cache new food item
                    let foodItem = createFoodItem(from: searchItem)
                    foodItem.source = .openFoodFacts
                    foodItem.lastUsed = Date()
                    try? modelContext.save()
                } else {
                    // Update last used
                    existing?.lastUsed = Date()
                    try? modelContext.save()
                }
            } catch {
                print("Error caching food item: \(error)")
            }
        }
    }
    
    /// Create a fallback food item with estimated macros when no search results are found
    /// Uses heuristics to estimate macros based on food type keywords
    private func createFallbackFoodItem(query: String) -> FoodSearchItem {
        let lowercaseQuery = query.lowercased()
        
        // Estimate macros based on food type
        var estimatedCalories: Double = 100
        var estimatedProtein: Double = 5
        var estimatedCarbs: Double = 15
        var estimatedFat: Double = 2
        
        // Protein-rich foods
        if lowercaseQuery.contains("chicken") || lowercaseQuery.contains("poultry") {
            estimatedCalories = 165
            estimatedProtein = 31
            estimatedCarbs = 0
            estimatedFat = 3.6
        } else if lowercaseQuery.contains("beef") || lowercaseQuery.contains("steak") {
            estimatedCalories = 250
            estimatedProtein = 26
            estimatedCarbs = 0
            estimatedFat = 17
        } else if lowercaseQuery.contains("fish") || lowercaseQuery.contains("salmon") || lowercaseQuery.contains("tuna") {
            estimatedCalories = 150
            estimatedProtein = 25
            estimatedCarbs = 0
            estimatedFat = 5
        } else if lowercaseQuery.contains("egg") {
            estimatedCalories = 155
            estimatedProtein = 13
            estimatedCarbs = 1.1
            estimatedFat = 11
        } else if lowercaseQuery.contains("milk") || lowercaseQuery.contains("yogurt") || lowercaseQuery.contains("cheese") {
            estimatedCalories = 100
            estimatedProtein = 8
            estimatedCarbs = 5
            estimatedFat = 5
        }
        // Carb-rich foods
        else if lowercaseQuery.contains("rice") {
            estimatedCalories = 130
            estimatedProtein = 2.7
            estimatedCarbs = 28
            estimatedFat = 0.3
        } else if lowercaseQuery.contains("pasta") || lowercaseQuery.contains("noodle") {
            estimatedCalories = 131
            estimatedProtein = 5
            estimatedCarbs = 25
            estimatedFat = 1.1
        } else if lowercaseQuery.contains("bread") {
            estimatedCalories = 247
            estimatedProtein = 13
            estimatedCarbs = 41
            estimatedFat = 4.2
        } else if lowercaseQuery.contains("potato") || lowercaseQuery.contains("sweet potato") {
            estimatedCalories = 86
            estimatedProtein = 1.6
            estimatedCarbs = 20
            estimatedFat = 0.1
        } else if lowercaseQuery.contains("oat") {
            estimatedCalories = 389
            estimatedProtein = 17
            estimatedCarbs = 66
            estimatedFat = 7
        }
        // Fruits
        else if lowercaseQuery.contains("apple") || lowercaseQuery.contains("banana") || lowercaseQuery.contains("orange") {
            estimatedCalories = 50
            estimatedProtein = 0.5
            estimatedCarbs = 13
            estimatedFat = 0.2
        }
        // Vegetables
        else if lowercaseQuery.contains("broccoli") || lowercaseQuery.contains("spinach") || lowercaseQuery.contains("lettuce") {
            estimatedCalories = 25
            estimatedProtein = 2
            estimatedCarbs = 5
            estimatedFat = 0.3
        }
        // Nuts/Seeds
        else if lowercaseQuery.contains("nut") || lowercaseQuery.contains("almond") || lowercaseQuery.contains("peanut") {
            estimatedCalories = 600
            estimatedProtein = 20
            estimatedCarbs = 20
            estimatedFat = 50
        }
        // Fats/Oils
        else if lowercaseQuery.contains("oil") || lowercaseQuery.contains("butter") {
            estimatedCalories = 900
            estimatedProtein = 0
            estimatedCarbs = 0
            estimatedFat = 100
        }
        
        return FoodSearchItem(
            name: query.capitalized,
            caloriesPer100g: estimatedCalories,
            proteinPer100g: estimatedProtein,
            carbsPer100g: estimatedCarbs,
            fatPer100g: estimatedFat,
            fiberPer100g: 2.0,
            source: .openFoodFacts
        )
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
        
        // Parse to search item first, then convert to FoodItem
        guard let searchItem = parseSearchItemFromAPI(productResponse.product) else {
            throw NutritionError.productNotFound
        }
        
        return createFoodItem(from: searchItem)
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
        guard let url = Bundle.main.url(forResource: "CommonFoods", withExtension: "json") else {
            print("CommonFoods.json not found in bundle")
            bundledFoods = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let commonFoodsResponse = try decoder.decode(CommonFoodsResponse.self, from: data)
            
            bundledFoods = commonFoodsResponse.foods.map { foodData in
                FoodItem(
                    name: foodData.name,
                    caloriesPer100g: foodData.caloriesPer100g,
                    proteinPer100g: foodData.proteinPer100g,
                    carbsPer100g: foodData.carbsPer100g,
                    fatPer100g: foodData.fatPer100g,
                    fiberPer100g: foodData.fiberPer100g,
                    source: .bundled
                )
            }
            
            print("Loaded \(bundledFoods.count) bundled foods")
        } catch {
            print("Failed to load CommonFoods.json: \(error)")
            bundledFoods = []
        }
    }
    
    /// Parse API response to transient FoodSearchItem (not SwiftData)
    private func parseSearchItemFromAPI(_ product: OpenFoodFactsProduct) -> FoodSearchItem? {
        guard let nutrients = product.nutriments else { return nil }
        
        return FoodSearchItem(
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
    
    /// Convert a FoodSearchItem to a FoodItem and insert into the model context
    /// Call this when the user selects a food to log
    func createFoodItem(from searchItem: FoodSearchItem) -> FoodItem {
        // Check if we already have this item (by barcode or ID)
        if let barcode = searchItem.barcode {
            let descriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate { food in
                    food.barcode == barcode
                }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                // Update last used
                existing.lastUsed = Date()
                existing.useCount += 1
                return existing
            }
        }
        
        // Create new FoodItem
        let foodItem = FoodItem(
            id: searchItem.id,
            name: searchItem.name,
            barcode: searchItem.barcode,
            brand: searchItem.brand,
            caloriesPer100g: searchItem.caloriesPer100g,
            proteinPer100g: searchItem.proteinPer100g,
            carbsPer100g: searchItem.carbsPer100g,
            fatPer100g: searchItem.fatPer100g,
            fiberPer100g: searchItem.fiberPer100g,
            sugarPer100g: searchItem.sugarPer100g,
            source: searchItem.source,
            lastUsed: Date(),
            useCount: 1
        )
        
        modelContext.insert(foodItem)
        return foodItem
    }
}

// MARK: - Transient Search Item (Not SwiftData)

/// A lightweight, transient struct for search results that doesn't use SwiftData.
/// This prevents crashes when creating food items in async contexts without a ModelContext.
/// Convert to FoodItem only when the user selects an item to log.
struct FoodSearchItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let barcode: String?
    let brand: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double?
    let sugarPer100g: Double?
    let source: FoodSource
    
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
        source: FoodSource
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
    }
    
    /// Create from an existing FoodItem (for user history)
    init(from foodItem: FoodItem) {
        self.id = foodItem.id
        self.name = foodItem.name
        self.barcode = foodItem.barcode
        self.brand = foodItem.brand
        self.caloriesPer100g = foodItem.caloriesPer100g
        self.proteinPer100g = foodItem.proteinPer100g
        self.carbsPer100g = foodItem.carbsPer100g
        self.fatPer100g = foodItem.fatPer100g
        self.fiberPer100g = foodItem.fiberPer100g
        self.sugarPer100g = foodItem.sugarPer100g
        self.source = foodItem.source
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
}

// MARK: - Search Results

enum FoodSearchResult: Identifiable {
    case userHistory(FoodSearchItem)
    case bundled(FoodSearchItem)
    case openFoodFacts(FoodSearchItem)
    
    var id: UUID {
        searchItem.id
    }
    
    var searchItem: FoodSearchItem {
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

// MARK: - Common Foods JSON Models

struct CommonFoodsResponse: Codable {
    let foods: [CommonFoodData]
}

struct CommonFoodData: Codable {
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
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

