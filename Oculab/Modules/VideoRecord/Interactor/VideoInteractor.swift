//
//  VideoInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 30/10/24.
//

import Foundation
import UIKit

class VideoInteractor {
    private let networkService: NetworkService

    init(networkService: NetworkService = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    func forwardVideotoBackend(
        examinationId: String,
        video: VideoForward
    ) async throws -> VideoForwardResponse {
        let urlString = API.BE + "/examination/forward-video-to-ml/"

        let response: APIResponse<VideoForwardResponse> = try await networkService.post(
            urlString: urlString,
            headers: nil,
            body: video
        )
        return response.data
    }

    func getStitchedImage(
        previousImage: CIImage,
        currentImage: CIImage
    ) -> UIImage {
        return UIImage()
    }
}

struct VideoForward: Encodable {
    var previewURL: URL?
}

struct VideoForwardResponse: Decodable {
    var message: String?
    var data: String?
}
