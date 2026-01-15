//
//  MuscleGroupVisualizationView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 1/14/26.
//

import SwiftUI
import SwiftData

struct MuscleGroupVisualizationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var strengthCategories: [MuscleGroup: StrengthCategory] = [:]
    @State private var calculator: MuscleStrengthCalculator?
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var biologicalSex: BiologicalSex {
        userProfile?.biologicalSex ?? .male
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Muscle Group Strength")
                .font(.cardTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Always show diagram if we have a user profile, even if categories are empty (will show all rookie)
            if userProfile == nil {
                ContentUnavailableView(
                    "No Profile Data",
                    systemImage: "person.crop.circle.fill",
                    description: Text("Complete your profile to see muscle group strength levels")
                )
                .frame(height: 300)
            } else {
                ZStack {
                    // Human body silhouette (male or female)
                    HumanBodyDiagram(
                        strengthCategories: strengthCategories,
                        biologicalSex: biologicalSex
                    )
                    .frame(height: 400)
                    
                    // Legend
                    VStack {
                        Spacer()
                        HStack(spacing: Spacing.sm) {
                            LegendItem(color: .red, label: "Rookie")
                            LegendItem(color: .orange, label: "Average")
                            LegendItem(color: .yellow, label: "Intermediate")
                            LegendItem(color: .green, label: "Advanced")
                            LegendItem(color: .blue, label: "Elite")
                        }
                        .padding()
                        .background(Color.cardBackground.opacity(0.9))
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .premiumCard()
        .onAppear {
            calculateCategories()
        }
        .onChange(of: userProfile?.id) { _, _ in
            calculateCategories()
        }
        .onChange(of: userProfile?.biologicalSex) { _, _ in
            calculateCategories()
        }
    }
    
    private func calculateCategories() {
        // Recreate calculator with current user profile
        calculator = MuscleStrengthCalculator(modelContext: modelContext, userProfile: userProfile)
        guard let calc = calculator else {
            // Fallback: if calculator creation fails, set all to rookie
            strengthCategories = Dictionary(uniqueKeysWithValues: MuscleGroup.allCases.map { ($0, .rookie) })
            return
        }
        
        let calculated = calc.calculateStrengthCategories()
        
        // Ensure we always have categories for all muscle groups
        if calculated.isEmpty {
            // If empty, initialize with all rookie
            strengthCategories = Dictionary(uniqueKeysWithValues: MuscleGroup.allCases.map { ($0, .rookie) })
        } else {
            strengthCategories = calculated
            
            // Ensure all muscle groups are represented
            for muscleGroup in MuscleGroup.allCases {
                if strengthCategories[muscleGroup] == nil {
                    strengthCategories[muscleGroup] = .rookie
                }
            }
        }
    }
}

// MARK: - Human Body Diagram

struct HumanBodyDiagram: View {
    let strengthCategories: [MuscleGroup: StrengthCategory]
    let biologicalSex: BiologicalSex
    
    var body: some View {
        Group {
            if biologicalSex == .female {
                FemaleBodyDiagram(strengthCategories: strengthCategories)
            } else {
                MaleBodyDiagram(strengthCategories: strengthCategories)
            }
        }
    }
    
    func colorForMuscleGroup(_ group: MuscleGroup) -> Color {
        guard let category = strengthCategories[group] else {
            return .gray.opacity(0.3) // No data
        }
        return MuscleStrengthCalculator.colorForCategory(category)
    }
}

// MARK: - Male Body Diagram

struct MaleBodyDiagram: View {
    let strengthCategories: [MuscleGroup: StrengthCategory]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            
            ZStack {
                // Head
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .position(x: centerX, y: 30)
                
                // Upper Body - Male proportions (broader shoulders, narrower hips)
                // Chest (broader)
                MuscleRegion(
                    path: chestPath(centerX: centerX, y: 80, width: width, isMale: true),
                    color: colorForMuscleGroup(.chest)
                )
                
                // Back
                MuscleRegion(
                    path: backPath(centerX: centerX, y: 80, width: width, isMale: true),
                    color: colorForMuscleGroup(.back)
                )
                
                // Shoulders (wider - 70% of width)
                MuscleRegion(
                    path: shouldersPath(centerX: centerX, y: 70, width: width, isMale: true),
                    color: colorForMuscleGroup(.shoulders)
                )
                
                // Arms
                MuscleRegion(
                    path: armPath(centerX: centerX - 38, y: 100, isLeft: true, isMale: true),
                    color: colorForMuscleGroup(.biceps)
                )
                MuscleRegion(
                    path: tricepsPath(centerX: centerX - 38, y: 100, isLeft: true, isMale: true),
                    color: colorForMuscleGroup(.triceps)
                )
                
                MuscleRegion(
                    path: armPath(centerX: centerX + 38, y: 100, isLeft: false, isMale: true),
                    color: colorForMuscleGroup(.biceps)
                )
                MuscleRegion(
                    path: tricepsPath(centerX: centerX + 38, y: 100, isLeft: false, isMale: true),
                    color: colorForMuscleGroup(.triceps)
                )
                
                // Forearms
                MuscleRegion(
                    path: forearmPath(centerX: centerX - 38, y: 150, isLeft: true, isMale: true),
                    color: colorForMuscleGroup(.forearms)
                )
                MuscleRegion(
                    path: forearmPath(centerX: centerX + 38, y: 150, isLeft: false, isMale: true),
                    color: colorForMuscleGroup(.forearms)
                )
                
                // Core (narrower waist)
                MuscleRegion(
                    path: absPath(centerX: centerX, y: 140, width: width, isMale: true),
                    color: colorForMuscleGroup(.abs)
                )
                
                // Lower Body (narrower hips)
                MuscleRegion(
                    path: quadPath(centerX: centerX - 18, y: 200, isLeft: true, isMale: true),
                    color: colorForMuscleGroup(.quads)
                )
                MuscleRegion(
                    path: quadPath(centerX: centerX + 18, y: 200, isLeft: false, isMale: true),
                    color: colorForMuscleGroup(.quads)
                )
                
                MuscleRegion(
                    path: hamstringPath(centerX: centerX - 18, y: 200, isLeft: true, isMale: true),
                    color: colorForMuscleGroup(.hamstrings)
                )
                MuscleRegion(
                    path: hamstringPath(centerX: centerX + 18, y: 200, isLeft: false, isMale: true),
                    color: colorForMuscleGroup(.hamstrings)
                )
                
                MuscleRegion(
                    path: glutesPath(centerX: centerX, y: 190, width: width, isMale: true),
                    color: colorForMuscleGroup(.glutes)
                )
                
                MuscleRegion(
                    path: calfPath(centerX: centerX - 18, y: 280, isLeft: true, isMale: true),
                    color: colorForMuscleGroup(.calves)
                )
                MuscleRegion(
                    path: calfPath(centerX: centerX + 18, y: 280, isLeft: false, isMale: true),
                    color: colorForMuscleGroup(.calves)
                )
            }
        }
    }
    
    private func colorForMuscleGroup(_ group: MuscleGroup) -> Color {
        guard let category = strengthCategories[group] else {
            return .gray.opacity(0.3)
        }
        return MuscleStrengthCalculator.colorForCategory(category)
    }
}

// MARK: - Female Body Diagram

struct FemaleBodyDiagram: View {
    let strengthCategories: [MuscleGroup: StrengthCategory]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            
            ZStack {
                // Head
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .position(x: centerX, y: 30)
                
                // Upper Body - Female proportions (narrower shoulders, wider hips)
                // Chest
                MuscleRegion(
                    path: chestPath(centerX: centerX, y: 80, width: width, isMale: false),
                    color: colorForMuscleGroup(.chest)
                )
                
                // Back
                MuscleRegion(
                    path: backPath(centerX: centerX, y: 80, width: width, isMale: false),
                    color: colorForMuscleGroup(.back)
                )
                
                // Shoulders (narrower - 60% of width)
                MuscleRegion(
                    path: shouldersPath(centerX: centerX, y: 70, width: width, isMale: false),
                    color: colorForMuscleGroup(.shoulders)
                )
                
                // Arms (slightly narrower)
                MuscleRegion(
                    path: armPath(centerX: centerX - 32, y: 100, isLeft: true, isMale: false),
                    color: colorForMuscleGroup(.biceps)
                )
                MuscleRegion(
                    path: tricepsPath(centerX: centerX - 32, y: 100, isLeft: true, isMale: false),
                    color: colorForMuscleGroup(.triceps)
                )
                
                MuscleRegion(
                    path: armPath(centerX: centerX + 32, y: 100, isLeft: false, isMale: false),
                    color: colorForMuscleGroup(.biceps)
                )
                MuscleRegion(
                    path: tricepsPath(centerX: centerX + 32, y: 100, isLeft: false, isMale: false),
                    color: colorForMuscleGroup(.triceps)
                )
                
                // Forearms
                MuscleRegion(
                    path: forearmPath(centerX: centerX - 32, y: 150, isLeft: true, isMale: false),
                    color: colorForMuscleGroup(.forearms)
                )
                MuscleRegion(
                    path: forearmPath(centerX: centerX + 32, y: 150, isLeft: false, isMale: false),
                    color: colorForMuscleGroup(.forearms)
                )
                
                // Core (wider waist)
                MuscleRegion(
                    path: absPath(centerX: centerX, y: 140, width: width, isMale: false),
                    color: colorForMuscleGroup(.abs)
                )
                
                // Lower Body (wider hips)
                MuscleRegion(
                    path: quadPath(centerX: centerX - 22, y: 200, isLeft: true, isMale: false),
                    color: colorForMuscleGroup(.quads)
                )
                MuscleRegion(
                    path: quadPath(centerX: centerX + 22, y: 200, isLeft: false, isMale: false),
                    color: colorForMuscleGroup(.quads)
                )
                
                MuscleRegion(
                    path: hamstringPath(centerX: centerX - 22, y: 200, isLeft: true, isMale: false),
                    color: colorForMuscleGroup(.hamstrings)
                )
                MuscleRegion(
                    path: hamstringPath(centerX: centerX + 22, y: 200, isLeft: false, isMale: false),
                    color: colorForMuscleGroup(.hamstrings)
                )
                
                MuscleRegion(
                    path: glutesPath(centerX: centerX, y: 190, width: width, isMale: false),
                    color: colorForMuscleGroup(.glutes)
                )
                
                MuscleRegion(
                    path: calfPath(centerX: centerX - 22, y: 280, isLeft: true, isMale: false),
                    color: colorForMuscleGroup(.calves)
                )
                MuscleRegion(
                    path: calfPath(centerX: centerX + 22, y: 280, isLeft: false, isMale: false),
                    color: colorForMuscleGroup(.calves)
                )
            }
        }
    }
    
    private func colorForMuscleGroup(_ group: MuscleGroup) -> Color {
        guard let category = strengthCategories[group] else {
            return .gray.opacity(0.3)
        }
        return MuscleStrengthCalculator.colorForCategory(category)
    }
}

