//
//  FOVDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI

// MARK: - Interaction Mode Enum

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

    // MARK: - State for Add Feature

    @State private var interactionMode: InteractionMode = .panAndZoom

    /// Holds the CGRect for the new box being created. Nil when not in add mode.
    @State private var newBoxRect: CGRect?

    @ObservedObject var presenter: FOVDetailPresenter = .init()

    var body: some View {
        NavigationView {
            ZStack {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        // MARK: - Refactored View

                        // The complex AsyncImage view has been moved to its own function
                        // to help the Swift compiler process the view hierarchy.
                        imageContentView(geometry: geometry)
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                // Prevent zooming while adding a box
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
                    .onTapGesture(count: 2) {
                        // Prevent double-tap zoom while adding a box
                        guard newBoxRect == nil else { return }
                        withAnimation {
                            if zoomScale == 1.0 { zoomScale = 2.0 } else { zoomScale = 1.0; offset = .zero }
                        }
                    }
                    // Disable scroll view's own gestures when in add mode to prevent conflict
                    .scrollDisabled(interactionMode == .add)
                }

                // ... (Your existing bottom tray view code) ...
                bottomControlsView
            }
            .foregroundStyle(Color.white) // Using standard color for brevity
            .toolbar {
                // ... (Your existing toolbar code) ...
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Gambar \(order + 1) dari \(total)")
                        Text("ID \(slideId)")
                    }.foregroundStyle(Color.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Router.shared.navigateBack() // Simplified
                    }) {
                        HStack {
                            Image(systemName: "chevron.left") // Using SF Symbol for compatibility
                                .foregroundStyle(Color.white)
                        }
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(.black)
            .onAppear {
                Task {
                    await presenter.fetchData(fovId: "b13046c1-16cb-4a68-a657-225537390109")
                }
            }
        }.navigationBarBackButtonHidden()
    }

    // MARK: - View Builders

    /// A helper function to build the complex image content view.
    /// This breaks up the main `body` expression to prevent compiler errors.
    private func imageContentView(geometry: GeometryProxy) -> some View {
        AsyncImage(url: URL(string: fovData.image)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay(
                    GeometryReader { imageGeometry in

                        // MARK: ZStack for all boxes (existing and new)

                        ZStack(alignment: .topLeading) {
                            // Existing boxes from your presenter
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

                            // MARK: Display Resizable Box if it exists

                            if newBoxRect != nil {
                                // **FIXED**: Create a non-optional binding. This is safe because of the `if` check.
                                let rectBinding = Binding<CGRect>(
                                    get: { self.newBoxRect! },
                                    set: { self.newBoxRect = $0 }
                                )
                                ResizableBoundingBoxView(
                                    rect: rectBinding,
                                    onConfirm: { finalRect in
                                        confirmNewBox(finalRect)
                                    },
                                    onCancel: {
                                        cancelNewBox()
                                    }
                                )
                            }
                        }

                        // MARK: Capture size for coordinate conversion

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

                // MARK: Gesture to add a new box

                .onTapGesture { location in
                    // Only create a box if in "add" mode and no box is currently being edited
                    if interactionMode == .add, newBoxRect == nil {
                        // Create a new box at the tap location
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

    /// A computed property for the bottom control tray view.
    private var bottomControlsView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Jumlah Bakteri: \(fovData.systemCount) BTA") // Removed .font for brevity
                Text(String(
                    format: "%.2f%% confidence level",
                    fovData.confidenceLevel * 100
                )) // Removed .font for brevity
                HStack(spacing: 20) {
                    Image(systemName: "circle.lefthalf.filled") // Using SF Symbol for compatibility
                    Image(systemName: "sun.max.fill") // Using SF Symbol for compatibility
                    Button(action: {
                        interactionMode = (interactionMode == .verify) ? .panAndZoom : .verify
                    }) {
                        Image(systemName: "checkmark.square") // Using SF Symbol for compatibility
                            .padding(10)
                            .background(interactionMode == .verify ? Color.blue.opacity(0.4) : Color.clear)
                            .clipShape(Circle())
                    }
                    Button(action: {
                        interactionMode = (interactionMode == .add) ? .panAndZoom : .add
                    }) {
                        Image(systemName: "plus.app") // Using SF Symbol for compatibility
                            .padding(10)
                            .background(interactionMode == .add ? Color.green.opacity(0.4) : Color.clear)
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
    }

    // MARK: - Functions for Add Feature

    /// Called when the user confirms the new box.
    private func confirmNewBox(_ finalRect: CGRect) {
        // **FIXED**: Convert coordinates from the view's scaled and panned space to the original image space.
        // We must account for both the offset (pan) and the zoomScale.
        let originalX = (finalRect.origin.x - offset.width) / zoomScale
        let originalY = (finalRect.origin.y - offset.height) / zoomScale
        let originalWidth = finalRect.size.width / zoomScale
        let originalHeight = finalRect.size.height / zoomScale

        print("Box confirmed! Sending to BE...")
        print("x: \(originalX), y: \(originalY), width: \(originalWidth), height: \(originalHeight)")

        // TODO: Call your presenter to send data to the backend
        // await presenter.addNewBox(x: originalX, y: originalY, width: originalWidth, height: originalHeight)

        // Clean up
        newBoxRect = nil
        interactionMode = .panAndZoom
    }

    /// Called when the user cancels creating a new box.
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
