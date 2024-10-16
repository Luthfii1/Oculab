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
        case .draft:
            VStack(alignment: .leading) {
                Text(StatusType.draft.rawValue)
                    .foregroundStyle(AppColors.orange500)
            }
            .font(AppTypography.s6)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.orange50)
            .cornerRadius(Decimal.d4)

        case .done:
            VStack(alignment: .leading) {
                Text(StatusType.done.rawValue)
                    .foregroundStyle(AppColors.blue500)
            }
            .font(AppTypography.s6)
            .padding(.horizontal, Decimal.d8)
            .padding(.vertical, Decimal.d6)
            .background(AppColors.blue50)
            .cornerRadius(Decimal.d4)

        case .none:
            EmptyView()
        }
    }
}

#Preview {
    StatusTagComponent(
        type: .done
    )
}
