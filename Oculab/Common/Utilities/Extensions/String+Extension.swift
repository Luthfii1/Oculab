//
//  String+Extension.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 17/11/24.
//

import Foundation

extension String {
    /// Converts an ISO8601 date string to the desired format `dd/MM/yy`.
    func toFormattedDate() -> String {
        return DateFormatterHelper.shared.formatISO8601ToShortDate(self)
    }

    func toFormattedDateYYYY() -> String {
        return DateFormatterHelper.shared.formatISO8601ToDate(self)
    }

    func toLowercase() -> String {
        return lowercased()
    }

    func toUppercase() -> String {
        return uppercased()
    }
}
