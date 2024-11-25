//
//  PINCirclesComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/11/24.
//

import SwiftUI

struct PINCirclesComponent: View {
    @EnvironmentObject var securityPresenter: AuthenticationPresenter

    var body: some View {
        HStack(spacing: 24) {
            ForEach(0..<4) { index in
                Circle()
                    .strokeBorder(securityPresenter.pinColor, lineWidth: 2)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                securityPresenter.inputPin.count > index ?
                                    AppColors.purple500 : .clear
                            )
                    )
            }
        }
    }
}

#Preview {
    PINCirclesComponent()
        .environmentObject(DependencyInjection.shared.createAuthPresenter())
}
