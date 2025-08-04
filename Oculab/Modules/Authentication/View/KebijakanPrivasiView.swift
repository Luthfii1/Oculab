//
//  KebijakanPrivasiView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/12/24.
//

import SwiftUI

struct KebijakanPrivasiView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Rectangle().hidden()

                    Text(AppText.Authentication.PrivacyPolicy.intro)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate900)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.Authentication.PrivacyPolicy.generalTitle)
                            .font(AppTypography.s5)
                            .foregroundStyle(AppColors.slate900)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(AppText.Authentication.PrivacyPolicy.generalPoints, id: \ .self) { point in
                                HStack(alignment: .top) {
                                    Text(AppText.Authentication.PrivacyPolicy.definitionBullet)
                                    Text(point)
                                }
                            }
                        }
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate900)
                        .padding(.leading, Decimal.d12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.Authentication.PrivacyPolicy.definitionTitle)
                            .font(AppTypography.s5)
                            .foregroundStyle(AppColors.slate900)

                        Text(AppText.Authentication.PrivacyPolicy.definitionIntro)
                            .font(AppTypography.p3)
                            .foregroundStyle(AppColors.slate900)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(AppText.Authentication.PrivacyPolicy.definitions, id: \ .self) { def in
                                if let subpoints = def.subpoints {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(alignment: .top) {
                                            Text(def.label)
                                            Text(def.text)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(subpoints, id: \ .self) { sub in
                                                HStack(alignment: .top) {
                                                    Text(sub.label)
                                                    Text(sub.text)
                                                }
                                            }
                                        }
                                        .padding(.leading, Decimal.d24)
                                    }
                                } else {
                                    HStack(alignment: .top) {
                                        Text(def.label)
                                        Text(def.text)
                                    }
                                }
                            }
                        }
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate900)
                        .padding(.leading, Decimal.d12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(AppText.Authentication.PrivacyPolicy.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppText.Icon.back)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    KebijakanPrivasiView()
}
