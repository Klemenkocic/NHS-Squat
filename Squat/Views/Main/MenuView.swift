import SwiftUI

// Preference key to capture button frames
struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { (_, new) in new }
    }
}

struct MenuView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var navigateToVisualizer = false
    @State private var navigateToTheory = false
    @State private var navigateToCounter = false
    @State private var navigateToSettings = false
    @State private var currentTutorialStep = 0
    @State private var showTutorial = false
    
    // State to store button frames
    @State private var buttonFrames: [String: CGRect] = [:]
    
    // Tutorial content
    private let tutorialSteps = [
        (title: "Squat Visualizer", description: "Analyze your squat mechanics in real-time with detailed feedback", icon: "figure.walk", color: Color.blue, id: "visualizer"),
        (title: "Squat Theory", description: "Learn proper technique and form through comprehensive guides", icon: "book.fill", color: Color.green, id: "theory"),
        (title: "Squat Counter", description: "Track your reps and monitor your workout progress", icon: "number.circle.fill", color: Color.purple, id: "counter"),
        (title: "Settings", description: "Customize your experience and manage your preferences", icon: "gearshape.fill", color: Color.orange, id: "settings")
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            // Main content
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                        Text("NHS Squat Analysis")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                        Text("Perfect Your Form Today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Main Menu Cards
                VStack(spacing: 20) {
                    // Visualizer Card
                        Button(action: {
                            if !showTutorial {
                                navigateToVisualizer = true
                            }
                        }) {
                        MenuCard(
                            title: "Squat Visualizer",
                                subtitle: "Analyze Squat Mechanics",
                            systemImage: "figure.walk",
                            color: .blue
                        )
                    }
                        .buttonStyle(PlainButtonStyle())
                        .id("visualizer")
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ButtonFramePreferenceKey.self, 
                                                value: ["visualizer": geo.frame(in: .global)])
                            }
                        )
                        .background(
                            NavigationLink(
                                destination: ContentView(),
                                isActive: $navigateToVisualizer,
                                label: { EmptyView() }
                            )
                        )
                    
                    // Theory Card
                        Button(action: {
                            if !showTutorial {
                                navigateToTheory = true
                            }
                        }) {
                        MenuCard(
                            title: "Squat Theory",
                                subtitle: "Learn Proper Technique",
                            systemImage: "book.fill",
                            color: .green
                        )
                    }
                        .buttonStyle(PlainButtonStyle())
                        .id("theory")
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ButtonFramePreferenceKey.self, 
                                                value: ["theory": geo.frame(in: .global)])
                            }
                        )
                        .background(
                            NavigationLink(
                                destination: TheoryView(),
                                isActive: $navigateToTheory,
                                label: { EmptyView() }
                            )
                        )
                        
                        // Counter Card
                        Button(action: {
                            if !showTutorial {
                                navigateToCounter = true
                            }
                        }) {
                        MenuCard(
                            title: "Squat Counter",
                                subtitle: "Track Your Reps",
                            systemImage: "number.circle.fill",
                            color: .purple
                        )
                    }
                        .buttonStyle(PlainButtonStyle())
                        .id("counter")
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ButtonFramePreferenceKey.self, 
                                                value: ["counter": geo.frame(in: .global)])
                            }
                        )
                        .background(
                            NavigationLink(
                                destination: SquatCounterView(),
                                isActive: $navigateToCounter,
                                label: { EmptyView() }
                            )
                        )
                    
                    // Settings Card
                        Button(action: {
                            if !showTutorial {
                                navigateToSettings = true
                            }
                        }) {
                        MenuCard(
                            title: "Settings",
                                subtitle: "Customize Your Experience",
                            systemImage: "gearshape.fill",
                            color: .orange
                        )
                    }
                        .buttonStyle(PlainButtonStyle())
                        .id("settings")
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ButtonFramePreferenceKey.self, 
                                                value: ["settings": geo.frame(in: .global)])
                            }
                        )
                        .background(
                            NavigationLink(
                                destination: SettingsView(),
                                isActive: $navigateToSettings,
                                label: { EmptyView() }
                            )
                        )
                }
                .padding(.horizontal)
                    
                    Spacer()
                    
                    // Powered by text
                    VStack(spacing: 4) {
                        Text("Powered By:")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("New Health Society")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
            .onPreferenceChange(ButtonFramePreferenceKey.self) { frames in
                self.buttonFrames = frames
            }
            
            // Tutorial overlay
            if showTutorial {
                TutorialOverlayView(
                    currentStep: currentTutorialStep,
                    tutorialSteps: tutorialSteps,
                    buttonFrames: buttonFrames,
                    onNext: nextTutorialStep,
                    onSkip: endTutorial,
                    onDone: endTutorial
                )
            }
        }
        .onAppear {
            // Reset navigation states when view appears
            navigateToVisualizer = false
            navigateToTheory = false
            navigateToCounter = false
            navigateToSettings = false
            
            // Show tutorial if user is new or hasn't seen the tutorial
            let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
            let isFirstTimeUser = appViewModel.isFirstTimeUser
            
            print("MenuView appeared: hasSeenTutorial = \(hasSeenTutorial), isFirstTimeUser = \(isFirstTimeUser)")
            print("appViewModel.hasSeenTutorial = \(appViewModel.hasSeenTutorial)")
            
            // If UserDefaults says we haven't seen tutorial OR the app thinks this is a first-time user
            // then show the tutorial
            if !hasSeenTutorial || isFirstTimeUser {
                print("Will show tutorial after delay")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                    print("Tutorial displayed: showTutorial = \(showTutorial)")
                }
            } else {
                print("Skipping tutorial display")
            }
        }
    }
    
    private func nextTutorialStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTutorialStep += 1
        }
    }
    
    private func endTutorial() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showTutorial = false
            appViewModel.hasSeenTutorial = true
        }
    }
}

