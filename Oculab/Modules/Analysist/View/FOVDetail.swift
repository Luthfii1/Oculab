//
//  FOVDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI
import UIKit

struct FOVDetail: View {
    var slideId: String
    var fovData: FOVData
    var order: Int
    var total: Int
    var examId: String?

    @StateObject private var presenter = FOVDetailPresenter()
    @StateObject private var albumPresenter = AnalysisResultPresenter()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if presenter.fovDetail != nil {
                    ZoomableImageComponent(
                        imageURL: URL(string: fovData.image),
                        zoomScale: $presenter.zoomScale,
                        offset: $presenter.offset
                    )
                    .environmentObject(presenter)
                    .edgesIgnoringSafeArea([.top, .bottom])
                } else {
                    // view with information that the data is loading because the data is not yet fetched
                    Text(AppTextAnalysisFOVDetail.loadingDataMessage)
                        .multilineTextAlignment(.center)
                        .font(AppTypography.h3)
                        .padding()
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea([.top, .bottom])
                }

                VStack(spacing: 0) {
                    // Top toolbar background
                    Color.black.opacity(0.4)
                        .frame(height: 100)
                        .edgesIgnoringSafeArea(.top)

                    Spacer()

                    // Bottom controls
                    VStack {
                        VStack(spacing: Decimal.d4) {
                            Text("\(AppTextAnalysisFOVDetail.bacteriaCountPrefix)\(fovData.systemCount)\(AppTextAnalysisFOVDetail.bacteriaCountSuffix)")
                                .font(AppTypography.h3)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, Decimal.d16)
                        .padding(.vertical, Decimal.d12)

                        HStack(spacing: Decimal.d16) {
                            Button(action: {
                                // Add contrast adjustment
                            }) {
                                Image(AppTextAnalysisFOVDetail.contrastIcon)
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                // Add brightness adjustment
                            }) {
                                Image(AppTextAnalysisFOVDetail.brightnessIcon)
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                // Add comment functionality
                            }) {
                                Image(AppTextAnalysisFOVDetail.commentIcon)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, Decimal.d16)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.4))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(" \(AppTextAnalysisFOVDetail.imageCountFormat) \(order + 1), \(total)")
                            .font(AppTypography.s4_1)
                            .foregroundColor(.white)
                        Text("\(AppTextAnalysisFOVDetail.slideIdPrefix) \(slideId)")
                            .font(AppTypography.p3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if let id = examId, !id.isEmpty {
                            Task {
                                await albumPresenter.submitTrackingDuration(examinationId: id)
                            }
                        }
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppTextAnalysisFOVDetail.backWhiteIcon)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                albumPresenter.setStartTime()

                Task {
                    await presenter.fetchData(fovId: fovData._id)
                    await presenter.verifyingFOV(fovId: fovData._id)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    FOVDetail(
        slideId: "A#EKNIR",
        fovData: FOVData(
            image: "https://is3.cloudhost.id/oculab-fov/oculab-fov/c5b14ad1-c15b-4d1c-bf2f-1dcf7fbf8d8d.png",
            type: .BTA1TO9,
            order: 1,
            systemCount: 12,
            confidenceLevel: 95.0
        ),
        order: 1,
        total: 10
    )
}
