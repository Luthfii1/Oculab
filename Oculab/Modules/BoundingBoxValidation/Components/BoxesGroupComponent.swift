//
//  BoxesGroupComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 20/05/25.
//

import SwiftUI

struct BoxesGroupComponentView: View {
    @EnvironmentObject var presenter: FOVDetailPresenter
    var zoomScale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(presenter.boxes) { box in
                BoxComponentView(
                    box: box,
                    selectedBox: presenter.selectedBox,
                    zoomScale: zoomScale,
                    transformedWidth: getTransformedWidth(box.width),
                    transformedHeight: getTransformedHeight(box.height)
                )
                .position(
                    x: getTransformedX(box.x),
                    y: getTransformedY(box.y)
                )
                .onTapGesture {
                    if presenter.interactionMode == .verify {
                        presenter.selectedBox = box
                    }
                }
                .disabled(presenter.interactionMode != .verify)
            }
        }
        .frame(
            width: presenter.imageFrame.width * zoomScale,
            height: presenter.imageFrame.height * zoomScale
        )
        .allowsHitTesting(presenter.interactionMode != .add) // Disable hit testing when in add mode
        .sheet(item: $presenter.selectedBox) { selected in
            TrayView(
                selectedBox: $presenter.selectedBox,
                boxes: presenter.boxes,
                onVerify: {
                    Task {
                        await presenter.updateBoxStatus(boxId: selected.id, newStatus: .verified)
                    }
                },
                onFlag: {
                    Task {
                        await presenter.updateBoxStatus(boxId: selected.id, newStatus: .flagged)
                    }
                },
                onReject: {
                    Task {
                        await presenter.updateBoxStatus(boxId: selected.id, newStatus: .trashed)
                    }
                }
            )
        }
    }
    
    // MARK: - Coordinate Transformation
    
    /// Transform X coordinate from original image space to display space
    private func getTransformedX(_ originalX: Double) -> Double {
        // Calculate the scale factor based on actual display dimensions
        let scale = presenter.imageFrame.width / presenter.originalImageSize.width
        
        // Transform the coordinate
        let transformedX = originalX * scale * zoomScale
        
        print("=== COORDINATE TRANSFORM DEBUG ===")
        print("Original X: \(originalX)")
        print("Image frame width: \(presenter.imageFrame.width)")
        print("Original image width: \(presenter.originalImageSize.width)")
        print("Scale: \(scale)")
        print("Zoom scale: \(zoomScale)")
        print("Transformed X: \(transformedX)")
        print("================================")
        
        return transformedX
    }
    
    /// Transform Y coordinate from original image space to display space
    private func getTransformedY(_ originalY: Double) -> Double {
        // Calculate the scale factor and centering offset
        let scale = presenter.imageFrame.width / presenter.originalImageSize.width
        let scaledHeight = presenter.originalImageSize.height * scale
        let centeringOffset = (presenter.containerFrame.height - scaledHeight) / 2
        
        // Transform the coordinate
        let transformedY = (originalY * scale + centeringOffset) * zoomScale
        
        print("=== COORDINATE TRANSFORM DEBUG ===")
        print("Original Y: \(originalY)")
        print("Container frame height: \(presenter.containerFrame.height)")
        print("Scale: \(scale)")
        print("Scaled height: \(scaledHeight)")
        print("Centering offset: \(centeringOffset)")
        print("Zoom scale: \(zoomScale)")
        print("Transformed Y: \(transformedY)")
        print("================================")
        
        return transformedY
    }
    
    private func getTransformedWidth(_ originalWidth: Double) -> Double {
        // Calculate the scale factor based on actual display dimensions
        let scale = presenter.imageFrame.width / presenter.originalImageSize.width
        
        // Transform the width
        let transformedWidth = originalWidth * scale * zoomScale
        
        print("=== WIDTH TRANSFORM DEBUG ===")
        print("Original width: \(originalWidth)")
        print("Image frame width: \(presenter.imageFrame.width)")
        print("Scale: \(scale)")
        print("Zoom scale: \(zoomScale)")
        print("Transformed width: \(transformedWidth)")
        print("=============================")
        
        return transformedWidth
    }

    private func getTransformedHeight(_ originalHeight: Double) -> Double {
        // Calculate the scale factor based on actual display dimensions
        let scale = presenter.imageFrame.width / presenter.originalImageSize.width
        
        // Transform the height
        let transformedHeight = originalHeight * scale * zoomScale
        
        print("=== HEIGHT TRANSFORM DEBUG ===")
        print("Original height: \(originalHeight)")
        print("Image frame width: \(presenter.imageFrame.width)")
        print("Scale: \(scale)")
        print("Zoom scale: \(zoomScale)")
        print("Transformed height: \(transformedHeight)")
        print("==============================")
        
        return transformedHeight
    }
}

enum BoxStatus: String, Decodable {
    case none = "UNVERIFIED"
    case verified = "VERIFIED"
    case trashed = "DELETED"
    case flagged = "FLAGGED"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let statusString = try container.decode(String.self)

        switch statusString.uppercased() {
        case "VERIFIED":
            self = .verified
        case "FLAGGED":
            self = .flagged
        case "DELETED":
            self = .trashed
        case "UNVERIFIED":
            self = .none
        default:
            self = .none
        }
    }
}

struct BoxModel: Identifiable, Equatable, Decodable {
    let id: String
    var width: Double
    var height: Double
    var x: Double
    var y: Double
    var status: BoxStatus

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case width
        case height
        case x = "xCoordinate"
        case y = "yCoordinate"
        case status
    }
    
    init(id: String, width: Double, height: Double, x: Double, y: Double, status: BoxStatus = .none) {
        self.id = id
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.status = status
    }
}
