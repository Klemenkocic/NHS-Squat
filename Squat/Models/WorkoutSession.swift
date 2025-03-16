import Foundation

public struct WorkoutSession: Identifiable, Codable {
    public var id = UUID()
    public let date: Date
    public let duration: TimeInterval
    public let repCount: Int
    public let caloriesBurned: Double
    
    public init(date: Date, duration: TimeInterval, repCount: Int, caloriesBurned: Double) {
        self.date = date
        self.duration = duration
        self.repCount = repCount
        self.caloriesBurned = caloriesBurned
    }
    
    public init(id: UUID, date: Date, duration: TimeInterval, repCount: Int, caloriesBurned: Double) {
        self.id = id
        self.date = date
        self.duration = duration
        self.repCount = repCount
        self.caloriesBurned = caloriesBurned
    }
    
    // Formatted properties for display
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 