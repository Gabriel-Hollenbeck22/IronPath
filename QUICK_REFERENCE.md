# IronPath Quick Reference Guide

Quick snippets for common operations during UI development.

## 🏋️ WorkoutManager Operations

### Start a Workout Session
```swift
@Environment(\.modelContext) private var modelContext
@State private var workoutManager: WorkoutManager?

// Initialize
.onAppear {
    workoutManager = WorkoutManager(modelContext: modelContext)
}

// Start workout
let workout = workoutManager?.startWorkout(name: "Push Day")
```

### Log a Set
```swift
do {
    let set = try workoutManager?.logSet(
        exercise: selectedExercise,
        setNumber: 1,
        weight: 225.0,
        reps: 5,
        rpe: 8
    )
} catch {
    print("Error logging set: \(error)")
}
```

### Complete Workout
```swift
do {
    try workoutManager?.completeWorkout()
    // Navigate away or show success
} catch {
    print("Error completing workout: \(error)")
}
```

### Get Weekly Volume
```swift
let weeklyVolume = workoutManager?.getWeeklyVolume() ?? 0
Text("Weekly Volume: \(Int(weeklyVolume)) lbs")
```

### Get Personal Record
```swift
if let pr = workoutManager?.getPersonalRecord(for: exercise) {
    Text("PR: \(Int(pr.weight)) lbs × \(pr.reps) reps")
    Text("Estimated 1RM: \(Int(pr.estimated1RM)) lbs")
}
```

## 🍎 NutritionService Operations

### Initialize Service
```swift
@State private var nutritionService: NutritionService?

.onAppear {
    nutritionService = NutritionService(modelContext: modelContext)
}
```

### Search for Food
```swift
@State private var searchResults: [FoodSearchResult] = []

Task {
    do {
        searchResults = try await nutritionService?.searchFood(query: "chicken") ?? []
    } catch {
        print("Search error: \(error)")
    }
}
```

### Display Search Results
```swift
ForEach(searchResults, id: \.foodItem.id) { result in
    HStack {
        VStack(alignment: .leading) {
            Text(result.foodItem.name)
            Text("\(Int(result.foodItem.proteinPer100g))g protein per 100g")
                .font(.caption)
        }
        Spacer()
        Text(result.sourceLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

### Log Food
```swift
do {
    try nutritionService?.logFood(
        foodItem: selectedFood,
        servingSizeGrams: 200.0,
        mealType: .lunch
    )
} catch {
    print("Error logging food: \(error)")
}
```

### Quick Meal Entry
```swift
do {
    try nutritionService?.logQuickMeal(
        name: "Post-Workout Shake",
        calories: 400,
        protein: 40,
        carbs: 50,
        fat: 8,
        mealType: .postworkout
    )
} catch {
    print("Error logging quick meal: \(error)")
}
```

### Get Today's Summary
```swift
if let summary = try? nutritionService?.getTodaysSummary() {
    Text("Calories: \(Int(summary.totalCalories))")
    Text("Protein: \(Int(summary.totalProtein))g")
    Text("Carbs: \(Int(summary.totalCarbs))g")
    Text("Fat: \(Int(summary.totalFat))g")
}
```

### Get Meal Suggestions
```swift
let suggestions = nutritionService?.getSuggestionsForMealType(.breakfast) ?? []
ForEach(suggestions) { food in
    Text(food.name)
}
```

## 🧠 IntegrationEngine Operations

### Initialize Engine
```swift
@State private var integrationEngine: IntegrationEngine?

.onAppear {
    integrationEngine = IntegrationEngine(modelContext: modelContext)
}
```

### Display Recovery Score
```swift
if let engine = integrationEngine,
   let profile = userProfile {
    let score = engine.calculateRecoveryScore(
        for: Date(),
        profile: profile,
        sleepHours: todaysSummary?.sleepHours,
        proteinIntake: todaysSummary?.totalProtein,
        lastWorkoutDate: lastWorkout?.date
    )
    
    ZStack {
        Circle()
            .stroke(Color.gray.opacity(0.3), lineWidth: 10)
        Circle()
            .trim(from: 0, to: score / 100.0)
            .stroke(scoreColor(score), lineWidth: 10)
            .rotationEffect(.degrees(-90))
        
        VStack {
            Text("\(Int(score))")
                .font(.system(size: 48, weight: .bold))
            Text("Recovery")
                .font(.caption)
        }
    }
    .frame(width: 150, height: 150)
}

