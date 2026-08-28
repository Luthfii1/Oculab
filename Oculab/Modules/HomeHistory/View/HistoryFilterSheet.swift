//
//  HistoryFilterSheet.swift
//  Oculab
//

import SwiftUI

struct HistoryFilterSheet: View {
    @Binding var filters: HistoryExamFilters
    var onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(AppTextHomeHistory.historyFilterDateSection) {
                    DatePicker(
                        AppTextHomeHistory.historyFilterFrom,
                        selection: $filters.fromDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        AppTextHomeHistory.historyFilterTo,
                        selection: $filters.toDate,
                        displayedComponents: .date
                    )
                }

                Section(AppTextHomeHistory.historyFilterStatusSection) {
                    Picker(AppTextHomeHistory.historyFilterStatus, selection: statusBinding) {
                        Text(AppTextHomeHistory.historyFilterAnyStatus).tag(Optional<StatusType>.none)
                        ForEach(StatusType.allCases.filter { $0 != .NONE }, id: \.self) { status in
                            Text(status.description).tag(Optional(status))
                        }
                    }
                }

                Section(AppTextHomeHistory.historyFilterGradingSection) {
                    Picker(AppTextHomeHistory.historyFilterGrading, selection: gradingBinding) {
                        Text(AppTextHomeHistory.historyFilterAnyGrading).tag(Optional<GradingType>.none)
                        ForEach(GradingType.allCases.filter { $0 != .unknown }, id: \.self) { grading in
                            Text(grading.rawValue).tag(Optional(grading))
                        }
                    }
                }
            }
            .navigationTitle(AppTextHomeHistory.historyFilterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppState.cancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTextHomeHistory.historyFilterApply) {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusBinding: Binding<StatusType?> {
        Binding(
            get: { filters.status },
            set: { filters.status = $0 }
        )
    }

    private var gradingBinding: Binding<GradingType?> {
        Binding(
            get: { filters.grading },
            set: { filters.grading = $0 }
        )
    }
}
