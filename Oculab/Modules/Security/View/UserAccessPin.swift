//
//  UserAccessPin.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 06/11/24.
//

import SwiftUI

struct UserAccessPin: View {
    @ObservedObject var securityPresenter = SecurityPresenter()
    var title: String = "Atur PIN"
    var description: String = "Atur PIN untuk kemudahan login di sesi berikutnya"
    var isOpeningApp: Bool = false

    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Text(description)
                    .font(AppTypography.p2)
                    .foregroundStyle(AppColors.slate900)
                    .padding(.top, 24)
                    .multilineTextAlignment(.center)

                HStack(alignment: .center, spacing: 24) {
                    ForEach(0..<4) { index in
                        Circle()
                            .strokeBorder(AppColors.purple500, lineWidth: 2)
                            .frame(width: 32, height: 32)
                            .background(securityPresenter.pin.count > index ? AppColors.purple500 : Color.clear)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 64)

                PinNumpadComponent(pin: $securityPresenter.pin, isOpeningApp: true)
                    .padding(.top, 40)

                if isOpeningApp {
                    HStack(alignment: .center, spacing: 12) {
                        Text("Lupa PIN?")
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate900)

                        Text("Gunakan Password")
                            .font(AppTypography.s5)
                            .foregroundStyle(AppColors.purple500)
                    }
                    .padding(.top, 64)
                }

                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(20)
        .ignoresSafeArea(.all)
    }
}

#Preview {
    UserAccessPin()
}
