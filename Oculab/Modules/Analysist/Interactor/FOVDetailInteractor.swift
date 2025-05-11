//
//  FOVDetailInteractor.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//

import Foundation

struct EmptyBody: Encodable {}

class FOVDetailInteractor {
    private var endpoint = API.BE_VERCEL

    func verifyingFOV(fovId: UUID) async throws -> FOVData {
        let response: APIResponse<FOVData> = try await NetworkHelper.shared.update(
            urlString: endpoint + "/fov/update-verified-field/" + fovId.uuidString.toLowercase(),
            body: EmptyBody()
        )

        return response.data
    }
}
