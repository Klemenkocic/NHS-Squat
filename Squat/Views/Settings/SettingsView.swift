import SwiftUI
import FirebaseAuth
import StoreKit

struct SettingsView: View {
    @AppStorage("showGridLines") private var showGridLines = true
    
    @AppStorage("useSystemAppearance") private var useSystemAppearance = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSignOutAlert = false
    @State private var showingExportAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    @State private var userEmail: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Use System Appearance", isOn: $useSystemAppearance)
                        .onChange(of: useSystemAppearance) { _ in
                            if useSystemAppearance {
                                isDarkMode = systemColorScheme == .dark
                            }
                        }
                    
                    if !useSystemAppearance {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .onChange(of: isDarkMode) { _ in
                                applyTheme()
                            }
                    }
                }
                
                Section(header: Text("Display")) {
                    Toggle("Show Grid Lines", isOn: $showGridLines)
                        .onChange(of: showGridLines) { _ in
                            // This will trigger an immediate update of the grid display
                            // No additional code needed as the StickFigureView observes this value
                        }
                }
                
                Section(header: Text("Account")) {
                    if let email = Auth.auth().currentUser?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: {
                        showingExportAlert = true
                    }) {
                        HStack {
                            Text("Export Workout Data")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Text("Clear All Data")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Legal")) {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        Text("Privacy Policy")
                    }
                    
                    Button(action: {
                        showingTermsOfService = true
                    }) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    appViewModel.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Export Data", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This feature will be available soon.")
            }
            .alert("Clear Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    // Handle data clearing
                }
            } message: {
                Text("This will delete all your workout data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                // Privacy Policy View
                Text("Privacy Policy")
            }
            .sheet(isPresented: $showingTermsOfService) {
                // Terms of Service View
                Text("Terms of Service")
            }
        }
        .onAppear {
            userEmail = Auth.auth().currentUser?.email
        }
    }
    
    private func applyTheme() {
        // Apply theme changes
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}

struct CameraPermissionsView: View {
    var body: some View {
        List {
            Section {
                Text("Squat uses your camera to track your workout movements and count repetitions.")
                    .font(.body)
                    .padding(.vertical, 8)
                
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Open Settings")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Camera Permissions")
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("Last updated: March 15, 2024")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This Privacy Policy describes how your personal information is collected, used, and shared when you use the Squat app.")
                        .padding(.vertical, 8)
                    
                    Group {
                        Text("Information We Collect")
                            .font(.headline)
                        
                        Text("When you use our app, we collect information about your workouts, including duration, repetitions, and estimated calories burned. We also collect authentication information when you sign in.")
                    }
                    
                    Group {
                        Text("How We Use Your Information")
                            .font(.headline)
                        
                        Text("We use the information we collect to provide, maintain, and improve our services, including tracking your workout progress and syncing your data across devices.")
                    }
                    
                    Group {
                        Text("Data Storage")
                            .font(.headline)
                        
                        Text("Your workout data is stored in Firebase Firestore and is associated with your user account. You can delete your data at any time through the app settings.")
                    }
                    
                    Group {
                        Text("Camera Usage")
                            .font(.headline)
                        
                        Text("The app uses your device's camera to track your movements for workout counting. Camera data is processed on-device and is not stored or transmitted.")
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    Text("Last updated: March 15, 2024")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("By using the Squat app, you agree to these terms of service.")
                        .padding(.vertical, 8)
                    
                    Group {
                        Text("Use of the App")
                            .font(.headline)
                        
                        Text("The Squat app is designed to help you track your workout progress. You are responsible for using the app safely and following proper exercise techniques.")
                    }
                    
                    Group {
                        Text("User Accounts")
                            .font(.headline)
                        
                        Text("You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.")
                    }
                    
                    Group {
                        Text("Limitation of Liability")
                            .font(.headline)
                        
                        Text("The app is provided 'as is' without warranties of any kind. We are not liable for any injuries or damages that may result from using the app.")
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 