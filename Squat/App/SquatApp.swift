import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase as early as possible
        FirebaseApp.configure()
        return true
    }

    // This is crucial for Google Sign-In to return to your app
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct SquatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var appViewModel = AppViewModel()
    
    // Theme settings
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Splash screen state
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                Group {
                    if appViewModel.isLoggedIn {
                        NavigationView {
                            MenuView()
                        }
                        .environmentObject(appViewModel)
                    } else {
                        WelcomeView()
                            .environmentObject(appViewModel)
                    }
                }
                .preferredColorScheme(useSystemAppearance ? nil : (isDarkMode ? .dark : .light))
                .onAppear {
                    // Check authentication state immediately
                    appViewModel.checkAuthState()
                }
                
                // Splash screen overlay
                if showSplash {
                    EnhancedSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            // Dismiss splash after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - EnhancedSplashView
struct EnhancedSplashView: View {
    var body: some View {
        ZStack {
            // Background only
            if UIImage(named: "welcome_bg") != nil {
                Image("welcome_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.white
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Original SplashView (kept for reference)
struct SplashView: View {
    var body: some View {
        ZStack {
            // Background only
            if UIImage(named: "welcome_bg") != nil {
                Image("welcome_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.blue
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .transition(.opacity)
    }
}
