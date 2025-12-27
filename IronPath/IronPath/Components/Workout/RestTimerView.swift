//
//  RestTimerView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI

/// View for displaying and controlling a rest timer.
/// Follows MVVM pattern - all timer logic and state is managed by RestTimerViewModel.
struct RestTimerView: View {
    /// ViewModel that owns all timer state and logic
    /// Using @StateObject ensures the ViewModel persists across view updates
    /// and is only created once when the view is first initialized
    @StateObject private var viewModel: RestTimerViewModel
    
    /// Initial duration in seconds (used for progress calculation)
    private let initialSeconds: Int
    
    init(seconds: Int = AppConfiguration.defaultRestTimerSeconds, onComplete: @escaping () -> Void = {}) {
        self.initialSeconds = seconds
        // Initialize ViewModel with the same parameters
        // @StateObject wrapper will be applied automatically
        self._viewModel = StateObject(wrappedValue: RestTimerViewModel(seconds: seconds, onComplete: onComplete))
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Timer Display Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: Double(viewModel.timeRemaining) / Double(initialSeconds))
                    .stroke(Color.ironPathPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.timeRemaining)
                
                Text(FormatHelpers.restTimer(viewModel.timeRemaining))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 120, height: 120)
            
            // Control Buttons
            HStack(spacing: Spacing.md) {
                // Start/Pause Button
                Button(viewModel.isActive ? "Pause" : "Start") {
                    viewModel.toggle()
                    HapticManager.lightImpact()
                }
                .buttonStyle(.borderedProminent)
                
                // Reset Button
                Button("Reset") {
                    viewModel.reset()
                    HapticManager.lightImpact()
                }
                .buttonStyle(.bordered)
            }
        }
        // Note: We intentionally do NOT stop the timer in onDisappear
        // This allows the timer to continue running even if the user navigates away,
        // preserving the rest period. The ViewModel's timer will continue counting down
        // until it reaches zero or is explicitly paused/reset by the user.
    }
}

#Preview {
    RestTimerView()
        .padding()
}

