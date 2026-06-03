//
//  ExamDetailSectionCard.swift
//  Oculab
//

import SwiftUI

struct ExamDetailSectionCard<Content: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.purple600)
                Text(title)
                    .font(AppTypography.s4_1)
                    .foregroundStyle(AppColors.slate900)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
    }
}

struct ExamDetailFieldList: View {
    let rows: [(label: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(rows, id: \.label) { row in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(row.label):")
                        .font(AppTypography.p5)
                        .foregroundStyle(AppColors.slate400)
                        .frame(width: 118, alignment: .leading)

                    Text(row.value)
                        .font(AppTypography.p4)
                        .foregroundStyle(AppColors.slate900)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
