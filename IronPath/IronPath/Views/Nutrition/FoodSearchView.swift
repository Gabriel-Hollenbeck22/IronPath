//
//  FoodSearchView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var nutritionService: NutritionService?
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var showingBarcodeScanner = false
    @State private var showingQuickAdd = false
    @State private var selectedSearchItem: FoodSearchItem?
    @State private var showingFoodDetail = false
    @State private var searchTask: Task<Void, Never>?
    @State private var debounceTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: Spacing.sm) {
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchText) { oldValue, newValue in
                            // Cancel previous debounce task
                            debounceTask?.cancel()
                            
                            // Debounce: wait 300ms after user stops typing
                            debounceTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                                
                                if !Task.isCancelled && !newValue.isEmpty {
                                    await performSearch()
                                } else if newValue.isEmpty {
                                    searchResults = []
                                }
                            }
                        }
                        .onSubmit {
                            debounceTask?.cancel()
                            Task {
                                await performSearch()
                            }
                        }
                    
                    Button(action: { showingBarcodeScanner = true }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                            .padding()
                            .background(Color.ironPathAccent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                // Quick Actions
                HStack(spacing: Spacing.md) {
                    Button(action: { showingQuickAdd = true }) {
                        Label("Quick Add", systemImage: "plus.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ironPathPrimary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // Search Results
                if isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )
                } else {
                    List {
                        ForEach(groupedResults.keys.sorted(), id: \.self) { source in
                            Section(source) {
                                ForEach(groupedResults[source] ?? []) { result in
                                    FoodSearchItemRow(
                                        searchItem: result.searchItem,
                                        sourceLabel: result.sourceLabel
                                    ) {
                                        selectedSearchItem = result.searchItem
                                        showingFoodDetail = true
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView()
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView()
            }
            .sheet(isPresented: $showingFoodDetail) {
                if let searchItem = selectedSearchItem, let service = nutritionService {
                    FoodSearchDetailView(searchItem: searchItem, nutritionService: service)
                }
            }
            .onAppear {
                nutritionService = NutritionService(modelContext: modelContext)
            }
            .onChange(of: searchText) { _, newValue in
                // Cancel previous search task
                searchTask?.cancel()
                
                if newValue.count >= 2 {
                    // Debounce search with small delay
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                        if !Task.isCancelled {
                            await performSearch()
                        }
                    }
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private var groupedResults: [String: [FoodSearchResult]] {
        Dictionary(grouping: searchResults) { $0.sourceLabel }
    }
    
    @MainActor
    private func performSearch() async {
        guard let service = nutritionService, !searchText.isEmpty else { return }
        
        isSearching = true
        
        do {
            let results = try await service.searchFood(query: searchText)
            searchResults = results
            isSearching = false
        } catch {
            print("Search error: \(error)")
            isSearching = false
        }
    }
}

// MARK: - Food Search Item Row

struct FoodSearchItemRow: View {
    let searchItem: FoodSearchItem
    let sourceLabel: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(searchItem.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let brand = searchItem.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(searchItem.caloriesPer100g)) cal")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Text("\(Int(searchItem.proteinPer100g))g protein")
                        .font(.caption)
                        .foregroundStyle(Color.macroProtein)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Food Search Detail View

struct FoodSearchDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let searchItem: FoodSearchItem
    let nutritionService: NutritionService
    
    @State private var servingSize: Double = 100
    @State private var servings: Double = 1
    
    private var totalGrams: Double {
        servingSize * servings
    }
    
    private var macros: MacroNutrients {
        searchItem.macrosForServing(totalGrams)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Food Info Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(searchItem.name)
                            .font(.sectionTitle)
                        
                        if let brand = searchItem.brand {
                            Text(brand)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumCard()
                    
                    // Serving Size
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Serving Size")
                            .font(.cardTitle)
                        
                        HStack {
                            TextField("Grams", value: $servingSize, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                            
                            Text("g")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("×")
                                .foregroundStyle(.secondary)
                            
                            TextField("Servings", value: $servings, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                            
                            Text("servings")
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Total: \(Int(totalGrams))g")
                            .font(.headline)
                            .foregroundStyle(Color.ironPathPrimary)
                    }
                    .premiumCard()
                    
                    // Macros
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Nutrition")
                            .font(.cardTitle)
                        
                        HStack(spacing: Spacing.lg) {
                            MacroColumn(label: "Calories", value: "\(Int(macros.calories))", color: .primary)
                            MacroColumn(label: "Protein", value: "\(Int(macros.protein))g", color: .macroProtein)
                            MacroColumn(label: "Carbs", value: "\(Int(macros.carbs))g", color: .macroCarbs)
                            MacroColumn(label: "Fat", value: "\(Int(macros.fat))g", color: .macroFat)
                        }
                    }
                    .premiumCard()
                    
                    // Log Button
                    Button {
                        logFood()
                    } label: {
                        Label("Log Food", systemImage: "plus.circle.fill")
                    }
                    .neonGlowButton()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func logFood() {
        // Convert search item to FoodItem and log it
        let foodItem = nutritionService.createFoodItem(from: searchItem)
        
        // Determine meal type based on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let mealType: MealType
        switch hour {
        case 6..<10: mealType = .breakfast
        case 10..<14: mealType = .lunch
        case 14..<17: mealType = .snack
        case 17..<21: mealType = .dinner
        default: mealType = .snack
        }
        
        // Create logged food entry
        if let summary = try? nutritionService.getTodaysSummary() {
            let loggedFood = LoggedFood(
                servingSizeGrams: totalGrams,
                loggedAt: Date(),
                mealType: mealType,
                calories: macros.calories,
                protein: macros.protein,
                carbs: macros.carbs,
                fat: macros.fat
            )
            loggedFood.foodItem = foodItem
            loggedFood.dailySummary = summary
            
            modelContext.insert(loggedFood)
            
            // Update daily totals
            summary.totalCalories += macros.calories
            summary.totalProtein += macros.protein
            summary.totalCarbs += macros.carbs
            summary.totalFat += macros.fat
            
            try? modelContext.save()
        }
        
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Macro Column Helper

struct MacroColumn: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FoodSearchView()
        .modelContainer(for: FoodItem.self, inMemory: true)
}

