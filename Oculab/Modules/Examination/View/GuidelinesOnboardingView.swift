//
//  GuidelinesOnboardingView.swift
//  Oculab
//
//  Created by Risa on 22/04/25.
//

import SwiftUI

struct GuidelinesOnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0

    let pages: [GuidelinePage] = [
        GuidelinePage(
            imageName: "Guideline1",
            title: "Temukan Lapang Pandang pada Mikroskop",
            description: "Teteskan minyak imersi pada kaca sediaan dan atur lensa objektif ke perbesaran 100x"
        ),
        GuidelinePage(
            imageName: "Guideline2",
            title: "Pasang Handphone pada Adapter",
            description: "Bersihkan lensa kamera utama dan sejajarkan dengan lubang adapter"
        ),
        GuidelinePage(
            imageName: "Guideline3",
            title: "Pasang Adapter pada Mikroskop",
            description: "Pasang adapter ke lensa okuler dan atur fokus antara mikroskop dan kamera"
        )
    ]

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Spacer().frame(height: 60)

                            Image(pages[index].imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 240)

                            Text(pages[index].title)
                                .font(AppTypography.s1)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            Text(pages[index].description)
                                .font(AppTypography.p2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // disables default dots

                CustomPageIndicator(totalPages: pages.count, currentPage: currentPage)
                    .padding(.bottom, 24)

                AppButton(
                    title: "Lanjutkan",
                    rightIcon: "chevron.right",
                    isEnabled: currentPage == pages.count - 1,
                    action: {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            dismiss()
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Persiapan Pemeriksaan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        Image("back")
                    }
                }
            }
        }
    }
}

struct GuidelinePage {
    let imageName: String
    let title: String
    let description: String
}

#Preview {
    GuidelinesOnboardingView()
}
