//
//  BoxComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 19/05/25.
//

import SwiftUI

struct BoxComponentView: View {
    var box: BoxModel
    var selectedBox: BoxModel?

    private var borderColor: Color {
        let noSelection = selectedBox == nil
        let isThisSelected = selectedBox?.id == box.id

        switch box.status {
        case .verified:
            return noSelection || isThisSelected ? .green : Color.green.opacity(0.1)
        case .flagged:
            return noSelection || isThisSelected ? .red : Color.orange.opacity(0.1)
        case .trashed:
            return .clear
        case .none:
            return noSelection || isThisSelected ? .yellow : .yellow.opacity(0.1)
        }
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: box.width, height: box.height)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .inset(by: 3.13)
                    .stroke(borderColor, lineWidth: 6.26842)
            )
    }
}

// #Preview {
//    BoxComponentView(
//        box: BoxModel(id: 1, width: 100, height: 39, x: 0, y: 0),
//        boxes: [
//            BoxModel(id: 1, width: 100, height: 39, x: 0, y: 0),
//            BoxModel(id: 2, width: 100, height: 39, x: 50, y: 50)
//        ],
//        isSelected: false // or false
//    )
// }
