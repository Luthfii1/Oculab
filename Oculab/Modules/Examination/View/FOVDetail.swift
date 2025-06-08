//
//  FOVDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI

enum InteractionMode {
    case panAndZoom
    case verify
    case add
}

struct FOVDetail: View {
    var slideId: String
    var fovData: FOVData
    var order: Int
    var total: Int

    @State private var zoomScale: CGFloat = 1.0
    @State private var offset = CGSize(width: 0, height: 0)
    @State private var imageSize: CGSize = .zero
    @State private var selectedBox: BoxModel?

    @State private var lastScale: CGFloat = 1.0
    @State private var gestureCenter: CGPoint = .zero
    @State private var interactionMode: InteractionMode = .panAndZoom

    @State private var newBoxRect: CGRect?

    @ObservedObject var presenter: FOVDetailPresenter = .init()

    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        imageContentView(geometry: geometry)
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                guard newBoxRect == nil else { return }

                                let delta = value / lastScale
                                lastScale = value
                                let newScale = min(max(zoomScale * delta, 1.0), 4.0)

                                let center = gestureCenter
                                let translatedCenter = CGPoint(
                                    x: (center.x - offset.width) / zoomScale,
                                    y: (center.y - offset.height) / zoomScale
                                )
                                let newOffset = CGSize(
                                    width: center.x - translatedCenter.x * newScale,
                                    height: center.y - translatedCenter.y * newScale
                                )

