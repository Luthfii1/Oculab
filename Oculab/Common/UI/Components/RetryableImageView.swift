//
//  RetryableImageView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 19/12/24.
//

import SwiftUI

struct RetryableImageView: View {
    let imageURL: String
    let size: CGFloat
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let placeholderImage: String?
    
    @State private var imageLoadingState: ImageLoadingState = .loading
    @State private var retryAttempts = 0
    
    enum ImageLoadingState {
        case loading
        case loaded
        case failed
    }
    
    private var resolvedImageURL: String {
        MediaURLResolver.resolve(imageURL)
    }

    init(
        imageURL: String,
        size: CGFloat,
        cornerRadius: CGFloat = AppConstants.fovCornerRadius,
        borderColor: Color = .clear,
        borderWidth: CGFloat = AppConstants.fovBorderWidth,
        placeholderImage: String? = nil
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.placeholderImage = placeholderImage
    }
    
    var body: some View {
        Group {
            switch imageLoadingState {
            case .loading:
                ProgressView()
                    .frame(width: size, height: size)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                
            case .loaded:
                AsyncImage(url: URL(string: resolvedImageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipped()
                    case .failure(_):
                        failureView
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                
            case .failed:
                failureView
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private var failureView: some View {
        VStack(spacing: 4) {
            if let placeholderImage = placeholderImage {
                Image(placeholderImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: AppIcon.warning)
                    .foregroundColor(.red)
                    .font(.system(size: size * 0.3))
                
                if retryAttempts < 3 {
                    Button(AppAction.retry) {
                        retryImageLoad()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .frame(width: size, height: size)
        .background(Color.gray.opacity(0.1))
    }
    
    private func loadImage() {
        guard retryAttempts < 3 else {
            imageLoadingState = .failed
            return
        }
        
        imageLoadingState = .loading
        
        guard let url = URL(string: resolvedImageURL) else {
            imageLoadingState = .failed
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if error != nil || data == nil {
                    if retryAttempts < 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            retryImageLoad()
                        }
                    } else {
                        imageLoadingState = .failed
                    }
                } else {
                    imageLoadingState = .loaded
                }
            }
        }.resume()
    }
    
    private func retryImageLoad() {
        retryAttempts += 1
        loadImage()
    }
}

#Preview {
    VStack(spacing: 20) {
        RetryableImageView(
            imageURL: "https://example.com/valid-image.jpg",
            size: 74,
            borderColor: .green,
            borderWidth: 2
        )
        
        RetryableImageView(
            imageURL: "https://invalid-url.com/image.jpg",
            size: 74,
            borderColor: .red,
            borderWidth: 2
        )
    }
    .padding()
}
