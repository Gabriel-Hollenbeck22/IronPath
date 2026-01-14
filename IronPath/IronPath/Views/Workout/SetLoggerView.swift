//
//  SetLoggerView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct SetLoggerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    let workout: Workout
    let manager: WorkoutManager
    
    @State private var weight: Double = 135
    @State private var reps: Int = 5
    @State private var rpe: Int? = nil
    @State private var setNumber: Int = 1
    
    var estimated1RM: Double {
        guard reps > 0, reps < 37 else { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.sectionSpacing) {
                // Exercise Info
                VStack(spacing: Spacing.xs) {
                    Text(exercise.name)
                        .font(.title2)
                    
                    HStack(spacing: Spacing.sm) {
                        Text(exercise.muscleGroup.displayName)
                        Text("•")
                        Text(exercise.equipment.displayName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                
                // Set Input
                VStack(spacing: Spacing.lg) {
                    // Weight
                    VStack(spacing: Spacing.sm) {
                        Text("Weight")
                            .font(.headline)
                        
                        HStack(spacing: Spacing.md) {
                            Button(action: {
                                weight = max(0, weight - 5)
                                HapticManager.lightImpact()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                            }
                            
                            Text(FormatHelpers.weight(weight))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(minWidth: 120)
                            
                            Button(action: {
                                weight += 5
                                HapticManager.lightImpact()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                        }
                    }
                    
                    // Reps
                    VStack(spacing: Spacing.sm) {
                        Text("Reps")
                            .font(.headline)
                        
                        HStack(spacing: Spacing.md) {
                            Button(action: {
                                reps = max(1, reps - 1)
                                HapticManager.lightImpact()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                            }
                            
                            Text("\(reps)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(minWidth: 60)
                            
                            Button(action: {
                                reps += 1
                                HapticManager.lightImpact()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                        }
                    }
                    
                    // RPE (Optional)
                    VStack(spacing: Spacing.sm) {
                        Text("RPE (Optional)")
                            .font(.headline)
                        
                        HStack(spacing: Spacing.sm) {
                            ForEach(1...10, id: \.self) { value in
                                Button(action: {
                                    rpe = rpe == value ? nil : value
                                    HapticManager.selection()
                                }) {
                                    Text("\(value)")
                                        .font(.headline)
                                        .foregroundColor(rpe == value ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(rpe == value ? Color.ironPathPrimary : Color.secondaryBackground)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                
                // Stats
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Estimated 1RM:")
                        Spacer()
                        Text(FormatHelpers.weight(estimated1RM))
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Volume:")
                        Spacer()
                        Text(FormatHelpers.weight(weight * Double(reps)))
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                
                // Complete Set Button
                HapticButton(hapticStyle: .success) {
                    do {
                        let setNumber = (workout.sets?.count ?? 0) + 1
                        _ = try manager.logSet(
                            exercise: exercise,
                            setNumber: setNumber,
                            weight: weight,
                            reps: reps,
                            rpe: rpe
                        )
                        dismiss()
                    } catch {
                        print("Error logging set: \(error)")
                    }
                } label: {
                    Label("Complete Set", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ironPathSuccess)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Log Set")
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
}

#Preview {
    SetLoggerView(
        exercise: Exercise(name: "Barbell Bench Press", muscleGroup: .chest, equipment: .barbell),
        workout: Workout(name: "Push Day"),
        manager: WorkoutManager(modelContext: try! ModelContext(ModelContainer(for: Workout.self)))
    )
}

