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
    var transformedWidth: Double
    var transformedHeight: Double

    private var borderColor: Color {
        let noSelection = selectedBox == nil
        let isThisSelected = selectedBox?.id == box.id

        switch box.status {
        case .verified:
            return noSelection || isThisSelected ? .green : Color.green.opacity(0.2)
        case .flagged:
            return noSelection || isThisSelected ? .red : Color.red.opacity(0.2)
        case .trashed:
            return .clear
        case .none:
            return noSelection || isThisSelected ? .yellow : .yellow.opacity(0.2)
        }
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: transformedWidth, height: transformedHeight)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .inset(by: 3.13)
                    .stroke(borderColor, lineWidth: 1 * zoomScale)
            )
    }
}
