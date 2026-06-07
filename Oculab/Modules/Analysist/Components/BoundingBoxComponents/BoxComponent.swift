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
    var labelNumber: Int?

    private var isSelected: Bool {
        selectedBox?.id == box.id
    }

    private var borderColor: Color {
        let noSelection = selectedBox == nil

        switch box.status {
        case .verified:
            return noSelection || isSelected ? .green : Color.green.opacity(0.3)
        case .flagged:
            return noSelection || isSelected ? .red : Color.red.opacity(0.3)
        case .trashed:
            return .clear
        case .none:
            return noSelection || isSelected ? .yellow : Color.yellow.opacity(0.3)
        }
    }

    private var strokeWidth: CGFloat {
        let base = max(1.5, 2.2 / zoomScale)

        if isSelected {
            return base * 1.35
        }
        if selectedBox == nil {
            return base
        }
        return base * 0.9
    }

    private var labelFontSize: CGFloat {
        max(11, min(13, 12 / zoomScale))
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .inset(by: strokeWidth / 2)
                    .stroke(borderColor, lineWidth: strokeWidth)
            )
            .background(alignment: .topLeading) {
                if let labelNumber {
                    Text("\(labelNumber)")
                        .font(.system(size: labelFontSize, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .offset(x: -4, y: -(labelFontSize + 8))
                }
            }
    }
}
