//
//  AppConfiguration.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation

enum AppConfiguration {
    // MARK: - API Endpoints
    
    /// Open Food Facts API base URL (Free/Open Source)
    static let openFoodFactsBaseURL = "https://world.openfoodfacts.org/api/v2"
    
    // MARK: - Default Nutrition Targets
    
    static let defaultProteinTarget = 150.0 // grams
    static let defaultCarbTarget = 200.0 // grams
    static let defaultFatTarget = 65.0 // grams
    static let defaultCalorieTarget = 2200.0 // calories
    
    // MARK: - Default Goals
    
    static let defaultSleepGoalHours = 7.5
    
    // MARK: - Recovery Score Weights
    
    static let sleepWeight = 0.4
    static let proteinWeight = 0.35
    static let restWeight = 0.25
    
    // MARK: - Volume Thresholds
    
    /// Percentile threshold for "high volume" workout
    static let highVolumePercentile = 0.8
    
    /// Maximum carb boost for high volume recovery (grams)
    static let maxCarbBoost = 40.0
    
    /// Maximum protein boost for high volume recovery (grams)
    static let maxProteinBoost = 20.0
    
    // MARK: - Protein Recommendations
    
    /// Minimum protein per pound of bodyweight for muscle synthesis
    static let minProteinPerPound = 0.7
    
    /// Optimal protein per pound of bodyweight for muscle gain
    static let optimalProteinPerPound = 0.9
    
    // MARK: - Caloric Thresholds
    
    /// Caloric deficit threshold for triggering suggestions (calories)
    static let significantDeficitThreshold = 300.0
    
    // MARK: - UI Configuration
    
    /// Number of recent workouts to cache
    static let recentWorkoutsLimit = 10
    
    /// Number of recent foods to display
    static let recentFoodsLimit = 10
    
    /// Default rest timer duration (seconds)
    static let defaultRestTimerSeconds = 90
    
    // MARK: - Cache Settings
    
    /// Number of days to keep in correlation view
    static let correlationDaysDefault = 7
    
    /// Maximum number of search results to return
    static let maxSearchResults = 15
    
    // MARK: - App Info
    
    static let appName = "IronPath"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}

