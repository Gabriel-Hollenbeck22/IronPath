# IronPath Project File Guide - Complete Documentation

Welcome! This document explains every single file in the IronPath project in a way that's easy to understand. Think of this as a tour guide for your codebase - we'll walk through each folder and file, explaining what it does and why it exists.

---

## 📁 The Big Picture: How Files Are Organized

Imagine building a house. You need:
- **Foundation** (Models) - The basic structure
- **Plumbing & Electrical** (Services) - The systems that make things work
- **Interior Design** (Views) - What people actually see
- **Building Plans** (Configuration) - Instructions and settings

IronPath is organized the same way! Let's explore each part.

---

## 🏠 Root Level Files

### `.gitignore`

**What it is:** A special file that tells Git (the version control system) which files to ignore and NOT save to the repository.

**Why we need it:** When you're coding, your computer creates lots of temporary files:
- `.DS_Store` files (Mac automatically creates these everywhere)
- Xcode user settings (these are personal to your computer)
- Build artifacts (temporary files created when building)
- Debug logs

**Think of it like this:** When you clean your room before guests come over, you put certain things in the closet. `.gitignore` is like that closet - it tells Git "don't worry about these files, they're not important for other people."

**What's in ours:**
- All `.DS_Store` files (Mac system files)
- `.cursor/` folder (development tools metadata)
- `xcuserdata/` folders (personal Xcode settings)
- `.xcuserstate` files (Xcode remembers your window positions)

---

## 🎯 App Entry Point

### `IronPath/IronPath/IronPathApp.swift`

**What it is:** The very first file that runs when your app starts! It's like the front door of a house - everything starts here.

**Why it exists:** In iOS apps built with SwiftUI, you need one special file marked with `@main` that tells the computer "this is where the app begins!" That's exactly what `IronPathApp.swift` does.

**What it does step-by-step:**
1. **Creates the database container:** Before anything else, it sets up SwiftData (the database system). Think of this like building the filing cabinets before you can store any papers.

