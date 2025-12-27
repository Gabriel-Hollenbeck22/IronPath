# IronPath - Bio-Feedback Fitness App

> **Status:** ✅ Core Architecture Complete - Ready for UI Development

A high-performance iOS fitness app that eliminates the friction between "What I lift" and "What I eat" by treating lifting data and nutritional data as two halves of a single goal.

## 🎯 Core Vision

IronPath is built on the principle that your training and nutrition are inseparable. The app provides:

- **Unified Logic:** High-volume leg day? The app automatically suggests a "Recovery Buffer" in your macros.
- **Smart Insights:** See how your protein dip two days ago affected your strength today.
- **Bio-Feedback Loop:** Sleep, nutrition, and training volume all feed into your daily Recovery Score.
- **Cost-Conscious:** Free to run - no paid APIs, no backend servers, local-first architecture.

## 📊 What's Been Built

### ✅ Complete Core Architecture

All foundational systems are implemented and tested:

1. **SwiftData Models** (8 models)
   - Workout domain (Exercise, Workout, WorkoutSet)
   - Nutrition domain (FoodItem, LoggedFood, Recipe)
   - Core domain (UserProfile, DailySummary)

2. **Service Layer** (5 services)
   - WorkoutManager - Volume calculations, 1RM tracking, PR detection
   - NutritionService - Three-tier search, food logging, meal suggestions
   - IntegrationEngine - Recovery scores, smart suggestions, correlation analysis
   - HealthKitManager - Sleep, weight, calories, steps
   - ExerciseLibraryLoader - 200+ bundled exercises

3. **Integration Engine** (The "Bio-Feedback" Core)
   - Recovery Score calculation (sleep + protein + rest)
   - Dynamic macro adjustments for high-volume workouts
   - Smart suggestions (plateau detection, protein warnings, recovery alerts)
   - 7-day correlation data for visualization

4. **Supporting Infrastructure**
   - AppConfiguration - Centralized constants
   - ExerciseLibrary.json - 200+ exercises across all muscle groups
   - Proper SwiftData relationships with cascade rules

See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for complete technical documentation.

## 🏗️ Technical Stack

- **Language:** Swift 6 / SwiftUI
- **Persistence:** SwiftData (Primary) + HealthKit (System-level sync)
- **Nutrition Data:** Open Food Facts API (Free/Open Source)
- **Architecture:** MVVM with @Observable (iOS 17+)
- **Deployment:** iOS 17+
- **Cost:** $0 (no paid APIs or backends)

## 🔄 The Integration Engine

The heart of IronPath is the Integration Engine, which connects three data streams:

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Workouts  │────▶│  Integration     │────▶│   Smart     │
│  (Volume)   │     │    Engine        │     │ Suggestions │
└─────────────┘     │                  │     └─────────────┘
                    │  • Recovery Score│
┌─────────────┐     │  • Buffer Calc   │     ┌─────────────┐
│  Nutrition  │────▶│  • Correlation   │────▶│   Macro     │
│  (Macros)   │     │  • Suggestions   │     │ Adjustments │
└─────────────┘     └──────────────────┘     └─────────────┘
                            ▲
┌─────────────┐             │
│  HealthKit  │─────────────┘
│  (Sleep)    │
└─────────────┘
```

### Key Formulas

**Recovery Score:**
```
Score = (Sleep × 0.4) + (Protein × 0.35) + (Rest × 0.25)
```

**1RM Estimation (Brzycki):**
```
1RM = Weight × (36 / (37 - Reps))
```

**Recovery Buffer (High Volume):**
```
If volume > 80th percentile:
  Carb Boost = 40g × normalized percentile
  Protein Boost = 20g × normalized percentile
```

## 📱 Next Steps: UI Development

The data layer is complete. Here's what needs to be built:

### Phase 1: Core Views (Minimum Viable Product)
1. **Workout Logger** - Live session interface with set tracking
2. **Nutrition Logger** - Food search, barcode scan, quick entry
3. **Dashboard** - Recovery score, suggestions, macro progress
4. **Profile Setup** - Initial onboarding, target configuration

### Phase 2: Enhanced Experience
5. **Analytics** - Charts for volume trends, 1RM progression, correlation
6. **History** - Workout list, food diary, calendar view
7. **Exercise Library** - Browse, search, view instructions
8. **Recipe Builder** - Create custom meals

### Phase 3: Polish
9. **Settings** - HealthKit setup, units, notifications
10. **Haptics & Animations** - Professional feel with micro-interactions
11. **Dark Mode Refinement** - "Midnight Professional" aesthetic
12. **Quick Actions** - Home screen shortcuts, widgets

## 🎨 Design Philosophy

- **Midnight Professional:** Dark mode default, high-contrast typography
- **Glassmorphism:** Material backgrounds, smooth transitions
- **Haptic Feedback:** Button presses, set completions, goal achievements
- **Simplicity:** Minimize taps to log - swipe actions for editing/deleting
- **Offline-First:** Perfect functionality with zero cell service

## 🧪 Testing the Architecture

Run the app to see the status screen. Try this workflow:

1. Tap "Initialize Sample Data" to create a UserProfile
2. Exercise library auto-loads on first launch (200+ exercises)
3. Ready for UI implementation

To manually test services (in a view or preview):

```swift
let workoutManager = WorkoutManager(modelContext: modelContext)
let workout = workoutManager.startWorkout(name: "Push Day")

