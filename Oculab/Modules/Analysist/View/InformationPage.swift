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

                    AppCard(icon: AppText.Icon.infoCircle, title: AppTextAnalysisInformation.assessmentStandardTitle, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            Text(AppTextAnalysisInformation.assessmentStandardDescription)

                            VStack(alignment: .leading, spacing: Decimal.d16) {
                                HStack(alignment: .top) {
                                    Text(AppTextAnalysisInformation.bulletPoint)
                                    Text(AppTextAnalysisInformation.negativeDescription)
                                }
                                HStack(alignment: .top) {
                                    Text(AppTextAnalysisInformation.bulletPoint)
                                    Text(AppTextAnalysisInformation.scantyDescription)
                                }
                                HStack(alignment: .top) {
                                    Text(AppTextAnalysisInformation.bulletPoint)
                                    Text(AppTextAnalysisInformation.positive1Description)
                                }
                                HStack(alignment: .top) {
                                    Text(AppTextAnalysisInformation.bulletPoint)
                                    Text(AppTextAnalysisInformation.positive2Description)
                                }
                                HStack(alignment: .top) {
                                    Text(AppTextAnalysisInformation.bulletPoint)
                                    Text(AppTextAnalysisInformation.positive3Description)
                                }
                            }
                            .padding(.leading, Decimal.d12)
                        }
                        .font(AppTypography.p3)
                    }

                    AppCard(icon: AppText.Icon.infoCircle, title: AppTextAnalysisInformation.confidenceLevelTitle, spacing: Decimal.d16) {
                        VStack(alignment: .leading, spacing: Decimal.d16) {
                            HStack(alignment: .top) {
                                Text(AppTextAnalysisInformation.bulletPoint)
                                Text(AppTextAnalysisInformation.perfectConfidenceDescription)
                            }
                            HStack(alignment: .top) {
                                Text(AppTextAnalysisInformation.bulletPoint)
                                Text(AppTextAnalysisInformation.highConfidenceDescription)
                            }
                            HStack(alignment: .top) {
                                Text(AppTextAnalysisInformation.bulletPoint)
                                Text(AppTextAnalysisInformation.mediumConfidenceDescription)
                            }
                            HStack(alignment: .top) {
                                Text(AppTextAnalysisInformation.bulletPoint)
                                Text(AppTextAnalysisInformation.lowConfidenceDescription)
                            }
                            HStack(alignment: .top) {
                                Text(AppTextAnalysisInformation.bulletPoint)
                                Text(AppTextAnalysisInformation.veryLowConfidenceDescription)
                            }
                            HStack(alignment: .top) {
                                Text(AppTextAnalysisInformation.bulletPoint)
                                Text(AppTextAnalysisInformation.unpredictedDescription)
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
                            Image("back")
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
