import Foundation
import UIKit

class CSVExporter {
    static let shared = CSVExporter()
    
    private init() {}
    
    /// Export workout sessions to a CSV file and share it
    /// - Parameters:
    ///   - workoutSessions: Array of workout sessions to export
    ///   - viewController: The view controller to present the share sheet from
    func exportWorkoutSessions(_ workoutSessions: [WorkoutSession], from viewController: UIViewController) {
        // Create CSV content
        let csvString = createCSVString(from: workoutSessions)
        
        // Create a temporary file
        let fileName = "Squat_Workout_History_\(formattedDate()).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            
            // Present the share sheet
            viewController.present(activityVC, animated: true)
        } catch {
            print("Error exporting CSV: \(error.localizedDescription)")
        }
    }
    
    /// Create CSV string from workout sessions
    /// - Parameter workoutSessions: Array of workout sessions
    /// - Returns: CSV formatted string
    private func createCSVString(from workoutSessions: [WorkoutSession]) -> String {
        // CSV header
        var csvString = "Date,Time,Duration,Repetitions,Calories Burned\n"
        
        // Add data rows
        for session in workoutSessions {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            let date = dateFormatter.string(from: session.date)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            let time = timeFormatter.string(from: session.date)
            
            let row = "\(date),\(time),\(session.formattedDuration),\(session.repCount),\(Int(session.caloriesBurned))\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
    /// Get formatted date for filename
    /// - Returns: Date string in format YYYY-MM-DD
    private func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension View {
    /// Export workout sessions to CSV and present a share sheet
    /// - Parameter workoutSessions: Array of workout sessions to export
    func exportToCSV(workoutSessions: [WorkoutSession]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        CSVExporter.shared.exportWorkoutSessions(workoutSessions, from: rootViewController)
    }
} 