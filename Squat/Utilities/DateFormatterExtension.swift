import Foundation

extension DateFormatter {
    /// Shared date formatter for displaying dates in UI
    static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Shared date formatter for displaying times in UI
    static let displayTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Shared date formatter for displaying full date and time in UI
    static let displayDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// Shared date formatter for file names (YYYY-MM-DD format)
    static let fileDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// Shared date formatter for ISO8601 dates (for API/JSON)
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Shared date formatter for CSV export date format
    static let csvDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    /// Formatter for showing full month, day, year (like "January 1, 2023")
    static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
}

// MARK: - Date Extension
extension Date {
    /// Format a date for display in the UI (medium date style, no time)
    var formattedDisplayDate: String {
        return DateFormatter.displayDate.string(from: self)
    }
    
    /// Format a date for display in the UI (no date, short time style)
    var formattedDisplayTime: String {
        return DateFormatter.displayTime.string(from: self)
    }
    
    /// Format a date for display in the UI (medium date style, short time style)
    var formattedDisplayDateTime: String {
        return DateFormatter.displayDateTime.string(from: self)
    }
    
    /// Format a date for file names (YYYY-MM-DD)
    var formattedFileDate: String {
        return DateFormatter.fileDate.string(from: self)
    }
    
    /// Format a date for JSON/API (ISO8601)
    var formattedISO8601: String {
        return DateFormatter.iso8601Full.string(from: self)
    }
    
    /// Format a date for CSV export
    var formattedCSVDateTime: String {
        return DateFormatter.csvDateTime.string(from: self)
    }
    
    /// Format a date in long style (January 1, 2023)
    var formattedLongDate: String {
        return DateFormatter.longDate.string(from: self)
    }
} 