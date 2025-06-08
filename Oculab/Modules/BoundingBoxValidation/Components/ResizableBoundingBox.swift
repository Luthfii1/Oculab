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
    /// Binding to the CGRect that defines the box's position and size.
    @Binding var rect: CGRect

    /// Closure to be called when the user confirms the box.
    let onConfirm: (CGRect) -> Void

    /// Closure to be called when the user cancels the operation.
    let onCancel: () -> Void

    /// The size of the corner resize handles.
    private let handleSize: CGFloat = 24.0

    /// The radius of the corner handles.
    private let handleRadius: CGFloat = 12.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main rectangle shape
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .border(Color.green, width: 2)

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
                    Button(action: {
                        onConfirm(rect)
                    }) {
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
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        // Gesture to move the entire box
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.rect.origin.x += value.translation.width
                    self.rect.origin.y += value.translation.height
                }
        )
    }

    /// A helper function to create a resize handle.
    private func handle(position: Corner) -> some View {
        Circle()
            .fill(Color.green)
            .frame(width: handleSize, height: handleSize)
            .position(position.point(in: rect))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        resize(with: value.translation, from: position)
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

    /// Logic to resize the rectangle based on which corner handle is dragged.
    private func resize(with translation: CGSize, from corner: Corner) {
        var newRect = rect
        let minSize: CGFloat = 40.0 // Minimum size for the box

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
            newRect.origin.x = rect.origin.x
        }
        if newRect.height < minSize {
            newRect.size.height = rect.height
            newRect.origin.y = rect.origin.y
        }

        rect = newRect
    }
}
