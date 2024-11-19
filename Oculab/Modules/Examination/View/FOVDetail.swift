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

    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        AsyncImage(url: URL(string: fovData.image)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        } placeholder: {
                            ProgressView()
                        }
                        .scaleEffect(zoomScale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoomScale = value
                                }
                        )
                    }
                }

                VStack(spacing: Decimal.d8 + Decimal.d2) {
                    Spacer()
                    Text("Jumlah Bakteri: \(fovData.systemCount) BTA").font(AppTypography.h3)
                    Text("\(fovData.confidenceLevel)% confidence level")
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
