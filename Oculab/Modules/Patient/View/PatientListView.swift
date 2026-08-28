//
//  PatientListView.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import SwiftUI

struct PatientListView: View {
    @State private var presenter = PatientPresenter()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: AppConstants.PatientUI.viewSpacing) {
                HStack {
                    Text(AppTextPatientList.navigationTitle)
                        .font(AppTypography.h1)
                        .foregroundColor(AppColors.slate900)
                    
                    Spacer()
                    
                    CompactNetworkStatusView()
                }
                
                AppSearchBar(
                    searchText: $presenter.searchText,
                    placeholder: AppTextPatientList.searchPlaceholder,
                    onSearch: {
                        presenter.searchPatients()
                    }
                )

                AppButton(
                    title: AppTextPatientList.buttonCreatePatient,
                    leftIcon: AppIcon.add,
                    colorType: .secondary,
                    action: {
                        presenter.navigateTo(.patientForm())
                    }
                )
                
                if presenter.isPatientLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, AppConstants.PatientUI.topPadding)
                } else if presenter.isPatientListEmpty {
                    emptyPatientListState
                } else if !presenter.searchText.isEmpty && presenter.filteredPatients.isEmpty {
                    emptySearchResultsState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: AppConstants.PatientUI.gridItemSpacing),
                            GridItem(.flexible(), spacing: AppConstants.PatientUI.gridItemSpacing)
                        ], spacing: AppConstants.PatientUI.gridSpacing) {
                            ForEach(presenter.filteredPatients) { patient in
                                Button {
                                    presenter.navigateTo(.patientDetail(patientId: patient.id))
                                } label: {
                                    PatientCard(
                                        name: patient.name,
                                        birthDate: patient.birthDate
                                    )
                                }
                            }
                        }
                    }
                }
                
            }
            .padding(.horizontal, AppConstants.PatientUI.horizontalPadding)
            .background(Color(.systemBackground))
            .onAppear {
                Task {
                    await presenter.getAllPatient()
                }
            }
            .onDisappear {
                presenter.resetState()
            }
            .onChange(of: presenter.searchText) { _, _ in
                presenter.searchPatients()
            }
        }
        .navigationBarHidden(true)
    }

    private var emptyPatientListState: some View {
        VStack(spacing: AppConstants.PatientUI.searchSpacing) {
            Image(systemName: AppIcon.personFill)
                .font(.system(size: AppConstants.PatientUI.noResultsIconSize))
                .foregroundColor(AppColors.slate300)

            Text(AppTextPatientList.emptyListMessage)
                .font(AppTypography.s3)
                .foregroundColor(AppColors.slate700)
                .multilineTextAlignment(.center)

            Text(AppTextPatientList.emptyListHint)
                .font(AppTypography.p3)
                .foregroundColor(AppColors.slate400)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptySearchResultsState: some View {
        VStack(spacing: AppConstants.PatientUI.searchSpacing) {
            Image(systemName: AppIcon.search)
                .font(.system(size: AppConstants.PatientUI.noResultsIconSize))
                .foregroundColor(AppColors.slate300)

            Text(AppSearch.noResults(presenter.searchText))
                .font(AppTypography.s3)
                .foregroundColor(AppColors.slate700)
                .multilineTextAlignment(.center)

            Button(action: {
                presenter.clearSearch()
            }) {
                Text(AppSearch.clearSearch)
                    .font(AppTypography.p2)
                    .foregroundColor(AppColors.purple600)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PatientListView()
}
