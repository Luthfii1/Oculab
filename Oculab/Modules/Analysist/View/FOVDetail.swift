//
//  FOVDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI
import UIKit

struct FOVDetail: View {
    let slideId: String
    let fovs: [FOVData]
    let examId: String?

    @State private var currentIndex: Int
    @StateObject private var session: FOVDetailSession

    init(slideId: String, fovs: [FOVData], currentIndex: Int, examId: String?) {
        self.slideId = slideId
        self.fovs = fovs
        self.examId = examId
        self._currentIndex = State(initialValue: currentIndex)
        self._session = StateObject(wrappedValue: FOVDetailSession(examId: examId))
    }

    private var analysisPresenter: AnalysisResultPresenter? {
        guard let examId, !examId.isEmpty else { return nil }
        return AnalysisResultSessionStore.shared.presenter(for: examId)
    }

    var body: some View {
        FOVDetailChrome(
            slideId: slideId,
            fovs: fovs,
            currentIndex: $currentIndex,
            session: session,
            examId: examId,
            analysisPresenter: analysisPresenter
        ) {
            TabView(selection: $currentIndex) {
                ForEach(Array(fovs.enumerated()), id: \.element.id) { index, fov in
                    FOVDetailPageContent(
                        fovData: fov,
                        presenter: session.presenter(for: fov.id)
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            analysisPresenter?.setStartTime()
            let fovId = fovs[currentIndex].id
            Task {
                await session.load(fovId: fovId, markVerified: true)
                session.presenter(for: fovId).notifyValidationDataChanged()
            }
            session.prefetchAdjacent(fovs: fovs, around: currentIndex)
        }
        .onChange(of: currentIndex) { _, newIndex in
            session.clearSelection()
            let fovId = fovs[newIndex].id
            Task {
                await session.load(fovId: fovId, markVerified: true)
            }
            session.prefetchAdjacent(fovs: fovs, around: newIndex)
        }
        .onDisappear {
            session.finish()
        }
    }
}

private struct FOVDetailChrome<Content: View>: View {
    let slideId: String
    let fovs: [FOVData]
    @Binding var currentIndex: Int
    @ObservedObject var session: FOVDetailSession
    let examId: String?
    let analysisPresenter: AnalysisResultPresenter?
    @ViewBuilder let content: () -> Content

    private var currentFov: FOVData {
        fovs[currentIndex]
    }

    private var presenter: FOVDetailPresenter {
        session.presenter(for: currentFov.id)
    }

    var body: some View {
        content()
            .background(Color.black.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FOVDetailBottomControls(
                    presenter: presenter,
                    fovData: currentFov
                )
                .id(currentFov.id)
            }
            .navigationTitle(AppTextAnalysisFOVDetail.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: Decimal.d2) {
                        Text(AppData.imageCount(currentIndex + 1, fovs.count))
                            .font(AppTypography.s4_1)
                            .foregroundColor(.white)
                        Text(AppData.makeSentence([AppMedical.Examination.slideId, slideId]))
                            .font(AppTypography.p3)
                            .foregroundColor(.white.opacity(0.75))
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if let id = examId, !id.isEmpty, let analysisPresenter {
                            Task {
                                await analysisPresenter.submitTrackingDuration(examinationId: id)
                            }
                        }
                        Router.shared.navigateBack()
                    }) {
                        Image(AppImage.backWhite)
                            .foregroundColor(.white)
                    }
                }

                if fovs.count > 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: Decimal.d12) {
                            Button {
                                currentIndex = max(0, currentIndex - 1)
                            } label: {
                                Image(systemName: AppIcon.back)
                                    .foregroundColor(currentIndex > 0 ? .white : .white.opacity(0.35))
                            }
                            .disabled(currentIndex == 0)

                            Button {
                                currentIndex = min(fovs.count - 1, currentIndex + 1)
                            } label: {
                                Image(systemName: AppIcon.forward)
                                    .foregroundColor(
                                        currentIndex < fovs.count - 1 ? .white : .white.opacity(0.35)
                                    )
                            }
                            .disabled(currentIndex == fovs.count - 1)
                        }
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.55), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct FOVDetailPageContent: View {
    let fovData: FOVData
    @ObservedObject var presenter: FOVDetailPresenter

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZoomableImageComponent(
                imageURL: URL(string: fovData.imageOriginal),
                zoomScale: $presenter.zoomScale,
                offset: $presenter.offset
            )
            .environmentObject(presenter)
            .edgesIgnoringSafeArea([.top, .bottom])

            if presenter.isLoading, presenter.fovDetail == nil {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }

            if presenter.isError {
                errorOverlay
            } else if presenter.fovDetail != nil, !presenter.isBoundingBoxAvailable {
                boundingBoxUnavailableOverlay
            }
        }
    }

    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: AppIcon.warning)
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text(AppTextAnalysisFOVDetail.errorLoadingDataTitle)
                .font(AppTypography.h3)
                .foregroundColor(.white)

            Text(presenter.errorMessage ?? AppTextAnalysisFOVDetail.boundingBoxNotAvailableMessage)
                .multilineTextAlignment(.center)
                .font(AppTypography.p2)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 32)

            Button(AppTextAnalysisFOVDetail.retryButtonTitle) {
                Task { await presenter.fetchData(fovId: fovData.id) }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.65))
    }

    private var boundingBoxUnavailableOverlay: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: AppIcon.info)
                        .foregroundColor(.blue)
                    Text(AppTextAnalysisFOVDetail.processingInProgressTitle)
                        .font(AppTypography.p3)
                        .foregroundColor(.white)
                    Text(AppTextAnalysisFOVDetail.boundingBoxNotAvailableMessage)
                        .font(AppTypography.s4_1)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                Spacer()
            }

            Spacer()
                .frame(height: 140)
        }
    }
}

