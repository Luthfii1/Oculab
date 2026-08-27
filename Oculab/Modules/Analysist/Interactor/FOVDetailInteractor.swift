//
//  FOVDetailInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//

import Foundation

struct EmptyBody: Encodable {}

class FOVDetailInteractor {
    private var endpoint = API.BE
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = DependencyInjection.shared.networkService) {
        self.networkService = networkService
    }

    func verifyingFOV(fovId: String) async throws -> FOVData {
        let response: APIResponse<FOVData> = try await networkService.update(
            urlString: endpoint + "/fov/update-verified-field/" + fovId.lowercased(),
            headers: nil,
            body: EmptyBody()
        )

        return response.data
    }

    func updateBoxStatus(boxId: String, newStatus: String) async throws -> APIResponse<BoxModel> {
        let body = StatusBody(boxStatus: newStatus)
        let url = endpoint + "/boundingBox/update-box-status/" + boxId.lowercased()
        
        let response: APIResponse<BoxModel> = try await networkService.update(
            urlString: url,
            headers: nil,
            body: body
        )
        
        return response
    }

    func fetchData(fovId: String) async throws -> FOVDetailData {
        let fovURL = API.BE + "/boundingBox/get-bounding-box-data/"
        let url = fovURL + fovId.lowercased()

        let response: APIResponse<FOVDetailData> = try await networkService
            .get(urlString: url, headers: nil)

        return response.data
    }
    
    func addBox(fovId: String, newBox: AddBoxRequest) async throws -> APIResponse<BoxModel> {
        let fovURL = API.BE + "/boundingBox/add-bounding-box/"
        let url = fovURL + fovId.lowercased()
        let body = newBox

        let response: APIResponse<BoxModel> = try await networkService.update(
            urlString: url,
            headers: nil,
            body: body
        )

        return response
    }
}

struct StatusBody: Codable {
    let boxStatus: String
}

struct FOVDetailData: Decodable {
    var frameWidth: Int
    var frameHeight: Int
    var boxes: [BoxModel]
}

struct AddBoxRequest: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
