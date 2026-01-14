//
//  WorkoutView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Workout> { !$0.isCompleted },
        sort: [SortDescriptor(\.startTime, order: .reverse)]
    ) private var activeWorkouts: [Workout]
    
    @State private var workoutManager: WorkoutManager?
    @State private var isWorkoutActive = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let activeWorkout = activeWorkouts.first {
                    if let manager = workoutManager {
                        WorkoutSessionView(workout: activeWorkout, manager: manager)
                    } else {
                        ContentUnavailableView(
                            "Loading...",
                            systemImage: "dumbbell.fill"
                        )
                    }
                } else {
                    workoutStartView
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                workoutManager = WorkoutManager(modelContext: modelContext)
                // Load active workout into manager if it exists
                if let activeWorkout = activeWorkouts.first {
                    workoutManager?.activeWorkout = activeWorkout
                    isWorkoutActive = true
                }
            }
        }
    }
    
    private var workoutStartView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.ironPathPrimary)
            
            Text("Ready to Train?")
                .font(.title)
            
            Text("Start a new workout session")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: startWorkout) {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ironPathPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding()
    }
    
    private func startWorkout() {
        guard let manager = workoutManager else { return }
        do {
            _ = try manager.startWorkout(name: "Workout")
            isWorkoutActive = true
            HapticManager.mediumImpact()
        } catch {
            print("Failed to start workout:", error)
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: Workout.self, inMemory: true)
}
