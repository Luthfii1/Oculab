//
//  HeaderViewComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/11/24.
//

import SwiftUI

struct HeaderViewComponent: View {
    @Binding var isLeavePopUpVisible: Bool
    var onClose: (() -> Void)? = nil

    var body: some View {
        HStack {
            Button(action: {
                if let onClose {
                    onClose()
                } else {
                    isLeavePopUpVisible = true
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(AppColors.slate100, lineWidth: 1)
                        .frame(width: 36, height: 36)
                    Image(systemName: AppIcon.close)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.slate900)
                }
            }

            Spacer()

            Text(AppTextExamCompHeaderView.newExaminationTitle)
                .font(AppTypography.s4_1)
                .foregroundColor(AppColors.slate900)

            Spacer()
            Spacer().frame(width: 44)
        }
        .padding(.horizontal)
        .frame(height: 24)
    }
}

#Preview {
    HeaderViewComponent(isLeavePopUpVisible: .constant(true))
}
