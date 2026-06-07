//
//  BoxesGroupComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 20/05/25.
//

import SwiftUI
import UIKit

struct BoxesGroupComponentView: View {
    @EnvironmentObject var presenter: FOVDetailPresenter
    var zoomScale: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let imageSize = geometry.size
            let scaleX = imageSize.width / Double(presenter.fovDetail?.frameWidth ?? 1)
            let scaleY = imageSize.height / Double(presenter.fovDetail?.frameHeight ?? 1)

            ZStack(alignment: .topLeading) {
                // Simple tap for adding new bounding boxes (we'll improve this later)
                if presenter.isAddBacilliActive && !presenter.isCreatingNewBox {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            Logger.debug("User tapped at: \(location)", category: .examination)

                            // Provide haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            // Start creating new box
                            presenter.startCreatingBox(at: location)
                        }
                }
                
                // Show editable box when creating new box
                if presenter.isCreatingNewBox, let location = presenter.newBoxLocation {
                    EditableBoxComponentView(
                        at: location,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        zoomScale: zoomScale,
                        onCancel: {
                            presenter.cancelBoxCreation()
                        },
                        onConfirm: { frame in
                            Task {
                                await presenter.confirmBoxCreation(
                                    frame: frame,
                                    frameWidth: presenter.fovDetail?.frameWidth ?? 1,
                                    frameHeight: presenter.fovDetail?.frameHeight ?? 1,
                                    scaleX: scaleX,
                                    scaleY: scaleY
                                )
                            }
                        }
                    )
                }
                
                if presenter.fovDetail != nil, presenter.isBoundingBoxVisible {
                    ForEach(presenter.boxes) { box in
                        let isSelected = presenter.selectedBox?.id == box.id
                        BoxComponentView(
                            box: box,
                            selectedBox: presenter.selectedBox,
                            zoomScale: zoomScale,
                            labelNumber: nil
                        )
                        .frame(width: box.width * scaleX, height: box.height * scaleY)
                        .position(
                            x: (box.x + box.width / 2) * scaleX,
                            y: (box.y + box.height / 2) * scaleY
                        )
                        .opacity(boxOpacity(for: box, isSelected: isSelected))
                        .onTapGesture {
                            if !presenter.isAddBacilliActive {
                                presenter.selectBox(box)
                            }
                        }
                    }

                    if let selectedBox = presenter.selectedBox {
                        selectedBoxLabel(
                            number: presenter.displayIndex(for: selectedBox, in: presenter.boxes),
                            box: selectedBox,
                            scaleX: scaleX,
                            scaleY: scaleY
                        )
                    }
                }
            }
        }
        .sheet(item: $presenter.selectedBox) { selected in
            if !presenter.isAddBacilliActive {
                TrayView(
                    selectedBox: $presenter.selectedBox,
                    boxes: presenter.boxes,
                    onNavigate: { box in
                        presenter.navigateToBoxInSequence(box)
                    },
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
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.slate0)
            }
        }
    }

    private func selectedBoxLabel(
        number: Int,
        box: BoxModel,
        scaleX: Double,
        scaleY: Double
    ) -> some View {
        Text("\(number)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.black)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .position(
                x: (box.x * scaleX) + 12,
                y: max(10, (box.y * scaleY) - 8)
            )
            .allowsHitTesting(false)
    }

    private func boxOpacity(for box: BoxModel, isSelected: Bool) -> Double {
        if presenter.isAddBacilliActive { return 0.3 }
        if presenter.selectedBox == nil { return 1.0 }
        return isSelected ? 1.0 : 0.45
    }
}

enum BoxStatus: String, Decodable, Encodable {
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

struct BoxModel: Identifiable, Equatable, Decodable, Encodable {
    let id: String
    var order: Int?
    var width: Double
    var height: Double
    var x: Double
    var y: Double
    var status: BoxStatus

    enum CodingKeys: String, CodingKey {
        case id
        case order
        case width
        case height
        case x = "xCoordinate"
        case y = "yCoordinate"
        case status
    }
}
