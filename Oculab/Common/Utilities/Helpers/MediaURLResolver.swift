//
//  MediaURLResolver.swift
//  Oculab
//

import Foundation

enum MediaURLResolver {
    private static let internalHostMarkers = ["rustfs-server", "localhost", "127.0.0.1"]
    static func resolve(_ urlString: String) -> String {
        guard !urlString.isEmpty else { return urlString }
        guard isInternalAssetURL(urlString) else { return urlString }
        guard let objectKey = extractObjectKey(from: urlString) else { return urlString }
        return "\(publicAssetBaseURL)/\(objectKey)"
    }

    static func resolveURL(_ urlString: String) -> URL? {
        URL(string: resolve(urlString))
    }

    private static var publicAssetBaseURL: String {
        "\(API.BE)/fov/media"
    }

    private static func isInternalAssetURL(_ urlString: String) -> Bool {
        guard urlString.hasPrefix("http://") else { return false }
        return internalHostMarkers.contains { urlString.localizedCaseInsensitiveContains($0) }
    }

    private static func extractObjectKey(from urlString: String) -> String? {
        guard let range = urlString.range(of: "/oculab-fov/", options: .caseInsensitive) else {
            return nil
        }
        let objectKey = String(urlString[range.upperBound...])
        return objectKey.isEmpty ? nil : objectKey
    }
}