private struct FOVDetailBottomControls: View {
    @ObservedObject var presenter: FOVDetailPresenter
    let fovData: FOVData

    private var canStartSequentialReview: Bool {
        presenter.isBoundingBoxAvailable && presenter.remainingToVerifyCount > 0
    }

    private var canShowReviewRemaining: Bool {
        presenter.isBoundingBoxAvailable
            && presenter.remainingToVerifyCount > 0
            && presenter.reviewedCount > 0
    }

    var body: some View {
        VStack(spacing: Decimal.d8) {
            Text(
                AppData.makeSentence(
                    [AppMedical.Examination.bacteriaCount,
                     presenter.numberOfBacilli,
                     AppMedical.Examination.bacteriaCountSuffix]
                )
            )
            .font(AppTypography.h3)
            .foregroundColor(.white)

            if presenter.isLoading, presenter.fovDetail == nil {
                Text(AppTextAnalysisFOVDetail.loadingDataMessage)
                    .font(AppTypography.p3)
                    .foregroundColor(.white.opacity(0.7))
            } else if presenter.isBoundingBoxAvailable, presenter.remainingToVerifyCount > 0 {
                reviewActionsRow
            } else if presenter.isBoundingBoxAvailable, !presenter.boxes.isEmpty {
                Text(AppTextAnalysisFOVDetail.allBacteriaReviewedMessage)
                    .font(AppTypography.p3)
                    .foregroundColor(.green.opacity(0.9))
            }

            HStack(spacing: Decimal.d16) {
                Button(action: {
                    presenter.isBoundingBoxVisible.toggle()
                }) {
                    Image(systemName: presenter.boundingBoxIcon)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(presenter.backgroundColorBoxIcon)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(AppColors.purple500, lineWidth: presenter.lineWidthBoxIcon)
                        )
                }

                if presenter.enableAddBacilliFeature {
                    Button(action: {
                        presenter.isAddBacilliActive.toggle()
                    }) {
                        Image(systemName: AppIcon.add)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(presenter.backgroundColorAddBacilliIcon)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(AppColors.purple500, lineWidth: presenter.lineWidthAddBacilliIcon)
                            )
                    }
                }

                if !presenter.isBoundingBoxAvailable {
                    Button(action: {
                        Task {
                            await presenter.fetchData(fovId: fovData.id)
                            if presenter.isBoundingBoxAvailable {
                                await presenter.verifyingFOV(fovId: fovData.id)
                            }
                        }
                    }) {
                        Image(systemName: AppIcon.refresh)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, Decimal.d16)
            .padding(.vertical, Decimal.d8)
        }
        .padding(.top, Decimal.d12)
        .padding(.bottom, Decimal.d8)
        .frame(maxWidth: .infinity)
        .background {
            Color.black.opacity(0.55)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var reviewActionsRow: some View {
        HStack(spacing: Decimal.d8) {
            Text(
                AppTextAnalysisFOVDetail.pendingReviewFormat(presenter.remainingToVerifyCount)
            )
            .font(AppTypography.p3)
            .foregroundColor(.white.opacity(0.7))

            if canStartSequentialReview {
                Text("·")
                    .foregroundColor(.white.opacity(0.35))
                Button(action: {
                    presenter.startReviewFromFirst()
                }) {
                    Text(AppTextAnalysisFOVDetail.startFromFirstButton)
                        .font(AppTypography.p3)
                        .foregroundColor(AppColors.purple300)
                        .underline()
                }
            }

            if canShowReviewRemaining {
                Text("·")
                    .foregroundColor(.white.opacity(0.35))
                Button(action: {
                    presenter.jumpToNextRemaining()
                }) {
                    Text(AppTextAnalysisFOVDetail.reviewRemainingButton)
                        .font(AppTypography.p3)
                        .foregroundColor(.white.opacity(0.85))
                        .underline()
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}

#Preview {
    FOVDetail(
        slideId: "A#EKNIR",
        fovs: [
            FOVData(
                imageMLAnalyzed: "https://is3.cloudhost.id/oculab-fov/oculab-fov/248d6e1e-eab3-4981-8445-2174e16b7fdb.jpeg",
                imageOriginal: "https://is3.cloudhost.id/oculab-fov/oculab-fov/c5b14ad1-c15b-4d1c-bf2f-1dcf7fbf8d8d.png",
                type: .BTA1TO9,
                order: 1,
                systemCount: 12,
                confidenceLevel: 95.0
            ),
        ],
        currentIndex: 0,
        examId: nil
    )
}
