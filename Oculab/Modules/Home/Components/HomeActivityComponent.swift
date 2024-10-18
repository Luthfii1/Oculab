//
//  HomeActivityComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct HomeActivityComponent: View {
    var fileName: String // URL as a String
    var slideId: String
    var status: StatusType
    var date: String
    var time: String

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d12) {
            ZStack(alignment: .topTrailing) {

                AsyncImage(url: URL(string: fileName)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 114)
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 114)
                            .clipped()
                    case .failure:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 114)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(Decimal.d8)

                StatusTagComponent(type: status)
                    .padding(Decimal.d6) // Padding for the status tag
            }
            .cornerRadius(Decimal.d8)

            VStack(alignment: .leading, spacing: Decimal.d8) {
                HStack {
                    Text(date)
                    Spacer()
                    Text(time)
                }
                .font(AppTypography.p5)
                .foregroundColor(AppColors.slate300)

                Text(slideId).font(AppTypography.h4_1)
            }
        }
        .padding(.horizontal, Decimal.d12)
        .padding(.vertical, Decimal.d12)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(AppColors.slate100)
        )
    }
}


#Preview {
    HomeActivityComponent(
        fileName: "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
        slideId: "24/11/1/0123A",
        status: .draft,
        date: "18 September 2024",
        time: "14.39"
    )
}
