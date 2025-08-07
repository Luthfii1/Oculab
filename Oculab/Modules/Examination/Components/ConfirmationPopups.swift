//
//  ConfirmationPopups.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct ConfirmationPopups: View {
    @EnvironmentObject var presenter: AnalysisResultPresenter
    @State var examinationId: String

    var body: some View {
        VStack {
            AppPopup(
                image: AppImage.confirmLeave,
                title: AppTextExamCompConfirmPopups.unfinishedExaminationTitle,
                description: AppTextExamCompConfirmPopups.unfinishedExaminationDescription,
                buttons: [
                    AppButton(title: AppAction.exit, colorType: .destructive(.primary)) {
                        presenter.popToRoot()
                    },
                    AppButton(title: "Periksa Kembali", colorType: .destructive(.secondary)) {
                        presenter.isLeavePopUpVisible = false
                    }
                ],
                isVisible: $presenter.isLeavePopUpVisible
            )

            AppPopup(
                image: AppImage.confirm,
                title: AppAction.save("Hasil Pemeriksaan"),
                description: AppTextExamCompConfirmPopups.saveResultDescription,
                buttons: [
                    AppButton(title: AppAction.save, colorType: .primary) {
                        Task {
                            await presenter.submitExpertResult(examinationId: examinationId)
                        }
                    },
                    AppButton(title: "Periksa Kembali", colorType: .tertiary) {
                        presenter.isVerifPopUpVisible = false
                    }
                ],
                isVisible: $presenter.isVerifPopUpVisible
            )
        }
    }
}

#Preview {
    ConfirmationPopups(examinationId: "jalo")
        .environmentObject(AnalysisResultPresenter())
}
