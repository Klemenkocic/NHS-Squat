import SwiftUI
import Foundation
import FirebaseAuth

struct WorkoutHistoryView: View {
    @State private var workoutSessions: [WorkoutSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: UUID?
    @State private var isUserSignedIn = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if !isUserSignedIn {
                    SignInPromptView()
                } else if isLoading {
                    LoadingView()
                } else if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage) {
                        loadWorkoutSessions()
                    }
                } else if workoutSessions.isEmpty {
                    EmptyStateView()
                } else {
                    workoutSessionsList
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkAuthState()
                loadWorkoutSessions()
            }
        }
    }
    
    private var workoutSessionsList: some View {
        List {
            ForEach(workoutSessions) { session in
                WorkoutSessionRow(session: session)
                    .swipeActions {
                        Button(role: .destructive) {
                            sessionToDelete = session.id
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .refreshable {
            await loadWorkoutSessionsAsync()
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = sessionToDelete {
                    deleteWorkoutSession(id: id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }
    
    private func checkAuthState() {
        isUserSignedIn = Auth.auth().currentUser != nil
    }
    
    private func loadWorkoutSessions() {
        isLoading = true
        errorMessage = nil
        
        WorkoutHistoryManager.shared.getAllWorkoutSessions { (result: Result<[WorkoutSession], Error>) in
            isLoading = false
            
            switch result {
            case .success(let sessions):
                workoutSessions = sessions
            case .failure(let error):
                errorMessage = "Failed to load workout history: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func loadWorkoutSessionsAsync() async {
        isLoading = true
        errorMessage = nil
        
        // Create a continuation to bridge between callback and async
        return await withCheckedContinuation { continuation in
            WorkoutHistoryManager.shared.getAllWorkoutSessions { (result: Result<[WorkoutSession], Error>) in
                isLoading = false
                
                switch result {
                case .success(let sessions):
                    workoutSessions = sessions
                case .failure(let error):
                    errorMessage = "Failed to load workout history: \(error.localizedDescription)"
                    showingError = true
                }
                
                continuation.resume()
            }
        }
    }
    
    private func deleteWorkoutSession(id: UUID) {
        WorkoutHistoryManager.shared.deleteWorkoutSession(sessionId: id) { (result: Result<Void, Error>) in
            switch result {
            case .success:
                // Remove from local array
                workoutSessions.removeAll { $0.id == id }
            case .failure(let error):
                errorMessage = "Failed to delete workout: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct SignInPromptView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("Sign In Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please sign in to view your workout history. Your workout data is stored securely in the cloud.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: AuthView()) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading workout history...")
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete your first workout to see it here!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.formattedDate)
                    .font(.headline)
                Spacer()
                Text("\(session.repCount) squats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label(session.formattedDuration, systemImage: "clock")
                Spacer()
                Label("\(Int(session.caloriesBurned)) calories", systemImage: "flame")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct WorkoutHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutHistoryView()
    }
} 