2. **Registers all data models:** It tells SwiftData about every type of data we want to store:
   - Exercises (like "Bench Press", "Squat")
   - Workouts (collections of exercises)
   - Workout Sets (individual sets within a workout)
   - Food Items (nutritional information)
   - Food Log Entries (what you actually ate)
   - Quick Add Entries (manually entered food)
   - Macro Targets (your daily nutrition goals)
   - Recipes (saved combinations of foods)
   - Daily Summaries (your complete day's data)
   - Cached Results (saved web search results)

3. **Sets up the window:** Creates the main window where your app will appear.

4. **Connects everything:** Links the database to the app so every screen can access it.

**Think of it like this:** It's the conductor of an orchestra - it makes sure all the instruments (different parts of your app) are ready and know where to be, then starts the music (the app).

**Key Code Explanation:**
- `@main` - This tells Swift "start here!"
- `var sharedModelContainer` - This is a property that creates the database once when the app starts
- `Schema([...])` - This is like a blueprint listing all the different types of data
- `ModelContainer` - This is the actual database that holds all your data
- `WindowGroup` - This creates the window your app displays in

---

## 📊 Data Models (The Foundation)

### `IronPath/IronPath/Models/DomainModels.swift`

**What it is:** This is the BIGGEST file in your app! It defines all the different types of information your app stores. Think of it as the blueprint for every piece of data.

**Why it's important:** Just like a library has rules about how books are organized (fiction vs. non-fiction, by author, etc.), your app needs rules about how data is organized. This file defines those rules.

**Let's break down what's inside:**

#### Enumerations (The Categories)

Think of enumerations like tags or labels. They help us organize things into groups.

1. **`WorkoutType`** - The kind of workout you did
   - Options: push, pull, legs, upper, lower, fullBody, conditioning
   - **Real-world example:** "Today I did a PUSH workout" means you worked chest, shoulders, and triceps

2. **`MuscleGroup`** - Which muscles you're targeting
   - Options: chest, back, legs, shoulders, arms, core, fullBody, conditioning
   - **Real-world example:** When you do bicep curls, the muscle group is "arms"

3. **`Equipment`** - What gear you used
   - Options: barbell, dumbbell, kettlebell, cable, machine, bodyweight, band, suspension, cardio
   - **Real-world example:** A bench press uses a "barbell"

4. **`FoodSource`** - Where the food information came from
   - Options: user (you added it), bundle (came with the app), openFoodFacts (from the internet)
   - **Real-world example:** If you scan a barcode, the source is "openFoodFacts"

5. **`MealTag`** - When you ate the food
   - Options: breakfast, lunch, dinner, snack, preWorkout, postWorkout
   - **Real-world example:** A banana at 7am is tagged as "breakfast"

#### Data Models (The Actual Data Structures)

Now let's look at the actual data models. Each one is like a form with specific fields to fill out.

1. **`Exercise`** - Represents a single exercise
   
   **Think of it like:** A recipe card for an exercise
   
   **What it stores:**
   - `id`: A unique identifier (like a serial number)
   - `name`: The exercise name (like "Bench Press")
   - `muscleGroup`: Which muscles it targets
   - `equipment`: What you need (barbell, dumbbell, etc.)
   - `isBodyweight`: Whether you need equipment or not
   - `defaultReps`: How many reps are typical (helps suggest values)
   - `defaultTempo`: How fast to do it (like "2-1-2" seconds)
   - `defaultRPE`: Rate of Perceived Exertion (how hard it felt)
   - `source`: Where this exercise came from
   
   **Real-world example:** 
   ```
   Exercise(
     name: "Barbell Squat",
     muscleGroup: .legs,
     equipment: .barbell,
     isBodyweight: false,
     defaultReps: 8
   )
   ```

2. **`Workout`** - Represents a complete workout session
   
   **Think of it like:** A workout log entry in a journal
   
   **What it stores:**
   - `id`: Unique identifier
   - `date`: When you did the workout
   - `type`: push, pull, legs, etc.
   - `notes`: Any thoughts or observations
   - `perceivedIntensity`: How hard it felt (1-10 scale)
   - `durationMinutes`: How long it took
   - `sets`: All the sets you did (this is a relationship to WorkoutSet)
   - `totalVolume`: All the weight lifted added up
   - `estimated1RM`: Your estimated one-rep max for the day
   
   **Real-world example:**
   ```
   Workout(
     date: December 26, 2025,
     type: .push,
     notes: "Felt strong today!",
     durationMinutes: 75,
     totalVolume: 15,000 kg
   )
   ```

3. **`WorkoutSet`** - A single set within a workout
   
   **Think of it like:** One line item in your workout log
   
   **What it stores:**
   - `id`: Unique identifier
   - `exercise`: Which exercise you did (links to Exercise)
   - `workout`: Which workout it belongs to (links to Workout)
   - `reps`: How many repetitions
   - `weight`: How much weight (in kg or lbs)
   - `rpe`: Rate of Perceived Exertion (how hard, 1-10)
   - `isWarmup`: Whether this was a warmup set
   - `timestamp`: Exactly when you did it
   - `est1RM`: Estimated one-rep max (calculated using Brzycki formula)
   - `tonnage`: Weight × reps (total weight moved)
   
   **The Brzycki Formula (est1RM calculation):**
   This is a famous formula that estimates how much weight you could lift for exactly 1 rep, based on how many reps you did with a lighter weight. It's like saying "if I can bench 100kg for 5 reps, I could probably bench 114kg for 1 rep!"
   
   Formula: `Weight × (36 / (37 - Reps))`
   
   **Real-world example:**
   ```
   WorkoutSet(
     exercise: BenchPress,
     reps: 5,
     weight: 100kg,
     rpe: 8,
     isWarmup: false
   )
   // This calculates: est1RM = 100 × (36/32) = 112.5kg
   // tonnage = 5 × 100 = 500kg
   ```

4. **`FoodItem`** - Represents a food's nutritional information
   
   **Think of it like:** A nutrition facts label on a food package
   
   **What it stores:**
   - `id`: Unique identifier
   - `name`: The food name (like "Chicken Breast")
   - `caloriesPer100g`: Calories per 100 grams
   - `proteinPer100g`: Protein per 100 grams
   - `carbsPer100g`: Carbohydrates per 100 grams
   - `fatPer100g`: Fat per 100 grams
   - `selectedServingSize`: How much you're eating (in grams)
   - `barcode`: The barcode number (if it has one)
   - `source`: Where this food info came from
   - `createdAt`: When it was added to your database
   
   **Special computed property:**
   - `isHighProtein`: Returns true if the food has more than 25g of protein per serving
   
   **Why per 100g?** This is a standard way to compare foods! It's like having all foods measured the same way so you can compare apples to oranges (literally).
   
   **Real-world example:**
   ```
   FoodItem(
     name: "Chicken Breast",
     caloriesPer100g: 165,
     proteinPer100g: 31,
     carbsPer100g: 0,
     fatPer100g: 3.6,
     selectedServingSize: 200  // 200 grams
   )
   // isHighProtein = true (because 31g × 2 = 62g > 25g)
   ```

5. **`FoodLogEntry`** - Records when you actually ate a food
   
   **Think of it like:** A diary entry for what you ate
   
   **What it stores:**
   - `id`: Unique identifier
   - `date`: When you ate it
   - `foodItem`: Links to the FoodItem (or nil if deleted)
   - `foodName`: The name (saved even if foodItem is deleted)
   - `grams`: How much you ate
   - `protein`, `carbs`, `fat`, `calories`: The actual macros consumed
   - `mealTag`: breakfast, lunch, dinner, etc.
   - `isFavorite`: Whether you marked it as a favorite
   - `source`: Where the food info came from
   
   **Why save macros separately?** Even if you delete the original FoodItem later, you still have a record of what you actually consumed!
   
   **Real-world example:**
   ```
   FoodLogEntry(
     date: December 26, 2025 7:30 AM,
     foodName: "Oatmeal",
     grams: 100,
     protein: 13,
     carbs: 67,
     fat: 7,
     calories: 389,
     mealTag: .breakfast
   )
   ```

6. **`QuickAddEntry`** - Manual food entry when you don't want to search
   
   **Think of it like:** A quick note instead of a full search
   
   **What it stores:**
   - `id`: Unique identifier
   - `date`: When you ate it
   - `calories`, `protein`, `carbs`, `fat`: Direct entry of macros
   - `note`: Any additional info (like "Home cooked meal")
   
   **Why have this?** Sometimes you know the macros but don't want to search! Maybe you ate at a restaurant and looked it up elsewhere, or you cooked something and calculated the macros yourself.
   
   **Real-world example:**
   ```
   QuickAddEntry(
     date: December 26, 2025,
     calories: 650,
     protein: 45,
     carbs: 80,
     fat: 15,
     note: "Restaurant meal - estimated"
   )
   ```

7. **`MacroTarget`** - Your daily nutrition goals
   
   **Think of it like:** Your daily nutrition budget
   
   **What it stores:**
   - `id`: Unique identifier
   - `protein`, `carbs`, `fat`, `calories`: Your target amounts
   - `trainingDay`: Whether this target is for a workout day (might be higher)
   - `effectiveDate`: When this target becomes active
   
   **Why have trainingDay?** On days you workout, you might want more carbs and protein! This lets you set different targets.
   
   **Real-world example:**
   ```
   MacroTarget(
     protein: 180,
     carbs: 250,
     fat: 70,
     calories: 2400,
     trainingDay: true,
     effectiveDate: January 1, 2025
   )
   ```

8. **`FoodComponent`** - Part of a recipe
   
   **Think of it like:** An ingredient in a recipe
   
   **What it stores:**
   - `id`: Unique identifier
   - `food`: Links to a FoodItem
   - `grams`: How much of this food
   - `nameSnapshot`: The food name (saved even if food is deleted)
   - `protein`, `carbs`, `fat`, `calories`: Macros for this amount
   
   **Real-world example:**
   ```
   FoodComponent(
     food: Oatmeal,
     grams: 100,
     nameSnapshot: "Rolled Oats",
     protein: 13,
     carbs: 67,
     fat: 7,
     calories: 389
   )
   ```

9. **`Recipe`** - A saved combination of foods
   
   **Think of it like:** A saved meal combination
   
   **What it stores:**
   - `id`: Unique identifier
   - `name`: Recipe name (like "Post-Workout Shake")
   - `items`: Array of FoodComponents
   - `totalProtein`, `totalCarbs`, `totalFat`, `totalCalories`: Cached totals
   
   **Why cache totals?** Instead of adding up every time, we save the total once for speed!
   
   **Real-world example:**
   ```
   Recipe(
     name: "Post-Workout Shake",
     items: [ProteinPowder(30g), Banana(120g), AlmondMilk(250ml)],
     totalProtein: 35,
     totalCarbs: 45,
     totalFat: 5,
     totalCalories: 350
   )
   ```

10. **`DailySummary`** - A complete day's data
   
    **Think of it like:** A daily report card
   
    **What it stores:**
    - `id`: Unique identifier
    - `date`: The day this summary is for
    - `totalProtein`, `totalCarbs`, `totalFat`, `totalCalories`: Your nutrition totals
    - `totalVolume`: All weight lifted that day
    - `average1RM`: Average estimated one-rep max
    - `sleepHours`: How much you slept (from HealthKit)
    - `recoveryScore`: A calculated score (0-100) of how well you recovered
    - `capacityWarning`: Whether you should reduce training due to poor sleep
    
    **Real-world example:**
    ```
    DailySummary(
      date: December 26, 2025,
      totalProtein: 180,
      totalCarbs: 240,
      totalFat: 65,
      totalCalories: 2350,
      totalVolume: 15,000,
      average1RM: 112.5,
      sleepHours: 7.5,
      recoveryScore: 85,
      capacityWarning: false
    )
    ```

11. **`CachedResult`** - Saved web search results
    
    **Think of it like:** A saved search result to avoid re-downloading
    
    **What it stores:**
    - `id`: Unique identifier
    - `query`: What was searched
    - `payload`: The actual data (stored as raw bytes)
    - `updatedAt`: When this was cached
    
    **Why cache?** Instead of asking the internet every time, we save the answer! If you search for "chicken" today and tomorrow, we can use today's result.

---

## ⚙️ Services (The Workers Behind the Scenes)

Services are like specialized workers in a restaurant - each has a specific job. They handle the complex logic so your views (the UI) stay simple.

### `IronPath/IronPath/Services/Configuration.swift`

**What it is:** A simple settings file that holds configuration values.

**Why it exists:** Instead of hardcoding values (like URLs) all over your code, you put them in one place! This makes it easy to change settings later.

**What it contains:**
- `openFoodFactsBaseURL`: The website address for Open Food Facts API
- `requestThrottleMs`: How long to wait between requests (to be nice to the server)
- `cacheTTL`: How long to keep cached data (Time To Live)

**Think of it like:** A settings menu in a video game - all the options in one place.

**Key Code Explanation:**
- `struct Configuration` - A simple container for settings
- `static let default` - A pre-configured setup that works out of the box
- `TimeInterval` - A type that represents time (in seconds)

**Real-world example:**
```
Configuration.default.openFoodFactsBaseURL 
// Returns: "https://world.openfoodfacts.org"
```

---

### `IronPath/IronPath/Services/WorkoutManager.swift`

**What it is:** The manager that handles all workout-related operations. It's like a personal trainer that keeps track of everything.

**Why it's an actor:** In Swift, `actor` means it's thread-safe - multiple parts of your app can ask it to do things at the same time without conflicts. Think of it like a single-file line at a bank - only one person gets helped at a time, so no confusion!

**What it does:**
1. **Manages live workout sessions** - Keeps track of sets as you're working out
2. **Calculates 1RM** - Uses the Brzycki formula to estimate your one-rep max
3. **Tracks volume** - Adds up all the weight you've lifted
4. **Handles rest timer** - Counts down rest periods with haptic feedback
5. **Saves workouts** - Persists your completed workout to the database

**Key Functions:**
- `startWorkout()` - Begins a new workout session
- `addSet()` - Adds a new set to the current workout
- `completeWorkout()` - Finishes and saves the workout
- `calculate1RM()` - Estimates your one-rep max

**Think of it like:** The workout manager at a gym - it knows what exercises you're doing, tracks your progress, and records everything when you're done.

---

### `IronPath/IronPath/Services/NutritionService.swift`

**What it is:** The service that handles all food-related operations. It's like a nutritionist that knows where to find food information.

**Why it's an actor:** Same reason as WorkoutManager - thread safety for multiple simultaneous requests.

**What it does:**
1. **Three-tier search system** - Searches in this order:
   - First: Your recent foods (from SwiftData)
   - Second: Bundled staples (foods that came with the app)
   - Third: Open Food Facts API (the internet)
   
   **Why three tiers?** Speed! Local data is instant, internet is slow. This way you get instant results for common foods.

2. **Barcode scanning** - Looks up foods by scanning their barcode
3. **Quick add** - Handles manual food entries
4. **Caching** - Saves search results to avoid repeated internet requests

**Key Functions:**
- `searchFoods(query:)` - Searches for foods using the three-tier system
- `barcodeLookup(code:)` - Finds a food by its barcode
- `recordQuickAdd(entry:)` - Saves a manually entered food
- `searchRecent()` - Searches your personal food history
- `searchStaples()` - Searches the bundled food database
- `searchOpenFoodFacts()` - Searches the internet API

**Think of it like:** A smart assistant that knows exactly where to look for food information - first in your notes, then in a reference book, then on the internet.

---

### `IronPath/IronPath/Services/HealthKitManager.swift`

**What it is:** The bridge between your app and Apple's HealthKit. HealthKit is like a health data hub on your iPhone - it stores sleep, steps, heart rate, weight, etc.

**Why it exists:** Your iPhone already tracks lots of health data! Why duplicate it? Instead, we ask HealthKit for permission to read it.

**What it does:**
1. **Requests permissions** - Asks the user if we can read their health data
2. **Fetches sleep data** - Gets how much the user slept
3. **Fetches weight** - Gets the user's weight
4. **Fetches active calories** - Gets calories burned from activity

**Why do we need this?** The Integration Engine uses sleep data to calculate recovery scores and capacity warnings. If you only got 5 hours of sleep, the app should warn you!

**Key Functions:**
- `requestPermissions()` - Asks user for health data access
- `fetchSleepHours(for:)` - Gets sleep duration for a specific date
- `fetchWeight()` - Gets the most recent weight
- `fetchActiveCalories(for:)` - Gets calories burned

**Think of it like:** A translator between your app and Apple's health system - it asks nicely for the data and translates it into a format your app understands.

---

### `IronPath/IronPath/Services/IntegrationEngine.swift`

**What it is:** THE MOST IMPORTANT SERVICE! This is the "brain" that connects workouts and nutrition. It's what makes IronPath special - it doesn't just track workouts and nutrition separately, it connects them!

**Why it exists:** This is the core innovation of IronPath. Most apps track workouts and nutrition separately. IronPath says "they're connected!" If you did a hard leg day, you need more protein and carbs to recover. If you're in a calorie deficit, your strength might plateau. This engine figures all that out.

**What it does:**
1. **Computes daily summaries** - Combines all your data for a day:
   - All food eaten
   - All workouts done
   - Sleep data
   - Calculates totals and scores

2. **Calculates recovery score** - A number (0-100) that shows how well you're recovering:
   - Based on protein intake (did you eat enough?)
   - Based on calories (did you fuel properly?)
   - Based on volume (did you work hard enough?)

3. **Provides recovery buffer suggestions** - After a high-volume workout, suggests:
   - Extra protein (maybe +30g)
   - Extra carbs (maybe +60g)

4. **Capacity warnings** - Checks sleep data:
   - If sleep < 70% of goal → warn user
   - Suggest reducing volume by 10% for safety

**Key Functions:**
- `computeDailySummary(for:)` - Creates a complete day summary
- `recoveryBuffer(for:)` - Suggests macro adjustments based on workout volume
- `capacityWarning(sleepHours:goalHours:)` - Checks if sleep is too low

**The Recovery Score Calculation:**
```
proteinScore = min(protein / 150g, 1.0)  // Did you eat enough protein?
calorieScore = min(calories / 2500, 1.0)  // Did you eat enough calories?
volumeScore = min(volume / 20000kg, 1.0)  // Did you work hard enough?

recoveryScore = (proteinScore + calorieScore + volumeScore) / 3 × 100
```

**Think of it like:** A smart coach that watches everything you do and gives you personalized advice. "You worked hard today - eat more protein! You didn't sleep well - take it easier tomorrow!"

---

### `IronPath/IronPath/Services/ImageCache.swift`

**What it is:** A smart storage system for food images downloaded from the internet.

**Why it exists:** When you search for foods, Open Food Facts provides images. Downloading the same image repeatedly is wasteful! This cache stores them in memory (and optionally on disk) for quick reuse.

**How it works:**
- First time: Downloads image from internet, saves it
- Next time: Returns the saved image instantly
- Automatic cleanup: Removes old images to save memory

**Think of it like:** A photo album where you keep food pictures - instead of asking for the picture every time, you just grab it from your album!

---

## 🎨 View Models (The Bridge Between Data and UI)

ViewModels are like translators. They take raw data (from Services) and prepare it for display (in Views). They also handle user interactions and update the data.

### `IronPath/IronPath/ViewModels/DashboardViewModel.swift`

**What it is:** The ViewModel for the main dashboard screen. It prepares all the data needed to show your correlation charts and recovery insights.

**What it does:**
- Fetches daily summaries for charting
- Prepares protein averages
- Prepares volume averages
- Handles date range selection (7-day, 28-day views)

**Think of it like:** A data analyst that prepares a report - it gathers all the numbers and organizes them into charts and graphs.

---

### `IronPath/IronPath/ViewModels/WorkoutViewModel.swift`

**What it is:** The ViewModel for the workout logging screen. It manages the state while you're logging a workout.

**What it does:**
- Keeps track of current workout
- Manages the list of sets
- Handles rest timer state
- Communicates with WorkoutManager to save data

**Think of it like:** A clipboard for a personal trainer - it holds all the notes while you're working out, then passes them to the manager to file away.

---

### `IronPath/IronPath/ViewModels/NutritionViewModel.swift`

**What it is:** The ViewModel for the food search and logging screen.

**What it does:**
- Manages search text input
- Holds search results (recent, staples, API results)
- Tracks selected items (for multi-add)
- Handles quick add entries
- Communicates with NutritionService

**Think of it like:** A shopping list organizer - you search for foods, select what you want, and it helps you add them all at once.

---

### `IronPath/IronPath/ViewModels/RecipeViewModel.swift`

**What it is:** The ViewModel for creating and managing recipes.

**What it does:**
- Manages recipe creation workflow
- Tracks ingredients being added
- Calculates recipe totals
- Handles saving and loading recipes

**Think of it like:** A recipe card editor - you add ingredients, see the totals update, and save the complete recipe.

---

## 🖼️ Views (What Users Actually See)

Views are what appears on your screen. They're built with SwiftUI and use ViewModels to get their data.

### `IronPath/IronPath/ContentView.swift`

**What it is:** The main container view that sets up the entire app structure.

**What it does:**
- Creates a TabView with four tabs:
  1. **Path** (Dashboard) - Shows correlation charts
  2. **Workout** - Workout logging screen
  3. **Fuel** - Food search and logging
  4. **Recipes** - Recipe creation and management
- Sets dark mode as default
- Creates ViewModels and passes them to child views

**Think of it like:** The main menu of a video game - it shows all the different screens you can visit and switches between them.

---

### `IronPath/IronPath/Views/DashboardView.swift`

**What it is:** The main dashboard that shows the correlation between workouts and nutrition.

**What it displays:**
- Dual-axis chart: Protein intake vs. Lifting volume
- Recovery score visualization
- Daily summaries
- Recovery alerts and suggestions

**Why it's special:** This is the "aha!" moment screen! When users see their protein line and strength line moving together, they understand the connection.

**Think of it like:** A fitness dashboard in a car - it shows multiple metrics at once so you can see how everything is connected.

---

### `IronPath/IronPath/Views/WorkoutLoggerView.swift`

**What it is:** The screen where you log workouts in real-time.

**What it includes:**
- Exercise selector
- Set input fields (reps, weight, RPE)
- Rest timer with haptic feedback
- Current workout stats (volume, estimated 1RM)
- Capacity warning banner (if sleep was poor)

**Why haptic feedback?** When you complete a set and the rest timer starts, your phone vibrates. It's like a coach tapping you on the shoulder saying "rest now!"

**Think of it like:** A digital workout logbook that's smart enough to help you time your rest periods.

---

### `IronPath/IronPath/Views/NutritionSearchView.swift`

**What it is:** The screen for searching and logging foods.

**What it includes:**
- Search bar with as-you-type filtering
- Three sections of results (Recent, Staples, API)
- Multi-select capability (tap multiple foods, add all at once)
- Quick Add card (manual macro entry)
- Barcode scanner button
- Serving size selector

**Why show macros in search results?** So you don't have to tap into each food to see if it's high-protein! The info is right there.

**Think of it like:** A smart food database that learns what you eat and makes logging faster and faster.

---

### `IronPath/IronPath/Views/RecipeCreatorView.swift`

**What it is:** The screen for creating and saving recipes.

**What it includes:**
- Recipe name input
- Ingredient search and addition
- Ingredient list with amounts
- Live totals (protein, carbs, fat, calories update as you add items)
- Save button

**Why recipes?** If you eat the same meal often (like a post-workout shake), you don't want to search for each ingredient every time! Save it as a recipe and add it with one tap.

**Think of it like:** A digital recipe book where you can create custom recipes and save them for quick access.

---

## 📦 Resources (Data Files)

### `IronPath/IronPath/Resources/Exercises.json`

**What it is:** A JSON file containing ~200 common exercises that ship with the app.

**Why it exists:** So you have exercises available even when offline! No need to create every exercise from scratch.

**What it contains:**
- Exercise names
- Muscle groups
- Equipment needed
- Default rep ranges

**JSON Format Example:**
```json
{
  "name": "Barbell Bench Press",
  "muscleGroup": "chest",
  "equipment": "barbell",
  "defaultReps": 8
}
```

**Think of it like:** A starter pack of exercises - you get all the basics, then you can add your own custom exercises too.

---

### `IronPath/IronPath/Resources/StapleFoods.json`

**What it is:** A JSON file containing ~500 common foods that ship with the app.

**Why it exists:** For the three-tier search system! This is tier 2 - common foods that work offline.

**What it contains:**
- Food names
- Nutritional information per 100g
- Common serving sizes

**JSON Format Example:**
```json
{
  "name": "Chicken Breast",
  "caloriesPer100g": 165,
  "proteinPer100g": 31,
  "carbsPer100g": 0,
  "fatPer100g": 3.6
}
```

**Think of it like:** A nutrition facts database of common foods - all the basics like chicken, rice, eggs, etc.

---

## ⚙️ Configuration Files

### `IronPath/IronPath/Info.plist`

**What it is:** An XML configuration file that tells iOS about your app.

**What it contains:**
- App Transport Security (ATS) settings - Allows HTTP connections to localhost for debugging
- App name and bundle identifier
- Required permissions (like HealthKit)

**Why ATS exception?** By default, iOS blocks HTTP connections (only allows HTTPS). We needed to allow HTTP to localhost for the debugging instrumentation to work.

**Think of it like:** An ID card for your app - it tells iOS "this is who I am, here's what I need permission to do."

---

## 📁 Xcode Project Files

### `IronPath/IronPath.xcodeproj/project.pbxproj`

**What it is:** The main Xcode project file. It's like a recipe that tells Xcode how to build your app.

**What it contains:**
- List of all source files
- Build settings (Swift version, deployment target, etc.)
- Target configurations
- File references

**Why it's complex:** Xcode uses this file to know:
- Which files to compile
- What frameworks to link
- What settings to use
- How to organize everything

**Think of it like:** The instruction manual for building your app - Xcode reads this and knows exactly what to do.

---

### `IronPath/IronPath.xcodeproj/project.xcworkspace/`

**What it is:** Workspace metadata folder. Contains settings about how Xcode displays your project.

**Contains:**
- `contents.xcworkspacedata` - Workspace configuration
- `xcshareddata/swiftpm/` - Swift Package Manager settings
- `xcuserdata/` - Your personal Xcode settings (window positions, etc.) - should be ignored

**Think of it like:** Xcode's personal notes about your project - how you like your windows arranged, which files you have open, etc.

---

## 🎨 Assets (Images and Colors)

### `IronPath/IronPath/Assets.xcassets/`

**What it is:** The asset catalog - a special folder where you store images, colors, and other visual assets.

**Contains:**
- `AppIcon.appiconset/` - Your app icon (the picture users see on their home screen)
- `AccentColor.colorset/` - Your app's accent color (used for buttons, highlights, etc.)
- `Contents.json` - Metadata about the asset catalog

**Think of it like:** A digital art folder where you keep all the pictures and colors your app uses.

---

## 📝 Testing Files

### `IronPath/IronPathTests/IntegrationEngineTests.swift`

**What it is:** Unit tests for the IntegrationEngine service.

**What it tests:**
- Brzycki 1RM calculation (does the math work correctly?)
- Recovery buffer logic (does it suggest correct amounts?)
- Daily summary computation

**Why tests matter:** They prove your code works correctly! Every time you change code, you run tests to make sure you didn't break anything.

**Example test:**
```swift
func testBrzycki() {
    let estimate = WorkoutSet.brzycki1RM(weight: 100, reps: 5)
    XCTAssertEqual(Int(estimate.rounded()), 114)
}
```

**Think of it like:** A quality control checklist - you test each function to make sure it works before shipping.

---

## 🎯 The Complete Picture: How Everything Works Together

Let's trace through what happens when you use the app:

### Scenario: Logging a Workout

1. **User opens app** → `IronPathApp.swift` starts, creates database
2. **User taps "Workout" tab** → `ContentView.swift` shows `WorkoutLoggerView`
3. **User starts workout** → `WorkoutViewModel` calls `WorkoutManager.startWorkout()`
4. **User adds a set** → `WorkoutLoggerView` captures input, `WorkoutViewModel` calls `WorkoutManager.addSet()`
5. **WorkoutManager calculates** → Computes tonnage, 1RM, stores in memory
6. **User finishes workout** → `WorkoutViewModel` calls `WorkoutManager.completeWorkout()`
7. **WorkoutManager saves** → Persists `Workout` and all `WorkoutSet` objects to SwiftData
8. **IntegrationEngine computes** → Later, creates `DailySummary` with volume and recovery score

### Scenario: Logging Food

1. **User taps "Fuel" tab** → `ContentView.swift` shows `NutritionSearchView`
2. **User types "chicken"** → `NutritionViewModel` calls `NutritionService.searchFoods("chicken")`
3. **Three-tier search** → 
   - Checks recent foods (instant)
   - Checks staples JSON (instant)
   - Falls back to Open Food Facts API (slower)
4. **User selects food** → `NutritionViewModel` tracks selection
5. **User taps "Add Selected"** → `NutritionSearchView` creates `FoodLogEntry`, saves to SwiftData
6. **IntegrationEngine updates** → Daily summary recalculates macros

### Scenario: Viewing Dashboard

1. **User taps "Path" tab** → `ContentView.swift` shows `DashboardView`
2. **DashboardViewModel fetches** → Gets all `DailySummary` records
3. **DashboardView displays** → Shows correlation chart (protein vs. volume)
4. **IntegrationEngine insights** → Shows recovery score, suggestions, warnings

---

## 🎓 Key Concepts Explained Simply

### SwiftData (@Model)

**What it is:** Apple's database system for storing data locally on your device.

**Why use it:** Instead of writing complex database code, you just add `@Model` to your class and SwiftData handles everything!

**Think of it like:** A magic filing cabinet - you just say "store this" and it figures out where to put it.

---

### Actor

**What it is:** A special type in Swift that's thread-safe.

**Why use it:** When multiple parts of your app try to access the same data at once, bad things can happen (like data corruption). Actors prevent this by only allowing one access at a time.

**Think of it like:** A single-file line - only one person goes at a time, so there's no pushing and shoving.

---

### ViewModel (MVVM Pattern)

**What it is:** Part of the Model-View-ViewModel architecture pattern.

**The pattern:**
- **Model** = Your data (like `Workout`, `FoodItem`)
- **View** = Your UI (like `WorkoutLoggerView`)
- **ViewModel** = The bridge between them

**Why use it:** Keeps your views simple! Views just display things and send user actions to ViewModels. ViewModels handle all the logic.

**Think of it like:** A waiter in a restaurant - the customer (View) gives orders to the waiter (ViewModel), who talks to the kitchen (Service/Model).

---

### @Observable

**What it is:** A Swift macro (iOS 17+) that makes objects observable - when they change, SwiftUI automatically updates the UI.

**Why use it:** Instead of manually telling the UI "something changed!", `@Observable` does it automatically.

**Think of it like:** A smart light switch - when you flip it, the light turns on automatically without extra wiring.

---

## 🎉 Summary

IronPath is a beautifully organized app that:

1. **Stores data** using SwiftData models (DomainModels.swift)
2. **Handles business logic** using Services (WorkoutManager, NutritionService, IntegrationEngine, etc.)
3. **Prepares data for display** using ViewModels
4. **Shows the UI** using SwiftUI Views
5. **Works offline** using bundled resources (Exercises.json, StapleFoods.json)
6. **Connects everything** through the Integration Engine

Every file has a purpose, and together they create an app that's more than the sum of its parts - it's a unified fitness and nutrition tracking system that actually connects the two!

Remember: **Good code is like a good recipe** - each ingredient (file) has a specific purpose, and when combined correctly, you get something amazing! 🚀
