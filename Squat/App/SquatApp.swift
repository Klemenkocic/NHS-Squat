import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import AuthenticationServices

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase synchronously on main thread to prevent race conditions
        // This is required as Firebase Auth needs FirebaseApp to be initialized first
        FirebaseApp.configure()
        print("Firebase configured on main thread")
        
        // Only do resource preloading asynchronously
        DispatchQueue.global(qos: .utility).async {
            ResourcePreloader.shared.preloadAll()
        }
        
        // Check Apple Sign In credential state for existing users
        if let userID = Auth.auth().currentUser?.uid {
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { (credentialState, error) in
                switch credentialState {
                case .authorized:
                    print("Apple credential still valid")
                case .revoked, .notFound:
                    // Handle sign out if credentials are revoked/not found
                    print("Apple credential revoked or not found - signing out")
                    try? Auth.auth().signOut()
                default:
                    break
                }
            }
        }
        
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
    @StateObject var authService = AuthService.shared
    
    // Theme settings
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Splash screen state
    @State private var showSplash = true
    
    // Enhanced timing for the splash screen
    // By using a slightly shorter display time, the app feels more responsive
    private let splashDuration: Double = 1.5
    
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
                        .environmentObject(authService)
                    } else {
                        WelcomeView()
                            .environmentObject(appViewModel)
                            .environmentObject(authService)
                    }
                }
                .preferredColorScheme(useSystemAppearance ? nil : (isDarkMode ? .dark : .light))
                .opacity(showSplash ? 0 : 1) // Ensure content is loaded but not visible during splash
                .onAppear {
                    // Check auth state immediately since Firebase is now initialized synchronously
                    appViewModel.checkAuthState()
                    
                    // Make sure splash screen gets dismissed after a fixed time
                    // This is a fallback in case of any issues
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if showSplash {
                            print("Forcing splash screen dismissal after timeout")
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
                }
                
                // Splash screen overlay
                if showSplash {
                    EnhancedSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            // Dismiss splash with smoother timing
                            DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) {
                                withAnimation(.easeOut(duration: 0.7)) {
                                    showSplash = false
                                    print("Dismissing splash screen")
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
        GeometryReader { geometry in
            ZStack {
                // First add a solid color as a fallback
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                // Then try to load the image
                if let uiImage = UIImage(named: "welcome_bg") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        // Use frame to exactly position the image to match Launch Screen
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .position(x: geometry.size.width/2, y: geometry.size.height/2)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
    }
}
