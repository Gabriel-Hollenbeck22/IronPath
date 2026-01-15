//
//  MuscleStrengthCalculator.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 1/14/26.
//

import Foundation
import SwiftData
import SwiftUI

/// Strength categories based on ExRx standards
enum StrengthCategory: String, CaseIterable {
    case rookie
    case average
    case intermediate
    case advanced
    case elite
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .rookie: return .red
        case .average: return .orange
        case .intermediate: return .yellow
        case .advanced: return .green
        case .elite: return .blue
        }
    }
}

/// Calculates comparative strength scores for each muscle group
/// Compares user performance against ExRx strength standards
final class MuscleStrengthCalculator {
    private let modelContext: ModelContext
    private let userProfile: UserProfile?
    
    init(modelContext: ModelContext, userProfile: UserProfile? = nil) {
        self.modelContext = modelContext
        self.userProfile = userProfile
    }
    
    /// Calculate strength categories for all muscle groups
    /// Returns a dictionary mapping MuscleGroup to StrengthCategory
    /// Always returns categories for ALL muscle groups, defaulting to .rookie if no data
    func calculateStrengthCategories() -> [MuscleGroup: StrengthCategory] {
        var categories: [MuscleGroup: StrengthCategory] = [:]
        
        guard let profile = userProfile,
              let bodyWeight = profile.bodyWeight,
              let biologicalSex = profile.biologicalSex else {
            // Return all as rookie if no profile data
            for muscleGroup in MuscleGroup.allCases {
                categories[muscleGroup] = .rookie
            }
            return categories
        }
        
        // Always calculate for all muscle groups
        for muscleGroup in MuscleGroup.allCases {
            let category = calculateCategoryForMuscleGroup(
                muscleGroup: muscleGroup,
                bodyWeight: bodyWeight,
                biologicalSex: biologicalSex
            )
            categories[muscleGroup] = category
        }
        
        // Double-check: ensure all muscle groups are present
        for muscleGroup in MuscleGroup.allCases {
            if categories[muscleGroup] == nil {
                categories[muscleGroup] = .rookie
            }
        }
        
        return categories
    }
    
    /// Calculate strength category for a specific muscle group
    private func calculateCategoryForMuscleGroup(
        muscleGroup: MuscleGroup,
        bodyWeight: Double,
        biologicalSex: BiologicalSex
    ) -> StrengthCategory {
        // Fetch all workout sets for exercises targeting this muscle group
        let allSets = fetchSetsForMuscleGroup(muscleGroup: muscleGroup)
        
        // Always return a category, default to rookie if no data
        guard !allSets.isEmpty else {
            return .rookie // No data = rookie
        }
        
        // Calculate average 1RM and volume
        let avg1RM = average1RM(sets: allSets)
        let avgVolume = averageVolume(sets: allSets)
        
        // Get exercises for this muscle group to find standards
        let exercises = fetchExercisesForMuscleGroup(muscleGroup: muscleGroup)
        
        // Calculate category based on exercises
        var categories: [StrengthCategory] = []
        
        for exercise in exercises {
            let exerciseSets = allSets.filter { $0.exercise?.id == exercise.id }
            guard !exerciseSets.isEmpty else { continue }
            
            let exercise1RM = average1RM(sets: exerciseSets)
            let exerciseVolume = averageVolume(sets: exerciseSets)
            
            // Get standard for this exercise
            if let standard = getStrengthStandard(
                exerciseName: exercise.name,
                muscleGroup: muscleGroup,
                bodyWeight: bodyWeight,
                biologicalSex: biologicalSex
            ) {
                // Compare 1RM (60% weight)
                let oneRMCategory = compareToStandard(
                    value: exercise1RM,
                    standard: standard,
                    useRelative: standard.isBodyweightRelative
                )
                
                // Compare volume (40% weight) - use volume relative to bodyweight for comparison
                let volumePerBodyweight = exerciseVolume / bodyWeight
                let volumeCategory = compareVolumeToStandard(
                    volumePerBodyweight: volumePerBodyweight,
                    standard: standard,
                    biologicalSex: biologicalSex
                )
                
                // Weighted combination: 60% 1RM, 40% volume
                let combinedCategory = combineCategories(
                    category1: oneRMCategory,
                    weight1: 0.6,
                    category2: volumeCategory,
                    weight2: 0.4
                )
                
                categories.append(combinedCategory)
            }
        }
        
        // If no exercise-specific standards found, use muscle group average
        if categories.isEmpty {
            return compareToMuscleGroupAverage(
                avg1RM: avg1RM,
                avgVolume: avgVolume,
                bodyWeight: bodyWeight,
                muscleGroup: muscleGroup,
                biologicalSex: biologicalSex
            )
        }
        
        // Average categories across exercises
        return averageCategories(categories)
    }
    
