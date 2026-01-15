//
//  AnalyticsView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var integrationEngine: IntegrationEngine?
    @State private var correlationData: CorrelationData?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Muscle Group Strength Visualization
                    MuscleGroupVisualizationView()
                    
                    // Correlation Chart
                    if let data = correlationData, !data.dataPoints.isEmpty {
                        CorrelationChartView(data: data)
                    } else {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Complete workouts and log meals to see analytics")
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [Color.subtleGradientTop, Color.subtleGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onAppear {
                setupEngine()
                loadCorrelationData()
            }
        }
    }
    
    private func setupEngine() {
        integrationEngine = IntegrationEngine(modelContext: modelContext)
    }
    
    private func loadCorrelationData() {
        guard let engine = integrationEngine else { return }
        
        Task {
            if let data = try? engine.generateCorrelationData(days: 7) {
                await MainActor.run {
                    correlationData = data
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: DailySummary.self, inMemory: true)
}

