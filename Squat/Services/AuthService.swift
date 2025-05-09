import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import AuthenticationServices

/// AuthService handles all authentication operations for the app
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isLoggedIn: Bool = false
    @Published var isFirstTimeUser: Bool = false
    @Published var currentUser: User?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State
    
    /// Setup listener for authentication state changes
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isLoggedIn = user != nil
                
                // Reset isFirstTimeUser to false by default
                self?.isFirstTimeUser = false
                
                // We don't want to set isFirstTimeUser to true here for regular sign-ins
                // This will only be set to true during specific sign-up operations
            }
        }
    }
    
    /// Check current authentication state
    func checkAuthState() {
        DispatchQueue.main.async {
            self.currentUser = Auth.auth().currentUser
            self.isLoggedIn = self.currentUser != nil
            
            // Don't modify isFirstTimeUser here - it should only be set during registration
        }
    }
    
    // MARK: - Email Authentication
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Callback with optional error
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.isLoggedIn = true
                    // Explicitly set isFirstTimeUser to false for sign-ins
                    self?.isFirstTimeUser = false
                }
                completion(error)
            }
        }
    }
    
    /// Create a new account with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Callback with optional error
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.isLoggedIn = true
                    // This is the ONLY place we set isFirstTimeUser to true - new account creation
                    self?.isFirstTimeUser = true
                    print("New user created with email: setting isFirstTimeUser = true")
                }
                completion(error)
            }
        }
    }
    
    /// Send password reset email
    /// - Parameters:
    ///   - email: User's email
    ///   - completion: Callback with optional error
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    /// - Returns: Optional error if sign out fails
    @discardableResult
    func signOut() -> Error? {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUser = nil
            }
            return nil
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            return error
        }
    }
    
    // MARK: - Google Sign In
    
    /// Handle Google Sign In
    /// - Parameters:
    ///   - viewController: The view controller to present the sign-in flow
    ///   - completion: Callback with optional error
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase app not configured"]))
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] signInResult, error in
            if let error = error {
                print("Google sign in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let result = signInResult else {
                completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No sign in result"]))
                return
            }
            
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token"]))
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Capture the current user state before signing in
            let wasSignedIn = Auth.auth().currentUser != nil
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                DispatchQueue.main.async {
                    if error == nil, let authResult = authResult {
                        self?.isLoggedIn = true
                        
                        // Check if this created a new account
                        if !wasSignedIn && authResult.additionalUserInfo?.isNewUser == true {
                            // This is a brand new user signing up with Google
                            self?.isFirstTimeUser = true
                            print("New user created with Google: setting isFirstTimeUser = true")
                        } else {
                            // This is an existing user signing in with Google
                            self?.isFirstTimeUser = false
                        }
                    }
                    completion(error)
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    /// Handle Apple Sign In
    /// - Parameters:
    ///   - viewController: The view controller to present the sign-in flow
    ///   - completion: Callback with optional error and isNewUser flag
    func signInWithApple(presenting viewController: UIViewController, completion: @escaping (Error?, Bool) -> Void) {
        // Generate a nonce for security
        let nonce = AppleSignInAuthDelegate.shared.generateNonce()
        AppleSignInAuthDelegate.shared.currentNonce = nonce
        
        // Create the Apple ID request
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        
        // Create and present the sign-in controller
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = AppleSignInAuthDelegate.shared
        
        // Use existing presentation provider
        let presentationProvider = AppleSignInPresentationProvider.shared
        presentationProvider.presentingViewController = viewController
        authController.presentationContextProvider = presentationProvider
        
        // Set completion handler
        AppleSignInAuthDelegate.shared.completionHandler = { [weak self] (credential, error) in
            if let error = error {
                print("Apple sign in error: \(error.localizedDescription)")
                completion(error, false)
                return
            }
            
            guard let appleIDCredential = credential as? ASAuthorizationAppleIDCredential else {
                completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ASAuthorizationAppleIDCredential"]), false)
                return
            }
            
            guard let nonce = AppleSignInAuthDelegate.shared.currentNonce else {
                completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: No nonce"]), false)
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]), false)
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completion(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string"]), false)
                return
            }
            
            // Create Firebase credential
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            // Capture the current user state before signing in
            let wasSignedIn = Auth.auth().currentUser != nil
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    print("Firebase sign in with Apple error: \(error.localizedDescription)")
                    completion(error, false)
                    return
                }
                
                print("User signed in with Apple, user: \(authResult?.user.uid ?? "none")")
                
                // Check if this is a new user
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                print("Apple sign-in: isNewUser = \(isNewUser)")
                
                DispatchQueue.main.async {
                    // Update login state
                    self?.isLoggedIn = true
                    
                    // Update first time user state if needed
                    if isNewUser {
                        print("New user created with Apple: Setting first time user flag")
                        self?.isFirstTimeUser = true
                        // Ensure tutorial will show
                        UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
                    }
                    
                    // Notify about successful auth and whether it's a new user
                    NotificationCenter.default.post(
                        name: .appleSignInSuccess,
                        object: nil,
                        userInfo: ["isNewUser": isNewUser]
                    )
                    
                    // Complete with no error and isNewUser status
                    completion(nil, isNewUser)
                }
            }
        }
        
        // Perform the request
        authController.performRequests()
    }
    
    // MARK: - Utility Methods
    
    /// Get current user's ID
    /// - Returns: User ID string or nil if not logged in
    func getCurrentUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Get current user's email
    /// - Returns: User email or nil if not logged in
    func getCurrentUserEmail() -> String? {
        return Auth.auth().currentUser?.email
    }
} 