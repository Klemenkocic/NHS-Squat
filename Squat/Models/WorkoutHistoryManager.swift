import Foundation
import FirebaseAuth

// Import the FirestoreError from FirestoreManager
public class WorkoutHistoryManager {
    public static let shared = WorkoutHistoryManager()
    
    // Keep a local cache of workout sessions
    private var cachedSessions: [WorkoutSession] = []
    private let firestoreManager = FirestoreManager.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Set up auth state listener
        setupAuthStateListener()
        
        // Load initial data if user is signed in
        if Auth.auth().currentUser != nil {
            loadWorkoutSessions()
        }
    }
    
    deinit {
        // Remove auth state listener
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Public Methods
    
    /// Save a new workout session
    /// - Parameters:
    ///   - duration: Duration of the workout in seconds
    ///   - repCount: Number of reps completed
    ///   - caloriesBurned: Estimated calories burned
    ///   - completion: Optional callback with success/failure result
    public func saveWorkoutSession(
        duration: TimeInterval,
        repCount: Int,
        caloriesBurned: Double,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let newSession = WorkoutSession(
            date: Date(),
            duration: duration,
            repCount: repCount,
            caloriesBurned: caloriesBurned
        )
        
        // Save to Firestore
        firestoreManager.saveWorkoutSession(newSession) { [weak self] (result: Result<Void, Error>) in
            switch result {
            case .success:
                // Update local cache
                self?.cachedSessions.insert(newSession, at: 0)
                completion?(.success(()))
            case .failure(let error):
                print("Error saving workout session: \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
    }
    
    /// Get all workout sessions
    /// - Returns: Array of workout sessions sorted by date (newest first)
    public func getAllWorkoutSessions() -> [WorkoutSession] {
        return cachedSessions
    }
    
    /// Get all workout sessions with completion handler
    /// - Parameter completion: Callback with array of workout sessions or error
    public func getAllWorkoutSessions(completion: @escaping (Result<[WorkoutSession], Error>) -> Void) {
        // Check if user is signed in
        guard Auth.auth().currentUser != nil else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        firestoreManager.getAllWorkoutSessions { [weak self] (result: Result<[WorkoutSession], Error>) in
            switch result {
            case .success(let sessions):
                self?.cachedSessions = sessions
                completion(.success(sessions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Delete a specific workout session
    /// - Parameters:
    ///   - sessionId: ID of the session to delete
    ///   - completion: Optional callback with success/failure result
    public func deleteWorkoutSession(
        sessionId: UUID,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        firestoreManager.deleteWorkoutSession(sessionId: sessionId) { [weak self] (result: Result<Void, Error>) in
            switch result {
            case .success:
                // Update local cache
                self?.cachedSessions.removeAll { $0.id == sessionId }
                completion?(.success(()))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    /// Clear all workout sessions (for testing)
    /// - Parameter completion: Optional callback with success/failure result
    public func clearAllSessions(completion: ((Result<Void, Error>) -> Void)? = nil) {
        firestoreManager.clearAllWorkoutSessions { [weak self] (result: Result<Void, Error>) in
            switch result {
            case .success:
                self?.cachedSessions.removeAll()
                completion?(.success(()))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if user != nil {
                // User signed in, load their data
                self?.loadWorkoutSessions()
            } else {
                // User signed out, clear cache
                self?.cachedSessions.removeAll()
            }
        }
    }
    
    private func loadWorkoutSessions() {
        firestoreManager.getAllWorkoutSessions { [weak self] (result: Result<[WorkoutSession], Error>) in
            switch result {
            case .success(let sessions):
                self?.cachedSessions = sessions
            case .failure(let error):
                print("Error loading workout sessions: \(error.localizedDescription)")
            }
        }
    }
} 
