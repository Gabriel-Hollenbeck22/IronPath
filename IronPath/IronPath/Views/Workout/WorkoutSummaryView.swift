//
//  WorkoutSummaryView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    let manager: WorkoutManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Summary Stats
                    VStack(spacing: Spacing.md) {
                        Text("Workout Complete!")
                            .font(.title)
                        
                        VStack(spacing: Spacing.sm) {
                            statRow(label: "Duration", value: FormatHelpers.duration(workout.durationSeconds))
                            statRow(label: "Total Volume", value: FormatHelpers.weight(workout.totalVolume))
                            statRow(label: "Sets", value: "\(workout.sets?.count ?? 0)")
                            
                            if let avgRPE = workout.averageRPE {
                                statRow(label: "Avg RPE", value: String(format: "%.1f", avgRPE))
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                    }
                    
                    // Exercises
                    if let sets = workout.sets, !sets.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Exercises")
                                .font(.headline)
                            
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
                    
                    // Done Button
                    HapticButton(hapticStyle: .success) {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ironPathSuccess)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

#Preview {
    WorkoutSummaryView(
        workout: Workout(name: "Push Day"),
        manager: WorkoutManager(modelContext: try! ModelContext(ModelContainer(for: Workout.self)))
    )
}

