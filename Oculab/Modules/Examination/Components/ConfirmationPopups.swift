//
//  ConfirmationPopups.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct ConfirmationPopups: View {
    @Binding var isVerifPopUpVisible: Bool
    @Binding var isLeavePopUpVisible: Bool
    var presenter: AnalysisResultPresenter

    var body: some View {
        VStack {
            AppPopup(
                image: "Confirm-Leave",
                title: "Pemeriksaan Belum Selesai",
                description: "Pemeriksaan disimpan sebagai draft dan dapat diakses di halaman riwayat",
                buttons: [
                    AppButton(title: "Keluar", colorType: .destructive(.primary)) {
                        presenter.popToRoot()
                    },
                    AppButton(title: "Periksa Kembali", colorType: .destructive(.secondary)) {
                        isLeavePopUpVisible = false
                    }
                ],
                isVisible: $isLeavePopUpVisible
            )

            AppPopup(
                image: "Confirm",
                title: "Simpan Hasil Pemeriksaan",
                description: "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali",
                buttons: [
                    AppButton(title: "Simpan", colorType: .primary) {
                        print("Simpan Tapped")
                    },
                    AppButton(title: "Periksa Kembali", colorType: .tertiary) {
                        isVerifPopUpVisible = false
                    }
                ],
                isVisible: $isVerifPopUpVisible
            )
        }
    }
}

#Preview {
    ConfirmationPopups(
        isVerifPopUpVisible: .constant(false),
        isLeavePopUpVisible: .constant(true),
        presenter: AnalysisResultPresenter()
    )
}
