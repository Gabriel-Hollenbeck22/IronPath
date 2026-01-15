//
//  MacroProgressSection.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI

struct MacroProgressSection: View {
    let summary: DailySummary
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Macros")
                .font(.cardTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Calorie Progress Bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Calories")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(summary.totalCalories)) / \(Int(profile.targetCalories))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.ironPathPrimary, Color.ironPathPrimary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * min(summary.totalCalories / profile.targetCalories, 1.0),
                                height: 12
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: summary.totalCalories)
                    }
                }
                .frame(height: 12)
            }
            .padding(.bottom, Spacing.sm)
            
            HStack(spacing: Spacing.lg) {
                MacroRingView(
                    current: summary.totalProtein,
                    target: profile.targetProtein,
                    color: .macroProtein,
                    label: "Protein"
                )
                
                MacroRingView(
                    current: summary.totalCarbs,
                    target: profile.targetCarbs,
                    color: .macroCarbs,
                    label: "Carbs"
                )
                
                MacroRingView(
                    current: summary.totalFat,
                    target: profile.targetFat,
                    color: .macroFat,
                    label: "Fat"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .premiumCard()
    }
}

#Preview {
    MacroProgressSection(
        summary: DailySummary(date: Date()),
        profile: UserProfile()
    )
    .padding()
}

