import SwiftUI
import FirebaseAuth
import StoreKit
import FirebaseFirestore

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
        Form {
                Section(header: Text("Appearance")) {
                    Toggle("Use System Appearance", isOn: $viewModel.useSystemAppearance)
                        .onChange(of: viewModel.useSystemAppearance) { _ in
                            viewModel.updateAppearanceBasedOnSystem(colorScheme: systemColorScheme)
                        }
                    
                    if !viewModel.useSystemAppearance {
                        Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                            .onChange(of: viewModel.isDarkMode) { _ in
                                viewModel.applyTheme()
                            }
                    }
                }
                
            Section(header: Text("Display")) {
                Toggle("Show Grid Lines", isOn: $viewModel.showGridLines)
                }
                
                Section(header: Text("Account")) {
                    if let email = viewModel.userEmail {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        viewModel.showingSignOutAlert = true
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
                        viewModel.exportWorkoutData()
                    }) {
                        HStack {
                            Text("Export Workout Data")
                            Spacer()
                            if viewModel.isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    .disabled(viewModel.isExporting)
                    
                    Button(action: {
                        viewModel.showingClearDataAlert = true
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
                        viewModel.showingPrivacyPolicy = true
                    }) {
                        Text("Privacy Policy")
                    }
                    
                    Button(action: {
                        viewModel.showingTermsOfService = true
                    }) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $viewModel.showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut {
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Export Data", isPresented: $viewModel.showingExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No workout data available to export.")
            }
            .alert("Clear Data", isPresented: $viewModel.showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearUserData()
                }
            } message: {
                Text("This will delete all your workout data. This action cannot be undone.")
            }
            .alert("Data Cleared", isPresented: $viewModel.showingClearSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All your workout data has been successfully deleted.")
            }
            .sheet(isPresented: $viewModel.showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $viewModel.showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $viewModel.showingExportSheet) {
                ExportView(workoutSessions: viewModel.workoutSessions)
            }
        }
        .onAppear {
            viewModel.loadUserInfo()
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
                    
                    Text("Last updated: \(Date().formattedLongDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This Privacy Policy describes how your personal information is collected, used, and shared when you use the Squat app.")
                        .padding(.vertical, 8)
                    
                    Group {
                        Text("1. Information We Collect")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("We collect several types of information when you use our app:")
                            .padding(.vertical, 4)
                        
                        Text("• Personal Information: When you create an account, we collect your email address and authentication information.")
                            .padding(.vertical, 2)
                        
                        Text("• Workout Data: We collect information about your workouts, including duration, repetitions, form data, movement patterns, and estimated calories burned.")
                            .padding(.vertical, 2)
                        
                        Text("• Device Information: We collect information about your device, including device model, operating system, and unique device identifiers.")
                            .padding(.vertical, 2)
                        
                        Text("• Camera Data: The app uses your device's camera to track your movements for workout analysis. This data is processed on-device and is not stored or transmitted unless you explicitly choose to save your workout.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("2. How We Use Your Information")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("We use the information we collect to:")
                            .padding(.vertical, 4)
                        
                        Text("• Provide, maintain, and improve our services")
                            .padding(.vertical, 2)
                        
                        Text("• Track your workout progress and provide feedback on your form")
                            .padding(.vertical, 2)
                        
                        Text("• Sync your data across your devices")
                            .padding(.vertical, 2)
                        
                        Text("• Analyze app usage to improve user experience")
                            .padding(.vertical, 2)
                        
                        Text("• Communicate with you about your account or the app")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("3. Data Storage and Security")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("Your workout data is stored in Firebase Firestore and is associated with your user account. We implement appropriate security measures to protect against unauthorized access, alteration, disclosure, or destruction of your personal information.")
                            .padding(.vertical, 4)
                        
                        Text("You can delete your data at any time through the app settings.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("4. Data Sharing")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("We do not sell your personal information to third parties. We may share your information with:")
                            .padding(.vertical, 4)
                        
                        Text("• Service Providers: Companies that provide services on our behalf, such as hosting, analytics, and customer service.")
                            .padding(.vertical, 2)
                        
                        Text("• Legal Requirements: When required by law or to protect our rights.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("5. Your Rights")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("Depending on your location, you may have certain rights regarding your personal information, including:")
                            .padding(.vertical, 4)
                        
                        Text("• Access: You can request access to the personal information we hold about you.")
                            .padding(.vertical, 2)
                        
                        Text("• Correction: You can request that we correct inaccurate information.")
                            .padding(.vertical, 2)
                        
                        Text("• Deletion: You can request that we delete your personal information.")
                            .padding(.vertical, 2)
                        
                        Text("• Data Portability: You can request a copy of your data in a structured, commonly used format.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("6. Changes to This Policy")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("We may update this privacy policy from time to time to reflect changes in our practices or for other operational, legal, or regulatory reasons. We will notify you of any material changes through the app or via email.")
                            .padding(.vertical, 4)
                    }
                    
                    Group {
                        Text("7. Contact Us")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("If you have any questions about this privacy policy or our data practices, please contact us at info@newhealthsociety.com.")
                            .padding(.vertical, 4)
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
                    
                    Text("Last updated: \(Date().formattedLongDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Please read these Terms of Service carefully before using the Squat app. By accessing or using the app, you agree to be bound by these Terms.")
                        .padding(.vertical, 8)
                    
                    Group {
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("By accessing or using the Squat app, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing the app.")
                            .padding(.vertical, 4)
                    }
                    
                    Group {
                        Text("2. Use of the App")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("The Squat app is designed to help you track your workout progress. You are responsible for using the app safely and following proper exercise techniques. We recommend consulting with a fitness professional before starting any new exercise program.")
                            .padding(.vertical, 4)
                        
                        Text("You agree to use the app only for lawful purposes and in a way that does not infringe upon the rights of others or restrict their use of the app.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("3. User Accounts")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("To use certain features of the app, you may need to create an account. You are responsible for:")
                            .padding(.vertical, 4)
                        
                        Text("• Maintaining the confidentiality of your account credentials")
                            .padding(.vertical, 2)
                        
                        Text("• All activities that occur under your account")
                            .padding(.vertical, 2)
                        
                        Text("• Notifying us immediately of any unauthorized use of your account")
                            .padding(.vertical, 2)
                        
                        Text("We reserve the right to terminate accounts that violate these Terms or for any other reason at our sole discretion.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("4. Intellectual Property")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("The Squat app, including its content, features, and functionality, is owned by us and is protected by copyright, trademark, and other intellectual property laws.")
                            .padding(.vertical, 4)
                        
                        Text("You may not reproduce, distribute, modify, create derivative works of, publicly display, publicly perform, republish, download, store, or transmit any of the material on our app without our prior written consent.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("5. User Content")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("Any content you submit to the app (such as workout data) remains your property. However, by submitting content, you grant us a non-exclusive, royalty-free, worldwide, perpetual license to use, modify, publicly display, reproduce, and distribute such content on and through the app.")
                            .padding(.vertical, 4)
                        
                        Text("You represent and warrant that you own or control all rights to the content you submit, and that such content does not violate these Terms or any applicable law.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("6. Subscription and Payments")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("Some features of the app may require a subscription. By subscribing, you agree to pay the fees as described at the time of purchase.")
                            .padding(.vertical, 4)
                        
                        Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage and cancel subscriptions through your App Store account settings.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("7. Disclaimer of Warranties")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED OR ERROR-FREE, OR THAT DEFECTS WILL BE CORRECTED.")
                            .padding(.vertical, 4)
                        
                        Text("WE DO NOT PROVIDE MEDICAL ADVICE. The app is not intended to diagnose, treat, cure, or prevent any disease or health condition. Always consult a qualified healthcare professional before starting any exercise program.")
                            .padding(.vertical, 2)
                    }
                    
                    Group {
                        Text("8. Limitation of Liability")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO, PERSONAL INJURY, PROPERTY DAMAGE, LOSS OF DATA, OR LOST PROFITS, ARISING OUT OF OR IN CONNECTION WITH YOUR USE OF THE APP.")
                            .padding(.vertical, 4)
                    }
                    
                    Group {
                        Text("9. Indemnification")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("You agree to indemnify and hold us harmless from any claims, losses, damages, liabilities, costs, and expenses, including legal fees, arising out of your use of the app, your violation of these Terms, or your violation of any rights of another.")
                            .padding(.vertical, 4)
                    }
                    
                    Group {
                        Text("10. Modifications to Terms")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("We reserve the right to modify these Terms at any time. We will provide notice of significant changes through the app. Your continued use of the app after such modifications constitutes your acceptance of the revised Terms.")
                            .padding(.vertical, 4)
                    }
                    
                    Group {
                        Text("11. Governing Law")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("These Terms shall be governed by and construed in accordance with the laws of Germany, without regard to its conflict of law provisions.")
                            .padding(.vertical, 4)
                    }
                    
                    Group {
                        Text("12. Contact Information")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("If you have any questions about these Terms, please contact us at info@newhealthsociety.com.")
                            .padding(.vertical, 4)
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

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    let workoutSessions: [WorkoutSession]
    @State private var exportFormat: WorkoutExporter.ExportFormat = .csv
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Export Format")) {
                        Picker("Format", selection: $exportFormat) {
                            Text("CSV").tag(WorkoutExporter.ExportFormat.csv)
                            Text("JSON").tag(WorkoutExporter.ExportFormat.json)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Summary")) {
                        HStack {
                            Text("Workouts")
                            Spacer()
                            Text("\(workoutSessions.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Duration")
                            Spacer()
                            Text(formatTotalDuration())
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total Repetitions")
                            Spacer()
                            Text("\(totalRepetitions())")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            exportWorkoutData()
                        }) {
                            HStack {
                                Spacer()
                                Text("Export Data")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export Workout Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Calculate total repetitions of all workouts
    private func totalRepetitions() -> Int {
        return workoutSessions.reduce(0) { $0 + $1.repCount }
    }
    
    // Calculate and format total duration
    private func formatTotalDuration() -> String {
        let totalSeconds = workoutSessions.reduce(0) { $0 + Int($1.duration) }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Export the workout data using the WorkoutExporter service
    private func exportWorkoutData() {
        self.exportWorkoutData(workoutSessions: workoutSessions, format: exportFormat)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 