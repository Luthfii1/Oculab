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

                if presenter.isError {
                    // Error state
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
                        
                        // Show the image even if bounding box data is not available
                        if let imageURL = URL(string: fovData.imageOriginal) {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(8)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 300)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Button(AppTextAnalysisFOVDetail.retryButtonTitle) {
                            Task {
                                await presenter.fetchData(fovId: fovData._id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if presenter.fovDetail != nil {
                    ZoomableImageComponent(
                        imageURL: URL(string: fovData.imageOriginal),
                        zoomScale: $presenter.zoomScale,
                        offset: $presenter.offset
                    )
                    .environmentObject(presenter)
                    .edgesIgnoringSafeArea([.top, .bottom])
                    
                    // Show overlay message if bounding box data is not available
                    if !presenter.isBoundingBoxAvailable {
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
                                .frame(height: 140) // Account for bottom controls
                        }
                    }
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
                        Text(
                            AppData.makeSentence(
                                [AppMedical.Examination.bacteriaCount,
                                 presenter.numberOfBacilli,
                                 AppMedical.Examination.bacteriaCountSuffix]
                            )
                        )
                        .font(AppTypography.h3)
                        .foregroundColor(.white)
                        .padding(.vertical, Decimal.d8)

                        HStack(spacing: Decimal.d16) {
                            Button(action: {
                                presenter.isBoundingBoxVisible.toggle()
                            }) {
                                Image(systemName: presenter.boundingBoxIcon)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(
                                        presenter.backgroundColorBoxIcon
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(AppColors.purple500, lineWidth: presenter.lineWidthBoxIcon)
                                    )
                            }

//                            Button(action: {
//                                // Add brightness adjustment
//                            }) {
//                                Image(AppImage.brightness)
//                                    .foregroundColor(.white)
//                            }
//
//                            Button(action: {
//                                // Add comment functionality
//                            }) {
//                                Image(AppImage.comment)
//                                    .foregroundColor(.white)
//                            }
                            
                            // Add refresh button when bounding box data is not available
                            if !presenter.isBoundingBoxAvailable {
                                Button(action: {
                                    Task {
                                        await presenter.fetchData(fovId: fovData._id)
                                        if presenter.isBoundingBoxAvailable {
                                            await presenter.verifyingFOV(fovId: fovData._id)
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
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.4))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(AppData.imageCount(order + 1, total))
                            .font(AppTypography.s4_1)
                            .foregroundColor(.white)
                        Text(AppData.makeSentence([AppMedical.Examination.slideId, slideId]))
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
                            Image(AppImage.backWhite)
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
            imageMLAnalyzed: "https://is3.cloudhost.id/oculab-fov/oculab-fov/248d6e1e-eab3-4981-8445-2174e16b7fdb.jpeg",
            imageOriginal: "https://is3.cloudhost.id/oculab-fov/oculab-fov/c5b14ad1-c15b-4d1c-bf2f-1dcf7fbf8d8d.png",
            type: .BTA1TO9,
            order: 1,
            systemCount: 12,
            confidenceLevel: 95.0
        ),
        order: 1,
        total: 10
    )
}
