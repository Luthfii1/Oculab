import Foundation

/// Birth dates are calendar dates. Keep non-midnight legacy timestamps readable
/// until their original time zones can be audited; new requests use YYYY-MM-DD.
enum PatientBirthDateCoding {
    static func decode(_ value: String, calendar: Calendar = .current) -> Date? {
        if value.count == 10 { return civilDate(value, calendar: calendar) }
        guard let instant = decodeInstant(value) else { return nil }
        let utc = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: instant)
        if (value.hasSuffix("Z") || value.hasSuffix("+00:00")), utc.hour == 0 && utc.minute == 0 && utc.second == 0 && (utc.nanosecond ?? 0) == 0 {
            // Server date-only inputs are returned as UTC midnight. Interpret
            // that canonical representation as a date, even west of UTC.
            return civilDate(String(value.prefix(10)), calendar: calendar)
        }
        return instant
    }

    static func encode(_ date: Date, calendar: Calendar = .current) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    static func decodeInstant(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private static func civilDate(_ value: String, calendar: Calendar) -> Date? {
        guard value.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else { return nil }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)
        guard let date = gregorian.date(from: components) else { return nil }
        let roundTrip = gregorian.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == parts[0], roundTrip.month == parts[1], roundTrip.day == parts[2] else { return nil }
        return date
    }
}
