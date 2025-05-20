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
    @Binding var selectedBox: BoxModel?
    var onBoxSelected: ((BoxModel) -> Void)?

    init(
        width: Double,
        height: Double,
        zoomScale: CGFloat,
        boxes: [BoxModel],
        selectedBox: Binding<BoxModel?>,
        onBoxSelected: ((BoxModel) -> Void)? = nil
    ) {
        self.width = width
        self.height = height
        self.zoomScale = zoomScale
        _boxes = State(initialValue: boxes)
        _selectedBox = selectedBox
        self.onBoxSelected = onBoxSelected
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
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
                    onBoxSelected?(box)
                }
            }
        }
        .frame(width: width * zoomScale, height: height * zoomScale)
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
