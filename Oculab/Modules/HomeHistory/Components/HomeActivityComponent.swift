//
//  HomeActivityComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

enum ViewType {
    case lab
    case admin
    case adminPatientDetail
}

struct HomeActivityComponent: View {
    var slideId: String
    var status: StatusType
    var date: String
    var patientName: String
    var patientDOB: String
    var picName: String
    var viewType: ViewType
    var showsPendingUpload: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                plannedDateHeader
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    if showsPendingUpload {
                        Text(AppTextExam.uploadPendingBadge)
                            .font(AppTypography.p4)
                            .foregroundStyle(AppColors.orange700)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.orange50)
                            .clipShape(Capsule())
                    }
                    StatusTagComponent(type: status)
                }
            }

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: AppIcon.documentFill)
                    .font(.title3)
                    .foregroundStyle(AppColors.purple600)
                    .frame(width: 44, height: 44)
                    .background(AppColors.purple50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 8) {
                    Text(primaryTitle)
                        .font(AppTypography.s4_1)
                        .foregroundStyle(AppColors.slate900)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    detailRows
                }

                Spacer(minLength: 4)

                Image(systemName: AppIcon.forward)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.slate300)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.slate0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
        .shadow(color: AppColors.slate400.opacity(0.12), radius: 8, y: 2)
    }

    @ViewBuilder
    private var detailRows: some View {
        switch viewType {
        case .lab, .adminPatientDetail:
            labeledRow(
                label: AppTextHomeHistCompHomeActivity.patientLabel,
                value: patientName
            )
            labeledRow(
                label: AppTextHomeHistCompHomeActivity.dobLabel,
                value: patientDOB
            )
        case .admin:
            labeledRow(
                label: AppTextHomeHistCompHomeActivity.patientLabel,
                value: AppData.makeSentence([patientName, patientDOB])
            )
            labeledRow(
                label: AppTextHomeHistCompHomeActivity.examinationOfficerLabel,
                value: picName
            )
        }
    }

    private var plannedDateHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: AppIcon.calendar)
                .font(.body)
                .foregroundStyle(AppColors.purple500)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppTextHomeHistCompHomeActivity.plannedDateLabel)
                    .font(AppTypography.p5)
                    .foregroundStyle(AppColors.slate400)

                Text(displayDate)
                    .font(AppTypography.p4)
                    .foregroundStyle(AppColors.slate700)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(AppTextHomeHistCompHomeActivity.plannedDateLabel), \(displayDate)"
        )
    }

    private var displayDate: String {
        let trimmed = date.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppValue.defaultStrike : trimmed
    }

    private var primaryTitle: String {
        switch viewType {
        case .lab, .adminPatientDetail:
            return slideId
        case .admin:
            return slideId.isEmpty ? patientName : slideId
        }
    }

    private func labeledRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(label):")
                .font(AppTypography.p5)
                .foregroundStyle(AppColors.slate400)
            Text(value)
                .font(AppTypography.p4)
                .foregroundStyle(AppColors.slate700)
                .lineLimit(1)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HomeActivityComponent(
            slideId: "Testing rahmat",
            status: .NOTSTARTED,
            date: "03 Jun 2026 12:58",
            patientName: "rahmat",
            patientDOB: "01/01/18",
            picName: "Officer",
            viewType: .lab
        )
        HomeActivityComponent(
            slideId: "24/11/1/0123A",
            status: .INPROGRESS,
            date: "18 September 2024",
            patientName: "Muhammad Rasyad",
            patientDOB: "19/12/00",
            picName: "Bachul",
            viewType: .admin
        )
    }
    .padding()
    .background(AppColors.slate0)
}
