//
//  MediaURLResolver.swift
//  Oculab
//

import Foundation

enum MediaURLResolver {
    private static let internalHostMarkers = ["rustfs-server", "localhost", "127.0.0.1"]

    static func resolve(_ urlString: String) -> String {
        guard !urlString.isEmpty else { return urlString }

        if isInternalAssetURL(urlString),
           let objectKey = extractObjectKey(from: urlString) {
            return authenticatedMediaURL(objectKey: objectKey)
        }

        // BE may already rewrite to /fov/media/<key> — still need a query token for AsyncImage.
        if urlString.contains("/fov/media/") {
            return appendAccessTokenIfNeeded(to: urlString)
        }

        return urlString
    }

    static func resolveURL(_ urlString: String) -> URL? {
        URL(string: resolve(urlString))
    }

    /// FOV media requires auth; AsyncImage cannot set headers, so append access_token.
    private static func authenticatedMediaURL(objectKey: String) -> String {
        appendAccessTokenIfNeeded(to: "\(API.BE)/fov/media/\(objectKey)")
    }

    private static func appendAccessTokenIfNeeded(to urlString: String) -> String {
        guard let token = KeychainHelper.string(for: .accessToken),
              var components = URLComponents(string: urlString)
        else {
            return urlString
        }

        var items = components.queryItems ?? []
        items.removeAll { $0.name == "access_token" }
        items.append(URLQueryItem(name: "access_token", value: token))
        components.queryItems = items
        return components.url?.absoluteString ?? urlString
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
