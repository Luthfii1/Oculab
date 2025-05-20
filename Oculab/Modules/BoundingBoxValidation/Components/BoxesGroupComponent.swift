
//
//  BoxesGroupComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 20/05/25.
//

import SwiftUI

struct BoxesGroupComponentView: View {
    var width: Double
    var height: Double
    var zoomScale: CGFloat
    @State private var boxes: [BoxModel]
    @State private var selectedBox: BoxModel?

    init(width: Double, height: Double, zoomScale: CGFloat, boxes: [BoxModel]) {
        self.width = width
        self.height = height
        self.zoomScale = zoomScale
        _boxes = State(initialValue: boxes)
    }

    // Calculate offset to center the selected box
//    private var offset: CGSize {
//        guard let selected = selectedBox else {
//            return .zero
//        }
//        let centerX = width / 2
//        let centerY = height / 2
//
//        let boxCenterX = selected.x
//        let boxCenterY = selected.y
//
//        // Add extra vertical padding to move box slightly higher on the screen
//        let verticalPadding: Double = -100
//
//        return CGSize(
//            width: centerX - boxCenterX,
//            height: (centerY + verticalPadding) - boxCenterY
//        )
//    }

    var body: some View {
        ZStack(alignment: .topLeading) {
//            Image("image 41")
            ForEach(boxes) { box in
                BoxComponentView(
                    box: box,
                    selectedBox: selectedBox,
                    zoomScale: zoomScale
                )
                .position(
                    x: box.x * zoomScale,
                    y: box.y * zoomScale
                )
                .onTapGesture {
                    selectedBox = box
                }
//                BoxComponentView(box: box, selectedBox: selectedBox)
//                    .frame(width: box.width * zoomScale, height: box.height * zoomScale)
//                    .position(
//                        x: box.x * zoomScale,
//                        y: box.y * zoomScale
//                    )
//                    .onTapGesture {
//                        selectedBox = box
//                    }
            }
        }
        .frame(width: width * zoomScale, height: height * zoomScale)
//        .offset(offset) // <-- Apply the offset to center the selected box
        .sheet(item: $selectedBox) { selected in
            TrayView(
                selectedBox: $selectedBox,
                boxes: boxes,
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

    private func updateBoxStatus(id: Int, to status: BoxStatus) {
        if let index = boxes.firstIndex(where: { $0.id == id }) {
            boxes[index].status = status
        }
    }
}

enum BoxStatus {
    case none, verified, trashed, flagged
}

struct BoxModel: Identifiable, Equatable {
    let id: Int
    var width: Double
    var height: Double
    var x: Double
    var y: Double
    var status: BoxStatus = .none
}

// #Preview {
//    BoxesGroupComponentView(
//        //        width: 300,
////        height: 300,
//        imageSize: CGSize(width: 100, height: 400), zoomScale: CGFloat(1),
//        boxes: [
//            BoxModel(id: 1, width: 80, height: 40, x: 40, y: 60),
//            BoxModel(id: 2, width: 120, height: 60, x: 180, y: 90),
//            BoxModel(id: 3, width: 90, height: 70, x: 70, y: 170),
//            BoxModel(id: 4, width: 110, height: 55, x: 210, y: 200),
//            BoxModel(id: 5, width: 75, height: 35, x: 130, y: 30),
//        ]
//    )
// }
