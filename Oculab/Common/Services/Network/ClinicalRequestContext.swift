import Foundation

/// Carries the session that authorized a clinical operation across executor hops.
/// It constrains token resolution without freezing the token: a refresh within
/// the same session can still replace an expired access token.
enum ClinicalRequestContext {
    @TaskLocal static var expectedSession: UploadQueueSession?

    static func withSession<T>(_ session: UploadQueueSession, operation: () async throws -> T) async rethrows -> T {
        try await $expectedSession.withValue(session, operation: operation)
    }

    @MainActor
    static func requireCurrentSession(_ expected: UploadQueueSession?) throws {
        try Task.checkCancellation()
        if let expected, expected != AuthSessionManager.uploadQueueSession { throw CancellationError() }
    }
}
