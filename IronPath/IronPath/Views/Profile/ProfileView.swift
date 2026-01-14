//
//  ProfileView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    if let profile = userProfiles.first {
                        profileInfoSection(profile: profile)
                        macroTargetsSection(profile: profile)
                        settingsSection
                    } else {
                        ContentUnavailableView(
                            "No Profile",
                            systemImage: "person.fill",
                            description: Text("Create a profile to get started")
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                if let profile = userProfiles.first {
                    EditProfileView(profile: profile)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func profileInfoSection(profile: UserProfile) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.ironPathPrimary)
            
            if let weight = profile.bodyWeight {
                Text(FormatHelpers.weight(weight))
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
    
    private func macroTargetsSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Macro Targets")
                .font(.headline)
            
            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("Protein")
                    Spacer()
                    Text(FormatHelpers.macro(profile.targetProtein))
                }
                
                HStack {
                    Text("Carbs")
                    Spacer()
                    Text(FormatHelpers.macro(profile.targetCarbs))
                }
                
                HStack {
                    Text("Fat")
                    Spacer()
                    Text(FormatHelpers.macro(profile.targetFat))
                }
                
                HStack {
                    Text("Calories")
                    Spacer()
                    Text(FormatHelpers.calories(profile.targetCalories))
                }
            }
            .padding(Spacing.cardPadding)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Settings")
                .font(.headline)
            
            NavigationLink(destination: HealthKitSettingsView()) {
                HStack {
                    Label("HealthKit", systemImage: "heart.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.cardPadding)
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}

