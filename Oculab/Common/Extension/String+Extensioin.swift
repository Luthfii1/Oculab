//
//  String+Extensioin.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/11/24.
//

import Foundation

extension String {
    /// Converts an ISO8601 date string to the desired format `dd/MM/yy`.
    func toFormattedDate() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yy"

        if let date = isoFormatter.date(from: self) {
            return displayFormatter.string(from: date)
        } else {
            return "Invalid Date"
        }
    }

    func toFormattedDateYYYY() -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yyyy"

        if let date = isoFormatter.date(from: self) {
            return displayFormatter.string(from: date)
        } else {
            return "Invalid Date"
        }
    }
}