    /// Fetch all workout sets for exercises targeting a specific muscle group
    private func fetchSetsForMuscleGroup(muscleGroup: MuscleGroup) -> [WorkoutSet] {
        let descriptor = FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let allSets = try modelContext.fetch(descriptor)
            return allSets.filter { set in
                set.exercise?.muscleGroup == muscleGroup
            }
        } catch {
            print("Error fetching sets for muscle group: \(error)")
            return []
        }
    }
    
    /// Fetch exercises for a muscle group
    private func fetchExercisesForMuscleGroup(muscleGroup: MuscleGroup) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        
        do {
            let allExercises = try modelContext.fetch(descriptor)
            return allExercises.filter { $0.muscleGroup == muscleGroup }
        } catch {
            print("Error fetching exercises: \(error)")
            return []
        }
    }
    
    /// Calculate average volume (weight × reps) for a set of workout sets
    private func averageVolume(sets: [WorkoutSet]) -> Double {
        guard !sets.isEmpty else { return 0 }
        let totalVolume = sets.reduce(0.0) { $0 + $1.volume }
        return totalVolume / Double(sets.count)
    }
    
    /// Calculate average estimated 1RM for a set of workout sets
    private func average1RM(sets: [WorkoutSet]) -> Double {
        guard !sets.isEmpty else { return 0 }
        let total1RM = sets.reduce(0.0) { $0 + $1.estimated1RM }
        return total1RM / Double(sets.count)
    }
    
    /// Get strength standard for an exercise
    private func getStrengthStandard(
        exerciseName: String,
        muscleGroup: MuscleGroup,
        bodyWeight: Double,
        biologicalSex: BiologicalSex
    ) -> ExRxStandard? {
        let lowercasedName = exerciseName.lowercased()
        
        // Check for specific exercise matches
        for (key, standard) in ExRxStandards.standards {
            if lowercasedName.contains(key.lowercased()) {
                // Adjust for sex first, then convert to absolute if needed
                let adjusted = ExRxStandards.adjustForSex(standard, biologicalSex: biologicalSex)
                return adjusted.getStandard(
                    bodyWeight: bodyWeight,
                    biologicalSex: biologicalSex
                )
            }
        }
        
        // Fall back to muscle group average
        return ExRxStandards.getMuscleGroupAverage(
            muscleGroup: muscleGroup,
            bodyWeight: bodyWeight,
            biologicalSex: biologicalSex
        )
    }
    
    /// Compare value to standard and return category
    private func compareToStandard(
        value: Double,
        standard: ExRxStandard,
        useRelative: Bool
    ) -> StrengthCategory {
        let actualValue = useRelative ? value : value
        
        if actualValue >= standard.elite {
            return .elite
        } else if actualValue >= standard.advanced {
            return .advanced
        } else if actualValue >= standard.intermediate {
            return .intermediate
        } else if actualValue >= standard.average {
            return .average
        } else {
            return .rookie
        }
    }
    
    /// Compare volume to standard
    private func compareVolumeToStandard(
        volumePerBodyweight: Double,
        standard: ExRxStandard,
        biologicalSex: BiologicalSex
    ) -> StrengthCategory {
        // Volume standards are approximate - use 1RM standards scaled down
        // Typical volume per bodyweight for intermediate: ~2-3x bodyweight per set
        let volumeStandard = ExRxStandard(
            rookie: standard.rookie * 1.5,
            average: standard.average * 1.8,
            intermediate: standard.intermediate * 2.2,
            advanced: standard.advanced * 2.5,
            elite: standard.elite * 3.0,
            isBodyweightRelative: true
        )
        
        return compareToStandard(
            value: volumePerBodyweight,
            standard: volumeStandard,
            useRelative: true
        )
    }
    
    /// Compare to muscle group average when no specific exercise standards exist
    private func compareToMuscleGroupAverage(
        avg1RM: Double,
        avgVolume: Double,
        bodyWeight: Double,
        muscleGroup: MuscleGroup,
        biologicalSex: BiologicalSex
    ) -> StrengthCategory {
        guard let standard = ExRxStandards.getMuscleGroupAverage(
            muscleGroup: muscleGroup,
            bodyWeight: bodyWeight,
            biologicalSex: biologicalSex
        ) else {
            return .rookie
        }
        
        let oneRMCategory = compareToStandard(
            value: avg1RM,
            standard: standard,
            useRelative: standard.isBodyweightRelative
        )
        
        let volumePerBodyweight = avgVolume / bodyWeight
        let volumeCategory = compareVolumeToStandard(
            volumePerBodyweight: volumePerBodyweight,
            standard: standard,
            biologicalSex: biologicalSex
        )
        
        return combineCategories(
            category1: oneRMCategory,
            weight1: 0.6,
            category2: volumeCategory,
            weight2: 0.4
        )
    }
    
    /// Combine two categories with weights
    private func combineCategories(
        category1: StrengthCategory,
        weight1: Double,
        category2: StrengthCategory,
        weight2: Double
    ) -> StrengthCategory {
        let categoryValues: [StrengthCategory: Double] = [
            .rookie: 1.0,
            .average: 2.0,
            .intermediate: 3.0,
            .advanced: 4.0,
            .elite: 5.0
        ]
        
        let value1 = categoryValues[category1] ?? 1.0
        let value2 = categoryValues[category2] ?? 1.0
        
        let combinedValue = (value1 * weight1) + (value2 * weight2)
        
        if combinedValue >= 4.5 {
            return .elite
        } else if combinedValue >= 3.5 {
            return .advanced
        } else if combinedValue >= 2.5 {
            return .intermediate
        } else if combinedValue >= 1.5 {
            return .average
        } else {
            return .rookie
        }
    }
    
    /// Average multiple categories
    private func averageCategories(_ categories: [StrengthCategory]) -> StrengthCategory {
        guard !categories.isEmpty else { return .rookie }
        
        let categoryValues: [StrengthCategory: Double] = [
            .rookie: 1.0,
            .average: 2.0,
            .intermediate: 3.0,
            .advanced: 4.0,
            .elite: 5.0
        ]
        
        let total = categories.reduce(0.0) { $0 + (categoryValues[$1] ?? 1.0) }
        let average = total / Double(categories.count)
        
        if average >= 4.5 {
            return .elite
        } else if average >= 3.5 {
            return .advanced
        } else if average >= 2.5 {
            return .intermediate
        } else if average >= 1.5 {
            return .average
        } else {
            return .rookie
        }
    }
    
    /// Get color for a strength category
    static func colorForCategory(_ category: StrengthCategory) -> Color {
        category.color
    }
    
    /// Get display label for a strength category
    static func labelForCategory(_ category: StrengthCategory) -> String {
        category.displayName
    }
}

