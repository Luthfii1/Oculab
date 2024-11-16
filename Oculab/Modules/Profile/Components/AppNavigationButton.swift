//
//  AppNavigationButton.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 16/11/24.
//

import SwiftUI

struct AppNavigationButton: View {
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("hai")
        }
        .font(AppTypography.s4_1)
        .padding(.horizontal, Decimal.d16)
        .padding(.vertical, Decimal.d16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(AppColors.slate100)
        )
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    AppNavigationButton {
        print("halo")
    }
}
