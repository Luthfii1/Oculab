//
//  AppPopup.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppPopup: View {
    var image: String?
    var title: String
    var description: String?
    var buttons: [AppButton]

    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            VStack {
                Spacer()

                VStack(spacing: Decimal.d24) {
                    VStack(spacing: Decimal.d8) {
                        // Optional image at the top
                        if let image = image {
                            Image(image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(AppColors.slate900)
                        }

                        // Title
                        Text(title)
                            .font(AppTypography.h3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppColors.slate900)

                        // Optional description
                        if let description = description {
                            Text(description)
                                .font(AppTypography.p2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.slate600)
                        }
                    }.padding(.top, Decimal.d32)

                    VStack(spacing: Decimal.d16) {
                        ForEach(buttons) { button in
                            button
                        }
                    }.padding(.bottom, Decimal.d32)
                }
                .padding(.horizontal, Decimal.d24)
                .background(AppColors.slate0)
                .cornerRadius(Decimal.d12)
                .shadow(radius: 20)
                .padding(.horizontal, Decimal.d20)

                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .zIndex(2)
        }
    }
}

#Preview {
    @Previewable @State var isVisible = true

    VStack {
        Button("Show Popup") {
            isVisible = true
        }

        AppPopup(
            image: "Confirm", // SF Symbol
            title: "Simpan Hasil Pemeriksaan",
            description: "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali",
            buttons: [
                AppButton(
                    title: "Simpan",
                    colorType: .primary,
                    size: .large,
                    isEnabled: true
                ) {
                    print("Simpan Tapped")
                },

                AppButton(
                    title: "Periksa Kembali",
                    colorType: .tertiary,
                    isEnabled: true
                ) {
                    print("Periksa Kembali Tapped")
                }
            ],
            isVisible: $isVisible
        )
    }
}
