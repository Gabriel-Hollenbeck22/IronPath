//
//  QuickActionsSection.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct QuickActionsSection: View {
    @Binding var selectedTab: Int?  // Add this
    @State private var showingWorkout = false
    @State private var showingNutrition = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Spacing.md) {
                HapticButton(hapticStyle: .medium) {
                    showingWorkout = true
                } label: {
                    Label("Start Workout", systemImage: "dumbbell.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ironPathPrimary)
                        .cornerRadius(12)
                }
                
                HapticButton(hapticStyle: .medium) {
                    showingNutrition = true
                } label: {
                    Label("Log Meal", systemImage: "fork.knife")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ironPathAccent)
                        .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $showingWorkout) {
            WorkoutQuickStartView(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $showingNutrition) {
            FoodSearchView()
        }
    }
}

// MARK: - Workout Quick Start View

struct WorkoutQuickStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: Int?  // Add this
    @State private var workoutName = "Workout"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                TextField("Workout Name", text: $workoutName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button(action: startWorkout) {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ironPathPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Start Workout")
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
    
    private func startWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? "Workout" : workoutName)
        modelContext.insert(workout)
        
        do {
            try modelContext.save()
            HapticManager.success()
            // Switch to Workout tab (index 1)
            selectedTab = 1
            dismiss()
        } catch {
            print("Error starting workout: \(error)")
            HapticManager.error()
        }
    }
}

#Preview {
    QuickActionsSection(selectedTab: .constant(0))
        .padding()
}
