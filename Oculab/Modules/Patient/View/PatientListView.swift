//
//  PatientListView.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import SwiftUI

struct PatientListView: View {
    @StateObject private var presenter = PatientPresenter()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Riwayat")
                        .font(AppTypography.h1)
                        .foregroundColor(AppColors.slate900)
                }
                
                AppSearchBar(
                    searchText: $presenter.searchText,
                    placeholder: "Cari nama pasien",
                    onSearch: {
                        presenter.searchPatients()
                    }
                )

                AppButton(
                    title: "Tambah Pasien Baru",
                    leftIcon: "plus",
                    colorType: .secondary,
                    action: {
                        presenter.navigateTo(.patientForm())
                    }
                )
                
                if presenter.isPatientLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                } else if !presenter.searchText.isEmpty && presenter.filteredPatientNameDoB.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.slate300)
                        
                        Text("Tidak ada hasil untuk \"\(presenter.searchText)\"")
                            .font(AppTypography.s3)
                            .foregroundColor(AppColors.slate700)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            presenter.clearSearch()
                        }) {
                            Text("Hapus Pencarian")
                                .font(AppTypography.p2)
                                .foregroundColor(AppColors.purple600)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(presenter.filteredPatientNameDoB, id: \.1) { nameWithDoB, patientId in
                                Button {
                                    presenter.navigateTo(.patientDetail(patientId: patientId))
                                } label: {
                                    PatientCard(
                                        name: nameWithDoB.components(separatedBy: " (").first ?? "",
                                        birthDate: nameWithDoB.components(separatedBy: " (").last?.replacingOccurrences(of: ")", with: "") ?? ""
                                    )
                                }
                            }
                        }
                    }
                }
                
            }
            .padding(.horizontal, Decimal.d20)
            .background(Color(.systemBackground))
            .onAppear {
                Task {
                    await presenter.getAllPatient()
                }
            }
            .onChange(of: presenter.searchText) { _, _ in
                presenter.searchPatients()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    PatientListView()
}
