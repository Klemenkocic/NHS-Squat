import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices

struct WelcomeView: View {
    @State private var navigateToAuth = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Fixed animation duration
    private let animationDuration: Double = 0.3

    var body: some View {
        ZStack {
            // Background gradient
            Group {
                if UIImage(named: "welcome_bg") != nil {
                    Image("welcome_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
                        .overlay(
                            Color.black.opacity(0.3)
                        )
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $navigateToAuth) {
            AuthView()
                .background(Color.white)
        }
        .onAppear {
            // Automatically navigate to auth view after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    navigateToAuth = true
                }
            }
        }
    }
}

// Feature row component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - EnhancedAuthView
struct EnhancedAuthView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var authMode: AuthMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text(authMode == .login ? "Welcome Back" : "Create Account")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(authMode == .login ? "Sign in to continue" : "Join the community")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Auth mode selector
            Picker(selection: $authMode, label: Text("")) {
                Text("Sign In").tag(AuthMode.login)
                Text("Sign Up").tag(AuthMode.register)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
            
            // Form fields
            VStack(spacing: 16) {
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.secondary)
                        
                        TextField("your@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                
                // Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        
                        SecureField("••••••••", text: $password)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                
                // Confirm password (only for Register mode)
                if authMode == .register {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                            
                            SecureField("••••••••", text: $confirmPassword)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                }
            }
            .padding(.horizontal, 30)
            
            // Forgot password (login mode only)
            if authMode == .login {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        sendPasswordReset()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 30)
            }
            
            // Primary action button
            Button(action: handleAuth) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    
                    Text(authMode == .login ? "Sign In" : "Create Account")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            .disabled(isProcessing)
            .padding(.horizontal, 30)
            .padding(.top, 30)
            
            // Divider
            HStack {
                VStack { Divider() }.padding(.horizontal, 8)
                Text("OR")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                VStack { Divider() }.padding(.horizontal, 8)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            
            // Social sign-in
            VStack(spacing: 12) {
                // Apple Sign In
                Button(action: handleAppleSignIn) {
                    HStack {
                        Image("apple_icon_white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        
                        Text("Continue with Apple")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                    )
                    .foregroundColor(.white)
                }
                
                // Google Sign In
                Button(action: handleGoogleSignIn) {
                    HStack {
                        Image("google_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        
                        Text("Continue with Google")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
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
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Handle Login/Register
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
    
    // MARK: - Reset Password
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
                self.errorMessage = "Google sign in failed: \(error.localizedDescription)"
                self.showAlert = true
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
                    self.errorMessage = "Firebase sign in failed: \(error.localizedDescription)"
                    self.showAlert = true
                } else {
                    print("User signed in with Google, user: \(authResult?.user.uid ?? "none")")
                    self.appViewModel.isLoggedIn = true
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
    
    // Helper to present sign-in flows
    func getRootViewController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = screen.windows.first,
              let rootVC = window.rootViewController else {
            return UIViewController()
        }
        return rootVC
    }
}
