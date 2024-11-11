//
//  VideoInput.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import AVKit
import SwiftUI

struct VideoInput: View {
    let videoPresenter = VideoRecordPresenter.shared
    @EnvironmentObject var examPresenter: ExamDataPresenter

    var title: String
    var isRequired: Bool
    var isEmpty: Bool

    @Binding var selectedURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack(spacing: Decimal.d2) {
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundColor(AppColors.slate900)

                if isRequired {
                    Text("*")
                        .font(AppTypography.h4)
                        .foregroundColor(.red)
                }
            }

            VStack(alignment: .center) {
                if selectedURL == nil {
                    AppButton(title: "Ambil Gambar", leftIcon: "camera", colorType: .secondary, size: .small) {
                        selectFile()
                        videoPresenter.previewURL = nil
                        examPresenter.newVideoRecord()
                    }
                } else {
                    VideoPlayer(player: AVPlayer(url: selectedURL!))
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(Decimal.d8)

                    AppButton(title: "Preview Video", leftIcon: "eye", colorType: .secondary, size: .small) {
                        previewVideo()
                    }
                }
            }
            .padding(.horizontal, Decimal.d16)
            .padding(.vertical, Decimal.d16)
            .frame(maxWidth: .infinity, minHeight: 250.0, alignment: .center)
            .cornerRadius(Decimal.d12)
            .overlay(
                RoundedRectangle(cornerRadius: Decimal.d12)
                    .stroke(style: StrokeStyle(
                        lineWidth: 2,
                        dash: selectedURL == nil ? [10] : []
                    ))
                    .foregroundColor(AppColors.slate100)
            )
        }
    }

    private func selectFile() {
        selectedURL = videoPresenter.previewURL
    }

    private func previewVideo() {
        print("Preview video at URL: \(selectedURL?.absoluteString ?? "No URL")")
    }
}
