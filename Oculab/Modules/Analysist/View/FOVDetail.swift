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

    @StateObject private var presenter = FOVDetailPresenter()

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
                    .overlay(
                        Group {
                            if let newBoxRect = presenter.newBoxRect {
                                let rectBinding = Binding<CGRect>(
                                    get: { newBoxRect },
                                    set: { presenter.newBoxRect = $0 }
                                )
                                ResizableBoundingBoxView(
                                    rect: rectBinding,
                                    zoomScale: presenter.zoomScale,
                                    onConfirm: { finalRect in
                                        presenter.confirmNewBox(finalRect, fovId: fovData._id)
                                    },
                                    onCancel: {
                                        presenter.cancelNewBox()
                                    }
                                )
                            }
                        }
                    )
                } else {
                    // view with information that the data is loading because the data is not yet fetched
                    Text("Data is loading...")
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
                            Text("Jumlah Bakteri: \(fovData.systemCount) BTA")
                                .font(AppTypography.h3)
                                .foregroundColor(AppColors.slate0)

                            Text(presenter.getInstructionText())
                                .font(AppTypography.p2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Decimal.d20)
                                .foregroundColor(AppColors.slate0)
                        }
                        .padding(.horizontal, Decimal.d16)
                        .padding(.vertical, Decimal.d12)

                        HStack(spacing: Decimal.d16) {
                            Button(action: {
                                presenter.setInteractionMode(presenter.interactionMode == .verify ? .panAndZoom : .verify)
                            }) {
                                Image("verify")
                                    .background(presenter.interactionMode == .verify ? Color.purple.opacity(0.4) : Color.clear)
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                presenter.setInteractionMode(presenter.interactionMode == .add ? .panAndZoom : .add)
                            }) {
                                Image("add")
                                    .background(presenter.interactionMode == .add ? Color.purple.opacity(0.4) : Color.clear)
                                    .clipShape(Circle())
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
                    Group {
                        if presenter.interactionMode == .panAndZoom {
                            VStack {
                                Text("Gambar \(order + 1) dari \(total)")
                                    .font(AppTypography.h3)
                                Text("ID \(slideId)")
                                    .font(AppTypography.p3)
                            }
                        } else if presenter.interactionMode == .verify {
                            Text("Verifikasi Bakteri")
                                .font(AppTypography.h3)
                        } else {
                            Text("Anotasi Bakteri")
                                .font(AppTypography.h3)
                        }
                    }
                    .id(presenter.interactionMode)
                    .foregroundStyle(Color.white)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if presenter.interactionMode == .panAndZoom {
                            Router.shared.navigateBack()
                        } else {
                            presenter.setInteractionMode(.panAndZoom)
                        }
                    }) {
                        HStack {
                            Image("back_white")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
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
