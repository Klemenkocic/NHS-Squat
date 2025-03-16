import SwiftUI
import FirebaseAuth

class AppViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isFirstTimeUser: Bool = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false

    init() {
        // Firebase automatically persists the user session.
        // If a user is logged in, Auth.auth().currentUser will be non-nil.
        checkAuthState()
    }
    
    /// Check if the user is currently authenticated
    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            self.isLoggedIn = true
            
            // Check if this is a new user (metadata.creationDate is close to last sign-in date)
            let metadata = user.metadata
            if let creationDate = metadata.creationDate,
               let lastSignInDate = metadata.lastSignInDate,
               creationDate.timeIntervalSince1970 > Date().timeIntervalSince1970 - 300, // Created in the last 5 minutes
               abs(creationDate.timeIntervalSince1970 - lastSignInDate.timeIntervalSince1970) < 300 { // First sign-in
                self.isFirstTimeUser = true
                self.hasSeenTutorial = false // Reset tutorial flag for new users
            }
        } else {
            self.isLoggedIn = false
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if error == nil {
                    self.isLoggedIn = true
                    self.isFirstTimeUser = false // Existing user
                }
                completion(error)
            }
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if error == nil {
                    self.isLoggedIn = true
                    self.isFirstTimeUser = true // New user
                    self.hasSeenTutorial = false // Reset tutorial flag for new users
                }
                completion(error)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
}
