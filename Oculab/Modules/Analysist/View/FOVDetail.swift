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
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, Decimal.d16)
                        .padding(.vertical, Decimal.d12)

                        HStack(spacing: Decimal.d16) {
                            Button(action: {
                                // Add contrast adjustment
                            }) {
                                Image("Contrast")
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                // Add brightness adjustment
                            }) {
                                Image("Brightness")
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                // Add comment functionality
                            }) {
                                Image("Comment")
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
                        Text("Gambar \(order + 1) dari \(total)")
                            .font(AppTypography.s4_1)
                            .foregroundColor(.white)
                        Text("ID \(slideId)")
                            .font(AppTypography.p3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
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
