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

            if presenter.isWSIImageVisible,
               !examination.imagePreview.isEmpty,
               let imageURL = URL(string: examination.imagePreview) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(height: 114)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 114)
                            .clipped()
                    case .failure:
                        Image(systemName: AppIcon.warning)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 114)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(Decimal.d8)
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
        }
        .padding(.horizontal, Decimal.d16)
        .padding(.vertical, Decimal.d16)
        .background(Color.white)
        .cornerRadius(Decimal.d12)
        .overlay(RoundedRectangle(cornerRadius: Decimal.d12).stroke(AppColors.slate100))
        .padding(.horizontal, Decimal.d20)
    }
}

// #Preview {
//    ImageSectionComponent()
// }