// MARK: - ExRx Strength Standards

struct ExRxStandard {
    let rookie: Double
    let average: Double
    let intermediate: Double
    let advanced: Double
    let elite: Double
    let isBodyweightRelative: Bool
    
    func getStandard(bodyWeight: Double, biologicalSex: BiologicalSex) -> ExRxStandard {
        if isBodyweightRelative {
            return ExRxStandard(
                rookie: rookie * bodyWeight,
                average: average * bodyWeight,
                intermediate: intermediate * bodyWeight,
                advanced: advanced * bodyWeight,
                elite: elite * bodyWeight,
                isBodyweightRelative: false
            )
        }
        return self
    }
}

struct ExRxStandards {
    // Exercise name keywords -> standards
    static let standards: [String: ExRxStandard] = [
        // Chest exercises
        "bench press": ExRxStandard(
            rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
            isBodyweightRelative: true
        ),
        "push up": ExRxStandard(
            rookie: 0.4, average: 0.6, intermediate: 0.8, advanced: 1.0, elite: 1.2,
            isBodyweightRelative: true
        ),
        "chest press": ExRxStandard(
            rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
            isBodyweightRelative: true
        ),
        
        // Back exercises
        "pull up": ExRxStandard(
            rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
            isBodyweightRelative: true
        ),
        "row": ExRxStandard(
            rookie: 0.4, average: 0.6, intermediate: 0.8, advanced: 1.0, elite: 1.2,
            isBodyweightRelative: true
        ),
        "lat pulldown": ExRxStandard(
            rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
            isBodyweightRelative: true
        ),
        
        // Leg exercises
        "squat": ExRxStandard(
            rookie: 0.75, average: 1.0, intermediate: 1.5, advanced: 2.0, elite: 2.5,
            isBodyweightRelative: true
        ),
        "deadlift": ExRxStandard(
            rookie: 1.0, average: 1.5, intermediate: 2.0, advanced: 2.5, elite: 3.0,
            isBodyweightRelative: true
        ),
        "leg press": ExRxStandard(
            rookie: 1.0, average: 1.5, intermediate: 2.0, advanced: 2.5, elite: 3.0,
            isBodyweightRelative: true
        ),
        
        // Shoulder exercises
        "overhead press": ExRxStandard(
            rookie: 0.3, average: 0.5, intermediate: 0.7, advanced: 0.9, elite: 1.1,
            isBodyweightRelative: true
        ),
        "shoulder press": ExRxStandard(
            rookie: 0.3, average: 0.5, intermediate: 0.7, advanced: 0.9, elite: 1.1,
            isBodyweightRelative: true
        ),
        
        // Arm exercises
        "bicep curl": ExRxStandard(
            rookie: 0.15, average: 0.25, intermediate: 0.35, advanced: 0.45, elite: 0.55,
            isBodyweightRelative: true
        ),
        "tricep": ExRxStandard(
            rookie: 0.2, average: 0.3, intermediate: 0.4, advanced: 0.5, elite: 0.6,
            isBodyweightRelative: true
        )
    ]
    
