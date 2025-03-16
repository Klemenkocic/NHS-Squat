import SwiftUI
import UIKit
import QuickPoseCore
import QuickPoseMP
import AVFoundation
import Foundation
import Combine

@MainActor
class SquatCounterViewModel: ObservableObject {
    @Published var repCount: Int = 0
    @Published var squatState: SquatState = .standing
    @Published var isStarted: Bool = false
    @Published var countdownValue: Int = 3
    @Published var isCountingDown: Bool = false
    @Published var errorMessage: String?
    @Published var userInFrame: Bool = true
    
    // Workout statistics
    @Published var workoutDuration: TimeInterval = 0
    @Published var caloriesBurned: Double = 0
    
    // QuickPose properties
    var quickPose: QuickPose?
    private var squatCounter = QuickPoseThresholdCounter()
    private var cameraSession: AVCaptureSession?
    
    private var countdownTimer: Timer?
    private var workoutTimer: Timer?
    private var workoutStartTime: Date?
    
    // Constants for calorie calculation
    private let caloriesPerSquat: Double = 0.32  // Average calories burned per squat
    
    // Device detection
    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // Fixed animation duration
    private let uiAnimationDuration: Double = 0.3
    
    init() {
        setupQuickPose()
    }
    
    private func setupQuickPose() {
        do {
            // Get SDK key from Info.plist
            guard let sdkKey = Bundle.main.object(forInfoDictionaryKey: "QuickPoseSDKKey") as? String else {
                errorMessage = "QuickPose SDK key not found in Info.plist"
                print("Error: QuickPose SDK key not found in Info.plist")
                return
            }
            
            // Print debug info
            print("Using QuickPose SDK Key: \(sdkKey)")
            print("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
            
            // Initialize QuickPose with your SDK key
            quickPose = try QuickPose(sdkKey: sdkKey)
            
            guard let quickPose = quickPose else {
                errorMessage = "Failed to initialize QuickPose"
                return
            }
            
            // Start QuickPose with squat feature
            quickPose.start(features: [.fitness(.squats)], onFrame: { [weak self] status, image, features, feedback, landmarks in
                guard let self = self else { return }
                
                switch status {
                case .success:
                    // Update person detection status
                    Task { @MainActor in
                        self.userInFrame = true
                    }
                    
                    // Process squat detection
                    if let result = features.values.first {
                        let counterState = self.squatCounter.count(result.value)
                        
                        Task { @MainActor in
                            // Update rep count
                            if counterState.count > self.repCount {
                                self.repCount = counterState.count
                                
                                // Update calories burned
                                self.caloriesBurned = Double(self.repCount) * self.caloriesPerSquat
                                
                                // Add haptic feedback on iPhone
                                self.triggerHapticFeedback(.medium)
                                
                                // Play rep completion sound
                                self.playSound(for: .rep)
                                
                                // Announce milestone reps using VoiceOver
                                if self.repCount % 5 == 0 {
                                    self.announceVoiceOver("\(self.repCount) squats completed")
                                }
                            }
                            
                            // Update squat state
                            withAnimation(.easeInOut(duration: self.uiAnimationDuration)) {
                                if result.value > 0.5 { // Threshold for squat position
                                    self.squatState = .squatting
                                } else {
                                    self.squatState = .standing
                                }
                            }
                        }
                    }
                    
                case .noPersonFound:
                    Task { @MainActor in
                        self.userInFrame = false
                    }
                    
                case .sdkValidationError:
                    Task { @MainActor in
                        self.errorMessage = "SDK validation error"
                    }
                    
                default:
                    break
                }
            })
            
        } catch {
            errorMessage = "Failed to initialize QuickPose: \(error.localizedDescription)"
            print("QuickPose initialization error: \(error)")
        }
    }
    
    func startWorkout() {
        // Reset stats
        if !isStarted && !isCountingDown {
            repCount = 0
            workoutDuration = 0
            caloriesBurned = 0
        }
        
        countdownValue = 3
        isCountingDown = true
        startCountdown()
        
        // Play start sound
        playSound(for: .start)
    }
    
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if self.countdownValue > 0 {
                self.countdownValue -= 1
                
                // Play tick sound
                self.playSound(for: .tick)
                
                // Haptic feedback for each countdown tick
                self.triggerHapticFeedback(.light)
            } else {
                timer.invalidate()
                self.isCountingDown = false
                self.isStarted = true
                
                // Play go sound
                self.playSound(for: .go)
                
                // Strong haptic feedback when workout starts
                self.triggerHapticFeedback(.heavy)
                
                // Start workout timer
                self.startWorkoutTimer()
                
                // Reset the squat counter
                self.squatCounter = QuickPoseThresholdCounter()
            }
        }
    }
    
    private func startWorkoutTimer() {
        workoutStartTime = Date()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.workoutStartTime else { return }
            
            self.workoutDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    func stopWorkout() {
        isStarted = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // Save workout session to history
        if repCount > 0 && workoutDuration > 0 {
            // Use WorkoutHistoryManager with completion handler
            let manager = WorkoutHistoryManager.shared
            manager.saveWorkoutSession(
                duration: workoutDuration,
                repCount: repCount,
                caloriesBurned: caloriesBurned
            ) { [weak self] (result: Result<Void, Error>) in
                switch result {
                case .success:
                    print("Workout session saved successfully")
                case .failure(let error):
                    self?.errorMessage = "Failed to save workout: \(error.localizedDescription)"
                    print("Error saving workout session: \(error.localizedDescription)")
                }
            }
        }
        
        // Play stop sound
        playSound(for: .stop)
        
        // Final haptic feedback
        triggerHapticFeedback(.medium)
        
        // Announce workout summary
        let summary = "Workout complete. \(repCount) squats performed in \(formattedDuration). Approximately \(Int(caloriesBurned)) calories burned."
        announceVoiceOver(summary)
    }
    
    // MARK: - Helper Methods
    
    // Format duration as mm:ss
    var formattedDuration: String {
        let minutes = Int(workoutDuration) / 60
        let seconds = Int(workoutDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Handle camera errors
    func handleCameraError(_ error: Error) {
        errorMessage = "Camera error: \(error.localizedDescription)"
        print("Camera error: \(error)")
    }
    
    // Haptic feedback with different intensities
    func triggerHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if isPhone {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    // Sound effects for different events
    enum SoundEffect {
        case start, stop, tick, go, rep
    }
    
    func playSound(for effect: SoundEffect) {
        // In a real app, you would implement sound playback here
        // For this mock implementation, we'll just print the sound effect
        print("Playing sound: \(effect)")
    }
    
    // Accessibility announcements
    func announceVoiceOver(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    deinit {
        countdownTimer?.invalidate()
        workoutTimer?.invalidate()
        quickPose?.stop()
    }
}

enum SquatState {
    case standing
    case squatting
} 