//
//  EditProfileView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let profile: UserProfile
    
    @State private var targetProtein: Double
    @State private var targetCarbs: Double
    @State private var targetFat: Double
    @State private var targetCalories: Double
    @State private var bodyWeight: Double?
    @State private var sleepGoalHours: Double
    
    init(profile: UserProfile) {
        self.profile = profile
        _targetProtein = State(initialValue: profile.targetProtein)
        _targetCarbs = State(initialValue: profile.targetCarbs)
        _targetFat = State(initialValue: profile.targetFat)
        _targetCalories = State(initialValue: profile.targetCalories)
        _bodyWeight = State(initialValue: profile.bodyWeight)
        _sleepGoalHours = State(initialValue: profile.sleepGoalHours)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Macro Targets") {
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", value: $targetProtein, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", value: $targetCarbs, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", value: $targetFat, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: $targetCalories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Body Metrics") {
                    HStack {
                        Text("Body Weight (lbs)")
                        Spacer()
                        TextField("0", value: $bodyWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Goals") {
                    HStack {
                        Text("Sleep Goal (hours)")
                        Spacer()
                        TextField("0", value: $sleepGoalHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        profile.targetProtein = targetProtein
        profile.targetCarbs = targetCarbs
        profile.targetFat = targetFat
        profile.targetCalories = targetCalories
        profile.bodyWeight = bodyWeight
        profile.sleepGoalHours = sleepGoalHours
        profile.lastUpdated = Date()
        
        do {
            try modelContext.save()
            HapticManager.success()
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

#Preview {
    EditProfileView(profile: UserProfile())
}

