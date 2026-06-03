//
//  FOVAlbum.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI

struct FOVAlbum: View {
    var fovGroup: FOVType
    @StateObject private var presenter = AnalysisResultPresenter()
    var examId: String

    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d24)

                LazyVGrid(columns: presenter.columnsFOVAlbum, spacing: AppConstants.fovGridSpacing) {
                    ForEach(Array(presenter.selectedFOVs(for: fovGroup).enumerated()), id: \.element.id) { index, fov in
                        Button {
                            presenter.navigateToDetailed(fovData: fov, order: index, total: presenter.selectedFOVs(for: fovGroup).count, examId: examId)
                        } label: {
                            RetryableImageView(
                                imageURL: fov.imageOriginal,
                                size: AppConstants.fovThumbnailSize,
                                cornerRadius: AppConstants.fovCornerRadius,
                                borderColor: fov.verified ? Color.green : Color.clear,
                                borderWidth: AppConstants.fovBorderWidth
                            )
                                .overlay(
                                    Group {
                                        if fov.verified {
                                            Image(systemName: AppIcon.success)
                                                .foregroundColor(.green)
                                                .font(.system(size: AppConstants.fovSuccessIconSize))
                                                .padding(AppConstants.fovSuccessIconPadding)
                                        }
                                    },
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle(AppTextAnalysisFOVAlbum.navigationTitleFormat(fovGroup.rawValue))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppImage.back)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await presenter.fetchData(examinationId: examId)
                }
            }
            .loadingOverlay(presenter.isLoading, message: AppState.loading)
        }
        .navigationBarBackButtonHidden()
    }
}

//#Preview {
//    FOVAlbum(fovGroup: .BTA1TO9, examId: "f58d4d5c-b591-45c3-9e4e-080b1b11dd4a")
//}
