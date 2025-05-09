import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isFirstTimeUser: Bool = false
    @Published var hasSeenTutorial: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService.shared
    private let defaults = UserDefaults.standard
    
    init() {
        // Load hasSeenTutorial from UserDefaults
        hasSeenTutorial = defaults.bool(forKey: "hasSeenTutorial")
        
        // Subscribe to AuthService changes
        authService.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                self?.isLoggedIn = isLoggedIn
                print("Login state changed: isLoggedIn = \(isLoggedIn)")
                
                // Every time login state changes, reload from UserDefaults
                if let defaults = self?.defaults {
                    self?.hasSeenTutorial = defaults.bool(forKey: "hasSeenTutorial")
                    print("Reloaded hasSeenTutorial from UserDefaults = \(self?.hasSeenTutorial ?? false)")
                }
            }
            .store(in: &cancellables)
        
        authService.$isFirstTimeUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFirstTime in
                self?.isFirstTimeUser = isFirstTime
                print("First time user state changed: isFirstTimeUser = \(isFirstTime)")
                
                // Only reset hasSeenTutorial for brand new registrations
                if isFirstTime && (self?.isLoggedIn == true) {
                    // This is a brand new user who just registered
                    self?.hasSeenTutorial = false
                    self?.defaults.set(false, forKey: "hasSeenTutorial") // Force-write to defaults
                    print("Setting hasSeenTutorial = false because user is new")
                }
            }
            .store(in: &cancellables)
        
        // Check auth state on initialization
        checkAuthState()
        
        // Monitor changes to hasSeenTutorial and save to UserDefaults
        $hasSeenTutorial
            .dropFirst() // Skip initial value
            .sink { [weak self] newValue in
                self?.defaults.set(newValue, forKey: "hasSeenTutorial")
            }
            .store(in: &cancellables)
    }
    
    /// Check if the user is currently authenticated
    func checkAuthState() {
        authService.checkAuthState()
        
        // We don't want to reset hasSeenTutorial here for existing users
        // It should only be reset during brand new account creation
        
        // However, we should load the latest value from UserDefaults
        // in case it was changed elsewhere in the app
        hasSeenTutorial = defaults.bool(forKey: "hasSeenTutorial")
        
        print("checkAuthState: isLoggedIn = \(isLoggedIn), isFirstTimeUser = \(isFirstTimeUser), hasSeenTutorial = \(hasSeenTutorial)")
    }
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        authService.signIn(email: email, password: password) { [weak self] error in
            if error == nil {
                self?.isFirstTimeUser = false
            }
            completion(error)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        authService.signUp(email: email, password: password) { [weak self] error in
            if error == nil {
                self?.isFirstTimeUser = true
                self?.hasSeenTutorial = false
            }
            completion(error)
        }
    }
    
    func signOut() {
        let _ = authService.signOut()
    }
    
    // Helper getter for current user ID
    var currentUserId: String? {
        return authService.getCurrentUserID()
    }
}
