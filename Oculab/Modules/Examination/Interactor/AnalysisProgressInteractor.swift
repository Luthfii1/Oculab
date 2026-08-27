//
//  AnalysisProgressInteractor.swift
//  Oculab
//

import Foundation

final class AnalysisProgressInteractor {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }

    func fetchProgress(examinationId: String) async -> AnalysisProgressUpdate? {
        let url = API.analysisProgressPath + examinationId.lowercased()
        guard let response: APIResponse<AnalysisProgressUpdate> = try? await networkService.get(
            urlString: url,
            headers: nil
        ) else {
            return nil
        }
        return response.data
    }
}
