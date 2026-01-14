//
//  WorkoutManager.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Observable
final class WorkoutManager {
    private let modelContext: ModelContext
    
    // Active workout session
    var activeWorkout: Workout?
    var isWorkoutActive: Bool { activeWorkout != nil }
    
    // Recent activity cache
    var recentWorkouts: [Workout] = []
    var weeklyVolume: Double = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecentData()
    }
    
    // MARK: - Workout Session Management
    
    /// Start a new workout session
    func startWorkout(name: String) throws -> Workout {
        let workout = Workout(name: name, startTime: Date())
        modelContext.insert(workout)
        try modelContext.save()
        
        activeWorkout = workout
        return workout
    }
    
    /// Complete the active workout
    func completeWorkout() throws {
        guard let workout = activeWorkout else {
            throw WorkoutError.noActiveWorkout
        }
        
        workout.endTime = Date()
        workout.durationSeconds = Int(workout.endTime!.timeIntervalSince(workout.startTime))
        workout.isCompleted = true
        
        modelContext.insert(workout)
        try modelContext.save()
        
        // Update daily summary
        try updateDailySummaryForWorkout(workout)
        
        activeWorkout = nil
        loadRecentData()
    }
    
    /// Cancel the active workout without saving
    func cancelWorkout() {
        activeWorkout = nil
    }
    
    // MARK: - Set Logging
    
    /// Log a new set to the active workout
    func logSet(
        exercise: Exercise,
        setNumber: Int,
        weight: Double,
        reps: Int,
        rpe: Int? = nil
    ) throws -> WorkoutSet {
        guard let workout = activeWorkout else {
            throw WorkoutError.noActiveWorkout
        }
        
        let workoutSet = WorkoutSet(
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            rpe: rpe
        )
        workoutSet.exercise = exercise
        workoutSet.workout = workout
        
        if workout.sets == nil {
            workout.sets = []
        }
        workout.sets?.append(workoutSet)
        
        return workoutSet
    }
    
    /// Delete a set from the active workout
    func deleteSet(_ set: WorkoutSet) throws {
        guard let workout = activeWorkout else {
            throw WorkoutError.noActiveWorkout
        }
        
        workout.sets?.removeAll { $0.id == set.id }
    }
    
    /// Update an existing set
    func updateSet(_ set: WorkoutSet, weight: Double?, reps: Int?, rpe: Int?) {
        if let weight = weight {
            set.weight = weight
        }
        if let reps = reps {
            set.reps = reps
        }
        if let rpe = rpe {
            set.rpe = rpe
        }
    }
    
    // MARK: - Volume Calculations
    
    /// Get weekly volume (last 7 days)
    func getWeeklyVolume() -> Double {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= sevenDaysAgo && workout.isCompleted
            }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            return workouts.reduce(0) { $0 + $1.totalVolume }
        } catch {
            print("Error fetching weekly volume: \(error)")
            return 0
        }
    }
    
    /// Get volume by muscle group for a date range
    func getVolumeByMuscleGroup(
        from startDate: Date,
        to endDate: Date
    ) -> [MuscleGroup: Double] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= startDate && workout.date <= endDate && workout.isCompleted
            }
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            var volumeDict: [MuscleGroup: Double] = [:]
            
            for workout in workouts {
                let workoutVolume = workout.volumeByMuscleGroup()
                for (muscleGroup, volume) in workoutVolume {
                    volumeDict[muscleGroup, default: 0] += volume
                }
            }
            
            return volumeDict
        } catch {
            print("Error fetching volume by muscle group: \(error)")
            return [:]
        }
    }
    
    /// Calculate volume percentile for a given workout
    func calculateVolumePercentile(for workout: Workout) -> Double {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted }
        )
        
        do {
            let allWorkouts = try modelContext.fetch(descriptor)
            guard !allWorkouts.isEmpty else { return 0.5 }
            
            let sortedVolumes = allWorkouts.map { $0.totalVolume }.sorted()
            let workoutVolume = workout.totalVolume
            
            let lowerCount = sortedVolumes.filter { $0 < workoutVolume }.count
            return Double(lowerCount) / Double(sortedVolumes.count)
        } catch {
            print("Error calculating volume percentile: \(error)")
            return 0.5
        }
    }
    
    /// Get estimated 1RM history for an exercise
    func get1RMHistory(for exercise: Exercise, limit: Int = 10) -> [WorkoutSet] {
        let exerciseID = exercise.id
        let descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let allSets = try modelContext.fetch(descriptor)
            let filteredSets = allSets.filter { $0.exercise?.id == exerciseID }
            return Array(filteredSets.prefix(limit))
        } catch {
            print("Error fetching 1RM history: \(error)")
            return []
        }
    }
    
    /// Get personal record (highest 1RM) for an exercise
    func getPersonalRecord(for exercise: Exercise) -> WorkoutSet? {
        let exerciseID = exercise.id
        let descriptor = FetchDescriptor<WorkoutSet>()
        
        do {
            let allSets = try modelContext.fetch(descriptor)
            let filteredSets = allSets.filter { $0.exercise?.id == exerciseID }
            return filteredSets.max { $0.estimated1RM < $1.estimated1RM }
        } catch {
            print("Error fetching personal record: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Management
    
    /// Load recent workouts into cache
    private func loadRecentData() {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isCompleted },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            recentWorkouts = try modelContext.fetch(descriptor).prefix(10).map { $0 }
            weeklyVolume = getWeeklyVolume()
        } catch {
            print("Error loading recent data: \(error)")
        }
    }
    
    /// Update daily summary with workout data
    private func updateDailySummaryForWorkout(_ workout: Workout) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: workout.date)
        
        // Fetch or create daily summary
        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate { summary in
                summary.date == startOfDay
            }
        )
        
        let summaries = try modelContext.fetch(descriptor)
        let summary: DailySummary
        
        if let existing = summaries.first {
            summary = existing
        } else {
            summary = DailySummary(date: startOfDay)
            modelContext.insert(summary)
        }
        
        // Update workout metrics
        summary.totalWorkoutVolume += workout.totalVolume
        summary.totalWorkoutDuration += workout.durationSeconds
        summary.workoutCount += 1
        
        if let avgRPE = workout.averageRPE {
            if let currentAvg = summary.averageWorkoutRPE {
                summary.averageWorkoutRPE = (currentAvg + avgRPE) / 2.0
            } else {
                summary.averageWorkoutRPE = avgRPE
            }
        }
        
        summary.volumePercentile = calculateVolumePercentile(for: workout)
        
        try modelContext.save()
    }
    
    /// Delete a workout
    func deleteWorkout(_ workout: Workout) throws {
        modelContext.delete(workout)
        try modelContext.save()
        loadRecentData()
    }
}

// MARK: - Errors

enum WorkoutError: LocalizedError {
    case noActiveWorkout
    case invalidSetData
    
    var errorDescription: String? {
        switch self {
        case .noActiveWorkout:
            return "No active workout session"
        case .invalidSetData:
            return "Invalid set data provided"
        }
    }
}

