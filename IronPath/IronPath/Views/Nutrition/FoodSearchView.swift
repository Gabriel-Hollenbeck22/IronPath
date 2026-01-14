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
    @State private var selectedFood: FoodItem?
    @State private var showingFoodDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: Spacing.sm) {
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            performSearch()
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
                                ForEach(groupedResults[source] ?? [], id: \.foodItem.id) { result in
                                    FoodItemRow(
                                        foodItem: result.foodItem,
                                        sourceLabel: result.sourceLabel
                                    ) {
                                        selectedFood = result.foodItem
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
                if let food = selectedFood {
                    FoodDetailView(foodItem: food)
                }
            }
            .onAppear {
                nutritionService = NutritionService(modelContext: modelContext)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.count >= 2 {
                    performSearch()
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private var groupedResults: [String: [FoodSearchResult]] {
        Dictionary(grouping: searchResults) { $0.sourceLabel }
    }
    
    private func performSearch() {
        guard let service = nutritionService, !searchText.isEmpty else { return }
        
        isSearching = true
        
        Task {
            do {
                let results = try await service.searchFood(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }
}

#Preview {
    FoodSearchView()
        .modelContainer(for: FoodItem.self, inMemory: true)
}

