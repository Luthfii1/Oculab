//
//  ResizableBoundingBox.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/06/25.
//

import SwiftUI

struct ResizableBoundingBoxView: View {
    // MARK: - Properties

    @Binding var rect: CGRect
    let zoomScale: CGFloat
    let onConfirm: (CGRect) -> Void
    let onCancel: () -> Void

    // MARK: - State

    /// Stores the state of the rectangle at the beginning of a drag gesture.
    /// This is the key to preventing the "running away" effect.
    @State private var startingRect: CGRect?

    /// **NEW**: Tracks if the user is currently dragging the box or a handle.
    /// This will be used to hide the confirm/cancel buttons during interaction.
    @State private var isDragging: Bool = false

    private let handleSize: CGFloat = 24.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // The resizable box itself, including its handles.
            boxWithHandles

            // **NEW**: The confirmation and cancel buttons are now outside the main box ZStack.
            // They are positioned relative to the box and are only visible when not dragging.
            controlButtons
        }
    }

    // MARK: - View Builders

    /// The main box view with its draggable handles.
    private var boxWithHandles: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.yellow.opacity(0.2))
                .border(Color.yellow, width: 2 / zoomScale)

            // Draggable handles at each corner
            handle(position: .topLeft)
            handle(position: .topRight)
            handle(position: .bottomLeft)
            handle(position: .bottomRight)
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .gesture(moveGesture) // Gesture to move the entire box
    }

    /// The confirmation and cancel buttons view.
    @ViewBuilder
    private var controlButtons: some View {
        HStack(spacing: 40) {
            Button(action: { onConfirm(rect) }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .background(Circle().fill(Color.white.opacity(0.8)))
            }

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                    .background(Circle().fill(Color.white.opacity(0.8)))
            }
        }
        .scaleEffect(1 / zoomScale)
        // Position the buttons below the main rectangle.
        .position(x: rect.midX, y: rect.maxY + (30 / zoomScale))
        // **NEW**: Buttons are invisible while the user is dragging.
        .opacity(isDragging ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    // MARK: - Gestures

    /// A gesture for moving the entire bounding box.
    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Set dragging state and store the starting rectangle on first change.
                if startingRect == nil {
                    startingRect = rect
                }
                isDragging = true

                var newRect = startingRect!
                newRect.origin.x += value.translation.width / zoomScale
                newRect.origin.y += value.translation.height / zoomScale
                rect = newRect
            }
            .onEnded { _ in
                // Reset states when the drag ends.
                startingRect = nil
                isDragging = false
            }
    }

    /// A helper function to create a resize handle with its gesture.
    private func handle(position: Corner) -> some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: handleSize / zoomScale, height: handleSize / zoomScale)
            .overlay(Circle().stroke(Color.white, lineWidth: 2 / zoomScale))
            .position(position.point(in: rect))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Set dragging state and store the starting rectangle on first change.
                        if startingRect == nil {
                            startingRect = rect
                        }
                        isDragging = true

                        let scaledTranslation = CGSize(
                            width: value.translation.width / zoomScale,
                            height: value.translation.height / zoomScale
                        )

                        rect = resize(rect: startingRect!, with: scaledTranslation, from: position)
                    }
                    .onEnded { _ in
                        // Reset states when the drag ends.
                        startingRect = nil
                        isDragging = false
                    }
            )
    }

    // MARK: - Helper Logic

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

    private func resize(rect: CGRect, with translation: CGSize, from corner: Corner) -> CGRect {
        var newRect = rect

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

        // **FIXED**: The minimum size enforcement has been removed.
        // The box can now be resized to be smaller.
        // Correct way to set width/height to 0 to avoid the get-only property error.
        if newRect.width < 0 { newRect.size.width = 0 }
        if newRect.height < 0 { newRect.size.height = 0 }

        return newRect
    }
}