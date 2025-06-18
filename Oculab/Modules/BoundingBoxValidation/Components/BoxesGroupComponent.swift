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
                    zoomScale: zoomScale
                )
                .position(
                    x: box.x * zoomScale,
                    y: box.y * zoomScale
                )
                .onTapGesture {
                    presenter.selectedBox = box
                }
            }
        }
        .frame(width: Double(presenter.fovDetail?.frameWidth ?? 0) * zoomScale, height: Double(presenter.fovDetail?.frameHeight ?? 0) * zoomScale)
        .sheet(item: $presenter.selectedBox) { selected in
            TrayView(
                selectedBox: $presenter.selectedBox,
                boxes: presenter.boxes,
                onVerify: {
                    updateBoxStatus(id: selected.id, to: .verified)
                },
                onFlag: {
                    updateBoxStatus(id: selected.id, to: .flagged)
                },
                onReject: {
                    updateBoxStatus(id: selected.id, to: .trashed)
                }
            )
        }
    }

    private func updateBoxStatus(id: String, to status: BoxStatus) {
        if let index = presenter.boxes.firstIndex(where: { $0.id == id }) {
            presenter.boxes[index].status = status

            Task {
                await presenter.updateBoxStatus(boxId: id, newStatus: status)
            }
        }
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
}
