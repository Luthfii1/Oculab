//
//  VideoInteractor.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 30/10/24.
//

import Foundation
import UIKit
import CoreImage

class VideoInteractor {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = AlamofireNetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Network Operations
    func forwardVideoToBackend(
        examinationId: String,
        video: VideoForward
    ) async throws -> VideoForwardResponse {
        Logger.info("Forwarding video to backend for examination: \(examinationId)", category: .videoRecord)
        
        let urlString = API.BE + "/examination/forward-video-to-ml/"

        let response: APIResponse<VideoForwardResponse> = try await networkService.post(
            urlString: urlString,
            headers: nil,
            body: video
        )
        
        Logger.info("Video forwarded successfully", category: .videoRecord)
        return response.data
    }

    // MARK: - Image Processing
    func processStitchedImage(
        previousImage: CIImage,
        currentImage: CIImage
    ) -> UIImage? {
        let context = CIContext()
        
        // Basic image compositing - can be enhanced with more sophisticated algorithms
        let compositeImage = currentImage.composited(over: previousImage)
        
        guard let cgImage = context.createCGImage(compositeImage, from: compositeImage.extent) else {
            Logger.error("Failed to create CGImage from composite", category: .videoRecord)
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Video Processing
    func validateVideoFormat(at url: URL) -> Bool {
        let supportedFormats = ["mov", "mp4", "m4v"]
        let fileExtension = url.pathExtension.lowercased()
        return supportedFormats.contains(fileExtension)
    }
    
    func getVideoMetadata(at url: URL) -> VideoMetadata? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            Logger.warning("Video file does not exist at path: \(url.path)", category: .videoRecord)
            return nil
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            return VideoMetadata(
                url: url,
                fileSize: fileSize,
                fileName: url.lastPathComponent,
                creationDate: attributes[.creationDate] as? Date ?? Date()
            )
        } catch {
            Logger.error("Failed to get video metadata: \(error.localizedDescription)", category: .videoRecord)
            return nil
        }
    }
}

// MARK: - Data Models
struct VideoForward: Encodable {
    let examinationId: String
    let videoURL: URL
    let metadata: VideoMetadata?
    
    enum CodingKeys: String, CodingKey {
        case examinationId
        case videoURL = "video_url"
        case metadata
    }
}

struct VideoForwardResponse: Decodable {
    let message: String?
    let data: String?
    let processingId: String?
    let status: ProcessingStatus
    
    enum ProcessingStatus: String, Decodable {
        case queued
        case processing
        case completed
        case failed
    }
}

struct VideoMetadata: Codable {
    let url: URL
    let fileSize: Int64
    let fileName: String
    let creationDate: Date
    let duration: TimeInterval?
    let resolution: CGSize?
    
    init(url: URL, fileSize: Int64, fileName: String, creationDate: Date, duration: TimeInterval? = nil, resolution: CGSize? = nil) {
        self.url = url
        self.fileSize = fileSize
        self.fileName = fileName
        self.creationDate = creationDate
        self.duration = duration
        self.resolution = resolution
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
