//
//  CustomPageIndicator.swift
//  Oculab
//
//  Created by Risa on 22/04/25.
//

import SwiftUI

struct CustomPageIndicator: View {
    var totalPages: Int
    var currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                if index == currentPage {
                    Capsule()
                        .fill(AppColors.purple500)
                        .frame(width: 32, height: 10)
                        .transition(.scale)
                        .animation(.easeInOut, value: currentPage)
                } else {
                    Circle()
                        .fill(AppColors.purple50)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
}
