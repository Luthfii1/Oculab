//
//  FOVDetailInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/06/25.
//

import Foundation

class FOVDetailInteractor {
    private func createGetURL(with fovId: String) -> String {
        let fovURL = API.BE + "/boundingBox/get-bounding-box-data/"
        return fovURL + fovId.lowercased()
    }

    private func createUpdateURL(with boxId: String) -> String {
        let boxURL = API.BE + "/boundingBox/update-box-status/"
        return boxURL + boxId.lowercased()
    }

    func fetchData(fovId: String) async throws -> FOVDetailData {
        //        try await debugFetchData(fovId: fovId)

        let response: APIResponse<FOVDetailData> = try await NetworkHelper.shared
            .get(urlString: createGetURL(with: fovId))

        return response.data
    }

    func debugFetchData(fovId: String) async throws {
        let urlString = createGetURL(with: fovId)
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        if let rawString = String(data: data, encoding: .utf8) {
            print("Raw JSON response: \(rawString)")
        }

        let decoded = try JSONDecoder().decode(APIResponse<FOVDetailData>.self, from: data)
        print("Decoded response: \(decoded)")
    }

    func updateData(boxId: String, newStatus: String) async throws
        -> APIResponse<BoxModel>
    {
        let body = StatusBody(boxStatus: newStatus)

        let url = createUpdateURL(with: boxId)
//        print("[DEBUG] URL: \(url)")
//        print("[DEBUG] Request body: \(body)")

        do {
            let response: APIResponse<BoxModel> = try await NetworkHelper.shared.put(urlString: url, body: body)
//            print("[DEBUG] Response status: \(response.status)")
//            print("[DEBUG] Response message: \(response.message)")
//            print("[DEBUG] Response code: \(response.code)")

            return response
        } catch {
//            print("[DEBUG] Error updating data: \(error)")
            throw error
        }
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
