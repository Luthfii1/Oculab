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
                image: AppText.Icon.confirmLeave,
                title: AppText.Examination.ConfirmationPopupsComponent.unfinishedExaminationTitle,
                description: AppText.Examination.ConfirmationPopupsComponent.unfinishedExaminationDescription,
                buttons: [
                    AppButton(title: AppText.Examination.ConfirmationPopupsComponent.exitButton, colorType: .destructive(.primary)) {
                        presenter.popToRoot()
                    },
                    AppButton(title: AppText.Examination.ConfirmationPopupsComponent.reviewAgainButton, colorType: .destructive(.secondary)) {
                        presenter.isLeavePopUpVisible = false
                    }
                ],
                isVisible: $presenter.isLeavePopUpVisible
            )

            AppPopup(
                image: AppText.Icon.confirm,
                title: AppText.Examination.ConfirmationPopupsComponent.saveResultTitle,
                description: AppText.Examination.ConfirmationPopupsComponent.saveResultDescription,
                buttons: [
                    AppButton(title: AppText.Examination.ConfirmationPopupsComponent.saveButton, colorType: .primary) {
                        Task {
                            await presenter.submitExpertResult(examinationId: examinationId)
                        }
                    },
                    AppButton(title: AppText.Examination.ConfirmationPopupsComponent.reviewAgainButton, colorType: .tertiary) {
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
