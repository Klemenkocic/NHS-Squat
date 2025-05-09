import Foundation
import UIKit
import SwiftUI

/// WorkoutExporter provides functionality to export workout data in various formats
class WorkoutExporter {
    static let shared = WorkoutExporter()
    
    enum ExportFormat {
        case csv
        case json
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
        
        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            }
        }
    }
    
    private init() {}
    
    /// Export workout sessions to a file and share it
    /// - Parameters:
    ///   - workoutSessions: Array of workout sessions to export
    ///   - format: Format to export (CSV or JSON)
    ///   - viewController: The view controller to present the share sheet from
    func exportWorkoutSessions(
        _ workoutSessions: [WorkoutSession],
        format: ExportFormat = .csv,
        from viewController: UIViewController
    ) {
        // Generate file name with current date
        let fileName = "Squat_Workout_History_\(Date().formattedFileDate).\(format.fileExtension)"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // Generate content based on format
            let data: Data
            switch format {
            case .csv:
                let csvString = createCSVString(from: workoutSessions)
                data = csvString.data(using: .utf8) ?? Data()
            case .json:
                data = try createJSONData(from: workoutSessions)
            }
            
            try data.write(to: path)
            
            // Share the file
            let activityVC = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            
            // Present the share sheet
            viewController.present(activityVC, animated: true)
        } catch {
            print("Error exporting workout data: \(error.localizedDescription)")
        }
    }
    
    /// Create CSV string from workout sessions
    /// - Parameter workoutSessions: Array of workout sessions
    /// - Returns: CSV formatted string
    private func createCSVString(from workoutSessions: [WorkoutSession]) -> String {
        // CSV header
        var csvString = "ID,Date,Duration,Repetitions,Calories Burned,Notes\n"
        
        // Add data rows
        for session in workoutSessions {
            let dateString = session.date.formattedCSVDateTime
            let durationString = session.formattedDuration
            let notesString = "" // Add notes field if WorkoutSession is updated to include it
            
            let row = "\(session.id.uuidString),\(dateString),\(durationString),\(session.repCount),\(Int(session.caloriesBurned)),\(notesString)\n"
            csvString.append(row)
        }
        
        return csvString
    }
    
    /// Create JSON data from workout sessions
    /// - Parameter workoutSessions: Array of workout sessions
    /// - Returns: JSON formatted data
    private func createJSONData(from workoutSessions: [WorkoutSession]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(workoutSessions)
    }
}

// MARK: - SwiftUI Integration
extension View {
    /// Export workout sessions and present a share sheet
    /// - Parameters:
    ///   - workoutSessions: Array of workout sessions to export
    ///   - format: Format to export (CSV or JSON)
    func exportWorkoutData(
        workoutSessions: [WorkoutSession],
        format: WorkoutExporter.ExportFormat = .csv
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        WorkoutExporter.shared.exportWorkoutSessions(
            workoutSessions,
            format: format,
            from: rootViewController
        )
    }
} 