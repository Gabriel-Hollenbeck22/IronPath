//
//  Exercise.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: Equipment
    var isCompound: Bool
    var instructions: String?
    
    @Relationship(deleteRule: .nullify, inverse: \WorkoutSet.exercise)
    var workoutSets: [WorkoutSet]?
    
    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment = .bodyweight,
        isCompound: Bool = false,
        instructions: String? = nil
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.isCompound = isCompound
        self.instructions = instructions
    }
}

// MARK: - Supporting Enums

enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case quads
    case hamstrings
    case glutes
    case calves
    case abs
    case fullBody
    
    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell
    case dumbbell
    case kettlebell
    case machine
    case cable
    case bodyweight
    case band
    case other
    
    var displayName: String {
        rawValue.capitalized
    }
}

