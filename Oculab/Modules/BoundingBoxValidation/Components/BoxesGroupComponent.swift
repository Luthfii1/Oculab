
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
    @State private var boxes: [BoxModel]
    @State private var selectedBox: BoxModel?

    init(width: Double, height: Double, boxes: [BoxModel]) {
        self.width = width
        self.height = height
        _boxes = State(initialValue: boxes)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(boxes) { box in
                BoxComponentView(
                    box: box,
                    selectedBox: selectedBox
                )
                .position(x: box.x, y: box.y)
                .onTapGesture {
                    selectedBox = box
                }
            }
        }
        .frame(width: width, height: height)
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

#Preview {
    BoxesGroupComponentView(width: 300, height: 300, boxes: [
        BoxModel(id: 1, width: 100, height: 50, x: 50, y: 50),
        BoxModel(id: 2, width: 100, height: 50, x: 150, y: 100),
        BoxModel(id: 3, width: 100, height: 50, x: 100, y: 150),
        BoxModel(id: 4, width: 100, height: 50, x: 200, y: 180),
        BoxModel(id: 5, width: 100, height: 50, x: 150, y: 40),
    ])
}
