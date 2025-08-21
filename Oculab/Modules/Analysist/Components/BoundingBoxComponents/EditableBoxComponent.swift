//
//  EditableBoxComponentView.swift
//  Oculab
//
//  Created by Assistant on [Date]
//

import SwiftUI

struct EditableBoxComponentView: View {
    @State private var boxFrame: CGRect
    @State private var isDragging = false
    @State private var activeHandle: ResizeHandle? = nil
    @State private var dragStartFrame: CGRect = .zero // Track the frame when drag started
    
    let initialLocation: CGPoint
    let scaleX: Double
    let scaleY: Double
    let zoomScale: CGFloat
    let onCancel: () -> Void
    let onConfirm: (CGRect) -> Void
    
    // Default box size (you can adjust these values)
    private let defaultWidth: CGFloat = 60
    private let defaultHeight: CGFloat = 60
    
    enum ResizeHandle {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case center // for moving the entire box
    }
    
    init(at location: CGPoint, scaleX: Double, scaleY: Double, zoomScale: CGFloat, onCancel: @escaping () -> Void, onConfirm: @escaping (CGRect) -> Void) {
        self.initialLocation = location
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.zoomScale = zoomScale
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        
        // Initialize the box frame centered on the tap location
        let initialFrame = CGRect(
            x: location.x - defaultWidth / 2,
            y: location.y - defaultHeight / 2,
            width: defaultWidth,
            height: defaultHeight
        )
        self._boxFrame = State(initialValue: initialFrame)
    }
    
    var body: some View {
        ZStack {
            // Main box
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.green, lineWidth: max(2.0, 3 / zoomScale))
                )
                .frame(width: boxFrame.width, height: boxFrame.height)
                .position(x: boxFrame.midX, y: boxFrame.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if activeHandle == nil {
                                activeHandle = .center
                                dragStartFrame = boxFrame
                            }
                            if activeHandle == .center {
                                let newX = dragStartFrame.minX + value.translation.width
                                let newY = dragStartFrame.minY + value.translation.height
                                boxFrame = CGRect(x: newX, y: newY, width: boxFrame.width, height: boxFrame.height)
                            }
                        }
                        .onEnded { _ in
                            activeHandle = nil
                        }
                )
            
            // Resize handles (corners)
            resizeHandle(for: .topLeft)
            resizeHandle(for: .topRight)
            resizeHandle(for: .bottomLeft)
            resizeHandle(for: .bottomRight)
            
            // Action buttons
            HStack(spacing: 8) {
                // Cancel button
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: max(24, 24 / zoomScale)))
                        .foregroundColor(.red)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                
                // Confirm button
                Button(action: {
                    onConfirm(boxFrame)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: max(24, 24 / zoomScale)))
                        .foregroundColor(.green)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .position(x: boxFrame.midX, y: boxFrame.minY - max(20, 20 / zoomScale))
        }
    }
    
    @ViewBuilder
    private func resizeHandle(for handle: ResizeHandle) -> some View {
        let handleSize: CGFloat = max(12, 12 / zoomScale)
        let position = handlePosition(for: handle)
        
        Circle()
            .fill(Color.green)
            .frame(width: handleSize, height: handleSize)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if activeHandle != handle {
                            activeHandle = handle
                            dragStartFrame = boxFrame
                        }
                        updateBoxFrame(for: handle, translation: value.translation)
                    }
                    .onEnded { _ in
                        activeHandle = nil
                    }
            )
    }
    
    private func handlePosition(for handle: ResizeHandle) -> CGPoint {
        switch handle {
        case .topLeft:
            return CGPoint(x: boxFrame.minX, y: boxFrame.minY)
        case .topRight:
            return CGPoint(x: boxFrame.maxX, y: boxFrame.minY)
        case .bottomLeft:
            return CGPoint(x: boxFrame.minX, y: boxFrame.maxY)
        case .bottomRight:
            return CGPoint(x: boxFrame.maxX, y: boxFrame.maxY)
        case .top:
            return CGPoint(x: boxFrame.midX, y: boxFrame.minY)
        case .bottom:
            return CGPoint(x: boxFrame.midX, y: boxFrame.maxY)
        case .left:
            return CGPoint(x: boxFrame.minX, y: boxFrame.midY)
        case .right:
            return CGPoint(x: boxFrame.maxX, y: boxFrame.midY)
        case .center:
            return CGPoint(x: boxFrame.midX, y: boxFrame.midY)
        }
    }
    
    private func updateBoxFrame(for handle: ResizeHandle, translation: CGSize) {
        let minSize: CGFloat = 20 // Minimum box size
        
        // Use the drag start frame as the base for calculations
        let startFrame = dragStartFrame
        
        switch handle {
        case .topLeft:
            let newWidth = max(minSize, startFrame.width - translation.width)
            let newHeight = max(minSize, startFrame.height - translation.height)
            let newX = startFrame.maxX - newWidth
            let newY = startFrame.maxY - newHeight
            boxFrame = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
            
        case .topRight:
            let newWidth = max(minSize, startFrame.width + translation.width)
            let newHeight = max(minSize, startFrame.height - translation.height)
            let newY = startFrame.maxY - newHeight
            boxFrame = CGRect(x: startFrame.minX, y: newY, width: newWidth, height: newHeight)
            
        case .bottomLeft:
            let newWidth = max(minSize, startFrame.width - translation.width)
            let newHeight = max(minSize, startFrame.height + translation.height)
            let newX = startFrame.maxX - newWidth
            boxFrame = CGRect(x: newX, y: startFrame.minY, width: newWidth, height: newHeight)
            
        case .bottomRight:
            let newWidth = max(minSize, startFrame.width + translation.width)
            let newHeight = max(minSize, startFrame.height + translation.height)
            boxFrame = CGRect(x: startFrame.minX, y: startFrame.minY, width: newWidth, height: newHeight)
            
        case .center:
            // This is handled in the main box gesture
            break
            
        default:
            break
        }
    }
}