// MARK: - Path Generators

private func chestPath(centerX: CGFloat, y: CGFloat, width: CGFloat, isMale: Bool) -> Path {
    var path = Path()
    let chestWidth: CGFloat = isMale ? 55 : 45
    path.addEllipse(in: CGRect(
        x: centerX - chestWidth/2,
        y: y - 10,
        width: chestWidth,
        height: 20
    ))
    return path
}

private func backPath(centerX: CGFloat, y: CGFloat, width: CGFloat, isMale: Bool) -> Path {
    var path = Path()
    let backWidth: CGFloat = isMale ? 55 : 45
    path.addEllipse(in: CGRect(
        x: centerX - backWidth/2,
        y: y - 10,
        width: backWidth,
        height: 20
    ))
    return path
}

private func shouldersPath(centerX: CGFloat, y: CGFloat, width: CGFloat, isMale: Bool) -> Path {
    var path = Path()
    let shoulderWidth: CGFloat = isMale ? width * 0.7 : width * 0.6
    path.addEllipse(in: CGRect(
        x: centerX - shoulderWidth/2,
        y: y - 5,
        width: shoulderWidth,
        height: 15
    ))
    return path
}

private func armPath(centerX: CGFloat, y: CGFloat, isLeft: Bool, isMale: Bool) -> Path {
    var path = Path()
    let armWidth: CGFloat = isMale ? 13 : 11
    path.addRoundedRect(in: CGRect(
        x: centerX - armWidth/2,
        y: y,
        width: armWidth,
        height: 50
    ), cornerSize: CGSize(width: 6, height: 6))
    return path
}

