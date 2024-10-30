//
//  AppFileInput.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppFileInput: View {
    let videoPresenter = VideoRecordPresenter.shared
    @EnvironmentObject var examPresenter: ExamDataPresenter

    var title: String
    var isRequired: Bool
    var isEmpty: Bool

//    @State var selectedFileName: String = ""
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
                        examPresenter.newVideoRecord()
                    }
                } else {
                    // Display a preview for the video URL or an image placeholder if needed
                    Text("Video Selected: \(selectedURL!.lastPathComponent)") // Display the file name
                        .font(.caption)
                        .foregroundColor(AppColors.slate900)
                        .padding(2)

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
        // Implement preview functionality here
        print("Preview video at URL: \(selectedURL?.absoluteString ?? "No URL")")
    }
}

// #Preview {
//    @State var fileName = "Instruction"
//
//    VStack {
//        AppFileInput(
//            title: "Upload Document",
//            isRequired: true,
//            isEmpty: true
//        )
//
//        AppFileInput(
//            title: "Profile Picture",
//            isRequired: false,
//            isEmpty: false,
//            selectedFileName: fileName
//        )
//    }
// }
