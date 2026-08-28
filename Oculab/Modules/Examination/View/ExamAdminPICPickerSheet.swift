//
//  ExamAdminPICPickerSheet.swift
//  Oculab
//

import SwiftUI

struct ExamAdminPICPickerSheet: View {
    let onSelect: (User) -> Void

    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    private let interactor = InputPatientInteractor()

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate600)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List(users, id: \.id) { user in
                        Button {
                            onSelect(user)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(AppTypography.p2)
                                    .foregroundStyle(AppColors.slate900)
                                Text(user.email ?? AppValue.empty)
                                    .font(AppTypography.p4)
                                    .foregroundStyle(AppColors.slate400)
                            }
                        }
                    }
                }
            }
            .navigationTitle(AppTextExamDetail.adminReassignPicTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(AppState.cancel) { dismiss() }
                }
            }
            .task {
                await loadUsers()
            }
        }
    }

    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            users = try await interactor.getAllUser()
            errorMessage = ""
        } catch {
            errorMessage = ErrorHandler.shared.handleError(error)
        }
    }
}
