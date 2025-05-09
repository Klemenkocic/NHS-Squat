import SwiftUI
import AVFoundation
import QuickPoseCamera
import QuickPoseSwiftUI
import QuickPoseCore

struct SquatCounterView: View {
    @StateObject private var viewModel = SquatCounterViewModel()
    @State private var showingPermissionAlert = false
    @State private var showDebugView = false
    @State private var showHistoryView = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // Dynamic colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemGray6)
    }
    
    private var accentColor: Color {
        Color.blue
    }
    
    // Fixed animation durations
    private let uiAnimationDuration: Double = 0.3
    private let countdownAnimationDuration: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            // QuickPose Camera View
            if let quickPose = viewModel.quickPose {
                QuickPoseCameraView(useFrontCamera: true, delegate: quickPose)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(viewModel.isStarted ? 1.0 : 0.5) // Dim when not started
            } else {
                // Fallback when QuickPose is not initialized
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.5)
                    .overlay(
                        Text("Initializing camera...")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
            }
            
            // Debug overlay (optional)
            if showDebugView, let quickPose = viewModel.quickPose {
                // Create a state variable for the overlay image
                let overlayImage = Binding<UIImage?>(
                    get: { nil },
                    set: { _ in }
                )
                
                QuickPoseOverlayView(overlayImage: overlayImage)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Guide overlay
            GuideOverlay(accentColor: accentColor)
                .opacity(0.4)
            
            // User not in frame warning
            if viewModel.isStarted && !viewModel.userInFrame {
                Text("Please step into frame")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // Countdown overlay
            if viewModel.isCountingDown {
                CountdownOverlay(count: viewModel.countdownValue)
            }
            
            // Main content
            VStack(spacing: 0) {
                // Top bar with rep counter
                HStack {
                    // Rep counter with card design
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REPS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        
                        Text("\(viewModel.repCount)")
                            .font(.system(size: isPhone ? 42 : 56, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : .white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    
                    Spacer()
                    
                    // Squat state indicator with improved visibility
                    VStack(alignment: .center, spacing: 4) {
                        Circle()
                            .fill(viewModel.squatState == .squatting ? Color.green : Color.red)
                            .frame(width: isPhone ? 24 : 32, height: isPhone ? 24 : 32)
                        
                        Text(viewModel.squatState == .squatting ? "SQUATTING" : "STANDING")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : .white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal)
                .padding(.top, isPhone ? 16 : 24)
                
                // Workout stats (only show when workout is active)
                if viewModel.isStarted {
                    WorkoutStatsView(duration: viewModel.formattedDuration, calories: Int(viewModel.caloriesBurned))
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Instructions card
                if !viewModel.isStarted && !viewModel.isCountingDown {
                    VStack(spacing: isPhone ? 16 : 24) {
                        Text("Squat Instructions")
                            .font(isPhone ? .title3 : .title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        VStack(alignment: .leading, spacing: isPhone ? 12 : 16) {
                            InstructionRow(number: "1", text: "Put the Phone on the ground leaning on something in front of you")
                            InstructionRow(number: "2", text: "Click START, step back and Stand with feet shoulder-width apart")
                            InstructionRow(number: "3", text: "Lower your body by bending your knees")
                            InstructionRow(number: "4", text: "Keep your back straight")
                            InstructionRow(number: "5", text: "Return to standing position")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: 500)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : .white)
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 10)
                    )
                    .padding(.horizontal, isPhone ? 20 : 40)
                }
                
                Spacer()
                
                // Bottom button row
                HStack {
                    // Debug toggle button
                    Button(action: {
                        showDebugView.toggle()
                    }) {
                        Image(systemName: "ladybug")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.gray.opacity(0.7)))
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // Start/Stop button with improved touch target
                    Button(action: {
                        if viewModel.isStarted {
                            viewModel.stopWorkout()
                        } else {
                            viewModel.startWorkout()
                        }
                    }) {
                        Text(viewModel.isStarted ? "Stop" : "Start")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: isPhone ? 160 : 200, height: 56) // Minimum 44pt height for touch targets
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(viewModel.isStarted ? Color.red : accentColor)
                            )
                            .shadow(color: (viewModel.isStarted ? Color.red : accentColor).opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Color.clear
                        .frame(width: 44, height: 44)
                        .padding(.trailing)
                }
                .padding(.bottom, isPhone ? max((UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), 20) + 16 : 50)
            }
            .animation(.easeInOut(duration: uiAnimationDuration), value: viewModel.isStarted)
            .animation(.easeInOut(duration: countdownAnimationDuration), value: viewModel.isCountingDown)
        }
        .navigationTitle("Squat Counter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showHistoryView = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18))
                }
            }
        }
        .sheet(isPresented: $showHistoryView) {
            WorkoutHistoryView()
        }
        .onAppear { 
            checkCameraPermission() 
            
            // Handle camera errors
            NotificationCenter.default.addObserver(forName: .AVCaptureSessionRuntimeError, object: nil, queue: .main) { notification in
                if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error {
                    viewModel.handleCameraError(error)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Camera access is required to use the squat counter.")
        }
        .statusBar(hidden: false)
    }
    
    // Helper to determine if we're on iPhone
    private var isPhone: Bool {
        horizontalSizeClass == .compact
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    showingPermissionAlert = true
                }
            }
        default:
            showingPermissionAlert = true
        }
    }
}

// Workout statistics view
struct WorkoutStatsView: View {
    let duration: String
    let calories: Int
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 20) {
            // Duration stat
            StatCard(
                icon: "clock",
                value: duration,
                label: "DURATION"
            )
            
            // Calories stat
            StatCard(
                icon: "flame.fill",
                value: "\(calories)",
                label: "CALORIES"
            )
        }
        .padding(.horizontal)
    }
}

// Individual stat card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(icon == "flame.fill" ? .orange : .blue)
                .frame(width: 32, height: 32)
            
            // Value and label
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : .white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity)
    }
}

// Instruction row component
struct InstructionRow: View {
    let number: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Number circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            // Instruction text
            Text(text)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true) // Ensures text wraps properly
            
            Spacer()
        }
    }
}

// Guide overlay to help users position themselves
struct GuideOverlay: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let accentColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Center line
                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                
                // Squat depth indicator line
                let depthPosition = horizontalSizeClass == .compact ? 0.65 : 0.7 // Adjust for iPhone
                Rectangle()
                    .fill(accentColor.opacity(0.5))
                    .frame(width: geometry.size.width * 0.6, height: 2)
                    .position(x: geometry.size.width/2, y: geometry.size.height * depthPosition)
            }
        }
    }
}

// Countdown overlay
struct CountdownOverlay: View {
    let count: Int
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background blur
            BlurView(style: .systemThinMaterial)
                .edgesIgnoringSafeArea(.all)
            
            // Count with shadow for better visibility
            Text("\(count)")
                .font(.system(size: horizontalSizeClass == .compact ? 120 : 160, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
}

// UIKit blur view for better visual effects
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct SquatCounterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                SquatCounterView()
            }
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("iPhone (Light)")
            
            NavigationView {
                SquatCounterView()
            }
            .previewDevice("iPhone 14 Pro")
            .environment(\.colorScheme, .dark)
            .previewDisplayName("iPhone (Dark)")
            
            NavigationView {
                SquatCounterView()
            }
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewDisplayName("iPad")
        }
    }
} 
