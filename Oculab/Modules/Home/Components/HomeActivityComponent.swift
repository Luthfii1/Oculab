//
//  HomeActivityComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

// import SwiftUI
//
// struct HomeActivityComponent: View {
//    var fileName: String // URL as a String
//    var slideId: String
//    var status: StatusType
//    var date: String
//    var time: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: Decimal.d12) {
//            ZStack(alignment: .top) {
//                AsyncImage(url: URL(string: fileName)) { phase in
//                    switch phase {
//                    case .empty:
//                        ProgressView()
//                            .frame(height: 114)
//                    case let .success(image):
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .frame(height: 114)
//                            .clipped()
//                    case .failure:
//                        Image(systemName: "exclamationmark.triangle.fill")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 114)
//                            .foregroundColor(.red)
//                    @unknown default:
//                        EmptyView()
//                    }
//                }
//                .cornerRadius(Decimal.d8)
//
//                HStack {
//                    Spacer()
//                    StatusTagComponent(type: status)
//                        .padding(Decimal.d6)
//                }
//            }
//            .cornerRadius(Decimal.d8)
//
//            VStack(alignment: .leading, spacing: Decimal.d8) {
//                HStack {
//                    Text(date)
//                    Spacer()
//                    Text(time)
//                }
//                .font(AppTypography.p5)
//                .foregroundColor(AppColors.slate300)
//
//                Text(slideId).font(AppTypography.h4_1)
//            }
//        }
//        .padding(.horizontal, Decimal.d12)
//        .padding(.vertical, Decimal.d12)
//        .cornerRadius(Decimal.d12)
//        .overlay(
//            RoundedRectangle(cornerRadius: Decimal.d12)
//                .stroke(AppColors.slate100)
//        )
//    }
// }
//
// #Preview {
//    HomeActivityComponent(
//        fileName: "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
//        slideId: "24/11/1/0123A",
//        status: .INPROGRESS,
//        date: "18 September 2024",
//        time: "14.39"
//    )
//
//    HomeActivityComponent(
//        fileName: "https://is3.cloudhost.id/oculab-fov/oculab-fov/eead8004-2fd7-4f40-be1f-1d02cb886af4.png",
//        slideId: "24/11/1/0123A",
//        status: .FINISHED,
//        date: "18 September 2024",
//        time: "14.39"
//    )
// }

import SwiftUI

struct HomeActivityComponent: View {
    var slideId: String
    var status: StatusType
    var date: String
    var patientName: String
    var patientDOB: String

    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            HStack {
                Text("\(date)").font(AppTypography.p5).foregroundStyle(AppColors.slate300)
                Spacer()
                StatusTagComponent(type: status)
            }
            HStack(spacing: Decimal.d8) {
                Image(systemName: "doc.text.fill")
                    .padding(Decimal.d8)
                    .background(AppColors.purple50)
                    .foregroundStyle(AppColors.purple500)
                    .cornerRadius(Decimal.d8)
                Text(slideId).font(AppTypography.s4_1)
            }
            HStack(spacing: Decimal.d4) {
                Text(patientName)
                Text("(\(patientDOB))")
            }.font(AppTypography.p4)
        }
        .padding(Decimal.d12)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(AppColors.slate100)
        )
    }
}

#Preview {
    HomeActivityComponent(
        slideId: "24/11/1/0123A",
        status: .INPROGRESS,
        date: "18 September 2024",
        patientName: "Muhammad Rasyad Caesarardhi",
        patientDOB: "19/12/00"
    )

    HomeActivityComponent(
        slideId: "24/11/1/0123A",
        status: .NOTSTARTED,
        date: "18 September 2024",
        patientName: "Muhammad Rasyad Caesarardhi",
        patientDOB: "19/12/00"
    )
}