                                zoomScale = newScale
                                offset = limitOffset(newOffset, geometry: geometry)
                            }
                            .onEnded { _ in lastScale = 1.0 }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in gestureCenter = value.location }
                    )

                    .onTapGesture(count: 2) { location in
                        guard newBoxRect == nil else { return }

                        withAnimation(.easeInOut) {
                            if zoomScale > 1.0 {
                                zoomScale = 1.0
                                offset = .zero
                            } else {
                                let newScale: CGFloat = 2.0

                                let translatedCenter = CGPoint(
                                    x: (location.x - offset.width) / zoomScale,
                                    y: (location.y - offset.height) / zoomScale
                                )

                                let newOffset = CGSize(
                                    width: location.x - translatedCenter.x * newScale,
                                    height: location.y - translatedCenter.y * newScale
                                )

                                zoomScale = newScale
                                offset = limitOffset(newOffset, geometry: geometry)
                            }
                        }
                    }

                    .scrollDisabled(interactionMode == .add)
                }

                let yOffset = (interactionMode != .panAndZoom) ? 250.0 : 0.0

                bottomControlsView
                    .offset(y: yOffset)

                VStack {
                    if interactionMode == .verify {
                        Text("Ketuk kotak anotasi bakteri yang ingin Anda verifikasi, tandai, atau hilangkan")
                            .font(AppTypography.p2).multilineTextAlignment(.center)
                            .padding(.horizontal, Decimal.d20)
                    } else if interactionMode == .add {
                        Text("Ketuk area lapangan pandang untuk menambahkan/menghapus anotasi bakteri")
                            .font(AppTypography.p2).multilineTextAlignment(.center)
                            .padding(.horizontal, Decimal.d20)
                    }

                    Spacer()
                }
            }
            .foregroundStyle(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Group {
                        if interactionMode == .panAndZoom {
                            VStack {
                                Text("Gambar \(order + 1) dari \(total)")
                                    .font(AppTypography.h3)
                                Text("ID \(slideId)")
                                    .font(AppTypography.p3)
                            }
                        } else if interactionMode == .verify {
                            Text("Verifikasi Bakteri")
                                .font(AppTypography.h3)
                        } else {
                            Text("Anotasi Bakteri")
                                .font(AppTypography.h3)
                        }
                    }
                    .id(interactionMode)
                    .foregroundStyle(Color.white)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if interactionMode == .panAndZoom {
                        } else {
                            withAnimation {
                                interactionMode = .panAndZoom
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(.black)
            .onAppear {
                Task {
                    await presenter.fetchData(fovId: fovData._id.uuidString)
                }
            }
        }.navigationBarBackButtonHidden()
    }

    private func imageContentView(geometry: GeometryProxy) -> some View {
        AsyncImage(url: URL(string: fovData.image)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    GeometryReader { imageGeometry in

                        ZStack(alignment: .topLeading) {
                            BoxesGroupComponentView(
                                presenter: presenter,
                                width: imageGeometry.size.width,
                                height: imageGeometry.size.height,
                                zoomScale: zoomScale,
                                boxes: presenter.boxes,
                                interactionMode: interactionMode,
                                selectedBox: $selectedBox,
                                onBoxSelected: { box in
                                    selectedBox = box
                                }
                            )

                            if newBoxRect != nil {
                                let rectBinding = Binding<CGRect>(
                                    get: { self.newBoxRect! },
                                    set: { self.newBoxRect = $0 }
                                )
                                ResizableBoundingBoxView(
                                    rect: rectBinding,
                                    zoomScale: zoomScale,
                                    onConfirm: { finalRect in
                                        confirmNewBox(finalRect)
                                    },
                                    onCancel: {
                                        cancelNewBox()
                                    }
                                )
                            }
                        }

                        .onAppear {
                            self.imageSize = imageGeometry.size
                        }
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
                        interactionMode = .panAndZoom
                    }
                }

                .onTapGesture { location in

                    if interactionMode == .add, newBoxRect == nil {
                        let initialSize = CGSize(width: 100, height: 100)
                        self.newBoxRect = CGRect(
                            origin: CGPoint(
                                x: location.x - initialSize.width / 2,
                                y: location.y - initialSize.height / 2
                            ),
                            size: initialSize
                        )
                    }
                }
        } placeholder: {
            ProgressView()
                .frame(
                    width: geometry.size.width * zoomScale,
                    height: geometry.size.height * zoomScale
                )
        }
    }

    private var bottomControlsView: some View {
        VStack {
            Spacer()
            VStack(spacing: Decimal.d8 + Decimal.d2) {
                Text("Jumlah Bakteri: \(fovData.systemCount) BTA")
                    .font(AppTypography.h3)
                    .foregroundStyle(AppColors.slate0)
                Text(String(
                    format: "%.2f%% confidence level",
                    fovData.confidenceLevel
                ))
                .font(AppTypography.p4)
                .foregroundStyle(AppColors.slate0)
                HStack(spacing: Decimal.d16) {
                    Image("Contrast")
                    Image("Brightness")
                    Button(action: {
                        withAnimation(.easeInOut) {
                            interactionMode = (interactionMode == .verify) ? .panAndZoom : .verify
                        }

                    }) {
                        Image("verify")
                            .background(interactionMode == .verify ? AppColors.purple100.opacity(0.4) : Color.clear)
                            .clipShape(Circle())
                    }
                    Button(action: {
                        withAnimation(.easeInOut) {
                            interactionMode = (interactionMode == .add) ? .panAndZoom : .add
                        }
                    }) {
                        Image("add")
                            .background(interactionMode == .add ? AppColors.purple100.opacity(0.4) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.5))
        }
        .padding(.vertical)
        .cornerRadius(12)
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func confirmNewBox(_ finalRect: CGRect) {
        let originalX = (finalRect.origin.x - offset.width) / zoomScale
        let originalY = (finalRect.origin.y - offset.height) / zoomScale
        let originalWidth = finalRect.size.width / zoomScale
        let originalHeight = finalRect.size.height / zoomScale

        print("Box confirmed! Sending to BE...")
        print("x: \(originalX), y: \(originalY), width: \(originalWidth), height: \(originalHeight)")

        let newClientBox = BoxModel(
            id: UUID().uuidString,
            width: originalWidth,
            height: originalHeight,
            x: originalX,
            y: originalY,
            status: .none
        )
        presenter.boxes.append(newClientBox)

        Task {
            await presenter.addBox(
                fovId: fovData._id.uuidString,
                x: originalX,
                y: originalY,
                width: originalWidth,
                height: originalHeight
            )
        }

        newBoxRect = nil
        interactionMode = .panAndZoom
    }

    private func cancelNewBox() {
        newBoxRect = nil
        interactionMode = .panAndZoom
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

        let boxCenterX = box.x + box.width / 2
        let boxCenterY = box.y + box.height / 2

        let screenCenterX = screenGeometry.size.width / 2
        let trayHeight = screenGeometry.size.height * 0.35
        let visibleAreaHeight = screenGeometry.size.height - trayHeight
        let visibleCenterY = visibleAreaHeight / 2

        let boxCenterScreenX = boxCenterX * newZoom
        let boxCenterScreenY = boxCenterY * newZoom

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
