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
        GeometryReader { geometry in
            let imageSize = geometry.size
            let scaleX = imageSize.width / Double(presenter.fovDetail?.frameWidth ?? 1)
            let scaleY = imageSize.height / Double(presenter.fovDetail?.frameHeight ?? 1)

            ZStack(alignment: .topLeading) {
                if presenter.fovDetail != nil {
                    ForEach(presenter.boxes) { box in
                        BoxComponentView(
                            box: box,
                            selectedBox: presenter.selectedBox,
                            zoomScale: zoomScale
                        )
                        .frame(width: box.width * scaleX, height: box.height * scaleY)
                        .position(
                            x: (box.x + box.width / 2) * scaleX,
                            y: (box.y + box.height / 2) * scaleY
                        )
                        .onTapGesture {
                            presenter.selectedBox = box
                        }
                        .offset(y: -10)
                    }
                }
            }
        }
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
