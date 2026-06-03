//
//  LaborantInfoComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 06/11/24.
//

import SwiftUI

struct LaborantInfoComponent: View {
    var pic: String
    var dpjp: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppTextExamCompLabInfo.cardTitle)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.purple700)

            HStack(alignment: .top, spacing: 16) {
                officerColumn(
                    label: AppTextExamCompLabInfo.examinationOfficerTitle,
                    name: displayName(pic)
                )
                officerColumn(
                    label: AppTextExamCompLabInfo.assignedByTitle,
                    name: displayName(dpjp)
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.purple50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.purple100, lineWidth: 1)
        )
    }

    private func officerColumn(label: String, name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.p5)
                .foregroundStyle(AppColors.slate400)
            Text(name)
                .font(AppTypography.s4_1)
                .foregroundStyle(AppColors.slate900)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func displayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppValue.defaultStrike : trimmed
    }
}
