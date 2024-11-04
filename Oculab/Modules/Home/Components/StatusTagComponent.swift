//
//  StatusTagComponent.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct StatusTagComponent: View {
    var type: StatusType

    var body: some View {
        switch type {
        case .INPROGRESS:
            VStack(alignment: .leading) {
                Text(StatusType.INPROGRESS.rawValue)
                    .foregroundStyle(AppColors.orange500)
            }
            .font(AppTypography.s6)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.orange50)
            .cornerRadius(Decimal.d4)

        case .FINISHED:
            VStack(alignment: .leading) {
                Text(StatusType.FINISHED.rawValue)
                    .foregroundStyle(AppColors.blue500)
            }
            .font(AppTypography.s6)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.blue50)
            .cornerRadius(Decimal.d4)

        case .NEEDVALIDATION:
            VStack(alignment: .leading) {
                Text(StatusType.NEEDVALIDATION.rawValue)
                    .foregroundStyle(AppColors.purple500)
            }
            .font(AppTypography.s6)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.purple50)
            .cornerRadius(Decimal.d4)

        case .NONE:
            EmptyView()

        case .NOTSTARTED:
            VStack(alignment: .leading) {
                HStack(spacing: Decimal.d8) {
                    Text(StatusType.NOTSTARTED.rawValue)
                        .foregroundStyle(AppColors.slate900)
                    Image(systemName: "exclamationmark.circle.fill").resizable()
                        .frame(width: Decimal.d12 + Decimal.d6, height: Decimal.d12 + Decimal.d6)
                        .foregroundStyle(AppColors.red500)
                }
            }
            .font(AppTypography.p4)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.red50)
            .cornerRadius(Decimal.d20)
        }
    }
}

#Preview {
    StatusTagComponent(
        type: .FINISHED
    )

    StatusTagComponent(
        type: .NOTSTARTED
    )
}
