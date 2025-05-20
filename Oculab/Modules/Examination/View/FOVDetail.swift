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
                    ScrollView([.horizontal, .vertical]) {
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
                                        resetThenZoomToBox(box, screenGeometry: geometry)
                                    }
                                }
                        } placeholder: {
                            ProgressView()
                                .frame(
                                    width: geometry.size.width * zoomScale,
                                    height: geometry.size.height * zoomScale
                                )
                        }

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

                VStack {
                    Spacer()

                    VStack(spacing: Decimal.d8 + Decimal.d2) {
                        Text("Jumlah Bakteri: \(fovData.systemCount) BTA").font(AppTypography.h3)
                        Text(String(format: "%.2f%% confidence level", fovData.confidenceLevel * 100))
                            .font(AppTypography.p4)
                        HStack {
                            Image("Contrast")
                            Image("Brightness")
                            Image("Comment")
                        }
                    }.padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.5))
                }
                .padding(.vertical)
                .cornerRadius(12)
                .ignoresSafeArea(edges: .bottom)
            }
            .foregroundStyle(AppColors.slate0)
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
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(.black)
            .onAppear {}
        }.navigationBarBackButtonHidden()
    }

    func resetThenZoomToBox(_ box: BoxModel, screenGeometry: GeometryProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            zoomScale = 1.0
            offset = .zero
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            zoomToBox(box, screenGeometry: screenGeometry)
        }
    }

    func zoomToBox(_ box: BoxModel, screenGeometry: GeometryProxy) {
        let newZoom: CGFloat = 2.0

        // Center of the box (in image coordinates)
        let boxCenterX = box.x + box.width / 2
        let boxCenterY = box.y + box.height / 2

        // Screen visible center
        let screenCenterX = screenGeometry.size.width / 2
        let trayHeight = screenGeometry.size.height * 0.35
        let visibleAreaHeight = screenGeometry.size.height - trayHeight
        let visibleCenterY = visibleAreaHeight / 2

        // New box center in screen coordinates after zoom
        let boxCenterScreenX = boxCenterX * newZoom
        let boxCenterScreenY = boxCenterY * newZoom

        // Target offset: move box center to visible area center
        let targetOffsetX = screenCenterX - boxCenterScreenX
        let targetOffsetY = visibleCenterY - boxCenterScreenY - 50

        withAnimation(.easeInOut(duration: 0.35)) {
            zoomScale = newZoom
            offset = CGSize(width: targetOffsetX, height: targetOffsetY)
        }
    }

    private func limitOffset(_ newOffset: CGSize, geometry: GeometryProxy) -> CGSize {
        let scaledWidth = geometry.size.width * zoomScale
        let scaledHeight = geometry.size.height * zoomScale

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
