//
//  VideoThumbnailView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 18/08/25.
//

import SwiftUI
import AVFoundation

// MARK: - Video Thumbnail View
struct VideoThumbnailView: View {
    let url: URL
    var aspectRatio: CGFloat? = nil
    var contentMode: ContentMode = .fit
    @State private var thumbnailImage: UIImage?

    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                if let ratio = aspectRatio {
                    if contentMode == .fill {
                        GeometryReader { geo in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .aspectRatio(ratio, contentMode: .fill)
                                .clipped()
                        }
                    } else {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(ratio, contentMode: .fit)
                    }
                } else {
                    Image(uiImage: image)
                        .resizable()
                }
            } else {
                // Loading placeholder
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading preview...")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            let thumbnail = await createVideoThumbnail(from: url)
            await MainActor.run {
                if let t = thumbnail {
                    Logger.info("[THUMBNAIL] generated size: \(t.size)", category: .videoRecord)
                }
                self.thumbnailImage = thumbnail
            }
        }
    }
    
    private func createVideoThumbnail(from url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        do {
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            Logger.error("Failed to generate video thumbnail: \(error)", category: .videoRecord)
            return nil
        }
    }
}
