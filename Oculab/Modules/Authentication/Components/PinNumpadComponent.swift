//
//  PinNumpadComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import SwiftUI

struct PinNumpadComponent: View {
    @Binding var pin: String
    @State var isOpeningApp: Bool? = false
    private let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["!", "0", "delete.left.fill"]
    ]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(numbers, id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row, id: \.self) { item in
                        Button(action: {
                            handleInput(item)
                            print("pin", pin)
                        }) {
                            switch item {
                            case "!":
                                if isOpeningApp != nil {
                                    Image(systemName: "faceid")
                                        .font(.title)
                                        .frame(width: 92, height: 92)
                                        .background(AppColors.slate50)
                                        .foregroundColor(AppColors.slate900)
                                        .clipShape(Circle())
                                } else {
                                    // No action button, empty button
                                    Circle()
                                        .frame(width: 92, height: 92)
                                        .foregroundColor(Color.clear)
                                }
                            case "delete.left.fill":
                                // Delete button
                                Image(systemName: item)
                                    .font(.title)
                                    .frame(width: 92, height: 92)
                                    .background(AppColors.slate50)
                                    .foregroundColor(AppColors.slate900)
                                    .clipShape(Circle())
                            default:
                                // Number buttons
                                Text(item)
                                    .font(AppTypography.s1)
                                    .frame(width: 92, height: 92)
                                    .background(AppColors.slate50)
                                    .foregroundColor(AppColors.slate900)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(item.isEmpty)
                    }
                }
            }
        }
    }

    // Handle button press actions
    private func handleInput(_ input: String) {
        switch input {
        case "!":
            print("nothing")
        case "delete.left.fill":
            if !pin.isEmpty {
                pin.removeLast()
            }
        default:
            if pin.count < 4 {
                pin.append(input)
            }
        }
    }
}

#Preview {
    PinNumpadComponent(pin: .constant("12"))
}
