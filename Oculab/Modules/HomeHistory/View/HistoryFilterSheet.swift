//
//  HistoryFilterSheet.swift
//  Oculab
//

import SwiftUI

struct HistoryFilterSheet: View {
    @State private var filters: HistoryExamFilters
    var onApply: (HistoryExamFilters) -> Void
    @Environment(\.dismiss) private var dismiss

    init(filters: HistoryExamFilters, onApply: @escaping (HistoryExamFilters) -> Void) {
        _filters = State(initialValue: filters)
        self.onApply = onApply
    }

    var body: some View {
        NavigationView {
            Form {
                Section(AppTextHomeHistory.historyFilterDateSection) {
                    DatePicker(
                        AppTextHomeHistory.historyFilterFrom,
                        selection: $filters.fromDate,
                        in: ...filters.toDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        AppTextHomeHistory.historyFilterTo,
                        selection: $filters.toDate,
                        in: filters.fromDate...,
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
                    Button(AppCommon.cancel) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTextHomeHistory.historyFilterApply) {
                        onApply(filters)
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
