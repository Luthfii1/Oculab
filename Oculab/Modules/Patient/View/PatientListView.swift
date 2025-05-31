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
                    searchText: .constant(""),
                    placeholder: "Cari nama pasien",
                    onSearch: {
                        
                    }
                )

                AppButton(
                    title: "Tambah Pasien Baru",
                    leftIcon: "plus",
                    colorType: .secondary,
                    action: {
                        Router.shared.navigateTo(.newPatient)
                    }
                )
                
                if presenter.isPatientLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(presenter.patientNameDoB, id: \.1) { nameWithDoB, patientId in
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
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    PatientListView()
}
