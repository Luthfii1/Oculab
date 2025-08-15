//
//  DateFormatterHelper.swift
//  Oculab
//
//  Created by GitHub Copilot on 11/08/25.
//

import Foundation

/// Centralized date formatting helper that ensures consistent localization across the app
struct DateFormatterHelper {
    
    // MARK: - Private Properties
    private static var _current = DateFormatterHelper()
    
    // MARK: - Public Properties
    static var shared: DateFormatterHelper {
        return _current
    }
    
    // MARK: - Formatters
    
    /// Returns a DateFormatter with current locale for consistent localization
    private func createFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current // Always use current locale for localization
        formatter.dateFormat = format
        return formatter
    }
    
    // MARK: - Public Methods
    
    /// Format date as "dd/MM/yyyy" with current locale
    func formatDDMMYYYY(_ date: Date) -> String {
        return createFormatter(format: "dd/MM/yyyy").string(from: date)
    }
    
    /// Format date as "dd MMM yyyy" with current locale (e.g., "15 Jan 2025" or "15 Jan 2025")
    func formatDayMonthYear(_ date: Date) -> String {
        return createFormatter(format: "dd MMM yyyy").string(from: date)
    }
    
    /// Format date as "dd MMMM yyyy" with current locale (e.g., "15 January 2025" or "15 Januari 2025")
    func formatDayFullMonthYear(_ date: Date) -> String {
        return createFormatter(format: "dd MMMM yyyy").string(from: date)
    }
    
    /// Format date and time as "dd MMM yyyy HH:mm" with current locale
    func formatDayMonthYearTime(_ date: Date) -> String {
        return createFormatter(format: "dd MMM yyyy HH:mm").string(from: date)
    }
    
    /// Format date and time as "dd MMMM yyyy HH:mm" with current locale
    func formatDayFullMonthYearTime(_ date: Date) -> String {
        return createFormatter(format: "dd MMMM yyyy HH:mm").string(from: date)
    }
    
    /// Format month and year as "MMMM yyyy" with current locale (e.g., "January 2025" or "Januari 2025")
    func formatMonthYear(_ date: Date) -> String {
        return createFormatter(format: "MMMM yyyy").string(from: date)
    }
    
    /// Convert ISO8601 date string to "dd/MM/yy" format with current locale
    func formatISO8601ToShortDate(_ isoDateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: isoDateString) {
            return createFormatter(format: "dd/MM/yy").string(from: date)
        } else {
            return "Invalid Date"
        }
    }
    
    /// Convert ISO8601 date string to "dd/MM/yyyy" format with current locale
    func formatISO8601ToDate(_ isoDateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: isoDateString) {
            return formatDDMMYYYY(date)
        } else {
            return "Invalid Date"
        }
    }
    
    /// Format Date to ISO8601 string format for API requests
    func formatToISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
