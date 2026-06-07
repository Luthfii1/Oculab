//
//  FOVAlbum.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI

struct FOVAlbum: View {
    var fovGroup: FOVType
    var examId: String

    @ObservedObject private var presenter: AnalysisResultPresenter

    init(fovGroup: FOVType, examId: String) {
        self.fovGroup = fovGroup
        self.examId = examId
        let resolved = AnalysisResultSessionStore.shared.presenter(for: examId)
            ?? AnalysisResultPresenter()
        self._presenter = ObservedObject(wrappedValue: resolved)
    }

    private var usesSharedPresenter: Bool {
        AnalysisResultSessionStore.shared.presenter(for: examId) != nil
    }

    var body: some View {
        ScrollView {
            Spacer().frame(height: Decimal.d24)

            LazyVGrid(columns: presenter.columnsFOVAlbum, spacing: AppConstants.fovGridSpacing) {
                ForEach(Array(presenter.selectedFOVs(for: fovGroup).enumerated()), id: \.element.id) { index, fov in
                    Button {
                        presenter.navigateToDetailed(
                            fovData: fov,
                            order: index,
                            total: presenter.selectedFOVs(for: fovGroup).count,
                            examId: examId,
                            fovGroup: fovGroup
                        )
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
                    Image(AppImage.back)
                }
            }
        }
        .onAppear {
            guard !usesSharedPresenter else { return }
            Task {
                await presenter.fetchData(examinationId: examId)
            }
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .fovVerificationUpdated,
                object: nil,
                userInfo: ["examId": examId]
            )
        }
        .loadingOverlay(presenter.isLoading && !usesSharedPresenter, message: AppState.loading)
        .navigationBarBackButtonHidden(true)
    }
}