let exercise = exercises.first! // Get from @Query
try workoutManager.logSet(
    exercise: exercise,
    setNumber: 1,
    weight: 225,
    reps: 5,
    rpe: 8
)

try workoutManager.completeWorkout()
```

## 📂 Project Structure

```
IronPath/
├── IronPath/
│   ├── Models/
│   │   ├── Workout/      (Exercise, Workout, WorkoutSet)
│   │   ├── Nutrition/    (FoodItem, LoggedFood, Recipe)
│   │   └── Core/         (UserProfile, DailySummary)
│   ├── Services/
│   │   ├── WorkoutManager.swift
│   │   ├── NutritionService.swift
│   │   ├── IntegrationEngine.swift
│   │   ├── HealthKitManager.swift
│   │   └── ExerciseLibraryLoader.swift
│   ├── Configuration/
│   │   └── AppConfiguration.swift
│   ├── Resources/
│   │   └── ExerciseLibrary.json (200+ exercises)
│   ├── IronPathApp.swift
│   └── ContentView.swift
├── IMPLEMENTATION_SUMMARY.md (Detailed technical docs)
└── README.md (This file)
```

## ⚙️ Setup Requirements

### Info.plist Additions (Required for HealthKit)

```xml
<key>NSHealthShareUsageDescription</key>
<string>IronPath needs access to read your sleep, weight, and activity data to provide personalized recovery recommendations.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>IronPath needs permission to save your body weight measurements.</string>
```

### Xcode Capabilities
- Enable HealthKit in Signing & Capabilities
- Camera permission (for future barcode scanning)

## 🚀 Quick Start

1. Open `IronPath.xcodeproj` in Xcode
2. Add HealthKit capability
3. Update Info.plist with usage descriptions
4. Build and run (iOS 17+ simulator or device)
5. The exercise library will auto-import on first launch
6. Begin building UI views connected to the services

## 📖 Documentation

- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Complete technical documentation
  - All models and their relationships
  - Service APIs and usage examples
  - Integration Engine formulas
  - Data flow diagrams
  - Smart suggestion triggers
  - Testing recommendations

## 💡 Key Design Decisions

1. **@Observable over ObservableObject** - Better performance, cleaner syntax (iOS 17+)
2. **Three-Tier Food Search** - User history → Bundled → API (minimize network calls)
3. **Cached Macros in LoggedFood** - Fast daily summary calculations
4. **Pre-computed Recovery Scores** - Stored in DailySummary for instant dashboard loads
5. **Volume Percentiles** - User-relative workout intensity tracking
6. **Local Exercise Library** - No API calls for common exercises

## 🎯 Success Metrics

The architecture is designed to support:
- ⚡️ **Instant offline access** - All core features work without internet
- 💾 **Efficient storage** - SwiftData handles large datasets smoothly
- 🔒 **Privacy-first** - No data leaves the device except optional HealthKit
- 🎨 **Smooth UX** - Pre-computed values for fast UI updates
- 📊 **Rich insights** - Correlation data enables powerful visualizations

## 🤝 Contributing

This is a personal project, but the architecture is clean and modular. Key extension points:

- **Custom Formulas** - Add new 1RM formulas in WorkoutSet
- **Additional Suggestions** - Extend `IntegrationEngine.generateSuggestions()`
- **New Health Metrics** - Add to HealthKitManager and DailySummary
- **Alternative APIs** - Swap NutritionService API in AppConfiguration

## 📄 License

Private project - All rights reserved.

---

**Built with:** Swift 6, SwiftUI, SwiftData, HealthKit  
**Developer:** Gabriel Hollenbeck  
**Status:** Core Architecture Complete ✅  
**Next Phase:** UI Development 🎨

*"Your workouts inform your nutrition. Your nutrition powers your workouts. IronPath connects the two."*

