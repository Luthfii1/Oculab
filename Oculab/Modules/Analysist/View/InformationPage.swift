//
//  InformationPage.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct InformationPage: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Decimal.d24) {
                    Rectangle()
                        .frame(width: 0, height: 0)

                    AppCard(icon: AppIcon.info, title: AppTextAnalysisInformation.assessmentStandardTitle, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            Text(AppTextAnalysisInformation.assessmentStandardDescription)

                            VStack(alignment: .leading, spacing: Decimal.d16) {
                                ForEach(AppTextAnalysisInformation.btaDescriptions, id: \.self) { description in
                                    HStack(alignment: .top) {
                                        Text(AppTextAnalysisInformation.bulletPoint)
                                        Text(description)
                                    }
                                }
                            }
                            .padding(.leading, Decimal.d12)
                        }
                        .font(AppTypography.p3)
                    }

                    AppCard(icon: AppIcon.info, title: AppTextAnalysisInformation.confidenceLevelTitle, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            ForEach(AppTextAnalysisInformation.confidenceDescriptions, id: \.self) { description in
                                HStack(alignment: .top) {
                                    Text(AppTextAnalysisInformation.bulletPoint)
                                    Text(description)
                                }
                            }
                        }
                        .padding(.leading, Decimal.d12)
                        .font(AppTypography.p3)
                    }
                }
                .padding(.horizontal, Decimal.d20)
            }
            .navigationTitle(AppTextAnalysisInformation.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image(AppImage.back)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    InformationPage()
}
