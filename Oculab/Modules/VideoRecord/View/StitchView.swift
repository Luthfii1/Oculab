//
//  StitchView.swift
//  Oculab
//
//  Created by Muhammad Rasyad Caesarardhi on 01/11/24.
//

import SwiftUI

struct StitchedImageView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter.shared

    var body: some View {
        VStack {
            if let image = videoRecordPresenter.stitchedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .padding()
            } else {
                Text(AppTextVideoRecordStitched.noImageAvailableMessage)
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle(AppTextVideoRecordStitched.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview { StitchedImageView() }
