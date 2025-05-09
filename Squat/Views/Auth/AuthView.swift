import SwiftUI
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import GoogleSignIn

// MARK: - Notification Name Extension
extension Notification.Name {
    static let appleSignInSuccess = Notification.Name("AppleSignInSuccess")
}

enum AuthMode {
    case login
    case register
}

// MARK: - AuthView
struct AuthView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var authMode: AuthMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title - Fixed at the top
                Text("Login")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 80)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                
            // Login/Register Picker
            Picker(selection: $authMode, label: Text("")) {
                Text("Login").tag(AuthMode.login)
                Text("Register").tag(AuthMode.register)
            }
            .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Form fields in a ScrollView to handle variable content
                VStack(spacing: 16) {
            // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            TextField("", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundColor(.primary)
                                .accentColor(.blue)
                                .modifier(PlaceholderStyle(showPlaceHolder: email.isEmpty, placeholder: "your@email.com"))
                        }
                .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }

            // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            SecureField("••••••••", text: $password)
                                .foregroundColor(.primary)
                                .accentColor(.blue)
                        }
                .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }

            // Confirm password (Register mode only)
            if authMode == .register {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                
                                SecureField("••••••••", text: $confirmPassword)
                                    .foregroundColor(.primary)
                                    .accentColor(.blue)
                            }
                    .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .animation(.none, value: authMode) // Prevent animation when switching modes

            // Forgot password (Login mode only)
            if authMode == .login {
                    HStack {
                        Spacer()
                Button("Forgot Password?") {
                    sendPasswordReset()
                }
                        .font(.system(size: 14))
                .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                }
                
                // Add spacer to ensure consistent spacing
                if authMode == .register {
                    Spacer()
                        .frame(height: 30) // Match the height of the forgot password section
            }

            // Primary auth button
            Button(action: handleAuth) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        
                Text(authMode == .login ? "Login" : "Register")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
            }
            .disabled(isProcessing)
                .padding(.horizontal, 24)
                .padding(.top, 32)

                // Divider
                HStack {
                    VStack { Divider() }.padding(.horizontal, 8)
                    Text("OR")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    VStack { Divider() }.padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)

            // Third-party sign-in
                VStack(spacing: 16) {
            // Google Sign In
                    Button(action: handleGoogleSignIn) {
                        HStack {
                            Image("google_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            
                            Text("Sign in with Google")
                                .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                        )
                        .foregroundColor(.primary)
                    }

            // Apple Sign In
                    Button(action: handleAppleSignIn) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            
                            Text("Sign in with Apple")
                                .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                        )
            .foregroundColor(.white)
                    }
        }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Message"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        // Automatically mark user as logged in after Apple sign-in success
        .onReceive(NotificationCenter.default.publisher(for: .appleSignInSuccess)) { notification in
            // Always update login state first
            appViewModel.isLoggedIn = true
            
            // Check if this is a new user
            if let isNewUser = notification.userInfo?["isNewUser"] as? Bool, isNewUser {
                print("New user created with Apple: Ensuring tutorial will show")
                // Directly modify UserDefaults to guarantee tutorial will show
                UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
                
                // Set first time user flag
                appViewModel.isFirstTimeUser = true
            }
        }
    }

    // MARK: - Email/Password Auth
    func handleAuth() {
        errorMessage = ""
        isProcessing = true

        if authMode == .register {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                showAlert = true
                isProcessing = false
                return
            }
            appViewModel.signUp(email: email, password: password) { error in
                isProcessing = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        } else {
            appViewModel.signIn(email: email, password: password) { error in
                isProcessing = false
                if let error = error {
                    let authError = AuthErrorCode(rawValue: (error as NSError).code)
                    switch authError {
                    case .wrongPassword:
                        errorMessage = "Wrong password."
                    case .userNotFound:
                        errorMessage = "Unknown email."
                    default:
                        errorMessage = error.localizedDescription
                    }
                    showAlert = true
                }
            }
        }
    }

    // MARK: - Password Reset
    func sendPasswordReset() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address first."
            showAlert = true
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = "Password reset email sent. Check your inbox."
            }
            showAlert = true
        }
    }

    // MARK: - Google Sign In
    func handleGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { signInResult, error in
            if let error = error {
                print("Google sign in error: \(error.localizedDescription)")
                return
            }
            guard let result = signInResult else { return }
            let user = result.user
            guard let idToken = user.idToken?.tokenString else { return }
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign in with Google error: \(error.localizedDescription)")
                } else {
                    print("User signed in with Google, user: \(authResult?.user.uid ?? "none")")
                    
                    // Check if this is a new user
                    let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                    
                    DispatchQueue.main.async {
                        // Always ensure login state is updated first
                        self.appViewModel.isLoggedIn = true
                        
                        if isNewUser {
                            print("New user created with Google: Ensuring tutorial will show")
                            // Directly modify UserDefaults to guarantee tutorial will show
                            UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
                            
                            // Set first time user flag
                            self.appViewModel.isFirstTimeUser = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Apple Sign In
    func handleAppleSignIn() {
        // Use the centralized auth service for Apple Sign In
        AuthService.shared.signInWithApple(presenting: getRootViewController()) { error, isNewUser in
            if let error = error {
                print("Apple sign in error: \(error.localizedDescription)")
                self.errorMessage = "Apple sign in failed: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            // isLoggedIn state is already updated in AuthService
            print("Successfully signed in with Apple, isNewUser: \(isNewUser)")
            
            // Ensure the app knows we're logged in
            self.appViewModel.isLoggedIn = true
            
            // If this is a new user, ensure the tutorial will be shown
            if isNewUser {
                self.appViewModel.isFirstTimeUser = true
            }
        }
    }

    // Helper to get the root view controller for presenting sign-in flows
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = screen.windows.first,
              let rootVC = window.rootViewController else {
            return UIViewController()
        }
        return rootVC
    }
}

// MARK: - Apple Sign In Helpers

/// Delegate to handle Apple sign-in callbacks
class AppleSignInAuthDelegate: NSObject, ASAuthorizationControllerDelegate {
    static let shared = AppleSignInAuthDelegate()
    var currentNonce: String?
    
    // Add completion handler property
    var completionHandler: ((ASAuthorizationCredential?, Error?) -> Void)?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Extract Apple ID credential
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Apple sign in failed: No ASAuthorizationAppleIDCredential.")
            completionHandler?(nil, NSError(domain: "AppleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "No ASAuthorizationAppleIDCredential"]))
            return
        }
        
        // Call completion handler if set
        completionHandler?(appleIDCredential, nil)
        
        guard let nonce = currentNonce else {
            print("Invalid state: No nonce provided.")
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch or serialize identity token.")
            return
        }

        // Create OAuth credential for Firebase
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)

        // Sign in with Firebase
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase sign in with Apple error: \(error.localizedDescription)")
            } else {
                print("User signed in with Apple, user: \(authResult?.user.uid ?? "none")")
                
                // Check if this is a new user - very important for showing the tutorial
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                print("Apple sign-in: isNewUser = \(isNewUser)")
                
                // Notify AuthView that sign in succeeded and if it's a new user
                DispatchQueue.main.async {
                    // Post notification with isNewUser information
                    NotificationCenter.default.post(
                        name: .appleSignInSuccess,
                        object: nil,
                        userInfo: ["isNewUser": isNewUser]
                    )
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple sign in error: \(error.localizedDescription)")
        // Call completion handler with error if set
        completionHandler?(nil, error)
    }

    /// Generate a random nonce string
    func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }
            randomBytes.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}

/// Provides the presentation anchor for the Apple sign-in flow
class AppleSignInPresentationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleSignInPresentationProvider()
    
    // Store the presenting view controller
    var presentingViewController: UIViewController?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let viewController = presentingViewController, 
           let window = viewController.view.window {
            return window
        }
        
        // Fallback to getting the key window
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first ?? UIWindow()
        return window
    }
}

// MARK: - Placeholder Style Modifier
struct PlaceholderStyle: ViewModifier {
    var showPlaceHolder: Bool
    var placeholder: String

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if showPlaceHolder {
                Text(placeholder)
                    .foregroundColor(Color(.placeholderText))
            }
            content
        }
    }
}

