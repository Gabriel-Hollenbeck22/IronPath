//
//  Workout.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var date: Date
    var name: String
    var startTime: Date
    var endTime: Date?
    var durationSeconds: Int
    var notes: String?
    var isCompleted: Bool
    
    @Relationship(deleteRule: .cascade)
    var sets: [WorkoutSet]?
    
    @Relationship(deleteRule: .nullify, inverse: \UserProfile.workouts)
    var userProfile: UserProfile?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        name: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationSeconds: Int = 0,
        notes: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.isCompleted = isCompleted
    }
    
    /// Computed total volume (sum of all set volumes)
    var totalVolume: Double {
        sets?.reduce(0) { $0 + $1.volume } ?? 0
    }
    
    /// Computed average RPE across all sets with RPE data
    var averageRPE: Double? {
        guard let sets = sets else { return nil }
        let rpeSets = sets.compactMap { $0.rpe }
        guard !rpeSets.isEmpty else { return nil }
        return Double(rpeSets.reduce(0, +)) / Double(rpeSets.count)
    }
    
    /// Get unique exercises in this workout
    var uniqueExercises: [Exercise] {
        guard let sets = sets else { return [] }
        var exerciseDict: [UUID: Exercise] = [:]
        for set in sets {
            if let exercise = set.exercise {
                exerciseDict[exercise.id] = exercise
            }
        }
        return Array(exerciseDict.values)
    }
    
    /// Calculate volume by muscle group
    func volumeByMuscleGroup() -> [MuscleGroup: Double] {
        guard let sets = sets else { return [:] }
        var volumeDict: [MuscleGroup: Double] = [:]
        
        for set in sets {
            if let exercise = set.exercise {
                let muscleGroup = exercise.muscleGroup
                volumeDict[muscleGroup, default: 0] += set.volume
            }
        }
        
        return volumeDict
    }
}

