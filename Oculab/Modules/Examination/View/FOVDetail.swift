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
    @State private var selectedBox: BoxModel?

    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    ZStack {
                        AsyncImage(url: URL(string: fovData.image)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .overlay(
                                    GeometryReader { imageGeometry in
                                        BoxesGroupComponentView(
                                            width: imageGeometry.size.width,
                                            height: imageGeometry.size.height,
                                            zoomScale: zoomScale,
                                            boxes: [
                                                BoxModel(id: 1, width: 17, height: 10, x: 40, y: 300),
                                                BoxModel(id: 2, width: 25, height: 30, x: 180, y: 400),
                                                BoxModel(id: 3, width: 20, height: 25, x: 70, y: 170),
                                                BoxModel(id: 4, width: 15, height: 15, x: 210, y: 200),
                                                BoxModel(id: 5, width: 15, height: 20, x: 130, y: 350),
                                            ],
                                            selectedBox: $selectedBox,
                                            onBoxSelected: { box in
                                                selectedBox = box
                                            }
                                        )
                                    }
                                )
                                .frame(
                                    width: geometry.size.width * zoomScale,
                                    height: geometry.size.height * zoomScale
                                )
                                .offset(offset)
                                .clipped()
                                .onChange(of: selectedBox) { newBox in
                                    if let box = newBox {
                                        centerBox(box, imageGeometry: geometry, screenGeometry: geometry)
                                    }
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(
                                    width: geometry.size.width * zoomScale,
                                    height: geometry.size.height * zoomScale
                                )
                        }

                        // Custom pan gesture to handle dragging - now works at any zoom level
                        Color.clear
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newOffset = CGSize(
                                            width: offset.width + value.translation.width,
                                            height: offset.height + value.translation.height
                                        )
                                        offset = limitOffset(newOffset, geometry: geometry)
                                    }
                            )
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let newZoom = min(max(value, 1.0), 4.0)
                                zoomScale = newZoom
                                // Reset offset when zooming out to 1.0
                                if newZoom == 1.0 {
                                    withAnimation {
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if zoomScale == 1.0 {
                                zoomScale = 2.0
                            } else {
                                zoomScale = 1.0
                                offset = .zero
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

    private func centerBox(_ box: BoxModel, imageGeometry: GeometryProxy, screenGeometry: GeometryProxy) {
        print("Centering box \(box.id) at position (\(box.x), \(box.y))")
        print("Image size: \(imageGeometry.size)")
        print("Screen size: \(screenGeometry.size)")
        print("Current zoom scale: \(zoomScale)")

        // Calculate box center position relative to the image (in image coordinates)
        let boxCenterX = box.x + box.width / 2
        let boxCenterY = box.y + box.height / 2

        print("Box center in image coordinates: (\(boxCenterX), \(boxCenterY))")

        // Convert to screen coordinates by applying zoom scale
        let boxCenterScreenX = boxCenterX * zoomScale
        let boxCenterScreenY = boxCenterY * zoomScale

        print("Box center in screen coordinates: (\(boxCenterScreenX), \(boxCenterScreenY))")

        // Calculate the visible area center (accounting for tray at bottom)
        let screenCenterX = screenGeometry.size.width / 2
        // Adjust Y center to account for tray - assume tray takes up about 1/3 of screen
        let trayHeight = screenGeometry.size.height * 0.35 // Approximate tray height
        let visibleAreaHeight = screenGeometry.size.height - trayHeight
        let visibleCenterY = visibleAreaHeight / 2

        print("Visible area center: (\(screenCenterX), \(visibleCenterY))")

        // Calculate the offset needed to move box center to visible area center
        let targetOffsetX = screenCenterX - boxCenterScreenX
        let targetOffsetY = visibleCenterY - boxCenterScreenY - 50

        print("Target offset: (\(targetOffsetX), \(targetOffsetY))")

        // Apply the offset with bounds checking
        let boundedOffset = limitOffset(CGSize(width: targetOffsetX, height: targetOffsetY), geometry: screenGeometry)

        print("Bounded offset: (\(boundedOffset.width), \(boundedOffset.height))")

        withAnimation(.easeInOut(duration: 0.5)) {
            offset = boundedOffset
        }
    }

    private func limitOffset(_ newOffset: CGSize, geometry: GeometryProxy) -> CGSize {
        let scaledWidth = geometry.size.width * zoomScale
        let scaledHeight = geometry.size.height * zoomScale

        let maxOffsetX = max(0, (scaledWidth - geometry.size.width) / 2)
        let maxOffsetY = max(0, (scaledHeight - geometry.size.height) / 2)

        let limitedX: CGFloat
        let limitedY: CGFloat

        limitedX = newOffset.width
        limitedY = newOffset.height

        return CGSize(width: limitedX, height: limitedY)
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
