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
                HStack(spacing: Decimal.d8) {
                    Image(systemName: "clock.fill").resizable()
                        .frame(width: Decimal.d12 + Decimal.d6, height: Decimal.d12 + Decimal.d6)
                        .foregroundStyle(AppColors.orange500)
                    Text(StatusType.NEEDVALIDATION.rawValue)
                        .foregroundStyle(AppColors.slate900)
                }
            }
            .font(AppTypography.p4)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.orange50)
            .cornerRadius(Decimal.d20)

        case .FINISHED:
            VStack(alignment: .leading) {
                HStack(spacing: Decimal.d8) {
                    Image(systemName: "checkmark.circle.fill").resizable()
                        .frame(width: Decimal.d12 + Decimal.d6, height: Decimal.d12 + Decimal.d6)
                        .foregroundStyle(AppColors.green500)
                    Text(StatusType.FINISHED.rawValue)
                        .foregroundStyle(AppColors.slate900)
                }
            }
            .font(AppTypography.p4)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.green50)
            .cornerRadius(Decimal.d20)

        case .NEEDVALIDATION:
            VStack(alignment: .leading) {
                HStack(spacing: Decimal.d8) {
                    Image(systemName: "clock.fill").resizable()
                        .frame(width: Decimal.d12 + Decimal.d6, height: Decimal.d12 + Decimal.d6)
                        .foregroundStyle(AppColors.orange500)
                    Text(StatusType.NEEDVALIDATION.rawValue)
                        .foregroundStyle(AppColors.slate900)
                }
            }
            .font(AppTypography.p4)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.orange50)
            .cornerRadius(Decimal.d20)

        case .NONE:
            EmptyView()

        case .NOTSTARTED:
            VStack(alignment: .leading) {
                HStack(spacing: Decimal.d8) {
                    Image(systemName: "exclamationmark.circle.fill").resizable()
                        .frame(width: Decimal.d12 + Decimal.d6, height: Decimal.d12 + Decimal.d6)
                        .foregroundStyle(AppColors.red500)
                    Text(StatusType.NOTSTARTED.rawValue)
                        .foregroundStyle(AppColors.slate900)
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
    // case INPROGRESS = "Sedang dianalisa sistem"
    // case NEEDVALIDATION = "Sedang Berlangsung"
    // case NOTSTARTED = "Belum Dimulai"
    // case FINISHED = "Selesai"
    // case NONE = ""

    StatusTagComponent(
        type: .FINISHED
    )

    StatusTagComponent(
        type: .NOTSTARTED
    )

    StatusTagComponent(
        type: .NEEDVALIDATION
    )

    StatusTagComponent(
        type: .INPROGRESS
    )
}
