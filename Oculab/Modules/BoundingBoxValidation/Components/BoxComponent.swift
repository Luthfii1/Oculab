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
    var zoomScale: CGFloat

    private var borderColor: Color {
        let noSelection = selectedBox == nil
        let isThisSelected = selectedBox?.id == box.id

        switch box.status {
        case .verified:
            return noSelection || isThisSelected ? .green : Color.green.opacity(0.3)
        case .flagged:
            return noSelection || isThisSelected ? .red : Color.red.opacity(0.3)
        case .trashed:
            return .clear
        case .none:
            return noSelection || isThisSelected ? .yellow : .yellow.opacity(0.3)
        }
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .inset(by: max(2.0, 3 / zoomScale))
                    .stroke(borderColor, lineWidth: max(2.0, 3 / zoomScale))
            )
    }
}
