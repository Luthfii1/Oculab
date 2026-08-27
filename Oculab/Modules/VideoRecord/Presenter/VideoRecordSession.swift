//
//  VideoRecordSession.swift
//  Oculab
//
//  Owns the active camera/recording presenter for one exam capture flow.
//  Call `beginNewSession()` when starting a fresh recording so capture
//  hardware and preview state do not leak across examinations.
//

import Foundation

@MainActor
enum VideoRecordSession {
    private(set) static var current = VideoRecordPresenter(interactor: VideoInteractor())

    /// Compatibility alias used by older call sites during migration.
    static var shared: VideoRecordPresenter { current }

    static func beginNewSession() {
        Task {
            await current.cleanup()
            current = VideoRecordPresenter(interactor: VideoInteractor())
        }
    }

    /// Synchronous reset for submit / leave flows that must drop the old presenter immediately.
    static func replaceSession() async {
        await current.cleanup()
        current = VideoRecordPresenter(interactor: VideoInteractor())
    }
}
