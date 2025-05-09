import SwiftUI
import Combine
import FirebaseAuth

class SettingsViewModel: ObservableObject {
    // App appearance settings
    @AppStorage("showGridLines") var showGridLines = true
    @AppStorage("useSystemAppearance") var useSystemAppearance = true
    @AppStorage("isDarkMode") var isDarkMode = false
    
    // Alert states
    @Published var showingSignOutAlert = false
    @Published var showingExportAlert = false
    @Published var showingClearDataAlert = false
    @Published var showingPrivacyPolicy = false
    @Published var showingTermsOfService = false
    @Published var showingClearSuccess = false
    
    // Export states
    @Published var isExporting = false
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var showingExportSheet = false
    @Published var selectedExportFormat: WorkoutExporter.ExportFormat = .csv
    
    // User info
    @Published var userEmail: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserInfo()
    }
    
    // MARK: - Theme Management
    
    func applyTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
    
    func updateAppearanceBasedOnSystem(colorScheme: ColorScheme) {
        if useSystemAppearance {
            isDarkMode = colorScheme == .dark
        }
    }
    
    // MARK: - User Management
    
    func loadUserInfo() {
        userEmail = AuthService.shared.getCurrentUserEmail()
    }
    
    func signOut(completion: @escaping () -> Void) {
        let _ = AuthService.shared.signOut()
        completion()
    }
    
    // MARK: - Data Management
    
    func exportWorkoutData() {
        isExporting = true
        
        WorkoutHistoryManager.shared.getAllWorkoutSessions { [weak self] result in
            DispatchQueue.main.async {
                self?.isExporting = false
                
                switch result {
                case .success(let sessions):
                    if sessions.isEmpty {
                        self?.showingExportAlert = true
                    } else {
                        self?.workoutSessions = sessions
                        self?.showingExportSheet = true
                    }
                case .failure(let error):
                    print("Error loading workout sessions: \(error.localizedDescription)")
                    self?.showingExportAlert = true
                }
            }
        }
    }
    
    func clearUserData() {
        WorkoutHistoryManager.shared.clearAllSessions { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showingClearSuccess = true
                case .failure(let error):
                    print("Error clearing data: \(error.localizedDescription)")
                }
            }
        }
    }
} 