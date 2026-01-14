//
//  WorkoutSessionView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    let manager: WorkoutManager
    
    @State private var selectedExercise: Exercise?
    @State private var showingExercisePicker = false
    @State private var showingSetLogger = false
    @State private var showingSummary = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Workout Header
                workoutHeader
                
                // Exercise List
                if let sets = workout.sets, !sets.isEmpty {
                    exerciseListSection(sets: sets)
                }
                
                // Add Exercise Button
                addExerciseButton
                
                // Complete Workout Button
                completeWorkoutButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    manager.cancelWorkout()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                selectedExercise = exercise
                showingExercisePicker = false
                showingSetLogger = true
            }
        }
        .sheet(isPresented: $showingSetLogger) {
            if let exercise = selectedExercise {
                SetLoggerView(
                    exercise: exercise,
                    workout: workout,
                    manager: manager
                )
            }
        }
        .sheet(isPresented: $showingSummary) {
            WorkoutSummaryView(workout: workout, manager: manager)
        }
    }
    
    private var workoutHeader: some View {
        VStack(spacing: Spacing.sm) {
            Text("Duration: \(FormatHelpers.duration(workout.durationSeconds))")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            if let volume = workout.sets?.reduce(0) { $0 + $1.volume } {
                Text("Total Volume: \(FormatHelpers.weight(volume))")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
    
    private func exerciseListSection(sets: [WorkoutSet]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Exercises")
                .font(.headline)
            
            // Group sets by exercise
            let groupedSets = Dictionary(grouping: sets) { $0.exercise?.id ?? UUID() }
            
            ForEach(Array(groupedSets.keys), id: \.self) { exerciseId in
                if let exerciseSets = groupedSets[exerciseId],
                   let exercise = exerciseSets.first?.exercise {
                    ExerciseSetsView(
                        exercise: exercise,
                        sets: exerciseSets
                    )
                }
            }
        }
    }
    
    private var addExerciseButton: some View {
        HapticButton(hapticStyle: .medium) {
            showingExercisePicker = true
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ironPathPrimary)
                .cornerRadius(12)
        }
    }
    
    private var completeWorkoutButton: some View {
        HapticButton(hapticStyle: .success) {
            do {
                try manager.completeWorkout()
                showingSummary = true
            } catch {
                print("Error completing workout: \(error)")
            }
        } label: {
            Label("Complete Workout", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ironPathSuccess)
                .cornerRadius(12)
        }
    }
}

// MARK: - Exercise Sets View

struct ExerciseSetsView: View {
    let exercise: Exercise
    let sets: [WorkoutSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(exercise.name)
                .font(.headline)
            
            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(FormatHelpers.weight(set.weight)) × \(set.reps) reps")
                        .font(.body)
                    
                    if let rpe = set.rpe {
                        Text("RPE \(rpe)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.sm)
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        WorkoutSessionView(
            workout: Workout(name: "Push Day"),
            manager: WorkoutManager(modelContext: try! ModelContext(ModelContainer(for: Workout.self)))
        )
    }
}

