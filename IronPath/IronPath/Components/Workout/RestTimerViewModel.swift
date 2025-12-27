//
//  RestTimerViewModel.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import Foundation
import Combine

/// ViewModel for RestTimerView following MVVM pattern.
///
/// **Why the timer lives in the ViewModel:**
/// - The Timer is a long-running resource that should persist across view lifecycle events
/// - If the timer lived in the View, it would be destroyed when the view disappears,
///   causing the countdown to reset and lose progress
/// - By owning the timer in the ViewModel, we ensure the timer continues running
///   even if the user navigates away and comes back, preserving the rest period
/// - The ViewModel's lifecycle is independent of the View's lifecycle, making it
///   the appropriate place for business logic and state management
final class RestTimerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current time remaining in seconds
    @Published var timeRemaining: Int
    
    /// Whether the timer is currently active/running
    @Published var isActive: Bool = false
    
    // MARK: - Private Properties
    
    /// The underlying Timer instance that drives the countdown
    /// Stored here (not in the View) so it persists across view lifecycle events
    private var timer: Timer?
    
    /// Initial duration in seconds (used for reset)
    private let initialSeconds: Int
    
    /// Callback invoked when timer reaches zero
    private let onComplete: () -> Void
    
    // MARK: - Initialization
    
    init(seconds: Int = AppConfiguration.defaultRestTimerSeconds, onComplete: @escaping () -> Void = {}) {
        self.initialSeconds = seconds
        self.timeRemaining = seconds
        self.onComplete = onComplete
    }
    
    // MARK: - Public Methods
    
    /// Start or resume the timer countdown
    func start() {
        guard !isActive else { return }
        
        isActive = true
        startTimer()
    }
    
    /// Pause the timer (preserves current time remaining)
    func pause() {
        guard isActive else { return }
        
        isActive = false
        stopTimer()
    }
    
    /// Toggle between start and pause states
    func toggle() {
        if isActive {
            pause()
        } else {
            start()
        }
    }
    
    /// Reset timer to initial duration and stop it
    func reset() {
        isActive = false
        timeRemaining = initialSeconds
        stopTimer()
    }
    
    // MARK: - Private Timer Management
    
    /// Start the timer countdown
    /// This creates a repeating Timer that decrements timeRemaining each second
    private func startTimer() {
        // Invalidate any existing timer first
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                // Timer reached zero - stop and invoke completion callback
                self.stopTimer()
                self.isActive = false
                HapticManager.success()
                self.onComplete()
            }
        }
    }
    
    /// Stop and invalidate the timer safely
    /// This ensures the Timer is properly cleaned up to prevent memory leaks
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Ensure timer is cleaned up when ViewModel is deallocated
        stopTimer()
    }
}

