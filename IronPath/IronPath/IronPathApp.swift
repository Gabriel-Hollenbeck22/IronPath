//
//  IronPathApp.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/26/25.
//

import SwiftUI
import SwiftData

@main
struct IronPathApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Core Models
            UserProfile.self,
            DailySummary.self,
            
            // Workout Models
            Exercise.self,
            Workout.self,
            WorkoutSet.self,
            
            // Nutrition Models
            FoodItem.self,
            LoggedFood.self,
            Recipe.self,
            RecipeIngredient.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
