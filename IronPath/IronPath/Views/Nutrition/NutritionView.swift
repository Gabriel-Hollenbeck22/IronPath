//
//  NutritionView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var nutritionService: NutritionService?
    @State private var todaysSummary: DailySummary?
    @State private var showingSearch = false
    @State private var showingBarcodeScanner = false
    @State private var scannedFoodItem: FoodItem?
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Today's Summary
                    if let summary = todaysSummary {
                        nutritionSummarySection(summary: summary)
                    }
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Daily Log
                    dailyLogSection(foods: todaysSummary?.loggedFoods ?? [])
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                FoodSearchView()
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { foodItem in
                    scannedFoodItem = foodItem
                }
            }
            .sheet(item: $scannedFoodItem) { foodItem in
                FoodDetailView(foodItem: foodItem)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                setupService()
                loadTodaysData()
            }
        }
    }
    
    private func nutritionSummarySection(summary: DailySummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Macros")
                .font(.cardTitle)
            
            // Calorie Progress Bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Calories")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(summary.totalCalories)) / \(Int(userProfile?.targetCalories ?? 2200))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.ironPathPrimary, Color.ironPathPrimary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * min(summary.totalCalories / (userProfile?.targetCalories ?? 2200), 1.0),
                                height: 12
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: summary.totalCalories)
                    }
                }
                .frame(height: 12)
            }
            .padding(.bottom, Spacing.sm)
            
            HStack(spacing: Spacing.lg) {
                MacroRingView(
                    current: summary.totalProtein,
                    target: userProfile?.targetProtein ?? 150.0,
                    color: .macroProtein,
                    label: "Protein"
                )
                
                MacroRingView(
                    current: summary.totalCarbs,
                    target: userProfile?.targetCarbs ?? 200.0,
                    color: .macroCarbs,
                    label: "Carbs"
                )
                
                MacroRingView(
                    current: summary.totalFat,
                    target: userProfile?.targetFat ?? 65.0,
                    color: .macroFat,
                    label: "Fat"
                )
            }
        }
        .premiumCard()
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Button {
                    showingSearch = true
                } label: {
                    Label("Search Food", systemImage: "magnifyingglass")
                }
                .neonGlowButton()
                
                Button {
                    showingBarcodeScanner = true
                } label: {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
                .neonGlowButton(color: .ironPathAccent)
            }
        }
    }
    
    private func dailyLogSection(foods: [LoggedFood]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Log")
                .font(.cardTitle)
            
            if foods.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No Food Logged Today")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Search or scan to add your meals")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            } else {
                ForEach(foods) { food in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(food.foodItem?.name ?? "Quick Meal")
                                .font(.body)
                            Text("\(FormatHelpers.macro(food.protein)) protein")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(FormatHelpers.calories(food.calories))
                            .font(.headline)
                    }
                    .nestedCard()
                }
            }
        }
        .premiumCard()
    }
    
    private func setupService() {
        nutritionService = NutritionService(modelContext: modelContext)
    }
    
    private func loadTodaysData() {
        guard let service = nutritionService else { return }
        if let summary = try? service.getTodaysSummary() {
            todaysSummary = summary
        }
    }
}

#Preview {
    NutritionView()
        .modelContainer(for: DailySummary.self, inMemory: true)
}

