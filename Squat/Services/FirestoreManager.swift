import Foundation
import FirebaseFirestore
import FirebaseAuth

// Define FirestoreError enum
enum FirestoreError: Error {
    case userNotAuthenticated
    case documentNotFound
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .userNotAuthenticated:
            return "User is not signed in"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    private let workoutsCollection = "workouts"
    
    private init() {}
    
    // MARK: - Workout History Methods
    
    /// Save a workout session to Firestore
    /// - Parameters:
    ///   - session: The workout session to save
    ///   - completion: Callback with success/failure result
    func saveWorkoutSession(_ session: WorkoutSession, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        // Convert WorkoutSession to dictionary
        let sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "date": Timestamp(date: session.date),
            "duration": session.duration,
            "repCount": session.repCount,
            "caloriesBurned": session.caloriesBurned,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add to Firestore
        db.collection(workoutsCollection).document(session.id.uuidString).setData(sessionData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Get all workout sessions for the current user
    /// - Parameter completion: Callback with array of workout sessions or error
    func getAllWorkoutSessions(completion: @escaping (Result<[WorkoutSession], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        db.collection(workoutsCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let sessions = documents.compactMap { document -> WorkoutSession? in
                    let data = document.data()
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let timestamp = data["date"] as? Timestamp,
                          let duration = data["duration"] as? TimeInterval,
                          let repCount = data["repCount"] as? Int,
                          let caloriesBurned = data["caloriesBurned"] as? Double else {
                        return nil
                    }
                    
                    return WorkoutSession(
                        id: id,
                        date: timestamp.dateValue(),
                        duration: duration,
                        repCount: repCount,
                        caloriesBurned: caloriesBurned
                    )
                }
                
                completion(.success(sessions))
            }
    }
    
    /// Delete a workout session
    /// - Parameters:
    ///   - sessionId: ID of the session to delete
    ///   - completion: Callback with success/failure result
    func deleteWorkoutSession(sessionId: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        db.collection(workoutsCollection).document(sessionId.uuidString).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Delete all workout sessions for the current user
    /// - Parameter completion: Callback with success/failure result
    func clearAllWorkoutSessions(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(FirestoreError.userNotAuthenticated))
            return
        }
        
        // Get all documents for the user
        db.collection(workoutsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // No documents to delete
                    completion(.success(()))
                    return
                }
                
                // Create a batch to delete all documents
                let batch = self.db.batch()
                documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }
} 