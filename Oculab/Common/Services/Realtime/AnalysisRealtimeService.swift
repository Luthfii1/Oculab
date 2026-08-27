//
//  AnalysisRealtimeService.swift
//  Oculab
//

import Foundation
import SocketIO

@MainActor
final class AnalysisRealtimeService {
    static let shared = AnalysisRealtimeService()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var subscribedExaminationIds = Set<String>()
    private var isConnecting = false

    private init() {}

    func subscribe(to examinationId: String) {
        let normalizedId = examinationId.lowercased()
        subscribedExaminationIds.insert(normalizedId)
        connectIfNeeded()
        socket?.emit("join", normalizedId)
        Logger.info("Subscribed to analysis updates for \(normalizedId)", category: .examination)
    }

    func unsubscribe(from examinationId: String) {
        subscribedExaminationIds.remove(examinationId.lowercased())
        if subscribedExaminationIds.isEmpty {
            disconnect()
        }
    }

    func connectIfNeeded() {
        guard socket == nil, !isConnecting else { return }
        isConnecting = true

        var config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .forceWebsockets(true),
        ]

        if let token = KeychainHelper.string(for: .accessToken) {
            config.insert(.auth(["token": token]))
            config.insert(.extraHeaders(["Authorization": "Bearer \(token)"]))
        }

        manager = SocketManager(
            socketURL: API.socketURL,
            config: config
        )
        let client = manager?.defaultSocket
        socket = client

        client?.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                self.isConnecting = false
                Logger.info("Analysis socket connected", category: .examination)
                for examId in self.subscribedExaminationIds {
                    self.socket?.emit("join", examId)
                }
            }
        }

        client?.on(clientEvent: .disconnect) { _, _ in
            Logger.info("Analysis socket disconnected", category: .examination)
        }

        client?.on(clientEvent: .error) { data, _ in
            Logger.error("Analysis socket error: \(data)", category: .examination)
        }

        client?.on("analysis:update") { [weak self] data, _ in
            guard let self, let update = Self.parseUpdate(from: data) else { return }
            Task { @MainActor in
                self.handle(update: update)
            }
        }

        client?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnecting = false
    }

    private func handle(update: AnalysisProgressUpdate) {
        NotificationCenter.default.post(
            name: .examinationAnalysisProgress,
            object: nil,
            userInfo: ["update": update]
        )

        if update.isReadyForValidation, AnalysisTrackingStore.isTracked(update.examId) {
            AnalysisTrackingStore.untrack(examinationId: update.examId)
            unsubscribe(from: update.examId)
            ExaminationNotificationService.shared.notifyAnalysisReady(examinationId: update.examId)
        }

        if update.isFailed, AnalysisTrackingStore.isTracked(update.examId) {
            AnalysisTrackingStore.untrack(examinationId: update.examId)
            unsubscribe(from: update.examId)
        }
    }

    private static func parseUpdate(from payload: [Any]) -> AnalysisProgressUpdate? {
        guard let first = payload.first else { return nil }

        if let dict = first as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict),
           let update = try? JSONDecoder().decode(AnalysisProgressUpdate.self, from: data) {
            return update
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let array = try? JSONDecoder().decode([AnalysisProgressUpdate].self, from: jsonData),
           let firstUpdate = array.first {
            return firstUpdate
        }

        return nil
    }
}
