//
//  ExamListCacheService.swift
//  Oculab
//

import Foundation

struct CachedExamListPayload: Codable {
    let userId: String
    let roleRaw: String
    let cachedAt: Date
    let examinations: [ExaminationCardData]
}

final class ExamListCacheService {
    static let shared = ExamListCacheService()

    private let fileManager = FileManager.default
    private let cacheDirectoryName = "ExamListCache"

    private init() {}

    func save(examinations: [ExaminationCardData], userId: String, role: RolesType) {
        let payload = CachedExamListPayload(
            userId: userId,
            roleRaw: role.rawValue,
            cachedAt: .now,
            examinations: examinations
        )

        do {
            let url = try cacheFileURL(userId: userId, role: role)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {
            Logger.warning("Failed to save exam list cache: \(error.localizedDescription)", category: .general)
        }
    }

    func load(userId: String, role: RolesType) -> CachedExamListPayload? {
        do {
            let url = try cacheFileURL(userId: userId, role: role)
            guard fileManager.fileExists(atPath: url.path) else { return nil }
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(CachedExamListPayload.self, from: data)
            guard payload.userId == userId, payload.roleRaw == role.rawValue else { return nil }
            return payload
        } catch {
            Logger.warning("Failed to load exam list cache: \(error.localizedDescription)", category: .general)
            return nil
        }
    }

    func clearAll() {
        do {
            let directory = try cacheDirectoryURL()
            guard fileManager.fileExists(atPath: directory.path) else { return }
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            Logger.warning("Failed to clear exam list cache: \(error.localizedDescription)", category: .general)
        }
    }

    // MARK: - Private

    private func cacheDirectoryURL() throws -> URL {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent(cacheDirectoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func cacheFileURL(userId: String, role: RolesType) throws -> URL {
        let safeUserId = userId.lowercased().replacingOccurrences(of: "/", with: "_")
        return try cacheDirectoryURL()
            .appendingPathComponent("\(safeUserId)_\(role.rawValue).json")
    }
}