func scoreColor(_ score: Double) -> Color {
    if score >= 80 { return .green }
    if score >= 60 { return .yellow }
    return .red
}
```

### Generate and Display Suggestions
```swift
@State private var suggestions: [SmartSuggestion] = []

Task {
    do {
        suggestions = try await integrationEngine?.generateSuggestions(profile: userProfile) ?? []
    } catch {
        print("Error generating suggestions: \(error)")
    }
}

// Display
ForEach(suggestions) { suggestion in
    HStack {
        Image(systemName: iconForType(suggestion.type))
            .foregroundColor(colorForPriority(suggestion.priority))
        
        VStack(alignment: .leading) {
            Text(suggestion.title)
                .font(.headline)
            Text(suggestion.message)
                .font(.caption)
        }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
}

func iconForType(_ type: SuggestionType) -> String {
    switch type {
    case .nutrition: return "fork.knife"
    case .workout: return "dumbbell.fill"
    case .recovery: return "bed.double.fill"
    case .general: return "info.circle"
    }
}

func colorForPriority(_ priority: SuggestionPriority) -> Color {
    switch priority {
    case .high: return .red
    case .medium: return .orange
    case .low: return .blue
    }
}
```

### Get Correlation Data for Chart
```swift
@State private var correlationData: CorrelationData?

Task {
    do {
        correlationData = try integrationEngine?.generateCorrelationData(days: 7)
    } catch {
        print("Error generating correlation data: \(error)")
    }
}

// Use with Swift Charts
if let data = correlationData {
    Chart {
        ForEach(data.dataPoints, id: \.date) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Protein", point.proteinIntake)
            )
            .foregroundStyle(.blue)
            
            LineMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.workoutVolume / 10) // Scale for display
            )
            .foregroundStyle(.orange)
        }
    }
}
```

## 💓 HealthKitManager Operations

### Initialize and Request Authorization
```swift
@State private var healthKitManager = HealthKitManager()

Button("Enable HealthKit") {
    Task {
        do {
            try await healthKitManager.requestAuthorization()
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
}
```

### Sync Today's Data
```swift
Task {
    do {
        try await healthKitManager.syncTodaysData()
        
        // Access synced data
        if let weight = healthKitManager.latestBodyWeight {
            Text("Weight: \(Int(weight)) lbs")
        }
        
        if let sleep = healthKitManager.todaySleepHours {
            Text("Sleep: \(sleep, specifier: "%.1f") hours")
        }
        
        if let calories = healthKitManager.todayActiveCalories {
            Text("Active Calories: \(Int(calories)) kcal")
        }
    } catch {
        print("Sync failed: \(error)")
    }
}
```

### Save Body Weight
```swift
Button("Log Weight") {
    Task {
        do {
            try await healthKitManager.saveBodyWeight(weightInPounds)
        } catch {
            print("Error saving weight: \(error)")
        }
    }
}
```

## 🗂️ SwiftData Queries

### Query Exercises
```swift
// All exercises
@Query private var exercises: [Exercise]

// By muscle group
@Query(
    filter: #Predicate<Exercise> { $0.muscleGroup == .chest },
    sort: \.name
) private var chestExercises: [Exercise]

// Search by name
@Query(
    filter: #Predicate<Exercise> { exercise in
        exercise.name.localizedStandardContains("press")
    }
) private var pressExercises: [Exercise]
```

### Query Workouts
```swift
// Recent workouts
@Query(
    filter: #Predicate<Workout> { $0.isCompleted },
    sort: [SortDescriptor(\.date, order: .reverse)]
) private var workouts: [Workout]

// This week's workouts
@Query(
    filter: #Predicate<Workout> { workout in
        workout.date >= Calendar.current.startOfWeek(for: Date()) &&
        workout.isCompleted
    }
) private var thisWeeksWorkouts: [Workout]
```

### Query Daily Summaries
```swift
// Last 7 days
@Query(
    filter: #Predicate<DailySummary> { summary in
        summary.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    },
    sort: [SortDescriptor(\.date)]
) private var recentSummaries: [DailySummary]
```

### Query Food Items
```swift
// Recent foods
@Query(
    filter: #Predicate<FoodItem> { $0.lastUsed != nil },
    sort: [SortDescriptor(\.lastUsed, order: .reverse)]
) private var recentFoods: [FoodItem]

