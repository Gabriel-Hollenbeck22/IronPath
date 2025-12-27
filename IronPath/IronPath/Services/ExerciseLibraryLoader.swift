//
//  ExerciseLibraryLoader.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import SwiftData

/// Utility to load bundled exercises from JSON into SwiftData
final class ExerciseLibraryLoader {
    
    struct ExerciseLibrary: Codable {
        let exercises: [ExerciseData]
    }
    
    struct ExerciseData: Codable {
        let name: String
        let muscleGroup: String
        let equipment: String
        let isCompound: Bool
        let instructions: String?
    }
    
    /// Load exercises from bundled JSON file
    static func loadExercises() -> [ExerciseData] {
        guard let url = Bundle.main.url(forResource: "ExerciseLibrary", withExtension: "json") else {
            print("Error: Could not find ExerciseLibrary.json in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let library = try decoder.decode(ExerciseLibrary.self, from: data)
            return library.exercises
        } catch {
            print("Error loading exercise library: \(error)")
            return []
        }
    }
    
    /// Import exercises into SwiftData (run once on first launch)
    static func importExercisesIfNeeded(modelContext: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        
        do {
            let existingExercises = try modelContext.fetch(descriptor)
            
            // Only import if database is empty
            guard existingExercises.isEmpty else {
                print("Exercises already loaded in database")
                return
            }
            
            let exerciseData = loadExercises()
            print("Importing \(exerciseData.count) exercises...")
            
            for data in exerciseData {
                guard let muscleGroup = MuscleGroup(rawValue: data.muscleGroup),
                      let equipment = Equipment(rawValue: data.equipment) else {
                    print("Warning: Invalid data for exercise \(data.name)")
                    continue
                }
                
                let exercise = Exercise(
                    name: data.name,
                    muscleGroup: muscleGroup,
                    equipment: equipment,
                    isCompound: data.isCompound,
                    instructions: data.instructions
                )
                
                modelContext.insert(exercise)
            }
            
            try modelContext.save()
            print("Successfully imported \(exerciseData.count) exercises")
            
        } catch {
            print("Error checking/importing exercises: \(error)")
        }
    }
    
    /// Get exercises filtered by muscle group
    static func getExercises(
        for muscleGroup: MuscleGroup,
        modelContext: ModelContext
    ) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.muscleGroup == muscleGroup
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching exercises: \(error)")
            return []
        }
    }
    
    /// Search exercises by name
    static func searchExercises(
        query: String,
        modelContext: ModelContext
    ) -> [Exercise] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.name.localizedStandardContains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error searching exercises: \(error)")
            return []
        }
    }
}