private func tricepsPath(centerX: CGFloat, y: CGFloat, isLeft: Bool, isMale: Bool) -> Path {
    var path = Path()
    let tricepWidth: CGFloat = isMale ? 11 : 9
    path.addRoundedRect(in: CGRect(
        x: centerX - tricepWidth/2,
        y: y + 20,
        width: tricepWidth,
        height: 30
    ), cornerSize: CGSize(width: 5, height: 5))
    return path
}

private func forearmPath(centerX: CGFloat, y: CGFloat, isLeft: Bool, isMale: Bool) -> Path {
    var path = Path()
    let forearmWidth: CGFloat = isMale ? 9 : 7
    path.addRoundedRect(in: CGRect(
        x: centerX - forearmWidth/2,
        y: y,
        width: forearmWidth,
        height: 40
    ), cornerSize: CGSize(width: 4, height: 4))
    return path
}

private func absPath(centerX: CGFloat, y: CGFloat, width: CGFloat, isMale: Bool) -> Path {
    var path = Path()
    let absWidth: CGFloat = isMale ? 38 : 42
    path.addRoundedRect(in: CGRect(
        x: centerX - absWidth/2,
        y: y,
        width: absWidth,
        height: 30
    ), cornerSize: CGSize(width: 8, height: 8))
    return path
}

