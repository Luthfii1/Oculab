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

    func verifyingFOV(fovId: UUID) async throws -> FOVData {
        let response: APIResponse<FOVData> = try await NetworkHelper.shared.update(
            urlString: endpoint + "/fov/update-verified-field/" + fovId.uuidString.toLowercase(),
            body: EmptyBody()
        )

        return response.data
    }

    func updateBoxStatus(boxId: String, newStatus: String) async throws -> APIResponse<BoxModel> {
        let body = StatusBody(boxStatus: newStatus)
        let url = endpoint + "/boundingBox/update-box-status/" + boxId.lowercased()
        
        let response: APIResponse<BoxModel> = try await NetworkHelper.shared.put(
            urlString: url,
            body: body
        )
        
        return response
    }

    func fetchData(fovId: UUID) async throws -> FOVDetailData {
        let fovURL = API.BE + "/boundingBox/get-bounding-box-data/"
        let url = fovURL + fovId.uuidString.toLowercase()
        
        print("URL: \(url)")

        let response: APIResponse<FOVDetailData> = try await NetworkHelper.shared
            .get(urlString: url)

        return response.data
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
