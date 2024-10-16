//
//  AppFileInput.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppFileInput: View {
    var title: String
    var isRequired: Bool
    var isEmpty: Bool

    @State var selectedFileName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            // Title with optional 'Required' marker
            HStack(spacing: Decimal.d2) {
                Text(title)
                    .font(AppTypography.h4)
                    .foregroundColor(AppColors.slate900)

                if isRequired {
                    Text("*")
                        .font(AppTypography.h4)
                        .foregroundColor(.red)
                }
            }

            VStack(alignment: .center) {
                // File selection button
                if selectedFileName.isEmpty {
                    AppButton(title: "Ambil Gambar", leftIcon: "camera", colorType: .secondary, size: .small) {
                        selectFile()
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
                    )) // Dashed border if no file is selected
                    .foregroundColor(AppColors.slate100)
            )
        }
    }

    // Dummy function to simulate file selection
    private func selectFile() {
        // Simulate file selection for now
        selectedFileName = "sample_file.pdf" // Example file name
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