private func quadPath(centerX: CGFloat, y: CGFloat, isLeft: Bool, isMale: Bool) -> Path {
    var path = Path()
    let quadWidth: CGFloat = isMale ? 16 : 18
    path.addRoundedRect(in: CGRect(
        x: centerX - quadWidth/2,
        y: y,
        width: quadWidth,
        height: 60
    ), cornerSize: CGSize(width: 7, height: 7))
    return path
}

private func hamstringPath(centerX: CGFloat, y: CGFloat, isLeft: Bool, isMale: Bool) -> Path {
    var path = Path()
    let hamstringWidth: CGFloat = isMale ? 13 : 15
    path.addRoundedRect(in: CGRect(
        x: centerX - hamstringWidth/2,
        y: y + 30,
        width: hamstringWidth,
        height: 30
    ), cornerSize: CGSize(width: 6, height: 6))
    return path
}

private func glutesPath(centerX: CGFloat, y: CGFloat, width: CGFloat, isMale: Bool) -> Path {
    var path = Path()
    let glutesWidth: CGFloat = isMale ? 48 : 55
    path.addEllipse(in: CGRect(
        x: centerX - glutesWidth/2,
        y: y,
        width: glutesWidth,
        height: 25
    ))
    return path
}

private func calfPath(centerX: CGFloat, y: CGFloat, isLeft: Bool, isMale: Bool) -> Path {
    var path = Path()
    let calfWidth: CGFloat = isMale ? 11 : 9
    path.addRoundedRect(in: CGRect(
        x: centerX - calfWidth/2,
        y: y,
        width: calfWidth,
        height: 50
    ), cornerSize: CGSize(width: 5, height: 5))
    return path
}

// MARK: - Muscle Region

struct MuscleRegion: View {
    let path: Path
    let color: Color
    
    var body: some View {
        path
            .fill(color.opacity(0.7))
            .overlay(
                path.stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Legend

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
        }
    }
}

#Preview {
    MuscleGroupVisualizationView()
        .modelContainer(for: [WorkoutSet.self, UserProfile.self], inMemory: true)
        .padding()
}
