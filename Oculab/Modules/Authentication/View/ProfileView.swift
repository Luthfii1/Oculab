//
//  ProfileView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/11/24.
//

import SwiftUI

struct ProfileView: View {
//    @EnvironmentObject private var authPresenter: AuthenticationPresenter
    @EnvironmentObject private var profilePresenter: ProfilePresenter

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    ExtendableCard(
                        icon: "person.fill",
                        title: "Informasi Akun",
                        isExtendable: false,
                        data: [
                            (key: "Username", value: profilePresenter.user.name),
                            (key: "Role", value: profilePresenter.user.role.rawValue),
                            (key: "Jabatan Pekerjaan", value: "Ahli Teknologi Laboratorium Medik"),
                        ],
                        titleSize: AppTypography.s4_1,
                        titleCard: profilePresenter.user.name
                    )

                    AppButton(
                        title: "Atur Kata Sandi",
                        leftIcon: "lock",
                        rightIcon: "arrow.right",
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        profilePresenter.navigateTo(.editPassword)
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(
                        title: "Atur PIN",
                        leftIcon: "lock.circle.dotted",
                        rightIcon: "arrow.right",
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        profilePresenter.navigateTo(.userAccessPin(state: .changePIN))
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(AppColors.purple500)
                        Toggle("Face ID", isOn: $profilePresenter.user.isFaceIdEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.purple500))
                            .font(AppTypography.s5)
                    }
                    .padding(.vertical, Decimal.d16)
                    .padding(.horizontal, 16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(
                        title: "Kebijakan Privasi",
                        leftIcon: "lock.shield",
                        rightIcon: "arrow.right",
                        colorType: .tertiary,
                        titleColor: AppColors.slate900
                    ) {
                        print("button Kebijakan privasi")
                    }
                    .padding(.vertical, Decimal.d16)
                    .background(.white)
                    .cornerRadius(Decimal.d12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Decimal.d12)
                            .stroke(AppColors.slate100)
                    )

                    AppButton(title: "Keluar", rightIcon: "door.right.hand.open", colorType: .destructive(.secondary)) {
                        profilePresenter.logout()
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Profile")
        }
//        .onAppear {
//            profilePresenter.setUser()
//        }
    }
}

#Preview {
    ProfileView()
//        .environmentObject(DependencyInjection.shared.createAuthPresenter())
            .environmentObject(DependencyInjection.shared.createProfilePresenter())
}
