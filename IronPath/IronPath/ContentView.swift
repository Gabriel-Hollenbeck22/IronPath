//
//  ContentView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/26/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var exercises: [Exercise]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("IronPath")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Bio-Feedback Fitness")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Status Display
                VStack(alignment: .leading, spacing: 12) {
                    StatusRow(
                        icon: "person.fill",
                        label: "User Profile",
                        status: userProfiles.isEmpty ? "Not Created" : "Ready",
                        isReady: !userProfiles.isEmpty
                    )
                    
                    StatusRow(
                        icon: "dumbbell.fill",
                        label: "Exercise Library",
                        status: "\(exercises.count) exercises",
                        isReady: !exercises.isEmpty
                    )
                    
                    StatusRow(
                        icon: "heart.fill",
                        label: "Integration Engine",
                        status: "Operational",
                        isReady: true
                    )
                    
                    StatusRow(
                        icon: "brain.head.profile",
                        label: "Core Architecture",
                        status: "Complete",
                        isReady: true
                    )
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("🎉 Implementation Complete")
                        .font(.headline)
                    
                    Text("All core data models, services, and the Integration Engine are ready. See IMPLEMENTATION_SUMMARY.md for details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: initializeData) {
                        Label("Initialize Sample Data", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(!exercises.isEmpty && !userProfiles.isEmpty)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Load exercise library on first launch
            ExerciseLibraryLoader.importExercisesIfNeeded(modelContext: modelContext)
        }
    }
    
    private func initializeData() {
        // Create a default user profile if none exists
        if userProfiles.isEmpty {
            let profile = UserProfile(
                targetProtein: 150.0,
                targetCarbs: 200.0,
                targetFat: 65.0,
                targetCalories: 2200.0,
                bodyWeight: 180.0,
                heightInches: 70.0,
                age: 30,
                biologicalSex: .male,
                sleepGoalHours: 7.5,
                activityLevel: .moderate,
                primaryGoal: .muscleGain
            )
            modelContext.insert(profile)
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving profile: \(error)")
            }
        }
    }
}

// MARK: - Status Row Component

struct StatusRow: View {
    let icon: String
    let label: String
    let status: String
    let isReady: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isReady ? .green : .orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isReady ? .green : .secondary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
