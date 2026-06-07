//
//  ImageSectionComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct ImageSectionComponent: View {
    @ObservedObject var presenter: AnalysisResultPresenter
    var examination: ExaminationResultData

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d16) {
            HStack {
                Image(systemName: AppIcon.photo)
                    .foregroundColor(AppColors.purple500)
                Text(AppTextExam.titleResultImages)
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
            }

            Text(AppTextExamCompImageSection.imageResultInstruction)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate300)

            if presenter.hasFOVData {
                if !presenter.previewFOVs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(presenter.previewFOVs.enumerated()), id: \.offset) { _, fov in
                                RetryableImageView(
                                    imageURL: fov.imageOriginal,
                                    size: 72,
                                    cornerRadius: AppConstants.fovCornerRadius,
                                    borderColor: AppColors.slate100,
                                    borderWidth: 1
                                )
                            }
                        }
                    }
                }

                ForEach(presenter.availableFOVTypes, id: \.self) { fovType in
                    if let count = presenter.fovCount(for: fovType) {
                        Button {
                            presenter.navigateToAlbum(fovGroup: fovType)
                        } label: {
                            FolderCardComponent(
                                title: fovType,
                                numOfImage: count
                            )
                        }
                    }
                }
            } else if examination.statusExamination == .NEEDVALIDATION {
                HStack(alignment: .center, spacing: Decimal.d12) {
                    ProgressView()
                    Text(AppTextExamCompImageSection.loadingImagesMessage)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate400)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Decimal.d8)
            }
        }
        .padding(.horizontal, Decimal.d16)
        .padding(.vertical, Decimal.d16)
        .background(Color.white)
        .cornerRadius(Decimal.d12)
        .overlay(RoundedRectangle(cornerRadius: Decimal.d12).stroke(AppColors.slate100))
        .padding(.horizontal, Decimal.d20)
    }
}
