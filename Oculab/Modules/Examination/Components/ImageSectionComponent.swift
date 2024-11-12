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
                Image(systemName: "photo")
                    .foregroundColor(AppColors.purple500)
                Text("Hasil Gambar")
                    .font(AppTypography.s4_1)
                    .padding(.leading, Decimal.d8)
            }
            Text("Ketuk untuk lihat detail gambar")
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate300)

            AsyncImage(url: URL(
                string: examination
                    .imagePreview
            )) { phase in
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
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 114)
                        .foregroundColor(.red)
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(Decimal.d8)

            if !(presenter.groupedFOVs?.bta0.isEmpty ?? true) {
                // Checking if the `data` array within each group is not empty
                Button {
                    presenter.navigateToAlbum(fovGroup: .BTA0)
                } label: {
                    FolderCardComponent(
                        title: .BTA0,
                        numOfImage: presenter.groupedFOVs?.bta0.count ?? 0
                    )
                }
            }

            if !(presenter.groupedFOVs?.bta1to9.isEmpty ?? true) {
                // Checking if the `data` array within each group is not empty
                Button {
                    presenter.navigateToAlbum(fovGroup: .BTA1TO9)
                } label: {
                    FolderCardComponent(
                        title: .BTA1TO9,
                        numOfImage: presenter.groupedFOVs?.bta1to9.count ?? 0
                    )
                }
            }

            if !(presenter.groupedFOVs?.btaabove9.isEmpty ?? true) {
                // Checking if the `data` array within each group is not empty
                Button {
                    presenter.navigateToAlbum(fovGroup: .BTAABOVE9)
                } label: {
                    FolderCardComponent(
                        title: .BTAABOVE9,
                        numOfImage: presenter.groupedFOVs?.btaabove9.count ?? 0
                    )
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