// Tutorial Overlay View
struct TutorialOverlayView: View {
    let currentStep: Int
    let tutorialSteps: [(title: String, description: String, icon: String, color: Color, id: String)]
    let buttonFrames: [String: CGRect]
    let onNext: () -> Void
    let onSkip: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if let currentButtonId = tutorialSteps[safe: currentStep]?.id,
               let currentFrame = buttonFrames[currentButtonId] {
                
                ZStack {
                    // Dark overlay for the entire screen
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    
                    // Duplicate the button with exact styling to appear bright
                    MenuCard(
                        title: tutorialSteps[currentStep].title,
                        subtitle: currentStep == 0 ? "Analyze squat mechanics" :
                                  currentStep == 1 ? "Learn proper technique" :
                                  currentStep == 2 ? "Track your reps" : "Customize your experience",
                        systemImage: tutorialSteps[currentStep].icon,
                        color: tutorialSteps[currentStep].color
                    )
                    .frame(width: currentFrame.width, height: currentFrame.height)
                    .position(x: currentFrame.midX, y: currentFrame.midY)
                    .allowsHitTesting(false)
                    
                    // Colored outline around the button
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(tutorialSteps[currentStep].color, lineWidth: 3)
                        .frame(width: currentFrame.width, height: currentFrame.height)
                        .position(x: currentFrame.midX, y: currentFrame.midY)
                        .allowsHitTesting(false)
                    
                    // Description and navigation buttons
                    VStack(spacing: 16) {
                        Text(tutorialSteps[currentStep].description)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 20) {
                            // Skip button (only on first step)
                            if currentStep == 0 {
                                Button(action: onSkip) {
                                    Text("Skip")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 25)
                                        .background(Color.gray.opacity(0.5))
                                        .cornerRadius(10)
                                }
                            }
                            
                            Spacer()
                            
                            // Next/Done button
                            Button(action: {
                                if currentStep < tutorialSteps.count - 1 {
                                    onNext()
                                } else {
                                    onDone()
                                }
                            }) {
                                Text(currentStep < tutorialSteps.count - 1 ? "Next" : "Done")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 25)
                                    .background(tutorialSteps[currentStep].color)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width / 2, y: currentFrame.maxY + 100)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// Helper extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Helper Views
struct MenuCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundColor(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), 
                        radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(colorScheme == .dark ? Color(.systemGray5) : Color.clear, lineWidth: 1)
        )
    }
}

// Preview
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MenuView()
                .environmentObject(AppViewModel())
        }
    }
}

