//
//  ResizableBoundingBox.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/06/25.
//

import SwiftUI

/// A view representing a bounding box that can be resized and moved.
/// It displays handles at the corners for resizing and provides buttons for confirmation or cancellation.
struct ResizableBoundingBoxView: View {
    // MARK: - Properties

    /// Binding to the CGRect that defines the box's position and size.
    @Binding var rect: CGRect

    /// The current zoom scale of the parent content view.
    let zoomScale: CGFloat

    /// Closure to be called when the user confirms the box.
    let onConfirm: (CGRect) -> Void

    /// Closure to be called when the user cancels the operation.
    let onCancel: () -> Void

    /// Stores the state of the rectangle at the beginning of a drag gesture.
    /// This is the key to preventing the "running away" effect.
    @State private var startingRect: CGRect?

    /// The size of the corner resize handles.
    private let handleSize: CGFloat = 24.0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main rectangle shape
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .border(Color.green, width: 2 / zoomScale) // Scale border width

            // Draggable handles at each corner
            handle(position: .topLeft)
            handle(position: .topRight)
            handle(position: .bottomLeft)
            handle(position: .bottomRight)

            // Confirmation and Cancel buttons
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { onConfirm(rect) }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    }
                    Spacer()
                }
                .padding(.bottom, 12)
            }
            .scaleEffect(1 / zoomScale) // Scale buttons so they don't get tiny when zoomed out
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        // **FIXED**: Gesture to move the entire box
        .gesture(
            DragGesture()
                .onChanged { value in
                    // On the first change, store the starting position.
                    if self.startingRect == nil {
                        self.startingRect = self.rect
                    }

                    var newRect = self.startingRect!
                    // Calculate new origin based on the STARTING point + translation.
                    // This prevents cumulative additions (the "running" effect).
                    newRect.origin.x += value.translation.width / self.zoomScale
                    newRect.origin.y += value.translation.height / self.zoomScale
                    self.rect = newRect
                }
                .onEnded { _ in
                    // Clear the starting position when the drag ends.
                    self.startingRect = nil
                }
        )
    }

    // MARK: - Helper Views and Functions

    /// A helper function to create a resize handle.
    private func handle(position: Corner) -> some View {
        Circle()
            .fill(Color.green)
            .frame(width: handleSize / zoomScale, height: handleSize / zoomScale) // Scale handle size
            .position(position.point(in: rect))
            // **FIXED**: Gesture for resizing a corner
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // On the first change, store the starting position.
                        if self.startingRect == nil {
                            self.startingRect = self.rect
                        }

                        // Scale the translation to match the content's zoom level
                        let scaledTranslation = CGSize(
                            width: value.translation.width / zoomScale,
                            height: value.translation.height / zoomScale
                        )

                        // Calculate the new rect based on the STARTING rect and current translation
                        self.rect = self.resize(
                            rect: self.startingRect!,
                            with: scaledTranslation,
                            from: position
                        )
                    }
                    .onEnded { _ in
                        // Clear the starting position when the drag ends.
                        self.startingRect = nil
                    }
            )
    }

    /// An enumeration for the four corners.
    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight

        func point(in rect: CGRect) -> CGPoint {
            switch self {
            case .topLeft: return CGPoint(x: 0, y: 0)
            case .topRight: return CGPoint(x: rect.width, y: 0)
            case .bottomLeft: return CGPoint(x: 0, y: rect.height)
            case .bottomRight: return CGPoint(x: rect.width, y: rect.height)
            }
        }
    }

    /// **REFACTORED**: Pure function to calculate the new resized rectangle.
    private func resize(rect: CGRect, with translation: CGSize, from corner: Corner) -> CGRect {
        var newRect = rect
        let minSize: CGFloat = 40.0 / zoomScale // Scale min size

        switch corner {
        case .topLeft:
            newRect.origin.x += translation.width
            newRect.origin.y += translation.height
            newRect.size.width -= translation.width
            newRect.size.height -= translation.height
        case .topRight:
            newRect.origin.y += translation.height
            newRect.size.width += translation.width
            newRect.size.height -= translation.height
        case .bottomLeft:
            newRect.origin.x += translation.width
            newRect.size.width -= translation.width
            newRect.size.height += translation.height
        case .bottomRight:
            newRect.size.width += translation.width
            newRect.size.height += translation.height
        }

        // Enforce minimum size
        if newRect.width < minSize {
            newRect.size.width = rect.width
        }
        if newRect.height < minSize {
            newRect.size.height = rect.height
        }

        return newRect
    }
}