// Favorites
@Query(
    filter: #Predicate<FoodItem> { $0.isFavorite },
    sort: [SortDescriptor(\.name)]
) private var favoriteFoods: [FoodItem]

// High protein
@Query(
    filter: #Predicate<FoodItem> { $0.proteinPer100g >= 25.0 }
) private var highProteinFoods: [FoodItem]
```

## 🎨 Common UI Patterns

### Macro Progress Ring
```swift
struct MacroRingView: View {
    let current: Double
    let target: Double
    let color: Color
    let label: String
    
    var progress: Double {
        min(current / target, 1.0)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(current))")
                        .font(.headline)
                    Text("/ \(Int(target))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            
            Text(label)
                .font(.caption)
        }
    }
}

// Usage
HStack(spacing: 20) {
    MacroRingView(
        current: summary.totalProtein,
        target: profile.targetProtein,
        color: .blue,
        label: "Protein"
    )
    MacroRingView(
        current: summary.totalCarbs,
        target: profile.targetCarbs,
        color: .orange,
        label: "Carbs"
    )
    MacroRingView(
        current: summary.totalFat,
        target: profile.targetFat,
        color: .purple,
        label: "Fat"
    )
}
```

### Exercise Selector
```swift
struct ExercisePickerView: View {
    @Query private var exercises: [Exercise]
    @Binding var selectedExercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    
    var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedStandardContains(searchText)) &&
            (selectedMuscleGroup == nil || exercise.muscleGroup == selectedMuscleGroup)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Button(group.displayName) {
                                selectedMuscleGroup = selectedMuscleGroup == group ? nil : group
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedMuscleGroup == group ? .blue : .gray)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Exercise list
                ForEach(filteredExercises) { exercise in
                    Button {
                        selectedExercise = exercise
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            HStack {
                                Text(exercise.muscleGroup.displayName)
                                Text("•")
                                Text(exercise.equipment.displayName)
                                if exercise.isCompound {
                                    Text("• Compound")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

### Rest Timer
```swift
struct RestTimerView: View {
    @State private var timeRemaining = AppConfiguration.defaultRestTimerSeconds
    @State private var isActive = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("\(timeRemaining)s")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            HStack(spacing: 20) {
                Button(isActive ? "Pause" : "Start") {
                    isActive.toggle()
                    if isActive {
                        // Haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset") {
                    timeRemaining = AppConfiguration.defaultRestTimerSeconds
                    isActive = false
                }
                .buttonStyle(.bordered)
            }
        }
        .onReceive(timer) { _ in
            if isActive && timeRemaining > 0 {
                timeRemaining -= 1
                
                if timeRemaining == 0 {
                    // Completion haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }
}
```

## 🔧 AppConfiguration Constants

Quick access to common values:

```swift
// API
AppConfiguration.openFoodFactsBaseURL

// Defaults
AppConfiguration.defaultProteinTarget        // 150g
AppConfiguration.defaultCarbTarget           // 200g
AppConfiguration.defaultFatTarget            // 65g
AppConfiguration.defaultCalorieTarget        // 2200

// Thresholds
AppConfiguration.highVolumePercentile        // 0.8
AppConfiguration.minProteinPerPound          // 0.7g
AppConfiguration.significantDeficitThreshold // 300 cal

// UI
AppConfiguration.recentWorkoutsLimit         // 10
AppConfiguration.defaultRestTimerSeconds     // 90
AppConfiguration.correlationDaysDefault      // 7
```

## 📱 Common Enums

```swift
// Muscle Groups
MuscleGroup.chest, .back, .shoulders, .biceps, .triceps, .forearms,
.quads, .hamstrings, .glutes, .calves, .abs, .fullBody

// Equipment
Equipment.barbell, .dumbbell, .kettlebell, .machine, .cable,
.bodyweight, .band, .other

// Meal Types
MealType.breakfast, .lunch, .dinner, .snack, .preworkout, .postworkout

// Food Sources
FoodSource.userHistory, .bundled, .openFoodFacts, .manual

// Activity Levels
ActivityLevel.sedentary, .light, .moderate, .active, .veryActive

// Fitness Goals
FitnessGoal.muscleGain, .fatLoss, .maintenance, .athleticPerformance, .generalHealth
```

---

**Pro Tip:** Use Xcode's code completion with these snippets. Most patterns follow consistent naming and structure across services.

