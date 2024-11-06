//
//  VideoInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 30/10/24.
//

import Foundation
import UIKit

class VideoInteractor {
    func forwardVideotoBackend(
        examinationId: String,
        video: VideoForward,
        completion: @escaping (Result<VideoForwardResponse, NetworkErrorType>) -> Void
    ) {
        let urlString = API.BE + "/examination/forward-video-to-ml/"

        NetworkHelper.shared.post(urlString: urlString, body: video) { (result: Result<
            APIResponse<VideoForwardResponse>,
            NetworkErrorType
        >) in
            DispatchQueue.main.async {
                switch result {
                case let .success(apiResponse):
                    completion(.success(apiResponse.data))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
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