    // Adjust standards for female (typically 60-70% of male standards)
    static func adjustForSex(_ standard: ExRxStandard, biologicalSex: BiologicalSex) -> ExRxStandard {
        guard biologicalSex == .female else { return standard }
        
        let multiplier = 0.65 // Female standards are ~65% of male
        return ExRxStandard(
            rookie: standard.rookie * multiplier,
            average: standard.average * multiplier,
            intermediate: standard.intermediate * multiplier,
            advanced: standard.advanced * multiplier,
            elite: standard.elite * multiplier,
            isBodyweightRelative: standard.isBodyweightRelative
        )
    }
    
    // Get muscle group average standards
    static func getMuscleGroupAverage(
        muscleGroup: MuscleGroup,
        bodyWeight: Double,
        biologicalSex: BiologicalSex
    ) -> ExRxStandard? {
        let baseStandard: ExRxStandard
        
        switch muscleGroup {
        case .chest:
            baseStandard = ExRxStandard(
                rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
                isBodyweightRelative: true
            )
        case .back:
            baseStandard = ExRxStandard(
                rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
                isBodyweightRelative: true
            )
        case .shoulders:
            baseStandard = ExRxStandard(
                rookie: 0.3, average: 0.5, intermediate: 0.7, advanced: 0.9, elite: 1.1,
                isBodyweightRelative: true
            )
        case .biceps:
            baseStandard = ExRxStandard(
                rookie: 0.15, average: 0.25, intermediate: 0.35, advanced: 0.45, elite: 0.55,
                isBodyweightRelative: true
            )
        case .triceps:
            baseStandard = ExRxStandard(
                rookie: 0.2, average: 0.3, intermediate: 0.4, advanced: 0.5, elite: 0.6,
                isBodyweightRelative: true
            )
        case .quads, .hamstrings, .glutes:
            baseStandard = ExRxStandard(
                rookie: 0.75, average: 1.0, intermediate: 1.5, advanced: 2.0, elite: 2.5,
                isBodyweightRelative: true
            )
        case .calves:
            baseStandard = ExRxStandard(
                rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
                isBodyweightRelative: true
            )
        case .abs, .forearms:
            baseStandard = ExRxStandard(
                rookie: 0.2, average: 0.3, intermediate: 0.4, advanced: 0.5, elite: 0.6,
                isBodyweightRelative: true
            )
        case .fullBody:
            baseStandard = ExRxStandard(
                rookie: 0.5, average: 0.75, intermediate: 1.0, advanced: 1.25, elite: 1.5,
                isBodyweightRelative: true
            )
        }
        
        let adjusted = adjustForSex(baseStandard, biologicalSex: biologicalSex)
        return adjusted.getStandard(bodyWeight: bodyWeight, biologicalSex: biologicalSex)
    }
}
