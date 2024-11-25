//
//  HomeActivityComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct HomeActivityComponent: View {
    var slideId: String
    var status: StatusType
    var date: String
    var patientName: String
    var patientDOB: String
    var picName: String

    var isLab: Bool

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
                Text(isLab ? slideId : patientName + " (\(patientDOB))").font(AppTypography.s4_1)
                    .foregroundStyle(AppColors.slate900)
                    .multilineTextAlignment(.leading)
            }

            if isLab {
                Text(patientName + " (\(patientDOB))").font(AppTypography.p4).foregroundStyle(AppColors.slate900)
            } else {
                Text("Petugas Pemeriksaan").font(AppTypography.s6).foregroundStyle(AppColors.slate300)
                Text(picName).font(AppTypography.p2).foregroundStyle(AppColors.slate900)
            }
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
        patientDOB: "19/12/00",
        picName: "Bachul",
        isLab: false
    )

    HomeActivityComponent(
        slideId: "24/11/1/0123A",
        status: .NOTSTARTED,
        date: "18 September 2024",
        patientName: "Muhammad Rasyad Caesarardhi",
        patientDOB: "19/12/00",
        picName: "Bachul",
        isLab: true
    )
}
