//
//  FOVDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI

struct FOVDetail: View {
    var slideId: String
    var fovData: FOVData
    var order: Int
    var total: Int

    @State private var zoomScale: CGFloat = 1.0

    @State private var offset = CGSize(width: 0, height: 0)

    @State private var imageSize: CGSize = .zero

    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        ZStack {
                            AsyncImage(url: URL(string: fovData.image)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .overlay(
                                        GeometryReader { _ in
                                            BoxesGroupComponentView(
                                                width: geometry.size.width * zoomScale,
                                                height: geometry.size.height * zoomScale,
                                                zoomScale: zoomScale,
                                                boxes: [
                                                    BoxModel(id: 1, width: 17, height: 10, x: 40, y: 300),
                                                    BoxModel(id: 2, width: 25, height: 30, x: 180, y: 400),
                                                    BoxModel(id: 3, width: 20, height: 25, x: 70, y: 170),
                                                    BoxModel(id: 4, width: 15, height: 15, x: 210, y: 200),
                                                    BoxModel(id: 5, width: 15, height: 20, x: 130, y: 350),
                                                ]
                                            )
                                        }
                                    )
                                    .frame(
                                        width: geometry.size.width * zoomScale,
                                        height: geometry.size.height * zoomScale
                                    )
                            } placeholder: {
                                ProgressView()
                                    .frame(
                                        width: geometry.size.width * zoomScale,
                                        height: geometry.size.height * zoomScale
                                    )
                            }
                        }
                        .frame(
                            width: geometry.size.width * zoomScale,
                            height: geometry.size.height * zoomScale,
                            alignment: .center
                        )

                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoomScale = min(max(value, 1.0), 4.0)
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                zoomScale = zoomScale == 1.0 ? 2.0 : 1.0
                            }
                        }
                    }
                }

                VStack(spacing: Decimal.d8 + Decimal.d2) {
                    Spacer()
                    Text("Jumlah Bakteri: \(fovData.systemCount) BTA").font(AppTypography.h3)
                    Text(String(format: "%.2f%% confidence level", fovData.confidenceLevel * 100))
                        .font(AppTypography.p4)
                    HStack {
                        Image("Contrast")
                        Image("Brightness")
                        Image("Comment")
                    }
                }
            }
            .foregroundStyle(AppColors.slate0)
            .padding(.horizontal, CGFloat(20))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Gambar \(order + 1) dari \(total)")
                            .font(AppTypography.s4_1)
                        Text("ID \(slideId)")
                            .font(AppTypography.p3)
                    }.foregroundStyle(AppColors.slate0)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image("back")
                                .foregroundStyle(AppColors.slate0)
                        }
                    }
                }
            }
            .background(.black)
            .onAppear {}
        }.navigationBarBackButtonHidden()
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
