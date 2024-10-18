//
//  AppFileInput.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppFileInput: View {
    @EnvironmentObject var examPresenter: ExamDataPresenter

    var title: String
    var isRequired: Bool
    var isEmpty: Bool

    @State var selectedFileName: String = ""

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
                if selectedFileName.isEmpty {
                    AppButton(title: "Ambil Gambar", leftIcon: "camera", colorType: .secondary, size: .small) {
                        selectFile()
                        examPresenter.newVideoRecord()
                    }
                } else {
                    Image(selectedFileName)
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: 250.0, alignment: .center)
                        .padding(2)
                    AppButton(title: "Preview Gambar", leftIcon: "eye", colorType: .secondary, size: .small) {}
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
                        dash: selectedFileName.isEmpty ? [10] : []
                    ))
                    .foregroundColor(AppColors.slate100)
            )
        }
    }

    private func selectFile() {
        selectedFileName = "sample_file.pdf"
    }
}

#Preview {
    @State var fileName = "Instruction"

    VStack {
        AppFileInput(
            title: "Upload Document",
            isRequired: true,
            isEmpty: true
        )

        AppFileInput(
            title: "Profile Picture",
            isRequired: false,
            isEmpty: false,
            selectedFileName: fileName
        )
    }
}
