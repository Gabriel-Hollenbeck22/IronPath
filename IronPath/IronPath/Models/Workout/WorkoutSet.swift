//
//  WorkoutSet.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID
    var setNumber: Int
    var weight: Double // in pounds (can be converted using Measurement API)
    var reps: Int
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var timestamp: Date
    var notes: String?
    
    @Relationship(deleteRule: .nullify)
    var exercise: Exercise?
    
    @Relationship(deleteRule: .nullify, inverse: \Workout.sets)
    var workout: Workout?
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double,
        reps: Int,
        rpe: Int? = nil,
        timestamp: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.timestamp = timestamp
        self.notes = notes
    }
    
    /// Computed property for estimated 1RM using Brzycki formula
    var estimated1RM: Double {
        guard reps > 0, reps < 37 else { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    
    /// Volume for this set (weight × reps)
    var volume: Double {
        return weight * Double(reps)
    }
}

